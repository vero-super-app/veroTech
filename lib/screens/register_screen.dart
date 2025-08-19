import 'package:flutter/material.dart';

class AppColors {
  static const brandOrange = Color(0xFFFF8A00);
  static const title = Color(0xFF101010);
  static const body = Color(0xFF6B6B6B);
  static const fieldFill = Color(0xFFF7F7F9);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Privacy')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating your account...')),
    );

    // TODO: Hook to your real registration flow
    // Example payload:
    // {
    //   name: _name.text.trim(),
    //   email: _email.text.trim(),
    //   phone: _phone.text.trim(),
    //   password: _password.text,
    // }
  }

  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(s);
    return ok ? null : 'Enter a valid email';
  }

  // 10 digits starting with 08 or 09
  String? _validatePhone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^(08|09)\d{8}$').hasMatch(s)) {
      return 'Enter 10 digits starting with 08 or 09';
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
                      // Avatar w/ gradient ring (Hero tag matches login for smooth transition)
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

                      // Glass card
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
                              // Name
                              TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Full name',
                                  hint: 'John Banda',
                                  icon: Icons.person_outline,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
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
                                  hint: '08xxxxxxxx or 09xxxxxxxx',
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
                                onFieldSubmitted: (_) => _submit(),
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
                                        borderRadius: BorderRadius.circular(4)),
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

                              const SizedBox(height: 6),
                              // Create account
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
                                        'Create account',
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
                              // Or + social
                              Row(
                                children: [
                                  const Expanded(child: Divider(thickness: 1)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'or sign up with',
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
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.mail_outline),
                                      label: const Text('Google'),
                                      style: OutlinedButton.styleFrom(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 12),
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
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 12),
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
                            "Already have an account?",
                            style:
                                TextStyle(color: AppColors.body, fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context), // back to Login
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
