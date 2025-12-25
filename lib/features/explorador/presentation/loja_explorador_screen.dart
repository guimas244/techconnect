import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/providers/kills_permanentes_provider.dart';
import '../models/monstro_explorador.dart';
import '../providers/equipamento_provider.dart';
import '../providers/equipe_explorador_provider.dart';

/// Tela de loja do Modo Explorador - FASE 9
///
/// 3 abas:
/// - Equipamentos: Comprar equipamentos por tipo
/// - Consumiveis: Itens de uso rapido
/// - Inventario: Ver itens comprados
///
/// Atualizar loja requer selecionar tipo para pagar kills (min 5)
class LojaExploradorScreen extends ConsumerStatefulWidget {
  const LojaExploradorScreen({super.key});

  @override
  ConsumerState<LojaExploradorScreen> createState() =>
      _LojaExploradorScreenState();
}

class _LojaExploradorScreenState extends ConsumerState<LojaExploradorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Tipo? _tipoFiltro; // null = mostrar todos

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
    final kills = ref.watch(killsPermanentesProvider);
    final inventario = ref.watch(inventarioEquipamentosProvider);
    final equipe = ref.watch(equipeExploradorProvider);
    final totalKills = ref.watch(totalKillsPermanentesProvider);

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
          // Total de kills
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.teal, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$totalKills',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(icon: Icon(Icons.shield), text: 'Equipamentos'),
            const Tab(icon: Icon(Icons.science), text: 'Consumiveis'),
            Tab(
              icon: Stack(
                children: [
                  const Icon(Icons.inventory_2),
                  if (inventario.isNotEmpty)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${inventario.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Inventario',
            ),
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
                    'Equipamentos ate tier ${equipe?.tierAtual ?? 1}',
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
                  _buildEquipamentosTab(kills),

                  // Tab Consumiveis
                  _buildConsumiveisTab(),

                  // Tab Inventario
                  _buildInventarioTab(inventario),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipamentosTab(dynamic kills) {
    final itensLoja = ref.watch(lojaEquipamentosPersistidosProvider);
    final lojaNotifier = ref.read(lojaEquipamentosPersistidosProvider.notifier);

    // Filtra itens pelo tipo selecionado
    final itensFiltrados = _tipoFiltro == null
        ? itensLoja
        : itensLoja.where((e) => e.tipoRequerido == _tipoFiltro).toList();

    // Cor do filtro selecionado
    final corFiltro = _tipoFiltro?.cor ?? Colors.teal;

    return Column(
      children: [
        // Dropdown de filtro
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black38,
          child: Row(
            children: [
              const Text(
                'Filtro:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: corFiltro.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corFiltro),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Tipo?>(
                      value: _tipoFiltro,
                      isExpanded: true,
                      dropdownColor: Colors.grey.shade900,
                      icon: Icon(Icons.arrow_drop_down, color: corFiltro),
                      items: [
                        // Opcao "Todos"
                        DropdownMenuItem<Tipo?>(
                          value: null,
                          child: Row(
                            children: [
                              const Icon(Icons.all_inclusive, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Todos',
                                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${itensLoja.length}',
                                  style: const TextStyle(color: Colors.teal, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tipos que tem itens na loja
                        ...Tipo.values.map((tipo) {
                          final qtdDoTipo = lojaNotifier.contarPorTipo(tipo);
                          // So mostra tipos que tem itens
                          if (qtdDoTipo == 0) return null;
                          return DropdownMenuItem<Tipo?>(
                            value: tipo,
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/tipagens/icon_tipo_${tipo.name}.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (_, __, ___) => Icon(tipo.icone, color: tipo.cor, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tipo.displayName,
                                  style: TextStyle(color: tipo.cor, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$qtdDoTipo',
                                    style: const TextStyle(color: Colors.teal, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).whereType<DropdownMenuItem<Tipo?>>(),
                      ],
                      onChanged: (tipo) {
                        setState(() {
                          _tipoFiltro = tipo;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid de equipamentos
        Expanded(
          child: itensLoja.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : _buildEquipamentosGrid(kills, itensFiltrados),
        ),

        // Botao refresh
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar Loja (grátis)'),
            onPressed: () => _mostrarDialogRefresh(context, kills),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipamentosGrid(dynamic kills, List<EquipamentoExplorador> equipamentos) {
    if (equipamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              _tipoFiltro != null
                  ? 'Nenhum equipamento ${_tipoFiltro!.displayName}'
                  : 'Nenhum equipamento disponivel',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: equipamentos.length,
      itemBuilder: (context, index) {
        final equip = equipamentos[index];
        return _buildEquipamentoCard(equip, kills);
      },
    );
  }

  Widget _buildEquipamentoCard(EquipamentoExplorador equip, dynamic kills) {
    final corRaridade = Color(equip.raridade.corHex);
    final killsDisponiveis = kills?.getKills(equip.tipoRequerido) ?? 0;
    final podeComprar = killsDisponiveis >= equip.preco;

    return GestureDetector(
      onTap: () => _mostrarDetalhesEquipamento(equip, podeComprar, killsDisponiveis),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: podeComprar ? corRaridade : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com imagem, raridade, tipo e tier
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: corRaridade.withAlpha(40),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  // Imagem da armadura
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: corRaridade.withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: corRaridade),
                    ),
                    child: Image.asset(
                      equip.iconeArmadura,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        IconData(equip.slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
                        color: corRaridade,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Slot + Tier
                        Row(
                          children: [
                            Icon(_getIconeSlot(equip.slot), color: corRaridade, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              equip.slot.displayName,
                              style: TextStyle(color: corRaridade, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'T${equip.tier}',
                                style: const TextStyle(color: Colors.white70, fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Raridade
                        Text(
                          equip.raridade.nome,
                          style: TextStyle(color: corRaridade, fontSize: 10),
                        ),
                        // Tipo requerido
                        Row(
                          children: [
                            Image.asset(
                              'assets/tipagens/icon_tipo_${equip.tipoRequerido.name}.png',
                              width: 12,
                              height: 12,
                              errorBuilder: (_, __, ___) => Icon(
                                equip.tipoRequerido.icone,
                                color: equip.tipoRequerido.cor,
                                size: 10,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              equip.tipoRequerido.displayName,
                              style: TextStyle(color: equip.tipoRequerido.cor, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats - 1 por linha
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatLine('HP', equip.vida, Colors.green),
                    _buildStatLine('EN', equip.energia, Colors.cyan),
                    _buildStatLine('ATK', equip.ataque, Colors.orange),
                    _buildStatLine('DEF', equip.defesa, Colors.blue),
                    _buildStatLine('AGI', equip.agilidade, Colors.teal),
                    _buildStatLine('DUR', equip.durabilidadeMax, Colors.grey),
                  ],
                ),
              ),
            ),

            // Preco
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: podeComprar ? Colors.teal.withAlpha(30) : Colors.red.withAlpha(30),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stars,
                    color: podeComprar ? Colors.teal : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${equip.preco}',
                    style: TextStyle(
                      color: podeComprar ? Colors.teal : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($killsDisponiveis)',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
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

  Widget _buildStatLine(String label, int valor, Color cor) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(color: cor.withAlpha(180), fontSize: 9),
          ),
        ),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (valor / 50).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cor.withAlpha(150),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 24,
          child: Text(
            '+$valor',
            style: TextStyle(color: cor, fontSize: 9, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Retorna o icone para cada slot de equipamento
  IconData _getIconeSlot(SlotEquipamento slot) {
    switch (slot) {
      case SlotEquipamento.cabeca:
        return Icons.sports_motorsports; // Capacete
      case SlotEquipamento.peito:
        return Icons.shield;             // Escudo/peitoral
      case SlotEquipamento.bracos:
        return Icons.sign_language;      // Mao/luvas
    }
  }

  Widget _buildConsumiveisTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science, color: Colors.grey.shade600, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Consumiveis em breve!',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Pocoes, pergaminhos e mais...',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildInventarioTab(List<EquipamentoExplorador> inventario) {
    if (inventario.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, color: Colors.grey.shade600, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Inventario vazio',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Compre equipamentos na loja!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inventario.length,
      itemBuilder: (context, index) {
        final equip = inventario[index];
        final corRaridade = Color(equip.raridade.corHex);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: corRaridade.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: corRaridade.withAlpha(100)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: corRaridade.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  equip.iconeArmadura,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    IconData(equip.slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
                    color: corRaridade,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equip.nome,
                      style: TextStyle(
                        color: corRaridade,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${equip.raridade.nome} - T${equip.tier}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/tipagens/icon_tipo_${equip.tipoRequerido.name}.png',
                          width: 14,
                          height: 14,
                          errorBuilder: (_, __, ___) => Icon(equip.tipoRequerido.icone, color: equip.tipoRequerido.cor, size: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          equip.tipoRequerido.displayName,
                          style: TextStyle(color: equip.tipoRequerido.cor, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${equip.vida}HP',
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                  ),
                  Text(
                    '+${equip.ataque}ATK',
                    style: const TextStyle(color: Colors.orange, fontSize: 10),
                  ),
                  Text(
                    '+${equip.defesa}DEF',
                    style: const TextStyle(color: Colors.blue, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetalhesEquipamento(EquipamentoExplorador equip, bool podeComprar, int killsDisponiveis) {
    final corRaridade = Color(equip.raridade.corHex);

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corRaridade.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: corRaridade, width: 2),
                  ),
                  child: Image.asset(
                    equip.iconeArmadura,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      IconData(equip.slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
                      color: corRaridade,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equip.nome,
                        style: TextStyle(
                          color: corRaridade,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: corRaridade.withAlpha(50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              equip.raridade.nome,
                              style: TextStyle(color: corRaridade, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tier ${equip.tier}',
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tipo requerido
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: equip.tipoRequerido.cor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/tipagens/icon_tipo_${equip.tipoRequerido.name}.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => Icon(equip.tipoRequerido.icone, color: equip.tipoRequerido.cor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Apenas monstros ${equip.tipoRequerido.displayName}',
                    style: TextStyle(color: equip.tipoRequerido.cor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            const Text(
              'Bonus:',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (equip.vida > 0) _buildStatChip('HP', equip.vida, Colors.green),
                if (equip.energia > 0) _buildStatChip('EN', equip.energia, Colors.cyan),
                if (equip.ataque > 0) _buildStatChip('ATK', equip.ataque, Colors.orange),
                if (equip.defesa > 0) _buildStatChip('DEF', equip.defesa, Colors.blue),
                if (equip.agilidade > 0) _buildStatChip('AGI', equip.agilidade, Colors.teal),
              ],
            ),

            const SizedBox(height: 16),

            // Durabilidade
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Durabilidade',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Dura ${equip.durabilidadeMax} batalhas antes de quebrar',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${equip.durabilidadeMax}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars, color: equip.tipoRequerido.cor),
                            const SizedBox(width: 8),
                            Text(
                              '${equip.preco}',
                              style: TextStyle(
                                color: equip.tipoRequerido.cor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kills ${equip.tipoRequerido.displayName}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                        Text(
                          'Disponivel: $killsDisponiveis',
                          style: TextStyle(
                            color: podeComprar ? Colors.teal : Colors.red,
                            fontSize: 10,
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  onPressed: podeComprar ? () => _comprarEquipamento(equip) : null,
                  child: Text(podeComprar ? 'Comprar' : 'Sem kills'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withAlpha(100)),
      ),
      child: Text(
        '+$valor $label',
        style: TextStyle(color: cor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _comprarEquipamento(EquipamentoExplorador equip) async {
    Navigator.pop(context);

    // Gasta as kills
    final sucesso = await ref.read(killsPermanentesProvider.notifier)
        .gastarKills(equip.tipoRequerido, equip.preco);

    if (sucesso) {
      // Adiciona ao inventario
      await ref.read(inventarioEquipamentosProvider.notifier)
          .adicionarEquipamento(equip);

      // Remove da loja (persistido)
      await ref.read(lojaEquipamentosPersistidosProvider.notifier)
          .removerItem(equip.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  IconData(equip.slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${equip.nome} comprado!'),
                ),
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

  void _mostrarDialogRefresh(BuildContext context, dynamic kills) {
    const custoMinimo = 0;

    // Tipos com kills suficientes
    final tiposDisponiveis = <Tipo>[];
    if (kills != null) {
      for (final tipo in Tipo.values) {
        if (kills.temKillsSuficientes(tipo, custoMinimo)) {
          tiposDisponiveis.add(tipo);
        }
      }
    }

    if (tiposDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voce precisa de pelo menos 5 kills de algum tipo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Tipo? tipoSelecionado;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                'Escolha um tipo para atualizar a loja (grátis):',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: DropdownButtonFormField<Tipo>(
                  initialValue: tipoSelecionado,
                  dropdownColor: Colors.grey.shade800,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: InputBorder.none,
                  ),
                  hint: Text(
                    'Selecione um tipo',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                  items: tiposDisponiveis.map((tipo) {
                    final quantidade = kills?.getKills(tipo) ?? 0;
                    return DropdownMenuItem<Tipo>(
                      value: tipo,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/tipagens/icon_tipo_${tipo.name}.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => Icon(tipo.icone, color: tipo.cor, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tipo.displayName,
                            style: TextStyle(color: tipo.cor, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($quantidade)',
                            style: TextStyle(color: tipo.cor.withAlpha(180), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (tipo) {
                    setDialogState(() => tipoSelecionado = tipo);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: tipoSelecionado != null
                  ? () async {
                      Navigator.pop(context);
                      await _refreshLoja(tipoSelecionado!, custoMinimo);
                    }
                  : null,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshLoja(Tipo tipo, int custo) async {
    // Gasta as kills
    final sucesso = await ref.read(killsPermanentesProvider.notifier)
        .gastarKills(tipo, custo);

    if (sucesso) {
      // Atualiza a loja (gera novos itens com as regras)
      await ref.read(lojaEquipamentosPersistidosProvider.notifier)
          .atualizarLoja();

      // Reseta filtro para mostrar todos
      setState(() {
        _tipoFiltro = null;
      });

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
}
