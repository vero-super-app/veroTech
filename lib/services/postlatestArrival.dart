// services/latestArrival.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/models/Latest_model.dart';
import 'api_config.dart';

class LatestArrivalsServicess {
  // ---- token helpers
  Future<String> _authToken() async {
    final prefs = await SharedPreferences.getInstance();
    // make sure your login saves ONE of these; prefer 'token'
    final token = prefs.getString('token') ??
        prefs.getString('jwt_token') ??
        prefs.getString('access_token') ??
        '';
    if (token.isEmpty) throw Exception('Not authenticated');
    return token;
  }

  Future<Map<String, String>> _jsonAuthHeaders() async {
    final t = await _authToken();
    return {
      'Authorization': 'Bearer $t',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _decode(http.Response r, {required String where}) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode} at $where: ${r.body}');
    }
    if (r.body.isEmpty) return {};
    return json.decode(r.body);
  }

  // -------- upload (AUTH ON MULTIPART)
  Future<String> uploadImageFile(File file, {String filename = 'latest.jpg'}) async {
    final base = await ApiConfig.readBase();
    final uri = Uri.parse('$base/uploads');

    final token = await _authToken(); // << include auth on uploads
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    req.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));

    final resp = await http.Response.fromStream(await req.send());
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
    }
    final body = json.decode(resp.body);
    final url = body is Map ? (body['url']?.toString()) : null;
    if (url == null || url.isEmpty) throw Exception('Upload ok but no "url" returned');
    return url;
  }

  // -------- public list
  Future<List<LatestArrivalModel>> fetchAll() async {
    final base = await ApiConfig.readBase();
    final url = Uri.parse('$base/latestarrivals');
    final r = await http.get(url);
    final body = _decode(r, where: 'GET $url');
    final list = body is List ? body : (body['data'] ?? []);
    return (list as List).map((e) => LatestArrivalModel.fromJson(e)).toList();
  }

  // -------- private list (AUTH)
  Future<List<LatestArrivalModel>> fetchMine() async {
    final base = await ApiConfig.readBase();
    final url = Uri.parse('$base/latestarrivals/me');
    final r = await http.get(url, headers: {
      'Authorization': 'Bearer ${await _authToken()}',
      'Accept': 'application/json',
    });
    final body = _decode(r, where: 'GET $url');
    final list = body is List ? body : (body['data'] ?? []);
    return (list as List).map((e) => LatestArrivalModel.fromJson(e)).toList();
  }

  // -------- create/update/delete (AUTH JSON)
  Future<void> create(LatestArrivalModel item) async {
    final base = await ApiConfig.readBase();
    final url = Uri.parse('$base/latestarrivals');
    final r = await http.post(url, headers: await _jsonAuthHeaders(), body: json.encode(item.toJson()));
    _decode(r, where: 'POST $url');
  }

  Future<void> update(int id, Map<String, dynamic> patch) async {
    final base = await ApiConfig.readBase();
    final url = Uri.parse('$base/latestarrivals/$id');
    final r = await http.put(url, headers: await _jsonAuthHeaders(), body: json.encode(patch));
    _decode(r, where: 'PUT $url');
  }

  Future<void> delete(int id) async {
    final base = await ApiConfig.readBase();
    final url = Uri.parse('$base/latestarrivals/$id');
    final r = await http.delete(url, headers: {
      'Authorization': 'Bearer ${await _authToken()}',
      'Accept': 'application/json',
    });
    _decode(r, where: 'DELETE $url');
  }
}
