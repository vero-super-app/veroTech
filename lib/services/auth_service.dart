// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/services/api_config.dart';
import 'package:vero360_app/toasthelper.dart';

class AuthService {
  // ===== Paths per your NestJS controller =====
  static const _loginPath       = '/auth/login';
  static const _registerPath    = '/auth/register';
  static const _otpRequestPath  = '/auth/otp/request';
  static const _otpVerifyPath   = '/auth/otp/verify';

  Future<String> _base() => ApiConfig.readBase();

  static Future<Map<String, String>> authHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? prefs.getString('token');
    return token == null
        ? {'Accept': 'application/json'}
        : {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  void _toast(BuildContext ctx, String msg, {bool success = false}) {
    ToastHelper.showCustomToast(ctx, msg,
        isSuccess: success, errorMessage: success ? '' : '');
  }

  bool _isEmail(String v) =>
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v);

  bool _isMwPhoneLocal(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^(08|09)\d{8}$').hasMatch(d);
  }

  bool _isMwPhoneE164(String v) => RegExp(r'^\+265[89]\d{8}$').hasMatch(v);

  String _toE164IfPhone(String v) {
    final s = v.trim();
    if (_isMwPhoneE164(s)) return s;
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (RegExp(r'^(08|09)\d{8}$').hasMatch(d)) return '+265${d.substring(1)}';
    return s;
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return {};
    }
  }

  String _prettyError(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        final msg = parsed['message'] ?? parsed['error'];
        if (msg is List && msg.isNotEmpty) return msg.first.toString();
        return msg?.toString() ?? body;
      }
      if (parsed is List && parsed.isNotEmpty) return parsed.first.toString();
      return body;
    } catch (_) {
      return body;
    }
  }

  bool _is2xx(int code) => code >= 200 && code < 300;

  // ---------- LOGIN (unchanged; accepts 2xx) ----------
  Future<Map<String, dynamic>?> loginWithIdentifier(
    String identifier,
    String password,
    BuildContext context,
  ) async {
    final id = identifier.trim();
    if (!_isEmail(id) && !_isMwPhoneLocal(id) && !_isMwPhoneE164(id)) {
      _toast(context, 'Enter a valid email or phone (08/09… or +265…)');
      return null;
    }

    final normalized = _toE164IfPhone(id);
    final uri = Uri.parse('${await _base()}$_loginPath');

    http.Response res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': normalized, 'password': password}),
    );

    if (_is2xx(res.statusCode)) {
  final data  = _safeJson(res.body);
  final token = data['access_token'] ?? data['token'];
  final user  = Map<String, dynamic>.from(data['user'] ?? {});

  if (token == null || (token is String && token.isEmpty)) {
    _toast(context, 'Login failed: missing token');
    return null;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('jwt_token', token.toString());
  await prefs.setString('token', token.toString());

  // persist email/phone as display id
  final displayId = user['email']?.toString() ?? user['phone']?.toString() ?? normalized;
  await prefs.setString('email', displayId);

  // NEW: persist name/phone/picture so ProfilePage has it immediately
  final fullName = ((user['name'] ??
    '${(user['firstName'] ?? '').toString().trim()} ${(user['lastName'] ?? '').toString().trim()}')
    .toString()).trim();

  await prefs.setString('fullName', fullName.isEmpty ? 'Guest User' : fullName);
  await prefs.setString('name',     fullName.isEmpty ? 'Guest User' : fullName);
  await prefs.setString('phone',    (user['phone'] ?? '').toString());
  await prefs.setString('profilepicture',
      (user['profilepicture'] ?? user['profilePicture'] ?? '').toString());

  await ApiConfig.setBase(await _base());
  _toast(context, 'Logged in successfully', success: true);
  return {'token': token, 'user': user};
}
  }

  // ---------- REQUEST OTP (verify-first) ----------
  // MATCHES: @Post('otp/request') with a DTO like { channel: 'email'|'phone', email?, phone? }
  Future<bool> requestOtp({
    required String channel, // 'email' or 'phone'
    String? email,
    String? phone,
    required BuildContext context,
  }) async {
    final base = await _base();
    final uri  = Uri.parse('$base$_otpRequestPath');

    Map<String, dynamic> body;

    if (channel == 'email') {
      if (email == null || !_isEmail(email)) {
        _toast(context, 'Provide a valid email');
        return false;
      }
      body = {'channel': 'email', 'email': email.trim()};
    } else {
      if (phone == null || (!_isMwPhoneLocal(phone) && !_isMwPhoneE164(phone))) {
        _toast(context, 'Provide a valid phone (08/09… or +265…)');
        return false;
      }
      body = {'channel': 'phone', 'phone': _toE164IfPhone(phone)};
    }

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    debugPrint('requestOtp($channel) -> ${res.statusCode} ${res.body}');
    if (_is2xx(res.statusCode)) {
      _toast(context, ' Verification code sent', success: true);
      return true;
    }

    _toast(context, 'Couldn’t send code: ${_prettyError(res.body)}');
    return false;
  }

  // ---------- VERIFY OTP → return a ticket or 'verified' ----------
  // MATCHES: @Post('otp/verify') with a DTO like { channel, email/phone, code }
  Future<String?> verifyOtpGetTicket({
    required String identifier, // email or phone
    required String code,
    required BuildContext context,
  }) async {
    final base     = await _base();
    final uri      = Uri.parse('$base$_otpVerifyPath');
    final isEmail  = _isEmail(identifier);
    final payload  = <String, dynamic>{
      'channel': isEmail ? 'email' : 'phone',
      if (isEmail) 'email': identifier.trim() else 'phone': _toE164IfPhone(identifier),
      'code'   : code.trim(), // <-- most backends name it "code"
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    debugPrint('verifyOtp -> ${res.statusCode} ${res.body}');
    if (_is2xx(res.statusCode)) {
      final data = _safeJson(res.body);
      final ticket = data['ticket']?.toString();
      _toast(context, 'Code verified', success: true);
      return (ticket != null && ticket.isNotEmpty) ? ticket : 'verified';
    }

    _toast(context, 'Verification failed: ${_prettyError(res.body)}');
    return null;
  }

  // ---------- REGISTER (verify-first friendly; 2xx OK) ----------
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'customer',
    String profilePicture = '',
    required String preferredVerification, // 'email'|'phone'
    String? verificationTicket,            // optional (backend may ignore)
    required BuildContext context,
  }) async {
    final uri = Uri.parse('${await _base()}$_registerPath');

    final payload = {
      'name'                  : name.trim(),
      'email'                 : email.trim(),
      'phone'                 : _toE164IfPhone(phone),
      'password'              : password,
      'role'                  : role,
      'profilepicture'        : profilePicture,
      'preferredVerification' : preferredVerification,
      if (verificationTicket != null) 'verificationTicket': verificationTicket,
    };

    final res = await http.post(
      uri,
      headers: {'accept': '*/*', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    debugPrint('register -> ${res.statusCode} ${res.body}');
    if (_is2xx(res.statusCode)) {
      final data = _safeJson(res.body);
      _toast(context, '🎉 Account created successfully', success: true);
      return data.isEmpty ? null : data;
    }

    _toast(context, 'Registration failed: ${_prettyError(res.body)}');
    return null;
  }

// lib/services/auth_service.dart (inside class AuthService)
Future<void> logout({BuildContext? context}) async {
  try {
    final base = await _base();
    final headers = await AuthService.authHeader();

    // If you expose a backend logout, this will invalidate refresh tokens/sessions.
    // It's safe if the endpoint doesn't exist — we'll ignore non-2xx.
    final uri = Uri.parse('$base/auth/logout');
    await http.post(uri, headers: {
      ...headers,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }).catchError((_) { /* network errors ignored on logout */ });
  } catch (_) {
    // ignore — we still clear local
  } finally {
    final prefs = await SharedPreferences.getInstance();
    // Remove only auth/session keys (don’t wipe other app settings like base URL)
    await prefs.remove('jwt_token');
    await prefs.remove('token');
    await prefs.remove('email');
  }
}

}
