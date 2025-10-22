// lib/services/food_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'package:http/http.dart' as http;

import 'package:vero360_app/models/food_model.dart';
import 'package:vero360_app/services/api_config.dart';
import 'package:http_parser/http_parser.dart';

class FoodService {
  /// Build `base + path` safely.
  Uri _buildUri(String base, String path, [Map<String, String>? query]) {
    final root = Uri.parse(base);
    final rootPath = root.path.endsWith('/')
        ? root.path.substring(0, root.path.length - 1)
        : root.path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return root.replace(
      path: '$rootPath$cleanPath',
      queryParameters: query,
    );
  }

  /// GET /marketplace?category=food
  Future<List<FoodModel>> fetchFoodItems() async {
    try {
      final base = await ApiConfig.readBase();
      final uri = _buildUri(base, '/marketplace', const {'category': 'food'});

      final res = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final trimmed = res.body.length > 300 ? '${res.body.substring(0, 300)}…' : res.body;
        throw Exception('HTTP ${res.statusCode} at $uri • $trimmed');
      }

      final decoded = jsonDecode(res.body);
      final List list = (decoded is Map && decoded['data'] is List)
          ? (decoded['data'] as List)
          : (decoded is List ? decoded : const []);

      final out = <FoodModel>[];
      for (final row in list) {
        if (row is! Map) continue;
        try {
          out.add(FoodModel.fromJson(_adaptMarketplaceToFoodJson(row)));
        } catch (_) {}
      }
      return out;
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON from server: $e');
    } catch (e) {
      throw Exception('Failed to fetch food: $e');
    }
  }

  /// Text search by FoodName OR RestrauntName (client-side filter over food list).
  Future<List<FoodModel>> searchFoodByNameOrRestaurant(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return fetchFoodItems();
    final all = await fetchFoodItems();
    return all.where((f) {
      final n = (f.FoodName).toLowerCase();
      final r = (f.RestrauntName).toLowerCase();
      return n.contains(q) || r.contains(q);
    }).toList();
  }

  /// Photo search → POST /marketplace/search/photo, then filter to category=food.
  Future<List<FoodModel>> searchFoodByPhoto(File imageFile) async {
    try {
      final base = await ApiConfig.readBase();
      final uri = _buildUri(base, '/marketplace/search/photo');

      final req = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final trimmed = res.body.length > 300 ? '${res.body.substring(0, 300)}…' : res.body;
        throw Exception('HTTP ${res.statusCode} at $uri • $trimmed');
      }

      final decoded = jsonDecode(res.body);
      final List list = (decoded is Map && decoded['data'] is List)
          ? (decoded['data'] as List)
          : (decoded is List ? decoded : const []);

      final out = <FoodModel>[];
      for (final row in list) {
        if (row is! Map) continue;
        try {
          final m = _adaptMarketplaceToFoodJson(row);
          // keep only food category
          final cat = (m['category'] ?? '').toString().toLowerCase();
          if (cat == 'food') out.add(FoodModel.fromJson(m));
        } catch (_) {}
      }
      return out;
    } on TimeoutException {
      throw Exception('Photo search timed out. Try a smaller image.');
    } on FormatException catch (e) {
      throw Exception('Invalid JSON from server: $e');
    } catch (e) {
      throw Exception('Photo search failed: $e');
    }
  }

  /// Adapter: marketplace → FoodModel JSON
  Map<String, dynamic> _adaptMarketplaceToFoodJson(Map raw) {
    String _s(dynamic v) => v?.toString() ?? '';
    String? _sn(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    final sp = (raw['serviceProvider'] ?? raw['merchant'] ?? raw['seller']);
    final sellerName = _sn(raw['sellerBusinessName']) ??
        _sn((sp is Map) ? sp['businessName'] : null) ??
        _sn(raw['businessName']) ??
        'Marketplace';

    final pr = raw['price'];
    final price = (pr is num) ? pr.toDouble() : double.tryParse('${pr ?? 0}') ?? 0.0;

    final img = _sn(raw['image'] ?? raw['img']) ?? '';

    int _id(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return <String, dynamic>{
      'id': _id(raw['id']),
      'FoodName': _s(raw['name']),
      'FoodImage': img,
      'RestrauntName': sellerName ?? 'Marketplace',
      'price': price,
      'description': _sn(raw['description']),
      'category': _sn(raw['category']),
    };
  }
}
