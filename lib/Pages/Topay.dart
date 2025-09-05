// address.dart
import 'package:flutter/material.dart';

class ToPayPage extends StatelessWidget {
  const ToPayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Pay'),
      ),
      body: const Center(
        child: Text('This is what you need to pay'),
      ),
    );
  }
}
