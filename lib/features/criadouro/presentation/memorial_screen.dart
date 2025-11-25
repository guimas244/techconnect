import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/criadouro_provider.dart';
import '../models/mascote_morto.dart';

class MemorialScreen extends ConsumerWidget {
  const MemorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memorial = ref.watch(memorialProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📜 ', style: TextStyle(fontSize: 24)),
            Text('Memorial'),
          ],
        ),
      ),
      body: memorial.isEmpty
          ? _buildVazio()
          : _buildLista(memorial),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            const Text(
              'Memorial Vazio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhum mascote descansou ainda.\nCuide bem do seu mascote!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(List<MascoteMorto> memorial) {
    // Ordena do mais recente para o mais antigo
    final ordenado = [...memorial]
      ..sort((a, b) => b.dataMorte.compareTo(a.dataMorte));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordenado.length,
      itemBuilder: (context, index) {
        final mascote = ordenado[index];
        return _MascoteMortoCard(mascote: mascote);
      },
    );
  }
}

class _MascoteMortoCard extends StatelessWidget {
  final MascoteMorto mascote;

  const _MascoteMortoCard({required this.mascote});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                Image.asset(
                  mascote.monstroId,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('🪦', style: TextStyle(fontSize: 30)),
                    );
                  },
                ),
                // Overlay de descanso
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Text('🪦', style: TextStyle(fontSize: 24)),
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          mascote.nome,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('📅 ', style: TextStyle(fontSize: 14)),
                Text(
                  'Viveu ${mascote.diasVivido} dias',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${mascote.causaMorte.emoji} ',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  mascote.causaMorte.descricao,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data da morte
                Row(
                  children: [
                    const Text('🗓️ ', style: TextStyle(fontSize: 16)),
                    Text(
                      'Faleceu em ${mascote.dataFormatada}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Estatísticas finais
                const Text(
                  'Estatísticas Finais',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildEstatistica('🍖', 'Fome', mascote.estatisticasFinais['fome'] ?? 0),
                _buildEstatistica('💧', 'Sede', mascote.estatisticasFinais['sede'] ?? 0),
                _buildEstatistica('🧼', 'Higiene', mascote.estatisticasFinais['higiene'] ?? 0),
                _buildEstatistica('😄', 'Alegria', mascote.estatisticasFinais['alegria'] ?? 0),
                _buildEstatistica('❤️', 'Saúde', mascote.estatisticasFinais['saude'] ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatistica(String emoji, String label, double valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: valor / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  valor <= 0 ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text(
              '${valor.toInt()}%',
              style: TextStyle(
                fontSize: 11,
                color: valor <= 0 ? Colors.red : Colors.grey[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
