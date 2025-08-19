import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart'; 

void main() => runApp(const EcoThriveApp());

class EcoThriveApp extends StatelessWidget {
  const EcoThriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoThrive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: AppColors.brandOrange,
          secondary: AppColors.brandOrange,
        ),
      ),
      home: const SplashScreen(), // navigates to OnboardingScreen
    );
  }
}
