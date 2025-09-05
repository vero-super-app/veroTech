// address.dart
import 'package:flutter/material.dart';

class ToReceivePage extends StatelessWidget {
  const ToReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To receive'),
      ),
      body: const Center(
        child: Text('This is you need to receive'),
      ),
    );
  }
}
