import 'package:flutter/material.dart';
import 'aventura/presentation/monstros_aventura_screen.dart';

class MonstrosMenuScreen extends StatelessWidget {
  const MonstrosMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monstros'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.pets,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Escolha o modo',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Botão Aventura
            _buildMenuCard(
              context: context,
              title: 'Aventura',
              subtitle: 'Gerencie seus monstros de aventura',
              icon: Icons.explore,
              color: Colors.green,
              onTap: () => _navegarParaAventura(context),
            ),
            
            const SizedBox(height: 20),
            
            // Botão Dex
            _buildMenuCard(
              context: context,
              title: 'Dex',
              subtitle: 'Catálogo completo de monstros',
              icon: Icons.library_books,
              color: Colors.blue,
              onTap: () => _navegarParaDex(context),
              enabled: false, // Por enquanto desabilitado
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: enabled ? 4 : 1,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: enabled ? null : Colors.grey[100],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: enabled ? color.withOpacity(0.1) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: enabled ? color : Colors.grey[500],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: enabled ? color : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? Colors.grey[700] : Colors.grey[400],
                      ),
                    ),
                    if (!enabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Em breve',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: enabled ? Colors.grey[400] : Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navegarParaAventura(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonstrosAventuraScreen(),
      ),
    );
  }

  void _navegarParaDex(BuildContext context) {
    // Por enquanto, mostra um snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dex em desenvolvimento...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
