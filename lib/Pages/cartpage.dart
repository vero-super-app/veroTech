import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_services.dart';
import '../models/cart_model.dart';

class CartPage extends StatefulWidget {
  final CartService cartService;

  const CartPage({required this.cartService, Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<CartModel>> _cartItemsFuture;

  @override
  void initState() {
    super.initState();
    _cartItemsFuture = _loadCartItems(); // ✅ initialize here
  }

  Future<List<CartModel>> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return widget.cartService.fetchCartItems(token: token);
  }

  Future<void> _removeFromCart(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    await widget.cartService.removeFromCart(itemId, token: token);

    setState(() {
      _cartItemsFuture = _loadCartItems(); // ✅ refresh after removal
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<CartModel>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          } else {
            final cartModels = snapshot.data!;
            double total = cartModels.fold(
              0,
              (sum, item) => sum + (item.price * item.quantity),
            );

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartModels.length,
                    itemBuilder: (context, index) =>
                        _buildCartItem(cartModels[index]),
                  ),
                ),
                _buildCartSummary(total),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCartItem(CartModel item) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.image.isNotEmpty
                ? Image.network(item.image, width: 80, height: 80, fit: BoxFit.cover)
                : const Icon(Icons.image_not_supported, size: 80),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('MWK${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green)),
                Text('Quantity: ${item.quantity}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeFromCart(item.item),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRow('Subtotal', total),
          _buildPriceRow('Delivery Fee', 20.00),
          _buildPriceRow('Discount', -10.00),
          const Divider(),
          _buildPriceRow('Total', total + 10.00, isTotal: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // TODO: Add checkout logic
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Checkout', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text('MWK${amount.toStringAsFixed(2)}',
              style: TextStyle(color: isTotal ? Colors.green : Colors.black)),
        ],
      ),
    );
  }
}
