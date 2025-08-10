import 'package:flutter/material.dart';

class MonstrosDebugScreen extends StatelessWidget {
  const MonstrosDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monstros - Debug'),
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: Container(
        color: Colors.red.shade50,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bug_report,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'Tela de Debug Funcionando!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Se você está vendo esta tela,\na navegação está funcionando.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
