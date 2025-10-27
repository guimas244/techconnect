import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../models/monstro_inimigo.dart';
import '../models/historia_jogador.dart';
import '../models/item.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../tipagem/data/tipagem_repository.dart';
import '../presentation/modal_monstro_inimigo.dart';
import '../presentation/selecao_monstro_screen.dart';
import '../presentation/casa_vigarista_screen.dart';
import '../presentation/models/resultado_loja.dart';
import '../presentation/modal_item_obtido.dart';
import '../presentation/modal_magia_obtida.dart';
import '../presentation/modal_cura_obtida.dart';
import '../presentation/modal_feirao.dart';
import '../presentation/modal_biblioteca.dart';
import '../models/magia_drop.dart';
import '../models/habilidade.dart';
import '../presentation/mochila_screen.dart';
import '../presentation/aventura_screen.dart';
import '../presentation/progresso_screen.dart';
import '../presentation/modal_tier11_transicao.dart';
import '../../../core/config/score_config.dart';

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

  String _aventuraTabKey() {
    if (historiaAtual == null) {
      return 'aventura_null';
    }
    final vidas = historiaAtual!.monstros.map((m) => m.vidaAtual).join('-');
    return 'aventura_${historiaAtual!.tier}_${historiaAtual!.score}_' + vidas;
  }

  @override
  void initState() {
    super.initState();
    _verificarAventuraIniciada();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega quando voltar da batalha
    if (!isLoading) {
      _recarregarHistoria();
    }
  }

  Future<void> _recarregarHistoria() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);

      final historia = await repository.carregarHistoricoJogador(emailJogador);

      if (historia != null && mounted) {
        setState(() {
          historiaAtual = historia;
        });
        print('🔄 [MapaAventura] História recarregada após batalha');
      }
    } catch (e) {
      print('❌ [MapaAventura] Erro ao recarregar história: $e');
    }
  }


  Future<void> _verificarAventuraIniciada() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      
      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Verificando aventura iniciada para: $emailJogador');
      
      // Carrega a história do jogador
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
            // Se há aventura iniciada, usa o mapa salvo
            mapaEscolhido = historia.mapaAventura!;
            print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Usando mapa salvo: $mapaEscolhido');
          } else {
            // Se não há aventura iniciada, sorteia um mapa aleatório
            final random = math.Random();
            mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
            print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Sorteou novo mapa: $mapaEscolhido');
          }

          isLoading = false;
        });
      } else {
        print('ÃƒÂ¢Ã‚ÂÃ…â€™ [MapaAventura] Nenhuma história encontrada');
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
    // Se há história carregada e aventura iniciada, usa os monstros da história
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Usando monstros da história: ${historiaAtual!.monstrosInimigos.length}');
      return historiaAtual!.monstrosInimigos;
    }
    
    // Caso contrário, usa os monstros passados por parâmetro
    print('ÃƒÂ°Ã…Â¸Ã¢â‚¬â€Ã‚ÂºÃƒÂ¯Ã‚Â¸Ã‚Â [MapaAventura] Usando monstros do parâmetro: ${widget.monstrosInimigos.length}');
    return widget.monstrosInimigos;
  }
  @override
  Widget build(BuildContext context) {
    // Observa mudanças no estado da aventura para recarregar quando necessário
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
          // Ícone de refresh - só aparece na aba MAPA
          if (_abaAtual == 1 && historiaAtual?.aventuraIniciada == true && _podeRefreshAndar())
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _refreshAndar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, color: Colors.green, size: 20),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${historiaAtual?.refreshsRestantes ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Conteúdo principal
            Expanded(
              child: _buildAbaAtual(),
            ),

            // Barra de abas inferior
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAbaAtual() {
    // Recarrega sempre que a aba muda - não usa IndexedStack para evitar cache
    switch (_abaAtual) {
      case 0:
        // ABA 0: EQUIPE (tela de seleção/início)
        return AventuraScreen(
          key: ValueKey('aventura_$_aventuraTabKey'),
        );
      case 1:
        // ABA 1: MAPA
        return _buildMapaView();
      case 2:
        // ABA 2: MOCHILA
        return MochilaScreen(
          key: const ValueKey('mochila'),
          historiaInicial: historiaAtual,
          onHistoriaAtualizada: (historiaAtualizada) async {
            setState(() {
              historiaAtual = historiaAtualizada;
            });

            try {
              final repository = ref.read(aventuraRepositoryProvider);
              // Salva APENAS no Hive local (sem sincronizar com Drive ao usar item da mochila)
              await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
              print('[Mochila] Historia atualizada apos uso de item (APENAS HIVE)');
            } catch (e) {
              print('[Mochila] Erro ao salvar historia: $e');
            }
          },
        );
      case 3:
        // ABA 3: LOJA
        return _buildLojaView();
      case 4:
        // ABA 4: PROGRESSO
        return const ProgressoScreen(
          key: ValueKey('progresso'),
        );
      default:
        return const Center(child: Text('Aba inválida'));
    }
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
                    'Mapa não encontrado',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
            // TIER, SCORE e botão avançar
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
            
        // Overlay de loading quando avançando tier
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

    return CasaVigaristaScreen(
      key: ValueKey('loja_${historiaAtual!.score}_${historiaAtual!.tier}_${historiaAtual!.monstros.map((m) => m.vidaAtual).join("_")}'),
      historia: historiaAtual!,
      onResultado: (ResultadoLoja resultado) async {
        print('📥 [Mapa] Recebeu resultado da loja inline: ${resultado.tipo}');
        if (resultado.tipo != TipoResultado.nenhum && mounted) {
          await _processarResultadoLoja(resultado);
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
              return; // Impede mudança de aba
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

    // Separa monstros de coleção dos demais
    final monstrosNormais = monstrosParaUsar.where((m) => !m.isRaro).toList();
    final monstrosColecao = monstrosParaUsar.where((m) => m.isRaro).toList();

    // Posições fixas dos pontos no mapa para monstros normais
    final posicoes = [
      (0.2, 0.2),   // Ponto 1 - Superior esquerdo
      (0.7, 0.15),  // Ponto 2 - Superior direito
      (0.5, 0.27),  // Ponto 3 - Centro
      (0.25, 0.38), // Ponto 4 - Inferior esquerdo
      (0.75, 0.47), // Ponto 5 - Inferior direito
      (0.5, 0.57),  // Ponto 6 - Elite (terceira linha, centro-inferior)
    ];

    // Adiciona pontos dos monstros normais
    for (int i = 0; i < posicoes.length && i < monstrosNormais.length; i++) {
      pontos.add(_buildPontoMapa(i, posicoes[i].$1, posicoes[i].$2, monstrosNormais));
    }

    // Casa do Vigarista agora está nas abas inferiores
    // pontos.add(_buildCasaDoVigarista(0.5, 0.25));

    // Adiciona monstros de coleção 3 centímetros abaixo do mercado
    for (int i = 0; i < monstrosColecao.length; i++) {
      final posX = 0.2 + (i * 0.6); // Posições 0.2, 0.8, etc. para múltiplos monstros
      pontos.add(_buildMonstroColecao(monstrosColecao[i], posX, 0.50)); // 0.25 + ~0.10 = 3cm abaixo
    }

    return pontos;
  }

  Widget _buildPontoMapa(int index, double left, double top, List<MonstroInimigo> monstros) {
    if (index >= monstros.length) {
      return const SizedBox.shrink();
    }

    final monstro = monstros[index];
    final bool estaMorto = monstro.vidaAtual <= 0;
    
    // Limita a posição máxima do topo para não colar na borda inferior
    // Ajustado para 0.75 para evitar sobreposição com a barra de abas
    final screenHeight = MediaQuery.of(context).size.height;
    final maxTop = screenHeight * 0.65;
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
    // Verifica se o jogador tem score suficiente (mínimo = 1 * tier atual)
    int tierAtual = historiaAtual?.tier ?? 1;
    int scoreAtual = historiaAtual?.score ?? 0;
    int custoMinimo = 1 * tierAtual;
    bool podeAcessar = scoreAtual >= custoMinimo;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final maxTop = screenHeight * 0.85;
    final calcTop = (screenHeight * top).clamp(0, maxTop).toDouble();
    
    return Positioned(
      left: MediaQuery.of(context).size.width * left - 35, // Centraliza o ícone
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

  void _mostrarCasaDoVigarista(bool podeAcessar, int custoMinimo) async {
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
                  'Você não possui score suficiente para acessar a Casa do Vigarista.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Score necessário: $custoMinimo pontos',
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

    // Abre a Casa do Vigarista como tela normal e aguarda resultado
    final resultado = await Navigator.of(context).push<ResultadoLoja>(
      MaterialPageRoute(
        builder: (context) => CasaVigaristaScreen(historia: historiaAtual!),
        fullscreenDialog: true,
      ),
    );

    // Processa o resultado
    if (resultado != null && resultado.tipo != TipoResultado.nenhum && mounted) {
      await _processarResultadoLoja(resultado);
    }
  }

  Future<void> _processarResultadoLoja(ResultadoLoja resultado) async {
    print('🛒 [Loja] Processando resultado: ${resultado.tipo}');

    // 1. Salva apenas localmente (HIVE) - SEM Drive
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      await repository.salvarHistoricoJogadorLocal(resultado.historiaAtualizada);
      print('✅ [Loja] História salva localmente (Hive apenas)');
    } catch (e) {
      print('❌ [Loja] Erro ao salvar história local: $e');
    }

    // 2. Atualiza estado local
    if (mounted) {
      setState(() {
        historiaAtual = resultado.historiaAtualizada;
      });
    }

    // 3. Aguarda um frame para garantir que a UI está estável
    print('⏳ [Loja] Aguardando UI estabilizar...');
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) {
      print('❌ [Loja] Widget desmontado, não abre modal');
      return;
    }

    // 4. Abre o modal apropriado baseado no tipo
    print('🎯 [Loja] Abrindo modal para tipo: ${resultado.tipo}');
    switch (resultado.tipo) {
      case TipoResultado.item:
        if (resultado.item != null) {
          print('📦 [Loja] Abrindo modal de equipar item: ${resultado.item!.nome}');
          await _mostrarModalEquiparItem(resultado.item!, resultado.historiaAtualizada);
        } else {
          print('❌ [Loja] Item é null!');
        }
        break;

      case TipoResultado.magia:
        if (resultado.habilidade != null) {
          await _mostrarModalEquiparMagia(resultado.habilidade!, resultado.historiaAtualizada);
        }
        break;

      case TipoResultado.cura:
        if (resultado.porcentagemCura != null) {
          await _mostrarModalCura(resultado.porcentagemCura!, resultado.historiaAtualizada);
        }
        break;

      case TipoResultado.abrirFeirao:
        if (resultado.itensFeirao != null) {
          await _mostrarModalFeirao(resultado.itensFeirao!, resultado.historiaAtualizada);
        }
        break;

      case TipoResultado.abrirBiblioteca:
        if (resultado.magiasBiblioteca != null) {
          await _mostrarModalBiblioteca(resultado.magiasBiblioteca!, resultado.historiaAtualizada);
        }
        break;

      case TipoResultado.roleta:
        // TODO: Implementar modal/tela da roleta de sorteio
        print('🎰 [Roleta] Resultado da roleta recebido');
        break;

      case TipoResultado.nenhum:
        break;
    }
  }

  Future<void> _mostrarModalEquiparItem(
    Item item,
    HistoriaJogador historia,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalItemObtido(
        item: item,
        monstrosDisponiveis: historia.monstros,
        onEquiparItem: (monstro, itemObtido) async {
          // Atualiza o monstro com o item equipado
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(itemEquipado: itemObtido);
            }
            return m;
          }).toList();

          final historiaAtualizada = historia.copyWith(
            monstros: monstrosAtualizados,
          );

          // Salva a história com o item equipado (apenas Hive)
          try {
            final repository = ref.read(aventuraRepositoryProvider);
            await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

            if (mounted) {
              setState(() {
                historiaAtual = historiaAtualizada;
              });
            }

            print('✅ [Loja] Item equipado e salvo localmente (Hive apenas)');
          } catch (e) {
            print('❌ [Loja] Erro ao salvar item equipado: $e');
          }

          // Fecha o modal
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _mostrarModalEquiparMagia(
    MagiaDrop magia,
    HistoriaJogador historia,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalMagiaObtida(
        magia: magia,
        monstrosDisponiveis: historia.monstros,
        onEquiparMagia: (monstro, magiaObtida, habilidadeSubstituida) async {
          // Encontra o monstro e substitui a habilidade
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              // Remove a habilidade antiga e adiciona a nova com tipagem do monstro
              final habilidadesAtualizadas = m.habilidades
                  .where((h) => h != habilidadeSubstituida)
                  .toList();

              // Escolhe o tipo elemental (50% cada tipo do monstro)
              final tipos = [m.tipo, m.tipoExtra];
              final tipoElemental = tipos[math.Random().nextInt(tipos.length)];

              // Cria a nova habilidade com a tipagem do monstro
              final novaHabilidade = Habilidade(
                nome: magiaObtida.nome,
                descricao: magiaObtida.descricao,
                tipo: magiaObtida.tipo,
                efeito: magiaObtida.efeito,
                tipoElemental: tipoElemental, // Sorteia entre os tipos do monstro (50% cada)
                valor: magiaObtida.valor,
                custoEnergia: magiaObtida.custoEnergia,
                level: magiaObtida.level,
              );

              habilidadesAtualizadas.add(novaHabilidade);

              return m.copyWith(habilidades: habilidadesAtualizadas);
            }
            return m;
          }).toList();

          final historiaAtualizada = historia.copyWith(
            monstros: monstrosAtualizados,
          );

          // Salva a história com a magia equipada (apenas Hive)
          try {
            final repository = ref.read(aventuraRepositoryProvider);
            await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

            if (mounted) {
              setState(() {
                historiaAtual = historiaAtualizada;
              });
            }

            print('✅ [Loja] Magia equipada e salva localmente (Hive apenas)');
          } catch (e) {
            print('❌ [Loja] Erro ao salvar magia equipada: $e');
          }

          // Fecha o modal
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _mostrarModalCura(
    int porcentagemCura,
    HistoriaJogador historia,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalCuraObtida(
        porcentagem: porcentagemCura,
        monstrosDisponiveis: historia.monstros,
        onCurarMonstro: (monstro, porcentagem) async {
          // Calcula a cura
          final vidaRecuperada = (monstro.vida * porcentagem / 100).round();
          final novaVida = (monstro.vidaAtual + vidaRecuperada).clamp(0, monstro.vida);

          // Atualiza o monstro com a vida curada
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(vidaAtual: novaVida);
            }
            return m;
          }).toList();

          final historiaAtualizada = historia.copyWith(
            monstros: monstrosAtualizados,
          );

          // Salva a história com a vida curada (apenas Hive)
          try {
            final repository = ref.read(aventuraRepositoryProvider);
            await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

            if (mounted) {
              setState(() {
                historiaAtual = historiaAtualizada;
              });
            }

            print('✅ [Loja] Monstro curado e salvo localmente (Hive apenas)');
          } catch (e) {
            print('❌ [Loja] Erro ao salvar cura: $e');
          }

          // Fecha o modal
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _mostrarModalFeirao(
    List<Item> itens,
    HistoriaJogador historia,
  ) async {
    print('🏪 [Loja] Abrindo modal do Feirão com ${itens.length} itens');

    final custoAposta = 2 * (historia.tier >= 11 ? 2 : historia.tier);

    final itemEscolhido = await showDialog<Item>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalFeirao(
        itens: itens,
        custoAposta: custoAposta,
        scoreAtual: historia.score,
      ),
    );

    if (itemEscolhido == null) {
      print('❌ [Loja] Usuário saiu do Feirão sem comprar');
      return;
    }

    print('💰 [Loja] Item escolhido no Feirão: ${itemEscolhido.nome}');

    // Debita o custo do item
    final historiaAtualizada = historia.copyWith(
      score: historia.score - custoAposta,
    );

    // Salva apenas localmente (Hive)
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
      print('✅ [Loja] Score debitado e salvo (Feirão)');
    } catch (e) {
      print('❌ [Loja] Erro ao salvar após compra do Feirão: $e');
    }

    // Atualiza estado local
    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });
    }

    // Aguarda um frame
    await Future.delayed(const Duration(milliseconds: 50));

    // Abre modal de equipar item
    if (mounted) {
      print('📦 [Loja] Abrindo modal de equipar item do Feirão');
      await _mostrarModalEquiparItem(itemEscolhido, historiaAtualizada);
    }
  }

  Future<void> _mostrarModalBiblioteca(
    List<MagiaDrop> magias,
    HistoriaJogador historia,
  ) async {
    print('📚 [Loja] Abrindo modal da Biblioteca com ${magias.length} magias');

    final custoAposta = 2 * (historia.tier >= 11 ? 2 : historia.tier);

    final magiaEscolhida = await showDialog<MagiaDrop>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalBiblioteca(
        magias: magias,
        custoAposta: custoAposta,
        scoreAtual: historia.score,
      ),
    );

    if (magiaEscolhida == null) {
      print('❌ [Loja] Usuário saiu da Biblioteca sem comprar');
      return;
    }

    print('💰 [Loja] Magia escolhida na Biblioteca: ${magiaEscolhida.nome}');

    // Debita o custo da magia
    final historiaAtualizada = historia.copyWith(
      score: historia.score - custoAposta,
    );

    // Salva apenas localmente (Hive)
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
      print('✅ [Loja] Score debitado e salvo (Biblioteca)');
    } catch (e) {
      print('❌ [Loja] Erro ao salvar após compra da Biblioteca: $e');
    }

    // Atualiza estado local
    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });
    }

    // Aguarda um frame
    await Future.delayed(const Duration(milliseconds: 50));

    // Abre modal de equipar magia
    if (mounted) {
      print('✨ [Loja] Abrindo modal de equipar magia da Biblioteca');
      await _mostrarModalEquiparMagia(magiaEscolhida, historiaAtualizada);
    }
  }

  Widget _buildMonstroColecao(MonstroInimigo monstro, double left, double top) {
    final bool estaMorto = monstro.vidaAtual <= 0;

    // Limita a posição máxima do topo para não colar na borda inferior
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
                : Colors.purple.withOpacity(0.9), // Cor especial para monstros de coleção
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.orange, // Cor dourada para monstros de coleção
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
        print('ÃƒÂ¢Ã‚ÂÃ…â€™ [ERRO] Não foi possível carregar dados de defesa para ${monstro.tipo.displayName}');
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
          onBattle: () async {
            Navigator.of(context).pop(); // Fecha o modal
            await _iniciarBatalha(monstro);
          },
        );
      },
    );
  }

    Future<void> _iniciarBatalha(MonstroInimigo monstroInimigo) async {
    // Verifica se a aventura expirou antes de iniciar batalha
    if (historiaAtual != null && historiaAtual!.aventuraExpirada) {
      print('[MapaAventura] Tentativa de batalhar com aventura expirada!');
      _mostrarModalAventuraExpirada();
      return;
    }

    final retorno = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SelecaoMonstroScreen(monstroInimigo: monstroInimigo),
      ),
    );

    if (!mounted) return;

    if (retorno == true) {
      await _verificarAventuraIniciada();
    }
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
      print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] historiaAtual não ÃƒÆ’Ã‚Â© null, continuando...');

      // Gera novos monstros para o próximo tier
      final novosMonstros = await _gerarNovosMonstrosParaTier(historiaAtual!.tier + 1);

      // Verifica se está transitando do tier 10 para o tier 11 (transição especial)
      final tierAtual = historiaAtual!.tier;
      final estaTransitandoParaTier11 = tierAtual == (ScoreConfig.SCORE_TIER_TRANSICAO - 1);
      final scoreAntesDaTransicao = historiaAtual!.score;

      int novoScore = historiaAtual!.score;

      if (estaTransitandoParaTier11) {
        // TRANSIÇÃO TIER 10 → 11: Conquista! Salva 50 pontos garantidos no ranking
        print('🏆 [MapaAventura] Transição tier $tierAtual → ${ScoreConfig.SCORE_TIER_TRANSICAO}');
        print('   - Score antes: $scoreAntesDaTransicao');
        print('   - Salvando no ranking com ${ScoreConfig.SCORE_PONTOS_GARANTIDOS_TIER_11} pontos GARANTIDOS (conquista tier 11)');

        // Cria cópia temporária com score fixado em 50 para salvar no ranking
        final historiaComScoreConquista = historiaAtual!.copyWith(
          score: ScoreConfig.SCORE_PONTOS_GARANTIDOS_TIER_11,
        );
        await repository.atualizarRankingPorScore(historiaComScoreConquista);

        // Reseta score para 0 (sistema tier 11+ começa do zero)
        novoScore = 0;
        print('   - Score resetado para: $novoScore');
      }

      // Atualiza a história com novo tier, novos monstros e score (resetado se transição tier 11)
      final historiaAtualizada = historiaAtual!.copyWith(
        tier: historiaAtual!.tier + 1,
        monstrosInimigos: novosMonstros,
        score: novoScore,
      );

      // Salva no repositório
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      // Atualiza o estado local
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      print('🏯 [MapaAventura] Tier avançado! Novo tier: ${historiaAtualizada.tier}, Score: ${historiaAtualizada.score}');

      // Mostra modal de transição tier 11 se aplicável
      if (estaTransitandoParaTier11 && mounted) {
        print('📢 [MapaAventura] Mostrando modal de transição para tier ${ScoreConfig.SCORE_TIER_TRANSICAO}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false, // Usuário deve ler a mensagem
              builder: (context) => ModalTier11Transicao(
                scoreAtual: scoreAntesDaTransicao,
              ),
            );
          }
        });
      }

    } catch (e) {
      print('ÃƒÂ¢Ã‚ÂÃ…â€™ [MapaAventura] Erro ao avançar tier: $e');
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

    // Chama o método público do repository para gerar novos monstros com itens
    final emailJogador = ref.read(validUserEmailProvider);
    final novosMonstros = await repository.gerarMonstrosInimigosPorTier(novoTier, emailJogador);

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
        return 'Tier 50: Equipamentos Lendários';
      default:
        return 'Aumento de Dificuldade';
    }
  }

  String _getMensagemDificuldadeDescricao(int tier) {
    switch (tier) {
      case 19:
        return 'A partir do tier 20, os inimigos não usarão mais itens inferiores. Apenas itens normais ou superiores serão equipados.';
      case 29:
        return 'A partir do tier 30, os inimigos não usarão mais itens normais. Apenas itens raros ou superiores serão equipados.';
      case 39:
        return 'A partir do tier 40, os inimigos não usarão mais itens raros. Apenas itens épicos ou superiores serão equipados.';
      case 49:
        return 'A partir do tier 50, os inimigos não usarão mais itens épicos. Apenas itens lendários serão equipados pelos inimigos.';
      default:
        return 'Os inimigos ficarão mais desafiadores a partir deste tier.';
    }
  }

  void _mostrarModalAvancarTier(bool podeAvancar, int monstrosMortos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Verificar se é o andar 10
        bool isAndar10 = historiaAtual?.tier == 10;

        // Verificar se é um dos tiers de aumento de dificuldade
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
                    ? (isAndar10 ? 'AVISO ESPECIAL - Andar 10' : (isTierDificuldade ? 'AUMENTO DE DIFICULDADE' : 'Avançar Tier'))
                    : 'Requisitos não atendidos',
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
                  // Mensagens específicas de aumento de dificuldade
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
                        const Text(
                          'Ao avançar para o andar 11:\n• Seu score será ZERADO (volta para 0)\n• Será salvo 50 pontos no ranking (conquista tier 11!)',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score atual: ${historiaAtual?.score ?? 0} pontos → Ficará: 0 pontos\nRanking: ${historiaAtual?.score ?? 0} pontos → Será salvo: 50 pontos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '⚠️ Outras mudanças importantes:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Monstros do andar 11+ darão 2 pontos por vitória'),
                  const Text('• A loja considerará preços como se fosse tier 2'),
                  const Text('• Novos monstros mais fortes aparecerão'),
                ] else ...[
                  // Aviso normal para outros andares
                  const Text(
                    '⚠️ ATENÇÃO: Ao avançar para o próximo tier:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('• Você não poderá retornar ao tier anterior'),
                  const Text('• Novos monstros mais fortes aparecerão'),
                  const Text('• Seu progresso atual será salvo'),
                  const SizedBox(height: 8),
                  const Text(
                    'Seu score atual será mantido.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'Você precisa derrotar pelo menos 3 monstros para avançar de tier.',
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
                  print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] Botão Confirmar clicado');
                  Navigator.of(context).pop();
                  print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] Modal fechado, chamando _avancarTier()');
                  _avancarTier();
                },
                child: Text(
                  isAndar10
                    ? ((historiaAtual?.score ?? 0) > 50 ? 'Avançar e Resetar' : 'Avançar (Score Mantido)')
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

              // Título
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
                'Sua aventura expirou após a meia-noite (horário de Brasília). Para continuar jogando, você precisa sortear novos monstros e começar uma nova aventura.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Container de informação adicional
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
                        'Aventuras são válidas apenas durante o dia em que foram criadas.',
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

              // Botão para voltar ÃƒÆ’Ã‚Â  tela de aventura
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

  /// Verifica se pode refresh do andar (não houve batalhas no andar atual e tem refreshs restantes)
  bool _podeRefreshAndar() {
    if (historiaAtual == null) return false;

    // Verifica se há batalhas no tier atual
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

                // Título
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

                // Container de informação adicional
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
                              'Seu progresso no tier será mantido.',
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
                              'Refreshs restantes após este: ${(historiaAtual?.refreshsRestantes ?? 1) - 1}',
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
      final emailJogador = ref.read(validUserEmailProvider);
      final novosMonstros = await repository.gerarMonstrosInimigosPorTier(historiaAtual!.tier, emailJogador);

      // Atualiza a história com novos monstros e decrementa refreshs
      final historiaAtualizada = historiaAtual!.copyWith(
        monstrosInimigos: novosMonstros,
        refreshsRestantes: historiaAtual!.refreshsRestantes - 1,
      );

      // Salva localmente
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      // Salva no Drive
      print('🎾 [MapaAventura] Salvando refresh no Drive...');
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
            content: const Text('Não foi possível resetar o andar. Tente novamente.'),
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






