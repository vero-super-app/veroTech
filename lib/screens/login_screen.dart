import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/Pages/homepage.dart';
import 'package:vero360_app/services/auth_service.dart';
import 'package:vero360_app/toasthelper.dart';
import 'register_screen.dart';

class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const fieldFill = Color(0xFFF7F7F9);
}

enum LoginMode { password, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController(); // email or phone
  final _password = TextEditingController();
  final _otpCtrl  = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  LoginMode _mode = LoginMode.password;
  bool _otpSent = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      if (_mode == LoginMode.password) {
        // loginWithIdentifier returns Map<String, dynamic>? (token, user) or null
        final Map<String, dynamic>? result = await AuthService().loginWithIdentifier(
          _identifier.text.trim(),
          _password.text.trim(),
          context,
        );

        if (result != null && result.containsKey('token')) {
          await _persistAndGoHome(_identifier.text.trim());
        }
      } else {
        // OTP mode
        if (!_otpSent) {
          final ok = await AuthService().sendOtp(
            _identifier.text.trim(),
            context,
          );
          if (ok) setState(() => _otpSent = true);
        } else {
          final code = _otpCtrl.text.trim();
          if (code.isEmpty || code.length < 4) {
            ToastHelper.showCustomToast(context, 'Enter the OTP code', isSuccess: false);
            return;
          }
          // verifyOtp returns bool
          final ok = await AuthService().verifyOtp(
            _identifier.text.trim(),
            code,
            context,
          );
          if (ok) {
            await _persistAndGoHome(_identifier.text.trim());
          }
        }
      }
    } catch (e) {
      ToastHelper.showCustomToast(context, ' Error: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistAndGoHome(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', id); // keep same key used elsewhere
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Vero360Homepage(email: id),
      ),
    );
  }

  void _switchMode(LoginMode m) {
    setState(() {
      _mode = m;
      _otpSent = false;
      _otpCtrl.clear();
      _password.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0, -1),
                end: Alignment(0, 1),
                colors: [Color(0xFFEAF6FF), Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/logo_mark.jpg',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Welcome back',
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
                        'Sign in to continue to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.body,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Mode toggle
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading ? null : () => _switchMode(LoginMode.password),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _mode == LoginMode.password
                                    ? AppColors.brandOrange.withOpacity(0.1)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: _mode == LoginMode.password
                                      ? AppColors.brandOrange
                                      : Colors.black12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _mode == LoginMode.password ? AppColors.brandOrange : AppColors.title,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading ? null : () => _switchMode(LoginMode.otp),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _mode == LoginMode.otp
                                    ? AppColors.brandOrange.withOpacity(0.1)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: _mode == LoginMode.otp
                                      ? AppColors.brandOrange
                                      : Colors.black12,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'OTP',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _mode == LoginMode.otp ? AppColors.brandOrange : AppColors.title,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Form card
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
                          child: Column(
                            children: [
                              // Email or Phone (+265 allowed)
                              TextFormField(
                                controller: _identifier,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Email or Phone',
                                  hint: 'you@example.com or +2659XXXXXXXX',
                                  icon: Icons.person_outline,
                                ),
                                validator: (v) {
                                  final val = v?.trim() ?? '';
                                  if (val.isEmpty) return 'Email or phone is required';
                                  final isEmail = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(val);
                                  final digits = val.replaceAll(RegExp(r'\D'), '');
                                  final isLocal = RegExp(r'^(08|09)\d{8}$').hasMatch(digits);
                                  final isE164  = RegExp(r'^\+265[89]\d{8}$').hasMatch(val);
                                  if (!isEmail && !isLocal && !isE164) {
                                    return 'Use email or phone (08/09… or +265…)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              if (_mode == LoginMode.password) ...[
                                // Password
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _fieldDecoration(
                                    label: 'Password',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline,
                                    trailing: IconButton(
                                      tooltip: _obscure ? 'Show' : 'Hide',
                                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (_mode != LoginMode.password) return null;
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 6) return 'Must be at least 6 characters';
                                    return null;
                                  },
                                ),
                              ] else ...[
                                // OTP
                                if (_otpSent) ...[
                                  TextFormField(
                                    controller: _otpCtrl,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: _fieldDecoration(
                                      label: 'Enter OTP',
                                      hint: '123456',
                                      icon: Icons.sms_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _loading
                                          ? null
                                          : () async {
                                              final ok = await AuthService().sendOtp(
                                                _identifier.text.trim(),
                                                context,
                                              );
                                              if (ok) setState(() => _otpSent = true);
                                            },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Resend OTP'),
                                    ),
                                  ),
                                ] else ...[
                                  const Text(
                                    'We’ll send a one-time code to your email or phone.',
                                    style: TextStyle(color: AppColors.body),
                                  ),
                                ],
                              ],

                              const SizedBox(height: 20),

                              // Primary button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandOrange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _loading
                                        ? (_mode == LoginMode.password
                                            ? 'Signing in…'
                                            : (_otpSent ? 'Verifying…' : 'Sending OTP…'))
                                        : (_mode == LoginMode.password
                                            ? 'Sign in'
                                            : (_otpSent ? 'Verify OTP' : 'Send OTP')),
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
                            "Don't have an account?",
                            style: TextStyle(color: AppColors.body, fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                    );
                                  },
                            child: const Text(
                              'Create one',
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
