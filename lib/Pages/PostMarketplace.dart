// lib/pages/marketplace_crud_page.dart
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

// services & models
import 'package:vero360_app/services/marketplace.service.dart';
import 'package:vero360_app/toasthelper.dart';
import '../models/marketplace.model.dart';
import '../services/api_config.dart';



class MarketplaceCrudPage extends StatefulWidget {
  const MarketplaceCrudPage({super.key});
  @override
  State<MarketplaceCrudPage> createState() => _MarketplaceCrudPageState();
}

class _MarketplaceCrudPageState extends State<MarketplaceCrudPage>
    with SingleTickerProviderStateMixin {
  final svc = MarketplaceService();

  // tabs
  late final TabController _tabs;

  // create form
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  bool _isActive = true;
  bool _submitting = false;

  // image (REQUIRED)
  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _pickedBytes;

  // manage list
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

  // ---------- Upload to {base}/uploads (required) ----------
  Future<String> _uploadImageXFile(XFile x) async {
    final base = await ApiConfig.readBase();
    debugPrint('Uploading to: $base/uploads');
    final uri = Uri.parse('$base/uploads');

    final req = http.MultipartRequest('POST', uri);
    final isPng = x.name.toLowerCase().endsWith('.png');
    final mt = isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');

    if (kIsWeb) {
      final bytes = await x.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: x.name, contentType: mt));
    } else {
      req.files.add(await http.MultipartFile.fromPath('file', x.path, filename: x.name, contentType: mt));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Upload failed: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body);
    final url = body['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Upload ok but no url returned');
    }
    return url;
  }

  // ---------- CREATE ----------
  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;

    if (_picked == null) {
      ToastHelper.showCustomToast(
        context,
        'Please pick a photo (camera or gallery)',
        isSuccess: false,
        errorMessage: 'Photo required',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // 1) upload required image
      final imageUrl = await _uploadImageXFile(_picked!);

      // 2) create item
      final item = MarketplaceItem(
        name: _name.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? 0,
        image: imageUrl, // always from upload
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        isActive: _isActive,
      );

      final created = await svc.createItem(item);

      ToastHelper.showCustomToast(
        context,
        'Item Created ',
        isSuccess: true,
        errorMessage: 'Created', // required param in your helper
      );

      // reset
      _form.currentState!.reset();
      _name.clear();
      _price.clear();
      _desc.clear();
      _picked = null;
      _pickedBytes = null;
      _isActive = true;
      setState(() {});

      // refresh list so it appears in Manage tab
      _loadItems();
      _tabs.animateTo(1); // jump to Manage tab after create
    } catch (e) {
      ToastHelper.showCustomToast(
        context,
        'Create failed: $e',
        isSuccess: false,
        errorMessage: 'Create failed',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------- LIST & DELETE (no ID typed) ----------
  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final data = await svc.fetchMarketItems();
      if (!mounted) return;
      setState(() {
        _items = data;
      });
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
        content: Text('Delete **${item.name}**?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await svc.deleteItem(item.id);
      ToastHelper.showCustomToast(
        context,
        'Deleted • ${item.name}',
        isSuccess: true,
        errorMessage: 'Deleted',
      );
      _items.removeWhere((e) => e.id == item.id);
      setState(() {});
    } catch (e) {
      ToastHelper.showCustomToast(
        context,
        'Delete failed: $e',
        isSuccess: false,
        errorMessage: 'Delete failed',
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final canCreate = !_submitting && _picked != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Add Item in my shop'),
            Tab(text: 'Manage  my shop'),
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

  // -------------------- ADD TAB --------------------
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

                _FullBleedImagePicker(
                  picked: _picked,
                  pickedBytes: _pickedBytes,
                  onPickGallery: _pickFromGallery,
                  onPickCamera: _pickFromCamera,
                  onClearPicked: _clearPicked,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name', filled: true, border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Price (MK)',
                    hintText: 'e.g. 3885',
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final pv = double.tryParse(v?.trim() ?? '');
                    if (pv == null || pv <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _desc,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description (optional)', filled: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),

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

  // -------------------- MANAGE TAB --------------------
  Widget _buildManageTab() {
    if (_loadingItems) {
      return const Center(child: CircularProgressIndicator());
    }
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
          final w = constraints.maxWidth;
          int cross = 2;
          if (w >= 600 && w < 900) cross = 3;
          else if (w >= 900) cross = 4;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final it = _items[i];
              return _ItemCard(
                item: it,
                onDelete: () => _deleteItem(it),
                deleting: _deleting,
              );
            },
          );
        },
      ),
    );
  }
}

/// Full-bleed, modern picker preview: keeps aspect and fills with cover
class _FullBleedImagePicker extends StatelessWidget {
  const _FullBleedImagePicker({
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
    final hasImage = picked != null;
    Widget content;

    if (hasImage) {
      if (kIsWeb && pickedBytes != null) {
        content = Image.memory(
          pickedBytes!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover, // FULL photo feel
        );
      } else if (!kIsWeb) {
        content = Image.file(
          File(picked!.path),
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        content = _placeholder();
      }
    } else {
      content = _placeholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(child: content),
                // subtle gradient for text legibility (future labels)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.00), Colors.black.withOpacity(0.06)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            if (hasImage)
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

  Widget _placeholder() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.black38),
      ),
    );
  }
}

/// Modern product card with full-bleed image and on-card delete
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

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {}, // could open details later
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // image area (FULL bleed feel)
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
                  // overlay delete button
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

            // info
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
      ),
    );
  }

  Widget _imgFallback() => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.black38)),
      );
}
