// lib/pages/marketplace_crud_page.dart
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/marketplace.model.dart';
import '../services/marketplace.service.dart';
import '../toasthelper.dart';

class MarketplaceCrudPage extends StatefulWidget {
  const MarketplaceCrudPage({super.key});
  @override
  State<MarketplaceCrudPage> createState() => _MarketplaceCrudPageState();
}

class _MarketplaceCrudPageState extends State<MarketplaceCrudPage>
    with SingleTickerProviderStateMixin {
  final svc = MarketplaceService();
  late final TabController _tabs;

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  bool _isActive = true;
  bool _submitting = false;

  // Categories must match backend enum values
  static const List<String> _kCategories = <String>[
    'food', 'drinks', 'electronics', 'clothes', 'shoes', 'other'
  ];
  String? _category = 'other';

  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _pickedBytes;

  List<MarketplaceDetailModel> _items = [];
  bool _loadingItems = true;
  bool _deleting = false;

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

  // ---------- data ----------
  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final data = await svc.fetchMyItems(); // ONLY my items (auth required)
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showCustomToast(
        context,
        'Failed to load items: $e',
        isSuccess: false,
        errorMessage: 'Load failed',
      );
    } finally {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  Future<void> _deleteItem(MarketplaceDetailModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete “${item.name}”?'),
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

    setState(() => _deleting = true);
    try {
      await svc.deleteItem(item.id); // server enforces ownership
      _items.removeWhere((e) => e.id == item.id);
      setState(() {});
      ToastHelper.showCustomToast(context, 'Deleted • ${item.name}', isSuccess: true, errorMessage: 'Deleted');
    } catch (e) {
      ToastHelper.showCustomToast(context, 'Delete failed: $e', isSuccess: false, errorMessage: 'Delete failed');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ---------- image pick ----------
  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 2048);
    if (x != null) {
      _picked = x;
      _pickedBytes = kIsWeb ? await x.readAsBytes() : null;
      setState(() {});
    }
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90, maxWidth: 2048);
    if (x != null) {
      _picked = x;
      _pickedBytes = kIsWeb ? await x.readAsBytes() : null;
      setState(() {});
    }
  }

  void _clearPicked() {
    _picked = null;
    _pickedBytes = null;
    setState(() {});
  }

  // ---------- create ----------
  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    if (_picked == null) {
      ToastHelper.showCustomToast(context, 'Please pick a photo', isSuccess: false, errorMessage: 'Photo required');
      return;
    }

    setState(() => _submitting = true);
    try {
      // 1) secure upload (requires token)
      final imageUrl = await svc.uploadImageFile(File(_picked!.path));

      // 2) create (server stamps ownerId from JWT)
      final item = MarketplaceItem(
        name: _name.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? 0,
        image: imageUrl,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        isActive: _isActive,
        category: _category, // include enum value
      );
      await svc.createItem(item);

      ToastHelper.showCustomToast(context, 'Item Created', isSuccess: true, errorMessage: 'Created');

      // reset & refresh
      _form.currentState!.reset();
      _name.clear();
      _price.clear();
      _desc.clear();
      _picked = null;
      _pickedBytes = null;
      _isActive = true;
      _category = 'other';
      setState(() {});
      await _loadItems();
      _tabs.animateTo(1);
    } catch (e) {
      ToastHelper.showCustomToast(context, 'Create failed: $e', isSuccess: false, errorMessage: 'Create failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final canCreate = !_submitting && _picked != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Add Item'),
            Tab(text: 'Manage My Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildAddTab(canCreate),
          _buildManageTab(),
        ],
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

                _FullBleedPicker(
                  picked: _picked,
                  pickedBytes: _pickedBytes,
                  onPickGallery: _pickFromGallery,
                  onPickCamera: _pickFromCamera,
                  onClearPicked: _clearPicked,
                ),
                const SizedBox(height: 12),

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

                // CATEGORY (ENUM DROPDOWN)
                DropdownButtonFormField<String>(
                  value: _category,
                  items: _kCategories
                      .map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(_titleCase(c)),
                          ))
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

  /// Manage tab
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
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78,
        ),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final it = _items[i];
          return _ItemCard(
            item: it,
            deleting: _deleting,
            onDelete: () => _deleteItem(it),
          );
        },
      ),
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/* ---------------- helper widgets ---------------- */

class _FullBleedPicker extends StatelessWidget {
  const _FullBleedPicker({
    required this.picked,
    required this.pickedBytes,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onClearPicked,
  });

  final XFile? picked;
  final Uint8List? pickedBytes;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onClearPicked;

  @override
  Widget build(BuildContext context) {
    final has = picked != null;
    Widget inner;

    if (has) {
      if (kIsWeb && pickedBytes != null) {
        inner = Image.memory(pickedBytes!, height: 220, width: double.infinity, fit: BoxFit.cover);
      } else {
        inner = Image.file(File(picked!.path), height: 220, width: double.infinity, fit: BoxFit.cover);
      }
    } else {
      inner = Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: Icon(Icons.image, size: 64, color: Colors.black38)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: inner),
        const SizedBox(height: 10),
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: onPickGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onPickCamera,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Camera'),
            ),
            const Spacer(),
            if (has)
              TextButton.icon(
                onPressed: onClearPicked,
                icon: const Icon(Icons.close),
                label: const Text('Clear'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onDelete,
    required this.deleting,
  });

  final MarketplaceDetailModel item;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final hasImage = (item.image).toString().trim().isNotEmpty;
    final cat = (item.category ?? '').isEmpty ? null : item.category;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                Positioned.fill(
                  child: hasImage
                      ? Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
                if (cat != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Chip(
                      label: Text(cat[0].toUpperCase() + cat.substring(1)),
                      backgroundColor: Colors.black.withOpacity(0.75),
                      labelStyle: const TextStyle(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: FilledButton.tonalIcon(
                    onPressed: deleting ? null : onDelete,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.85),
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: deleting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Text('MK ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 18, color: Colors.black45),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.black38),
        ),
      );
}
