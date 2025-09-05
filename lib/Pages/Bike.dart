// address.dart
import 'package:flutter/material.dart';

class BikePage extends StatelessWidget {
  const BikePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike'),
      ),
      body: const Center(
        child: Text('call bike'),
      ),
    );
  }
}
