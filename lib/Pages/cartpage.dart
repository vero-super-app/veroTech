import 'dart:async';
import 'dart:math';

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
  late Future<List<CartModel>> _cartFuture;
  List<CartModel> _items = [];
  String? _error;
  bool _loading = false;
  String? _userId; // cached so we always pass it

  @override
  void initState() {
    super.initState();
    _cartFuture = _fetch();
  }

  Future<String?> _tryGetUserId() async {
    // Prefer value saved by your login flow
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    return uid; // if null, CartService will decode from JWT
  }

  Future<List<CartModel>> _fetch() async {
  setState(() { _loading = true; _error = null; });
  try {
    await widget.cartService.warmup();                 // ⬅️ NEW
    _userId ??= await _tryGetUserId();
    final data = await widget.cartService.fetchCartItems(userId: _userId);
    _items = List<CartModel>.from(data);
    return _items;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}



  Future<void> _refresh() async {
    setState(() => _cartFuture = _fetch());
    await _cartFuture;
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, it) => sum + (it.price * it.quantity));

  String _mwk(num n) => 'MWK ${n.toStringAsFixed(2)}';

  Future<void> _remove(CartModel item) async {
    final idx = _items.indexWhere((x) => x.item == item.item);
    if (idx == -1) return;
    final backup = _items[idx];
    setState(() => _items.removeAt(idx));

    try {
      await widget.cartService.removeFromCart(item.item, userId: _userId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Removed ${item.name}')));
      }
    } catch (e) {
      setState(() => _items.insert(idx, backup));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
      }
    }
    setState(() {});
  }

  Future<void> _changeQty(CartModel item, int newQty) async {
    newQty = max(0, min(99, newQty));
    if (newQty == item.quantity) return;
    if (newQty == 0) return _remove(item);

    final idx = _items.indexWhere((x) => x.item == item.item);
    if (idx == -1) return;
    final backup = _items[idx];
    setState(() => _items[idx] = backup.copyWith(quantity: newQty));

    try {
      final model = CartModel(
        userId: _userId ?? backup.userId,
        item: item.item,
        quantity: newQty,
        name: item.name,
        image: item.image,
        price: item.price,
        description: item.description,
        comment: item.comment,
      );
      await widget.cartService.addToCart(model);
    } catch (e) {
      setState(() => _items[idx] = backup);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity: $e')),
        );
      }
    }
    setState(() {});
  }

  Future<void> _clearCart() async {
    if (_items.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('Remove all items from your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await widget.cartService.clearCart(userId: _userId);
      setState(() => _items.clear());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear: $e')),
        );
      }
    }
  }

  Future<void> _proceedToCheckout() async {
    // TODO: integrate payment flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkout flow coming soon…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryFee = _items.isEmpty ? 0.0 : 20.0;
    final discount = 0.0;
    final total = _subtotal + deliveryFee + discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Clear cart',
            onPressed: _items.isEmpty ? null : _clearCart,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<CartModel>>(
          future: _cartFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && _items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Error loading cart:\n${_error ?? snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }

            if (_items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Your cart is empty')),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) => _CartItemTile(
                      item: _items[i],
                      onInc: () => _changeQty(_items[i], _items[i].quantity + 1),
                      onDec: () => _changeQty(_items[i], _items[i].quantity - 1),
                      onRemove: () => _remove(_items[i]),
                    ),
                  ),
                ),
                _CartSummary(
                  subtotal: _subtotal,
                  deliveryFee: deliveryFee,
                  discount: discount,
                  total: total,
                  loading: _loading,
                  onCheckout: _proceedToCheckout,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ===== Widgets ===============================================================

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  final CartModel item;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  String _mwk(num n) => 'MWK ${n.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 80,
              height: 80,
              child: item.image.isNotEmpty
                  ? Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEAEAEA),
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFFEAEAEA),
                      child: Icon(Icons.image_not_supported, size: 40),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mwk(item.price),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Qty controls
                  Row(
                    children: [
                      _IconBtn(icon: Icons.remove, onTap: onDec),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.quantity}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      _IconBtn(icon: Icons.add, onTap: onInc),
                      const Spacer(),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.remove, size: 18), // icon filled by parent call
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.loading,
    required this.onCheckout,
  });

  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final bool loading;
  final VoidCallback onCheckout;

  String _mwk(num n) => 'MWK ${n.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          children: [
            _row('Subtotal', _mwk(subtotal)),
            _row('Delivery Fee', _mwk(deliveryFee)),
            if (discount != 0) _row('Discount', _mwk(discount)),
            const Divider(height: 16),
            _row('Total', _mwk(total), bold: true, green: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : onCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(loading ? 'Please wait…' : 'Checkout', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool green = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: green ? Colors.green : Colors.black87,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

extension CartCopy on CartModel {
  CartModel copyWith({
    String? userId,
    int? item,
    int? quantity,
    String? image,
    String? name,
    double? price,
    String? description,
    String? comment,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      description: description ?? this.description,
      comment: comment ?? this.comment,
    );
  }
}
