import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegrasScreen extends StatelessWidget {
  const RegrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Regras'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text('Conteúdo de Regras', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
