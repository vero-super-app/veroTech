import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';

class CartService {
  final String baseUrl;

  CartService(this.baseUrl);

  // ✅ Get backend token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token'); // token saved after login
  }

  // ✅ Add item to cart
  Future<void> addToCart(CartModel cartItem) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not logged in');

    final url = Uri.parse('$baseUrl/cart');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'item': cartItem.item,
        'quantity': cartItem.quantity,
        'image': cartItem.image,
        'name': cartItem.name,
        'price': cartItem.price,
        'description': cartItem.description,
        'comment': cartItem.comment,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add item to cart: ${response.body}');
    }
  }

  // ✅ Fetch cart items
  Future<List<CartModel>> fetchCartItems({String? token}) async {
    final token = await _getToken();
    if (token == null) throw Exception("User not logged in");

    final url = Uri.parse('$baseUrl/cart');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => CartModel.fromJson(data)).toList();
    } else {
      throw Exception('Failed to fetch cart items: ${response.body}');
    }
  }

  // ✅ Remove item from cart
  Future<void> removeFromCart(int itemId, {String? token}) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not logged in');

    final url = Uri.parse('$baseUrl/cart/$itemId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove item: ${response.body}');
    }
  }
}
