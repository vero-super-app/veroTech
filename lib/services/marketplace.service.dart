import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/marketplace.model.dart';

class ApiConfig {
  // Toggle this to true to hit your Render backend instead of local dev
  static const bool useProd = false;

  static String _localHost() {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000'; // Android emulator
    return 'http://localhost:3000'; // iOS simulator / desktop
  }

  static String get baseUrl =>
      (useProd ? 'https://vero-backend.onrender.com' : _localHost()) +
      '/marketplace';
}

class MarketplaceService {
  final String baseUrl;
  MarketplaceService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // Helper: throws on non-200 and returns decoded json
  dynamic _decodeOrThrow(http.Response r, {String where = ''}) {
    if (r.statusCode != 200) {
      throw Exception(
          'HTTP ${r.statusCode} at $where: ${r.body.isNotEmpty ? r.body : 'No body'}');
    }
    try {
      return json.decode(r.body);
    } catch (e) {
      throw Exception('JSON decode error at $where: $e');
    }
  }

  Future<List<MarketplaceDetailModel>> searchByPhoto(File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/search/photo');
      final request = http.MultipartRequest('POST', url.toString().startsWith('http') ? url : Uri.parse(url.toString()));
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final body = _decodeOrThrow(resp, where: 'POST $url');
      final list = body['data'];
      if (list is List) {
        return list.map((e) => MarketplaceDetailModel.fromJson(e)).toList().cast<MarketplaceDetailModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error photo-search: $e');
      return [];
    }
  }
  

  Future<MarketplaceDetailModel?> getItemDetails(int itemId) async {
    try {
      final url = Uri.parse('$baseUrl/$itemId');
      final r = await http.get(url);
      final body = _decodeOrThrow(r, where: 'GET $url');
      final data = body['data'];
      if (data == null) return null;
      return MarketplaceDetailModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching item details: $e');
      return null;
    }
  }

  /// List ALL items  -> GET /marketplace
  Future<List<MarketplaceDetailModel>> fetchMarketItems() async {
    try {
      final url = Uri.parse(baseUrl);
      final r = await http.get(url);
      final body = _decodeOrThrow(r, where: 'GET $url');

      final list = body['data'];
      if (list is List) {
        return list
            .map((e) => MarketplaceDetailModel.fromJson(e))
            .toList()
            .cast<MarketplaceDetailModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching market items: $e');
      return [];
    }
  }

  /// Name-only search  -> GET /marketplace/search/:name
  Future<List<MarketplaceDetailModel>> searchByName(String name) async {
    try {
      final safe = Uri.encodeComponent(name.trim());
      final url = Uri.parse('$baseUrl/search/$safe');
      final r = await http.get(url);
      final body = _decodeOrThrow(r, where: 'GET $url');

      final list = body['data'];
      if (list is List) {
        return list
            .map((e) => MarketplaceDetailModel.fromJson(e))
            .toList()
            .cast<MarketplaceDetailModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching items: $e');
      return [];
    }
  }
}
