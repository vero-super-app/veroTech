// lib/services/cart_services.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_model.dart';

/// Timeouts tuned for Render cold starts
const _kFirstTimeout = Duration(seconds: 60); // first attempt
const _kRetryTimeout = Duration(seconds: 30); // subsequent attempts

class CartService {
  /// Example: 'https://vero-backend.onrender.com'  (NO trailing slash)
  /// Local Android emulator: 'http://10.0.2.2:3000'
  final String baseOrigin;

  /// If your Nest app uses a global prefix: app.setGlobalPrefix('api')
  /// pass 'api'; otherwise leave ''.
  final String apiPrefix;

  CartService(this.baseOrigin, {this.apiPrefix = ''});

  // Warm-up is memoized per app session
  static bool _warmedUp = false;

  // ----------------- Helpers -----------------
  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('jwt_token');
  }

  Future<String?> _getUserIdFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_id'); // set on login if you store it
  }

  /// Resolve userId: prefs first, else decode JWT (sub/id/userId/uid)
  Future<String?> _resolveUserId() async {
    final fromPrefs = await _getUserIdFromPrefs();
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;

    final token = await _getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.padRight(payload.length + ((4 - payload.length % 4) % 4), '=');
      final map = json.decode(utf8.decode(base64Url.decode(payload)));
      return (map['userId'] ?? map['sub'] ?? map['id'] ?? map['uid'])?.toString();
    } catch (_) {
      return null;
    }
  }

  Uri _buildUri(String path, [Map<String, String>? q]) {
    final base = baseOrigin.endsWith('/')
        ? baseOrigin.substring(0, baseOrigin.length - 1)
        : baseOrigin;
    final prefix = apiPrefix.isNotEmpty ? '/$apiPrefix' : '';
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$prefix$normalized');
    return q == null ? uri : uri.replace(queryParameters: {...uri.queryParameters, ...q});
  }

  Map<String, String> _headers({String? token}) => {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        // helps avoid proxy keep-alive resets
        'Connection': 'close',
        'User-Agent': 'Vero360App/1.0 (+cart)',
      };

  Future<http.Response> _withRetry(
    Future<http.Response> Function() run, {
    int retries = 3,
    List<Duration>? timeouts,
  }) async {
    Object? lastErr;
    for (var attempt = 0; attempt <= retries; attempt++) {
      final timeout = (timeouts != null && attempt < timeouts.length)
          ? timeouts[attempt]
          : _kRetryTimeout;
      try {
        final res = await run().timeout(timeout);
        return res;
      } on SocketException catch (e) {
        lastErr = e;
      } on http.ClientException catch (e) {
        lastErr = e;
      } on TimeoutException catch (e) {
        lastErr = e;
      }
      // backoff: 0.6s, 1.2s, 1.8s, ...
      await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
    }
    throw Exception('Network error after retries: $lastErr');
  }

  List<dynamic> _extractList(String body) {
    final decoded = json.decode(body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'] as List<dynamic>;
    throw Exception('Unexpected response: $body');
  }

  // ----------------- Warm-up -----------------
  /// Ping a public endpoint so Render can wake before authed calls.
  Future<void> warmup() async {
    if (_warmedUp) return;

    final health = _buildUri('/healthz');
    final market = _buildUri('/marketplace'); // fallback if no /healthz

    try {
      print('WARMUP: GET $health');
      final r = await http.get(health, headers: _headers()).timeout(_kFirstTimeout);
      print('WARMUP /healthz => ${r.statusCode}');
      _warmedUp = true;
      return;
    } catch (e) {
      print('WARMUP /healthz failed: $e');
    }

    try {
      print('WARMUP: GET $market');
      final r = await http.get(market, headers: _headers()).timeout(_kFirstTimeout);
      print('WARMUP /marketplace => ${r.statusCode}');
      _warmedUp = true;
    } catch (e) {
      // don't throw; main call will retry with longer timeouts
      print('WARMUP /marketplace failed: $e');
    }
  }

  // ----------------- API -----------------

  /// Upsert/add item in cart (server may treat as "set quantity")
  Future<void> addToCart(CartModel cartItem) async {
    await warmup();

    final token = await _getToken();
    if (token == null) throw Exception('User not logged in');

    final uid = cartItem.userId.isNotEmpty ? cartItem.userId : (await _resolveUserId());
    if (uid == null) throw Exception('Cannot resolve userId');

    final uri = _buildUri('/cart');
    print('CART POST => $uri');

    final res = await _withRetry(
      () => http.post(
        uri,
        headers: _headers(token: token),
        body: json.encode({
          'userId': uid,
          'item': cartItem.item,
          'quantity': cartItem.quantity,
          'name': cartItem.name,
          'image': cartItem.image,
          'price': cartItem.price,
          'description': cartItem.description,
          'comment': cartItem.comment,
        }),
      ),
      retries: 3,
      timeouts: const [_kFirstTimeout, _kRetryTimeout, _kRetryTimeout, _kRetryTimeout],
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to add to cart (${res.statusCode}): ${res.body}');
    }
  }

  /// Fetch the current user's cart
  Future<List<CartModel>> fetchCartItems({String? userId}) async {
    await warmup();

    final token = await _getToken();
    if (token == null) throw Exception('User not logged in');

    final uid = userId ?? await _resolveUserId();
    final uri = _buildUri('/cart', { if (uid != null) 'userId': uid });

    print('CART GET => $uri');

    final res = await _withRetry(
      () => http.get(uri, headers: _headers(token: token)),
      retries: 3,
      timeouts: const [_kFirstTimeout, _kRetryTimeout, _kRetryTimeout, _kRetryTimeout],
    );

    if (res.statusCode == 200) {
      final list = _extractList(res.body);
      return list.map((e) => CartModel.fromJson(e)).toList();
    }

    throw Exception('Failed to fetch cart (${res.statusCode}): ${res.body}');
  }

  /// Remove a single item from the cart
  Future<void> removeFromCart(int itemId, {String? userId}) async {
    await warmup();

    final token = await _getToken();
    if (token == null) throw Exception('User not logged in');

    final uid = userId ?? await _resolveUserId();
    final uri = _buildUri('/cart/$itemId', { if (uid != null) 'userId': uid });

    print('CART DELETE => $uri');

    final res = await _withRetry(
      () => http.delete(uri, headers: _headers(token: token)),
      retries: 3,
      timeouts: const [_kFirstTimeout, _kRetryTimeout, _kRetryTimeout, _kRetryTimeout],
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to remove item (${res.statusCode}): ${res.body}');
    }
  }

  /// Clear the entire cart (if backend supports DELETE /cart)
  Future<void> clearCart({String? userId}) async {
    await warmup();

    final token = await _getToken();
    if (token == null) throw Exception('User not logged in');

    final uid = userId ?? await _resolveUserId();
    final uri = _buildUri('/cart', { if (uid != null) 'userId': uid });

    print('CART CLEAR => $uri');

    final res = await _withRetry(
      () => http.delete(uri, headers: _headers(token: token)),
      retries: 3,
      timeouts: const [_kFirstTimeout, _kRetryTimeout, _kRetryTimeout, _kRetryTimeout],
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to clear cart (${res.statusCode}): ${res.body}');
    }
  }
}
