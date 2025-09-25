import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Defaults
  static const String prod = 'https://vero-backend.onrender.com';
  static const String devAndroid = 'http://10.0.2.2:3000';
  static const String devIOSDesktop = 'http://127.0.0.1:3000';

  static const String _prefsKey = 'api_base';
  static String? _current;
  static bool _inited = false;

  /// Call once early (e.g., in main()) or let readBase() lazy-init.
  static Future<void> init() async {
    if (_inited) return;
    final prefs = await SharedPreferences.getInstance();

    // 1) If user/dev explicitly set a base earlier, use it.
    var base = prefs.getString(_prefsKey);

    // 2) If not set, honor build-time dart define: --dart-define=API_BASE=...
    base ??= const String.fromEnvironment('API_BASE', defaultValue: '');

    // 3) If still empty, auto-detect: try local dev quickly, else use prod
    if (base.isEmpty) {
      base = await _autoDetectBase();
      // Persist so all services use the same value consistently
      await prefs.setString(_prefsKey, base);
    }

    _current = base;
    _inited = true;
  }

  static Future<String> readBase() async {
    if (!_inited) await init();
    return _current!;
  }

  static Future<void> setBase(String base) async {
    _current = base;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, base);
  }

  static Future<void> useProd() => setBase(prod);
  static Future<void> useDev() async => setBase(_devDefault());

  // ===== Internals =====
  static String _devDefault() {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return devAndroid;
    return devIOSDesktop;
  }

  static Future<String> _autoDetectBase() async {
    // Try dev first; if reachable, use it. Otherwise prod.
    final candidate = _devDefault();
    final ok = await _isReachable(candidate);
    return ok ? candidate : prod;
  }

  static Future<bool> _isReachable(String base) async {
    try {
      // Try a cheap endpoint; change to /health if you expose one
      final uri = Uri.parse('$base/');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 600));
      return res.statusCode >= 200 && res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
