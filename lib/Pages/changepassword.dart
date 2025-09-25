// lib/pages/change_password_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/toasthelper.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key, this.userId = 1}) : super(key: key);
  final int userId; // defaults to 1 as requested

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // THEME
  final Color _brand = const Color(0xFFFF8A00); // orange

  // FORM
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _saving = false;
  double _strength = 0.0;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(_recalcStrength);
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.removeListener(_recalcStrength);
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _recalcStrength() {
    final s = _newCtrl.text;
    setState(() => _strength = _passwordStrength(s));
  }

  double _passwordStrength(String s) {
    if (s.isEmpty) return 0;
    int score = 0;
    if (s.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(s)) score++;
    if (RegExp(r'[a-z]').hasMatch(s)) score++;
    if (RegExp(r'\d').hasMatch(s)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(s)) score++;
    return (score / 5).clamp(0, 1).toDouble();
  }

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('jwt_token');
  }

  Future<Uri> _buildUri() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base');
    final base = (saved != null && saved.isNotEmpty)
        ? saved
        : kIsWeb
            ? 'http://localhost:3000'
            : (defaultTargetPlatform == TargetPlatform.android
                ? 'http://10.0.2.2:3000'
                : 'http://127.0.0.1:3000');
    return Uri.parse('$base/users/${widget.userId}/password');
  }

  String _prettyError(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        final msg = parsed['message'] ?? parsed['error'];
        if (msg is List && msg.isNotEmpty) return msg.first.toString();
        return msg?.toString() ?? body;
      }
      if (parsed is List && parsed.isNotEmpty) return parsed.first.toString();
      return body;
    } catch (_) {
      return body;
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final token = await _readToken();
      if (token == null || token.isEmpty) {
        ToastHelper.showCustomToast(
          context,
          'Please log in again.',
          isSuccess: false,
          errorMessage: 'Missing token',
        );
        setState(() => _saving = false);
        return;
      }

      final uri = await _buildUri();
      final res = await http
          .put(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'currentPassword': _currentCtrl.text,
              'newPassword': _newCtrl.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 204) {
        if (!mounted) return;
        ToastHelper.showCustomToast(
          context,
          '✅ Password changed successfully',
          isSuccess: true,
          errorMessage: '',
        );
        Navigator.pop(context, true);
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        if (!mounted) return;
        ToastHelper.showCustomToast(
          context,
          'Session expired. Please log in.',
          isSuccess: false,
          errorMessage: 'HTTP ${res.statusCode}',
        );
      } else {
        if (!mounted) return;
        ToastHelper.showCustomToast(
          context,
          'Failed to change password',
          isSuccess: false,
          errorMessage: _prettyError(res.body),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showCustomToast(
        context,
        'Error while updating password',
        isSuccess: false,
        errorMessage: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _barColor(double v) {
    if (v < .34) return Colors.redAccent;
    if (v < .67) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF222222),
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: const Text('Change password'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 22,
                  spreadRadius: -8,
                  offset: Offset(0, 14),
                  color: Color(0x1A000000),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_brand.withOpacity(.15), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      size: 40, color: Color(0xFF6B778C)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change password', style: titleStyle),
                      const SizedBox(height: 6),
                      Text(
                        'Use a strong, unique password you haven’t used elsewhere.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: const Color(0xFF6B778C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Current
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: !_showCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _showCurrent = !_showCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your current password' : null,
                ),
                const SizedBox(height: 14),

                // New
                TextFormField(
                  controller: _newCtrl,
                  obscureText: !_showNew,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _showNew = !_showNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a new password';
                    if (v.length < 8) return 'Must be at least 8 characters';
                    if (!RegExp(r'[A-Z]').hasMatch(v)) {
                      return 'Add at least one uppercase letter';
                    }
                    if (!RegExp(r'\d').hasMatch(v)) {
                      return 'Add at least one number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Strength meter
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _strength,
                    minHeight: 8,
                    color: _barColor(_strength),
                    backgroundColor: Colors.black12,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _strength < .34
                        ? 'Weak'
                        : _strength < .67
                            ? 'Medium'
                            : 'Strong',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: _barColor(_strength)),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Re-enter the new password';
                    }
                    if (v != _newCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.black12.withOpacity(.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_outline),
                        label: Text(_saving ? 'Saving…' : 'Update password'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
