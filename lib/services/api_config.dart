// lib/services/api_config.dart
import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  // ===== Defaults =====
  static const String prod = 'https://vero-backend.onrender.com';
  static const String devAndroid = 'http://10.0.2.2:3000';   // Android emulator → host
  static const String devIOSDesktop = 'http://127.0.0.1:3000'; // iOS sim / desktop
  static const String devWeb = 'http://localhost:3000';      // Flutter web

  // Back-compat alias (some services reference prodBase)
  static String get prodBase => prod;

  static const String _prefsKey = 'api_base';
  static String? _current;
  static bool _inited = false;

  /// Call once early in main() or let readBase() lazy-init.
  static Future<void> init() async {
    if (_inited) return;
    final prefs = await SharedPreferences.getInstance();

    // 1) Previously chosen base (user/dev override)
    String? base = prefs.getString(_prefsKey)?.trim();

    // 2) Build-time define: --dart-define=API_BASE=https://example
    base ??= const String.fromEnvironment('API_BASE', defaultValue: '').trim();

    // 3) If empty, auto-detect: prefer local dev if reachable, else prod
    if (base.isEmpty) {
      base = await _autoDetectBase();
      await prefs.setString(_prefsKey, base);
    }

    _current = base;
    _inited = true;
  }

  /// Non-null, single source of truth.
  static Future<String> readBase() async {
    if (!_inited) await init();
    return _current ?? prod;
  }

  /// Persist and use a new base (empty → prod).
  static Future<void> setBase(String base) async {
    final v = base.trim().isEmpty ? prod : base.trim();
    _current = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, v);
  }

  static Future<void> useProd() => setBase(prod);
  static Future<void> useDev() async => setBase(_devDefault());

  // ===== Internals =====
  static String _devDefault() {
    if (kIsWeb) return devWeb;
    if (defaultTargetPlatform == TargetPlatform.android) return devAndroid;
    return devIOSDesktop;
  }

  static Future<String> _autoDetectBase() async {
    final candidate = _devDefault();
    final ok = await _isReachable(candidate);
    return ok ? candidate : prod;
  }

  static Future<bool> _isReachable(String base) async {
    // Try /health first (if you have it), fall back to /
    for (final path in const ['/health', '/']) {
      try {
        final uri = Uri.parse('$base$path');
        final res = await http.get(uri).timeout(const Duration(milliseconds: 600));
        if (res.statusCode >= 200 && res.statusCode < 500) return true;
      } catch (_) {
        // keep trying next path
      }
    }
    return false;
  }
}
