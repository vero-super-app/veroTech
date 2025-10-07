// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/Pages/MerchantApplicationForm.dart';
import 'package:vero360_app/Pages/merchantbottomnavbar.dart';
import 'package:vero360_app/services/auth_service.dart';
import 'package:vero360_app/toasthelper.dart';
import 'package:vero360_app/screens/login_screen.dart'; // <- for redirect after submit

class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const fieldFill = Color(0xFFF7F7F9);
}

enum VerifyMethod { email, phone }
enum UserRole { customer, merchant }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _phone    = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();
  final _code     = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;

  VerifyMethod _method = VerifyMethod.email;
  UserRole _role = UserRole.customer;

  bool _sending = false;
  bool _otpSent = false;
  bool _verifying = false;
  bool _registering = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _code.dispose();
    super.dispose();
  }

  String? _validateName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Name is required' : null;

  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(s);
    return ok ? null : 'Enter a valid email';
  }

  String? _validatePhone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Mobile number is required';
    final digits = s.replaceAll(RegExp(r'\D'), '');
    final isLocal = RegExp(r'^(08|09)\d{8}$').hasMatch(digits);
    final isE164  = RegExp(r'^\+265[89]\d{8}$').hasMatch(s);
    if (!isLocal && !isE164) return 'Use 08/09xxxxxxxx or +2659xxxxxxxx';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? trailing,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: trailing,
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandOrange, width: 1.2),
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _sending = true;
      _otpSent = false;
    });

    try {
      final method = _method == VerifyMethod.email ? 'email' : 'phone';
      final ok = await AuthService().requestOtp(
        channel: method,
        email: method == 'email' ? _email.text.trim() : null,
        phone: method == 'phone' ? _phone.text.trim() : null,
        context: context,
      );
      if (ok) setState(() => _otpSent = true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    if (!_agree) {
      ToastHelper.showCustomToast(
        context,
        'Please agree to the Terms & Privacy',
        isSuccess: false,
        errorMessage: '',
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_otpSent) {
      ToastHelper.showCustomToast(
        context,
        'Please request a code first',
        isSuccess: false,
        errorMessage: '',
      );
      return;
    }
    if (_code.text.trim().isEmpty) {
      ToastHelper.showCustomToast(
        context,
        'Enter the verification code',
        isSuccess: false,
        errorMessage: '',
      );
      return;
    }

    final preferred = _method == VerifyMethod.email ? 'email' : 'phone';
    final identifier =
        preferred == 'email' ? _email.text.trim() : _phone.text.trim();

    setState(() => _verifying = true);
    String? ticket;
    try {
      ticket = await AuthService().verifyOtpGetTicket(
        identifier: identifier,
        code: _code.text.trim(),
        context: context,
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
    if (ticket == null) return;

    setState(() => _registering = true);
    try {
      final resp = await AuthService().registerUser(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        role: _role == UserRole.merchant ? 'merchant' : 'customer',
        profilePicture: '',
        preferredVerification: preferred,
        verificationTicket: ticket,
        context: context,
      );

      if (!mounted) return;
      await _handleAuthResponse(resp);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  /// Merchant flow:
  /// - Save token if present.
  /// - Mark review pending.
  /// - Go to MerchantApplicationForm (no back).
  /// - On form finished: logout → back to Login.
  Future<void> _handleAuthResponse(Map<String, dynamic>? resp) async {
    if (resp == null || !mounted) return;

    if (_role == UserRole.merchant) {
      final token = (resp['access_token'] ??
              resp['token'] ??
              resp['jwt'] ??
              resp['jwt_token'])
          ?.toString();

      final prefs = await SharedPreferences.getInstance();

      if (token != null && token.isNotEmpty) {
        await prefs.setString('token', token);
        await prefs.setString('jwt_token', token);
      } else {
        _showSnack('Account created. Continue with your merchant application.');
      }

      // mark that application is now under review (used by login/profile)
      await prefs.setBool('merchant_review_pending', true);

      _goToMerchantApplication(); // cannot back
      return;
    }

    // Non-merchant: back to login (or your customer home)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _goToMerchantHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MerchantBottomnavbar(
          email: _email.text.trim(),
        ),
      ),
      (_) => false,
    );
  }

  void _goToMerchantApplication() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => WillPopScope(
          onWillPop: () async => false, // block back
          child: MerchantApplicationForm(
            onFinished: () async {
              // set flags
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('merchant_application_submitted', true);
              await prefs.setBool('merchant_review_pending', true);

              // logout & go to login screen
              await _logoutToLogin();
            },
          ),
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _logoutToLogin() async {
    // Clear tokens; keep email so the login field can prefill if desired
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('jwt_token');

    if (!mounted) return;
    ToastHelper.showCustomToast(context, 'Application submitted. Please log in later to check status.', isSuccess: true, errorMessage: '');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final canSend = (_formKey.currentState?.validate() ?? false) &&
        (_method == VerifyMethod.email
            ? _email.text.trim().isNotEmpty
            : _phone.text.trim().isNotEmpty);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0, -1),
                end: Alignment(0, 1),
                colors: [Color(0xFFFFF4E9), Colors.white],
              ),
            ),
          ),
          const Positioned(right: -50, top: -30, child: _Blob(size: 220, color: Color(0x33FF8A00))),
          const Positioned(left: -70, top: 200, child: _Blob(size: 180, color: Color(0x2264D2FF))),
          const Positioned(right: -40, bottom: -40, child: _Blob(size: 160, color: Color(0x2245C4B0))),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.brandOrange, Color(0xFFFFB85C)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandOrange.withOpacity(0.25),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo_mark.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.eco, size: 42, color: AppColors.brandOrange),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Create your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.title,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'It’s quick and easy to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.body,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          onChanged: () => setState(() {}),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Account type',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('Customer'),
                                    selected: _role == UserRole.customer,
                                    onSelected: (_) => setState(() => _role = UserRole.customer),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Merchant'),
                                    selected: _role == UserRole.merchant,
                                    onSelected: (_) => setState(() => _role = UserRole.merchant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Your name',
                                  hint: 'vero',
                                  icon: Icons.person_outline,
                                ),
                                validator: _validateName,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Email',
                                  hint: 'you@vero.com',
                                  icon: Icons.alternate_email,
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Mobile number',
                                  hint: '08xxxxxxxx, 09xxxxxxxx or +2659xxxxxxxx',
                                  icon: Icons.phone_iphone,
                                ),
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure1,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  trailing: IconButton(
                                    tooltip: _obscure1 ? 'Show' : 'Hide',
                                    icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirm,
                                obscureText: _obscure2,
                                textInputAction: TextInputAction.done,
                                decoration: _fieldDecoration(
                                  label: 'Confirm password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  trailing: IconButton(
                                    tooltip: _obscure2 ? 'Show' : 'Hide',
                                    icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                                  ),
                                ),
                                validator: _validateConfirm,
                              ),

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agree,
                                    onChanged: (v) => setState(() => _agree = v ?? false),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'I agree to the Terms & Privacy Policy',
                                      style: TextStyle(color: AppColors.body, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Verify via',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('Email'),
                                    selected: _method == VerifyMethod.email,
                                    onSelected: (_) => setState(() {
                                      _method = VerifyMethod.email;
                                      _code.clear();
                                      _otpSent = false;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Phone'),
                                    selected: _method == VerifyMethod.phone,
                                    onSelected: (_) => setState(() {
                                      _method = VerifyMethod.phone;
                                      _code.clear();
                                      _otpSent = false;
                                    }),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: (_sending || _verifying || _registering || !canSend)
                                          ? null
                                          : _sendCode,
                                      icon: const Icon(Icons.sms_outlined),
                                      label: Text(_sending ? 'Sending…' : 'Send code'),
                                    ),
                                  ),
                                ],
                              ),

                              if (_otpSent) ...[
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _code,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration(
                                    label: 'Verification code',
                                    hint: 'Enter the code',
                                    icon: Icons.verified_outlined,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (_registering || _verifying) ? null : _verifyAndRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandOrange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _registering
                                        ? 'Creating account…'
                                        : _verifying
                                            ? 'Verifying…'
                                            : 'Verify & Create account',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: AppColors.body,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    );
  }
}
