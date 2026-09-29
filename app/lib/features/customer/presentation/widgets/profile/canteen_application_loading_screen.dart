import 'package:flutter/material.dart';

class CanteenApplicationLoadingScreen extends StatelessWidget {
  const CanteenApplicationLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buka Kantin'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
