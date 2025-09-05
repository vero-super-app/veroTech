// address.dart
import 'package:flutter/material.dart';

class TaxiPage extends StatelessWidget {
  const TaxiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport'),
      ),
      body: const Center(
        child: Text('find taxi or uber'),
      ),
    );
  }
}
