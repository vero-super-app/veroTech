import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/Pages/address.dart';

import 'package:vero360_app/models/cart_model.dart';
import 'package:vero360_app/services/paychangu_service.dart';
import 'package:vero360_app/toasthelper.dart';
import 'package:vero360_app/Pages/payment_webview.dart';

// ⬇️ Address imports
import 'package:vero360_app/models/address_model.dart';
import 'package:vero360_app/services/address_service.dart';


enum PaymentMethod { mobile, card, cod }

class CheckoutFromCartPage extends StatefulWidget {
  final List<CartModel> items;
  const CheckoutFromCartPage({Key? key, required this.items}) : super(key: key);

  @override
  State<CheckoutFromCartPage> createState() => _CheckoutFromCartPageState();
}

class _CheckoutFromCartPageState extends State<CheckoutFromCartPage> {
  // Same payment UI as main checkout
  static const String _kAirtel = 'AirtelMoney';
  static const String _kMpamba = 'Mpamba';
  PaymentMethod _method = PaymentMethod.mobile;
  String _provider = _kAirtel;

  final _phoneCtrl = TextEditingController();

  bool _submitting = false;
  String? _phoneError;

  // Address state
  final _addrSvc = AddressService();
  Address? _defaultAddr;
  bool _loadingAddr = true;
  bool _loggedIn = false;

  double get _subtotal =>
      widget.items.fold(0.0, (s, it) => s + (it.price * it.quantity));
  double get _delivery => 0;
  double get _total => _subtotal + _delivery;

  @override
  void initState() {
    super.initState();
    _initAuthAndAddress();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Auth + Address bootstrap ─────────────────────────────────────────────
  Future<String?> _readAuthToken() async {
    final sp = await SharedPreferences.getInstance();
    for (final k in const ['token', 'jwt_token', 'jwt']) {
      final v = sp.getString(k);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Future<void> _initAuthAndAddress() async {
    setState(() {
      _loadingAddr = true;
      _defaultAddr = null;
      _loggedIn = false;
    });

    final token = await _readAuthToken();
    if (!mounted) return;

    if (token == null) {
      setState(() {
        _loggedIn = false;
        _loadingAddr = false;
      });
      return;
    }

    try {
      final list = await _addrSvc.getMyAddresses();
      Address? def = list.firstWhere(
        (a) => a.isDefault,
        orElse: () => list.isNotEmpty ? list.first : null as Address,
      );
      setState(() {
        _loggedIn = true;
        _defaultAddr = def?.isDefault == true ? def : null;
        _loadingAddr = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _defaultAddr = null;
        _loadingAddr = false;
      });
    }
  }

  Future<bool> _ensureDefaultAddress() async {
    if (!_loggedIn) {
      ToastHelper.showCustomToast(
        context,
        'Please log in to complete checkout.',
        isSuccess: false,
        errorMessage: 'Not logged in',
      );
      return false;
    }
    if (_defaultAddr != null) return true;

    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delivery address required'),
        content: const Text('Set a default address before checkout.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Set address')),
        ],
      ),
    );

    if (go == true) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage()));
      await _initAuthAndAddress();
      return _defaultAddr != null;
    }
    return false;
  }

  // ── Phone + provider helpers ─────────────────────────────────────────────
  String get _providerLabel => _provider == _kAirtel ? 'Airtel Money' : 'TNM Mpamba';
  String get _providerHint  => _provider == _kAirtel ? '09xxxxxxxx'   : '08xxxxxxxx';
  IconData get _providerIcon => _provider == _kAirtel
      ? Icons.phone_android_rounded
      : Icons.phone_iphone_rounded;

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

  String _mwk(num n) => 'MWK ${n.toStringAsFixed(2)}';

  // ── Pay flows ────────────────────────────────────────────────────────────
  Future<void> _onPayPressed() async {
    if (!await _ensureDefaultAddress()) return;

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

  Future<void> _payMobile() async {
    final err = _validatePhoneForSelectedProvider(_phoneCtrl.text);
    if (err != null) {
      setState(() => _phoneError = err);
      ToastHelper.showCustomToast(context, err, isSuccess: false, errorMessage: 'Invalid phone');
      return;
    }
    setState(() => _phoneError = null);

    final itemsStr = widget.items.map((e) => '${e.name} x${e.quantity}').join(', ');
    setState(() => _submitting = true);
    try {
      final resp = await PaymentsService.pay(
        amount: _total,
        currency: 'MWK',
        phoneNumber: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
        relatedType: 'ORDER',
        description: 'Cart: $itemsStr • $_providerLabel • Deliver to: ${_defaultAddr?.city ?? '-'}',
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

  Future<void> _payCard() async {
    final itemsStr = widget.items.map((e) => '${e.name} x${e.quantity}').join(', ');
    setState(() => _submitting = true);
    try {
      final resp = await PaymentsService.pay(
        amount: _total,
        currency: 'MWK',
        phoneNumber: null,
        relatedType: 'ORDER',
        description: 'Cart (card): $itemsStr • Deliver to: ${_defaultAddr?.city ?? '-'}',
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

  Future<void> _placeCOD() async {
    ToastHelper.showCustomToast(
      context,
      'Order placed • COD',
      isSuccess: true,
      errorMessage: 'OK',
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canPay = !_submitting && _loggedIn && _defaultAddr != null;

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

          // ----- Delivery Address (required) -----
          _DeliveryAddressCard(
            loading: _loadingAddr,
            loggedIn: _loggedIn,
            address: _defaultAddr,
            onManage: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage()));
              await _initAuthAndAddress();
            },
          ),

          const SizedBox(height: 12),

          // ----- Payment method (same as main) -----
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Column(
              children: [
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
                              child: Column(
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
                                      labelText: 'Phone number (${_providerLabel})',
                                      hintText: _providerHint,
                                      prefixIcon: Icon(_providerIcon),
                                      border: const OutlineInputBorder(),
                                      helperText: '10 digits only',
                                      errorText: _phoneError,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('mobile-empty')),
                    ),
                  ],
                ),
                const Divider(height: 1),
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.card,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text('Card'),
                  secondary: const Icon(Icons.credit_card_rounded),
                ),
                const Divider(height: 1),
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

          // ----- Pay / Place Order -----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!_submitting && _loggedIn && _defaultAddr != null) ? _onPayPressed : null,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock),
              label: Text(_submitting
                  ? 'Processing…'
                  : (_method == PaymentMethod.cod ? 'Place Order' : 'Pay Now')),
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

// Reuse the same Delivery Address card as on main checkout (copy/paste)
class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.loading,
    required this.loggedIn,
    required this.address,
    required this.onManage,
  });

  final bool loading;
  final bool loggedIn;
  final Address? address;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            if (loading)
              const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (!loggedIn)
              _line('Not logged in', 'Please log in to select address')
            else if (address == null)
              _line('No default address', 'Set your default delivery address')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(_label(address!.addressType), address!.city),
                  if (address!.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(address!.description, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ],
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.location_pin),
                label: Text(address == null ? 'Set address' : 'Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _line(String a, String b) {
    return Row(
      children: [
        Expanded(child: Text(a, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(b, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }

  static String _label(AddressType t) {
    switch (t) {
      case AddressType.home: return 'Home';
      case AddressType.work: return 'Office';
      case AddressType.business: return 'Business';
      case AddressType.other: return 'Other';
    }
  }
}
