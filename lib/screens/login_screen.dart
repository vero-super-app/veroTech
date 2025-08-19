import 'package:flutter/material.dart';
import 'register_screen.dart';

class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const fieldFill = Color(0xFFF7F7F9);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signing in...')),
      );
      // TODO: hook up your real auth flow here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background with soft gradient + decorative blobs for visual interest
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0, -1),
                end: Alignment(0, 1),
                colors: [Color(0xFFEAF6FF), Colors.white],
              ),
            ),
          ),
          // Top-right blob
          Positioned(
            right: -40,
            top: -30,
            child: _Blob(size: 200, color: const Color(0x33FF8A00)),
          ),
          // Left blob
          Positioned(
            left: -60,
            top: 180,
            child: _Blob(size: 160, color: const Color(0x2264D2FF)),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar with gradient ring (Hero for a smooth transition)
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
                          child: Hero(
                            tag: 'brand-mark',
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo_mark.jpg', // uses your JPG
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.eco,
                                  size: 42,
                                  color: AppColors.brandOrange,
                                ),
                              ),
                            ),
                          ),
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

                      // Glassy card
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
                          child: Column(
                            children: [
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
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  final ok = RegExp(
                                    r"^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$",
                                  ).hasMatch(v.trim());
                                  return ok ? null : 'Enter a valid email';
                                },
                              ),
                              const SizedBox(height: 14),

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
                                    icon: Icon(
                                      _obscure ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: navigate to forgot password
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandOrange,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Sign in
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.brandOrange, Color(0xFFFFA53A)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Sign in',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // or divider
                              Row(
                                children: [
                                  const Expanded(child: Divider(thickness: 1)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'or continue with',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.55),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(child: Divider(thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Social auth buttons (placeholders)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.mail_outline),
                                      label: const Text('Google'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.apple),
                                      label: const Text('Apple'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                        onPressed: () {
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

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
