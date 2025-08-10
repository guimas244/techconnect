import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Monstros',
      home: TestMonstrosScreen(),
    );
  }
}

class TestMonstrosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Monstros'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: Colors.green),
            SizedBox(height: 32),
            Text('TESTE AVENTURA', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Teste de navegação
              },
              child: Text('Aventura'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: null, // Desabilitado
              child: Text('Dex (Em breve)'),
            ),
          ],
        ),
      ),
    );
  }
}
