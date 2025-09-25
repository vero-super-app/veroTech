// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';

// Deep links (v6+ API: the stream emits initial + subsequent links)
import 'package:app_links/app_links.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';

// Your pages/services
import 'package:vero360_app/Pages/BottomNavbar.dart';
import 'package:vero360_app/Pages/cartpage.dart';
import 'package:vero360_app/pages/profile_from_link_page.dart';
import 'package:vero360_app/screens/login_screen.dart';
import 'package:vero360_app/screens/register_screen.dart';
import 'package:vero360_app/services/auth_guard.dart';
import 'package:vero360_app/services/cart_services.dart';
import 'package:vero360_app/services/api_config.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (replace options with your own if needed)
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCWFa4tCHalRUqPkmfxVtrAbcXkC9negA8",
        authDomain: "superapp-c7cdb.firebaseapp.com",
        projectId: "superapp-c7cdb",
        storageBucket: "superapp-c7cdb.appspot.com",
        messagingSenderId: "802147518690",
        appId: "1:802147518690:android:a2d203d3708083dfc8f6bb",
        measurementId: "",
      ),
    );
  } catch (_) {
    // swallow init errors; app can still run without Firebase
  }

  // Initialize API base once (auto-picks local vs prod; persists)
  await ApiConfig.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks(); // singleton instance

    // v6+: The initial link (cold start) is emitted first on this stream,
    // followed by any subsequent links while the app is running.
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri != null) _routeFor(uri);
      },
      onError: (_) {
        // ignore/log as needed
      },
    );
  }

  void _routeFor(Uri uri) {
    // Handle: vero360://users/me  -> show a page that calls /users/me with saved JWT
    if (uri.scheme == 'vero360' && uri.host == 'users' && uri.path == '/me') {
      navKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ProfileFromLinkPage()),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      title: 'Vero360',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF8A00), // your orange brand
      ),
      // Use your existing named routes
      initialRoute: '/Bottomnavbar',
      routes: {
        '/Bottomnavbar': (context) => const Bottomnavbar(email: ''),
        '/signup': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/cartpage': (context) =>
            _authGuard(context, CartPage(cartService: CartService('https://vero-backend.onrender.com/cart'))),
      },
    );
  }
}

/// Ensures restricted pages require login (wrap target page in your AuthGuard)
Widget _authGuard(BuildContext context, Widget page) {
  return AuthGuard(child: page);
}
