import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/marketplace.model.dart';

class MarketplaceService {
  final String baseUrl = 'https://vero-backend.onrender.com/marketplace';

  Future<MarketplaceDetailModel?> getItemDetails(int itemId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/items/$itemId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return MarketplaceDetailModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching item details: $e');
      return null;
    }
  }

  Future<List<MarketplaceDetailModel>> fetchLatestArrivals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/items/latest'));
      if (response.statusCode == 200) {
        final List items = json.decode(response.body)['data'];
        return items.map((e) => MarketplaceDetailModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching latest arrivals: $e');
      return [];
    }
  }

  Future<List<MarketplaceDetailModel>> fetchMarketItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/items'));
      if (response.statusCode == 200) {
        final List items = json.decode(response.body)['data'];
        return items.map((e) => MarketplaceDetailModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching market items: $e');
      return [];
    }
  }
}
