import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:vero360_app/models/hostel_model.dart';


class HostelService {
  static const String apiUrl = 'https://vero-backend.onrender.com/accommodations';

  Future<List<Hostel>> fetchHostels() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Hostel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load hostels');
    }
  }
}
