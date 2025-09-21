// lib/services/hostel_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:vero360_app/models/hostel_model.dart'; // defines Accommodation & Owner

class AccommodationService {
  String _localHost() {
    if (kIsWeb) return 'localhost';       // Flutter web
    if (Platform.isAndroid) return '10.0.2.2'; // Android emulator
    return '127.0.0.1';                   // iOS sim / desktop
  }

  Uri _allUri() => Uri(
        scheme: 'http',
        host: _localHost(),
        port: 3000,
        path: '/accommodations/all',
      );

  Future<List<Accommodation>> fetchAll() async {
    final res = await http
        .get(_allUri(), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception(
          'GET /accommodations/all failed: ${res.statusCode} ${res.body}');
    }

    final decoded = json.decode(res.body);
    if (decoded is! List) {
      throw Exception('Unexpected response (expected a JSON array).');
    }

    return decoded
        .map<Accommodation>(
          (e) => Accommodation.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }
}
