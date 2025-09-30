import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../models/monstro_inimigo.dart';
import '../models/historia_jogador.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../tipagem/data/tipagem_repository.dart';
import '../presentation/modal_monstro_inimigo.dart';
import '../presentation/selecao_monstro_screen.dart';
import '../presentation/casa_vigarista_modal_v2.dart';
import '../presentation/mochila_screen.dart';
import '../presentation/aventura_screen.dart';
import '../presentation/progresso_screen.dart';

class MapaAventuraScreen extends ConsumerStatefulWidget {
  final String mapaPath;
  final List<MonstroInimigo> monstrosInimigos;

  const MapaAventuraScreen({
    super.key,
    required this.mapaPath,
    required this.monstrosInimigos,
  });

  @override
  ConsumerState<MapaAventuraScreen> createState() => _MapaAventuraScreenState();
}

class _MapaAventuraScreenState extends ConsumerState<MapaAventuraScreen> {
  late String mapaEscolhido;
  HistoriaJogador? historiaAtual;
  bool isLoading = true;
  bool isAdvancingTier = false;
  int _abaAtual = 0; // 0 = Equipe, 1 = Mapa, 2 = Mochila, 3 = Loja, 4 = Progresso

  final List<String> mapasDisponiveis = [
    'assets/mapas_aventura/cidade_abandonada.jpg',
    'assets/mapas_aventura/deserto.jpg',
    'assets/mapas_aventura/floresta_verde.jpg',
    'assets/mapas_aventura/praia.jpg',
    'assets/mapas_aventura/vulcao.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _verificarAventuraIniciada();
  }


  Future<void> _verificarAventuraIniciada() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      
      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Verificando aventura iniciada para: $emailJogador');
      
      // Carrega a histÃƒÆ’Ã‚Â³ria do jogador
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      
      if (historia != null) {
        print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] HistÃƒÆ’Ã‚Â³ria encontrada - Aventura iniciada: ${historia.aventuraIniciada}');

        // Verifica se a aventura expirou
        if (historia.aventuraExpirada) {
          print('ÃƒÂ¢Ã‚ÂÃ‚Â° [MapaAventura] Aventura expirada ao carregar mapa!');
          setState(() {
            isLoading = false;
          });

          // Mostra modal e volta para tela de aventura
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mostrarModalAventuraExpirada();
          });
          return;
        }

        setState(() {
          historiaAtual = historia;

          if (historia.aventuraIniciada && historia.mapaAventura != null) {
            // Se hÃƒÆ’Ã‚Â¡ aventura iniciada, usa o mapa salvo
            mapaEscolhido = historia.mapaAventura!;
            print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Usando mapa salvo: $mapaEscolhido');
          } else {
            // Se nÃƒÆ’Ã‚Â£o hÃƒÆ’Ã‚Â¡ aventura iniciada, sorteia um mapa aleatÃƒÆ’Ã‚Â³rio
            final random = math.Random();
            mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
            print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Sorteou novo mapa: $mapaEscolhido');
          }

          isLoading = false;
        });
      } else {
        print('ÃƒÂ¢Ã‚ÂÃ…â€™ [MapaAventura] Nenhuma histÃƒÆ’Ã‚Â³ria encontrada');
        setState(() {
          final random = math.Random();
          mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
          isLoading = false;
        });
      }
    } catch (e) {
      print('ÃƒÂ¢Ã‚ÂÃ…â€™ [MapaAventura] Erro ao verificar aventura: $e');
      setState(() {
        final random = math.Random();
        mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
        isLoading = false;
      });
    }
  }

  List<MonstroInimigo> get monstrosParaExibir {
    // Se hÃƒÆ’Ã‚Â¡ histÃƒÆ’Ã‚Â³ria carregada e aventura iniciada, usa os monstros da histÃƒÆ’Ã‚Â³ria
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Usando monstros da histÃƒÆ’Ã‚Â³ria: ${historiaAtual!.monstrosInimigos.length}');
      return historiaAtual!.monstrosInimigos;
    }
    
    // Caso contrÃƒÆ’Ã‚Â¡rio, usa os monstros passados por parÃƒÆ’Ã‚Â¢metro
    print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Usando monstros do parÃƒÆ’Ã‚Â¢metro: ${widget.monstrosInimigos.length}');
    return widget.monstrosInimigos;
  }
  @override
  Widget build(BuildContext context) {
    // Observa mudanÃƒÆ’Ã‚Â§as no estado da aventura para recarregar quando necessÃƒÆ’Ã‚Â¡rio
    ref.listen<AventuraEstado>(aventuraEstadoProvider, (previous, next) {
      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ¢â‚¬Å¾ [MapaAventura] Estado mudou: $previous -> $next');
      if (next == AventuraEstado.aventuraIniciada && previous != AventuraEstado.aventuraIniciada) {
        print('ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ [MapaAventura] Aventura foi iniciada! Recarregando estado...');
        _verificarAventuraIniciada();
      } else if (next == AventuraEstado.semHistorico) {
        print('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ¢â‚¬Å¾ [MapaAventura] Aventura foi deletada! Recarregando estado...');
        setState(() {
          historiaAtual = null;
        });
      } else if (next == AventuraEstado.podeIniciar) {
        print('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ¢â‚¬Å¾ [MapaAventura] Novos monstros sorteados! Recarregando estado...');
        _verificarAventuraIniciada();
      }
    });

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('Mapa de Aventura'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando aventura...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Aventura'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          // ÃƒÆ’Ã‚Âcone de refresh - sÃƒÆ’Ã‚Â³ aparece quando aventura iniciada e sem batalhas no andar atual
          if (historiaAtual?.aventuraIniciada == true && _podeRefreshAndar())
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshAndar,
                  tooltip: 'Resetar andar atual',
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${historiaAtual?.refreshsRestantes ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ConteÃƒÆ’Ã‚Âºdo principal
            Expanded(
              child: IndexedStack(
                index: _abaAtual,
                children: [
                  // ABA 0: EQUIPE (tela de seleÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o/inÃƒÆ’Ã‚Â­cio)
                  const AventuraScreen(),

                  // ABA 1: MAPA
                  _buildMapaView(),

                  // ABA 2: MOCHILA
                  const MochilaScreen(),

                  // ABA 3: LOJA
                  _buildLojaView(),

                  // ABA 4: PROGRESSO
                  const ProgressoScreen(),
                ],
              ),
            ),

            // Barra de abas inferior
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapaView() {
    int tierAtual = historiaAtual?.tier ?? 1;
    int scoreAtual = historiaAtual?.score ?? 0;
    int mortosNoTier = monstrosParaExibir.where((m) => m.vidaAtual <= 0).length;
    bool podeAvancarTier = mortosNoTier >= 3;
    print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] mortosNoTier: $mortosNoTier, podeAvancarTier: $podeAvancarTier');

    return Stack(
      children: [
        // Imagem do mapa de fundo
        Positioned.fill(
          child: Image.asset(
            mapaEscolhido,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade800,
                child: const Center(
                  child: Text(
                    'Mapa nÃƒÆ’Ã‚Â£o encontrado',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
            // TIER, SCORE e botÃƒÆ’Ã‚Â£o avanÃƒÆ’Ã‚Â§ar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Row(
                  children: [
                    // TIER
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'TIER $tierAtual',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // SCORE
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          'SCORE: $scoreAtual',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // BOTÃƒÆ’Ã†â€™O AVANÃƒÆ’Ã¢â‚¬Â¡AR
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _mostrarModalAvancarTier(podeAvancarTier, mortosNoTier),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: podeAvancarTier 
                              ? Colors.green.withOpacity(0.8)
                              : Colors.grey.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pontos interativos do mapa (5 pontos fixos)
            ..._buildPontosMapa(),
            
        // Overlay de loading quando avanÃƒÆ’Ã‚Â§ando tier
        if (isAdvancingTier)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Preparando novo andar...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gerando novos monstros e salvando progresso',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLojaView() {
    if (historiaAtual == null) {
      return Container(
        color: Colors.grey.shade900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Carregando loja...',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return CasaVigaristaModalV2(
      historia: historiaAtual!,
      onHistoriaAtualizada: (historiaAtualizada) async {
        setState(() {
          historiaAtual = historiaAtualizada;
        });

        try {
          final repository = ref.read(aventuraRepositoryProvider);
          await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
          await repository.salvarHistoricoEAtualizarRanking(historiaAtualizada);
          print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â„¢Ã‚Â¾ [Loja] HistÃƒÆ’Ã‚Â³ria atualizada apÃƒÆ’Ã‚Â³s compra');
        } catch (e) {
          print('ÃƒÂ¢Ã‚ÂÃ…â€™ [Loja] Erro ao salvar histÃƒÆ’Ã‚Â³ria: $e');
        }
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabButton(
            index: 0,
            icon: Icons.groups,
            label: 'EQUIPE',
            isSelected: _abaAtual == 0,
          ),
          Builder(
            builder: (context) {
              final mapaDisabled = historiaAtual?.aventuraIniciada != true;
              print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MAPA TAB] aventuraIniciada=${historiaAtual?.aventuraIniciada}, disabled=$mapaDisabled');
              return _buildTabButton(
                index: 1,
                icon: Icons.map,
                label: 'MAPA',
                isSelected: _abaAtual == 1,
                disabled: mapaDisabled,
              );
            },
          ),
          _buildTabButton(
            index: 2,
            icon: Icons.backpack,
            label: 'MOCHILA',
            isSelected: _abaAtual == 2,
            iconAsset: 'assets/icons_gerais/mochila.png',
          ),
          Builder(
            builder: (context) {
              final lojaDisabled = historiaAtual?.aventuraIniciada != true;
              print('ÃƒÂ°Ã…Â¸Ã‚ÂÃ‚Âª [LOJA TAB] aventuraIniciada=${historiaAtual?.aventuraIniciada}, disabled=$lojaDisabled');
              return _buildTabButton(
                index: 3,
                icon: Icons.store,
                label: 'LOJA',
                isSelected: _abaAtual == 3,
                disabled: lojaDisabled,
              );
            },
          ),
          _buildTabButton(
            index: 4,
            icon: Icons.star,
            label: 'PROGRESSO',
            isSelected: _abaAtual == 4,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    String? iconAsset,
    bool disabled = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (disabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inicie uma aventura primeiro!'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
              return; // Impede mudanÃƒÆ’Ã‚Â§a de aba
            }
            setState(() {
              _abaAtual = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? Colors.amber : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ÃƒÆ’Ã‚Âcone (asset ou icon)
                if (iconAsset != null)
                  Image.asset(
                    iconAsset,
                    width: 28,
                    height: 28,
                    color: disabled
                        ? Colors.white.withOpacity(0.3)
                        : (isSelected ? Colors.amber : Colors.white60),
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        icon,
                        size: 28,
                        color: disabled
                            ? Colors.white.withOpacity(0.3)
                            : (isSelected ? Colors.amber : Colors.white60),
                      );
                    },
                  )
                else
                  Icon(
                    icon,
                    size: 28,
                    color: disabled
                        ? Colors.white.withOpacity(0.3)
                        : (isSelected ? Colors.amber : Colors.white60),
                  ),

                const SizedBox(height: 4),

                // Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: disabled
                        ? Colors.white.withOpacity(0.3)
                        : (isSelected ? Colors.amber : Colors.white60),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPontosMapa() {
    final monstrosParaUsar = monstrosParaExibir;
    final pontos = <Widget>[];

    // Separa monstros de coleÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o dos demais
    final monstrosNormais = monstrosParaUsar.where((m) => !m.isRaro).toList();
    final monstrosColecao = monstrosParaUsar.where((m) => m.isRaro).toList();

    // PosiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes fixas dos pontos no mapa para monstros normais
    final posicoes = [
      (0.2, 0.2),   // Ponto 1 - Superior esquerdo
      (0.7, 0.15),  // Ponto 2 - Superior direito
      (0.5, 0.45),  // Ponto 3 - Centro
      (0.25, 0.65), // Ponto 4 - Inferior esquerdo
      (0.75, 0.68), // Ponto 5 - Inferior direito
      (0.5, 0.75),  // Ponto 6 - Elite (terceira linha, centro-inferior)
    ];

    // Adiciona pontos dos monstros normais
    for (int i = 0; i < posicoes.length && i < monstrosNormais.length; i++) {
      pontos.add(_buildPontoMapa(i, posicoes[i].$1, posicoes[i].$2, monstrosNormais));
    }

    // Casa do Vigarista agora estÃƒÆ’Ã‚Â¡ nas abas inferiores
    // pontos.add(_buildCasaDoVigarista(0.5, 0.25));

    // Adiciona monstros de coleÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o 3 centÃƒÆ’Ã‚Â­metros abaixo do mercado
    for (int i = 0; i < monstrosColecao.length; i++) {
      final posX = 0.2 + (i * 0.6); // PosiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes 0.2, 0.8, etc. para mÃƒÆ’Ã‚Âºltiplos monstros
      pontos.add(_buildMonstroColecao(monstrosColecao[i], posX, 0.35)); // 0.25 + ~0.10 = 3cm abaixo
    }

    return pontos;
  }

  Widget _buildPontoMapa(int index, double left, double top, List<MonstroInimigo> monstros) {
    if (index >= monstros.length) {
      return const SizedBox.shrink();
    }

    final monstro = monstros[index];
    final bool estaMorto = monstro.vidaAtual <= 0;
    
    // Limita a posiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o mÃƒÆ’Ã‚Â¡xima do topo para nÃƒÆ’Ã‚Â£o colar na borda inferior
    final screenHeight = MediaQuery.of(context).size.height;
    final maxTop = screenHeight * 0.85;
    final calcTop = (screenHeight * top).clamp(0, maxTop).toDouble();
    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: calcTop,
      child: GestureDetector(
        onTap: () => _mostrarModalMonstroInimigo(monstro),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: estaMorto
                ? Colors.grey.withOpacity(0.9)
                : monstro.tipo.cor.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: monstro.isElite ? const Color(0xFFFFD700) : Colors.white, // Gold color
              width: monstro.isElite ? 4 : 3
            ),
            boxShadow: [
              BoxShadow(
                color: estaMorto 
                    ? Colors.grey.withOpacity(0.6)
                    : monstro.tipo.cor.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ColorFiltered(
            colorFilter: estaMorto
                ? const ColorFilter.matrix([
                    0.2126, 0.7152, 0.0722, 0, 0, // Red
                    0.2126, 0.7152, 0.0722, 0, 0, // Green
                    0.2126, 0.7152, 0.0722, 0, 0, // Blue
                    0,      0,      0,      1, 0, // Alpha
                  ])
                : const ColorFilter.matrix([
                    1, 0, 0, 0, 0,
                    0, 1, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
            child: Image.asset(
              monstro.isRaro
                ? 'assets/icons_gerais/monstro_colecao.png'
                : (monstro.isElite
                    ? 'assets/icons_gerais/monstro_elite.png'
                    : 'assets/icons_gerais/monstro_comum.png'),
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCasaDoVigarista(double left, double top) {
    // Verifica se o jogador tem score suficiente (mÃƒÆ’Ã‚Â­nimo = 1 * tier atual)
    int tierAtual = historiaAtual?.tier ?? 1;
    int scoreAtual = historiaAtual?.score ?? 0;
    int custoMinimo = 1 * tierAtual;
    bool podeAcessar = scoreAtual >= custoMinimo;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final maxTop = screenHeight * 0.85;
    final calcTop = (screenHeight * top).clamp(0, maxTop).toDouble();
    
    return Positioned(
      left: MediaQuery.of(context).size.width * left - 35, // Centraliza o ÃƒÆ’Ã‚Â­cone
      top: calcTop,
      child: GestureDetector(
        onTap: () => _mostrarCasaDoVigarista(podeAcessar, custoMinimo),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: podeAcessar 
                ? Colors.amber.withOpacity(0.9)
                : Colors.grey.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: podeAcessar ? Colors.yellow.shade700 : Colors.grey.shade500, 
              width: 3
            ),
            boxShadow: [
              BoxShadow(
                color: podeAcessar 
                    ? Colors.amber.withOpacity(0.8)
                    : Colors.grey.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/npc/loja.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              color: podeAcessar ? null : Colors.grey.shade300,
              colorBlendMode: podeAcessar ? null : BlendMode.saturation,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarCasaDoVigarista(bool podeAcessar, int custoMinimo) {
    if (!podeAcessar) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Acesso Negado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VocÃƒÆ’Ã‚Âª nÃƒÆ’Ã‚Â£o possui score suficiente para acessar a Casa do Vigarista.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Score necessÃƒÆ’Ã‚Â¡rio: $custoMinimo pontos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Seu score atual: ${historiaAtual?.score ?? 0} pontos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Derrote mais monstros para ganhar score!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (historiaAtual == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CasaVigaristaModalV2(
          historia: historiaAtual!,
          onHistoriaAtualizada: (historiaAtualizada) async {
            // Atualiza o estado local
            setState(() {
              historiaAtual = historiaAtualizada;
            });

            // Salva no repositÃƒÆ’Ã‚Â³rio
            try {
              final repository = ref.read(aventuraRepositoryProvider);
              // Salva localmente primeiro
              await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

              // Salva no Drive e atualiza ranking apÃƒÆ’Ã‚Â³s compra na loja
              print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â„¢Ã‚Â¾ [MapaAventura] Salvando compra no Drive e atualizando ranking...');
              await repository.salvarHistoricoEAtualizarRanking(historiaAtualizada);

              print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â„¢Ã‚Â¾ [MapaAventura] HistÃƒÆ’Ã‚Â³ria atualizada apÃƒÆ’Ã‚Â³s compra na Casa do Vigarista (HIVE + Drive)');
            } catch (e) {
              print('ÃƒÂ¢Ã‚ÂÃ…â€™ [MapaAventura] Erro ao salvar histÃƒÆ’Ã‚Â³ria: $e');
            }
          },
        );
      },
    );
  }

  Widget _buildMonstroColecao(MonstroInimigo monstro, double left, double top) {
    final bool estaMorto = monstro.vidaAtual <= 0;

    // Limita a posiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o mÃƒÆ’Ã‚Â¡xima do topo para nÃƒÆ’Ã‚Â£o colar na borda inferior
    final screenHeight = MediaQuery.of(context).size.height;
    final calcTop = math.min(screenHeight * top, screenHeight - 100);

    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: calcTop,
      child: GestureDetector(
        onTap: () => _mostrarModalMonstroInimigo(monstro),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: estaMorto
                ? Colors.grey.withOpacity(0.9)
                : Colors.purple.withOpacity(0.9), // Cor especial para monstros de coleÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.orange, // Cor dourada para monstros de coleÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o
              width: 4
            ),
            boxShadow: [
              BoxShadow(
                color: estaMorto
                    ? Colors.grey.withOpacity(0.6)
                    : Colors.purple.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons_gerais/monstro_colecao.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            color: estaMorto ? Colors.grey.shade600 : null, // Apenas escurece se morto
          ),
        ),
      ),
    );
  }

  void _mostrarModalMonstroInimigo(MonstroInimigo monstro) async {
    // ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ PRINT DOS DADOS DE DEFESA DO MONSTRO INIMIGO
    print('ÃƒÂ°Ã…Â¸Ã‚ÂÃ¢â‚¬Â° [MONSTRO INIMIGO CLICADO] Tipo: ${monstro.tipo.displayName} (${monstro.tipo.name})');
    
    try {
      // Busca os dados de defesa do tipo do monstro
      final tipagemRepository = TipagemRepository();
      final dadosDefesa = await tipagemRepository.carregarDadosTipo(monstro.tipo);
      
      if (dadosDefesa != null) {
        print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â„¢Ã‚Â¥ [DADOS DE DEFESA] Lista de dano recebido por ${monstro.tipo.displayName}:');
        print('ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬' * 60);
        
        // Imprime cada tipo e o valor de dano recebido
        for (final entry in dadosDefesa.entries) {
          final atacante = entry.key;
          final multiplicador = entry.value;
          
          // Determina a efetividade
          String efetividade;
          if (multiplicador > 1.0) {
            efetividade = 'SUPER EFETIVO';
          } else if (multiplicador < 1.0 && multiplicador > 0.0) {
            efetividade = 'POUCO EFETIVO';
          } else if (multiplicador == 0.0) {
            efetividade = 'NÃƒÆ’Ã†â€™O AFETA';
          } else {
            efetividade = 'NORMAL';
          }
          
          print('${atacante.displayName.padRight(15)} -> ${multiplicador.toString().padLeft(4)} (${efetividade})');
        }
        print('ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬' * 60);
      } else {
        print('ÃƒÂ¢Ã‚ÂÃ…â€™ [ERRO] NÃƒÆ’Ã‚Â£o foi possÃƒÆ’Ã‚Â­vel carregar dados de defesa para ${monstro.tipo.displayName}');
      }
    } catch (e) {
      print('ÃƒÂ¢Ã‚ÂÃ…â€™ [ERRO] Erro ao buscar dados de defesa: $e');
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ModalMonstroInimigo(
          monstro: monstro,
          showBattleButton: true,
          onBattle: () {
            Navigator.of(context).pop(); // Fecha o modal
            _iniciarBatalha(monstro);
          },
        );
      },
    );
  }

  void _iniciarBatalha(MonstroInimigo monstroInimigo) {
    // Verifica se a aventura expirou antes de iniciar batalha
    if (historiaAtual != null && historiaAtual!.aventuraExpirada) {
      print('ÃƒÂ¢Ã‚ÂÃ‚Â° [MapaAventura] Tentativa de batalhar com aventura expirada!');
      _mostrarModalAventuraExpirada();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecaoMonstroScreen(monstroInimigo: monstroInimigo),
      ),
    );
  }

  Future<void> _avancarTier() async {
    print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] _avancarTier() iniciado');
    setState(() {
      isAdvancingTier = true;
      print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] isAdvancingTier definido como true');
    });

    try {
      final repository = ref.read(aventuraRepositoryProvider);

      if (historiaAtual == null) {
        print('ÃƒÂ¢Ã‚ÂÃ…â€™ [DEBUG] historiaAtual ÃƒÆ’Ã‚Â© null, retornando');
        return;
      }
      print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] historiaAtual nÃƒÆ’Ã‚Â£o ÃƒÆ’Ã‚Â© null, continuando...');

      // Gera novos monstros para o prÃƒÆ’Ã‚Â³ximo tier
      final novosMonstros = await _gerarNovosMonstrosParaTier(historiaAtual!.tier + 1);

      // Verifica se ÃƒÆ’Ã‚Â© o andar 10 para resetar score (sÃƒÆ’Ã‚Â³ se tiver mais de 50)
      int novoScore = historiaAtual!.score;
      if (historiaAtual!.tier == 10 && historiaAtual!.score > 50) {
        novoScore = 50;
        print('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ¢â‚¬Å¾ [MapaAventura] Reset de score no andar 10: ${historiaAtual!.score} ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ $novoScore');
      } else if (historiaAtual!.tier == 10) {
        print('ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã…â€™ [MapaAventura] Score mantido no andar 10 (ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤50): ${historiaAtual!.score}');
      }

      // Atualiza a histÃƒÆ’Ã‚Â³ria com novo tier, novos monstros e score (resetado se tier 10)
      final historiaAtualizada = historiaAtual!.copyWith(
        tier: historiaAtual!.tier + 1,
        monstrosInimigos: novosMonstros,
        score: novoScore,
      );

      // Salva no repositÃƒÆ’Ã‚Â³rio
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      // Atualiza o estado local
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [MapaAventura] Tier avanÃƒÆ’Ã‚Â§ado! Novo tier: ${historiaAtualizada.tier}, Score: ${historiaAtualizada.score}');

    } catch (e) {
      print('ÃƒÂ¢Ã‚ÂÃ…â€™ [MapaAventura] Erro ao avanÃƒÆ’Ã‚Â§ar tier: $e');
    } finally {
      print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] Finally executado, resetando isAdvancingTier');
      setState(() {
        isAdvancingTier = false;
      });
    }
  }

  Future<List<MonstroInimigo>> _gerarNovosMonstrosParaTier(int novoTier) async {
    // Gera novos monstros usando o repository para o novo tier
    final repository = ref.read(aventuraRepositoryProvider);

    print('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ¢â‚¬Å¾ [MapaAventura] Gerando novos monstros inimigos para tier $novoTier');

    // Chama o mÃƒÆ’Ã‚Â©todo pÃƒÆ’Ã‚Âºblico do repository para gerar novos monstros com itens
    final novosMonstros = await repository.gerarMonstrosInimigosPorTier(novoTier);

    print('ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ [MapaAventura] Novos monstros gerados com tier $novoTier');
    return novosMonstros;
  }

  String _getMensagemDificuldadeTitulo(int tier) {
    switch (tier) {
      case 19:
        return 'Tier 20: Inimigos Mais Fortes';
      case 29:
        return 'Tier 30: Equipamentos Melhores';
      case 39:
        return 'Tier 40: Itens de Elite';
      case 49:
        return 'Tier 50: Equipamentos LendÃƒÆ’Ã‚Â¡rios';
      default:
        return 'Aumento de Dificuldade';
    }
  }

  String _getMensagemDificuldadeDescricao(int tier) {
    switch (tier) {
      case 19:
        return 'A partir do tier 20, os inimigos nÃƒÆ’Ã‚Â£o usarÃƒÆ’Ã‚Â£o mais itens inferiores. Apenas itens normais ou superiores serÃƒÆ’Ã‚Â£o equipados.';
      case 29:
        return 'A partir do tier 30, os inimigos nÃƒÆ’Ã‚Â£o usarÃƒÆ’Ã‚Â£o mais itens normais. Apenas itens raros ou superiores serÃƒÆ’Ã‚Â£o equipados.';
      case 39:
        return 'A partir do tier 40, os inimigos nÃƒÆ’Ã‚Â£o usarÃƒÆ’Ã‚Â£o mais itens raros. Apenas itens ÃƒÆ’Ã‚Â©picos ou superiores serÃƒÆ’Ã‚Â£o equipados.';
      case 49:
        return 'A partir do tier 50, os inimigos nÃƒÆ’Ã‚Â£o usarÃƒÆ’Ã‚Â£o mais itens ÃƒÆ’Ã‚Â©picos. Apenas itens lendÃƒÆ’Ã‚Â¡rios serÃƒÆ’Ã‚Â£o equipados pelos inimigos.';
      default:
        return 'Os inimigos ficarÃƒÆ’Ã‚Â£o mais desafiadores a partir deste tier.';
    }
  }

  void _mostrarModalAvancarTier(bool podeAvancar, int monstrosMortos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Verificar se ÃƒÆ’Ã‚Â© o andar 10
        bool isAndar10 = historiaAtual?.tier == 10;

        // Verificar se ÃƒÆ’Ã‚Â© um dos tiers de aumento de dificuldade
        bool isTierDificuldade = podeAvancar && [19, 29, 39, 49].contains(historiaAtual?.tier);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                podeAvancar ? (isAndar10 ? Icons.warning : (isTierDificuldade ? Icons.trending_up : Icons.arrow_upward)) : Icons.block,
                color: podeAvancar ? (isAndar10 ? Colors.orange : (isTierDificuldade ? Colors.deepOrange : Colors.green)) : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  podeAvancar
                    ? (isAndar10 ? 'AVISO ESPECIAL - Andar 10' : (isTierDificuldade ? 'AUMENTO DE DIFICULDADE' : 'AvanÃƒÆ’Ã‚Â§ar Tier'))
                    : 'Requisitos nÃƒÆ’Ã‚Â£o atendidos',
                  style: TextStyle(
                    color: podeAvancar ? (isAndar10 ? Colors.orange : (isTierDificuldade ? Colors.deepOrange : Colors.green)) : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (podeAvancar) ...[
                if (isTierDificuldade) ...[
                  // Mensagens especÃƒÆ’Ã‚Â­ficas de aumento de dificuldade
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.deepOrange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getMensagemDificuldadeTitulo(historiaAtual!.tier),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getMensagemDificuldadeDescricao(historiaAtual!.tier),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (isAndar10) ...[
                  // Aviso especial para o andar 10
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ((historiaAtual?.score ?? 0) > 50 ? Colors.red : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ((historiaAtual?.score ?? 0) > 50 ? Colors.red : Colors.green).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (historiaAtual?.score ?? 0) > 50 ? Icons.warning : Icons.check_circle,
                              color: (historiaAtual?.score ?? 0) > 50 ? Colors.red : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (historiaAtual?.score ?? 0) > 50
                                  ? 'RESET DE SCORE NO ANDAR 10'
                                  : 'SCORE MANTIDO NO ANDAR 10',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: (historiaAtual?.score ?? 0) > 50 ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (historiaAtual?.score ?? 0) > 50
                            ? 'Ao avanÃƒÆ’Ã‚Â§ar do andar 10 para o 11, seu score serÃƒÆ’Ã‚Â¡ resetado para 50 pontos.'
                            : 'Ao avanÃƒÆ’Ã‚Â§ar do andar 10 para o 11, seu score serÃƒÆ’Ã‚Â¡ mantido (ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤50 pontos).',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (historiaAtual?.score ?? 0) > 50
                            ? 'Score atual: ${historiaAtual?.score ?? 0} pontos ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ FicarÃƒÆ’Ã‚Â¡: 50 pontos'
                            : 'Score atual: ${historiaAtual?.score ?? 0} pontos ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ SerÃƒÆ’Ã‚Â¡ mantido',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: (historiaAtual?.score ?? 0) > 50 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â Outras mudanÃƒÆ’Ã‚Â§as importantes:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Monstros do andar 11+ darÃƒÆ’Ã‚Â£o 2 pontos por vitÃƒÆ’Ã‚Â³ria'),
                  const Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ A loja considerarÃƒÆ’Ã‚Â¡ preÃƒÆ’Ã‚Â§os como se fosse tier 2'),
                  const Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Novos monstros mais fortes aparecerÃƒÆ’Ã‚Â£o'),
                ] else ...[
                  // Aviso normal para outros andares
                  const Text(
                    'ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â ATENÃƒÆ’Ã¢â‚¬Â¡ÃƒÆ’Ã†â€™O: Ao avanÃƒÆ’Ã‚Â§ar para o prÃƒÆ’Ã‚Â³ximo tier:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ VocÃƒÆ’Ã‚Âª nÃƒÆ’Ã‚Â£o poderÃƒÆ’Ã‚Â¡ retornar ao tier anterior'),
                  const Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Novos monstros mais fortes aparecerÃƒÆ’Ã‚Â£o'),
                  const Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Seu progresso atual serÃƒÆ’Ã‚Â¡ salvo'),
                  const SizedBox(height: 8),
                  const Text(
                    'Seu score atual serÃƒÆ’Ã‚Â¡ mantido.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'VocÃƒÆ’Ã‚Âª precisa derrotar pelo menos 3 monstros para avanÃƒÆ’Ã‚Â§ar de tier.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Progresso atual: $monstrosMortos/3 monstros derrotados',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continue explorando o mapa e derrotando monstros!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            if (podeAvancar)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAndar10 ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] BotÃƒÆ’Ã‚Â£o Confirmar clicado');
                  Navigator.of(context).pop();
                  print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] Modal fechado, chamando _avancarTier()');
                  _avancarTier();
                },
                child: Text(
                  isAndar10
                    ? ((historiaAtual?.score ?? 0) > 50 ? 'AvanÃƒÆ’Ã‚Â§ar e Resetar' : 'AvanÃƒÆ’Ã‚Â§ar (Score Mantido)')
                    : 'Confirmar'
                ),
              ),
          ],
        );
      },
    );
  }

  /// Mostra modal de aventura expirada
  Future<void> _mostrarModalAventuraExpirada() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.orange.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ÃƒÆ’Ã‚Âcone de aventura expirada
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              // TÃƒÆ’Ã‚Â­tulo
              const Text(
                'Aventura Expirada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Mensagem explicativa
              const Text(
                'Sua aventura expirou apÃƒÆ’Ã‚Â³s a meia-noite (horÃƒÆ’Ã‚Â¡rio de BrasÃƒÆ’Ã‚Â­lia). Para continuar jogando, vocÃƒÆ’Ã‚Âª precisa sortear novos monstros e comeÃƒÆ’Ã‚Â§ar uma nova aventura.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Container de informaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o adicional
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Aventuras sÃƒÆ’Ã‚Â£o vÃƒÆ’Ã‚Â¡lidas apenas durante o dia em que foram criadas.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BotÃƒÆ’Ã‚Â£o para voltar ÃƒÆ’Ã‚Â  tela de aventura
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o modal
                    Navigator.of(context).pop(); // Volta para a tela de aventura
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Voltar para Aventura',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Verifica se pode refresh do andar (nÃƒÆ’Ã‚Â£o houve batalhas no andar atual e tem refreshs restantes)
  bool _podeRefreshAndar() {
    if (historiaAtual == null) return false;

    // Verifica se hÃƒÆ’Ã‚Â¡ batalhas no tier atual
    final batalhasNoTierAtual = historiaAtual!.historicoBatalhas
        .where((batalha) => batalha.tierNaBatalha == historiaAtual!.tier)
        .toList();

    // Verifica se tem refreshs restantes
    final temRefreshsRestantes = historiaAtual!.refreshsRestantes > 0;

    return batalhasNoTierAtual.isEmpty && temRefreshsRestantes;
  }

  /// Reseta o andar atual gerando novos monstros
  Future<void> _refreshAndar() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ÃƒÆ’Ã‚Âcone de refresh animado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),

                // TÃƒÆ’Ã‚Â­tulo
                const Text(
                  'Resetando Andar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Progress indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),

                // Mensagem explicativa
                const Text(
                  'Gerando novos monstros para o andar atual...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Container de informaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o adicional
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Seu progresso no tier serÃƒÆ’Ã‚Â¡ mantido.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Refreshs restantes apÃƒÆ’Ã‚Â³s este: ${(historiaAtual?.refreshsRestantes ?? 1) - 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
      );

      final repository = ref.read(aventuraRepositoryProvider);

      if (historiaAtual == null) return;

      // Delay de 2 segundos para mostrar o loading
      await Future.delayed(const Duration(seconds: 2));

      // Gera novos monstros para o tier atual
      final novosMonstros = await repository.gerarMonstrosInimigosPorTier(historiaAtual!.tier);

      // Atualiza a histÃƒÆ’Ã‚Â³ria com novos monstros e decrementa refreshs
      final historiaAtualizada = historiaAtual!.copyWith(
        monstrosInimigos: novosMonstros,
        refreshsRestantes: historiaAtual!.refreshsRestantes - 1,
      );

      // Salva localmente
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      // Salva no Drive
      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â„¢Ã‚Â¾ [MapaAventura] Salvando refresh no Drive...');
      await repository.salvarHistoricoEAtualizarRanking(historiaAtualizada);

      // Atualiza o estado local
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      // Fecha o dialog de loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ¢â‚¬Å¾ [MapaAventura] Andar resetado! Novos monstros gerados para tier ${historiaAtualizada.tier}');
      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ¢â‚¬Å¾ [MapaAventura] Refreshs restantes: ${historiaAtualizada.refreshsRestantes}');

    } catch (e) {
      print('ÃƒÂ¢Ã‚ÂÃ…â€™ [MapaAventura] Erro ao resetar andar: $e');

      // Fecha o dialog de loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostra erro
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: const Text('NÃƒÆ’Ã‚Â£o foi possÃƒÆ’Ã‚Â­vel resetar o andar. Tente novamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

