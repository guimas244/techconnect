import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/providers/kills_permanentes_provider.dart';
import '../models/item_loja.dart';
import '../providers/loja_explorador_provider.dart';
import '../providers/equipe_explorador_provider.dart';

/// Tela de loja do Modo Explorador
///
/// - Itens sao especificos por tipagem
/// - Preco em kills do mesmo tipo
/// - Botao de refresh (paga kills)
/// - Memoria de tier (nao vende acima do tier atual)
class LojaExploradorScreen extends ConsumerStatefulWidget {
  const LojaExploradorScreen({super.key});

  @override
  ConsumerState<LojaExploradorScreen> createState() =>
      _LojaExploradorScreenState();
}

class _LojaExploradorScreenState extends ConsumerState<LojaExploradorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Tipo? _tipoSelecionadoRefresh;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itensLoja = ref.watch(itensLojaProvider);
    final inventario = ref.watch(inventarioExploradorProvider);
    final kills = ref.watch(killsPermanentesProvider);
    final equipe = ref.watch(equipeExploradorProvider);
    final custoRefresh = ref.watch(custoRefreshLojaProvider);

    // Separa itens por categoria
    final equipamentos = itensLoja.where((i) => i.ehEquipamento).toList();
    final consumiveis = itensLoja.where((i) => i.ehConsumivel).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Loja do Explorador'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/explorador'),
        ),
        actions: [
          // Inventario
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.inventory_2, color: Colors.amber),
                onPressed: () => _mostrarInventario(context, inventario),
              ),
              if (inventario.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${inventario.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.shield), text: 'Equips'),
            Tab(icon: Icon(Icons.science), text: 'Itens'),
            Tab(icon: Icon(Icons.stars), text: 'Kills'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mapas_aventura/floresta_verde.jpg'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: Column(
          children: [
            // Info tier atual
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tier ${equipe?.tierAtual ?? 1}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Itens ate tier ${equipe?.tierAtual ?? 1}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Conteudo das tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Equipamentos
                  _buildItensGrid(equipamentos, kills),

                  // Tab Consumiveis
                  _buildItensGrid(consumiveis, kills),

                  // Tab Kills
                  _buildKillsTab(kills),
                ],
              ),
            ),

            // Botao refresh
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text('Atualizar Loja ($custoRefresh kills)'),
                      onPressed: () => _mostrarDialogRefresh(context, custoRefresh, kills),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItensGrid(List<ItemLoja> itens, dynamic kills) {
    if (itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Nenhum item disponivel',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Atualize a loja para ver novos itens',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
        return _buildItemCard(item, kills);
      },
    );
  }

  Widget _buildItemCard(ItemLoja item, dynamic kills) {
    final podeComprar = kills != null &&
        item.tipoElemental != null &&
        kills.temKillsSuficientes(item.tipoElemental!, item.preco);

    final cor = item.tipoElemental?.cor ?? Colors.grey;

    return GestureDetector(
      onTap: () => _mostrarDetalhesItem(context, item, podeComprar),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: podeComprar ? cor.withAlpha(200) : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com tipo e tier
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: cor.withAlpha(50),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(item.tipoElemental?.icone, color: cor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        item.tipoElemental?.displayName ?? '',
                        style: TextStyle(color: cor, fontSize: 10),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'T${item.tier}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Icone/Emoji do item
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.icone,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Bonus stats
            if (item.bonusStats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: item.bonusStats.entries.take(2).map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${e.value} ${_statName(e.key)}',
                        style: const TextStyle(color: Colors.teal, fontSize: 9),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 8),

            // Preco
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: podeComprar ? cor.withAlpha(30) : Colors.red.withAlpha(30),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stars,
                    color: podeComprar ? cor : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.preco}',
                    style: TextStyle(
                      color: podeComprar ? cor : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statName(String key) {
    switch (key) {
      case 'vida':
        return 'HP';
      case 'ataque':
        return 'ATK';
      case 'defesa':
        return 'DEF';
      case 'agilidade':
        return 'AGI';
      case 'energia':
        return 'EN';
      case 'cura':
        return 'HP';
      case 'ataque_pct':
        return '%ATK';
      case 'defesa_pct':
        return '%DEF';
      default:
        return key;
    }
  }

  Widget _buildKillsTab(dynamic kills) {
    if (kills == null) {
      return const Center(
        child: Text(
          'Carregando kills...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final killsOrdenadas = kills.killsOrdenadas as List;

    if (killsOrdenadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma kill ainda',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Derrote monstros para ganhar kills!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: killsOrdenadas.length,
      itemBuilder: (context, index) {
        final entry = killsOrdenadas[index];
        final tipo = entry.key as Tipo;
        final quantidade = entry.value as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tipo.cor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tipo.cor.withAlpha(100)),
          ),
          child: Row(
            children: [
              Icon(tipo.icone, color: tipo.cor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tipo.displayName,
                  style: TextStyle(
                    color: tipo.cor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.teal, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$quantidade',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetalhesItem(BuildContext context, ItemLoja item, bool podeComprar) {
    final cor = item.tipoElemental?.cor ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(item.icone, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        item.tipoItem.displayName,
                        style: TextStyle(color: cor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cor.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(item.tipoElemental?.icone, color: cor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Tier ${item.tier}',
                        style: TextStyle(color: cor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Descricao
            Text(
              item.descricao,
              style: TextStyle(color: Colors.grey.shade400),
            ),

            const SizedBox(height: 16),

            // Bonus stats
            if (item.bonusStats.isNotEmpty) ...[
              const Text(
                'Bonus:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.bonusStats.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${e.value} ${_statName(e.key)}',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Preco e botao comprar
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, color: cor),
                        const SizedBox(width: 8),
                        Text(
                          '${item.preco} kills ${item.tipoElemental?.displayName ?? ""}',
                          style: TextStyle(
                            color: cor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: podeComprar ? Colors.teal : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: podeComprar
                      ? () {
                          Navigator.pop(context);
                          _comprarItem(item);
                        }
                      : null,
                  child: Text(podeComprar ? 'Comprar' : 'Kills insuf.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _comprarItem(ItemLoja item) async {
    if (item.tipoElemental == null) return;

    final killsNotifier = ref.read(killsPermanentesProvider.notifier);
    final sucesso = await killsNotifier.gastarKills(item.tipoElemental!, item.preco);

    if (sucesso) {
      // Adiciona ao inventario
      ref.read(inventarioExploradorProvider.notifier).adicionarItem(item);

      // Remove da loja
      ref.read(itensLojaProvider.notifier).removerItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(item.icone),
                const SizedBox(width: 8),
                Text('${item.nome} comprado!'),
              ],
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kills insuficientes!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogRefresh(BuildContext context, int custo, dynamic kills) {
    // Tipos com kills suficientes para o custo
    final tiposDisponiveis = <Tipo>[];
    if (kills != null) {
      for (final tipo in Tipo.values) {
        if (kills.temKillsSuficientes(tipo, custo)) {
          tiposDisponiveis.add(tipo);
        }
      }
    }

    if (tiposDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voce precisa de pelo menos $custo kills de algum tipo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.teal),
            SizedBox(width: 8),
            Text('Atualizar Loja', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha o tipo de kills para pagar ($custo):',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tiposDisponiveis.take(8).map((tipo) {
                final selecionado = _tipoSelecionadoRefresh == tipo;
                return GestureDetector(
                  onTap: () {
                    setState(() => _tipoSelecionadoRefresh = tipo);
                    Navigator.pop(context);
                    _mostrarDialogRefresh(context, custo, kills);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selecionado ? tipo.cor.withAlpha(100) : tipo.cor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selecionado ? tipo.cor : tipo.cor.withAlpha(100),
                        width: selecionado ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tipo.icone, color: tipo.cor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          tipo.displayName,
                          style: TextStyle(color: tipo.cor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tipoSelecionadoRefresh = null;
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: _tipoSelecionadoRefresh != null
                ? () async {
                    Navigator.pop(context);
                    await _refreshLoja(custo);
                  }
                : null,
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshLoja(int custo) async {
    if (_tipoSelecionadoRefresh == null) return;

    final sucesso = await ref
        .read(itensLojaProvider.notifier)
        .refreshLoja(_tipoSelecionadoRefresh!, custo);

    if (sucesso) {
      // Aumenta custo do proximo refresh
      ref.read(custoRefreshLojaProvider.notifier).state = custo + 2;
      _tipoSelecionadoRefresh = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loja atualizada!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  void _mostrarInventario(BuildContext context, List<ItemLoja> inventario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text(
                    'Inventario',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${inventario.length} itens',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.grey),

            // Lista
            Expanded(
              child: inventario.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, color: Colors.grey.shade600, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Inventario vazio',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: inventario.length,
                      itemBuilder: (context, index) {
                        final item = inventario[index];
                        final cor = item.tipoElemental?.cor ?? Colors.grey;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cor.withAlpha(100)),
                          ),
                          child: Row(
                            children: [
                              Text(item.icone, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nome,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      item.tipoItem.displayName,
                                      style: TextStyle(color: cor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'T${item.tier}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
