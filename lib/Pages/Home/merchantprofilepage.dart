// lib/Pages/profile_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:vero360_app/Pages/Home/myorders.dart';
import 'package:vero360_app/Pages/QRcode.dart';
import 'package:vero360_app/Pages/ToRefund.dart';
import 'package:vero360_app/Pages/myaccomodation.dart';
import 'package:vero360_app/Pages/Toreceive.dart';
import 'package:vero360_app/Pages/Toship.dart';
import 'package:vero360_app/Pages/address.dart';
import 'package:vero360_app/Pages/changepassword.dart';
import 'package:vero360_app/models/Latest_model.dart';
import 'package:vero360_app/screens/login_screen.dart';
import 'package:vero360_app/services/auth_service.dart';
import 'package:vero360_app/services/latest_Services.dart';
import 'package:vero360_app/toasthelper.dart';
import 'package:vero360_app/Pages/MerchantApplicationForm.dart'; // <- for KYC reopen

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({Key? key}) : super(key: key);

  @override
  State<MerchantProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<MerchantProfilePage> {
  final Color _brandNavy = const Color(0xFF16284C);
  final Color _veroOrange = const Color(0xFFFF8A00);
  final Color _cardBg = Colors.white;
  final Color _chipGrey = const Color(0xFFF4F5F7);

  String name = "Guest User";
  String email = "No Email";
  String phone = "No Phone";
  String address = "No Address";
  String profileUrl = "";

  bool _loading = false;

  // application state
  String applicationStatus = ""; // approved | pending | under_review | rejected | ''
  String kycStatus = "";         // e.g., incomplete/complete
  bool reviewPending = false;    // local flag to show banner even if server unreachable

  // demo wallet figures
  double balance = 450;
  double cashback = 23;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCurrentUser();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name       = prefs.getString('fullName') ?? prefs.getString('name') ?? 'Guest User';
      email      = prefs.getString('email') ?? 'No Email';
      phone      = prefs.getString('phone') ?? 'No Phone';
      address    = prefs.getString('address') ?? 'No Address';
      profileUrl = prefs.getString('profilepicture') ?? '';
      applicationStatus = prefs.getString('applicationStatus') ?? '';
      kycStatus        = prefs.getString('kycStatus') ?? '';
      reviewPending    = prefs.getBool('merchant_review_pending') ?? false;
    });
  }

  String _joinName(String? first, String? last, {required String fallback}) {
    final parts = [first, last].where((s) => s != null && s!.trim().isNotEmpty);
    if (parts.isEmpty) return fallback;
    return parts.join(' ');
  }

  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ??
        prefs.getString('token') ??
        prefs.getString('authToken') ??
        '';
  }

  Future<void> _persistUserToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final user = (data['user'] is Map) ? (data['user'] as Map) : data;

    final userName = (user['name'] ??
            _joinName(user['firstName'], user['lastName'], fallback: ''))
        .toString();
    final emailVal = (user['email'] ?? user['userEmail'] ?? '').toString();
    final phoneVal = (user['phone'] ?? '').toString();
    final picVal =
        (user['profilepicture'] ?? user['profilePicture'] ?? '').toString();

    String addr = 'No Address';
    final addresses = user['addresses'];
    if (addresses is List && addresses.isNotEmpty) {
      final first = addresses.first;
      if (first is Map && first['address'] != null) {
        addr = first['address'].toString();
      } else if (first is String && first.trim().isNotEmpty) {
        addr = first;
      }
    } else if (user['address'] != null) {
      addr = user['address'].toString();
    }

    // statuses
    final serverAppStatus = (user['applicationStatus'] ?? '').toString().toLowerCase();
    final serverKycStatus = (user['kycStatus'] ?? '').toString().toLowerCase();

    setState(() {
      name = userName.trim().isEmpty ? 'Guest User' : userName.trim();
      email = emailVal.trim().isEmpty ? 'No Email' : emailVal.trim();
      phone = phoneVal.trim().isEmpty ? 'No Phone' : phoneVal.trim();
      address = (addr.trim().isEmpty) ? 'No Address' : addr.trim();
      profileUrl = picVal;

      applicationStatus = serverAppStatus.isNotEmpty ? serverAppStatus : applicationStatus;
      kycStatus = serverKycStatus.isNotEmpty ? serverKycStatus : kycStatus;

      // reviewPending is true unless approved
      reviewPending = (applicationStatus != 'approved');
    });

    await prefs.setString('fullName', name);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('phone', phone);
    await prefs.setString('address', address);
    await prefs.setString('profilepicture', profileUrl);
    await prefs.setString('applicationStatus', applicationStatus);
    await prefs.setString('kycStatus', kycStatus);
    await prefs.setBool('merchant_review_pending', reviewPending);
  }

  Future<void> _fetchCurrentUser() async {
    setState(() => _loading = true);
    try {
      final token = await _getAuthToken();
      if (token.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('https://vero-backend.onrender.com/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final Map<String, dynamic> payload =
            decoded is Map && decoded['data'] is Map
                ? Map<String, dynamic>.from(decoded['data'])
                : (decoded is Map ? Map<String, dynamic>.from(decoded) : {});
        await _persistUserToPrefs(payload);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in.')),
        );
      } else {
        debugPrint('Failed to fetch user: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            if (profileUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Remove current photo (local)'),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => profileUrl = '');
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('profilepicture', '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (file == null) return;
      await _uploadProfilePicture(file);
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showCustomToast(context, 'Could not pick image', isSuccess: false, errorMessage: '');
    }
  }

  Future<void> _uploadProfilePicture(XFile picked) async {
    final token = await _getAuthToken();
    if (token.isEmpty) {
      if (!mounted) return;
      ToastHelper.showCustomToast(context, 'Please log in to update your photo', isSuccess: false, errorMessage: '');
      return;
    }

    setState(() => _loading = true);
    try {
      final uri = Uri.parse('https://vero-backend.onrender.com/users/me/profile-picture');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'profile.png'));
      } else {
        req.files.add(await http.MultipartFile.fromPath('file', picked.path));
      }

      final sent = await req.send();
      final resp = await http.Response.fromStream(sent);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonMap = jsonDecode(resp.body);
        final payload = (jsonMap is Map && jsonMap['data'] is Map)
            ? Map<String, dynamic>.from(jsonMap['data'])
            : (jsonMap is Map ? Map<String, dynamic>.from(jsonMap) : {});
        final newUrl = (payload['profilepicture'] ?? payload['profilePicture'] ?? payload['url'] ?? '').toString();

        setState(() => profileUrl = newUrl);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilepicture', newUrl);

        if (!mounted) return;
        ToastHelper.showCustomToast(context, 'Profile picture updated', isSuccess: true, errorMessage: '');
      } else {
        if (!mounted) return;
        ToastHelper.showCustomToast(context, 'Failed to upload', isSuccess: false, errorMessage: '');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loading = true);
    try {
      await AuthService().logout(context: context);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fullName');
      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('phone');
      await prefs.remove('address');
      await prefs.remove('profilepicture');
      // keep review flag/status if you want it after re-login; usually server is source of truth
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: _brandNavy,
      elevation: 0,
      titleSpacing: 0,
      title: const Text('Merchant Profile', style: TextStyle(color: Colors.white)),
      actions: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  // --- BANNER: Application under review + Finish KYC ---
  Widget _reviewBanner() {
    if (!reviewPending) return const SizedBox.shrink();

    final statusText = (applicationStatus.isEmpty || applicationStatus == 'pending' || applicationStatus == 'under_review')
        ? 'Application is under review'
        : (applicationStatus == 'rejected' ? 'Application rejected' : applicationStatus);

    final needsKyc = (kycStatus.isEmpty || kycStatus == 'incomplete' || kycStatus == 'pending');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD9B3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB86E00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$statusText.${needsKyc ? " Please complete your KYC." : ""}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          if (needsKyc)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MerchantApplicationForm(
                      onFinished: () async {
                        // After adding missing KYC docs, just pop back to profile and refresh
                        if (!mounted) return;
                        ToastHelper.showCustomToast(context, 'KYC updated', isSuccess: true, errorMessage: '');
                        await _fetchCurrentUser();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
              child: const Text('Finish KYC'),
            ),
        ],
      ),
    );
  }

  Widget _topProfileCard() {
    final avatar = GestureDetector(
      onTap: _showPhotoSheet,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.black12,
        backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
        child: profileUrl.isEmpty
            ? const Icon(Icons.person, size: 28, color: Colors.black45)
            : null,
      ),
    );

    // Show status chip text
    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: applicationStatus == 'approved'
            ? const Color(0xFFE7F6EC)
            : const Color(0xFFFFF3E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        applicationStatus.isEmpty ? '—' : applicationStatus.toUpperCase(),
        style: TextStyle(
          color: applicationStatus == 'approved' ? Colors.green.shade700 : const Color(0xFFB86E00),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );

    return Stack(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: _brandNavy,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        Positioned.fill(
          top: 16,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 6),
                        statusChip,
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (_) {},
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'active',
                        enabled: false,
                        child: Row(
                          children: [
                            Icon(
                              applicationStatus == 'approved' ? Icons.verified : Icons.hourglass_bottom,
                              size: 16,
                              color: applicationStatus == 'approved' ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              applicationStatus == 'approved' ? 'Approved' : 'Under review',
                              style: TextStyle(
                                color: applicationStatus == 'approved' ? Colors.green.shade700 : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip({
    required IconData icon,
    required Color bg,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _chipGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: _brandNavy),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ordersQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _orderAction('My Orders', Icons.book, () {
            _openBottomSheet(const OrdersPage());
          }),
          _orderAction('Shipped', Icons.local_shipping_outlined, () {
            _openBottomSheet(const ToShipPage());
          }),
          _orderAction('Received', Icons.move_to_inbox_outlined, () {
            _openBottomSheet(const DeliveredOrdersPage());
          }),
          _orderAction('Accomodation', Icons.house, () {
            _openBottomSheet(const MyBookingsPage());
          }),
          _orderAction('Refund', Icons.replay_circle_filled_outlined, () {
            _openBottomSheet(const ToRefundPage());
          }),
        ],
      ),
    );
  }

  Widget _orderAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _chipGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _brandNavy),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _openBottomSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: child,
      ),
    );
  }

  Widget _otherDetailsGrid() {
    final items = <_DetailItem>[
      _DetailItem('Post on Marketplace', Icons.qr_code_2, () {
        _openBottomSheet(const ProfileQrPage());
      }),
      _DetailItem('My Address', Icons.location_on, () {
        _openBottomSheet(const AddressPage());
      }),
      _DetailItem('Change Password', Icons.lock_outline, () {
        _openBottomSheet(const ChangePasswordPage());
      }),
      _DetailItem('Post Latest arrival', Icons.notifications_none, () {}),
      _DetailItem('Language', Icons.language, () {}),
      _DetailItem('Logout', Icons.logout, _logout),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 8, 6, 10),
            child: Text('Other Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 100,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (_, i) => _detailTile(items[i]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: _appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _topProfileCard(),
            const SizedBox(height: 12),
            _reviewBanner(),             // <-- REVIEW/KYC section here
            const SizedBox(height: 24),
            _ordersQuickActions(),
            _otherDetailsGrid(),
            const LatestArrivalsSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(_DetailItem item) {
    return InkWell(
      onTap: () async {
        await item.onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: _chipGrey,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: _brandNavy, size: 24),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  _DetailItem(this.label, this.icon, FutureOr<void> Function() handler)
      : onTap = (() {
          final result = handler();
          if (result is Future) {
            return result;
          }
          return Future.value();
        });
}

// --------- Latest Arrivals section (unchanged, kept for completeness) ---------

class LatestArrivalsSection extends StatefulWidget {
  const LatestArrivalsSection({super.key});

  @override
  State<LatestArrivalsSection> createState() => _LatestArrivalsSectionState();
}

class _LatestArrivalsSectionState extends State<LatestArrivalsSection> {
  final _service = LatestArrivalServices();
  late Future<List<LatestArrivalModels>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchLatestArrivals();
  }

  String _fmtKwacha(int n) {
    final s = n.toString();
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Latest Arrivals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<List<LatestArrivalModels>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Could not load arrivals.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No items yet.', style: TextStyle(color: Colors.red))),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return _ProductCardFromApi(
                    imageUrl: it.imageUrl,
                    name: it.name,
                    priceText: 'MWK ${_fmtKwacha(it.price)}',
                    brandOrange: const Color(0xFFFF8A00),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProductCardFromApi extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String priceText;
  final Color brandOrange;

  const _ProductCardFromApi({
    required this.imageUrl,
    required this.name,
    required this.priceText,
    required this.brandOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140, color: const Color(0xFFEDEDED),
                      child: const Center(child: Icon(Icons.image_not_supported_rounded)),
                    ),
                  )
                : Container(
                    height: 140, color: const Color(0xFFEDEDED),
                    child: const Center(child: Icon(Icons.image_not_supported_rounded)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(priceText,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showCardOptions(context, name),
                  icon: Icon(Icons.add_circle, color: brandOrange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCardOptions(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Choose an action', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.green),
            title: const Text('Add to cart'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added to cart')));
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: brandOrange),
            title: const Text('More details'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }
}
