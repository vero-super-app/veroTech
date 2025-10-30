// lib/pages/marketplace_crud_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../models/marketplace.model.dart';
import '../services/marketplace.service.dart';
import '../toasthelper.dart';

// ⬇️ import your edit page (create it if you haven't yet)
import 'marketplace_edit_page.dart';

class LocalMedia {
  final Uint8List bytes;
  final String filename;
  final String? mime;
  final bool isVideo;
  const LocalMedia({
    required this.bytes,
    required this.filename,
    this.mime,
    this.isVideo = false,
  });
}

class MarketplaceCrudPage extends StatefulWidget {
  const MarketplaceCrudPage({super.key});
  @override
  State<MarketplaceCrudPage> createState() => _MarketplaceCrudPageState();
}

class _MarketplaceCrudPageState extends State<MarketplaceCrudPage>
    with SingleTickerProviderStateMixin {
  final svc = MarketplaceService();
  final _picker = ImagePicker();
  late final TabController _tabs;

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();

  bool _isActive = true;
  bool _submitting = false;

  static const List<String> _kCategories = <String>[
    'food', 'drinks', 'electronics', 'clothes', 'shoes', 'other'
  ];
  String? _category = 'other';

  // media (create tab)
  LocalMedia? _cover;
  final List<LocalMedia> _gallery = <LocalMedia>[];
  final List<LocalMedia> _videos  = <LocalMedia>[];

  // manage tab
  List<MarketplaceDetailModel> _items = [];
  bool _loadingItems = true;
  bool _busyRow = false; // disables per-card buttons when true

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  // ---------------- data ----------------
  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final data = await svc.fetchMyItems();
      if (!mounted) return;
      setState(() => _items = data);
    } finally {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  Future<void> _deleteItem(MarketplaceDetailModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete “${item.name}”? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busyRow = true);
    try {
      await svc.deleteItem(item.id);
      _items.removeWhere((e) => e.id == item.id);
      setState(() {});
      ToastHelper.showCustomToast(context, 'Deleted • ${item.name}', isSuccess: true, errorMessage: 'Deleted');
    } catch (e) {
      ToastHelper.showCustomToast(context, 'Delete failed: $e', isSuccess: false, errorMessage: 'Delete failed');
    } finally {
      if (mounted) setState(() => _busyRow = false);
    }
  }

  Future<void> _editItem(MarketplaceDetailModel item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MarketplaceEditPage(item: item)),
    );
    if (changed == true) {
      // refresh grid after editing
      await _loadItems();
    }
  }

  // ---------------- pickers (bytes) ----------------
  Future<void> _pickCover(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 90, maxWidth: 2048);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _cover = LocalMedia(
        bytes: bytes,
        filename: x.name,
        mime: lookupMimeType(x.name, headerBytes: bytes),
      );
    });
  }

  Future<void> _pickGalleryMulti() async {
    final xs = await _picker.pickMultiImage(imageQuality: 90, maxWidth: 2048);
    for (final x in xs) {
      final bytes = await x.readAsBytes();
      _gallery.add(LocalMedia(
        bytes: bytes,
        filename: x.name,
        mime: lookupMimeType(x.name, headerBytes: bytes),
      ));
    }
    setState(() {});
  }

  Future<void> _pickVideo() async {
    final x = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
    if (x == null) return;
    final bytes = await x.readAsBytes();
    _videos.add(LocalMedia(
      bytes: bytes,
      filename: x.name,
      mime: lookupMimeType(x.name, headerBytes: bytes),
      isVideo: true,
    ));
    setState(() {});
  }

  void _removeGalleryAt(int i) { _gallery.removeAt(i); setState(() {}); }
  void _removeVideoAt(int i) { _videos.removeAt(i); setState(() {}); }
  void _clearCover() { _cover = null; setState(() {}); }

  // ---------------- uploads ----------------
  Future<List<String>> _uploadAll(List<LocalMedia> items) async {
    final urls = <String>[];
    for (final m in items) {
      final u = await svc.uploadBytes(m.bytes, filename: m.filename);
      urls.add(u);
    }
    return urls;
  }

  // ---------------- create ----------------
  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    if (_cover == null) {
      ToastHelper.showCustomToast(context, 'Please pick a cover photo',
          isSuccess: false, errorMessage: 'Photo required');
      return;
    }

    setState(() => _submitting = true);
    try {
      final coverUrl   = await svc.uploadBytes(_cover!.bytes, filename: _cover!.filename);
      final galleryUrl = await _uploadAll(_gallery);
      final videoUrl   = await _uploadAll(_videos);

      final item = MarketplaceItem(
        name: _name.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? 0,
        image: coverUrl,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        isActive: _isActive,
        category: _category,
        gallery: galleryUrl,
        videos: videoUrl,
      );

      await svc.createItem(item);

      ToastHelper.showCustomToast(context, 'Item Posted', isSuccess: true, errorMessage: 'Created');

      // reset
      _form.currentState!.reset();
      _name.clear(); _price.clear(); _desc.clear();
      _cover = null; _gallery.clear(); _videos.clear();
      _isActive = true; _category = 'other';
      setState(() {});
      await _loadItems();
      _tabs.animateTo(1);
    } catch (e) {
      ToastHelper.showCustomToast(context, 'Create failed: $e', isSuccess: false, errorMessage: 'Create failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final canCreate = !_submitting && _cover != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Add Item'), Tab(text: 'Manage My Items')],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildAddTab(canCreate),
            _buildManageTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTab(bool canCreate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                // cover picker preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cover == null
                      ? Container(
                          height: 220,
                          color: Colors.grey.shade100,
                          child: const Center(child: Icon(Icons.image, size: 64, color: Colors.black38)),
                        )
                      : Image.memory(_cover!.bytes, height: 220, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _pickCover(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickCover(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Camera'),
                    ),
                    const Spacer(),
                    if (_cover != null)
                      TextButton.icon(
                        onPressed: _clearCover,
                        icon: const Icon(Icons.close),
                        label: const Text('Clear'),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text('More photos (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _mediaStripImages(),

                const SizedBox(height: 12),
                const Text('Videos (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _mediaStripVideos(),

                const SizedBox(height: 16),

                // NAME
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name', filled: true, border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),

                // PRICE
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Price (MK)', filled: true, border: OutlineInputBorder()),
                  validator: (v) {
                    final pv = double.tryParse(v?.trim() ?? '');
                    if (pv == null || pv <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // CATEGORY
                DropdownButtonFormField<String>(
                  value: _category,
                  items: _kCategories
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(_titleCase(c))))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please select a category' : null,
                ),
                const SizedBox(height: 12),

                // DESCRIPTION
                TextFormField(
                  controller: _desc,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description (optional)', filled: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),

                // ACTIVE
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),

                // SUBMIT
                FilledButton.icon(
                  onPressed: canCreate ? _create : null,
                  icon: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('Post on Marketplace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mediaStripImages() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _gallery.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == _gallery.length) {
            return OutlinedButton.icon(
              onPressed: _pickGalleryMulti,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add'),
            );
          }
          final m = _gallery[i];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(m.bytes, width: 128, height: 96, fit: BoxFit.cover),
              ),
              Positioned(
                right: 4, top: 4,
                child: InkWell(
                  onTap: () => _removeGalleryAt(i),
                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mediaStripVideos() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _videos.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == _videos.length) {
            return OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Add video'),
            );
          }
          return Stack(
            children: [
              Container(
                width: 160, height: 72,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Icon(Icons.play_arrow_rounded)),
              ),
              Positioned(
                right: 4, top: 4,
                child: InkWell(
                  onTap: () => _removeVideoAt(i),
                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildManageTab() {
    if (_loadingItems) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No items yet. Add your first product!', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive columns
          int crossAxisCount = 2;
          if (constraints.maxWidth >= 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 700) {
            crossAxisCount = 3;
          }

          // Safe aspect ratio: image 16:9 + texts/buttons
          // 0.70…0.80 works well across widths; tweak slightly for wide screens
  final aspect = (constraints.maxWidth >= 700) ? 0.90 : 0.88; // space yapansi pa card ← was 0.75 / 0.70


          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspect,
            ),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final it = _items[i];
              return _ManageCard(
                item: it,
                busy: _busyRow,
                onEdit: () => _editItem(it),
                onDelete: () => _deleteItem(it),
              );
            },
          );
        },
      ),
    );
  }

  String _titleCase(String s) => s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
}







/* ---------- Manage card, tuned to avoid overflows ---------- */

class _ManageCard extends StatelessWidget {
  const _ManageCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.busy,
  });

  final MarketplaceDetailModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top media (fixed ratio prevents overflow)
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.black38),
                    ),
                  ),
                ),
              ),
              // Overlay actions (top-right)
              Positioned(
                right: 6,
                top: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _roundIcon(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onTap: busy ? null : onEdit,
                    ),
                    const SizedBox(width: 6),
                    _roundIcon(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      color: Colors.red.shade600,
                      onTap: busy ? null : onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          // Price + fallback actions (for very narrow tiles)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Text('MK ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                // small buttons visible on narrow layouts;
                // they duplicate the overlay actions but help when overlay is cramped
           
               
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({
    required IconData icon,
    String? tooltip,
    Color? color,
    VoidCallback? onTap,
  }) {
    final btn = Material(
      color: Colors.white.withOpacity(0.90),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? Colors.black87),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }
}
