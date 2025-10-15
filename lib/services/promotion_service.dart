import 'dart:convert';
import 'dart:io' show File;

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class PromoModel {
  final int id;
  final int merchantId;
  final int? serviceProviderId;
  final String title;
  final String? description;
  final double? price;
  final String? image;
  final bool isActive;
  final DateTime? freeTrialEndsAt;
  final DateTime? subscribedAt;
  final DateTime createdAt;

  PromoModel({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.isActive,
    required this.createdAt,
    this.serviceProviderId,
    this.description,
    this.price,
    this.image,
    this.freeTrialEndsAt,
    this.subscribedAt,
  });

  factory PromoModel.fromJson(Map<String, dynamic> j) => PromoModel(
        id: j['id'],
        merchantId: j['merchantId'],
        serviceProviderId: j['serviceProviderId'],
        title: j['title'] ?? '',
        description: j['description'],
        price: (j['price'] == null) ? null : (j['price'] as num).toDouble(),
        image: j['image'],
        isActive: j['isActive'] == true,
        freeTrialEndsAt: j['freeTrialEndsAt'] == null ? null : DateTime.parse(j['freeTrialEndsAt']),
        subscribedAt: j['subscribedAt'] == null ? null : DateTime.parse(j['subscribedAt']),
        createdAt: DateTime.parse(j['createdAt']),
      );

  Map<String, dynamic> toCreateJson() => {
        'title': title,
        'description': description,
        'price': price,
        'image': image,
        // serviceProviderId intentionally omitted (server maps internally)
      };
}

class PromoService {
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? prefs.getString('token') ?? '';
  }

  Map<String, String> _auth(String t, {Map<String, String>? extra}) => {
        'Authorization': 'Bearer $t',
        'Accept': 'application/json',
        if (extra != null) ...extra,
      };

  dynamic _decode(http.Response r, {required String where}) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode} at $where: ${r.body}');
    }
    return r.body.isEmpty ? {} : json.decode(r.body);
  }

  // === uploads (auth) ===
  Future<String> uploadImageFile(File f, {String filename = 'promo.jpg'}) async {
    final base = await ApiConfig.readBase();
    final t = await _token();
    final url = Uri.parse('$base/uploads');

    final req = http.MultipartRequest('POST', url)
      ..headers.addAll(_auth(t))
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        f.path,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    final body = _decode(resp, where: 'POST $url');
    final imageUrl = (body is Map ? body['url']?.toString() : null);
    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('Upload ok but no "url" returned');
    }
    return imageUrl;
  }

  // === secured promo endpoints ===
  Future<List<PromoModel>> fetchMyPromos() async {
    final base = await ApiConfig.readBase();
    final t = await _token();
    final url = Uri.parse('$base/promos/me');
    final r = await http.get(url, headers: _auth(t));
    final body = _decode(r, where: 'GET $url');
    final list = (body as List).cast<Map<String, dynamic>>();
    return list.map(PromoModel.fromJson).toList();
  }

  Future<PromoModel> createPromo(PromoModel p) async {
    final base = await ApiConfig.readBase();
    final t = await _token();
    final url = Uri.parse('$base/promos');
    final r = await http.post(
      url,
      headers: _auth(t, extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(p.toCreateJson()),
    );
    final body = _decode(r, where: 'POST $url') as Map<String, dynamic>;
    return PromoModel.fromJson(body);
  }

  Future<void> subscribe(int promoId, double amountPaid) async {
    final base = await ApiConfig.readBase();
    final t = await _token();
    final url = Uri.parse('$base/promos/$promoId/subscribe');
    final r = await http.patch(
      url,
      headers: _auth(t, extra: {'Content-Type': 'application/json'}),
      body: jsonEncode({'amountPaid': amountPaid}),
    );
    _decode(r, where: 'PATCH $url');
  }

  Future<void> deactivate(int promoId) async {
    final base = await ApiConfig.readBase();
    final t = await _token();
    final url = Uri.parse('$base/promos/$promoId/deactivate');
    final r = await http.patch(url, headers: _auth(t));
    _decode(r, where: 'PATCH $url');
  }

  Future<void> deletePromo(int promoId) async {
    final base = await ApiConfig.readBase();
    final t = await _token();
    final url = Uri.parse('$base/promos/$promoId');
    final r = await http.delete(url, headers: _auth(t));
    _decode(r, where: 'DELETE $url');
  }
}
