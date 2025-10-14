import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/marketplace.model.dart';
import 'api_config.dart';

class MarketplaceService {
  dynamic _decodeOrThrow(http.Response r, {String where = ''}) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode} at $where: ${r.body.isNotEmpty ? r.body : 'No body'}');
    }
    if (r.statusCode == 204 || r.body.isEmpty) return const {};
    try {
      return json.decode(r.body);
    } catch (e) {
      throw Exception('JSON decode error at $where: $e');
    }
  }

  // CREATE -> POST {base}/marketplace
  Future<MarketplaceDetailModel> createItem(MarketplaceItem item) async {
    final base = await ApiConfig.readBase();
    final uri = Uri.parse('$base/marketplace');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    final body = _decodeOrThrow(r, where: 'POST $uri');
    final data = (body is Map ? (body['data'] ?? body) : body) as Map<String, dynamic>;
    return MarketplaceDetailModel.fromJson(data);
  }

  // DELETE -> DELETE {base}/marketplace/:id
  Future<void> deleteItem(int id) async {
    final base = await ApiConfig.readBase();
    final uri = Uri.parse('$base/marketplace/$id');
    final r = await http.delete(uri);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Delete failed (${r.statusCode}) at $uri: ${r.body}');
    }
  }

  // Upload -> POST {base}/uploads (multipart "file") => {url}
  Future<String> uploadImageFile(File imageFile, {String filename = 'upload.jpg'}) async {
    final base = await ApiConfig.readBase();
    final uri = Uri.parse('$base/uploads');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    final body = _decodeOrThrow(resp, where: 'POST $uri');
    final url = body is Map ? (body['url']?.toString()) : null;
    if (url == null || url.isEmpty) throw Exception('Upload ok but no "url" returned');
    return url;
  }

  // === KEEP: Search by photo ===
  Future<List<MarketplaceDetailModel>> searchByPhoto(File imageFile) async {
    try {
      final base = await ApiConfig.readBase();
      final url = Uri.parse('$base/marketplace/search/photo');
      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final body = _decodeOrThrow(resp, where: 'POST $url');
      final list = body is Map ? body['data'] : null;
      if (list is List) {
        return list.map((e) => MarketplaceDetailModel.fromJson(e)).toList().cast<MarketplaceDetailModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error photo-search: $e');
      return [];
    }
  }

  // === KEEP: Search by name ===
  Future<List<MarketplaceDetailModel>> searchByName(String name) async {
    try {
      final base = await ApiConfig.readBase();
      final safe = Uri.encodeComponent(name.trim());
      final url = Uri.parse('$base/marketplace/search/$safe');
      final r = await http.get(url);
      final body = _decodeOrThrow(r, where: 'GET $url');
      final list = body is Map ? body['data'] : null;
      if (list is List) {
        return list.map((e) => MarketplaceDetailModel.fromJson(e)).toList().cast<MarketplaceDetailModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching items: $e');
      return [];
    }
  }

  // Optional read helpers
  Future<MarketplaceDetailModel?> getItemDetails(int itemId) async {
    try {
      final base = await ApiConfig.readBase();
      final url = Uri.parse('$base/marketplace/$itemId');
      final r = await http.get(url);
      final body = _decodeOrThrow(r, where: 'GET $url');
      final data = body is Map ? body['data'] : null;
      if (data == null) return null;
      return MarketplaceDetailModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching item details: $e');
      return null;
    }
  }

  Future<List<MarketplaceDetailModel>> fetchMarketItems() async {
    try {
      final base = await ApiConfig.readBase();
      final url = Uri.parse('$base/marketplace');
      final r = await http.get(url);
      final body = _decodeOrThrow(r, where: 'GET $url');
      final list = body is Map ? body['data'] : null;
      if (list is List) {
        return list.map((e) => MarketplaceDetailModel.fromJson(e)).toList().cast<MarketplaceDetailModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching market items: $e');
      return [];
    }
  }
}
