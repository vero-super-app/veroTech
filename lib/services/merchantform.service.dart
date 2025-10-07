// lib/services/merchantform.service.dart
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/toasthelper.dart';

class ServiceProviderService {
  final String baseUrl;
  ServiceProviderService({required this.baseUrl});

  /// Multipart POST /serviceprovider
  /// fields (strings): businessName, businessDescription, openingHours, status
  /// files:
  ///  - nationalIdImage  (REQUIRED)
  ///  - logoimage        (optional)
  Future<bool> submitServiceProviderMultipart({
    required Map<String, String> fields,
    required XFile nationalIdFile,
    XFile? logoFile,
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? prefs.getString('token') ?? '';
      if (token.isEmpty) {
        ToastHelper.showCustomToast(context, 'Please log in again', isSuccess: false, errorMessage: '');
        return false;
      }

      // Strictly only accepted keys (whitelist to avoid 400 "should not exist")
      final allowed = <String>{
        'businessName',
        'businessDescription',
        'openingHours',
        'status',
      };
      final sanitized = <String, String>{};
      fields.forEach((k, v) {
        if (allowed.contains(k) && v.trim().isNotEmpty) {
          sanitized[k] = v.trim();
        }
      });

      final uri = Uri.parse('$baseUrl/serviceprovider');
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'accept': '*/*',
        })
        ..fields.addAll(sanitized);

      // Attach files with EXACT Multer field names:
      // nationalIdImage (required)
      if (kIsWeb) {
        final bytes = await nationalIdFile.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes(
          'nationalIdImage',
          bytes,
          filename: nationalIdFile.name.isEmpty ? 'national-id.jpg' : nationalIdFile.name,
        ));
        if (logoFile != null) {
          final lbytes = await logoFile.readAsBytes();
          req.files.add(http.MultipartFile.fromBytes(
            'logoimage',
            lbytes,
            filename: logoFile.name.isEmpty ? 'logo.jpg' : logoFile.name,
          ));
        }
      } else {
        req.files.add(await http.MultipartFile.fromPath('nationalIdImage', nationalIdFile.path));
        if (logoFile != null) {
          req.files.add(await http.MultipartFile.fromPath('logoimage', logoFile.path));
        }
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      // Friendly errors (400 validation / 413 big images / others)
      String message = _extractMessage(res.body);
      if (res.statusCode == 413) {
        message = 'Images are too large. Please pick a smaller photo.';
      }
      ToastHelper.showCustomToast(
        context,
        'Failed to submit: ${res.statusCode} ${message}',
        isSuccess: false,
        errorMessage: '',
      );
      return false;
    } catch (e) {
      ToastHelper.showCustomToast(context, 'Network error: $e', isSuccess: false, errorMessage: '');
      return false;
    }
  }

  String _extractMessage(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        final m = parsed['message'];
        if (m is List) return m.join(', ');
        if (m is String) return m;
        return parsed['error']?.toString() ?? body;
      }
      if (parsed is List) return parsed.join(', ');
      return body;
    } catch (_) {
      return body;
    }
  }
}
