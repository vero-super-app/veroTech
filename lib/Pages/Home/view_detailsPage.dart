// lib/Pages/Home/view_detailsPage.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/Pages/checkout_page.dart';

import 'package:vero360_app/models/cart_model.dart';
import 'package:vero360_app/models/marketplace.model.dart';
import 'package:vero360_app/services/cart_services.dart';
import 'package:vero360_app/services/serviceprovider_service.dart';
import 'package:vero360_app/models/serviceprovider_model.dart';
import 'package:vero360_app/toasthelper.dart';

class DetailsPage extends StatefulWidget {
  static const routeName = '/details';

  final MarketplaceDetailModel item;
  final CartService cartService;

  const DetailsPage({
    required this.item,
    required this.cartService,
    Key? key,
  }) : super(key: key);

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _SellerInfo {
  String? businessName, openingHours, status, description, logoUrl, serviceProviderId;
  double? rating;
  _SellerInfo({
    this.businessName,
    this.openingHours,
    this.status,
    this.description,
    this.rating,
    this.logoUrl,
    this.serviceProviderId,
  });
}

class _DetailsPageState extends State<DetailsPage> {
  Future<_SellerInfo>? _sellerFuture;
  final TextEditingController _commentController = TextEditingController();
  final FToast _fToast = FToast();

  @override
  void initState() {
    super.initState();
    _sellerFuture = _loadSeller();
    _fToast.init(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sellerFuture ??= _loadSeller();
  }

  Future<_SellerInfo> _loadSeller() async {
    final info = _SellerInfo(
      businessName: widget.item.sellerBusinessName,
      openingHours: widget.item.sellerOpeningHours,
      status: widget.item.sellerStatus,
      description: widget.item.sellerBusinessDescription,
      rating: widget.item.sellerRating,
      logoUrl: widget.item.sellerLogoUrl,
      serviceProviderId: widget.item.serviceProviderId,
    );

    final missing = info.businessName == null ||
        info.openingHours == null ||
        info.status == null ||
        info.description == null ||
        info.rating == null ||
        info.logoUrl == null;

    final spId = info.serviceProviderId?.trim();
    if (missing && spId != null && spId.isNotEmpty) {
      try {
        final ServiceProvider? sp = await ServiceProviderServicess.fetchByNumber(spId);
        if (sp != null) {
          info.businessName ??= sp.businessName;
          info.openingHours ??= sp.openingHours;
          info.status ??= sp.status;
          info.description ??= sp.businessDescription;
          info.logoUrl ??= sp.logoUrl;
          final r = sp.rating;
          if (info.rating == null && r != null) {
            info.rating = (r is num) ? r.toDouble() : double.tryParse('$r');
          }
        }
      } catch (_) {/* ignore → show placeholders */}
    }
    return info;
  }

  Future<void> _goToCheckout(MarketplaceDetailModel item) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');
  // if (userId == null) {
  //   ToastHelper.showCustomToast(
  //     context,
  //     'Please log in to continue checking out.',
  //     isSuccess: false,
  //     errorMessage: 'Not logged in',
  //   );
  //   return;
  // }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CheckoutPage(item: item),
    ),
  );
}


  void _toast(String msg, IconData icon, Color color) {
    _fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white), const SizedBox(width: 12),
          Flexible(child: Text(msg, style: const TextStyle(color: Colors.white))),
        ]),
      ),
      gravity: ToastGravity.CENTER,
      toastDuration: const Duration(seconds: 2),
    );
  }

  String? _closingFromHours(String? openingHours) {
    if (openingHours == null || openingHours.trim().isEmpty) return null;
    final parts = openingHours.replaceAll('–', '-').split('-');
    return parts.length == 2 ? parts[1].trim() : null;
  }

  String _fmtRating(double? r) {
    if (r == null) return '—';
    final whole = r.truncateToDouble();
    return r == whole ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }

  Widget _ratingStars(double? rating) {
    final rr = ((rating ?? 0).clamp(0, 5)).toDouble();
    final filled = rr.floor();
    final hasHalf = (rr - filled) >= 0.5 && filled < 5;
    final empty = 5 - filled - (hasHalf ? 1 : 0);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < filled; i++) const Icon(Icons.star, size: 16, color: Colors.amber),
      if (hasHalf) const Icon(Icons.star_half, size: 16, color: Colors.amber),
      for (int i = 0; i < empty; i++) const Icon(Icons.star_border, size: 16, color: Colors.amber),
      const SizedBox(width: 6),
      Text(_fmtRating(rr), style: const TextStyle(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _infoRow(String label, String? value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.black54), const SizedBox(width: 8),
        ],
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54))),
        const SizedBox(width: 8),
        Expanded(child: Text((value ?? '').isNotEmpty ? value! : '—',
            style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _statusChip(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    Color bg = Colors.grey.shade200, fg = Colors.black87;
    if (s == 'open') { bg = Colors.green.shade50; fg = Colors.green.shade700; }
    else if (s == 'closed') { bg = Colors.red.shade50; fg = Colors.red.shade700; }
    else if (s == 'busy') { bg = Colors.orange.shade50; fg = Colors.orange.shade800; }
    return Chip(
      label: Text((status ?? '—').toUpperCase()),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(title: const Text("Item Details")),
      body: FutureBuilder<_SellerInfo>(
        future: _sellerFuture ??= _loadSeller(),
        builder: (context, snapshot) {
          final s = snapshot.data;
          final businessName = s?.businessName;
          final status = s?.status;
          final openingHours = s?.openingHours;
          final closing = _closingFromHours(openingHours);
          final rating = s?.rating;
          final businessDesc = s?.description;
          final logo = s?.logoUrl;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.image.isNotEmpty
                      ? Image.network(item.image, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(height: 16),

              Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("MWK ${item.price}", style: const TextStyle(fontSize: 20, color: Colors.green)),
              const SizedBox(height: 12),
              Text(item.description),

              const SizedBox(height: 20),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      if (logo != null && logo.isNotEmpty)
                        CircleAvatar(radius: 18, backgroundImage: NetworkImage(logo)),
                      if (logo != null && logo.isNotEmpty) const SizedBox(width: 10),
                      const Icon(Icons.storefront_rounded, size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(businessName ?? 'Posted by —',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      _ratingStars(rating),
                      const SizedBox(width: 8),
                      _statusChip(status),
                    ]),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    _infoRow('Business name', businessName, icon: Icons.badge_rounded),
                    _infoRow('Closing hours', closing, icon: Icons.access_time_rounded),
                    _infoRow('Status', (status ?? '').isEmpty ? '—' : status!.toUpperCase(),
                        icon: Icons.info_outline_rounded),
                    const SizedBox(height: 6),
                    const Text('Business description', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text((businessDesc ?? '').isNotEmpty ? businessDesc! : '—',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),

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
  onPressed: () => _goToCheckout(widget.item), // from DetailsPage
  child: const Text("Continue to checkout"),
),

            ]),
          );
        },
      ),
    );
  }
}
