import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monstro_aventura.dart';
import '../data/monstro_aventura_repository.dart';
import 'monstro_cadastro_screen.dart';
import '../../../../shared/models/tipo_enum.dart';

// Provider para o repository
final monstroAventuraRepositoryProvider = Provider<MonstroAventuraRepository>((ref) {
  return MonstroAventuraRepository();
});

// Provider para lista de monstros
final monstrosListProvider = FutureProvider<List<MonstroAventura>>((ref) async {
  final repository = ref.watch(monstroAventuraRepositoryProvider);
  return await repository.listarMonstros();
});

class MonstrosAventuraScreen extends ConsumerWidget {
  const MonstrosAventuraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monstrosAsync = ref.watch(monstrosListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monstros - Aventura'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(monstrosListProvider);
            },
            tooltip: 'Sincronizar',
          ),
        ],
      ),
      body: monstrosAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando monstros...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar monstros', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(monstrosListProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (monstros) => monstros.isEmpty
            ? _buildEmptyState(context)
            : _buildMonstrosList(context, ref, monstros),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarParaCadastro(context, ref),
        tooltip: 'Cadastrar Monstro',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 96,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum monstro cadastrado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para cadastrar seu primeiro monstro',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonstrosList(BuildContext context, WidgetRef ref, List<MonstroAventura> monstros) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: monstros.length,
      itemBuilder: (context, index) {
        final monstro = monstros[index];
        return _buildMonstroCard(context, ref, monstro);
      },
    );
  }

  Widget _buildMonstroCard(BuildContext context, WidgetRef ref, MonstroAventura monstro) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildMonstroImagem(monstro),
        title: Text(
          monstro.nome,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTipoChip(monstro.tipo1),
                const SizedBox(width: 8),
                _buildTipoChip(monstro.tipo2),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Criado em ${_formatarData(monstro.criadoEm)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, ref, monstro, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remover',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remover', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navegarParaEdicao(context, ref, monstro),
      ),
    );
  }

  Widget _buildMonstroImagem(MonstroAventura monstro) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: monstro.imagemUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const Icon(Icons.image, size: 32), // Por enquanto, ícone placeholder
            )
          : Icon(
              Icons.pets,
              size: 32,
              color: Colors.grey[600],
            ),
    );
  }

  Widget _buildTipoChip(Tipo tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tipo.cor.withOpacity(0.2),
        border: Border.all(color: tipo.cor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tipo.displayName,
        style: TextStyle(
          color: tipo.cor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, MonstroAventura monstro, String action) {
    switch (action) {
      case 'editar':
        _navegarParaEdicao(context, ref, monstro);
        break;
      case 'remover':
        _confirmarRemocao(context, ref, monstro);
        break;
    }
  }

  void _navegarParaCadastro(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonstroCadastroScreen(),
      ),
    ).then((_) {
      // Atualiza a lista quando volta da tela de cadastro
      ref.invalidate(monstrosListProvider);
    });
  }

  void _navegarParaEdicao(BuildContext context, WidgetRef ref, MonstroAventura monstro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonstroCadastroScreen(monstroParaEditar: monstro),
      ),
    ).then((_) {
      // Atualiza a lista quando volta da tela de edição
      ref.invalidate(monstrosListProvider);
    });
  }

  void _confirmarRemocao(BuildContext context, WidgetRef ref, MonstroAventura monstro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar remoção'),
        content: Text('Tem certeza que deseja remover o monstro "${monstro.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removerMonstro(context, ref, monstro);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _removerMonstro(BuildContext context, WidgetRef ref, MonstroAventura monstro) async {
    try {
      final repository = ref.read(monstroAventuraRepositoryProvider);
      await repository.removerMonstro(monstro.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monstro "${monstro.nome}" removido com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Atualiza a lista
      ref.invalidate(monstrosListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover monstro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
