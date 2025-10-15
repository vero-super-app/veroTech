import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vero360_app/models/marketplace.model.dart';
import 'package:vero360_app/services/cart_services.dart';
import 'package:vero360_app/services/marketplace.service.dart';

import '../Pages/Home/view_detailsPage.dart';

class MarketPage extends StatefulWidget {
  final CartService cartService;
  const MarketPage({required this.cartService, Key? key}) : super(key: key);

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final MarketplaceService marketplaceService = MarketplaceService();

  final TextEditingController _searchCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Timer? _debounce;
  String _lastQuery = '';
  bool _loading = false;
  bool _photoMode = false; // true when results come from photo search

  late Future<List<MarketplaceDetailModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Data loaders ----------
  Future<List<MarketplaceDetailModel>> _loadAll() async {
    setState(() {
      _loading = true;
      _photoMode = false;
    });
    try {
      final items = await marketplaceService.fetchMarketItems();
      return items;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<MarketplaceDetailModel>> _searchByName(String raw) async {
    final q = raw.trim();
    if (q.isEmpty || q.length < 2) return _loadAll();
    setState(() {
      _loading = true;
      _photoMode = false;
    });
    try {
      final items = await marketplaceService.searchByName(q);
      return items;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<MarketplaceDetailModel>> _searchByPhoto(File file) async {
    setState(() {
      _loading = true;
      _photoMode = true;
    });
    try {
      final items = await marketplaceService.searchByPhoto(file);
      return items;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Search handlers ----------
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final txt = _searchCtrl.text;
      if (txt == _lastQuery) return;
      _lastQuery = txt;
      setState(() => _future = _searchByName(txt));
    });
  }

  void _onSubmit(String value) {
    _debounce?.cancel();
    setState(() => _future = _searchByName(value));
  }

  Future<void> _showPhotoPickerSheet() async {
    if (kIsWeb) {
      // On web, camera is limited; pick from gallery
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (picked == null) return;
      // NOTE: File is not web-safe; this feature is aimed at mobile.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo search is best on mobile builds.')),
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Use Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                  maxWidth: 1280,
                );
                if (picked != null) {
                  final file = File(picked.path);
                  setState(() => _future = _searchByPhoto(file));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 1280,
                );
                if (picked != null) {
                  final file = File(picked.path);
                  setState(() => _future = _searchByPhoto(file));
                }
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    _searchCtrl.clear();
    _lastQuery = '';
    setState(() => _future = _loadAll());
    await _future;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Market Place",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showPhotoPickerSheet,
            icon: const Icon(Icons.camera_alt, color: Colors.black),
            tooltip: 'Search by Photo',
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSubmit,
              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSubmit('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _showPhotoPickerSheet,
                      tooltip: 'Search by Photo',
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),

          // Optional categories (static placeholders)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryTab("All Products", isSelected: !_photoMode && _searchCtrl.text.isEmpty),
                _buildCategoryTab("Food"),
                _buildCategoryTab("Drinks"),
              ],
            ),
          ),

          if (_photoMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: const [
                  Icon(Icons.image_search, size: 16),
                  SizedBox(width: 6),
                  Text("Showing results similar to your photo"),
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<MarketplaceDetailModel>>(
                future: _future,
                builder: (context, snapshot) {
                  // Loading
                  if (_loading && snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            "Failed to load items",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  final items = snapshot.data ?? const <MarketplaceDetailModel>[];
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            _photoMode
                                ? "No visually similar items found"
                                : "No items available",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        final crossAxisCount = isWide ? 3 : 2;
                        // Tune this to avoid pixel overflow; slightly < 0.7 gives room for buttons.
                        final childAspectRatio = isWide ? 0.70 : 0.68;

                        return GridView.builder(
                          itemCount: items.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailsPage(
                                      itemId: item.id,
                                      cartService: widget.cartService,
                                    ),
                                  ),
                                );
                              },
                              child: _buildMarketItem(item),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Widgets ----------
  Widget _buildCategoryTab(String title, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Chip(
        label: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isSelected ? Colors.orange : Colors.grey[300],
      ),
    );
  }

 Widget _buildMarketItem(MarketplaceDetailModel item) {
  return Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Let the photo grow to use any extra vertical space
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              item.image,
              fit: BoxFit.cover,           // fills; no letterboxing
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ),

        // Texts
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                "MWK ${item.price}",
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
              ),
            ],
          ),
        ),

        // Buttons row (fixed height; keeps layout consistent)
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} added to cart')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("AddCart"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsPage(
                          itemId: item.id,
                          cartService: widget.cartService,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("BuyNow"),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}
