import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:vero360_app/toasthelper.dart';

class SellersApplicationFormService {
  final String _baseUrl = 'http://127.0.0.1:3000/sellers/create';

  Future<bool> postSellersApplicationForm(
    Map<String, dynamic> formData,
    BuildContext context,
  ) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(formData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        ToastHelper.showCustomToast(
          context,
          "Merchant Application submitted successfully ✅",
          isSuccess: true,
        );
        return true;
      } else {
        final body = _prettyError(response.body);
        ToastHelper.showCustomToast(
          context,
          "Failed to submit form ❌: $body",
          isSuccess: false,
        );
        throw Exception(
          'Failed: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on http.ClientException catch (e) {
      ToastHelper.showCustomToast(
        context,
        'Client error ❌: $e',
        isSuccess: false,
      );
      throw Exception('Client-side issue: $e');
    } on TimeoutException {
      ToastHelper.showCustomToast(
        context,
        'Request timed out ⏳. Please try again.',
        isSuccess: false,
      );
      throw Exception('Timeout');
    } catch (e) {
      ToastHelper.showCustomToast(
        context,
        'Unexpected error ❌: $e',
        isSuccess: false,
      );
      throw Exception('Unexpected: $e');
    }
  }

  String _prettyError(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        return parsed['message']?.toString() ??
            parsed['error']?.toString() ??
            body;
      }
      if (parsed is List && parsed.isNotEmpty) {
        return parsed.first.toString();
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}
