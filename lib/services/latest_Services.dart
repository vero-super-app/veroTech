import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Latest_model.dart';

class LatestArrivalServices {
  final String _baseUrl = 'https://vero-backend.onrender.com/latestarrivals';

  Future<List<LatestArrivalModels>> fetchLatestArrivals() async {
    try {
      final uri = Uri.parse(_baseUrl);

      // Make the HTTP GET request with a timeout to handle network delays
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        // Map each item into LatestArrivalModels and return as a list
        return data
            .map((json) =>
                LatestArrivalModels.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Log the response status for debugging
        print('Failed to fetch latest arrivals: ${response.statusCode}');
        throw Exception('Failed to fetch latest arrivals: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      // Handle client-side errors (e.g., network issues)
      print('Client error: $e');
      throw Exception('Error fetching latest arrivals due to client-side issue');
    } on TimeoutException {
      // Handle timeout errors
      print('Error: Request timed out');
      throw Exception('Request timed out. Please try again later.');
    } catch (e) {
      // Handle all other exceptions
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred while fetching latest arrivals: $e');
    }
  }
}
