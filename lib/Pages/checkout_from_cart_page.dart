import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vero360_app/models/cart_model.dart';
import 'package:vero360_app/services/paychangu_service.dart';

import 'package:vero360_app/toasthelper.dart';
import 'package:vero360_app/Pages/payment_webview.dart'; // PaymentWebView(checkoutUrl: ...)

class CheckoutFromCartPage extends StatefulWidget {
  final List<CartModel> items;
  const CheckoutFromCartPage({Key? key, required this.items}) : super(key: key);

  @override
  State<CheckoutFromCartPage> createState() => _CheckoutFromCartPageState();
}

class _CheckoutFromCartPageState extends State<CheckoutFromCartPage> {
  final _phoneCtrl = TextEditingController();

  bool _submitting = false;
  String? _phoneError;

  double get _subtotal =>
      widget.items.fold(0.0, (s, it) => s + (it.price * it.quantity));
  double get _delivery => 0;
  double get _total => _subtotal + _delivery;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<bool> _hasToken() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('token') ?? sp.getString('jwt_token') ?? sp.getString('jwt');
    return t != null && t.isNotEmpty;
  }

  String? _validatePhone(String raw) {
    final p = raw.replaceAll(RegExp(r'\D'), '');
    if (p.length != 10) return 'Phone must be exactly 10 digits';
    if (!(PaymentsService.validateAirtel(p) || PaymentsService.validateMpamba(p))) {
      return 'Airtel starts 09…, Mpamba starts 08…';
    }
    return null;
  }

  String _mwk(num n) => 'MWK ${n.toStringAsFixed(2)}';

  Future<void> _payNow() async {
    if (!await _hasToken()) {
      ToastHelper.showCustomToast(
        context,
        'Please log in to complete checkout.',
        isSuccess: false,
        errorMessage: 'Not logged in',
      );
      return;
    }

    final err = _validatePhone(_phoneCtrl.text);
    if (err != null) {
      setState(() => _phoneError = err);
      ToastHelper.showCustomToast(
        context,
        err,
        isSuccess: false,
        errorMessage: 'Invalid phone',
      );
      return;
    }
    setState(() => _phoneError = null);

    final itemNames = widget.items.map((e) => e.name).join(', ');
    setState(() => _submitting = true);
    try {
      final resp = await PaymentsService.pay(
        amount: _total,
        currency: 'MWK',
        phoneNumber: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
        relatedType: 'ORDER',
        description: 'Cart: $itemNames',
      );

      if (resp.checkoutUrl != null && resp.checkoutUrl!.isNotEmpty) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(checkoutUrl: resp.checkoutUrl!),
          ),
        );
      } else {
        ToastHelper.showCustomToast(
          context,
          resp.message ?? resp.status ?? 'Payment initiated',
          isSuccess: true,
          errorMessage: 'OK',
        );
      }

      if (mounted) Navigator.pop(context); // back to cart
    } catch (e) {
      ToastHelper.showCustomToast(
        context,
        'Payment error: $e',
        isSuccess: false,
        errorMessage: 'Payment failed',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          // ----- Items with thumbnails -----
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Items',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  ListView.separated(
                    itemCount: widget.items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const Divider(height: 14),
                    itemBuilder: (_, i) {
                      final it = widget.items[i];
                      final lineTotal = it.price * it.quantity;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: (it.image.isNotEmpty)
                                  ? Image.network(
                                      it.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const _ImgFallback(),
                                    )
                                  : const _ImgFallback(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_mwk(it.price)}  •  Qty: ${it.quantity}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _mwk(lineTotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ----- Mobile Money (compact) -----
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mobile Money',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (_) {
                    if (_phoneError != null) setState(() => _phoneError = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: '09xxxxxxxx (Airtel) / 08xxxxxxxx (Mpamba)',
                    border: const OutlineInputBorder(),
                    helperText: '10 digits only',
                    errorText: _phoneError,
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          // ----- Summary -----
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                _row('Subtotal', _mwk(_subtotal)),
                const SizedBox(height: 6),
                _row('Delivery', _mwk(_delivery)),
                const Divider(height: 18),
                _row('Total', _mwk(_total), bold: true),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ----- Pay Now -----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _payNow,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock),
              label: Text(_submitting ? 'Processing…' : 'Pay Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String r, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      children: [Expanded(child: Text(l, style: style)), Text(r, style: style)],
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEAEAEA),
      child: Center(child: Icon(Icons.image_not_supported, size: 24)),
    );
  }
}
