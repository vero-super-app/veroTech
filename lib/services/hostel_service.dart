// lib/services/hostel_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vero360_app/models/hostel_model.dart';
import 'package:vero360_app/services/api_config.dart';

class AccommodationService {
  Future<List<Accommodation>> fetchAll() async {
    final base = await ApiConfig.readBase();                // ← uses your config
    final uri  = Uri.parse('$base/accommodations/all');

    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('GET /accommodations/all failed: ${res.statusCode} ${res.body}');
    }

    final decoded = json.decode(res.body);
    if (decoded is! List) {
      throw Exception('Unexpected response (expected JSON array).');
    }

    return decoded
        .map<Accommodation>((e) => Accommodation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
