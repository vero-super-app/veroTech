import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/models/aunthentication_model.dart';

class AuthService {
  final String baseUrl = 'https://vero-backend.onrender.com'; // your backend URL



  // 🔹 Signup method
  Future<bool> signup(UserModel user) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    return response.statusCode == 201;
  }



  // 🔹 Login method (returns Map instead of bool)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');   
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final token = data['access_token'];
      final user = data['user'] ?? {"email": email};

      // Debug: Print the token
      print('✅ Token received: $token');

      // Save the token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('email', user['email']);

      return {
        "token": token,
        "user": user,
      };
    } else {
      print('❌ Login failed: ${response.body}');
      return null;
    }
  }


  // 🔹 Get saved JWT token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print('Retrieved token: $token');
    return token;
  }



  // 🔹 Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
