import 'package:flutter/material.dart';
import 'aventura/presentation/monstros_aventura_screen.dart';

class MonstrosMenuScreenSimple extends StatelessWidget {
  const MonstrosMenuScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monstros'),
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Card Aventura
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonstrosAventuraScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  child: const Column(
                    children: [
                      Icon(
                        Icons.explore,
                        size: 50,
                        color: Colors.green,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aventura',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Gerencie seus monstros de aventura'),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Card Dex
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dex em desenvolvimento'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  child: const Column(
                    children: [
                      Icon(
                        Icons.book,
                        size: 50,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Dex',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Enciclopédia de monstros'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
