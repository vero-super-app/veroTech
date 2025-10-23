// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vero360_app/services/api_config.dart';
import 'package:vero360_app/toasthelper.dart';

class AuthService {
  // ===== Paths (adjust only if your NestJS routes differ) =====
  static const _loginPath      = '/auth/login';
  static const _registerPath   = '/auth/register';
  static const _otpRequestPath = '/auth/otp/request';
  static const _otpVerifyPath  = '/auth/otp/verify';

  // ===== Tunables =====
  static const Duration _netTimeout  = Duration(seconds: 12);
  static const Duration _otpCooldown = Duration(seconds: 45);

  static DateTime? _lastOtpAt;

  Future<String> _base() => ApiConfig.readBase();

  // ---- headers / helpers ----
  static Future<Map<String, String>> authHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? prefs.getString('token');
    return token == null
        ? {'Accept': 'application/json'}
        : {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Map<String, String> _jsonHeaders({Map<String, String>? extra}) =>
      {'Accept': 'application/json', 'Content-Type': 'application/json', if (extra != null) ...extra};

  void _toast(BuildContext ctx, String msg, {bool success = false}) {
    ToastHelper.showCustomToast(ctx, msg, isSuccess: success, errorMessage: success ? '' : '');
  }

  bool _isEmail(String v) => RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v.trim());

  bool _isMwPhoneLocal(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^(08|09)\d{8}$').hasMatch(d);
  }

  bool _isMwPhoneE164(String v) => RegExp(r'^\+265[89]\d{8}$').hasMatch(v.trim());

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

  bool _looksSuspended(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    if (res.statusCode == 503 && ct.contains('text/html')) return true;
    return ct.contains('text/html') && res.body.contains('Service Suspended');
  }

  // ---------- LOGIN ----------
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

    try {
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({'identifier': normalized, 'password': password}))
          .timeout(_netTimeout);

      if (_looksSuspended(res)) {
        _toast(context, 'Service is temporarily offline. Please try again later.');
        return null;
      }

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

        final displayId = user['email']?.toString() ?? user['phone']?.toString() ?? normalized;
        await prefs.setString('email', displayId);

        final fullName = ((user['name'] ??
                '${(user['firstName'] ?? '').toString().trim()} ${(user['lastName'] ?? '').toString().trim()}')
            .toString())
            .trim();

        await prefs.setString('fullName', fullName.isEmpty ? 'Guest User' : fullName);
        await prefs.setString('name',     fullName.isEmpty ? 'Guest User' : fullName);
        await prefs.setString('phone',    (user['phone'] ?? '').toString());
        await prefs.setString('profilepicture',
            (user['profilepicture'] ?? user['profilePicture'] ?? '').toString());

        _toast(context, 'Logged in successfully', success: true);
        return {'token': token, 'user': user};
      }

      _toast(context, _prettyError(res.body));
      return null;
    } on TimeoutException {
      _toast(context, 'Network timeout. Please try again.');
      return null;
    } catch (e) {
      _toast(context, 'Login error: $e');
      return null;
    }
  }

  // ---------- REQUEST OTP ----------
  Future<bool> requestOtp({
    required String channel, // 'email' or 'phone'
    String? email,
    String? phone,
    required BuildContext context,
  }) async {
    // Cooldown to avoid “forever sending” spam during outages
    final now = DateTime.now();
    if (_lastOtpAt != null && now.difference(_lastOtpAt!) < _otpCooldown) {
      final remain = _otpCooldown - now.difference(_lastOtpAt!);
      _toast(context, 'Please wait ${remain.inSeconds}s before requesting another code');
      return false;
    }

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

    try {
      debugPrint('OTP URL => $uri');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode(body))
          .timeout(_netTimeout);

      debugPrint('requestOtp($channel) -> ${res.statusCode} ${res.body}');

      if (_looksSuspended(res)) {
        _toast(context, 'Service is temporarily offline. Please try again later.');
        return false;
      }

      if (_is2xx(res.statusCode)) {
        _lastOtpAt = now;
        _toast(context, 'Verification code sent', success: true);
        return true;
      }

      _toast(context, 'Couldn’t send code: ${_prettyError(res.body)}');
      return false;
    } on TimeoutException {
      _toast(context, 'Network timeout. Please check connection and try again.');
      return false;
    } catch (e) {
      _toast(context, 'Error: $e');
      return false;
    }
  }

  // ---------- VERIFY OTP → returns ticket or 'verified' ----------
  Future<String?> verifyOtpGetTicket({
    required String identifier, // email or phone
    required String code,
    required BuildContext context,
  }) async {
    final base = await _base();
    final uri  = Uri.parse('$base$_otpVerifyPath');
    final isEmail = _isEmail(identifier);
    final payload = <String, dynamic>{
      'channel': isEmail ? 'email' : 'phone',
      if (isEmail) 'email': identifier.trim() else 'phone': _toE164IfPhone(identifier),
      'code': code.trim(),
    };

    try {
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode(payload))
          .timeout(_netTimeout);

      debugPrint('verifyOtp -> ${res.statusCode} ${res.body}');

      if (_looksSuspended(res)) {
        _toast(context, 'Service is temporarily offline. Please try again later.');
        return null;
      }

      if (_is2xx(res.statusCode)) {
        final data = _safeJson(res.body);
        final ticket = data['ticket']?.toString();
        _toast(context, 'Code verified', success: true);
        return (ticket != null && ticket.isNotEmpty) ? ticket : 'verified';
      }

      _toast(context, 'Verification failed: ${_prettyError(res.body)}');
      return null;
    } on TimeoutException {
      _toast(context, 'Verification timeout. Please try again.');
      return null;
    } catch (e) {
      _toast(context, 'Verification error: $e');
      return null;
    }
  }

  // ---------- REGISTER ----------
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'customer',
    String profilePicture = '',
    required String preferredVerification, // 'email'|'phone'
    String? verificationTicket,
    required BuildContext context,
  }) async {
    final uri = Uri.parse('${await _base()}$_registerPath');

    final payload = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': _toE164IfPhone(phone),
      'password': password,
      'role': role,
      'profilepicture': profilePicture,
      'preferredVerification': preferredVerification,
      if (verificationTicket != null) 'verificationTicket': verificationTicket,
    };

    try {
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));

      debugPrint('register -> ${res.statusCode} ${res.body}');

      if (_looksSuspended(res)) {
        _toast(context, 'Service is temporarily offline. Please try again later.');
        return null;
      }

      if (_is2xx(res.statusCode)) {
        final data = _safeJson(res.body);
        _toast(context, '🎉 Account created successfully', success: true);
        return data.isEmpty ? null : data;
      }

      _toast(context, 'Registration failed: ${_prettyError(res.body)}');
      return null;
    } on TimeoutException {
      _toast(context, 'Network timeout while creating account.');
      return null;
    } catch (e) {
      _toast(context, 'Registration error: $e');
      return null;
    }
  }

  // ---------- LOGOUT ----------
  Future<void> logout({BuildContext? context}) async {
    try {
      final base = await _base();
      final headers = await AuthService.authHeader();
      final uri = Uri.parse('$base/auth/logout');
      await http.post(uri, headers: {
        ...headers,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }).catchError((_) {});
    } catch (_) {
      // ignore
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('token');
      await prefs.remove('email');
    }
  }
}
