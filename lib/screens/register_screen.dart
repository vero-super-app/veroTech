import 'package:flutter/material.dart';
import 'package:vero360_app/services/auth_service.dart';
import 'package:vero360_app/toasthelper.dart';

class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const fieldFill = Color(0xFFF7F7F9);
}

enum VerifyMethod { email, phone }

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
  bool _otpSent = false;
  bool _verifying = false;
  bool _sending = false;
  bool _registering = false;
  bool _verified = false;

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

  // --------- FLOW ACTIONS ---------
  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final identifier = _method == VerifyMethod.email
        ? _email.text.trim()
        : _phone.text.trim();

    setState(() {
      _sending = true;
      _otpSent = false;
      _verified = false;
    });

    try {
      final ok = await AuthService().sendOtp(identifier, context);
      if (ok) {
        _otpSent = true;
      }
    } catch (e) {
      ToastHelper.showCustomToast(context, ' code not sent: $e', isSuccess: false, errorMessage: '');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    if (!_agree) {
      ToastHelper.showCustomToast(
        context,
        'Please agree to the Terms & Privacy',
        isSuccess: false, errorMessage: '',
      );
      return;
    }

    // Full form validation (name/email/phone/password/confirm)
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final identifier = _method == VerifyMethod.email
        ? _email.text.trim()
        : _phone.text.trim();

    if (!_otpSent) {
      ToastHelper.showCustomToast(context, 'Please request a code first', isSuccess: false, errorMessage: '');
      return;
    }
    if (_code.text.trim().isEmpty) {
      ToastHelper.showCustomToast(context, 'Enter the verification code', isSuccess: false, errorMessage: '');
      return;
    }

    // Step 1: verify code
    setState(() => _verifying = true);
    try {
      final ok = await AuthService().verifyOtp(identifier, _code.text.trim(), context);
      if (!ok) {
        setState(() => _verified = false);
        return;
      }
      setState(() => _verified = true);
    } catch (e) {
      ToastHelper.showCustomToast(context, ' Verification error: $e', isSuccess: false, errorMessage: '');
      setState(() => _verified = false);
      return;
    } finally {
      if (mounted) setState(() => _verifying = false);
    }

    // Step 2: register
    setState(() => _registering = true);
    try {
      final ok = await AuthService().registerUser(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(), // normalized inside service to +265
        password: _password.text,
        context: context,
      );
      if (ok && mounted) {
        // You can also navigate to LoginScreen, if you prefer:
        // Navigator.pop(context);
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      ToastHelper.showCustomToast(context, ' Registration error: $e', isSuccess: false, errorMessage: '');
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  // --------- VALIDATORS ---------
  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(s);
    return ok ? null : 'Enter a valid email';
  }

  // Accept 10-digit local (08/09xxxxxxxx) OR E.164 +2658/9xxxxxxxx
  String? _validatePhone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Mobile number is required';
    final digits = s.replaceAll(RegExp(r'\D'), '');
    final isLocal = RegExp(r'^(08|09)\d{8}$').hasMatch(digits);
    final isE164  = RegExp(r'^\+265[89]\d{8}$').hasMatch(s);
    if (!isLocal && !isE164) {
      return 'Use 08/09xxxxxxxx or +2659xxxxxxxx';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Must be at least 6 characters';
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
    TextInputType? keyboard,
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

  @override
  Widget build(BuildContext context) {
    final canSend = (_formKey.currentState?.validate() ?? false)
        && (_method == VerifyMethod.email ? _email.text.trim().isNotEmpty : _phone.text.trim().isNotEmpty);

    return Scaffold(
      body: Stack(
        children: [
          // background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0, -1),
                end: Alignment(0, 1),
                colors: [Color(0xFFFFF4E9), Colors.white],
              ),
            ),
          ),
          // decorative blobs
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
                      // Avatar / brand mark
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
                              'assets/logo_mark.jpg',
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

                      // Card
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
                          border: Border.all(color: const Color(0x11FFFFFF)),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Form(
                          key: _formKey,
                          onChanged: () => setState(() {}),
                          child: Column(
                            children: [
                              // Name
                              TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Full name',
                                  hint: 'John Banda',
                                  icon: Icons.person_outline,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              // Email
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Email',
                                  hint: 'you@example.com',
                                  icon: Icons.alternate_email,
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 14),

                              // Phone
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

                              // Password
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

                              // Confirm
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: const BorderSide(color: Color(0xFFBDBDBD)),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'I agree to the Terms & Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.body,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Verify method selector
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Verify via',
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
                                    label: const Text('Email'),
                                    selected: _method == VerifyMethod.email,
                                    onSelected: (_) => setState(() {
                                      _method = VerifyMethod.email;
                                      _otpSent = false;
                                      _verified = false;
                                      _code.clear();
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Phone'),
                                    selected: _method == VerifyMethod.phone,
                                    onSelected: (_) => setState(() {
                                      _method = VerifyMethod.phone;
                                      _otpSent = false;
                                      _verified = false;
                                      _code.clear();
                                    }),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Send code + input code (only after sent)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: (_sending || _verifying || _registering || !canSend)
                                          ? null
                                          : _sendCode,
                                      icon: const Icon(Icons.sms_outlined),
                                      label: Text(_sending ? 'Sending…' : 'Send code'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
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

                              // Create account (Verify & Register)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (_registering || _verifying) ? null : _verifyAndRegister,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
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
                      Wrap(
                        spacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(color: AppColors.body, fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontWeight: FontWeight.w800,
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
