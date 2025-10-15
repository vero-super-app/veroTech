import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vero360_app/models/Latest_model.dart';
import 'package:vero360_app/services/postlatestArrival.dart';

import '../toasthelper.dart';

class LatestArrivalsCrudPage extends StatefulWidget {
  const LatestArrivalsCrudPage({super.key});
  @override
  State<LatestArrivalsCrudPage> createState() => _LatestArrivalsCrudPageState();
}

class _LatestArrivalsCrudPageState extends State<LatestArrivalsCrudPage>
    with SingleTickerProviderStateMixin {
  final svc = LatestArrivalsServicess();
  late final TabController _tabs;

  // form
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  bool _submitting = false;

  // image
  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _pickedBytes;

  // list
  List<LatestArrivalModel> _items = [];
  bool _loading = true;
  bool _busyRow = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadMine();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    setState(() => _loading = true);
    try {
      final data = await svc.fetchMine();
      if (!mounted) return;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showCustomToast(context, 'Failed to load: $e', isSuccess: false, errorMessage: 'Load failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // pickers
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

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    if (_picked == null) {
      ToastHelper.showCustomToast(context, 'Please pick a photo', isSuccess: false, errorMessage: 'Photo required');
      return;
    }

    setState(() => _submitting = true);
    try {
      final imageUrl = !kIsWeb
          ? await svc.uploadImageFile(File(_picked!.path))
          : null; // (implement web upload with bytes if needed)

      final priceVal = double.tryParse(_price.text.trim()) ?? 0;

      await svc.create(LatestArrivalModel(
        id: 0,
        image: imageUrl ?? '',
        name: _name.text.trim(),
        price: priceVal,
        createdAt: DateTime.now(),
      ));

      ToastHelper.showCustomToast(context, 'Latest arrival posted', isSuccess: true, errorMessage: 'Created');

      _form.currentState!.reset();
      _name.clear();
      _price.clear();
      _picked = null;
      _pickedBytes = null;
      setState(() {});
      await _loadMine();
      _tabs.animateTo(1);
    } catch (e) {
      ToastHelper.showCustomToast(context, 'Create failed: $e', isSuccess: false, errorMessage: 'Create failed');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(LatestArrivalModel it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete latest arrival'),
        content: Text('Delete “${it.name}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busyRow = true);
    try {
      await svc.delete(it.id);
      ToastHelper.showCustomToast(context, 'Deleted', isSuccess: true, errorMessage: 'Deleted');
      _items.removeWhere((e) => e.id == it.id);
      setState(() {});
    } catch (e) {
      ToastHelper.showCustomToast(context, 'Delete failed: $e', isSuccess: false, errorMessage: 'Delete failed');
    } finally {
      if (mounted) setState(() => _busyRow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest Arrivals'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'New Arrival'), Tab(text: 'Manage My Arrivals')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildCreateTab(), _buildManageTab()],
      ),
    );
  }

  Widget _buildCreateTab() {
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
                const Text('Post Latest Arrival', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                _FullBleedPicker(
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
                  decoration: const InputDecoration(labelText: 'Price (MWK)', filled: true, border: OutlineInputBorder()),
                  validator: (v) {
                    final pv = double.tryParse(v?.trim() ?? '');
                    if (pv == null || pv <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                FilledButton.icon(
                  onPressed: _submitting ? null : _create,
                  icon: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: const Text('Post Arrival'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManageTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMine,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No items yet. Post one!', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
    }

   // In _buildManageTab()

return RefreshIndicator(
  onRefresh: _loadMine,
  child: LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth;
      // Responsive columns + a taller tile on smaller widths
      final cols = w >= 1200 ? 4 : w >= 800 ? 3 : 2;
      final ratio = w >= 1200 ? 0.90 : w >= 800 ? 0.80 : 0.72; // smaller => taller tiles

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
        ),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final it = _items[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Let the image flex so text area never overflows
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16), topRight: Radius.circular(16),
                    ),
                    child: _NetworkCover(url: it.image),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Text(
                    it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                // Price + compact delete
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'MWK ${it.price.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _busyRow ? null : () => _delete(it),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ),
);
  }}

/* ---------- covers & picker (full-bleed, no empty space) ---------- */

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
    Widget content;
    if (has) {
      if (kIsWeb && pickedBytes != null) {
        content = Image.memory(pickedBytes!, fit: BoxFit.cover, gaplessPlayback: true);
      } else {
        content = Image.file(File(picked!.path), fit: BoxFit.cover, gaplessPlayback: true);
      }
    } else {
      content = const _PlaceholderCover();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(aspectRatio: 16 / 9, child: content),
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
            if (has) TextButton.icon(onPressed: onClearPicked, icon: const Icon(Icons.close), label: const Text('Clear')),
          ],
        ),
      ],
    );
  }
}

class _NetworkCover extends StatelessWidget {
  const _NetworkCover({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.grey.shade200),
        Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) => progress == null
              ? child
              : const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          errorBuilder: (_, __, ___) => const _PlaceholderCover(),
        ),
      ],
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEDEDED),
      child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.black38)),
    );
  }
}
