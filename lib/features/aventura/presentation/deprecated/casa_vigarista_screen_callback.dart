import 'package:flutter/material.dart';
import '../models/historia_jogador.dart';
import '../services/item_service.dart';
import '../services/magia_service.dart';
import 'models/resultado_loja.dart';
import 'package:google_fonts/google_fonts.dart';

/// Casa do Vigarista - Loja de itens, magias e curas
/// Dialog fullscreen com callbacks
class CasaVigaristaScreen extends StatefulWidget {
  final HistoriaJogador historia;
  final Function(ResultadoLoja) onCompraRealizada;

  const CasaVigaristaScreen({
    super.key,
    required this.historia,
    required this.onCompraRealizada,
  });

  @override
  State<CasaVigaristaScreen> createState() => _CasaVigaristaScreenState();
}

class _CasaVigaristaScreenState extends State<CasaVigaristaScreen> {
  final ItemService _itemService = ItemService();
  final MagiaService _magiaService = MagiaService();
  late HistoriaJogador _historiaAtual;
  bool _comprando = false;

  // Custos dinâmicos
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
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF1a1a2e),
      child: Stack(
        children: [
          // Fundo gradiente simples
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                ],
              ),
            ),
          ),

          // Conteúdo
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Imagem do Vigarista
                        _buildVigaristaSection(),
                        const SizedBox(height: 32),

                        // Texto de boas-vindas
                        _buildWelcomeText(),
                        const SizedBox(height: 32),

                        // Opções de compra
                        _buildOptionsGrid(),
                      ],
                    ),
                  ),
                ),

                // Footer com score
                _buildFooter(),
              ],
            ),
          ),

          // Loading overlay
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
            onPressed: _comprando ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: Colors.white70,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildVigaristaSection() {
    return Column(
      children: [
        // Imagem do rato vigarista
        Container(
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
        ),
      ],
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
        Text(
          'Tenho ofertas especiais para você...',
          style: const TextStyle(
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
        // Linha 1: Item e Magia
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Item Misterioso',
                icon: Icons.inventory_2,
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
                icon: Icons.auto_fix_high,
                iconAsset: 'assets/icons_gerais/magia.png',
                cost: custoAposta,
                color: const Color(0xFF457b9d),
                onTap: _apostarMagia,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Linha 2: Cura
        _buildOptionCard(
          title: 'Cura da Vida',
          icon: Icons.favorite,
          iconAsset: 'assets/icons_gerais/cura.png',
          cost: custoCura,
          color: const Color(0xFFe63946),
          onTap: _apostarCura,
          fullWidth: true,
        ),
        const SizedBox(height: 16),

        // Linha 3: Feirão e Biblioteca
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Feirão',
                icon: Icons.shopping_cart,
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
                icon: Icons.menu_book,
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
    required IconData icon,
    required int cost,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
    String? badge,
    String? iconAsset,
  }) {
    final canAfford = _historiaAtual.score >= cost;
    final cardColor = canAfford ? color : Colors.grey.shade800;

    return GestureDetector(
      onTap: canAfford && !_comprando ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canAfford ? color : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Ícone (asset ou IconData)
            if (iconAsset != null)
              Image.asset(
                iconAsset,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                color: canAfford ? null : Colors.grey.shade600,
              )
            else
              Icon(
                icon,
                color: canAfford ? color : Colors.grey.shade600,
                size: 48,
              ),
            const SizedBox(height: 12),

            // Título
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

            // Badge (se tiver)
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: canAfford ? color.withValues(alpha: 0.3) : Colors.grey.shade900,
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

            // Custo
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
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
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFf4a261),
            ),
            SizedBox(height: 16),
            Text(
              'Preparando compra...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MÉTODOS DE COMPRA ====================

  void _apostarItem() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    setState(() => _comprando = true);

    try {
      print('🛒 [Loja] Iniciando compra de item...');

      // 1. Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      print('💰 [Loja] Score debitado: ${_historiaAtual.score} -> ${historiaAtualizada.score}');

      // 2. Gera item
      final item = _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier);

      print('✅ [Loja] Item gerado: ${item.nome}');

      // 3. Chama callback
      final resultado = ResultadoLoja(
        tipo: TipoResultado.item,
        item: item,
        historiaAtualizada: historiaAtualizada,
      );

      print('📤 [Loja] Enviando resultado via callback...');

      widget.onCompraRealizada(resultado);

      print('🚪 [Loja] Fechando loja...');

      // 4. Fecha a loja
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      print('❌ Erro ao apostar item: $e');
      print('Stack: $stack');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  void _apostarMagia() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    setState(() => _comprando = true);

    try {
      // 1. Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      // 2. Gera magia
      final magia = _magiaService.gerarMagiaAleatoria(tierAtual: _historiaAtual.tier);

      // 3. Chama callback
      widget.onCompraRealizada(ResultadoLoja(
        tipo: TipoResultado.magia,
        habilidade: magia,
        historiaAtualizada: historiaAtualizada,
      ));

      // 4. Fecha a loja
      if (mounted) {
        Navigator.of(context).pop();
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
      // 1. Calcula porcentagem de cura baseada no tier
      final porcentagemCura = 30 + (_historiaAtual.tier * 5); // 35%, 40%, 45%...

      // 2. Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoCura,
      );

      // 3. Chama callback
      widget.onCompraRealizada(ResultadoLoja(
        tipo: TipoResultado.cura,
        porcentagemCura: porcentagemCura,
        historiaAtualizada: historiaAtualizada,
      ));

      // 4. Fecha a loja
      if (mounted) {
        Navigator.of(context).pop();
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
      // 1. Gera 3 itens
      final itens = List.generate(
        3,
        (_) => _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier),
      );

      // 2. Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoFeirao,
      );

      // 3. Chama callback
      widget.onCompraRealizada(ResultadoLoja(
        tipo: TipoResultado.abrirFeirao,
        itensFeirao: itens,
        historiaAtualizada: historiaAtualizada,
      ));

      // 4. Fecha a loja
      if (mounted) {
        Navigator.of(context).pop();
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
      // 1. Gera 3 magias
      final magias = List.generate(
        3,
        (_) => _magiaService.gerarMagiaAleatoria(tierAtual: _historiaAtual.tier),
      );

      // 2. Debita score
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoFeirao,
      );

      // 3. Chama callback
      widget.onCompraRealizada(ResultadoLoja(
        tipo: TipoResultado.abrirBiblioteca,
        magiasBiblioteca: magias,
        historiaAtualizada: historiaAtualizada,
      ));

      // 4. Fecha a loja
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Erro ao abrir biblioteca: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }
}
