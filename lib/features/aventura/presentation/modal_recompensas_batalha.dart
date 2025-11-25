import 'package:flutter/material.dart';

import '../models/drop.dart';
import '../models/habilidade.dart';
import '../models/item.dart';
import '../models/item_consumivel.dart';
import '../models/magia_drop.dart';
import '../models/mochila.dart';
import '../models/monstro_aventura.dart';
import 'widgets/gerenciador_equipamentos_monstros.dart';

class RecompensasBatalha {
  final List<MonstroAventura> monstrosEvoluidos;
  final Map<MonstroAventura, Map<String, int>> ganhosAtributos;
  final Map<MonstroAventura, Map<String, dynamic>?> habilidadesEvoluidas;

  final Item? itemRecebido; // Mantido para compatibilidade (drops de elites/equipados)
  final int? tierItem;
  final RaridadeItem? raridadeItem;

  final MagiaDrop? magiaRecebida; // Mantido para compatibilidade

  final List<Item> itensRecebidos; // NOVO: Múltiplos itens do sistema de drops independentes
  final List<MagiaDrop> magiasRecebidas; // NOVO: Múltiplas magias do sistema de drops independentes

  final List<ItemConsumivel> itensConsumiveisRecebidos;

  final int moedaEvento; // Quantidade de moedas de evento recebidas (moedaHalloween)
  final int moedaChave; // Quantidade de moedas chave recebidas
  final int teks; // Quantidade de Teks (moeda do Criadouro)

  final List<TipoDrop> dropsDoSortudo; // Lista de tipos de drop que vieram da passiva Sortudo
  final bool superDrop; // Se ativou o super drop

  const RecompensasBatalha({
    this.monstrosEvoluidos = const [],
    this.ganhosAtributos = const {},
    this.habilidadesEvoluidas = const {},
    this.itemRecebido,
    this.tierItem,
    this.raridadeItem,
    this.magiaRecebida,
    this.itensRecebidos = const [],
    this.magiasRecebidas = const [],
    this.itensConsumiveisRecebidos = const [],
    this.moedaEvento = 0,
    this.moedaChave = 0,
    this.teks = 0,
    this.dropsDoSortudo = const [],
    this.superDrop = false,
  });

  bool get temEvolucao => monstrosEvoluidos.isNotEmpty;
  bool get temEquipamento => itemRecebido != null || itensRecebidos.isNotEmpty;
  bool get temMagia => magiaRecebida != null || magiasRecebidas.isNotEmpty;
  bool get temEquipamentoOuMagia => temEquipamento || temMagia;
  bool get temItensConsumiveis => itensConsumiveisRecebidos.isNotEmpty;
  bool get temMoedaEvento => moedaEvento > 0;
  bool get temTeks => teks > 0;
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
    int moedaEvento,
    int moedaChave,
    int teks,
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

  // Controle individual de expansão para cada item/magia do novo sistema
  final Map<String, bool> _itensExpandidos = {}; // key: "item_$index"
  final Map<String, bool> _magiasExpandidas = {}; // key: "magia_$index"

  // Sistema novo: controle individual para cada item
  final Map<String, MonstroAventura?> _monstrosSelecionadosItens = {}; // key: "item_$index"
  final Map<String, bool> _processandoItens = {}; // key: "item_$index"
  final Map<String, bool> _itensResolvidos = {}; // key: "item_$index"

  // Sistema antigo: controle de item/magia única
  bool _itemResolvido = false;
  bool _magiaResolvida = false;

  MonstroAventura? _monstroSelecionadoItem;
  bool _processandoItem = false;

  MonstroAventura? _monstroSelecionadoMagia;
  Habilidade? _habilidadeSelecionada;
  bool _processandoMagia = false;

  // Sistema novo: controle individual para cada magia
  final Map<String, MonstroAventura?> _monstrosSelecionadosMagias = {}; // key: "magia_$index"
  final Map<String, Habilidade?> _habilidadesSelecionadasMagias = {}; // key: "magia_$index"
  final Map<String, bool> _processandoMagias = {}; // key: "magia_$index"

  late List<ItemConsumivel> _itensParaGuardar;
  final Set<int> _novosItensDescartados = {};
  final Set<int> _slotsParaLiberar = {};
  bool _processandoSalvarItens = false;

  @override
  void initState() {
    super.initState();
    // Todos os menus começam retraídos
    _evolucaoExpandida = false;
    _equipamentoExpandido = false;
    _itensExpandido = false;

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

  // DROPS vão para a mochila comum, então verificamos o espaço disponível
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

                      // Sistema antigo: item único
                      if (widget.recompensas.itemRecebido != null) ...[
                        _buildEquipamentoRetratil(),
                        const SizedBox(height: 12),
                      ],

                      // Sistema antigo: magia única
                      if (widget.recompensas.magiaRecebida != null) ...[
                        _buildMagiaRetratil(),
                        const SizedBox(height: 12),
                      ],

                      // Sistema novo: múltiplos itens (cada um em sua própria aba)
                      ...widget.recompensas.itensRecebidos.asMap().entries.map((entry) {
                        return Column(
                          children: [
                            _buildItemRetratil(entry.value, entry.key),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),

                      // Sistema novo: múltiplas magias (cada uma em sua própria aba)
                      ...widget.recompensas.magiasRecebidas.asMap().entries.map((entry) {
                        return Column(
                          children: [
                            _buildMagiaRetratilNova(entry.value, entry.key),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),

                      if (widget.recompensas.temItensConsumiveis ||
                          widget.recompensas.temMoedaEvento ||
                          widget.recompensas.moedaChave > 0)
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(17),
          bottomRight: Radius.circular(17),
        ),
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
    print('[ModalRecompensas] 🚀 Concluindo recompensas - salvarItens=$salvarItens, faltaEspaco=$faltaEspaco');

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

    print('[ModalRecompensas] 📦 Total de itens: ${_itensParaGuardar.length}');
    print('[ModalRecompensas] 📦 Itens descartados: ${_novosItensDescartados.length}');
    print('[ModalRecompensas] ✅ Itens para guardar: ${itensParaGuardar.length}');
    for (var item in itensParaGuardar) {
      print('[ModalRecompensas]    - ${item.nome} (iconPath: ${item.iconPath})');
    }

    setState(() {
      _processandoSalvarItens = true;
    });

    try {
      // SEMPRE salva se tiver moedas de evento/chave/teks, mesmo que descarte todos os itens
      if (salvarItens || widget.recompensas.moedaEvento > 0 || widget.recompensas.moedaChave > 0 || widget.recompensas.teks > 0) {
        print('[ModalRecompensas] 💾 Chamando onGuardarItensNaMochila...');
        await widget.onGuardarItensNaMochila(
          itensParaGuardar,
          _slotsParaLiberar,
          widget.recompensas.moedaEvento,
          widget.recompensas.moedaChave,
          widget.recompensas.teks,
        );
        print('[ModalRecompensas] ✅ onGuardarItensNaMochila concluído');
      } else {
        print('[ModalRecompensas] ⏭️ Pulando salvamento (sem itens e sem moedas)');
      }
      print('[ModalRecompensas] 🏁 Chamando onConcluir...');
      await widget.onConcluir();
      print('[ModalRecompensas] ✅ onConcluir concluído');
      print('[ModalRecompensas] 🚪 Fechando modal de recompensas...');
      if (mounted) {
        Navigator.of(context).pop(); // Apenas fecha o modal, não sai da batalha
      }
    } catch (e, stack) {
      print('[ModalRecompensas] ❌ Erro ao finalizar: $e');
      print(stack);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EVOLUÇÃO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (widget.recompensas.monstrosEvoluidos.isNotEmpty)
                          Builder(
                            builder: (context) {
                              final monstro = widget.recompensas.monstrosEvoluidos.first;
                              final ganhos = widget.recompensas.ganhosAtributos[monstro] ?? {};
                              final levelAntes = ganhos['levelAntes'] ?? (monstro.level - 1);
                              final levelDepois = ganhos['levelDepois'] ?? monstro.level;

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calcula se o nome completo cabe
                                  final nomeCompleto = monstro.nome;
                                  final textPainter = TextPainter(
                                    text: TextSpan(
                                      text: nomeCompleto,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    maxLines: 1,
                                    textDirection: TextDirection.ltr,
                                  )..layout(maxWidth: constraints.maxWidth - 80);

                                  final fontSize = textPainter.didExceedMaxLines ? 11.0 : 13.0;

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '$nomeCompleto - Level',
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade400, width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$levelAntes',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(Icons.arrow_forward, size: 10, color: Colors.green.shade700),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$levelDepois',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                      ],
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
    final habilidadeInfo = widget.recompensas.habilidadesEvoluidas[monstro];
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monstro.nome,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Vida recuperada: ${ganhos['vida'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Status recebidos logo após a foto e vida recuperada
          if (ganhosPositivos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ganhosPositivos
                  .map((entry) => _buildAtributoChip(entry.key, entry.value))
                  .toList(),
            ),
          ],
          // Habilidade evoluída com mais detalhes
          if (habilidadeInfo != null && habilidadeInfo['evoluiu'] == true) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.shade200.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade600, Colors.purple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Row 1: Ícone + Texto com resize
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  const texto = 'HABILIDADE EVOLUÍDA';
                                  final textPainter = TextPainter(
                                    text: const TextSpan(
                                      text: texto,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    maxLines: 1,
                                    textDirection: TextDirection.ltr,
                                  )..layout(maxWidth: constraints.maxWidth);

                                  final fontSize = textPainter.didExceedMaxLines ? 10.0 : 13.0;
                                  final letterSpacing = textPainter.didExceedMaxLines ? 0.5 : 1.0;

                                  return Text(
                                    texto,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: letterSpacing,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Row 2: Nome da habilidade com resize
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final nomeHabilidade = habilidadeInfo['nome'] ?? '';
                            final textPainter = TextPainter(
                              text: TextSpan(
                                text: nomeHabilidade,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                            )..layout(maxWidth: constraints.maxWidth);

                            final fontSize = textPainter.didExceedMaxLines ? 14.0 : 18.0;

                            return Text(
                              nomeHabilidade,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        // Level centralizado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lv ${habilidadeInfo['levelAntes']}',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.purple.shade700,
                                  size: 16,
                                ),
                              ),
                              Text(
                                'Lv ${habilidadeInfo['levelDepois']}',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conteúdo
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Descrição (substitui o valor base pelo valor efetivo)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Builder(
                            builder: (context) {
                              final descricaoOriginal = habilidadeInfo['descricao'] ?? '';
                              final valorBase = habilidadeInfo['valorAntes'];
                              final valorEfetivo = habilidadeInfo['valorEfetivoDepois'];

                              // Substitui o valor base pelo valor efetivo na descrição
                              String descricaoAtualizada = descricaoOriginal;
                              if (valorBase != null && valorEfetivo != null) {
                                descricaoAtualizada = descricaoOriginal.replaceAll(
                                  '$valorBase pontos',
                                  '$valorEfetivo pontos',
                                );
                              }

                              return Text(
                                descricaoAtualizada,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Estatísticas reformuladas
                        _buildCompactStatRow(
                          'Pontuação',
                          habilidadeInfo['valorEfetivoAntes'],
                          habilidadeInfo['valorEfetivoDepois'],
                          Icons.stars,
                          Colors.amber.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildAtributoLinha(String atributo, int valor) {
    Color cor = _getCorAtributo(atributo);
    IconData icon = _getIconeAtributo(atributo);
    String nome = _nomeAtributo(atributo);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 20),
          const SizedBox(width: 10),
          Text(
            nome,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cor,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$valor',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCorAtributo(String atributo) {
    switch (atributo) {
      case 'vida':
        return Colors.red;
      case 'energia':
        return Colors.blue;
      case 'ataque':
        return Colors.orange;
      case 'defesa':
        return Colors.green;
      case 'agilidade':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCompactStatRow(
    String label,
    int? valorAntes,
    int? valorDepois,
    IconData icon,
    Color color,
  ) {
    if (valorAntes == null || valorDepois == null) return const SizedBox.shrink();

    final diferenca = valorDepois - valorAntes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Linha 1: Ícone + Pontuação (centralizado)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linha 2: Formato "76 -> 114 ganho de +38"
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                '$valorAntes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 20,
                color: color,
              ),
              Text(
                '$valorDepois',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (diferenca != 0) ...[
                const SizedBox(width: 4),
                Text(
                  'ganho de',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diferenca > 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    diferenca > 0 ? '+$diferenca' : '$diferenca',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
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
    // Verifica drops do sistema antigo (compatibilidade)
    // IMPORTANTE: Este método é APENAS para o sistema antigo (drops de elites/equipados)
    // Os drops do novo sistema (independentes) têm suas próprias abas individuais
    final temItemAntigo = widget.recompensas.itemRecebido != null;
    final temMagiaAntiga = widget.recompensas.magiaRecebida != null;

    final temItem = temItemAntigo;
    final temMagia = temMagiaAntiga;
    final resolvido = (!temItem || _itemResolvido) && (!temMagia || _magiaResolvida);

    // Define tier e raridade para o título (sistema antigo apenas)
    final raridade = widget.recompensas.raridadeItem?.nome.toUpperCase() ?? 'DESCONHECIDA';
    final tier = widget.recompensas.tierItem?.toString() ?? '-';

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
                          Text(
                            'NOVO EQUIPAMENTO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final texto = 'Tier $tier ($raridade)';
                              final textPainter = TextPainter(
                                text: TextSpan(
                                  text: texto,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                maxLines: 1,
                                textDirection: TextDirection.ltr,
                              )..layout(maxWidth: constraints.maxWidth);

                              final fontSize = textPainter.didExceedMaxLines ? 11.0 : 13.0;

                              return Text(
                                texto,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                        if (temMagia && !temItem) ...[
                          Text(
                            'NOVA MAGIA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
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
            // Sistema antigo: item único
            if (temItemAntigo) _buildItemContent(),

            if ((temItem) && (temMagia)) const SizedBox(height: 12),

            // Sistema antigo: magia única
            if (temMagiaAntiga) _buildMagiaContent(),
          ],
        ],
      ),
    );
  }

  // NOVO: Seção retrátil para um item individual (sistema novo)
  Widget _buildItemRetratil(Item item, int index) {
    final destaque = item.raridade.cor;
    final key = 'item_$index';
    final expandido = _itensExpandidos[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque, width: 2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _itensExpandidos[key] = !expandido;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.backpack, color: destaque, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EQUIPAMENTO ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tier ${item.tier} - ${item.raridade.nome}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (expandido) _buildItemContentNovo(item, index),
        ],
      ),
    );
  }

  // NOVO: Seção retrátil para uma magia individual (sistema antigo compatibilidade)
  Widget _buildMagiaRetratil() {
    final magia = widget.recompensas.magiaRecebida!;
    const destaque = Colors.purpleAccent;
    final expandido = _equipamentoExpandido;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque, width: 2),
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
                  Icon(Icons.auto_fix_high, color: destaque, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MAGIA RECEBIDA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (expandido) _buildMagiaContent(),
        ],
      ),
    );
  }

  // NOVO: Seção retrátil para uma magia individual (sistema novo)
  Widget _buildMagiaRetratilNova(MagiaDrop magia, int index) {
    const destaque = Colors.purpleAccent;
    final key = 'magia_$index';
    final expandido = _magiasExpandidas[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque, width: 2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _magiasExpandidas[key] = !expandido;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high, color: destaque, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAGIA ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level ${magia.level}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (expandido) _buildMagiaContentNova(magia, index),
        ],
      ),
    );
  }

  // NOVO: Método para exibir um item da lista (sistema independente)
  Widget _buildItemContentNovo(Item item, int index) {
    final destaque = item.raridade.cor;
    final key = 'item_$index';
    final monstroSelecionado = _monstrosSelecionadosItens[key];
    final processando = _processandoItens[key] ?? false;
    final resolvido = _itensResolvidos[key] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [destaque.withOpacity(0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque, width: 2),
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
                  'Tier ${item.tier} - ${item.raridade.nome}',
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
              'Bônus do equipamento:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...item.atributos.entries
                .where((entry) => entry.value != 0)
                .map((entry) => _buildAtributoLinha(entry.key, entry.value)),
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
          GerenciadorEquipamentosMonstros(
            monstros: widget.timeJogador,
            monstroSelecionado: monstroSelecionado,
            corDestaque: destaque,
            onSelecionarMonstro: (monstro) {
              setState(() {
                _monstrosSelecionadosItens[key] = monstro;
              });
            },
            onVisualizarEquipamento: _mostrarDetalhesItem,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: processando || resolvido
                    ? null
                    : () => _descartarItemNovo(item, index),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (!processando && !resolvido)
                      ? () => _equiparItemNovo(item, index)
                      : null,
                  icon: processando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(processando ? 'Equipando...' : 'Equipar'),
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

  Widget _buildItemContent() {
    final item = widget.recompensas.itemRecebido!;
    final destaque = item.raridade.cor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [destaque.withOpacity(0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque, width: 2),
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
                  'Tier ${item.tier} - ${item.raridade.nome}',
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
              'Bônus do equipamento:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...item.atributos.entries
                .where((entry) => entry.value != 0)
                .map((entry) => _buildAtributoLinha(entry.key, entry.value))
                .toList(),
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
          GerenciadorEquipamentosMonstros(
            monstros: widget.timeJogador,
            monstroSelecionado: _monstroSelecionadoItem,
            corDestaque: destaque,
            onSelecionarMonstro: (monstro) {
              setState(() {
                _monstroSelecionadoItem = monstro;
              });
            },
            onVisualizarEquipamento: _mostrarDetalhesItem,
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
      case 'impossível':
      case 'impossivel':
        return 'assets/armaduras/armadura_impossivel.png';
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
                '${item.raridade.nome} - Tier ${item.tier}',
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
  // NOVO: Método para exibir uma magia da lista (sistema independente)
  Widget _buildMagiaContentNova(MagiaDrop magia, int index) {
    const destaque = Colors.purpleAccent;
    final key = 'magia_$index';
    final monstroSelecionado = _monstrosSelecionadosMagias[key];
    final habilidadeSelecionada = _habilidadesSelecionadasMagias[key];
    final processando = _processandoMagias[key] ?? false;

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
              Image.asset(
                _getImagemTipoMagia(magia),
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
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
              _buildInfoChip('Valor', magia.valorEfetivo.toString(), Colors.orangeAccent),
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
          GerenciadorEquipamentosMonstros(
            monstros: widget.timeJogador,
            monstroSelecionado: monstroSelecionado,
            corDestaque: destaque,
            onSelecionarMonstro: (monstro) {
              setState(() {
                _monstrosSelecionadosMagias[key] = monstro;
                _habilidadesSelecionadasMagias[key] = null;
              });
            },
            onVisualizarEquipamento: _mostrarDetalhesItem,
          ),
          if (monstroSelecionado != null) ...[
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
            if (monstroSelecionado.habilidades.isEmpty)
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
                children: monstroSelecionado.habilidades.map((habilidade) {
                  final selecionada = habilidadeSelecionada == habilidade;
                  final valorCalculado = habilidade.valorEfetivo;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _habilidadesSelecionadasMagias[key] = selecionada ? null : habilidade;
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
                                child: selecionada
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        _getImagemTipoHabilidade(habilidade),
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.contain,
                                        color: Colors.white,
                                      ),
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
                onPressed: processando ? null : () => _descartarMagiaNova(magia, index),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !processando ? () => _equiparMagiaNova(magia, index) : null,
                  icon: processando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(processando ? 'Aprendendo...' : 'Aprender Magia'),
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
              Image.asset(
                _getImagemTipoMagia(magia),
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
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
              _buildInfoChip('Valor', magia.valorEfetivo.toString(), Colors.orangeAccent),
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
          GerenciadorEquipamentosMonstros(
            monstros: widget.timeJogador,
            monstroSelecionado: _monstroSelecionadoMagia,
            corDestaque: destaque,
            onSelecionarMonstro: (monstro) {
              setState(() {
                _monstroSelecionadoMagia = monstro;
                _habilidadeSelecionada = null;
              });
            },
            onVisualizarEquipamento: _mostrarDetalhesItem,
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
                                child: selecionada
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Image.asset(
                                        _getImagemTipoHabilidade(habilidade),
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.contain,
                                        color: Colors.white,
                                      ),
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

  /// Seção retrátil para exibir os DROPS obtidos na batalha
  /// DROPS são itens consumíveis como poções e pedras de reforço
  /// que vão direto para os 3 slots especiais de drops na mochila (não são itens comuns)
  Widget _buildItensRetratil() {
    final faltaEspaco = _faltamSlotsParaNovosItens;
    final totalNovos = _itensParaGuardar.length;
    final mantidos = _novosItensMantidos;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700, width: 2), // Cor amber para drops
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
                    faltaEspaco ? Icons.warning_amber : Icons.card_giftcard, // Ícone de presente para drops
                    color: faltaEspaco
                        ? Colors.orangeAccent
                        : Colors.amber.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DROPS ($mantidos/$totalNovos)', // Nome alterado para DROPS
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
    final temItens = _itensParaGuardar.isNotEmpty;
    final temMoeda = widget.recompensas.temMoedaEvento;

    if (!temItens && !temMoeda) {
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
          if (temItens)
            Text(
              'Toque nos itens abaixo para alternar entre guardar ou descartar.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          if (temItens) const SizedBox(height: 8),

          // Moeda de Evento (sempre coletada, não pode ser descartada)
          if (temMoeda) ...[
            _buildMoedaEventoCard(),
            const SizedBox(height: 8),
          ],

          // Moeda Chave (sempre coletada, não pode ser descartada)
          if (widget.recompensas.moedaChave > 0) ...[
            _buildMoedaChaveCard(),
            const SizedBox(height: 8),
          ],

          // Teks (sempre coletada, não pode ser descartada)
          if (widget.recompensas.teks > 0) ...[
            _buildTeksCard(),
            const SizedBox(height: 8),
          ],

          // Lista vertical de drops (não grid)
          if (temItens)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _itensParaGuardar.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _itensParaGuardar[index];
                final descartado = _novosItensDescartados.contains(index);

                // Exibe cada drop obtido com opção de guardar ou descartar
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
                  child: _buildDropCard(item, index, descartado),
                );
              },
            ),
          const SizedBox(height: 12),
          Text(
            'Espaços disponíveis: $_slotsDisponiveisBase - Necessários: $mantidos',
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
                'Libere ao menos $necessarios espaço(s) na mochila ou descarte drops novos.',
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
          const SizedBox(height: 12),
          _buildBotaoDescartarTodosRow(),
        ],
      ),
    );
  }

  /// Widget que exibe um DROP (poção/pedra) com imagem maior de assets/drops/
  /// Imagem grande em Row com texto e descrição ao lado
  Widget _buildDropCard(ItemConsumivel item, int index, bool descartado) {
    // Verifica se este item específico veio do Sortudo
    // O item.id contém o TipoDrop.id original (ex: "frutaNuty", "pocaoVidaPequena")
    final bool veioDoSortudo = widget.recompensas.dropsDoSortudo.any((tipoDrop) => tipoDrop.id == item.id);

    return Container(
      decoration: BoxDecoration(
        color: descartado ? Colors.grey.shade200 : (veioDoSortudo ? Colors.green.shade50 : Colors.amber.shade50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: descartado ? Colors.grey.shade400 : (veioDoSortudo ? Colors.green.shade700 : Colors.amber.shade700),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Mensagem especial do Sortudo (se aplicável)
          if (veioDoSortudo) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🍀 PASSIVA SORTUDO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagem MAIOR do drop (assets/drops/)
              Opacity(
                opacity: descartado ? 0.4 : 1.0,
                child: item.iconPath.isNotEmpty
                    ? Image.asset(
                        item.iconPath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          _getIconForType(item.tipo),
                          size: 60,
                          color: veioDoSortudo ? Colors.green.shade700 : Colors.amber.shade700,
                        ),
                      )
                    : Icon(
                        _getIconForType(item.tipo),
                        size: 60,
                        color: veioDoSortudo ? Colors.green.shade700 : Colors.amber.shade700,
                      ),
              ),
              const SizedBox(width: 12),
              // Informações do item ao lado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícone de status (guardar/descartar) + Nome
                    Row(
                      children: [
                        Icon(
                          descartado ? Icons.delete : Icons.inventory_2,
                          size: 16,
                          color: descartado ? Colors.red.shade600 : Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: descartado ? Colors.grey.shade600 : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Descrição do que o item faz
                    Text(
                      item.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: descartado ? Colors.grey.shade500 : Colors.grey.shade600,
                        height: 1.2,
                      ),
                    ),
                    // Mensagem adicional do Sortudo
                    if (veioDoSortudo) ...[
                      const SizedBox(height: 4),
                      Text(
                        'A sorte favoreceu você nesta batalha!',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoedaEventoCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Fundo laranja claro para lendário
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF9800), // Laranja para lendário
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagem da moeda de evento
          Image.asset(
            'assets/eventos/halloween/moeda_halloween.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.stars,
              size: 60,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(width: 12),
          // Informações da moeda
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de coletado + Nome
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Moeda de Evento',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Quantidade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x${widget.recompensas.moedaEvento}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Descrição
                const Text(
                  'Moeda especial coletada automaticamente! Use na loja para roletas especiais.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Tag de raridade
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LENDÁRIO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoedaChaveCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Fundo azul claro
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2196F3), // Azul
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone da moeda chave
          const Icon(
            Icons.vpn_key,
            size: 60,
            color: Color(0xFF2196F3),
          ),
          const SizedBox(width: 12),
          // Informações da moeda
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de coletado + Nome
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Moeda Chave',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Quantidade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x${widget.recompensas.moedaChave}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Descrição
                const Text(
                  'Moeda rara coletada automaticamente! Use para desbloquear conteúdos especiais.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Tag de raridade
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ÉPICO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeksCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Fundo verde claro
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF4CAF50), // Verde
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone da Teks (emoji de planta/semente)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '🌱',
                style: TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Informações da Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de coletado + Nome
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Teks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Quantidade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x${widget.recompensas.teks}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Descrição
                const Text(
                  'Moeda do Criadouro! Use para comprar itens e cuidar do seu mascote.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Tag de raridade
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CRIADOURO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(8),
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
                size: 24,
              ),
            )
          : Center(
              child: item.iconPath.isNotEmpty
                  ? Image.asset(
                      item.iconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2,
                        color: Colors.grey.shade600,
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.inventory_2,
                      color: Colors.grey.shade600,
                      size: 32,
                    ),
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

  Widget _buildBotaoDescartarTodosRow() {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              // Descarta todos os drops recebidos (marca todos como descartados)
              for (int i = 0; i < widget.recompensas.itensConsumiveisRecebidos.length; i++) {
                if (!_novosItensDescartados.contains(i)) {
                  _novosItensDescartados.add(i);
                }
              }
            });
          },
          icon: const Icon(Icons.delete_forever),
          label: const Text('Descartar Todos os Drops'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
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

  // Métodos para múltiplos itens (sistema novo)
  Future<void> _equiparItemNovo(Item item, int index) async {
    final key = 'item_$index';
    final monstro = _monstrosSelecionadosItens[key];
    if (monstro == null) {
      _mostrarSnack('Selecione um monstro para equipar o item.', erro: true);
      return;
    }

    setState(() => _processandoItens[key] = true);
    try {
      await widget.onEquiparItem(monstro, item);
      if (mounted) {
        setState(() {
          _itensResolvidos[key] = true;
          _processandoItens[key] = false;
        });
        _mostrarSnack('${item.nome} equipado em ${monstro.nome}!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoItens[key] = false);
        _mostrarSnack('Erro ao equipar item: $e', erro: true);
      }
    }
  }

  Future<void> _descartarItemNovo(Item item, int index) async {
    final key = 'item_$index';
    setState(() => _processandoItens[key] = true);
    try {
      await widget.onDescartarItem(item);
      if (mounted) {
        setState(() {
          _itensResolvidos[key] = true;
          _processandoItens[key] = false;
          _monstrosSelecionadosItens[key] = null;
        });
        _mostrarSnack('${item.nome} descartado.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoItens[key] = false);
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

  // NOVO: Equipar magia do sistema independente
  Future<void> _equiparMagiaNova(MagiaDrop magia, int index) async {
    final key = 'magia_$index';
    final monstro = _monstrosSelecionadosMagias[key];
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
    final habilidadeSelecionada = _habilidadesSelecionadasMagias[key];
    if (habilidadeSelecionada == null) {
      _mostrarSnack(
        'Escolha qual habilidade será substituída.',
        erro: true,
      );
      return;
    }

    setState(() => _processandoMagias[key] = true);
    try {
      await widget.onEquiparMagia(
        monstro,
        magia,
        habilidadeSelecionada,
      );
      if (mounted) {
        setState(() {
          _processandoMagias[key] = false;
          // Limpa a seleção após equipar
          _monstrosSelecionadosMagias[key] = null;
          _habilidadesSelecionadasMagias[key] = null;
        });
        _mostrarSnack('${magia.nome} aprendida por ${monstro.nome}!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoMagias[key] = false);
        _mostrarSnack('Erro ao aprender magia: $e', erro: true);
      }
    }
  }

  // NOVO: Descartar magia do sistema independente
  Future<void> _descartarMagiaNova(MagiaDrop magia, int index) async {
    final key = 'magia_$index';
    setState(() => _processandoMagias[key] = true);
    try {
      await widget.onDescartarMagia(magia);
      if (mounted) {
        setState(() {
          _processandoMagias[key] = false;
          // Limpa a seleção após descartar
          _monstrosSelecionadosMagias[key] = null;
          _habilidadesSelecionadasMagias[key] = null;
        });
        _mostrarSnack('${magia.nome} foi descartada.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processandoMagias[key] = false);
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
      case TipoItemConsumivel.fruta:
        return Icons.apple;
      case TipoItemConsumivel.vidinha:
        return Icons.favorite;
      case TipoItemConsumivel.pergaminho:
        return Icons.article;
      case TipoItemConsumivel.elixir:
        return Icons.science;
      case TipoItemConsumivel.fragmento:
        return Icons.broken_image;
      case TipoItemConsumivel.moedaEvento:
      case TipoItemConsumivel.moedaHalloween:
        return Icons.stars;
      case TipoItemConsumivel.moedaChave:
        return Icons.key;
      case TipoItemConsumivel.ovoEvento:
        return Icons.egg;
    }
  }

  String _getImagemTipoMagia(MagiaDrop magia) {
    final tipo = magia.tipo.toString().toLowerCase();
    if (tipo.contains('ofensiv')) return 'assets/icons_gerais/magia_ofensiva.png';
    if (tipo.contains('cura')) return 'assets/icons_gerais/magia_cura.png';
    if (tipo.contains('suporte')) return 'assets/icons_gerais/magia_suporte.png';
    return 'assets/icons_gerais/magia.png';
  }

  String _getImagemTipoHabilidade(Habilidade hab) {
    final tipo = hab.tipo.toString().toLowerCase();
    if (tipo.contains('ofensiv')) return 'assets/icons_gerais/magia_ofensiva.png';
    if (tipo.contains('cura')) return 'assets/icons_gerais/magia_cura.png';
    if (tipo.contains('suporte')) return 'assets/icons_gerais/magia_suporte.png';
    return 'assets/icons_gerais/magia.png';
  }
}
