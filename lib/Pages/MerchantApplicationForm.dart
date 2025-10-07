// lib/Pages/MerchantApplicationForm.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vero360_app/services/api_config.dart';
import 'package:vero360_app/services/merchantform.service.dart';
import 'package:vero360_app/Pages/merchantbottomnavbar.dart';
import 'package:vero360_app/toasthelper.dart';

class AppColors {
  static const brand = Color(0xFFFF8A00);
  static const sub = Color(0xFF6B6B6B);
  static const bgTop = Color(0xFFFFF4E9);
}

class MerchantApplicationForm extends StatefulWidget {
  final Future<void> Function()? onFinished;
  const MerchantApplicationForm({Key? key, this.onFinished}) : super(key: key);

  @override
  State<MerchantApplicationForm> createState() => _MerchantApplicationFormState();
}

class _MerchantApplicationFormState extends State<MerchantApplicationForm> {
  final _form = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _businessDescription = TextEditingController();

  TimeOfDay? _opensAt;
  TimeOfDay? _closesAt;

  XFile? _logoFile; // optional
  XFile? _nidFile;  // required

  bool _submitting = false;
  bool _agreed = true;

  // NEW: lock the form if already submitted/pending/approved
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _prefillBusinessName();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final prefs = await SharedPreferences.getInstance();
    final reviewPending = prefs.getBool('merchant_review_pending') ?? false;
    final status = (prefs.getString('applicationStatus') ?? '').toLowerCase();
    setState(() {
      _locked = reviewPending ||
          status == 'pending' ||
          status == 'under_review' ||
          status == 'approved';
    });
  }

  Future<void> _prefillBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? prefs.getString('fullName') ?? '';
    if (name.isNotEmpty && mounted) {
      _businessName.text = "${name.split(' ').first}'s Shop";
    }
  }

  @override
  void dispose() {
    _businessName.dispose();
    _businessDescription.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String get _openingHoursStr {
    if (_opensAt == null || _closesAt == null) return '';
    return '${_fmtTime(_opensAt!)} - ${_fmtTime(_closesAt!)}';
  }

  Future<void> _pickTime({required bool opening}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: opening
          ? (_opensAt ?? const TimeOfDay(hour: 8, minute: 0))
          : (_closesAt ?? const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null && mounted) {
      setState(() => opening ? _opensAt = picked : _closesAt = picked);
    }
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 75,
    );
    if (picked == null) return;
    setState(() => isLogo ? _logoFile = picked : _nidFile = picked);
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.2),
      ),
    );
  }

  Future<void> _goToMerchantHomeAfterSuccess() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final emailOrPhone = prefs.getString('email') ?? prefs.getString('phone') ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MerchantBottomnavbar(email: emailOrPhone)),
        (_) => false,
      );
    });
  }

  Future<void> _submit() async {
    if (_locked) {
      ToastHelper.showCustomToast(context, 'Your application is already submitted.', isSuccess: false, errorMessage: '');
      return;
    }
    if (!_agreed) {
      ToastHelper.showCustomToast(context, 'You must accept the terms', isSuccess: false, errorMessage: '');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_opensAt == null || _closesAt == null) {
      ToastHelper.showCustomToast(context, 'Please select opening & closing time', isSuccess: false, errorMessage: '');
      return;
    }
    if (_nidFile == null) {
      ToastHelper.showCustomToast(context, 'Please attach your National ID photo', isSuccess: false, errorMessage: '');
      return;
    }

    final fields = <String, String>{
      // match backend DTO (camelCase)
      'businessName': _businessName.text.trim(),
      'businessDescription': _businessDescription.text.trim(),
      'openingHours': _openingHoursStr,
      'status': 'pending',
    };

    setState(() => _submitting = true);
    try {
      final base = await ApiConfig.readBase();
      final ok = await ServiceProviderService(baseUrl: base).submitServiceProviderMultipart(
        fields: fields,
        nationalIdFile: _nidFile!,   // sent as "nationalIdImage"
        logoFile: _logoFile,         // optional "logoimage"
        context: context,
      );

      if (!ok) return;

      // Persist statuses so Profile banner knows KYC is complete & review is in progress.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('merchant_review_pending', true);
      await prefs.setString('applicationStatus', 'under_review');
      await prefs.setString('kycStatus', 'complete');

      ToastHelper.showCustomToast(context, 'Application submitted ✅', isSuccess: true, errorMessage: '');

      // Optional hook
      try { await widget.onFinished?.call(); } catch (_) {}

      // Lock immediately to prevent second submit in same session
      setState(() => _locked = true);

      await _goToMerchantHomeAfterSuccess();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment(0, -1), end: Alignment(0, 1), colors: [AppColors.bgTop, Colors.white]),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconButton(onPressed: _submitting ? null : () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back)),
                    const SizedBox(width: 6),
                    const Text('Merchant Application', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  _pill(Icons.verified_user_outlined, _locked
                      ? 'Your application is in review. We’ll notify you shortly.'
                      : 'Fill this short form to start selling on Vero.'),
                  const SizedBox(height: 14),

                  if (_locked)
                    _lockedCard()
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _form,
                        child: Column(children: [
                          TextFormField(
                            controller: _businessName,
                            decoration: _dec('Business name'),
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessDescription,
                            decoration: _dec('Business description'),
                            minLines: 3,
                            maxLines: 5,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),

                          Row(children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(opening: true),
                                borderRadius: BorderRadius.circular(14),
                                child: InputDecorator(
                                  decoration: _dec('Opens at'),
                                  child: Text(_opensAt == null ? 'Select time' : _fmtTime(_opensAt!),
                                      style: TextStyle(color: _opensAt == null ? Colors.black45 : Colors.black87)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(opening: false),
                                borderRadius: BorderRadius.circular(14),
                                child: InputDecorator(
                                  decoration: _dec('Closes at'),
                                  child: Text(_closesAt == null ? 'Select time' : _fmtTime(_closesAt!),
                                      style: TextStyle(color: _closesAt == null ? Colors.black45 : Colors.black87)),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),

                          _uploadRow(label: 'Logo image (optional)', file: _logoFile, onPick: () => _pickImage(isLogo: true)),
                          const SizedBox(height: 12),
                          _uploadRow(label: 'National ID photo', file: _nidFile, onPick: () => _pickImage(isLogo: false), required: true),
                          const SizedBox(height: 12),

                          Row(children: [
                            _chip('Status: pending'),
                            const SizedBox(width: 8),
                            _chip('Verified: no'),
                            const SizedBox(width: 8),
                            _chip('Rating: 0'),
                          ]),
                          const SizedBox(height: 12),

                          Row(children: [
                            Checkbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false)),
                            const Expanded(child: Text('I confirm the information provided is accurate.', style: TextStyle(fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 6),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(_submitting ? 'Submitting…' : 'Submit application'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brand,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _lockedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thanks! Your application is being reviewed.',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('We’ll email you once it’s approved.'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToMerchantHomeAfterSuccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to merchant home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadRow({required String label, required VoidCallback onPick, XFile? file, bool required = false}) {
    return InputDecorator(
      decoration: _dec(label),
      child: Row(children: [
        if (file != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: kIsWeb
                ? Image.network(file.path, height: 44, width: 44, fit: BoxFit.cover)
                : Image.file(File(file.path), height: 44, width: 44, fit: BoxFit.cover),
          )
        else
          Container(
            height: 44, width: 44,
            decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.image_outlined, color: Colors.black45),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(file == null ? (required ? 'Required' : 'Select file') : file.name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        TextButton.icon(onPressed: onPick, icon: const Icon(Icons.upload_outlined), label: const Text('Upload')),
      ]),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.brand),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.sub, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF5F6F9), borderRadius: BorderRadius.circular(30)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
