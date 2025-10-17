// lib/Pages/checkout_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vero360_app/models/marketplace.model.dart';
import 'package:vero360_app/services/paychangu_service.dart';

import 'package:vero360_app/toasthelper.dart';
import 'package:vero360_app/Pages/payment_webview.dart'; // PaymentWebView(checkoutUrl: ...)

enum PaymentMethod { mobile, card, cod }

class CheckoutPage extends StatefulWidget {
  final MarketplaceDetailModel item;
  const CheckoutPage({required this.item, Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // ► Mobile money provider constants (labels your UI shows)
  static const String _kAirtel = 'AirtelMoney';
  static const String _kMpamba = 'Mpamba';

  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  PaymentMethod _method = PaymentMethod.mobile;
  String _provider = _kAirtel;        // default dropdown selection

  String? _phoneError;
  int _qty = 1;
  bool _submitting = false;

  double get _subtotal => widget.item.price * _qty;
  double get _delivery => 0;          // adjust if you add delivery fees
  double get _total => _subtotal + _delivery;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Provider helpers used in UI/validation ──────────────────────────────
  String get _providerLabel => _provider == _kAirtel ? 'Airtel Money' : 'TNM Mpamba';
  String get _providerHint  => _provider == _kAirtel ? '09xxxxxxxx'   : '08xxxxxxxx';
  IconData get _providerIcon => _provider == _kAirtel ? Icons.phone_android_rounded
                                                      : Icons.phone_iphone_rounded;

  // Validate: 10 digits + prefix based on selected provider
  String? _validatePhoneForSelectedProvider(String raw) {
    final p = raw.replaceAll(RegExp(r'\D'), '');
    if (p.length != 10) return 'Phone must be exactly 10 digits';
    if (_provider == _kAirtel && !PaymentsService.validateAirtel(p)) {
      return 'Airtel numbers must start with 09…';
    }
    if (_provider == _kMpamba && !PaymentsService.validateMpamba(p)) {
      return 'Mpamba numbers must start with 08…';
    }
    return null;
  }
  // ===== helpers (paste inside your State class) ===============================
Future<String?> _readAuthToken() async {
  final sp = await SharedPreferences.getInstance();
  for (final k in const ['token', 'jwt_token', 'jwt']) {
    final v = sp.getString(k);
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

/// Try to derive numeric user id from the JWT payload (sub | id | userId).
Future<int?> _userIdFromJwt() async {
  final t = await _readAuthToken();
  if (t == null) return null;
  try {
    final parts = t.split('.');
    if (parts.length != 3) return null;
    String p = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (p.length % 4 != 0) { p += '='; }
    final payload = jsonDecode(utf8.decode(base64.decode(p)));
    final raw = payload['sub'] ?? payload['id'] ?? payload['userId'];
    return raw == null ? null : int.tryParse(raw.toString());
  } catch (_) { return null; }
}
  Future<bool> _isLoggedIn() async => (await _readAuthToken()) != null;

// ---------- Checkout guard ----------
Future<bool> _requireLogin() async {
  if (!await _isLoggedIn()) {
    ToastHelper.showCustomToast(
      context,
      'Please log in to complete checkout.',
      isSuccess: false,
      errorMessage: 'Not logged in',
    );
    return false;
  }
  return true;
}

  Future<void> _onPayPressed() async {
    switch (_method) {
      case PaymentMethod.mobile:
        await _payMobile();
        break;
      case PaymentMethod.card:
        await _payCard();
        break;
      case PaymentMethod.cod:
        await _placeCOD();
        break;
    }
  }

  // ── Mobile Money flow ───────────────────────────────────────────────────
  Future<void> _payMobile() async {
    if (!await _requireLogin()) return;

    final err = _validatePhoneForSelectedProvider(_phoneCtrl.text);
    if (err != null) {
      setState(() => _phoneError = err);
      ToastHelper.showCustomToast(context, err, isSuccess: false, errorMessage: 'Invalid phone');
      return;
    }
    setState(() => _phoneError = null);

    final phone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

    setState(() => _submitting = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final userId = sp.getInt('userId');

      // NOTE: Your /payments/pay DTO does not require provider; we include it in description.
      final resp = await PaymentsService.pay(
        amount: _total,
        currency: 'MWK',
        phoneNumber: phone,                 // required for mobile
        relatedType: 'ORDER',
        description: 'Order for ${widget.item.name} (x$_qty) • via $_providerLabel',
        // You can also pass txRef/relatedId if you want; service generates defaults.
      );

      if (resp.checkoutUrl != null && resp.checkoutUrl!.isNotEmpty) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentWebView(checkoutUrl: resp.checkoutUrl!)),
        );
      } else {
        ToastHelper.showCustomToast(
          context,
          resp.message ?? resp.status ?? 'Payment initiated',
          isSuccess: true,
          errorMessage: 'OK',
        );
      }
      if (mounted) Navigator.pop(context);
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

  // ── Card flow (hosted page) ─────────────────────────────────────────────
  Future<void> _payCard() async {
    if (!await _requireLogin()) return;

    setState(() => _submitting = true);
    try {
      final resp = await PaymentsService.pay(
        amount: _total,
        currency: 'MWK',
        phoneNumber: null, // not needed for card
        relatedType: 'ORDER',
        description: 'Card payment for ${widget.item.name} (x$_qty)',
      );

      if (resp.checkoutUrl != null && resp.checkoutUrl!.isNotEmpty) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentWebView(checkoutUrl: resp.checkoutUrl!)),
        );
      } else {
        ToastHelper.showCustomToast(
          context,
          resp.message ?? resp.status ?? 'Card payment started',
          isSuccess: true,
          errorMessage: 'OK',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ToastHelper.showCustomToast(
        context,
        'Card payment error: $e',
        isSuccess: false,
        errorMessage: 'Card payment failed',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Cash on Delivery (simple confirm / create order call if you have it) ─
  Future<void> _placeCOD() async {
    if (!await _requireLogin()) return;

    // TODO: call your create-order endpoint if needed
    ToastHelper.showCustomToast(
      context,
      'Order placed • Cash on Delivery',
      isSuccess: true,
      errorMessage: 'OK',
    );
    if (mounted) Navigator.pop(context);
  }

  String _methodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.mobile: return 'Pay Now';
      case PaymentMethod.card:   return 'Pay Now';
      case PaymentMethod.cod:    return 'Place Order';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          // ── Item summary ──────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.image,
                    width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90, height: 90, color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('MWK ${item.price}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _qtyBtn(Icons.remove, () { if (_qty > 1) setState(() => _qty--); }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      _qtyBtn(Icons.add, () { setState(() => _qty++); }),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          // ── Payment method selector with inline Mobile Money fields ───────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Column(
              children: [
                // Mobile Money row + expanding section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioListTile<PaymentMethod>(
                      value: PaymentMethod.mobile,
                      groupValue: _method,
                      onChanged: (v) => setState(() => _method = v!),
                      title: const Text('Mobile Money'),
                      secondary: const Icon(Icons.phone_iphone_rounded),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _method == PaymentMethod.mobile
                          ? Padding(
                              key: const ValueKey('mobile-fields'),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _mobileFields(),
                            )
                          : const SizedBox.shrink(key: ValueKey('mobile-empty')),
                    ),
                  ],
                ),

                const Divider(height: 1),

                // Card row (collapsed)
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.card,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text('Card'),
                  secondary: const Icon(Icons.credit_card_rounded),
                ),

                const Divider(height: 1),

                // Cash on Delivery row (collapsed)
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.cod,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text('Cash on Delivery'),
                  secondary: const Icon(Icons.delivery_dining_rounded),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

         

          // ── Summary ───────────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                _rowLine('Subtotal', 'MWK ${_subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                _rowLine('Delivery', 'MWK ${_delivery.toStringAsFixed(0)}'),
                const Divider(height: 18),
                _rowLine('Total', 'MWK ${_total.toStringAsFixed(0)}', bold: true),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Action button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _onPayPressed,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock),
              label: Text(_submitting ? 'Processing…' : _methodLabel(_method)),
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

  // ── Inline Mobile Money fields (provider dropdown + single phone) ────────
  Widget _mobileFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _provider,
          icon: const Icon(Icons.arrow_drop_down),
          decoration: const InputDecoration(
            labelText: 'Provider',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: _kAirtel, child: Text('Airtel Money')),
            DropdownMenuItem(value: _kMpamba, child: Text('TNM Mpamba')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _provider = v;
              _phoneError = null;
            });
          },
        ),
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
            labelText: 'Phone number ($_providerLabel)',
            hintText: _providerHint,
            prefixIcon: Icon(_providerIcon),
            border: const OutlineInputBorder(),
            errorText: _phoneError,
            helperText: '10 digits only',
          ),
        ),
      ],
    );
  }

  // ── Small helpers ────────────────────────────────────────────────────────
  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _rowLine(String left, String right, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      children: [
        Expanded(child: Text(left, style: style)),
        Text(right, style: style),
      ],
    );
  }
}
