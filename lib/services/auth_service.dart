import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vero360_app/services/api_config.dart';
import 'package:vero360_app/toasthelper.dart';

class AuthService {
  final _client = http.Client();
  String get _base => ApiConfig.prod;

  Map<String, String> _headers([String? token]) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  void _toast(BuildContext ctx, String msg, {bool ok = true}) {
    ToastHelper.showCustomToast(ctx, msg, isSuccess: ok, errorMessage: ok ? '' : msg);
  }

  // ---------------- Email/Phone + Password ----------------
  Future<Map<String, dynamic>?> loginWithIdentifier(
    String identifier,
    String password,
    BuildContext context,
  ) async {
    try {
      final url = Uri.parse('$_base/auth/login');
      final res = await _client.post(url,
          headers: _headers(),
          body: jsonEncode({'identifier': identifier, 'password': password}));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _toast(context, 'Signed in');
        return _normalizeAuthResponse(data);
      }
      final err = _extractError(res);
      _toast(context, err, ok: false);
      return null;
    } catch (e) {
      _toast(context, 'Network error: $e', ok: false);
      return null;
    }
  }

  // ---------------- OTP (register flow) ----------------
  Future<bool> requestOtp({
    required String channel, // 'email' | 'phone'
    String? email,
    String? phone,
    required BuildContext context,
  }) async {
    try {
      final url = Uri.parse('$_base/auth/otp/request');
      final payload = {
        'channel': channel,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
      final res = await _client.post(url, headers: _headers(), body: jsonEncode(payload));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _toast(context, 'Verification code sent');
        return true;
      }
      final err = _extractError(res);
      _toast(context, err, ok: false);
      return false;
    } catch (e) {
      _toast(context, 'Network error: $e', ok: false);
      return false;
    }
  }

  Future<String?> verifyOtpGetTicket({
    required String identifier, // email or phone
    required String code,
    required BuildContext context,
  }) async {
    try {
      final channel = identifier.contains('@') ? 'email' : 'phone';
      final url = Uri.parse('$_base/auth/otp/verify');
      final body = {
        'channel': channel,
        if (channel == 'email') 'email': identifier,
        if (channel == 'phone') 'phone': identifier,
        'code': code,
      };
      final res = await _client.post(url, headers: _headers(), body: jsonEncode(body));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ticket = data['ticket']?.toString();
        if (ticket == null || ticket.isEmpty) {
          _toast(context, 'No ticket in response', ok: false);
          return null;
        }
        _toast(context, 'Verified');
        return ticket;
      }
      final err = _extractError(res);
      _toast(context, err, ok: false);
      return null;
    } catch (e) {
      _toast(context, 'Network error: $e', ok: false);
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role, // 'customer' | 'merchant'
    required String profilePicture,
    required String preferredVerification, // 'email' | 'phone'
    required String verificationTicket,
    required BuildContext context,
  }) async {
    try {
      final url = Uri.parse('$_base/auth/register');
      final res = await _client.post(url, headers: _headers(), body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'profilepicture': profilePicture,
        'preferredVerification': preferredVerification,
        'verificationTicket': verificationTicket,
      }));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _toast(context, 'Account created');
        return _normalizeAuthResponse(data);
      }
      final err = _extractError(res);
      _toast(context, err, ok: false);
      return null;
    } catch (e) {
      _toast(context, 'Network error: $e', ok: false);
      return null;
    }
  }


  Future<bool> logout({BuildContext? context}) async {
    String? token;
    try {
      final sp = await SharedPreferences.getInstance();
      token = sp.getString('token') ?? sp.getString('jwt_token') ?? sp.getString('jwt');
    } catch (_) {}

    // 1) Best-effort server revoke (if you add this route server-side)
    if (token != null && token.isNotEmpty) {
      try {
        final url = Uri.parse('$_base/auth/logout');
        // If the route doesn’t exist, this will 404 — we ignore errors.
        await _client.post(url, headers: _headers(token));
      } catch (_) {/* ignore */}
    }

    // 2) Google sign-out (safe to run even if user didn’t use Google)
    try { await _google.signOut(); } catch (_) {}
    try { await _google.disconnect(); } catch (_) {}

    // 3) (Apple) Nothing specific to do client-side; clearing local session is enough.

    // 4) Local cleanup
    final ok = await _clearLocalSession();

    if (context != null) {
      _toast(context, ok ? 'Signed out' : 'Signed out (local cleanup error)', ok: ok);
    }
    return ok;
  }

  /// Clears tokens and session-related preferences.
  Future<bool> _clearLocalSession() async {
    try {
      final sp = await SharedPreferences.getInstance();
      // Common token keys and any auth-related prefs you use
      const keys = <String>[
        'token',
        'jwt_token',
        'jwt',
        'email',
        'prefill_login_identifier',
        'prefill_login_role',
        'merchant_review_pending',
      ];
      for (final k in keys) {
        await sp.remove(k);
      }
      return true;
    } catch (_) {
      return false;
    }
  }


  // ---------------- Social: Google ----------------
  final GoogleSignIn _google = GoogleSignIn(scopes: ['email', 'profile']);

  Future<Map<String, dynamic>?> continueWithGoogle(BuildContext context) async {
    try {
      final acct = await _google.signIn();
      if (acct == null) return null; // cancelled
      final auth = await acct.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _toast(context, 'No Google ID token', ok: false);
        return null;
      }
      final res = await _client.post(
        Uri.parse('$_base/auth/google'),
        headers: _headers(),
        body: jsonEncode({'idToken': idToken}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _toast(context, 'Signed in with Google');
        return _normalizeAuthResponse(data);
      }
      final err = _extractError(res);
      _toast(context, err, ok: false);
      return null;
    } catch (e) {
      _toast(context, 'Google sign-in failed: $e', ok: false);
      return null;
    }
  }

  // ---------------- Social: Apple ----------------
  Future<Map<String, dynamic>?> continueWithApple(BuildContext context) async {
    try {
      if (!Platform.isIOS) {
        _toast(context, 'Apple Sign-In is only available on iOS', ok: false);
        return null;
      }
      final rawNonce = _randomNonce();
      final nonce = _sha256of(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        _toast(context, 'No Apple identity token', ok: false);
        return null;
      }

      final fullName = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ').trim();

      final res = await _client.post(
        Uri.parse('$_base/auth/apple'),
        headers: _headers(),
        body: jsonEncode({
          'identityToken': identityToken,
          'rawNonce': rawNonce,
          if (fullName.isNotEmpty) 'fullName': fullName,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _toast(context, 'Signed in with Apple');
        return _normalizeAuthResponse(data);
      }
      final err = _extractError(res);
      _toast(context, err, ok: false);
      return null;
    } catch (e) {
      _toast(context, 'Apple sign-in failed: $e', ok: false);
      return null;
    }
  }

  // ---------------- Helpers ----------------
  Map<String, dynamic> _normalizeAuthResponse(Map<String, dynamic> data) {
    // normalize common shapes: { user, access_token } | { user, token } | { jwt }
    final token = data['access_token'] ?? data['token'] ?? data['jwt'];
    return {
      'token': token?.toString(),
      'user': data['user'] ?? data, // fallback if API returns whole user
    };
  }

  String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        final m = body['message'];
        if (m is String) return m;
        if (m is List && m.isNotEmpty) return m.first.toString();
      }
    } catch (_) {}
    return 'Request failed (${res.statusCode})';
  }

  String _randomNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => charset[rand.nextInt(charset.length)]).join();
  }

  String _sha256of(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Utility to persist token centrally (if you want service to save it)
  static Future<void> saveTokenLocally(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', token);
    await sp.setString('jwt_token', token);
  }
}
