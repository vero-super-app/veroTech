import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:vero360_app/Pages/ToRefund.dart';
import 'package:vero360_app/Pages/Topay.dart';
import 'package:vero360_app/Pages/Toreceive.dart';
import 'package:vero360_app/Pages/Toship.dart';
import 'package:vero360_app/Pages/address.dart';
import 'package:vero360_app/models/marketplace.model.dart';
import 'package:vero360_app/screens/login_screen.dart';
import 'package:vero360_app/services/marketplace.service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final MarketplaceService marketplaceService = MarketplaceService();

  String fullName = "Guest User";
  String email = "No Email";
  String address = "No Address";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCurrentUser();
  }

  /// Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? 'Guest User';
      email = prefs.getString('email') ?? 'No Email';
      address = prefs.getString('address') ?? 'No Address';
    });
  }

  /// Fetch current user from API and store in SharedPreferences
  Future<void> _fetchCurrentUser() async {
    try {
      final token = await _getAuthToken();
      if (token.isEmpty) return;

      final response = await http.get(
        Uri.parse('https://vero-backend.onrender.com/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          fullName = data['name'] ?? 'Guest User';
          email = data['email'] ?? 'No Email';
          address = data['addresses'] != null && data['addresses'].isNotEmpty
              ? data['addresses'][0]['address']
              : 'No Address';
        });
        await prefs.setString('fullName', fullName);
        await prefs.setString('email', email);
        await prefs.setString('address', address);
      } else {
        debugPrint('Failed to fetch user: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken') ?? '';
  }

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.green,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.orange),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.green, size: 30),
                ),
                const SizedBox(height: 10),
                Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 18)),
                Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 5),
                Text(address, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.white),
            title: const Text('To Pay', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToPayPage())),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping, color: Colors.white),
            title: const Text('To Ship', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToShipPage())),
          ),
          ListTile(
            leading: const Icon(Icons.move_to_inbox, color: Colors.white),
            title: const Text('To Receive', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToReceivePage())),
          ),
          ListTile(
            leading: const Icon(Icons.replay_circle_filled, color: Colors.white),
            title: const Text('Refund', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToRefundPage())),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.white),
            title: const Text('My Address', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressPage())),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(color: Colors.black, fontSize: 16)),
                Text(address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.black), onPressed: () {}),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $fullName', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text('Email: $email', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text('Address: $address', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Latest Arrivals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<MarketplaceDetailModel>>(
              future: marketplaceService.fetchLatestArrivals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Failed to load latest arrivals"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No latest arrivals available"));
                } else {
                  final items = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildListingCard(items[index]),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(MarketplaceDetailModel item) {
    return Card(
      elevation: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
