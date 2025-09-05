import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/models/cart_model.dart';
import 'package:vero360_app/models/marketplace.model.dart';
import 'package:vero360_app/services/cart_services.dart';
import 'package:vero360_app/services/marketplace.service.dart';


class DetailsPage extends StatefulWidget {
  final int itemId;
  final CartService cartService;

  const DetailsPage({required this.itemId, required this.cartService, Key? key}) : super(key: key);

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<MarketplaceDetailModel?> _itemDetails;
  final TextEditingController _commentController = TextEditingController();
  final FToast _fToast = FToast();

  @override
  void initState() {
    super.initState();
    _itemDetails = MarketplaceService().getItemDetails(widget.itemId);
    _fToast.init(context);
  }

  Future<void> _addToCart(MarketplaceDetailModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      _showToast("Please log in to add items to cart.", Icons.error, Colors.red);
      return;
    }

    final cartItem = CartModel(
      userId: userId.toString(),
      item: item.id,
      quantity: 1,
      name: item.name,
      image: item.image,
      price: item.price,
      description: item.description,
      comment: _commentController.text,
    );

    try {
      await widget.cartService.addToCart(cartItem);
      _showToast("${item.name} added to cart!", Icons.check_circle, Colors.green);
    } catch (e) {
      _showToast("Failed to add item: $e", Icons.error, Colors.red);
    }
  }

  void _showToast(String message, IconData icon, Color color) {
    _fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      gravity: ToastGravity.CENTER,
      toastDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Item Details")),
      body: FutureBuilder<MarketplaceDetailModel?>(
        future: _itemDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text("Item not found"));
          final item = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Image.network(item.image, height: 300, fit: BoxFit.cover),
                const SizedBox(height: 16),
                Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("MWK ${item.price}", style: const TextStyle(fontSize: 20, color: Colors.green)),
                const SizedBox(height: 16),
                Text(item.description),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Add a note (optional)",
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _addToCart(item),
                  child: const Text("Add to Cart"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
