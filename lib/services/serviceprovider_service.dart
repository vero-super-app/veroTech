// lib/services/serviceprovider_service.dart  (drop-in replacement)
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/services/api_config.dart';

import '../models/serviceprovider_model.dart';

class ServiceProviderServicess {
  // Build a full URI from the configured base + path (handles slashes)
  static Future<Uri> _u(String path) async {
    final base = await ApiConfig.readBase();                 // e.g. http://10.0.2.2:3000
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$b$p');
  }

  static Future<String?> _getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('jwt') ?? sp.getString('token');
  }

  static Future<ServiceProvider?> fetchMine() async {
    final t = await _getToken();
    final uri = await _u('/serviceprovider/me');
    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (t != null) 'Authorization': 'Bearer $t',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = (body is Map && body['data'] != null) ? body['data'] : body;
      if (data == null) return null;
      return ServiceProvider.fromJson(data);
    }
    if (res.statusCode == 404) return null;
    throw Exception('fetchMine failed: ${res.statusCode} ${res.body}');
  }

  static Future<ServiceProvider> create({
    required String businessName,
    String? businessDescription,
    String? status,
    required String openingHours,
    String? logoPath,          // mobile/desktop
    Uint8List? logoBytes,      // web
    String? logoFileName,
  }) async {
    final t = await _getToken();
    final uri = await _u('/serviceprovider');
    final req = http.MultipartRequest('POST', uri);
    if (t != null) req.headers['Authorization'] = 'Bearer $t';
    req.headers['Accept'] = 'application/json';

    req.fields['businessName'] = businessName;
    req.fields['openingHours'] = openingHours;
    if (businessDescription != null) req.fields['businessDescription'] = businessDescription;
    if (status != null) req.fields['status'] = status;

    if (!kIsWeb && logoPath != null) {
      req.files.add(await http.MultipartFile.fromPath(
        'logoImage',
        logoPath,
        filename: logoFileName ?? logoPath.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      ));
    } else if (kIsWeb && logoBytes != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'logoImage',
        logoBytes,
        filename: logoFileName ?? 'logo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return ServiceProvider.fromJson(data);
    }
    throw Exception('create failed: ${res.statusCode} ${res.body}');
  }

  static Future<ServiceProvider> update(
    int id, {
    String? businessName,
    String? businessDescription,
    String? status,
    String? openingHours,
    String? logoPath,
    Uint8List? logoBytes,
    String? logoFileName,
  }) async {
    final t = await _getToken();
    final uri = await _u('/serviceprovider/$id');
    final req = http.MultipartRequest('PATCH', uri);
    if (t != null) req.headers['Authorization'] = 'Bearer $t';
    req.headers['Accept'] = 'application/json';

    if (businessName != null) req.fields['businessName'] = businessName;
    if (businessDescription != null) req.fields['businessDescription'] = businessDescription;
    if (status != null) req.fields['status'] = status;
    if (openingHours != null) req.fields['openingHours'] = openingHours;

    if (!kIsWeb && logoPath != null) {
      req.files.add(await http.MultipartFile.fromPath(
        'logoImage',
        logoPath,
        filename: logoFileName ?? logoPath.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      ));
    } else if (kIsWeb && logoBytes != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'logoImage',
        logoBytes,
        filename: logoFileName ?? 'logo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = body['data'] ?? body;
      return ServiceProvider.fromJson(data);
    }
    throw Exception('update failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> deleteById(int id) async {
    final t = await _getToken();
    final uri = await _u('/serviceprovider/$id');
    final res = await http.delete(
      uri,
      headers: {
        if (t != null) 'Authorization': 'Bearer $t',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode != 200) {
      debugPrint('delete failed: ${res.statusCode} ${res.body}');
      throw Exception('delete failed');
    }
  }
}
