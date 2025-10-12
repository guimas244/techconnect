import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../models/mochila.dart';
import '../services/item_service.dart';
import '../services/magia_service.dart';
import '../services/mochila_service.dart';
import 'models/resultado_loja.dart';
import 'roleta_halloween_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/habilidade.dart';
import '../../auth/providers/auth_provider.dart';

/// Casa do Vigarista - Nova implementação seguindo REESTRUTURACAO_LOJA.md
/// Retorna ResultadoLoja via Navigator.pop() ou callback se inline
class CasaVigaristaScreen extends ConsumerStatefulWidget {
  final HistoriaJogador historia;
  final Function(ResultadoLoja)? onResultado; // Callback para quando está inline na tab

  const CasaVigaristaScreen({
    super.key,
    required this.historia,
    this.onResultado,
  });

  @override
  ConsumerState<CasaVigaristaScreen> createState() => _CasaVigaristaScreenState();
}

class _CasaVigaristaScreenState extends ConsumerState<CasaVigaristaScreen> {
  final ItemService _itemService = ItemService();
  final MagiaService _magiaService = MagiaService();
  late HistoriaJogador _historiaAtual;
  bool _comprando = false;
  Mochila? _mochila;

  // Custos dinâmicos baseados no tier
  int get custoAposta => 2 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
  int get custoCura => 1 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
  int get custoFeirao => ((_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier) * 1.5).ceil();
  int get custoRoleta => 1; // Roleta custa 1 moeda de evento

  @override
  void initState() {
    super.initState();
    _historiaAtual = widget.historia;
    _carregarMochila();
  }

  @override
  void didUpdateWidget(covariant CasaVigaristaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega mochila se a história mudou (ex: voltou de uma batalha)
    if (widget.historia != oldWidget.historia) {
      _historiaAtual = widget.historia;
      _carregarMochila();
    }
  }

  Future<void> _carregarMochila() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    final mochila = await MochilaService.carregarMochila(context, user.email!);
    if (mounted) {
      setState(() {
        _mochila = mochila;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1a1a2e),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildOptionsGrid(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
          if (_comprando) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFf4a261).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/npc/besta_Karma.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Casa do Vigarista',
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFf4a261),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Column(
      children: [
        // Row 1: Item + Cura + Magia
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Comprar Item',
                iconAsset: 'assets/icons_gerais/bau.png',
                cost: custoAposta,
                color: const Color(0xFF9d4edd),
                onTap: _apostarItem,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionCard(
                title: 'Comprar Cura',
                iconAsset: 'assets/icons_gerais/cura.png',
                cost: custoCura,
                color: const Color(0xFFe63946),
                onTap: _apostarCura,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionCard(
                title: 'Comprar Magia',
                iconAsset: 'assets/icons_gerais/magia.png',
                cost: custoAposta,
                color: const Color(0xFF457b9d),
                onTap: _apostarMagia,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Loja de Itens + Roleta + Loja de Magias
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Abrir Loja de Itens',
                iconAsset: 'assets/icons_gerais/bau.png',
                cost: custoFeirao,
                color: const Color(0xFFf4a261),
                onTap: _abrirFeirao,
                badge: 'x3',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionCard(
                title: 'Roleta de Sorteio',
                iconAsset: 'assets/icons_gerais/roleta.png',
                cost: custoRoleta,
                color: const Color(0xFFe76f51),
                onTap: _abrirRoleta,
                customCostIcon: 'assets/eventos/halloween/moeda_halloween.png',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOptionCard(
                title: 'Abrir Loja de Magias',
                iconAsset: 'assets/icons_gerais/magia.png',
                cost: custoFeirao,
                color: const Color(0xFF2a9d8f),
                onTap: _abrirBiblioteca,
                badge: 'x3',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String iconAsset,
    required int cost,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    String? customCostIcon, // Ícone customizado para o custo
  }) {
    // Se tem ícone customizado, verifica moeda de evento. Caso contrário, verifica score.
    final canAfford = customCostIcon != null
        ? (_mochila?.quantidadeMoedaEvento ?? 0) >= cost
        : _historiaAtual.score >= cost;

    return GestureDetector(
      onTap: canAfford && !_comprando ? onTap : null,
      child: AspectRatio(
        aspectRatio: 0.7, // Cards verticais (mais altos que largos)
        child: Container(
          decoration: BoxDecoration(
            color: (canAfford ? color : Colors.grey.shade800).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford ? color : Colors.grey.shade700,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Row 1: Nome (centralizado, multi-linha)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                width: double.infinity,
                child: Center(
                  child: Text(
                    title,
                    style: GoogleFonts.cinzel(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? Colors.white : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              // Row 2: Imagem (área maior) com badge
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Image.asset(
                          iconAsset,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          color: canAfford ? null : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    // Badge x3 no canto superior direito da imagem
                    if (badge != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (canAfford ? color : Colors.grey.shade900).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: canAfford ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade700,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 12,
                              color: canAfford ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Row 3: Valor
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (customCostIcon != null)
                      Image.asset(
                        customCostIcon,
                        width: 20,
                        height: 20,
                        color: canAfford ? null : Colors.grey.shade600,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.monetization_on,
                            color: canAfford ? Colors.amber : Colors.grey.shade600,
                            size: 18,
                          );
                        },
                      )
                    else
                      Icon(
                        Icons.monetization_on,
                        color: canAfford ? Colors.amber : Colors.grey.shade600,
                        size: 18,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      '$cost',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 16,
                        color: canAfford ? Colors.amber : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFf4a261).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Score: ',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                '${_historiaAtual.score}',
                style: GoogleFonts.pressStart2p(
                  fontSize: 16,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          Text(
            'Tier ${_historiaAtual.tier}',
            style: GoogleFonts.pressStart2p(
              fontSize: 14,
              color: const Color(0xFFf4a261),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFf4a261)),
              SizedBox(height: 16),
              Text(
                'Preparando compra...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MÉTODOS DE COMPRA ====================

  void _apostarItem() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    // 1. Mostra modal de confirmação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a3e),
        title: Text(
          'Confirmar Compra',
          style: GoogleFonts.cinzel(
            color: const Color(0xFFf4a261),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja comprar um Item Misterioso?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Custo: $custoAposta',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Você receberá um item aleatório baseado no seu tier atual.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf4a261),
              foregroundColor: Colors.black,
            ),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    // Se cancelou, retorna
    if (confirmacao != true) return;

    // Ativa loading
    setState(() => _comprando = true);

    try {
      // Aguarda um frame para garantir que o loading apareça
      await Future.delayed(const Duration(milliseconds: 100));

      print('🛒 [Loja] Comprando item...');

      // 2. Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      // 3. Gera item (simula processamento)
      await Future.delayed(const Duration(milliseconds: 800));
      final item = _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier);

      print('✅ [Loja] Item gerado: ${item.nome}');

      final resultado = ResultadoLoja(
        tipo: TipoResultado.item,
        item: item,
        historiaAtualizada: historiaAtualizada,
      );

      // 4. Retorna via callback (inline) ou Navigator.pop (modal)
      if (widget.onResultado != null) {
        // Está inline na tab, usa callback
        print('📤 [Loja] Usando callback (inline) - mantém loading');
        widget.onResultado!(resultado);

        // Aguarda mais tempo para garantir que o modal abra
        await Future.delayed(const Duration(milliseconds: 500));

        // Desliga loading após timeout de segurança (3s total)
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && _comprando) {
            print('⏰ [Loja] Timeout - desligando loading');
            setState(() => _comprando = false);
          }
        });
      } else {
        // Está como modal, usa Navigator.pop
        print('📤 [Loja] Usando Navigator.pop (modal)');
        if (mounted) {
          Navigator.of(context).pop(resultado);
        }
      }
    } catch (e) {
      print('❌ Erro ao apostar item: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  void _apostarMagia() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    // 1. Mostra modal de confirmação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a3e),
        title: Text(
          'Confirmar Compra',
          style: GoogleFonts.cinzel(
            color: Colors.purple.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja comprar uma Magia Ancestral?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Custo: $custoAposta',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Você receberá uma magia aleatória baseada no seu tier atual.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    // Se cancelou, retorna
    if (confirmacao != true) return;

    // Ativa loading
    setState(() => _comprando = true);

    try {
      // Aguarda um frame para garantir que o loading apareça
      await Future.delayed(const Duration(milliseconds: 100));

      print('🛒 [Loja] Comprando magia...');

      // Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      // Gera magia (simula processamento)
      await Future.delayed(const Duration(milliseconds: 800));
      final magia = _magiaService.gerarMagiaAleatoria(tierAtual: _historiaAtual.tier, isCompra: true);

      print('✅ [Loja] Magia gerada: ${magia.nome}');

      final resultado = ResultadoLoja(
        tipo: TipoResultado.magia,
        habilidade: magia,
        historiaAtualizada: historiaAtualizada,
      );

      // Retorna via callback (inline) ou Navigator.pop (modal)
      if (widget.onResultado != null) {
        // Está inline na tab, usa callback
        print('📤 [Loja] Usando callback (inline) - mantém loading');
        widget.onResultado!(resultado);

        // Aguarda mais tempo para garantir que o modal abra
        await Future.delayed(const Duration(milliseconds: 500));

        // Desliga loading após timeout de segurança (3s total)
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && _comprando) {
            print('⏰ [Loja] Timeout - desligando loading');
            setState(() => _comprando = false);
          }
        });
      } else {
        // Está como modal, usa Navigator.pop
        print('📤 [Loja] Usando Navigator.pop (modal)');
        if (mounted) {
          Navigator.of(context).pop(resultado);
        }
      }
    } catch (e) {
      print('❌ Erro ao apostar magia: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  void _apostarCura() async {
    if (_comprando || _historiaAtual.score < custoCura) return;

    // 1. Mostra modal de confirmação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a3e),
        title: Text(
          'Confirmar Compra',
          style: GoogleFonts.cinzel(
            color: const Color(0xFFe63946),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja comprar Cura da Vida?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Custo: $custoCura',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Você receberá uma porcentagem de cura baseada no seu tier.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe63946),
              foregroundColor: Colors.white,
            ),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    // Se cancelou, retorna
    if (confirmacao != true) return;

    // Ativa loading
    setState(() => _comprando = true);

    try {
      // Aguarda um frame para garantir que o loading apareça
      await Future.delayed(const Duration(milliseconds: 100));

      print('🛒 [Loja] Comprando cura...');

      // Sorteia porcentagem de cura aleatória (1-100%)
      final random = Random();
      final porcentagemCura = 1 + random.nextInt(100); // 1 a 100

      // Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoCura,
      );

      // Simula processamento
      await Future.delayed(const Duration(milliseconds: 800));

      print('✅ [Loja] Cura gerada: $porcentagemCura%');

      final resultado = ResultadoLoja(
        tipo: TipoResultado.cura,
        porcentagemCura: porcentagemCura,
        historiaAtualizada: historiaAtualizada,
      );

      // Retorna via callback (inline) ou Navigator.pop (modal)
      if (widget.onResultado != null) {
        // Está inline na tab, usa callback
        print('📤 [Loja] Usando callback (inline) - mantém loading');
        widget.onResultado!(resultado);

        // Aguarda mais tempo para garantir que o modal abra
        await Future.delayed(const Duration(milliseconds: 500));

        // Desliga loading após timeout de segurança (3s total)
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && _comprando) {
            print('⏰ [Loja] Timeout - desligando loading');
            setState(() => _comprando = false);
          }
        });
      } else {
        // Está como modal, usa Navigator.pop
        print('📤 [Loja] Usando Navigator.pop (modal)');
        if (mounted) {
          Navigator.of(context).pop(resultado);
        }
      }
    } catch (e) {
      print('❌ Erro ao apostar cura: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  void _abrirFeirao() async {
    if (_comprando || _historiaAtual.score < custoFeirao) return;

    // 1. Mostra modal de confirmação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a3e),
        title: Text(
          'Confirmar Compra',
          style: GoogleFonts.cinzel(
            color: const Color(0xFFf4a261),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja abrir o Feirão?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Custo: $custoFeirao',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Você poderá escolher e comprar 1 entre 3 itens aleatórios.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf4a261),
              foregroundColor: Colors.black,
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    // Se cancelou, retorna
    if (confirmacao != true) return;

    setState(() => _comprando = true);

    try {
      print('🏪 [Loja] Gerando 3 itens para o Feirão...');

      // Aguarda um frame para garantir que o loading apareça
      await Future.delayed(const Duration(milliseconds: 100));

      final itens = List.generate(
        3,
        (_) => _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier),
      );

      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoFeirao,
      );

      final resultado = ResultadoLoja(
        tipo: TipoResultado.abrirFeirao,
        itensFeirao: itens,
        historiaAtualizada: historiaAtualizada,
      );

      // Retorna via callback (inline) ou Navigator.pop (modal)
      if (widget.onResultado != null) {
        // Está inline na tab, usa callback
        print('📤 [Loja] Feirão inline - usando callback');
        widget.onResultado!(resultado);

        // Timeout de segurança
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted && _comprando) {
            print('⏰ [Loja] Timeout Feirão - desligando loading');
            setState(() => _comprando = false);
          }
        });
      } else {
        // Está como modal, usa Navigator.pop
        print('📤 [Loja] Feirão modal - usando Navigator.pop');
        if (mounted) {
          Navigator.of(context).pop(resultado);
        }
      }
    } catch (e) {
      print('❌ Erro ao abrir feirão: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  void _abrirBiblioteca() async {
    if (_comprando || _historiaAtual.score < custoFeirao) return;

    // 1. Mostra modal de confirmação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a3e),
        title: Text(
          'Confirmar Compra',
          style: GoogleFonts.cinzel(
            color: const Color(0xFF2a9d8f),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja abrir a Biblioteca?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Custo: $custoFeirao',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Você poderá escolher e comprar 1 entre 3 magias aleatórias.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2a9d8f),
              foregroundColor: Colors.white,
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    // Se cancelou, retorna
    if (confirmacao != true) return;

    setState(() => _comprando = true);

    try {
      print('📚 [Loja] Gerando 3 magias para a Biblioteca...');

      // Aguarda um frame para garantir que o loading apareça
      await Future.delayed(const Duration(milliseconds: 100));

      final magias = List.generate(
        3,
        (_) => _magiaService.gerarMagiaAleatoria(tierAtual: _historiaAtual.tier, isCompra: true),
      );

      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoFeirao,
      );

      final resultado = ResultadoLoja(
        tipo: TipoResultado.abrirBiblioteca,
        magiasBiblioteca: magias,
        historiaAtualizada: historiaAtualizada,
      );

      // Retorna via callback (inline) ou Navigator.pop (modal)
      if (widget.onResultado != null) {
        // Está inline na tab, usa callback
        print('📤 [Loja] Biblioteca inline - usando callback');
        widget.onResultado!(resultado);

        // Timeout de segurança
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted && _comprando) {
            print('⏰ [Loja] Timeout Biblioteca - desligando loading');
            setState(() => _comprando = false);
          }
        });
      } else {
        // Está como modal, usa Navigator.pop
        print('📤 [Loja] Biblioteca modal - usando Navigator.pop');
        if (mounted) {
          Navigator.of(context).pop(resultado);
        }
      }
    } catch (e) {
      print('❌ Erro ao abrir biblioteca: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  /// Abre a roleta de Halloween com cartas
  Future<void> _abrirRoleta() async {
    print('🎰 [Roleta] Iniciando roleta de sorteio...');

    // Verifica se tem moeda de evento
    final temMoedas = (_mochila?.quantidadeMoedaEvento ?? 0) >= custoRoleta;
    if (!temMoedas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem moedas de evento suficientes!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Modal de confirmação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/icons_gerais/roleta.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'Roleta de Sorteio',
              style: TextStyle(color: Color(0xFFe76f51)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deseja girar a roleta?',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Image.asset(
                  'assets/eventos/halloween/moeda_halloween.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.stars, color: Color(0xFFFF9800), size: 20);
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Custo: $custoRoleta Moeda de Evento',
                  style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A roleta sorteará 3 monstros de Halloween!\nDepois você escolhe 1 carta.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe76f51),
              foregroundColor: Colors.white,
            ),
            child: const Text('Girar'),
          ),
        ],
      ),
    );

    // Se cancelou, retorna
    if (confirmacao != true) return;

    setState(() => _comprando = true);

    try {
      print('🎰 [Roleta] Debitando moeda de evento...');

      // Debita moeda de evento da mochila
      final user = ref.read(currentUserProvider);
      if (user == null || user.email == null || _mochila == null) {
        print('❌ [Roleta] Erro: usuário ou mochila não encontrado');
        setState(() => _comprando = false);
        return;
      }

      final mochilaAtualizada = _mochila!.removerMoedaEvento(custoRoleta);
      if (mochilaAtualizada == null) {
        print('❌ [Roleta] Erro: não foi possível remover moeda de evento');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao processar pagamento!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _comprando = false);
        return;
      }

      // Salva mochila atualizada
      await MochilaService.salvarMochila(context, user.email!, mochilaAtualizada);
      setState(() {
        _mochila = mochilaAtualizada;
      });

      print('✅ [Roleta] Moeda debitada. Navegando para roleta de Halloween...');

      // Desliga loading enquanto a roleta roda
      setState(() => _comprando = false);

      // Navega para tela de roleta de Halloween
      final monstroRetornado = await Navigator.of(context).push<MonstroAventura>(
        MaterialPageRoute(
          builder: (context) => const RoletaHalloweenScreen(),
        ),
      );

      // Se retornou um monstro, adiciona à equipe
      if (monstroRetornado != null && mounted) {
        print('🎰 [Roleta] Monstro escolhido: ${monstroRetornado.tipo.monsterName}');
        print('🎰 [Roleta] Adicionando monstro à equipe...');

        // Adiciona monstro à lista de monstros
        final monstrosAtualizados = [..._historiaAtual.monstros, monstroRetornado];

        final resultado = ResultadoLoja(
          tipo: TipoResultado.roleta,
          historiaAtualizada: _historiaAtual.copyWith(
            monstros: monstrosAtualizados,
            score: _historiaAtual.score - custoRoleta, // 0
          ),
        );

        // Atualiza estado local
        setState(() {
          _historiaAtual = resultado.historiaAtualizada;
        });

        // Se tem callback (inline), chama ele
        if (widget.onResultado != null) {
          print('🔄 [Roleta] Usando callback inline');
          widget.onResultado!(resultado);
        } else {
          // Está como modal, usa Navigator.pop
          print('📤 [Roleta] Modal - usando Navigator.pop');
          if (mounted) {
            Navigator.of(context).pop(resultado);
          }
        }
      } else {
        print('🎰 [Roleta] Usuário cancelou ou não retornou monstro');
      }
    } catch (e) {
      print('❌ Erro ao abrir roleta: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }
}
