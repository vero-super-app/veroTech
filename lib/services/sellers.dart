import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SellersApplicationFormService {
  final String _baseUrl = 'http://127.0.0.1:3000/sellers/create';

  Future<bool> postSellersApplicationForm(Map<String, dynamic> formData) async {
    try {
      final uri = Uri.parse(_baseUrl);

      // Send HTTP POST request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print('Seller application form submitted successfully');
        return true;
      } else {
        print('Failed to submit seller application form: ${response.statusCode}');
        throw Exception('Failed to submit form: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      print('Client error: $e');
      throw Exception('Error submitting form due to client-side issue');
    } on TimeoutException {
      print('Error: Request timed out');
      throw Exception('Request timed out. Please try again later.');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred while submitting the form: $e');
    }
  }
}
