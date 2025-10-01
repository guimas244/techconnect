import 'package:flutter/material.dart';
import 'dart:math';
import '../models/historia_jogador.dart';
import '../models/item.dart';
import '../models/habilidade.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../services/item_service.dart';
import '../utils/gerador_habilidades.dart';
import 'modal_item_obtido.dart';
import 'modal_magia_obtida.dart';
import 'modal_cura_obtida.dart';
import '../models/magia_drop.dart';
// Bibliotecas para UI Avançada
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CasaVigaristaModalV2 extends StatefulWidget {
  final HistoriaJogador historia;
  final Function(HistoriaJogador historiaAtualizada) onHistoriaAtualizada;

  const CasaVigaristaModalV2({
    super.key,
    required this.historia,
    required this.onHistoriaAtualizada,
  });

  @override
  State<CasaVigaristaModalV2> createState() => _CasaVigaristaModalV2State();
}

class _CasaVigaristaModalV2State extends State<CasaVigaristaModalV2>
    with TickerProviderStateMixin {
  final ItemService _itemService = ItemService();
  int get custoAposta => 2 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
  int get custoCura => 1 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
  int get custoFeirao => ((_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier) * 1.5).ceil();
  bool _comprando = false;
  late HistoriaJogador _historiaAtual;

  late AnimationController _particleController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _historiaAtual = widget.historia;
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CasaVigaristaModalV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza o score quando a história é atualizada
    if (oldWidget.historia.score != widget.historia.score) {
      setState(() {
        _historiaAtual = widget.historia;
      });
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Stack(
          children: [
            // Fundo com efeito glassmorphism
            GlassmorphicContainer(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 25,
              blur: 20,
              alignment: Alignment.bottomCenter,
              border: 3,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E2E2E).withOpacity(0.8),
                  const Color(0xFF3A3A3A).withOpacity(0.9),
                  const Color(0xFF4A4A4A).withOpacity(0.8),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B6B6B).withOpacity(0.8),
                  const Color(0xFF8B8B8B).withOpacity(0.6),
                  const Color(0xFF6B6B6B).withOpacity(0.8),
                ],
              ),
            ),
            // Partículas flutuantes animadas
            ...List.generate(15, (index) => _buildFloatingParticle(index)),
            // Conteúdo principal
            _buildMainContent(context),
          ],
        ),
      ).animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header da loja com animação
            _buildAnimatedHeader(),
            const SizedBox(height: 15),

            // Vendedor com efeitos
            _buildEnhancedVendedor(),
            const SizedBox(height: 15),

            // Opções da loja em carousel
            Expanded(
              child: SingleChildScrollView(
                child: _buildShopCarousel(),
              ),
            ),

            const SizedBox(height: 15),
            // Footer com stats
            _buildEnhancedFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = Random(index);
    final size = 3.0 + random.nextDouble() * 4;
    final left = random.nextDouble() * 300;
    final duration = 3000 + random.nextInt(2000);

    return Positioned(
      left: left,
      top: 50 + random.nextDouble() * 400,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
            const Color(0xFF8B8B8B),
            const Color(0xFF6B6B6B),
            random.nextDouble(),
          )!.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B6B6B).withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      )
        .animate(onPlay: (controller) => controller.repeat())
        .moveY(
          begin: 0,
          end: -50,
          duration: Duration(milliseconds: duration),
          curve: Curves.easeInOut,
        )
        .fade(
          begin: 0.3,
          end: 0.8,
          duration: Duration(milliseconds: duration ~/ 2),
        )
        .then()
        .fade(
          begin: 0.8,
          end: 0.2,
          duration: Duration(milliseconds: duration ~/ 2),
        ),
    );
  }

  Widget _buildAnimatedHeader() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 80,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          const Color(0xFF6B6B6B).withOpacity(0.3),
          const Color(0xFF8B8B8B).withOpacity(0.2),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFF6B6B6B),
          const Color(0xFF8B8B8B),
        ],
      ),
      child: Stack(
        children: [
          // Efeito de brilho animado
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
          ),
          // Conteúdo do header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ícone da loja com animação
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6B6B6B),
                        const Color(0xFF0F3460),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B6B6B).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 4000.ms)
                  .then()
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                    duration: 1000.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(1.0, 1.0),
                    duration: 1000.ms,
                  ),

                const SizedBox(width: 15),

                // Título com animação de texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'LOJA MÍSTICA',
                            textStyle: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 8,
                                  color: Color(0xFFE94560),
                                ),
                              ],
                            ),
                            speed: const Duration(milliseconds: 100),
                          ),
                        ],
                        isRepeatingAnimation: false,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Casa do Vigarista Arcano',
                        style: GoogleFonts.cinzel(
                          fontSize: 10,
                          color: const Color(0xFF8B8B8B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão de fechar removido - a loja agora é uma aba
                const SizedBox(width: 30), // Espaço para manter o layout simétrico
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .slideY(begin: -1, duration: 800.ms, curve: Curves.elasticOut)
      .fadeIn(duration: 600.ms);
  }

  Widget _buildEnhancedVendedor() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 20,
      blur: 10,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          const Color(0xFF16213E).withOpacity(0.4),
          const Color(0xFF0F3460).withOpacity(0.6),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFF8B8B8B).withOpacity(0.8),
          const Color(0xFF6B6B6B).withOpacity(0.6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar do vendedor com efeitos
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6B6B6B),
                    const Color(0xFF0F3460),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B6B6B).withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Anel de energia
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B8B8B),
                          width: 2,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                        duration: 2000.ms,
                      )
                      .fade(begin: 0.8, end: 0.2),
                  ),
                  // Imagem do vendedor
                  Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/npc/besta_Karma.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate()
              .scale(delay: 300.ms, duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(width: 16),

            // Informações do vendedor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Nome com shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: const Color(0xFF8B8B8B),
                    child: AutoSizeText(
                      'MERCADOR ARCANO',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Descrição misteriosa
                  Flexible(
                    child: AutoSizeText(
                      'Segredos ancestrais aguardam...',
                      style: GoogleFonts.philosopher(
                        fontSize: 12,
                        color: const Color(0xFF8B8B8B),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Preços com efeito neon
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6B6B6B).withOpacity(0.3),
                            const Color(0xFF0F3460).withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF8B8B8B),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B6B6B).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: const Color(0xFF8B8B8B),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: AutoSizeText(
                              'Básico: $custoAposta • Feirão: $custoFeirao',
                              style: GoogleFonts.orbitron(
                                fontSize: 10,
                                color: const Color(0xFF8B8B8B),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              minFontSize: 8,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .slideX(delay: 800.ms, duration: 400.ms)
                    .fadeIn(),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .slideX(begin: 1, delay: 400.ms, duration: 800.ms, curve: Curves.elasticOut)
      .fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildShopCarousel() {
    return AnimationLimiter(
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          // Item Aleatório
          AnimationConfiguration.staggeredGrid(
            position: 0,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildMagicalShopItem(
                  title: 'ITEM',
                  subtitle: 'Misterioso',
                  icon: 'assets/icons_gerais/bau.png',
                  colors: [Color(0xFF4169E1), Color(0xFF1E90FF)],
                  onTap: () => _mostrarConfirmacao('Item', _apostarItem),
                ),
              ),
            ),
          ),

          // Magia Aleatória
          AnimationConfiguration.staggeredGrid(
            position: 1,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildMagicalShopItem(
                  title: 'MAGIA',
                  subtitle: 'Ancestral',
                  icon: 'assets/icons_gerais/magia.png',
                  colors: [Color(0xFF9932CC), Color(0xFF8A2BE2)],
                  onTap: () => _mostrarConfirmacao('Magia', _apostarMagia),
                ),
              ),
            ),
          ),

          // Cura Aleatória
          AnimationConfiguration.staggeredGrid(
            position: 2,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildMagicalShopItem(
                  title: 'CURA',
                  subtitle: 'da Vida',
                  icon: 'assets/icons_gerais/cura.png',
                  colors: [Color(0xFF228B22), Color(0xFF32CD32)],
                  onTap: () => _mostrarConfirmacao('Cura', _apostarCura),
                ),
              ),
            ),
          ),

          // Feirão
          AnimationConfiguration.staggeredGrid(
            position: 3,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildMagicalShopItem(
                  title: 'BOLSO',
                  subtitle: 'Vigarista',
                  icon: Icons.store,
                  colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                  onTap: () => _mostrarConfirmacaoFeirao(),
                  isIcon: true,
                ),
              ),
            ),
          ),

          // Biblioteca do Vigarista (novo)
          AnimationConfiguration.staggeredGrid(
            position: 4,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildMagicalShopItem(
                  title: 'BIBLIOTECA',
                  subtitle: 'do Vigarista',
                  icon: Icons.library_books,
                  colors: [Color(0xFF6A0DAD), Color(0xFF8B008B)],
                  onTap: () => _mostrarConfirmacaoBiblioteca(),
                  isIcon: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicalShopItem({
    required String title,
    required String subtitle,
    required dynamic icon,
    required List<Color> colors,
    required VoidCallback onTap,
    bool isIcon = false,
  }) {
    bool podeComprar = _historiaAtual.score >= custoAposta && !_comprando;

    // Para a cura, verifica custo especial
    if (title == 'CURA') {
      podeComprar = _historiaAtual.score >= custoCura && !_comprando;
    }
    // Para o feirão, verifica custo especial
    else if (isIcon && icon == Icons.store) {
      podeComprar = _historiaAtual.score >= custoFeirao && !_comprando;
    }

    return GestureDetector(
      onTap: podeComprar ? onTap : null,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 20,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: podeComprar
              ? [
                  colors[0].withOpacity(0.3),
                  colors[1].withOpacity(0.2),
                ]
              : [
                  Colors.grey.withOpacity(0.2),
                  Colors.grey.withOpacity(0.1),
                ],
        ),
        borderGradient: LinearGradient(
          colors: podeComprar
              ? [
                  colors[0].withOpacity(0.8),
                  colors[1].withOpacity(0.6),
                ]
              : [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.3),
                ],
        ),
        child: Stack(
          children: [
            // Efeito de pulso
            if (podeComprar)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      colors: [
                        colors[0].withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 2000.ms,
                  )
                  .fade(begin: 0.5, end: 0.0),
              ),

            // Conteúdo principal
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone central
                  Flexible(
                    flex: 2,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: podeComprar
                            ? LinearGradient(
                                colors: [
                                  colors[0].withOpacity(0.8),
                                  colors[1].withOpacity(0.6),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade600,
                                  Colors.grey.shade400,
                                ],
                              ),
                        boxShadow: podeComprar
                            ? [
                                BoxShadow(
                                  color: colors[0].withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isIcon
                          ? Icon(
                              icon,
                              color: Colors.white,
                              size: 24,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                icon,
                                fit: BoxFit.contain,
                                // Remover filtro de cor para mostrar ícones originais
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Texto com efeito shimmer
                  Flexible(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (podeComprar)
                          Shimmer.fromColors(
                            baseColor: Colors.white,
                            highlightColor: colors[0],
                            child: AutoSizeText(
                              title,
                              style: GoogleFonts.cinzel(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              minFontSize: 10,
                            ),
                          )
                        else
                          AutoSizeText(
                            title,
                            style: GoogleFonts.cinzel(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            minFontSize: 10,
                          ),
                        const SizedBox(height: 2),
                        AutoSizeText(
                          subtitle,
                          style: GoogleFonts.philosopher(
                            fontSize: 10,
                            color: podeComprar ? colors[0] : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Overlay de bloqueio
            if (!podeComprar)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFooter() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 70,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          const Color(0xFF16213E).withOpacity(0.4),
          const Color(0xFF0F3460).withOpacity(0.6),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFF6B6B6B).withOpacity(0.6),
          const Color(0xFF8B8B8B).withOpacity(0.4),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Score atual
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B6B6B).withOpacity(0.3),
                      const Color(0xFF0F3460).withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B8B8B),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.diamond,
                      color: const Color(0xFF8B8B8B),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AutoSizeText(
                        '${_historiaAtual.score} OURO',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B8B8B),
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Tier atual
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F3460).withOpacity(0.5),
                      const Color(0xFF6B6B6B).withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6B6B6B),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: const Color(0xFF6B6B6B),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AutoSizeText(
                        'NÍVEL ${widget.historia.tier}',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B6B6B),
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .slideY(begin: 1, delay: 1000.ms, duration: 600.ms, curve: Curves.elasticOut)
      .fadeIn(delay: 1000.ms, duration: 400.ms);
  }

  // Métodos de confirmação e funcionalidades (mantidos iguais ao arquivo original)
  void _mostrarConfirmacao(String tipoAposta, VoidCallback onConfirm) {
    // Determina o custo baseado no tipo de aposta
    int custo = custoAposta;
    if (tipoAposta == 'Cura') {
      custo = custoCura;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphicContainer(
            width: 350,
            height: 400,
            borderRadius: 25,
            blur: 20,
            alignment: Alignment.center,
            border: 3,
            linearGradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.9),
                const Color(0xFF16213E).withOpacity(0.9),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFF6B6B6B),
                const Color(0xFF8B8B8B),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone de confirmação
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6B6B6B),
                          const Color(0xFF0F3460),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B6B6B).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ).animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 25),

                  // Título
                  Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: const Color(0xFF8B8B8B),
                    child: AutoSizeText(
                      'CONFIRMAR NEGÓCIO',
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Descrição
                  AutoSizeText(
                    'Investir $custo moedas de ouro\\nem "$tipoAposta"?',
                    style: GoogleFonts.philosopher(
                      fontSize: 16,
                      color: const Color(0xFF8B8B8B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 30),

                  // Botões
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancelar
                      Flexible(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade700,
                                  Colors.grey.shade500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Center(
                              child: AutoSizeText(
                                'CANCELAR',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Confirmar
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            onConfirm();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6B6B6B),
                                  const Color(0xFF8B8B8B),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: const Color(0xFF6B6B6B)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6B6B6B).withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: AutoSizeText(
                                'CONFIRMAR',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate()
          .scale(duration: 400.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 300.ms);
      },
    );
  }

  void _mostrarConfirmacaoBiblioteca() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphicContainer(
            width: 350,
            height: 480,
            borderRadius: 25,
            blur: 20,
            alignment: Alignment.center,
            border: 3,
            linearGradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.9),
                const Color(0xFF16213E).withOpacity(0.9),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFF6A0DAD),
                const Color(0xFF8B008B),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone especial da biblioteca
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6A0DAD),
                          const Color(0xFF8B008B),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A0DAD).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.library_books,
                      color: Colors.white,
                      size: 40,
                    ),
                  ).animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .then()
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 3000.ms),

                  const SizedBox(height: 25),

                  // Título da biblioteca
                  Shimmer.fromColors(
                    baseColor: const Color(0xFF8B008B),
                    highlightColor: Colors.white,
                    child: AutoSizeText(
                      'BIBLIOTECA DO VIGARISTA',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B008B),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      minFontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Descrição da biblioteca
                  AutoSizeText(
                    'Se você deseja brincar com a sorte pague $custoFeirao e tenha acesso a 3 magias únicas',
                    style: GoogleFonts.philosopher(
                      fontSize: 14,
                      color: const Color(0xFF8B008B),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    minFontSize: 10,
                  ),

                  const SizedBox(height: 20),

                  AutoSizeText(
                    'Cada magia custará $custoAposta moedas',
                    style: GoogleFonts.philosopher(
                      fontSize: 12,
                      color: const Color(0xFF8B8B8B),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 25),

                  // Botões
                  Row(
                    children: [
                      // Cancelar
                      Flexible(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade700,
                                  Colors.grey.shade500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: AutoSizeText(
                                'CANCELAR',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Abrir Biblioteca
                      Flexible(
                        child: GestureDetector(
                          onTap: _historiaAtual.score >= custoFeirao ? () {
                            Navigator.of(context).pop();
                            _abrirBiblioteca();
                          } : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _historiaAtual.score >= custoFeirao
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF6A0DAD),
                                        const Color(0xFF8B008B),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade600,
                                        Colors.grey.shade400,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: _historiaAtual.score >= custoFeirao
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF6A0DAD).withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: AutoSizeText(
                                'ABRIR',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate()
          .scale(duration: 400.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 300.ms);
      },
    );
  }

  void _mostrarConfirmacaoFeirao() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphicContainer(
            width: 350,
            height: 450,
            borderRadius: 25,
            blur: 20,
            alignment: Alignment.center,
            border: 3,
            linearGradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.9),
                const Color(0xFF16213E).withOpacity(0.9),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFFFF8C00),
                const Color(0xFFFFD700),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone especial do feirão
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF8C00),
                          const Color(0xFFFFD700),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 40,
                    ),
                  ).animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .then()
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 3000.ms),

                  const SizedBox(height: 25),

                  // Título do feirão
                  Shimmer.fromColors(
                    baseColor: const Color(0xFFFFD700),
                    highlightColor: Colors.white,
                    child: AutoSizeText(
                      'BOLSO DO VIGARISTA',
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Descrição do feirão
                  AutoSizeText(
                    'Se você deseja brincar com a sorte pague $custoFeirao e tenha acesso a 3 itens únicos',
                    style: GoogleFonts.philosopher(
                      fontSize: 14,
                      color: const Color(0xFFFFD700),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    minFontSize: 10,
                  ),

                  const SizedBox(height: 15),

                  AutoSizeText(
                    'Cada item custará apenas $custoAposta moedas',
                    style: GoogleFonts.philosopher(
                      fontSize: 14,
                      color: const Color(0xFF8B8B8B),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 30),

                  // Botões
                  Row(
                    children: [
                      // Cancelar
                      Flexible(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade700,
                                  Colors.grey.shade500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: AutoSizeText(
                                'CANCELAR',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Abrir Bolso
                      Flexible(
                        child: GestureDetector(
                          onTap: _historiaAtual.score >= custoFeirao ? () {
                            Navigator.of(context).pop();
                            _abrirFeirao();
                          } : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: _historiaAtual.score >= custoFeirao
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFFFF8C00),
                                      const Color(0xFFFFD700),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade600,
                                      Colors.grey.shade400,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: _historiaAtual.score >= custoFeirao
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                            child: Center(
                              child: AutoSizeText(
                                'ABRIR BOLSO',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate()
          .scale(duration: 400.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 300.ms);
      },
    );
  }

  // Métodos de funcionalidade mantidos do arquivo original
  void _apostarItem() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    if (!mounted) return;
    if (!mounted) return;
    setState(() { _comprando = true; });

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      if (mounted) {
        setState(() {
          _historiaAtual = historiaAtualizada;
        });
      }
      widget.onHistoriaAtualizada(historiaAtualizada);

      final item = _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier);
      if (mounted) {
        _mostrarResultadoItem(item, historiaAtualizada);
      }
    } catch (e) {
      if (mounted) {
        _mostrarErro('Erro ao processar aposta: $e');
      }
    }

    if (mounted) {
      if (mounted) {
      setState(() { _comprando = false; });
    }
    }
  }

  void _apostarMagia() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    if (!mounted) return;
    setState(() { _comprando = true; });

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      if (mounted) {
        setState(() {
          _historiaAtual = historiaAtualizada;
        });
      }
      widget.onHistoriaAtualizada(historiaAtualizada);

      final habilidade = _gerarHabilidadeAleatoria();
      _mostrarResultadoMagia(habilidade, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }

    if (mounted) {
      setState(() { _comprando = false; });
    }
  }

  void _apostarCura() async {
    if (_comprando || _historiaAtual.score < custoCura) return;

    if (!mounted) return;
    setState(() { _comprando = true; });

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoCura,
      );

      if (mounted) {
        setState(() {
          _historiaAtual = historiaAtualizada;
        });
      }
      widget.onHistoriaAtualizada(historiaAtualizada);

      final random = Random();
      final porcentagemCura = random.nextInt(100) + 1;

      _mostrarResultadoCura(porcentagemCura, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }

    if (mounted) {
      setState(() { _comprando = false; });
    }
  }

  Widget _buildMagiaPreview(String nome, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cor,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: AutoSizeText(
              nome,
              style: GoogleFonts.philosopher(
                fontSize: 12,
                color: cor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              minFontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirBiblioteca() async {
    if (_comprando || _historiaAtual.score < custoFeirao) return;

    if (!mounted) return;
    setState(() { _comprando = true; });

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoFeirao,
      );

      if (mounted) {
        setState(() {
          _historiaAtual = historiaAtualizada;
        });
      }
      widget.onHistoriaAtualizada(historiaAtualizada);

      // Gerar 3 magias aleatórias
      List<Habilidade> magiasBiblioteca = [];
      for (int i = 0; i < 3; i++) {
        final magia = _gerarHabilidadeAleatoria();
        magiasBiblioteca.add(magia);
      }

      _mostrarModalBiblioteca(magiasBiblioteca, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao abrir biblioteca: $e');
    }

    if (mounted) {
      setState(() { _comprando = false; });
    }
  }

  void _abrirFeirao() async {
    if (_comprando || _historiaAtual.score < custoFeirao) return;

    if (!mounted) return;
    setState(() { _comprando = true; });

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoFeirao,
      );

      if (mounted) {
        setState(() {
          _historiaAtual = historiaAtualizada;
        });
      }
      widget.onHistoriaAtualizada(historiaAtualizada);

      List<Item> itensFeirao = [];
      for (int i = 0; i < 3; i++) {
        final item = _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier);
        itensFeirao.add(item);
      }

      _mostrarModalFeirao(itensFeirao, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao abrir feirão: $e');
    }

    if (mounted) {
      setState(() { _comprando = false; });
    }
  }

  Habilidade _gerarHabilidadeAleatoria() {
    final random = Random();
    final tierAtual = widget.historia.tier;

    // Gerar habilidade base com tipo normal (sem tipagem específica)
    final habilidades = GeradorHabilidades.gerarHabilidadesMonstro(Tipo.normal, null, levelCustomizado: tierAtual);

    if (habilidades.isNotEmpty) {
      final habilidadeBase = habilidades.first;
      // Criar nova habilidade com tipo normal para indicar que não tem tipagem especial
      return Habilidade(
        nome: habilidadeBase.nome,
        descricao: '${habilidadeBase.descricao} (obtida na Biblioteca do Vigarista)',
        tipo: habilidadeBase.tipo,
        efeito: habilidadeBase.efeito,
        tipoElemental: Tipo.normal, // Tipo neutro, sem vantagens/desvantagens
        valor: habilidadeBase.valor,
        custoEnergia: habilidadeBase.custoEnergia,
        level: tierAtual,
      );
    }

    return Habilidade(
      nome: 'Habilidade Misteriosa',
      descricao: 'Uma habilidade obtida na Biblioteca do Vigarista',
      tipo: TipoHabilidade.ofensiva,
      efeito: EfeitoHabilidade.danoDirecto,
      tipoElemental: Tipo.normal, // Tipo neutro, sem vantagens/desvantagens
      valor: 10 * tierAtual,
      custoEnergia: (5 * tierAtual).clamp(5, 50),
      level: tierAtual,
    );
  }

  void _mostrarResultadoItem(Item item, HistoriaJogador historia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalItemObtido(
        item: item,
        monstrosDisponiveis: historia.monstros,
        onEquiparItem: (monstro, itemObtido) async {
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(itemEquipado: itemObtido);
            }
            return m;
          }).toList();

          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);

          Navigator.of(context).pop();

          _mostrarMensagemSucesso('Item ${itemObtido.nome} equipado em ${monstro.tipo.displayName}!');
        },
      ),
    );
  }

  void _mostrarResultadoMagia(Habilidade habilidade, HistoriaJogador historia) {
    final magia = MagiaDrop(
      nome: habilidade.nome,
      descricao: habilidade.descricao,
      tipo: habilidade.tipo,
      efeito: habilidade.efeito,
      valor: habilidade.valor,
      custoEnergia: habilidade.custoEnergia,
      level: habilidade.level,
      dataObtencao: DateTime.now(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalMagiaObtida(
        magia: magia,
        monstrosDisponiveis: historia.monstros,
        onEquiparMagia: (monstro, magiaObtida, habilidadeSubstituida) async {
          final novaHabilidade = Habilidade(
            nome: magiaObtida.nome,
            descricao: magiaObtida.descricao,
            tipo: magiaObtida.tipo,
            efeito: magiaObtida.efeito,
            tipoElemental: habilidade.tipoElemental,
            valor: magiaObtida.valor,
            custoEnergia: magiaObtida.custoEnergia,
            level: magiaObtida.level,
          );

          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              final novasHabilidades = m.habilidades.map((h) {
                return h == habilidadeSubstituida ? novaHabilidade : h;
              }).toList();
              return m.copyWith(habilidades: novasHabilidades);
            }
            return m;
          }).toList();

          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);

          Navigator.of(context).pop();

          _mostrarMensagemSucesso('${monstro.tipo.displayName} aprendeu ${novaHabilidade.nome}!');
        },
      ),
    );
  }

  void _mostrarResultadoCura(int porcentagem, HistoriaJogador historia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalCuraObtida(
        porcentagem: porcentagem,
        monstrosDisponiveis: historia.monstros,
        onCurarMonstro: (monstro, porcentagemCura) async {
          final curaTotal = (monstro.vida * porcentagemCura / 100).round();
          final novaVidaAtual = (monstro.vidaAtual + curaTotal).clamp(0, monstro.vida);

          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(vidaAtual: novaVidaAtual);
            }
            return m;
          }).toList();

          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);

          if (mounted) {
            setState(() {
              _historiaAtual = historiaFinal;
            });
          }
          widget.onHistoriaAtualizada(historiaFinal);

          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          if (mounted) {
            _mostrarMensagemSucesso('${monstro.tipo.displayName} foi curado em $porcentagemCura%!');
          }
        },
      ),
    );
  }

  void _mostrarModalBiblioteca(List<Habilidade> magias, HistoriaJogador historia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassmorphicContainer(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          borderRadius: 25,
          blur: 20,
          alignment: Alignment.center,
          border: 3,
          linearGradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E).withOpacity(0.9),
              const Color(0xFF16213E).withOpacity(0.9),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              const Color(0xFF6A0DAD),
              const Color(0xFF8B008B),
            ],
          ),
          child: Column(
            children: [
              // Header da biblioteca
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6A0DAD),
                            const Color(0xFF8B008B),
                          ],
                        ),
                      ),
                      child: Icon(Icons.library_books, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: const Color(0xFF8B008B),
                        highlightColor: Colors.white,
                        child: AutoSizeText(
                          'BIBLIOTECA DO VIGARISTA',
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B008B),
                          ),
                          maxLines: 2,
                          minFontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de magias
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: magias.length,
                  itemBuilder: (context, index) {
                    return _buildBibliotecaItem(magias[index], historia, index);
                  },
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.diamond, color: const Color(0xFF8B8B8B)),
                        const SizedBox(width: 8),
                        AutoSizeText(
                          '${_historiaAtual.score} OURO',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF8B8B8B),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade700,
                              Colors.grey.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: AutoSizeText(
                          'SAIR',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms),
    );
  }

  void _mostrarModalFeirao(List<Item> itens, HistoriaJogador historia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassmorphicContainer(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          borderRadius: 25,
          blur: 20,
          alignment: Alignment.center,
          border: 3,
          linearGradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E).withOpacity(0.9),
              const Color(0xFF16213E).withOpacity(0.9),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              const Color(0xFFFF8C00),
              const Color(0xFFFFD700),
            ],
          ),
          child: Column(
            children: [
              // Header do feirão
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFF8C00),
                            const Color(0xFFFFD700),
                          ],
                        ),
                      ),
                      child: Icon(Icons.store, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: const Color(0xFFFFD700),
                        highlightColor: Colors.white,
                        child: AutoSizeText(
                          'BOLSO DO VIGARISTA',
                          style: GoogleFonts.cinzel(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de itens
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    final item = itens[index];
                    return _buildFeiraoItem(item, historia, index);
                  },
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.diamond, color: const Color(0xFF8B8B8B)),
                        const SizedBox(width: 8),
                        AutoSizeText(
                          '${_historiaAtual.score} OURO',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF8B8B8B),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade700,
                              Colors.grey.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: AutoSizeText(
                          'SAIR',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms),
    );
  }

  Widget _buildFeiraoItem(Item item, HistoriaJogador historia, int index) {
    bool podeComprar = _historiaAtual.score >= custoAposta && !_comprando;

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calcula altura baseada no número de atributos
                int attributeCount = 0;
                if (item.ataque > 0) attributeCount++;
                if (item.defesa > 0) attributeCount++;
                if (item.vida > 0) attributeCount++;
                if (item.energia > 0) attributeCount++;
                if (item.agilidade > 0) attributeCount++;

                // Altura base + altura por atributo
                double calculatedHeight = 140 + (attributeCount * 20);

                return GlassmorphicContainer(
                  width: double.infinity,
                  height: calculatedHeight,
                  borderRadius: 15,
              blur: 10,
              border: 2,
              linearGradient: LinearGradient(
                colors: [
                  item.raridade.cor.withOpacity(0.3),
                  const Color(0xFF16213E).withOpacity(0.4),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  item.raridade.cor,
                  item.raridade.cor.withOpacity(0.6),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha 1: Imagem e nome do item
                    Row(
                      children: [
                        // Ícone do item
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                item.raridade.cor,
                                item.raridade.cor.withOpacity(0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.raridade.cor.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _buildItemIcon(item.raridade),
                        ),

                        const SizedBox(width: 12),

                        // Nome do item
                        Expanded(
                          child: _buildScrollingText(item.nome),
                        ),

                        // Botão de comprar
                        GestureDetector(
                          onTap: podeComprar ? () => _comprarItemFeirao(item, historia) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: podeComprar
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFFFFD700),
                                        const Color(0xFFFF8C00),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade600,
                                        Colors.grey.shade400,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: podeComprar
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF8C00).withOpacity(0.3),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                AutoSizeText(
                                  '$custoAposta',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 7,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Linha 2: Raridade e valor
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.raridade.cor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AutoSizeText(
                            item.raridade.nome.toUpperCase(),
                            style: GoogleFonts.orbitron(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            minFontSize: 8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AutoSizeText(
                            'Valor Total: ${item.totalAtributos}',
                            style: GoogleFonts.philosopher(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B8B8B),
                            ),
                            maxLines: 1,
                            minFontSize: 9,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Atributos - um por linha
                    if (item.ataque > 0)
                      _buildAttributeLine('ATAQUE', '+${item.ataque}', Colors.red),
                    if (item.defesa > 0)
                      _buildAttributeLine('DEFESA', '+${item.defesa}', Colors.blue),
                    if (item.vida > 0)
                      _buildAttributeLine('VIDA', '+${item.vida}', Colors.green),
                    if (item.energia > 0)
                      _buildAttributeLine('ENERGIA', '+${item.energia}', Colors.purple),
                    if (item.agilidade > 0)
                      _buildAttributeLine('AGILIDADE', '+${item.agilidade}', Colors.orange),
                  ],
                ),
              ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 7,
              color: cor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            minFontSize: 5,
          ),
          const SizedBox(width: 1),
          AutoSizeText(
            valor,
            style: GoogleFonts.orbitron(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            maxLines: 1,
            minFontSize: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildBibliotecaItem(Habilidade habilidade, HistoriaJogador historia, int index) {
    bool podeComprar = _historiaAtual.score >= custoAposta && !_comprando;

    // Definir dados baseados no tipo da habilidade
    String iconPath;
    List<Color> cores;

    String tipoTexto;

    switch (habilidade.tipo) {
      case TipoHabilidade.ofensiva:
        iconPath = 'assets/icons_gerais/magia_ofensiva.png';
        cores = [Colors.red.withOpacity(0.6), Colors.redAccent.withOpacity(0.4)];
        tipoTexto = 'MAGIA OFENSIVA';
        break;
      case TipoHabilidade.suporte:
        iconPath = 'assets/icons_gerais/magia_suporte.png';
        cores = [Colors.blue.withOpacity(0.6), Colors.blueAccent.withOpacity(0.4)];
        tipoTexto = 'MAGIA DEFENSIVA';
        break;
      default:
        iconPath = 'assets/icons_gerais/magia.png';
        cores = [Colors.purple.withOpacity(0.6), Colors.purpleAccent.withOpacity(0.4)];
        tipoTexto = 'MAGIA ESPECIAL';
        break;
    }

    // Se a habilidade tem efeito de cura, usar ícone de cura
    if (habilidade.efeito == EfeitoHabilidade.curarVida) {
      iconPath = 'assets/icons_gerais/magia_cura.png';
      cores = [Colors.green.withOpacity(0.6), Colors.greenAccent.withOpacity(0.4)];
      tipoTexto = 'MAGIA DE CURA';
    }

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 110,
              borderRadius: 15,
              blur: 10,
              border: 2,
              linearGradient: LinearGradient(
                colors: [
                  cores[0].withOpacity(0.15),
                  const Color(0xFF16213E).withOpacity(0.3),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  cores[0],
                  cores[1],
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Ícone da magia
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            cores[0],
                            cores[1],
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cores[0].withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          iconPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    // Informações da magia
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Nome da magia com scroll
                          AutoSizeText(
                            habilidade.nome,
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            minFontSize: 12,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Descrição
                          Flexible(
                            child: AutoSizeText(
                              habilidade.descricao,
                              style: GoogleFonts.philosopher(
                                fontSize: 12,
                                color: cores[0],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              minFontSize: 9,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Preço e botão
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cores[0].withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: cores[0]),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: cores[0],
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: AutoSizeText(
                                        tipoTexto,
                                        style: GoogleFonts.orbitron(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: cores[0].withOpacity(0.9),
                                        ),
                                        maxLines: 1,
                                        minFontSize: 6,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: podeComprar ? () => _comprarMagiaBiblioteca(habilidade, historia) : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: podeComprar
                                        ? LinearGradient(
                                            colors: [
                                              const Color(0xFF6A0DAD),
                                              const Color(0xFF8B008B),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey.shade600,
                                              Colors.grey.shade400,
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: podeComprar
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF6A0DAD).withOpacity(0.3),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.monetization_on,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      AutoSizeText(
                                        '$custoAposta',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        minFontSize: 8,
                                      ),
                                    ],
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _comprarItemFeirao(Item item, HistoriaJogador historia) async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    if (!mounted) return;
    setState(() { _comprando = true; });

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      if (mounted) {
        setState(() {
          _historiaAtual = historiaAtualizada;
        });
      }
      widget.onHistoriaAtualizada(historiaAtualizada);

      Navigator.of(context).pop();

      _mostrarResultadoItem(item, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao comprar item: $e');
    }

    if (mounted) {
      setState(() { _comprando = false; });
    }
  }

  void _mostrarMensagemSucesso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _comprarMagiaBiblioteca(Habilidade habilidade, HistoriaJogador historia) async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    if (!mounted) return;
    setState(() { _comprando = true; });

    try {
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      if (mounted) {
        setState(() {
          _historiaAtual = historiaAtualizada;
        });
      }
      widget.onHistoriaAtualizada(historiaAtualizada);

      Navigator.of(context).pop();
      _mostrarResultadoMagia(habilidade, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao comprar magia: $e');
    }

    if (mounted) {
      setState(() { _comprando = false; });
    }
  }


  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    if (mounted) {
      setState(() { _comprando = false; });
    }
  }

  Widget _buildItemIcon(RaridadeItem raridade) {
    String iconPath;
    switch (raridade) {
      case RaridadeItem.inferior:
        iconPath = 'assets/armaduras/armadura_inferior.png';
        break;
      case RaridadeItem.normal:
        iconPath = 'assets/armaduras/armadura_normal.png';
        break;
      case RaridadeItem.raro:
        iconPath = 'assets/armaduras/armadura_rara.png';
        break;
      case RaridadeItem.epico:
        iconPath = 'assets/armaduras/armadura_epica.png';
        break;
      case RaridadeItem.lendario:
        iconPath = 'assets/armaduras/armadura_lendaria.png';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        iconPath,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildAttributeLine(String label, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AutoSizeText(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            maxLines: 1,
            minFontSize: 8,
          ),
          AutoSizeText(
            valor,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cor.withOpacity(0.9),
            ),
            maxLines: 1,
            minFontSize: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollingText(String text) {
    return AutoSizeText(
      text,
      style: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      maxLines: 1,
      minFontSize: 10,
      overflow: TextOverflow.ellipsis,
    );
  }
}