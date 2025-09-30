import 'package:flutter/material.dart';

import '../models/habilidade.dart';
import '../models/item.dart';
import '../models/item_consumivel.dart';
import '../models/magia_drop.dart';
import '../models/mochila.dart';
import '../models/monstro_aventura.dart';

class RecompensasBatalha {
  final List<MonstroAventura> monstrosEvoluidos;
  final Map<MonstroAventura, Map<String, int>> ganhosAtributos;
  final Map<MonstroAventura, String?> habilidadesEvoluidas;

  final Item? itemRecebido;
  final int? tierItem;
  final RaridadeItem? raridadeItem;

  final MagiaDrop? magiaRecebida;

  final List<ItemConsumivel> itensConsumiveisRecebidos;

  const RecompensasBatalha({
    this.monstrosEvoluidos = const [],
    this.ganhosAtributos = const {},
    this.habilidadesEvoluidas = const {},
    this.itemRecebido,
    this.tierItem,
    this.raridadeItem,
    this.magiaRecebida,
    this.itensConsumiveisRecebidos = const [],
  });

  bool get temEvolucao => monstrosEvoluidos.isNotEmpty;
  bool get temEquipamento => itemRecebido != null;
  bool get temMagia => magiaRecebida != null;
  bool get temEquipamentoOuMagia => temEquipamento || temMagia;
  bool get temItensConsumiveis => itensConsumiveisRecebidos.isNotEmpty;
}

class ModalRecompensasBatalha extends StatefulWidget {
  final RecompensasBatalha recompensas;
  final List<MonstroAventura> timeJogador;
  final Mochila mochilaAtual;
  final Future<void> Function(MonstroAventura, Item) onEquiparItem;
  final Future<void> Function(Item) onDescartarItem;
  final Future<void> Function(MonstroAventura, MagiaDrop, Habilidade) onEquiparMagia;
  final Future<void> Function(MagiaDrop) onDescartarMagia;
  final Future<void> Function(
    List<ItemConsumivel> itensParaGuardar,
    Set<int> slotsParaLiberar,
  ) onGuardarItensNaMochila;
  final Future<void> Function() onConcluir;

  const ModalRecompensasBatalha({
    super.key,
    required this.recompensas,
    required this.timeJogador,
    required this.mochilaAtual,
    required this.onEquiparItem,
    required this.onDescartarItem,
    required this.onEquiparMagia,
    required this.onDescartarMagia,
    required this.onGuardarItensNaMochila,
    required this.onConcluir,
  });

  @override
  State<ModalRecompensasBatalha> createState() => _ModalRecompensasBatalhaState();
}
class _ModalRecompensasBatalhaState extends State<ModalRecompensasBatalha> {
  bool _evolucaoExpandida = false;
  bool _equipamentoExpandido = false;
  bool _itensExpandido = false;

  bool _itemResolvido = false;
  bool _magiaResolvida = false;

  MonstroAventura? _monstroSelecionadoItem;
  bool _processandoItem = false;

  MonstroAventura? _monstroSelecionadoMagia;
  Habilidade? _habilidadeSelecionada;
  bool _processandoMagia = false;

  late List<ItemConsumivel> _itensParaGuardar;
  final Set<int> _novosItensDescartados = {};
  final Set<int> _slotsParaLiberar = {};
  bool _processandoSalvarItens = false;

  @override
  void initState() {
    super.initState();
    _evolucaoExpandida = widget.recompensas.temEvolucao;
    _equipamentoExpandido = widget.recompensas.temEquipamentoOuMagia;
    _itensExpandido = widget.recompensas.temItensConsumiveis;

    _itemResolvido = !widget.recompensas.temEquipamento;
    _magiaResolvida = !widget.recompensas.temMagia;

    _itensParaGuardar = List<ItemConsumivel>.from(
      widget.recompensas.itensConsumiveisRecebidos,
    );
  }

  bool get _podeFechar {
    if (widget.recompensas.itemRecebido != null && !_itemResolvido) return false;
    if (widget.recompensas.magiaRecebida != null && !_magiaResolvida) return false;
    if (_processandoItem || _processandoMagia || _processandoSalvarItens) return false;
    return true;
  }

  int get _slotsDisponiveisBase =>
      widget.mochilaAtual.slotsDesbloqueados - widget.mochilaAtual.itensOcupados;

  int get _novosItensMantidos => _itensParaGuardar.length - _novosItensDescartados.length;

  int get _slotsDisponiveisComSelecao => _slotsDisponiveisBase + _slotsParaLiberar.length;

  bool get _faltamSlotsParaNovosItens =>
      _novosItensMantidos > _slotsDisponiveisComSelecao;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _podeFechar,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade700, width: 3),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (widget.recompensas.temEvolucao) _buildEvolucaoRetratil(),
                      if (widget.recompensas.temEvolucao)
                        const SizedBox(height: 12),
                      if (widget.recompensas.temEquipamentoOuMagia)
                        _buildEquipamentoRetratil(),
                      if (widget.recompensas.temEquipamentoOuMagia)
                        const SizedBox(height: 12),
                      if (widget.recompensas.temItensConsumiveis)
                        _buildItensRetratil(),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.amber.shade700, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'RECOMPENSAS DE BATALHA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final itensMantidos = _novosItensMantidos;
    final slotsDisponiveis = _slotsDisponiveisComSelecao;
    final precisaSalvarItens = itensMantidos > 0 || _slotsParaLiberar.isNotEmpty;
    final faltaEspaco = itensMantidos > slotsDisponiveis;
    final podeAvancar = _podeFechar && (!faltaEspaco || itensMantidos == 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.amber.shade700, width: 2),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: podeAvancar
              ? () => _concluirRecompensas(
                    salvarItens: precisaSalvarItens,
                    faltaEspaco: faltaEspaco,
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: podeAvancar ? Colors.amber.shade700 : Colors.grey,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _processandoSalvarItens
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  podeAvancar
                      ? 'CONTINUAR'
                      : 'RESOLVA AS AÇÕES OBRIGATÓRIAS',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _concluirRecompensas({
    required bool salvarItens,
    required bool faltaEspaco,
  }) async {
    if (!_podeFechar) {
      _mostrarSnack(
        'Resolva primeiro os itens obrigatórios (equipamento ou magia).',
        erro: true,
      );
      return;
    }

    if (faltaEspaco) {
      _mostrarSnack(
        'Libere espaço na mochila ou descarte itens novos para continuar.',
        erro: true,
      );
      setState(() => _itensExpandido = true);
      return;
    }

    final itensParaGuardar = <ItemConsumivel>[];
    for (int i = 0; i < _itensParaGuardar.length; i++) {
      if (!_novosItensDescartados.contains(i)) {
        itensParaGuardar.add(_itensParaGuardar[i]);
      }
    }

    setState(() {
      _processandoSalvarItens = true;
    });

    try {
      if (salvarItens) {
        await widget.onGuardarItensNaMochila(
          itensParaGuardar,
          _slotsParaLiberar,
        );
      }
      await widget.onConcluir();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _mostrarSnack('Erro ao finalizar recompensas: $e', erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _processandoSalvarItens = false;
        });
      }
    }
  }
  Widget _buildEvolucaoRetratil() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade400, width: 2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _evolucaoExpandida = !_evolucaoExpandida;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EVOLUÇÃO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Icon(
                    _evolucaoExpandida ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (_evolucaoExpandida)
            ...widget.recompensas.monstrosEvoluidos
                .map(_buildMonstroEvoluidoItem)
                .toList(),
        ],
      ),
    );
  }

  Widget _buildMonstroEvoluidoItem(MonstroAventura monstro) {
    final ganhos = Map<String, int>.from(
      widget.recompensas.ganhosAtributos[monstro] ?? {},
    );
    final levelAntes = ganhos.remove('levelAntes') ?? (monstro.level - 1);
    final levelDepois = ganhos.remove('levelDepois') ?? monstro.level;
    final habilidadeDescricao = widget.recompensas.habilidadesEvoluidas[monstro];
    final ganhosPositivos = ganhos.entries
        .where((entry) => entry.value > 0)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade400, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    monstro.imagem,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: Icon(Icons.catching_pokemon, color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${monstro.nome} • Level $levelAntes → $levelDepois',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (ganhosPositivos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Ganhos de atributos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ganhosPositivos
                  .map((entry) => _buildAtributoChip(entry.key, entry.value))
                  .toList(),
            ),
          ],
          if (habilidadeDescricao != null && habilidadeDescricao.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Habilidade evoluída',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300, width: 2),
              ),
              child: Text(
                habilidadeDescricao,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.purple.shade900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAtributoChip(String atributo, int valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade400, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconeAtributo(atributo),
            color: Colors.green.shade700,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '${_nomeAtributo(atributo)} +$valor',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _nomeAtributo(String atributo) {
    switch (atributo) {
      case 'vida':
        return 'Vida';
      case 'energia':
        return 'Energia';
      case 'ataque':
        return 'Ataque';
      case 'defesa':
        return 'Defesa';
      case 'agilidade':
        return 'Agilidade';
      default:
        if (atributo.isEmpty) return atributo;
        return atributo[0].toUpperCase() + atributo.substring(1);
    }
  }

  IconData _getIconeAtributo(String atributo) {
    switch (atributo) {
      case 'vida':
        return Icons.favorite;
      case 'energia':
        return Icons.bolt;
      case 'ataque':
        return Icons.sports_mma;
      case 'defesa':
        return Icons.shield;
      case 'agilidade':
        return Icons.speed;
      default:
        return Icons.star;
    }
  }
  Widget _buildEquipamentoRetratil() {
    final temItem = widget.recompensas.itemRecebido != null;
    final temMagia = widget.recompensas.magiaRecebida != null;
    final resolvido = (!temItem || _itemResolvido) && (!temMagia || _magiaResolvida);

    // Define tier e raridade fora do if para usar depois
    final raridade = widget.recompensas.raridadeItem?.nome.toUpperCase() ?? 'DESCONHECIDA';
    final tier = widget.recompensas.tierItem?.toString() ?? '-';

    final partesTitulo = <String>[];
    if (temItem) {
      partesTitulo.add('EQUIPAMENTO TIER $tier ($raridade)');
    }
    if (temMagia) {
      partesTitulo.add('MAGIA RECEBIDA');
    }
    final titulo = partesTitulo.join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resolvido ? Colors.blue.shade700 : Colors.orange.shade700,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _equipamentoExpandido = !_equipamentoExpandido;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (!resolvido)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.priority_high,
                        size: 18,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (temItem) ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'NOVO EQUIPAMENTO',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tier $tier ($raridade)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                        if (temMagia && !temItem) ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'NOVA MAGIA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                        if (temItem && temMagia) ...[
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '+ NOVA MAGIA',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _equipamentoExpandido ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (_equipamentoExpandido) ...[
            if (temItem) _buildItemContent(),
            if (temItem && temMagia) const SizedBox(height: 12),
            if (temMagia) _buildMagiaContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildItemContent() {
    final item = widget.recompensas.itemRecebido!;
    final destaque = item.raridade.cor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.backpack, color: destaque),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: destaque.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: destaque),
                ),
                child: Text(
                  'Tier ${item.tier} • ${item.raridade.nome}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: destaque,
                  ),
                ),
              ),
            ],
          ),
          if (item.atributos.values.any((valor) => valor != 0)) ...[
            const SizedBox(height: 12),
            Text(
              'Bônus do equipamento',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: item.atributos.entries
                  .where((entry) => entry.value != 0)
                  .map((entry) => _buildAtributoChip(entry.key, entry.value))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Escolha um monstro para equipar:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildTimeJogadorGrid(
            selecionado: _monstroSelecionadoItem,
            destaque: destaque,
            onSelect: (monstro) {
              setState(() {
                _monstroSelecionadoItem = monstro;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _processandoItem || _itemResolvido
                    ? null
                    : () => _descartarItem(item),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (!_processandoItem && !_itemResolvido)
                      ? () => _equiparItem(item)
                      : null,
                  icon: _processandoItem
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_processandoItem ? 'Equipando...' : 'Equipar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: destaque,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: destaque.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeJogadorGrid({
    required MonstroAventura? selecionado,
    required Color destaque,
    required ValueChanged<MonstroAventura> onSelect,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.timeJogador.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final monstro = widget.timeJogador[index];
        final selecionadoAtual = selecionado == monstro;
        return GestureDetector(
          onTap: () => onSelect(monstro),
          child: _buildMonstroCard(monstro, selecionadoAtual, destaque),
        );
      },
    );
  }

  Widget _buildMonstroCard(
    MonstroAventura monstro,
    bool selecionado,
    Color destaque,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selecionado
            ? destaque.withOpacity(0.2)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selecionado ? destaque : Colors.grey.shade300,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Imagem do monstro e informações
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        monstro.imagem,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.catching_pokemon,
                          color: destaque,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    monstro.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Lv. ${monstro.level}',
                    style: TextStyle(
                      fontSize: 10,
                      color: destaque,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Seção da mochila
          if (monstro.itemEquipado != null)
            GestureDetector(
              onTap: () => _mostrarDetalhesItem(monstro.itemEquipado!),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.backpack,
                  color: monstro.itemEquipado!.raridade.cor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }


  String _getImagemArmadura(Item item) {
    final raridadeNome = item.raridade.nome.toLowerCase();
    switch (raridadeNome) {
      case 'inferior':
        return 'assets/armaduras/armadura_inferior.png';
      case 'normal':
        return 'assets/armaduras/armadura_normal.png';
      case 'rara':
        return 'assets/armaduras/armadura_rara.png';
      case 'épica':
      case 'epica':
        return 'assets/armaduras/armadura_epica.png';
      case 'lendária':
      case 'lendaria':
        return 'assets/armaduras/armadura_lendaria.png';
      default:
        return 'assets/armaduras/armadura_normal.png';
    }
  }

  void _mostrarDetalhesItem(Item item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.raridade.cor, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagem da armadura
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.raridade.cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: item.raridade.cor, width: 2),
                ),
                child: Image.asset(
                  _getImagemArmadura(item),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.shield,
                    color: item.raridade.cor,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.nome,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${item.raridade.nome} • Tier ${item.tier}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bônus:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...item.atributos.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_right, size: 16, color: item.raridade.cor),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.key}: +${entry.value}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
  Widget _buildMagiaContent() {
    final magia = widget.recompensas.magiaRecebida!;
    const destaque = Colors.purpleAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: destaque),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  magia.nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            magia.descricao,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoChip('Tipo', magia.tipo.nome, destaque),
              _buildInfoChip('Efeito', magia.efeito.nome, destaque),
              _buildInfoChip('Valor', magia.valor.toString(), Colors.orangeAccent),
              _buildInfoChip('Level', magia.level.toString(), Colors.lightBlueAccent),
              _buildInfoChip('Custo', '${magia.custoEnergia} EN', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Escolha um monstro para aprender:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildTimeJogadorGrid(
            selecionado: _monstroSelecionadoMagia,
            destaque: destaque,
            onSelect: (monstro) {
              setState(() {
                _monstroSelecionadoMagia = monstro;
                _habilidadeSelecionada = null;
              });
            },
          ),
          if (_monstroSelecionadoMagia != null) ...[
            const SizedBox(height: 12),
            Text(
              'Escolha qual habilidade será substituída:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (_monstroSelecionadoMagia!.habilidades.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Este monstro não possui habilidades para substituir.',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
              )
            else
              Column(
                children: _monstroSelecionadoMagia!.habilidades.map((habilidade) {
                  final selecionada = _habilidadeSelecionada == habilidade;
                  final valorCalculado = habilidade.valorEfetivo;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _habilidadeSelecionada = selecionada ? null : habilidade;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selecionada ? destaque : Colors.grey.shade300,
                          width: selecionada ? 2.5 : 1.5,
                        ),
                        boxShadow: selecionada ? [
                          BoxShadow(
                            color: destaque.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: selecionada ? destaque : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  selecionada ? Icons.check : Icons.auto_fix_high,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habilidade.nome,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Image.asset(
                                          habilidade.tipoElemental.iconAsset,
                                          width: 14,
                                          height: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Lv.${habilidade.level}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: habilidade.tipo.cor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            habilidade.tipo.nome,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: habilidade.tipo.cor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habilidade.descricao,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatBox(
                                        label: habilidade.efeito.nome,
                                        value: valorCalculado.toString(),
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatBox(
                                      label: 'Custo',
                                      value: '${habilidade.custoEnergia} EN',
                                      color: Colors.blue.shade600,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _processandoMagia || _magiaResolvida
                    ? null
                    : () => _descartarMagia(magia),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (!_processandoMagia && !_magiaResolvida)
                      ? () => _equiparMagia(magia)
                      : null,
                  icon: _processandoMagia
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_processandoMagia ? 'Aprendendo...' : 'Aprender Magia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: destaque,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: destaque.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItensRetratil() {
    final faltaEspaco = _faltamSlotsParaNovosItens;
    final totalNovos = _itensParaGuardar.length;
    final mantidos = _novosItensMantidos;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade700, width: 2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _itensExpandido = !_itensExpandido;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    faltaEspaco ? Icons.warning_amber : Icons.backpack,
                    color: faltaEspaco
                        ? Colors.orangeAccent
                        : Colors.purple.shade300,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ITENS DE MOCHILA ($mantidos/$totalNovos)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  if (faltaEspaco)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AÇÃO NECESSÁRIA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _itensExpandido ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (_itensExpandido) _buildItensContent(),
        ],
      ),
    );
  }

  Widget _buildItensContent() {
    if (_itensParaGuardar.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nenhum item foi adicionado à mochila desta vez.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      );
    }

    final faltaEspaco = _faltamSlotsParaNovosItens;
    final mantidos = _novosItensMantidos;
    final necessarios = (mantidos - _slotsDisponiveisBase).clamp(0, mantidos);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toque nos itens abaixo para alternar entre guardar ou descartar.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _itensParaGuardar.length,
            itemBuilder: (context, index) {
              final item = _itensParaGuardar[index];
              final descartado = _novosItensDescartados.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (descartado) {
                      _novosItensDescartados.remove(index);
                    } else {
                      _novosItensDescartados.add(index);
                    }
                  });
                },
                child: Stack(
                  children: [
                    Opacity(
                      opacity: descartado ? 0.35 : 1,
                      child: _buildItemConsumivel(item, index),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: descartado
                              ? Colors.redAccent
                              : Colors.purple.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          descartado ? 'DESCARTADO' : 'GUARDAR',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Espaços disponíveis: $_slotsDisponiveisBase • Necessários após escolhas: $mantidos',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          if (faltaEspaco) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade700),
              ),
              child: Text(
                'Libere ao menos $necessarios espaço(s) na mochila ou descarte itens novos.',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Selecione itens existentes para liberar espaço:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildMochilaGrid(),
        ],
      ),
    );
  }

  Widget _buildItemConsumivel(ItemConsumivel item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.raridade.cor, width: 2),
      ),
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: item.iconPath.isNotEmpty
                    ? Image.asset(
                        item.iconPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          _getIconForType(item.tipo),
                          size: 28,
                          color: item.raridade.cor,
                        ),
                      )
                    : Icon(
                        _getIconForType(item.tipo),
                        size: 28,
                        color: item.raridade.cor,
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                item.nome,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
              ),
            ],
          ),
          if (item.quantidade > 1)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: item.raridade.cor),
                ),
                child: Text(
                  'x${item.quantidade}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item.raridade.cor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildMochilaGrid() {
    final itens = widget.mochilaAtual.itens;
    final totalSlots = widget.mochilaAtual.slotsDesbloqueados;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = itens[index];
        final selecionado = _slotsParaLiberar.contains(index);
        return GestureDetector(
          onTap: item == null
              ? null
              : () {
                  setState(() {
                    if (selecionado) {
                      _slotsParaLiberar.remove(index);
                    } else {
                      _slotsParaLiberar.add(index);
                    }
                  });
                },
          child: _buildMochilaSlot(item, selecionado),
        );
      },
    );
  }

  Widget _buildMochilaSlot(ItemConsumivel? item, bool selecionado) {
    final corBorda = selecionado ? Colors.redAccent : Colors.grey.shade300;
    final corpo = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selecionado
            ? Colors.red.withOpacity(0.2)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: corBorda,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: item == null
          ? Center(
              child: Icon(
                Icons.add_box_outlined,
                color: Colors.grey.shade300,
                size: 20,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: item.iconPath.isNotEmpty
                      ? Image.asset(
                          item.iconPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2,
                          color: Colors.grey.shade600,
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );

    if (!selecionado) {
      return corpo;
    }

    return Stack(
      children: [
        corpo,
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'REMOVER',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _equiparItem(Item item) async {
    final monstro = _monstroSelecionadoItem;
    if (monstro == null) {
      _mostrarSnack('Selecione um monstro para equipar o item.', erro: true);
      return;
    }

    setState(() => _processandoItem = true);
    try {
      await widget.onEquiparItem(monstro, item);
      if (mounted) {
        setState(() {
          _itemResolvido = true;
          _processandoItem = false;
        });
        _mostrarSnack('${item.nome} equipado em ${monstro.nome}!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoItem = false);
        _mostrarSnack('Erro ao equipar item: $e', erro: true);
      }
    }
  }

  Future<void> _descartarItem(Item item) async {
    setState(() => _processandoItem = true);
    try {
      await widget.onDescartarItem(item);
      if (mounted) {
        setState(() {
          _itemResolvido = true;
          _processandoItem = false;
          _monstroSelecionadoItem = null;
        });
        _mostrarSnack('${item.nome} descartado.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoItem = false);
        _mostrarSnack('Erro ao descartar item: $e', erro: true);
      }
    }
  }

  Future<void> _equiparMagia(MagiaDrop magia) async {
    final monstro = _monstroSelecionadoMagia;
    if (monstro == null) {
      _mostrarSnack('Selecione um monstro para aprender a magia.', erro: true);
      return;
    }
    if (monstro.habilidades.isEmpty) {
      _mostrarSnack(
        'Este monstro não possui habilidades para substituir.',
        erro: true,
      );
      return;
    }
    if (_habilidadeSelecionada == null) {
      _mostrarSnack(
        'Escolha qual habilidade será substituída.',
        erro: true,
      );
      return;
    }

    setState(() => _processandoMagia = true);
    try {
      await widget.onEquiparMagia(
        monstro,
        magia,
        _habilidadeSelecionada!,
      );
      if (mounted) {
        setState(() {
          _magiaResolvida = true;
          _processandoMagia = false;
        });
        _mostrarSnack('${magia.nome} aprendida por ${monstro.nome}!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoMagia = false);
        _mostrarSnack('Erro ao aprender magia: $e', erro: true);
      }
    }
  }

  Future<void> _descartarMagia(MagiaDrop magia) async {
    setState(() => _processandoMagia = true);
    try {
      await widget.onDescartarMagia(magia);
      if (mounted) {
        setState(() {
          _magiaResolvida = true;
          _processandoMagia = false;
          _monstroSelecionadoMagia = null;
          _habilidadeSelecionada = null;
        });
        _mostrarSnack('${magia.nome} foi descartada.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoMagia = false);
        _mostrarSnack('Erro ao descartar magia: $e', erro: true);
      }
    }
  }

  void _mostrarSnack(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade600,
      ),
    );
  }

  IconData _getIconForType(TipoItemConsumivel tipo) {
    switch (tipo) {
      case TipoItemConsumivel.pocao:
        return Icons.local_drink;
      case TipoItemConsumivel.joia:
        return Icons.diamond;
      case TipoItemConsumivel.pergaminho:
        return Icons.article;
      case TipoItemConsumivel.elixir:
        return Icons.science;
      case TipoItemConsumivel.fragmento:
        return Icons.broken_image;
    }
  }
}
