import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/marketplace.model.dart';
import 'api_config.dart';

class MarketplaceService {
  // ---- auth helpers ----
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ??
           prefs.getString('token') ??
           '';
  }

  Map<String, String> _authHeaders(String token, {Map<String, String>? extra}) {
    return {
      'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

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

  // ========= UPLOADS =========

  /// Upload from BYTES (works for HEIC and temp files that disappear)
  Future<String> uploadBytes(Uint8List bytes, {required String filename, String? mimeType}) async {
    final base = await ApiConfig.readBase();
    final token = await _token();
    final uri = Uri.parse('$base/uploads');
    final mime = lookupMimeType(filename, headerBytes: bytes);
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders(token))
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: mime != null ? MediaType.parse(mime) : null,
      ));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    final body = _decodeOrThrow(resp, where: 'POST $uri');
    final url = body is Map ? (body['url']?.toString()) : null;
    if (url == null || url.isEmpty) {
      throw Exception('Upload ok but no "url" returned');
    }
    return url;
  }

  /// Old helper: keep for compatibility if you *really* have a stable file path.
  /// Prefer [uploadBytes] to avoid PathNotFound on temp files.
  Future<String> uploadImageFile(File imageFile, {String filename = 'upload.jpg'}) async {
    final base = await ApiConfig.readBase();
    final token = await _token();
    final uri = Uri.parse('$base/uploads');

    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders(token))
      ..files.add(await http.MultipartFile.fromPath(
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

  String _safeDefaultNameFromMime(String mime) {
    if (mime.contains('png')) return 'upload.png';
    if (mime.contains('webp')) return 'upload.webp';
    if (mime.contains('heic') || mime.contains('heif')) return 'upload.heic';
    if (mime.contains('gif')) return 'upload.gif';
    if (mime.startsWith('video/')) return 'upload.mp4';
    return 'upload.jpg';
  }

  // ========= SECURED (owner enforced server-side) =========

  /// CREATE now accepts gallery/videos arrays (if provided in `item`)
  Future<MarketplaceDetailModel> createItem(MarketplaceItem item) async {
    final base = await ApiConfig.readBase();
    final token = await _token();
    final uri = Uri.parse('$base/marketplace');

    final r = await http.post(
      uri,
      headers: _authHeaders(token, extra: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }),
      body: jsonEncode(item.toJson()),
    );

    final body = _decodeOrThrow(r, where: 'POST $uri');
    final data = (body is Map ? (body['data'] ?? body) : body) as Map<String, dynamic>;
    return MarketplaceDetailModel.fromJson(data);
  }

  /// DELETE -> DELETE {base}/marketplace/:id
  Future<void> deleteItem(int id) async {
    final base = await ApiConfig.readBase();
    final token = await _token();
    final uri = Uri.parse('$base/marketplace/$id');

    final r = await http.delete(uri, headers: _authHeaders(token));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Delete failed (${r.statusCode}) at $uri: ${r.body}');
    }
  }

  // ========= PUBLIC =========

  /// ONLY MINE -> GET {base}/marketplace/me
  Future<List<MarketplaceDetailModel>> fetchMyItems() async {
    try {
      final base = await ApiConfig.readBase();
      final token = await _token();
      final url = Uri.parse('$base/marketplace/me');

      final r = await http.get(url, headers: _authHeaders(token, extra: {'Accept': 'application/json'}));
      final body = _decodeOrThrow(r, where: 'GET $url');

      final list = body is Map ? body['data'] : null;
      if (list is List) {
        return list.map((e) => MarketplaceDetailModel.fromJson(e)).toList().cast<MarketplaceDetailModel>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my items: $e');
      return [];
    }
  }

  /// Photo search
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

  /// Name search
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


Future<MarketplaceDetailModel> updateItem(int id, Map<String, dynamic> patch) async {
  final base = await ApiConfig.readBase();
  final token = await _token();
  final uri = Uri.parse('$base/marketplace/$id');

  final r = await http.put(
    uri,
    headers: _authHeaders(token, extra: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }),
    body: jsonEncode(patch),
  );

  final body = _decodeOrThrow(r, where: 'PUT $uri');
  final data = (body is Map ? (body['data'] ?? body) : body) as Map<String, dynamic>;
  return MarketplaceDetailModel.fromJson(data);
}


  /// Details
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

  /// List (optionally filtered by category)
  Future<List<MarketplaceDetailModel>> fetchMarketItems({String? category}) async {
    try {
      final base = await ApiConfig.readBase();
      final url = Uri.parse(
        (category == null || category.isEmpty)
            ? '$base/marketplace'
            : '$base/marketplace?category=${Uri.encodeComponent(category.toLowerCase())}',
      );
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
