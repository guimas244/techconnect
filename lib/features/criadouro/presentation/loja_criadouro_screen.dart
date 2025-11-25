import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/criadouro_provider.dart';
import '../models/criadouro_models.dart';

class LojaCriadouroScreen extends ConsumerStatefulWidget {
  const LojaCriadouroScreen({super.key});

  @override
  ConsumerState<LojaCriadouroScreen> createState() =>
      _LojaCriadouroScreenState();
}

class _LojaCriadouroScreenState extends ConsumerState<LojaCriadouroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<CategoriaItem> _categorias = CategoriaItem.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categorias.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planis = ref.watch(planisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏪 ', style: TextStyle(fontSize: 24)),
            Text('Loja do Criadouro'),
          ],
        ),
        actions: [
          // Saldo de Planis
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💰', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$planis',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categorias
              .map((c) => Tab(text: c.nomeCompleto))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categorias.map((c) => _buildListaItens(c)).toList(),
      ),
    );
  }

  Widget _buildListaItens(CategoriaItem categoria) {
    final itens = ItensCriadouro.porCategoria(categoria);
    final planis = ref.watch(planisProvider);
    final inventario = ref.watch(inventarioProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
        final podeComprar = planis >= item.preco;
        final quantidade = inventario.quantidadeDeItem(item.id);

        return Card(
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(item.nome)),
                if (quantidade > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'x$quantidade',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.efeitoDescricao,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
                if (item.descricao != null)
                  Text(
                    item.descricao!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: podeComprar ? () => _comprarItem(item) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: podeComprar ? Colors.green : Colors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${item.preco}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _comprarItem(ItemCriadouro item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text('Comprar ${item.nome}?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Efeito: ${item.efeitoDescricao}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Preço: '),
                const Text('💰', style: TextStyle(fontSize: 16)),
                Text(
                  ' ${item.preco} Planis',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final sucesso =
                  ref.read(criadouroProvider.notifier).comprarItem(item.id);
              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Comprou ${item.nome}! ${item.emoji}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Planis insuficientes! 💰'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }
}
