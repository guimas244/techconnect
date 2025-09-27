import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JogadorScreen extends StatelessWidget {
  const JogadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogador'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/background/templo.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card de Coleção
                _buildMenuCard(
                  context: context,
                  title: 'Coleção',
                  subtitle: 'Visualize sua coleção de monstros',
                  icon: Icons.collections,
                  color: Colors.purple,
                  onTap: () => context.go('/jogador/colecao'),
                ),
                const SizedBox(height: 20),

                // Placeholder para futuras funcionalidades
                _buildMenuCard(
                  context: context,
                  title: 'Vantagens',
                  subtitle: 'Visualize estatísticas e conquistas',
                  icon: Icons.star,
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento...'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  enabled: false,
                ),
                const SizedBox(height: 20),

                _buildMenuCard(
                  context: context,
                  title: 'Configurações',
                  subtitle: 'Ajustes pessoais do jogador',
                  icon: Icons.settings,
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento...'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  enabled: false,
                ),
              ],
            ),
          ),
        ],
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
                        'Em desenvolvimento',
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
}