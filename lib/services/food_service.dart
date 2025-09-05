import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vero360_app/models/food_model.dart';

import '../models/marketplace.model.dart';

class FoodService {
  final String _baseUrl = 'http://127.0.0.1:3000/orders';

  // Fetch list of market items
  Future<List<FoodModel>> fetchFoodItems() async {
    try {
      final uri = Uri.parse(_baseUrl);

      // Make the HTTP GET request with a timeout to handle network delays
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        // Map each item into MarketPlaceModel and return as a list
        return data.map((json) => FoodModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        // Log the response status for debugging
        print('Failed to food f items: ${response.statusCode}');
        throw Exception('Failed to fetch food items: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      // Handle client-side errors (e.g., network issues)
      print('Client error: $e');
      throw Exception('Error fetching food items due to client-side issue');
    } on TimeoutException {
      // Handle timeout errors
      print('Error: Request timed out');
      throw Exception('Request timed out. Please try again later.');
    } catch (e) {
      // Handle all other exceptions
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred while fetching food items: $e');
    }
  }

  fetchLatestArrivals() {}
}
