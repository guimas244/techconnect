import 'package:flutter/material.dart';
import '../models/historia_jogador.dart';
import '../services/item_service.dart';
import '../services/magia_service.dart';
import 'models/resultado_loja.dart';
import 'package:google_fonts/google_fonts.dart';

/// Casa do Vigarista - Nova implementação seguindo REESTRUTURACAO_LOJA.md
/// Retorna ResultadoLoja via Navigator.pop() ou callback se inline
class CasaVigaristaScreen extends StatefulWidget {
  final HistoriaJogador historia;
  final Function(ResultadoLoja)? onResultado; // Callback para quando está inline na tab

  const CasaVigaristaScreen({
    super.key,
    required this.historia,
    this.onResultado,
  });

  @override
  State<CasaVigaristaScreen> createState() => _CasaVigaristaScreenState();
}

class _CasaVigaristaScreenState extends State<CasaVigaristaScreen> {
  final ItemService _itemService = ItemService();
  final MagiaService _magiaService = MagiaService();
  late HistoriaJogador _historiaAtual;
  bool _comprando = false;

  // Custos dinâmicos baseados no tier
  int get custoAposta => 2 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
  int get custoCura => 1 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
  int get custoFeirao => ((_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier) * 1.5).ceil();

  @override
  void initState() {
    super.initState();
    _historiaAtual = widget.historia;
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
                        _buildVigaristaSection(),
                        const SizedBox(height: 32),
                        _buildWelcomeText(),
                        const SizedBox(height: 32),
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
          const Icon(
            Icons.store,
            color: Color(0xFFf4a261),
            size: 28,
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
          IconButton(
            onPressed: _comprando
                ? null
                : () => Navigator.of(context).pop(ResultadoLoja(
                      tipo: TipoResultado.nenhum,
                      historiaAtualizada: _historiaAtual,
                    )),
            icon: const Icon(Icons.close),
            color: Colors.white70,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildVigaristaSection() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a3e),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFf4a261),
          width: 3,
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/npc/besta_Karma.png',
          width: 110,
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Olá, aventureiro!',
          style: GoogleFonts.cinzel(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Tenho ofertas especiais para você...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOptionsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Item Misterioso',
                iconAsset: 'assets/icons_gerais/bau.png',
                cost: custoAposta,
                color: const Color(0xFF9d4edd),
                onTap: _apostarItem,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOptionCard(
                title: 'Magia Ancestral',
                iconAsset: 'assets/icons_gerais/magia.png',
                cost: custoAposta,
                color: const Color(0xFF457b9d),
                onTap: _apostarMagia,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          title: 'Cura da Vida',
          iconAsset: 'assets/icons_gerais/cura.png',
          cost: custoCura,
          color: const Color(0xFFe63946),
          onTap: _apostarCura,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Feirão',
                iconAsset: 'assets/icons_gerais/bau.png',
                cost: custoFeirao,
                color: const Color(0xFFf4a261),
                onTap: _abrirFeirao,
                badge: '3 itens',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOptionCard(
                title: 'Biblioteca',
                iconAsset: 'assets/icons_gerais/magia.png',
                cost: custoFeirao,
                color: const Color(0xFF2a9d8f),
                onTap: _abrirBiblioteca,
                badge: '3 magias',
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
    bool fullWidth = false,
    String? badge,
  }) {
    final canAfford = _historiaAtual.score >= cost;

    return GestureDetector(
      onTap: canAfford && !_comprando ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: (canAfford ? color : Colors.grey.shade800).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canAfford ? color : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Image.asset(
              iconAsset,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              color: canAfford ? null : Colors.grey.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: canAfford ? Colors.white : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (canAfford ? color : Colors.grey.shade900).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    color: canAfford ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: canAfford ? Colors.amber : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '$cost',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: canAfford ? Colors.amber : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seu Score',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                '${_historiaAtual.score}',
                style: GoogleFonts.pressStart2p(
                  fontSize: 20,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          Text(
            'Tier ${_historiaAtual.tier}',
            style: GoogleFonts.pressStart2p(
              fontSize: 16,
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

    setState(() => _comprando = true);

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      final magia = _magiaService.gerarMagiaAleatoria(tierAtual: _historiaAtual.tier);

      if (mounted) {
        Navigator.of(context).pop(ResultadoLoja(
          tipo: TipoResultado.magia,
          habilidade: magia,
          historiaAtualizada: historiaAtualizada,
        ));
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

    setState(() => _comprando = true);

    try {
      final porcentagemCura = 30 + (_historiaAtual.tier * 5);

      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoCura,
      );

      if (mounted) {
        Navigator.of(context).pop(ResultadoLoja(
          tipo: TipoResultado.cura,
          porcentagemCura: porcentagemCura,
          historiaAtualizada: historiaAtualizada,
        ));
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

    setState(() => _comprando = true);

    try {
      print('🏪 [Loja] Gerando 3 itens para o Feirão...');

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

    setState(() => _comprando = true);

    try {
      print('📚 [Loja] Gerando 3 magias para a Biblioteca...');

      final magias = List.generate(
        3,
        (_) => _magiaService.gerarMagiaAleatoria(tierAtual: _historiaAtual.tier),
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
}
