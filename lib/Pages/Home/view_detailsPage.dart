import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/Pages/Home/Messages.dart';
import 'package:vero360_app/Pages/checkout_page.dart';
import 'package:vero360_app/models/marketplace.model.dart';
import 'package:vero360_app/services/cart_services.dart';
import 'package:vero360_app/services/serviceprovider_service.dart';
import 'package:vero360_app/models/serviceprovider_model.dart';
import 'package:vero360_app/toasthelper.dart';

import '../video_player_page.dart';

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

class _Media {
  final String url;
  final bool isVideo;
  _Media._(this.url, this.isVideo);
  factory _Media.image(String u) => _Media._(u, false);
  factory _Media.video(String u) => _Media._(u, true);
}

class _DetailsPageState extends State<DetailsPage> {
  Future<_SellerInfo>? _sellerFuture;
  final TextEditingController _commentController = TextEditingController();
  final FToast _fToast = FToast();

  late final PageController _pc;
  int _page = 0;
  List<_Media> _media = const [];
  Timer? _autoTimer;
  static const _autoInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    _sellerFuture = _loadSeller();
    _fToast.init(context);

    final it = widget.item;
    final images = (it.gallery);
    final videos = (it.videos);
    _media = [
      if ((it.image).toString().trim().isNotEmpty) _Media.image(it.image),
      ...images.map(_Media.image),
      ...videos.map(_Media.video),
    ];
    if (_media.length > 1) _startAutoplay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pc.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // autoplay
  void _startAutoplay() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || _media.length <= 1) return;
      final next = (_page + 1) % _media.length;
      _pc.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }
  void _stopAutoplay() { _autoTimer?.cancel(); _autoTimer = null; }
  void _next() { if (_media.isEmpty) return; _stopAutoplay(); final n = (_page + 1) % _media.length; _pc.animateToPage(n, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); Future.delayed(const Duration(seconds: 5), _startAutoplay); }
  void _prev() { if (_media.isEmpty) return; _stopAutoplay(); final p = (_page - 1 + _media.length) % _media.length; _pc.animateToPage(p, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); Future.delayed(const Duration(seconds: 5), _startAutoplay); }

  // seller/data
  Future<_SellerInfo> _loadSeller() async {
    final i = widget.item;
    final info = _SellerInfo(
      businessName: i.sellerBusinessName,
      openingHours: i.sellerOpeningHours,
      status: i.sellerStatus,
      description: i.sellerBusinessDescription,
      rating: i.sellerRating,
      logoUrl: i.sellerLogoUrl,
      serviceProviderId: i.serviceProviderId,
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
      } catch (_) {}
    }
    return info;
  }

  Future<String?> getMyUserId() async {
  final sp = await SharedPreferences.getInstance();
  final token = sp.getString('jwt_token') ?? sp.getString('token');
  if (token == null || token.isEmpty) return null;
  final claims = JwtDecoder.decode(token);
  final id = (claims['sub'] ?? claims['id'])?.toString();
  return (id != null && id.isNotEmpty) ? id : null;
}


  Future<void> _goToCheckout(MarketplaceDetailModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final _ = prefs.getInt('userId');
    Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(item: item)));
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

  void _openVideo(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(url: url)));
  }

 void _openChat(MarketplaceDetailModel item) {
  final String? peer = [item.sellerUserId, item.serviceProviderId]
      .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);

  if (peer == null) {
    _toast('Seller chat unavailable', Icons.info_outline, Colors.red);
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MessagePage(
        peerId: peer,
        peerName: item.sellerBusinessName ?? 'Seller',
        peerAvatarUrl: item.sellerLogoUrl,
      ),
    ),
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
              // ----- MEDIA CAROUSEL -----
              SizedBox(
                height: MediaQuery.of(context).size.width * 9 / 16,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pc,
                      physics: _media.length > 1 ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                      itemCount: _media.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) {
                        final m = _media[i];
                        if (!m.isVideo) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              m.url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                            ),
                          );
                        }
                        return InkWell(
                          onTap: () => _openVideo(m.url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(children: [
                              Container(color: Colors.black26),
                              const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white)),
                            ]),
                          ),
                        );
                      },
                    ),
                    if (_media.length > 1) ...[
                      Positioned(left: 8, top: 0, bottom: 0, child: _NavBtn(icon: Icons.chevron_left, onTap: _prev)),
                      Positioned(right: 8, top: 0, bottom: 0, child: _NavBtn(icon: Icons.chevron_right, onTap: _next)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ----- TEXTS + CHAT BUTTON IN LINE (BOTTOM-RIGHT) -----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("MWK ${item.price}", style: const TextStyle(fontSize: 20, color: Colors.green)),
                        const SizedBox(height: 12),
                        Text(item.description),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Chat with seller',
                        icon: const Icon(Icons.message_rounded, color: Colors.red),
                        onPressed: () => _openChat(item),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ----- SELLER CARD (no transparent horizontal line requested → removed Divider) -----
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
                onPressed: () => _goToCheckout(widget.item),
                child: const Text("Continue to checkout"),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: const SizedBox(
          width: 40, height: 40,
          child: Icon(Icons.chevron_right, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
