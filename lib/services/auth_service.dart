import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:vero360_app/toasthelper.dart';

class AuthService {
  final String baseUrl = 'https://vero-backend.onrender.com';

  // Adjust if your backend routes differ
  static const _loginPath      = '/auth/login';
  static const _otpSendPath    = '/auth/otp/send';
  static const _otpVerifyPath  = '/auth/otp/verify';
  static const _registerPath   = '/auth/register';

  // ========= PASSWORD LOGIN (email or phone supported) =========
  Future<Map<String, dynamic>?> loginWithIdentifier(
    String identifier,
    String password,
    BuildContext context,
  ) async {
    final id = identifier.trim();
    if (!_isEmail(id) && !_isMwPhoneLocal(id) && !_isMwPhoneE164(id)) {
      ToastHelper.showCustomToast(
        context,
        'Enter a valid email or phone (08/09… or +265…)',
        isSuccess: false,
      );
      return null;
    }

    final normalized = _toE164IfPhone(id);
    final url = Uri.parse('$baseUrl$_loginPath');

    // Try unified identifier
    http.Response res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': normalized, 'password': password}),
    );

    // Fallback to explicit email/phone body
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = _isEmail(id)
          ? {'email': id, 'password': password}
          : {'phone': normalized, 'password': password};
      res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data  = _safeJson(res.body);
      final token = data['access_token'] ?? data['token'];
      final user  = Map<String, dynamic>.from(data['user'] ?? {});
      if (token == null) {
        ToastHelper.showCustomToast(context, ' Login failed: missing token', isSuccess: false);
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      final displayId = user['email']?.toString() ?? user['phone']?.toString() ?? normalized;
      await prefs.setString('email', displayId);

      ToastHelper.showCustomToast(context, '✅ Logged in successfully', isSuccess: true);
      return {'token': token, 'user': user};
    } else {
      ToastHelper.showCustomToast(
        context,
        ' Login failed: ${_prettyError(res.body)}',
        isSuccess: false,
      );
      return null;
    }
  }

  // ========= OTP SEND (email or phone) =========
  Future<bool> sendOtp(String identifier, BuildContext context) async {
    final id = identifier.trim();
    if (!_isEmail(id) && !_isMwPhoneLocal(id) && !_isMwPhoneE164(id)) {
      ToastHelper.showCustomToast(
        context,
        'Enter a valid email or phone (08/09… or +265…)',
        isSuccess: false,
      );
      return false;
    }

    final normalized = _toE164IfPhone(id);
    final url = Uri.parse('$baseUrl$_otpSendPath');

    // Try unified identifier
    http.Response res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': normalized}),
    );

    // Fallback explicit
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = _isEmail(id) ? {'email': id} : {'phone': normalized};
      res = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      ToastHelper.showCustomToast(context, '📨 Verification code sent', isSuccess: true);
      return true;
    } else {
      ToastHelper.showCustomToast(
        context,
        'Couldn’t send code: ${_prettyError(res.body)}',
        isSuccess: false,
      );
      return false;
    }
  }

  // ========= OTP VERIFY (email or phone) =========
  Future<bool> verifyOtp(String identifier, String code, BuildContext context) async {
    final id = identifier.trim();
    final normalized = _toE164IfPhone(id);
    final url = Uri.parse('$baseUrl$_otpVerifyPath');

    // Try unified
    http.Response res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': normalized, 'otp': code}),
    );

    // Fallback explicit
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = _isEmail(id)
          ? {'email': id, 'otp': code}
          : {'phone': normalized, 'otp': code};
      res = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      ToastHelper.showCustomToast(context, '✅ Code verified', isSuccess: true);
      return true;
    } else {
      ToastHelper.showCustomToast(
        context,
        'Verification failed: ${_prettyError(res.body)}',
        isSuccess: false,
      );
      return false;
    }
  }

  // ========= REGISTER USER (after verification) =========
  Future<bool> registerUser({
    required String name,
    required String email,
    required String phone, // can be local or +265; we normalize to +265
    required String password,
    required BuildContext context,
  }) async {
    final phoneE164 = _toE164IfPhone(phone.trim());
    final url = Uri.parse('$baseUrl$_registerPath');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name'    : name.trim(),
        'email'   : email.trim(),
        'phone'   : phoneE164,
        'password': password,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      ToastHelper.showCustomToast(context, '🎉 Account created successfully', isSuccess: true);
      return true;
    } else {
      ToastHelper.showCustomToast(
        context,
        ' Registration failed: ${_prettyError(res.body)}',
        isSuccess: false,
      );
      return false;
    }
  }

  // ========= Helpers =========
  bool _isEmail(String v) {
    final re = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    return re.hasMatch(v);
  }

  // Local: 10 digits starting 08/09
  bool _isMwPhoneLocal(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^(08|09)\d{8}$').hasMatch(d);
  }

  // +265 E.164: +265 followed by 9 digits starting with 8 or 9
  bool _isMwPhoneE164(String v) {
    return RegExp(r'^\+265[89]\d{8}$').hasMatch(v);
  }

  // Convert local 08/09xxxxxxxx → +2658/9xxxxxxxx. If already email or E.164, return as-is.
  String _toE164IfPhone(String v) {
    final s = v.trim();
    if (_isMwPhoneE164(s)) return s;
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (RegExp(r'^(08|09)\d{8}$').hasMatch(d)) {
      return '+265${d.substring(1)}';
    }
    return s; // email or invalid
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
}
