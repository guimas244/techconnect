import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../providers/kills_permanentes_provider.dart';

/// Tela de visualizacao de kills permanentes
/// Usada para debug e para mostrar saldo de kills no modo explorador
class KillsPermanentesScreen extends ConsumerWidget {
  const KillsPermanentesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kills = ref.watch(killsPermanentesProvider);
    final totalKills = ref.watch(totalKillsPermanentesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kills Permanentes'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/explorador'),
        ),
        actions: [
          // Botao de debug para adicionar kills aleatorias
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Adicionar kills (debug)',
            onPressed: () => _mostrarDialogAdicionarKills(context, ref),
          ),
          // Botao para limpar kills
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Limpar todas kills',
            onPressed: () => _confirmarLimparKills(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Total: $totalKills kills',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kills permanentes nao expiram',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Lista de kills por tipo
          Expanded(
            child: kills == null
                ? const Center(child: CircularProgressIndicator())
                : _buildListaKills(kills.killsOrdenadas),
          ),
        ],
      ),
    );
  }

  Widget _buildListaKills(List<MapEntry<Tipo, int>> killsOrdenadas) {
    if (killsOrdenadas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma kill permanente ainda',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Jogue no modo Explorador para ganhar kills!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: killsOrdenadas.length,
      itemBuilder: (context, index) {
        final entry = killsOrdenadas[index];
        final tipo = entry.key;
        final quantidade = entry.value;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tipo.cor.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(tipo.icone, color: tipo.cor, size: 28),
            ),
            title: Text(
              tipo.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Monstro: ${tipo.monsterName}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tipo.cor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$quantidade',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogAdicionarKills(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Kills (Debug)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: Tipo.values.length,
            itemBuilder: (context, index) {
              final tipo = Tipo.values[index];
              return ListTile(
                leading: Icon(tipo.icone, color: tipo.cor),
                title: Text(tipo.displayName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        await ref
                            .read(killsPermanentesProvider.notifier)
                            .adicionarKill(tipo);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () async {
                        await ref
                            .read(killsPermanentesProvider.notifier)
                            .adicionarKills(tipo, 10);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _confirmarLimparKills(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Kills'),
        content: const Text(
          'Tem certeza que deseja remover todas as kills permanentes?\n\n'
          'Esta acao nao pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await ref.read(killsPermanentesProvider.notifier).limparKills();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kills removidas!')),
                );
              }
            },
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );
  }
}
