import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vero360_app/models/mybooking_model.dart';
import 'package:vero360_app/services/api_config.dart';

class AuthRequiredException implements Exception {
  final String message;
  AuthRequiredException([this.message = 'Authentication required']);
  @override
  String toString() => message;
}

class MyBookingService {
  Future<String> _base() async {
    final b = await ApiConfig.readBase();
    return b.isEmpty ? ApiConfig.prod : b;
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('jwt_token') ?? prefs.getString('token');
    if (t == null || t.isEmpty) throw AuthRequiredException('No auth token found');
    return t;
  }

  Future<Map<String, String>> _headers() async => {
    'Accept'       : 'application/json',
    'Content-Type' : 'application/json',
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
        final res = await run().timeout(const Duration(seconds: 45));
        if ((res.statusCode == 502 || res.statusCode == 503 || res.statusCode == 504) && attempt < retries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        return res;
      } on TimeoutException {
        if (attempt < retries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        rethrow;
      } on SocketException {
        if (attempt < retries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        rethrow;
      }
    }
  }

  /// GET /bookings/me  (?status=pending|confirmed|cancelled|completed)
  Future<List<BookingItem>> getMyBookings({BookingStatus? status}) async {
    final base = await _base();
    final qp   = status != null ? {'status': bookingStatusToApi(status)} : null;
    final u    = Uri.parse('$base/bookings/me').replace(queryParameters: qp);
    final h    = await _headers();

    final r = await _retry(() => http.get(u, headers: h));
    if (r.statusCode != 200) _bad(r);

    final decoded = jsonDecode(r.body);
    final List list = decoded is List
        ? decoded
        : (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : (decoded is Map ? [decoded] : <dynamic>[]);

    return list.whereType<Map<String, dynamic>>().map(BookingItem.fromJson).toList();
  }

  /// POST /bookings (returns BookingItem).
  /// If you need a different endpoint for another flow, pass [overridePath].
  Future<BookingItem> createBooking(
    BookingCreatePayload payload, {
    String? overridePath,
  }) async {
    final base = await _base();
    final path = overridePath ?? '/bookings';
    final u    = Uri.parse('$base$path');
    final h    = await _headers();

    final r = await _retry(() => http.post(u, headers: h, body: jsonEncode(payload.toJson())));
    if (r.statusCode < 200 || r.statusCode >= 300) _bad(r);

    final d = jsonDecode(r.body);
    final map = (d is Map<String, dynamic>)
        ? d
        : (d is Map && d['data'] is Map)
            ? d['data'] as Map<String, dynamic>
            : <String, dynamic>{};
    return BookingItem.fromJson(map);
  }

  /// PATCH /bookings/{id}/status
  Future<void> updateStatus(String id, BookingStatus next) async {
    final u = Uri.parse('${await _base()}/bookings/$id/status');
    final h = await _headers();
    final body = jsonEncode({'status': bookingStatusToApi(next)}); // change to "Status" if your API requires
    final r = await _retry(() => http.patch(u, headers: h, body: body));
    if (r.statusCode < 200 || r.statusCode >= 300) _bad(r);
  }

  /// DELETE /bookings/{id}
  Future<void> deleteBooking(String id) async {
    final u = Uri.parse('${await _base()}/bookings/$id');
    final h = await _headers();
    final r = await _retry(() => http.delete(u, headers: h));
    if (r.statusCode < 200 || r.statusCode >= 300) _bad(r);
  }

  /// Try to cancel via status; if not supported, delete.
  Future<bool> cancelOrDelete(String id) async {
    try {
      await updateStatus(id, BookingStatus.cancelled);
      return true;
    } catch (_) {
      await deleteBooking(id);
      return false;
    }
  }
}
