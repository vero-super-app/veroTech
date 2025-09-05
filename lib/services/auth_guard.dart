import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero360_app/screens/login_screen.dart';
import 'package:vero360_app/screens/register_screen.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoggedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null && token.isNotEmpty) {
      // 🔹 Optional: Validate token with backend
      // final response = await http.get(
      //   Uri.parse("http://your-backend.com/api/verify"),
      //   headers: {"Authorization": "Bearer $token"},
      // );
      // setState(() => _isLoggedIn = response.statusCode == 200);

      setState(() => _isLoggedIn = true); // trust local token
    } else {
      setState(() => _isLoggedIn = false);
    }

    setState(() => _loading = false);
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow user to cancel
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text(
          "You need to log in or sign up to continue. "
          "Only quick services can be accessed without logging in.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text("Login"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: const Text("Sign Up"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isLoggedIn) {
      Future.delayed(Duration.zero, () => _showAuthDialog(context));
    }

    return widget.child;
  }
}
