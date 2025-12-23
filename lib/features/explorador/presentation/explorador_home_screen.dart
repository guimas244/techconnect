import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../aventura/providers/kills_permanentes_provider.dart';

/// Tela principal do Modo Explorador
///
/// Este é o novo modo de jogo com:
/// - Batalhas manuais estratégicas
/// - Equipe de 2 monstros ativos + 3 no banco
/// - Sistema de XP e level up
/// - 3 slots de equipamento (cabeça, peito, braços)
/// - Kills como moeda de troca
/// - Lojas por tipagem
class ExploradorHomeScreen extends ConsumerStatefulWidget {
  const ExploradorHomeScreen({super.key});

  @override
  ConsumerState<ExploradorHomeScreen> createState() =>
      _ExploradorHomeScreenState();
}

class _ExploradorHomeScreenState extends ConsumerState<ExploradorHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final totalKills = ref.watch(totalKillsPermanentesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Modo Explorador'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/modo-selecao'),
        ),
        actions: [
          // Mostrar total de kills no app bar
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, size: 18, color: Colors.teal),
                const SizedBox(width: 4),
                Text(
                  '$totalKills',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mapas_aventura/floresta_verde.jpg'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header com icone
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.explore,
                          size: 40,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MODO EXPLORADOR',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Batalhas estrategicas manuais',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info em desenvolvimento
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.construction, color: Colors.orange.shade300),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Em desenvolvimento - funcionalidades sendo implementadas',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Grid de botoes
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildActionButton(
                      icon: Icons.group,
                      label: 'Equipe',
                      subtitle: '2 ativos + 3 banco',
                      onTap: () => context.go('/explorador/equipe'),
                    ),
                    _buildActionButton(
                      icon: Icons.map,
                      label: 'Mapa',
                      subtitle: 'Selecionar batalha',
                      onTap: () => context.go('/explorador/mapa'),
                    ),
                    _buildActionButton(
                      icon: Icons.store,
                      label: 'Loja',
                      subtitle: 'Comprar com kills',
                      onTap: () => context.go('/explorador/loja'),
                    ),
                    _buildActionButton(
                      icon: Icons.stars,
                      label: 'Kills',
                      subtitle: '$totalKills disponíveis',
                      onTap: () => context.go('/kills-permanentes'),
                    ),
                  ],
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withAlpha(80)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
