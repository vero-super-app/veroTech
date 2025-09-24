import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/models/address_model.dart';

/// If you previously added ApiBase, you can replace [_buildUri] with it.
Future<Uri> _buildUri(String path) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('https://vero-backend.onrender.com'); // e.g. http://10.0.2.2:3000 or https://vero-backend.onrender.com
  final base = (saved != null && saved.isNotEmpty) ? saved : 'https://vero-backend.onrender.com';
  return Uri.parse('$base$path');
}

class AuthRequiredException implements Exception {
  final String message;
  AuthRequiredException([this.message = 'Authentication required']);
  @override
  String toString() => message;
}

class AddressService {
  Future<String> _getTokenOrThrow() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('jwt_token');
    if (token == null || token.isEmpty) throw AuthRequiredException('No auth token found');
    return token;
  }

  Future<Map<String, String>> _headers() async {
    final t = await _getTokenOrThrow();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $t',
    };
  }

  Never _handleBad(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw AuthRequiredException('Unauthorized or session expired');
    }
    throw Exception('HTTP ${r.statusCode}: ${r.body}');
  }

  // GET /addresses/me
  Future<List<Address>> getMyAddresses() async {
    final u = await _buildUri('/addresses/me');
    final h = await _headers();
    final r = await http.get(u, headers: h).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) _handleBad(r);

    final decoded = jsonDecode(r.body);
    final List list = decoded is List
        ? decoded
        : (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().map(Address.fromJson).toList();
  }

  // POST /addresses
  Future<Address> createAddress(AddressPayload payload) async {
    final u = await _buildUri('/addresses');
    final h = await _headers();
    final r = await http
        .post(u, headers: h, body: jsonEncode(payload.toJson()))
        .timeout(const Duration(seconds: 20));
    if (r.statusCode < 200 || r.statusCode >= 300) _handleBad(r);

    final d = jsonDecode(r.body);
    final map = d is Map<String, dynamic>
        ? d
        : (d is Map && d['data'] is Map)
            ? d['data'] as Map<String, dynamic>
            : <String, dynamic>{};
    return Address.fromJson(map);
  }

  // PUT /addresses/:id
  Future<Address> updateAddress(String id, AddressPayload payload) async {
    final u = await _buildUri('/addresses/$id');
    final h = await _headers();
    final r = await http
        .put(u, headers: h, body: jsonEncode(payload.toJson()))
        .timeout(const Duration(seconds: 20));
    if (r.statusCode < 200 || r.statusCode >= 300) _handleBad(r);

    // Some APIs return 204 (no body); handle gracefully
    if (r.body.isEmpty) {
      // Re-fetch the updated record from /me list:
      final all = await getMyAddresses();
      return all.firstWhere((a) => a.id == id, orElse: () => all.first);
    }

    final d = jsonDecode(r.body);
    final map = d is Map<String, dynamic>
        ? d
        : (d is Map && d['data'] is Map)
            ? d['data'] as Map<String, dynamic>
            : <String, dynamic>{};
    return Address.fromJson(map);
  }

  // DELETE /addresses/:id
  Future<void> deleteAddress(String id) async {
    final u = await _buildUri('/addresses/$id');
    final h = await _headers();
    final r = await http.delete(u, headers: h).timeout(const Duration(seconds: 20));
    if (r.statusCode < 200 || r.statusCode >= 300) _handleBad(r);
  }

  // --- NEW: server-side default flag ---
  Future<void> setDefaultAddress(String id) async {
    // Get the target so we don't accidentally wipe fields
    final addresses = await getMyAddresses();
    final target = addresses.firstWhere((a) => a.id == id, orElse: () => throw Exception('Address not found'));

    // 1) Mark chosen one as default (server should clear others internally)
    await updateAddress(
      id,
      AddressPayload(
        addressType: target.addressType,
        city: target.city,
        description: target.description,
        isDefault: true,
      ),
    );

    // 2) (Optional) Mark all others false if the server doesn't auto-clear
    for (final a in addresses) {
      if (a.id == id) continue;
      // Only send if it was previously default
      if (a.isDefault) {
        await updateAddress(
          a.id,
          AddressPayload(
            addressType: a.addressType,
            city: a.city,
            description: a.description,
            isDefault: false,
          ),
        );
      }
    }
  }
}
