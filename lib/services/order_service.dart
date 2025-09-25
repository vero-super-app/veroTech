import 'dart:async';
import 'dart:io';
import 'dart:convert';
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
  Future<String> _base() async {
    final v = await ApiConfig.readBase();
    return v.isEmpty ? ApiConfig.prodBase : v;
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('jwt_token') ?? prefs.getString('token');
    if (t == null || t.isEmpty) throw AuthRequiredException('No auth token found');
    return t;
  }

  Future<Map<String,String>> _headers() async => {
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
        if ((res.statusCode == 502 || res.statusCode == 503 || res.statusCode == 504) &&
            attempt < retries) {
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

  // GET /orders/me  (optional server-side filter: ?status=pending|confirmed|delivered|cancelled)
  Future<List<OrderItem>> getMyOrders({OrderStatus? status}) async {
    final base = await _base();
    final qp = status != null ? {'status': orderStatusToApi(status)} : null;
    final u = Uri.parse('$base/orders/me').replace(queryParameters: qp);
    final h = await _headers();

    final r = await _retry(() => http.get(u, headers: h));
    if (r.statusCode != 200) _bad(r);

    final decoded = jsonDecode(r.body);

    // Accept: List, {data:[...]}, or single object (wrap it)
    final List list = decoded is List
        ? decoded
        : (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : (decoded is Map ? [decoded] : <dynamic>[]);

    final all = list.whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList();

    // If backend ignored the filter, group client-side
    if (status != null) {
      return all.where((o) => o.status == status).toList();
    }
    return all;
  }

  // ONLY show the changed/added parts

  // PATCH /orders/{id}/status
  Future<void> updateStatus(String id, OrderStatus next) async {
    final u = Uri.parse('${await _base()}/orders/$id/status');
    final h = await _headers();
    final body = jsonEncode({'Status': orderStatusToApi(next)}); // backend expects "Status"

    final r = await _retry(() => http.patch(u, headers: h, body: body));
    if (r.statusCode < 200 || r.statusCode >= 300) _bad(r);
  }

  /// Cancel order:
  /// - Prefer PATCH -> cancelled (so it appears in "Cancelled")
  /// - Fallback to DELETE if PATCH not supported
  /// Returns: true if moved to Cancelled (patched), false if deleted.
  Future<bool> cancelOrMarkCancelled(String id) async {
    try {
      await updateStatus(id, OrderStatus.cancelled);
      return true; // now should show under Cancelled
    } on AuthRequiredException {
      rethrow;
    } catch (e) {
      // PATCH failed — try DELETE as a fallback
      final u = Uri.parse('${await _base()}/orders/$id');
      final h = await _headers();
      final r = await _retry(() => http.delete(u, headers: h));
      if (r.statusCode < 200 || r.statusCode >= 300) _bad(r);
      return false; // deleted entirely (won’t appear in Cancelled)
    }
  }

}
