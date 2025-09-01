import 'package:flutter/material.dart';

class ComparePlaceholder extends StatelessWidget {
  const ComparePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karşılaştır (Placeholder)')),
      body: const Center(
        child: Text(
          'Karşılaştırma ekranı henüz implemente edilmedi.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}