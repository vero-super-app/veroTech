import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vero360_app/models/order_model.dart';
import 'package:vero360_app/services/api_config.dart';

class AuthRequiredException implements Exception {
  final String message;
  AuthRequiredException([this.message = 'Authentication required']);
  @override
  String toString() => message;
}

class OrderService {
  /* --------------------- infra helpers --------------------- */

  Future<String> _base() async {
    final b = await ApiConfig.readBase();
    return b.isNotEmpty ? b : (ApiConfig.prodBase);
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    const keys = ['jwt_token', 'token', 'authToken', 'merchant_token', 'merchantToken'];
    for (final k in keys) {
      final t = prefs.getString(k);
      if (t != null && t.isNotEmpty) return t;
    }
    throw AuthRequiredException('No auth token found');
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isMerchant() async {
    // 1) Prefer explicit flags saved during login
    final prefs = await SharedPreferences.getInstance();
    final explicit = (prefs.getBool('is_merchant') ?? prefs.getBool('merchant')) == true;
    if (explicit) return true;

    final roleStr = (prefs.getString('role') ?? prefs.getString('userRole') ?? '').toLowerCase();
    if (roleStr.contains('merchant')) return true;

    // 2) Fallback: inspect JWT claims
    try {
      final t = await _token();
      final p = _decodeJwtPayload(t);
      if (p != null) {
        if (p['isMerchant'] == true) return true;
        final role = (p['role'] ?? '').toString().toLowerCase();
        if (role.contains('merchant')) return true;
        final roles = p['roles'];
        if (roles is List && roles.map((e) => '$e'.toLowerCase()).contains('merchant')) return true;
        final scope = (p['scope'] ?? '').toString().toLowerCase();
        if (scope.contains('merchant')) return true;
        final perms = p['permissions'];
        if (perms is List && perms.map((e) => '$e'.toLowerCase()).contains('merchant')) return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, String>> _headers() async => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      };

  Never _bad(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw AuthRequiredException('Unauthorized or session expired');
    }
    throw Exception('HTTP ${r.statusCode}: ${r.body}');
  }

  Future<http.Response> _retry(Future<http.Response> Function() run, {int retries = 2}) async {
    int attempt = 0;
    while (true) {
      try {
        final res = await run().timeout(const Duration(seconds: 60));
        if ((res.statusCode == 502 || res.statusCode == 503 || res.statusCode == 504) && attempt < retries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 600 * attempt));
          continue;
        }
        return res;
      } on TimeoutException {
        if (attempt < retries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 600 * attempt));
          continue;
        }
        rethrow;
      } on SocketException catch (e) {
        if (attempt < retries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 600 * attempt));
          continue;
        }
        throw Exception('Network error: $e');
      } on http.ClientException catch (e) {
        if (attempt < retries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 600 * attempt));
          continue;
        }
        throw Exception('HTTP client error: $e');
      }
    }
  }

  /* --------------------- public API --------------------- */

  // Chooses the right “me” endpoint by role.
  Future<List<OrderItem>> getMyOrders({OrderStatus? status}) async {
    final base = await _base();
    final isMerchant = await _isMerchant();
    final path = isMerchant ? '/orders/merchant/me' : '/orders/me';

    final qp = status != null ? {'status': orderStatusToApi(status)} : null;
    final u = Uri.parse('$base$path').replace(queryParameters: qp);
    final h = await _headers();

    final r = await _retry(() => http.get(u, headers: h));
    if (r.statusCode != 200) _bad(r);

    final decoded = jsonDecode(r.body);
    final List list = decoded is List
        ? decoded
        : (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : (decoded is Map ? [decoded] : <dynamic>[]);

    final all = list.whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList();

    // If backend ignored the filter, narrow client-side.
    if (status != null) {
      return all.where((o) => o.status == status).toList();
    }
    return all;
  }

  // PATCH /orders/{id}/status (works for either role if permitted server-side)
  Future<void> updateStatus(String id, OrderStatus next) async {
    final u = Uri.parse('${await _base()}/orders/$id/status');
    final h = await _headers();
    final body = jsonEncode({'Status': orderStatusToApi(next)}); // keep your server's expected key casing
    final r = await _retry(() => http.patch(u, headers: h, body: body));
    if (r.statusCode < 200 || r.statusCode >= 300) _bad(r);
  }

  // Cancel, else delete as fallback.
  Future<bool> cancelOrMarkCancelled(String id) async {
    try {
      await updateStatus(id, OrderStatus.cancelled);
      return true;
    } on AuthRequiredException {
      rethrow;
    } catch (_) {
      final u = Uri.parse('${await _base()}/orders/$id');
      final h = await _headers();
      final r = await _retry(() => http.delete(u, headers: h));
      if (r.statusCode < 200 || r.statusCode >= 300) _bad(r);
      return false;
    }
  }
}
