import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MonstrosScreen extends StatelessWidget {
  const MonstrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Monstros'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text('Conteúdo de Monstros', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
