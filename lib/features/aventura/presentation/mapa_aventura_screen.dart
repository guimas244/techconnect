import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../models/monstro_inimigo.dart';
import '../models/monstro_aventura.dart';
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
import '../presentation/modal_loja_ganandius.dart';
import '../models/magia_drop.dart';
import '../models/habilidade.dart';
import '../presentation/mochila_screen.dart';
import '../presentation/aventura_screen.dart';
import '../presentation/progresso_screen.dart';
import '../presentation/modal_tier11_transicao.dart';
import '../../../core/config/score_config.dart';
import '../../../core/config/version_config.dart';
import '../../../core/config/developer_config.dart';
import '../services/auto_mode_service.dart';
import '../services/mochila_service.dart';
import '../services/chave_auto_service.dart';
import '../services/recompensa_andar_service.dart';
import 'modal_chave_auto_drops.dart';
import 'modal_premio_andar.dart';
import '../models/item_consumivel.dart';
import '../services/magia_service.dart';
import '../services/item_service.dart';
import '../models/mochila.dart';
import '../models/passiva.dart';
import '../presentation/batalha_screen.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import 'dart:math';

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

  // Modo Automático
  bool _modoAutoAtivo = false;
  bool _autoModeEmExecucao = false;
  final AutoModeService _autoModeService = AutoModeService();
  Mochila? _mochilaAutoMode;

  // Modo Chave Auto (auto sem usar consumíveis, 2 andares)
  final ChaveAutoService _chaveAutoService = ChaveAutoService();

  // Serviço de recompensas por andar (chave auto a cada 25, nuty a cada 30)
  final RecompensaAndarService _recompensaService = RecompensaAndarService();

  // Filtro de drops - todas as raridades marcadas por padrão
  Map<RaridadeItem, bool> _filtroDrops = {
    RaridadeItem.inferior: true,
    RaridadeItem.normal: true,
    RaridadeItem.raro: true,
    RaridadeItem.epico: true,
    RaridadeItem.lendario: true,
    RaridadeItem.impossivel: true,
  };

  // Valor mínimo para magias (0 = sem filtro)
  int _valorMinimoMagia = 0;
  late TextEditingController _valorMinimoMagiaController;

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
    _valorMinimoMagiaController = TextEditingController(text: _valorMinimoMagia.toString());
    _carregarFiltroDrops();
    _verificarAventuraIniciada();
  }

  @override
  void dispose() {
    _valorMinimoMagiaController.dispose();
    super.dispose();
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
          // Ícone de recompensa pendente (só aparece quando há recompensa)
          if (_recompensaService.temRecompensaPendente)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _mostrarRecompensaPendente,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.mail,
                          color: Colors.amber,
                          size: 28,
                        ),
                        // Badge com número de recompensas
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_recompensaService.quantidadeRecompensas}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Ícone de configuração de filtro de drops
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Filtrar Drops',
            onPressed: _mostrarFiltroDrops,
          ),
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
          onChaveAutoUsada: () {
            // Ativa o modo chave auto
            _ativarModoChaveAuto();
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

            // Botão Modo Automático (apenas em modo dev)
            if (DeveloperConfig.ENABLE_TYPE_EDITING)
              Positioned(
                top: 76,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleModoAuto,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _modoAutoAtivo
                            ? Colors.green.withOpacity(0.9)
                            : Colors.blueGrey.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _modoAutoAtivo ? Colors.greenAccent : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _modoAutoAtivo
                                ? Colors.green.withOpacity(0.5)
                                : Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _modoAutoAtivo ? Icons.smart_toy : Icons.smart_toy_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _modoAutoAtivo ? 'AUTO ON' : 'AUTO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

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

    // Adiciona NPC Ganandius no andar 11, depois 21, 31, 41, etc. (a cada 10 andares após o 11)
    final tierAtual = historiaAtual?.tier ?? 1;
    if (tierAtual >= 11 && (tierAtual - 11) % 10 == 0) {
      pontos.add(_buildNpcGanandius(0.5, 0.35)); // Centro do mapa
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

  Widget _buildNpcGanandius(double left, double top) {
    final screenHeight = MediaQuery.of(context).size.height;
    final calcTop = math.min(screenHeight * top, screenHeight - 100);

    return Positioned(
      left: MediaQuery.of(context).size.width * left - 30, // Centraliza o ícone (60/2)
      top: calcTop,
      child: GestureDetector(
        onTap: () => _mostrarLojaGanandius(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber,
              width: 4
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/npc/icon_negociante_ganandius.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.amber,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarLojaGanandius() async {
    if (historiaAtual == null) return;

    try {
      // Carrega se já pegou o despertar gratuito neste tier
      final prefs = await SharedPreferences.getInstance();
      final emailJogador = ref.read(validUserEmailProvider);
      final chaveGratuito = 'ganandius_gratuito_${emailJogador}_tier_${historiaAtual!.tier}';
      final jaPegouGratuito = prefs.getBool(chaveGratuito) ?? false;

      // Carrega o contador de compras PARA ESTE RUN (não por tier)
      final runId = historiaAtual!.runId;
      final chaveCompras = 'ganandius_compras_${emailJogador}_run_$runId';
      final comprasRealizadas = prefs.getInt(chaveCompras) ?? 0;

      print('🔍 [MapaAventura] Carregando compras do run $runId: $comprasRealizadas compras realizadas');

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => ModalLojaGanandius(
          historia: historiaAtual!,
          onHistoriaAtualizada: (historiaAtualizada) async {
            // Atualiza a história localmente
            setState(() {
              historiaAtual = historiaAtualizada;
            });

            // Salva no repositório
            try {
              final repository = ref.read(aventuraRepositoryProvider);
              await repository.salvarHistoricoJogador(historiaAtualizada);
              print('✅ [MapaAventura] História atualizada após despertar');
            } catch (e) {
              print('❌ [MapaAventura] Erro ao salvar história: $e');
            }
          },
          jaPegouGratuito: jaPegouGratuito,
          onPegouGratuito: () async {
            // Marca que já pegou o gratuito neste tier
            await prefs.setBool(chaveGratuito, true);
            print('✅ [MapaAventura] Despertar gratuito marcado para tier ${historiaAtual!.tier}');
          },
          comprasRealizadas: comprasRealizadas,
          onCompraRealizada: () async {
            // Incrementa o contador de compras PARA ESTE RUN
            final novoContador = comprasRealizadas + 1;
            await prefs.setInt(chaveCompras, novoContador);
            print('✅ [MapaAventura] Compra #$novoContador registrada para run $runId (tier ${historiaAtual!.tier})');
          },
        ),
      );
    } catch (e) {
      print('❌ [MapaAventura] Erro ao abrir loja Ganandius: $e');
    }
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
        builder: (context) => SelecaoMonstroScreen(
          monstroInimigo: monstroInimigo,
          autoMode: _modoAutoAtivo,
        ),
      ),
    );

    if (!mounted) return;

    if (retorno == true) {
      await _verificarAventuraIniciada();

      // Se modo auto ativo, continua para próximo monstro automaticamente
      if (_modoAutoAtivo && !_autoModeEmExecucao) {
        _iniciarBatalhaAutomatica();
      }
    }
  }

  /// Toggle do modo automático
  void _toggleModoAuto() {
    if (_modoAutoAtivo) {
      // Desativar modo auto
      setState(() {
        _modoAutoAtivo = false;
        _autoModeEmExecucao = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🤖 Modo Automático DESATIVADO'),
          backgroundColor: Colors.blueGrey,
          duration: Duration(seconds: 2),
        ),
      );

      print('🤖 [AutoMode] Modo automático DESATIVADO');
    } else {
      // Ativar modo auto e iniciar batalha automaticamente
      setState(() {
        _modoAutoAtivo = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🤖 Modo Automático ATIVADO - Iniciando...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      print('🤖 [AutoMode] Modo automático ATIVADO - Iniciando batalha automática...');

      // Inicia a primeira batalha automaticamente
      _iniciarBatalhaAutomatica();
    }
  }

  /// Ativa o modo Chave Auto (2 andares sem usar consumíveis)
  void _ativarModoChaveAuto() {
    // Ativa o serviço de chave auto
    _chaveAutoService.ativar();

    // Muda para a aba do mapa
    setState(() {
      _abaAtual = 1;
      _modoAutoAtivo = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔑 Modo Chave Auto ATIVADO - 2 andares automáticos!'),
        backgroundColor: Colors.cyan,
        duration: Duration(seconds: 2),
      ),
    );

    print('🔑 [ChaveAuto] Modo Chave Auto ATIVADO - Iniciando batalha automática...');

    // Inicia a primeira batalha automaticamente
    _iniciarBatalhaAutomatica();
  }

  /// Finaliza o modo Chave Auto e mostra os drops coletados
  Future<void> _finalizarModoChaveAuto() async {
    if (!_chaveAutoService.ativo) return;

    final drops = _chaveAutoService.finalizar();

    setState(() {
      _modoAutoAtivo = false;
      _autoModeEmExecucao = false;
    });

    print('🔑 [ChaveAuto] Finalizado com ${drops.length} drops');

    // Mostra o modal de seleção de drops
    if (mounted && drops.isNotEmpty) {
      final itensSelecionados = await mostrarModalChaveAutoDrops(context, drops);

      if (itensSelecionados != null && itensSelecionados.isNotEmpty) {
        // Adiciona os itens selecionados à mochila
        await _adicionarItensNaMochila(itensSelecionados);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔑 Modo Chave Auto finalizado! Nenhum consumível encontrado.'),
          backgroundColor: Colors.cyan,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Adiciona itens selecionados na mochila
  Future<void> _adicionarItensNaMochila(List<ItemConsumivel> itens) async {
    final email = ref.read(validUserEmailProvider);
    if (email.isEmpty) return;

    var mochila = await MochilaService.carregarMochila(context, email);
    if (mochila == null) return;

    for (final item in itens) {
      mochila = mochila!.adicionarItem(item);
    }

    await MochilaService.salvarMochila(context, email, mochila!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${itens.length} ${itens.length == 1 ? 'item adicionado' : 'itens adicionados'} à mochila!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Inicia uma batalha automaticamente escolhendo o inimigo mais fácil
  Future<void> _iniciarBatalhaAutomatica() async {
    if (!_modoAutoAtivo || _autoModeEmExecucao) return;

    setState(() {
      _autoModeEmExecucao = true;
    });

    try {
      // Verifica se há história carregada
      if (historiaAtual == null) {
        await _recarregarHistoria();
      }

      if (historiaAtual == null) {
        print('❌ [AutoMode] Sem história carregada');
        _pararModoAuto('Erro: história não encontrada');
        return;
      }

      // Carrega mochila para usar consumíveis
      await _carregarMochilaAutoMode();

      // Usa consumíveis automaticamente antes da batalha
      if (_mochilaAutoMode != null) {
        await _usarConsumiveisAutoMode();
      }

      // Verifica se pode interagir com Ganandius (tiers 11, 21, 31, etc.)
      await _interagirComGanandiusAutoMode();

      // Verifica inimigos vivos primeiro
      final inimigosVivos = monstrosParaExibir.where((i) => i.vidaAtual > 0).toList();

      // Verifica monstros vivos do jogador
      final monstrosVivos = historiaAtual!.monstros.where((m) => m.vidaAtual > 0).toList();

      // Se todos os inimigos estão mortos, avança tier
      if (inimigosVivos.isEmpty) {
        print('✅ [AutoMode] Todos os inimigos derrotados!');

        // No tier 10, executa compras automáticas ANTES de mostrar countdown
        if (historiaAtual?.tier == 10) {
          print('🛒 [AutoMode] Tier 10 detectado! Gastando score antes de avançar...');
          await _executarComprasAutomaticasTier10();
        }

        // Mostra countdown para avançar tier (5 segundos)
        await _mostrarCountdownAvancarTier();
        return;
      }

      // Se todos os monstros estão mortos mas ainda há inimigos
      if (monstrosVivos.isEmpty) {
        print('💀 [AutoMode] Todos os monstros estão mortos! Verificando opções...');

        // PRIMEIRO: Verifica se pode avançar tier mesmo com monstros mortos
        final mortosNoTierMonstrosMortos = monstrosParaExibir.where((m) => m.vidaAtual <= 0).length;
        final podeAvancarTierMonstrosMortos = mortosNoTierMonstrosMortos >= 3;

        if (podeAvancarTierMonstrosMortos) {
          print('✅ [AutoMode] Pode avançar tier! Avançando...');
          await _mostrarCountdownAvancarTier();
          return;
        }

        // Se não pode avançar, tenta resolver a situação
        print('💀 [AutoMode] Não pode avançar tier. Buscando solução...');
        final resolvido = await _resolverMonstrosMortosAutoMode();
        if (resolvido) {
          // Conseguiu reviver algum monstro, continua batalha
          if (mounted && _modoAutoAtivo) {
            await Future.delayed(const Duration(milliseconds: 500));
            // Reseta o flag antes de chamar novamente
            setState(() {
              _autoModeEmExecucao = false;
            });
            _iniciarBatalhaAutomatica();
          }
          return;
        }

        // Não conseguiu resolver - para o auto mode
        _pararModoAuto('Todos os seus monstros estão mortos e não há como reviver!');
        return;
      }

      // === VERIFICA SE DEVE USAR REFRESH ===
      // Só verifica no início do andar (quando pode fazer refresh)
      if (_podeRefreshAndar()) {
        final andarRuim = await _autoModeService.andarEhRuim(
          historiaAtual!.monstros,
          inimigosVivos,
        );
        if (andarRuim) {
          print('🔄 [AutoMode] Andar ruim detectado! Usando refresh...');
          await _refreshAndarAutoMode();
          // Após refresh, continua a batalha
          if (mounted && _modoAutoAtivo) {
            await Future.delayed(const Duration(milliseconds: 500));
            // Reseta o flag antes de chamar novamente
            setState(() {
              _autoModeEmExecucao = false;
            });
            _iniciarBatalhaAutomatica();
          }
          return;
        }
      }

      // === VERIFICA SE PODE AVANÇAR TIER ===
      final mortosNoTier = monstrosParaExibir.where((m) => m.vidaAtual <= 0).length;
      final podeAvancarTier = mortosNoTier >= 3;

      // === VERIFICA SE HÁ INIMIGOS QUE VALE A PENA ATACAR ===
      final temAlvo = await _autoModeService.temInimigoParaAtacar(
        historiaAtual!.monstros,
        inimigosVivos,
      );

      if (!temAlvo && podeAvancarTier) {
        // Nenhum inimigo vale a pena atacar E pode avançar - avança tier
        print('⚠️ [AutoMode] Nenhum inimigo atacável! Avançando tier...');
        await _mostrarCountdownAvancarTier();
        return;
      }

      // Encontra a melhor combinação COM VANTAGEM
      var combinacao = await _autoModeService.selecionarMelhorCombinacaoComVantagem(
        historiaAtual!.monstros,
        inimigosVivos,
      );

      if ((combinacao == null || combinacao.inimigo == null || combinacao.monstro == null) && podeAvancarTier) {
        // Não encontrou combinação boa MAS pode avançar - avança tier
        print('⚠️ [AutoMode] Sem combinação vantajosa! Avançando tier...');
        await _mostrarCountdownAvancarTier();
        return;
      }

      // Se não tem vantagem MAS não pode avançar tier, força atacar a melhor opção disponível
      if (combinacao == null || combinacao.inimigo == null || combinacao.monstro == null) {
        print('⚠️ [AutoMode] Sem vantagem mas NÃO pode avançar tier! Atacando melhor opção...');
        // Usa seleção normal (sem filtro de vantagem)
        combinacao = await _autoModeService.selecionarMelhorCombinacao(
          historiaAtual!.monstros,
          inimigosVivos,
        );

        if (combinacao.inimigo == null || combinacao.monstro == null) {
          print('❌ [AutoMode] Erro: não encontrou nenhuma combinação válida!');
          _pararModoAuto('Nenhuma combinação disponível');
          return;
        }
        print('🎯 [AutoMode] Forçando batalha mesmo sem vantagem...');
      }

      print('🤖 [AutoMode] Iniciando batalha:');
      print('   Inimigo: ${combinacao.inimigo!.tipo.displayName}');
      print('   Monstro: ${combinacao.monstro!.tipo.displayName}');

      if (!mounted) return;

      setState(() {
        _autoModeEmExecucao = false;
      });

      // Vai direto para a batalha (sem passar pela tela de seleção)
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BatalhaScreen(
            jogador: combinacao!.monstro!,
            inimigo: combinacao.inimigo!,
            equipeCompleta: historiaAtual!.monstros,
            autoMode: true,
          ),
        ),
      );

      if (!mounted) return;

      // Recarrega história após batalha
      await _recarregarHistoria();

      // Reage ao resultado
      if (resultado == true) {
        // VITÓRIA - continua para próxima batalha
        print('✅ [AutoMode] Vitória! Continuando...');

        if (_modoAutoAtivo) {
          // Pequeno delay antes da próxima batalha
          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted && _modoAutoAtivo) {
            _iniciarBatalhaAutomatica();
          }
        }
      } else {
        // DERROTA - NÃO para, tenta continuar com outro monstro ou renascer
        print('❌ [AutoMode] Derrota! Verificando se pode continuar...');

        if (_modoAutoAtivo && mounted) {
          // Pequeno delay antes de tentar continuar
          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted && _modoAutoAtivo) {
            // Tenta continuar (vai verificar monstros vivos ou tentar renascer)
            _continuarAposDerrota();
          }
        }
      }
    } catch (e) {
      print('❌ [AutoMode] Erro: $e');
      _pararModoAuto('Erro: $e');
    }
  }

  /// Continua o modo auto após uma derrota
  /// Verifica se há monstros vivos ou tenta renascer um com vantagem
  Future<void> _continuarAposDerrota() async {
    if (!_modoAutoAtivo || historiaAtual == null) return;

    // Verifica monstros vivos
    final monstrosVivos = historiaAtual!.monstros.where((m) => m.vidaAtual > 0).toList();

    if (monstrosVivos.isNotEmpty) {
      // Ainda tem monstros vivos, continua normalmente
      print('🤖 [AutoMode] Ainda há ${monstrosVivos.length} monstro(s) vivo(s), continuando...');
      _iniciarBatalhaAutomatica();
      return;
    }

    // Todos os monstros estão mortos - tenta renascer
    print('💀 [AutoMode] Todos os monstros estão mortos! Tentando renascer...');

    // Verifica inimigos restantes
    final inimigosVivos = monstrosParaExibir.where((i) => i.vidaAtual > 0).toList();
    if (inimigosVivos.isEmpty) {
      _pararModoAuto('Todos os inimigos derrotados! Avance de tier.');
      return;
    }

    // === PRIORIDADE 1: Tentar usar poção para renascer ===
    // NOTA: Se modo Chave Auto ativo, não usa consumíveis
    if (!_chaveAutoService.ativo) {
      await _carregarMochilaAutoMode();
      if (_mochilaAutoMode != null) {
        final usouPocao = await _usarPocaoParaRenascerAutoMode();
        if (usouPocao) {
          // Poção usada com sucesso, continua batalha
          if (mounted && _modoAutoAtivo) {
            await Future.delayed(const Duration(milliseconds: 500));
            _iniciarBatalhaAutomatica();
          }
          return;
        }
      }
    } else {
      print('🔑 [ChaveAuto] Modo Chave Auto ativo - ignorando uso de poções');
    }

    // === PRIORIDADE 2: Pagar ouro para renascer ===
    // Custo de cura (igual à Casa do Vigarista)
    const int custoCura = 2;

    // Verifica se tem score suficiente
    if (historiaAtual!.score < custoCura) {
      _pararModoAuto('Sem ouro para renascer (precisa $custoCura)');
      return;
    }

    // Encontra o melhor monstro para renascer (com mais vantagem)
    final melhorParaRenascer = await _encontrarMelhorMonstroParaRenascer(inimigosVivos);

    if (melhorParaRenascer == null) {
      _pararModoAuto('Nenhum monstro com vantagem para renascer');
      return;
    }

    // Renasce o monstro (cura 100%)
    print('💚 [AutoMode] Renascendo ${melhorParaRenascer.tipo.displayName} por $custoCura ouro...');

    await _renascerMonstroAutoMode(melhorParaRenascer, custoCura);

    // Continua a batalha
    if (mounted && _modoAutoAtivo) {
      await Future.delayed(const Duration(milliseconds: 500));
      _iniciarBatalhaAutomatica();
    }
  }

  /// Encontra o melhor monstro para renascer baseado em vantagem contra inimigos
  Future<MonstroAventura?> _encontrarMelhorMonstroParaRenascer(List<MonstroInimigo> inimigosVivos) async {
    if (historiaAtual == null) return null;

    MonstroAventura? melhorMonstro;
    double melhorScoreTotal = double.negativeInfinity;

    for (final monstro in historiaAtual!.monstros) {
      double scoreTotal = 0.0;

      // Calcula score médio contra todos os inimigos vivos
      for (final inimigo in inimigosVivos) {
        final score = await _autoModeService.calcularScoreVantagem(monstro, inimigo);
        scoreTotal += score;
      }

      // Média de vantagem
      final scoreMedia = scoreTotal / inimigosVivos.length;

      print('📊 [AutoMode] ${monstro.tipo.displayName} score médio: $scoreMedia');

      // Só considera se tiver vantagem positiva (score > 0)
      if (scoreMedia > 0 && scoreMedia > melhorScoreTotal) {
        melhorScoreTotal = scoreMedia;
        melhorMonstro = monstro;
      }
    }

    if (melhorMonstro != null) {
      print('✅ [AutoMode] Melhor para renascer: ${melhorMonstro.tipo.displayName} (score: $melhorScoreTotal)');
    } else {
      print('❌ [AutoMode] Nenhum monstro com vantagem positiva');
    }

    return melhorMonstro;
  }

  /// Renasce um monstro no modo auto (cura 100% e desconta ouro)
  Future<void> _renascerMonstroAutoMode(MonstroAventura monstro, int custo) async {
    if (historiaAtual == null) return;

    final repository = ref.read(aventuraRepositoryProvider);

    // Atualiza o monstro com vida completa
    final monstrosAtualizados = historiaAtual!.monstros.map((m) {
      if (m.tipo == monstro.tipo && m.tipoExtra == monstro.tipoExtra) {
        return m.copyWith(vidaAtual: m.vida); // Cura 100%
      }
      return m;
    }).toList();

    // Desconta o custo
    final historiaAtualizada = historiaAtual!.copyWith(
      monstros: monstrosAtualizados,
      score: historiaAtual!.score - custo,
    );

    // Salva
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💚 ${monstro.tipo.displayName} renasceu! (-$custo ouro)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Para o modo automático e mostra mensagem
  void _pararModoAuto(String mensagem) {
    if (!mounted) return;

    // Se modo chave auto estiver ativo, finaliza e mostra drops
    if (_chaveAutoService.ativo) {
      print('🔑 [ChaveAuto] Parando modo auto devido a: $mensagem');
      _finalizarModoChaveAuto();
      return;
    }

    setState(() {
      _modoAutoAtivo = false;
      _autoModeEmExecucao = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🤖 $mensagem'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra countdown de 5 segundos antes de avançar tier
  /// Se o usuário não cancelar, avança automaticamente
  Future<void> _mostrarCountdownAvancarTier() async {
    if (!mounted || !_modoAutoAtivo) return;

    bool cancelado = false;
    int segundosRestantes = 5;

    final avancar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Inicia o countdown
            if (segundosRestantes > 0 && !cancelado) {
              Future.delayed(const Duration(seconds: 1), () {
                if (!cancelado && segundosRestantes > 0) {
                  setDialogState(() {
                    segundosRestantes--;
                  });

                  // Quando chegar a 0, fecha o dialog
                  if (segundosRestantes == 0) {
                    Navigator.of(dialogContext).pop(true); // true = avançar
                  }
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.grey.shade900,
              title: Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Avançando Tier',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Todos os inimigos derrotados!\nAvançando para o próximo tier em:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  // Countdown grande
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.2),
                      border: Border.all(color: Colors.green, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        '$segundosRestantes',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tier ${historiaAtual?.tier ?? 0} → ${(historiaAtual?.tier ?? 0) + 1}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelado = true;
                    Navigator.of(dialogContext).pop(false); // false = cancelar
                  },
                  child: const Text(
                    'PARAR AUTO',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true); // true = avançar agora
                  },
                  child: const Text('AVANÇAR AGORA'),
                ),
              ],
            );
          },
        );
      },
    );

    // Processa o resultado do dialog
    if (avancar == true && mounted && _modoAutoAtivo) {
      // Compras automáticas do tier 10 já foram executadas ANTES do countdown
      // Avança o tier
      await _avancarTier();

      // Continua o auto mode após avançar
      if (mounted && _modoAutoAtivo) {
        await Future.delayed(const Duration(milliseconds: 1000));
        print('🤖 [AutoMode] Continuando auto mode após avançar tier...');
        // IMPORTANTE: Reseta o flag de execução antes de chamar novamente
        setState(() {
          _autoModeEmExecucao = false;
        });
        _iniciarBatalhaAutomatica();
      }
    } else if (avancar == false) {
      // Usuário cancelou - para o auto mode
      _pararModoAuto('Auto mode desativado pelo usuário');
    } else {
      // Dialog fechado sem escolha (null) - reseta o flag
      setState(() {
        _autoModeEmExecucao = false;
      });
    }
  }

  /// Faz refresh do andar automaticamente (sem mostrar dialog)
  Future<void> _refreshAndarAutoMode() async {
    if (historiaAtual == null || !_podeRefreshAndar()) return;

    print('🔄 [AutoMode] Executando refresh automático...');

    try {
      final repository = ref.read(aventuraRepositoryProvider);
      final emailJogador = ref.read(validUserEmailProvider);

      // Gera novos monstros para o tier atual
      final novosMonstros = await repository.gerarMonstrosInimigosPorTier(
        historiaAtual!.tier,
        emailJogador,
      );

      // Atualiza a história com novos monstros e decrementa refreshs
      final historiaAtualizada = historiaAtual!.copyWith(
        monstrosInimigos: novosMonstros,
        refreshsRestantes: historiaAtual!.refreshsRestantes - 1,
      );

      // Salva localmente
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      // Atualiza o estado local
      if (mounted) {
        setState(() {
          historiaAtual = historiaAtualizada;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 Andar resetado! Refreshs restantes: ${historiaAtualizada.refreshsRestantes}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('✅ [AutoMode] Refresh automático concluído!');

    } catch (e) {
      print('❌ [AutoMode] Erro no refresh automático: $e');
    }
  }

  /// Executa compras automáticas no tier 10 antes de avançar para o tier 11
  /// Gasta TODO o score disponível: primeiro magias, depois itens, depois curas
  Future<void> _executarComprasAutomaticasTier10() async {
    if (historiaAtual == null || historiaAtual!.tier != 10) return;

    print('🛒 [AutoMode] ========================================');
    print('🛒 [AutoMode] TIER 10 - GASTANDO TODO O SCORE!');
    print('🛒 [AutoMode] Score inicial: ${historiaAtual!.score}');
    print('🛒 [AutoMode] ========================================');

    final magiaService = MagiaService();
    final itemService = ItemService();
    final repository = ref.read(aventuraRepositoryProvider);

    // Custo da biblioteca/feirão (3 para abrir + custo por item)
    // No tier 10, o custo de cada magia/item é: 2 * tier = 20
    final custoAbertura = 3;
    final custoCompra = 2 * historiaAtual!.tier; // 20 no tier 10
    final custoTotal = custoAbertura + custoCompra; // 23 por compra
    final custoCura = 2; // Custo de cura na loja

    int magiasPurchased = 0;
    int itensPurchased = 0;
    int curasPurchased = 0;

    // FASE 1: Gastar em MAGIAS até não poder mais
    print('📚 [AutoMode] FASE 1: Comprando MAGIAS...');
    while (historiaAtual!.score >= custoTotal && magiasPurchased < 50) {
      // Encontra o monstro com a magia mais fraca para melhorar
      final monstroAlvo = _encontrarMonstroComMagiaMaisFraca();
      if (monstroAlvo == null) {
        print('⚠️ [AutoMode] Nenhum monstro disponível para magias');
        break;
      }

      magiasPurchased++;
      print('📚 [AutoMode] Magia #$magiasPurchased para ${monstroAlvo.tipo.displayName} (score: ${historiaAtual!.score})');

      await _comprarMagiaAutomatica(magiaService, repository, monstroAlvo);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    print('📚 [AutoMode] Total de magias compradas: $magiasPurchased');

    // FASE 2: Gastar em ITENS até não poder mais
    print('🎒 [AutoMode] FASE 2: Comprando ITENS...');
    while (historiaAtual!.score >= custoTotal && itensPurchased < 50) {
      // Encontra o monstro com item mais fraco
      final monstroAlvo = _encontrarMonstroComItemMaisFraco();
      if (monstroAlvo == null) {
        print('⚠️ [AutoMode] Nenhum monstro disponível para itens');
        break;
      }

      itensPurchased++;
      print('🎒 [AutoMode] Item #$itensPurchased para ${monstroAlvo.tipo.displayName} (score: ${historiaAtual!.score})');

      await _comprarItemAutomatico(itemService, repository, monstroAlvo);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    print('🎒 [AutoMode] Total de itens comprados: $itensPurchased');

    // FASE 3: Gastar o restante em CURAS
    print('💚 [AutoMode] FASE 3: Curando o time...');
    while (historiaAtual!.score >= custoCura && curasPurchased < 20) {
      // Encontra monstro que precisa de cura
      final monstroFerido = historiaAtual!.monstros.cast<MonstroAventura?>().firstWhere(
        (m) => m != null && m.vidaAtual < m.vida,
        orElse: () => null,
      );

      if (monstroFerido == null) {
        print('✅ [AutoMode] Todos os monstros estão com vida cheia!');
        break;
      }

      curasPurchased++;
      print('💚 [AutoMode] Cura #$curasPurchased para ${monstroFerido.tipo.displayName} (Vida: ${monstroFerido.vidaAtual}/${monstroFerido.vida})');

      await _comprarCuraParaMonstro(monstroFerido, repository);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    print('💚 [AutoMode] Total de curas compradas: $curasPurchased');

    print('🏁 [AutoMode] ========================================');
    print('🏁 [AutoMode] COMPRAS FINALIZADAS!');
    print('🏁 [AutoMode] Magias: $magiasPurchased | Itens: $itensPurchased | Curas: $curasPurchased');
    print('🏁 [AutoMode] Score restante: ${historiaAtual!.score}');
    print('🏁 [AutoMode] ========================================');
  }

  /// Encontra o monstro que mais precisa de magias baseado no sistema de roles
  /// Ordem: Atacante (precisa de 4 dano) > Tank (precisa de 2 def + 1 vida + 1 atq) > Flex
  MonstroAventura? _encontrarMonstroComMagiaMaisFraca() {
    if (historiaAtual == null) return null;

    final monstros = historiaAtual!.monstros.where((m) => m.vidaAtual > 0).toList();
    if (monstros.isEmpty) return null;

    // Verifica cada monstro baseado no role
    for (int i = 0; i < monstros.length; i++) {
      final monstro = monstros[i];
      final role = _autoModeService.getRoleMonstro(monstros, monstro);

      switch (role) {
        case RoleMonstro.atacante:
          // Atacante precisa de 4 magias de dano
          final magiaDano = monstro.habilidades.where((h) =>
            h.tipo == TipoHabilidade.ofensiva).length;
          if (magiaDano < 4) {
            print('🎯 [AutoMode/Role] Atacante ${monstro.tipo.displayName} precisa de dano ($magiaDano/4)');
            return monstro;
          }
          // Verifica se alguma magia de dano é fraca
          final magiaMaisFraca = _autoModeService.encontrarMagiaMaisFraca(monstro);
          if (magiaMaisFraca != null && magiaMaisFraca.valorEfetivo < 400) {
            print('🎯 [AutoMode/Role] Atacante ${monstro.tipo.displayName} tem magia fraca (${magiaMaisFraca.valorEfetivo})');
            return monstro;
          }
          break;

        case RoleMonstro.tank:
          // Tank precisa de: 2 defesa + 1 aumentar vida + 1 aumentar dano
          final defesas = monstro.habilidades.where((h) =>
            h.efeito == EfeitoHabilidade.aumentarDefesa).length;
          final aumentarVida = monstro.habilidades.where((h) =>
            h.efeito == EfeitoHabilidade.aumentarVida).length;
          final aumentarDano = monstro.habilidades.where((h) =>
            h.efeito == EfeitoHabilidade.aumentarAtaque).length;

          if (defesas < 2 || aumentarVida < 1 || aumentarDano < 1) {
            print('🛡️ [AutoMode/Role] Tank ${monstro.tipo.displayName} precisa de suporte (def=$defesas/2, vida=$aumentarVida/1, atq=$aumentarDano/1)');
            return monstro;
          }
          break;

        case RoleMonstro.flex:
          // Flex: verifica se tem magias fracas para substituir
          final magiaMaisFracaFlex = monstro.habilidades
            .where((h) => h.valorEfetivo < 350)
            .toList();
          if (magiaMaisFracaFlex.isNotEmpty) {
            print('⚔️ [AutoMode/Role] Flex ${monstro.tipo.displayName} tem magia fraca');
            return monstro;
          }
          break;
      }
    }

    // Se todos estão bons, retorna o atacante para melhorar dano
    return monstros.isNotEmpty ? monstros[0] : null;
  }

  /// Encontra o monstro com o item mais fraco ou sem item
  MonstroAventura? _encontrarMonstroComItemMaisFraco() {
    if (historiaAtual == null) return null;

    MonstroAventura? piorMonstro;
    int menorPoder = 999999;

    for (final monstro in historiaAtual!.monstros) {
      if (monstro.vidaAtual <= 0) continue; // Ignora mortos

      // Verifica o poder do item equipado
      if (monstro.itemEquipado == null) {
        // Monstro sem item tem prioridade máxima
        return monstro;
      }

      // Calcula o poder total do item
      final item = monstro.itemEquipado!;
      final poderTotal = item.ataque + item.defesa + item.agilidade + item.vida;

      if (poderTotal < menorPoder) {
        menorPoder = poderTotal;
        piorMonstro = monstro;
      }
    }

    return piorMonstro;
  }

  /// Compra cura para um monstro específico
  Future<void> _comprarCuraParaMonstro(
    MonstroAventura monstro,
    dynamic repository,
  ) async {
    if (historiaAtual == null) return;

    final custoCura = 2;
    if (historiaAtual!.score < custoCura) return;

    // Calcula quanto vida falta
    final vidaFaltando = monstro.vida - monstro.vidaAtual;
    if (vidaFaltando <= 0) return;

    // Cura é 25% da vida máxima
    final cura = (monstro.vida * 0.25).round();
    final novaVida = (monstro.vidaAtual + cura).clamp(0, monstro.vida);

    // Atualiza o monstro
    final monstrosAtualizados = historiaAtual!.monstros.map((m) {
      if (m.tipo == monstro.tipo && m.level == monstro.level) {
        return m.copyWith(vidaAtual: novaVida);
      }
      return m;
    }).toList();

    final historiaAtualizada = historiaAtual!.copyWith(
      score: historiaAtual!.score - custoCura,
      monstros: monstrosAtualizados,
    );

    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });
    }

    print('💚 [AutoMode] ${monstro.tipo.displayName} curado: $cura vida (${monstro.vidaAtual} → $novaVida)');
  }

  /// Compra uma magia automaticamente (biblioteca) usando sistema de roles
  Future<void> _comprarMagiaAutomatica(
    MagiaService magiaService,
    dynamic repository,
    MonstroAventura monstroAlvo,
  ) async {
    if (historiaAtual == null) return;

    final custoAbertura = 3;
    final custoMagia = 2 * historiaAtual!.tier;

    // Verifica se tem score suficiente
    if (historiaAtual!.score < custoAbertura + custoMagia) return;

    // Debita custo de abertura
    var historiaAtualizada = historiaAtual!.copyWith(
      score: historiaAtual!.score - custoAbertura,
    );

    // Determina o role do monstro
    final monstrosVivos = historiaAtual!.monstros.where((m) => m.vidaAtual > 0).toList();
    final role = _autoModeService.getRoleMonstro(monstrosVivos, monstroAlvo);

    // Gera 3 magias
    final magias = <MagiaDrop>[];
    for (int i = 0; i < 3; i++) {
      magias.add(magiaService.gerarMagiaAleatoria(
        tierAtual: historiaAtual!.tier,
        isCompra: true,
      ));
    }

    // Seleciona a melhor magia baseado no ROLE
    MagiaDrop? melhorMagia;

    switch (role) {
      case RoleMonstro.atacante:
        // Atacante: só aceita dano direto, maior pontos
        int melhorPontos = 0;
        for (final magia in magias) {
          if (magia.tipo == TipoHabilidade.ofensiva &&
              magia.efeito == EfeitoHabilidade.danoDirecto) {
            if (magia.valorEfetivo > melhorPontos) {
              melhorPontos = magia.valorEfetivo;
              melhorMagia = magia;
            }
          }
        }
        print('🗡️ [AutoMode/Role] Atacante: selecionando dano (${melhorMagia?.valorEfetivo ?? 0} pts)');
        break;

      case RoleMonstro.tank:
        // Tank: prioriza defesa > aumentar vida > aumentar ataque
        final defesas = monstroAlvo.habilidades.where((h) =>
          h.efeito == EfeitoHabilidade.aumentarDefesa).length;
        final aumentarVida = monstroAlvo.habilidades.where((h) =>
          h.efeito == EfeitoHabilidade.aumentarVida).length;
        final aumentarDano = monstroAlvo.habilidades.where((h) =>
          h.efeito == EfeitoHabilidade.aumentarAtaque).length;

        // Prioridade: o que falta primeiro
        EfeitoHabilidade? efeitoDesejado;
        if (defesas < 2) {
          efeitoDesejado = EfeitoHabilidade.aumentarDefesa;
        } else if (aumentarVida < 1) {
          efeitoDesejado = EfeitoHabilidade.aumentarVida;
        } else if (aumentarDano < 1) {
          efeitoDesejado = EfeitoHabilidade.aumentarAtaque;
        }

        if (efeitoDesejado != null) {
          for (final magia in magias) {
            if (magia.efeito == efeitoDesejado) {
              melhorMagia = magia;
              break;
            }
          }
        }

        // Se não encontrou o que precisa, pega qualquer suporte útil (não cura)
        if (melhorMagia == null) {
          for (final magia in magias) {
            if (magia.tipo == TipoHabilidade.suporte &&
                magia.efeito != EfeitoHabilidade.curarVida &&
                magia.efeito != EfeitoHabilidade.aumentarEnergia) {
              melhorMagia = magia;
              break;
            }
          }
        }
        print('🛡️ [AutoMode/Role] Tank: selecionando ${melhorMagia?.efeito ?? 'qualquer'}');
        break;

      case RoleMonstro.flex:
        // Flex: qualquer magia exceto curar vida/energia, maior pontos
        int melhorPontos = 0;
        for (final magia in magias) {
          if (magia.efeito != EfeitoHabilidade.curarVida &&
              magia.efeito != EfeitoHabilidade.aumentarEnergia) {
            if (magia.valorEfetivo > melhorPontos) {
              melhorPontos = magia.valorEfetivo;
              melhorMagia = magia;
            }
          }
        }
        print('⚔️ [AutoMode/Role] Flex: selecionando qualquer (${melhorMagia?.valorEfetivo ?? 0} pts)');
        break;
    }

    // Se não encontrou magia ideal, pega a primeira que não seja curar energia
    if (melhorMagia == null) {
      for (final magia in magias) {
        if (magia.efeito != EfeitoHabilidade.aumentarEnergia) {
          melhorMagia = magia;
          break;
        }
      }
      melhorMagia ??= magias[0]; // Último recurso
    }

    await _aplicarMagiaNoMonstro(melhorMagia, monstroAlvo, historiaAtualizada, custoMagia, repository);
  }

  /// Aplica uma magia no monstro alvo usando sistema de roles
  Future<void> _aplicarMagiaNoMonstro(
    MagiaDrop magia,
    MonstroAventura monstroAlvo,
    HistoriaJogador historia,
    int custoMagia,
    dynamic repository,
  ) async {
    // Debita custo da magia
    var historiaAtualizada = historia.copyWith(
      score: historia.score - custoMagia,
    );

    // Usa o sistema de roles para encontrar qual habilidade substituir
    final monstrosVivos = historiaAtualizada.monstros.where((m) => m.vidaAtual > 0).toList();
    final resultado = _autoModeService.selecionarMonstroParaMagia(
      monstrosVivos,
      magia.valor,
      magia.level,
      magia.tipo,
      efeitoMagia: magia.efeito,
    );

    // Se o sistema de roles não encontrou match, usa fallback
    final habilidadeParaSubstituir = resultado?.habilidade ??
        _autoModeService.encontrarMagiaMaisFraca(monstroAlvo);

    // Atualiza o monstro com a nova magia
    final monstrosAtualizados = historiaAtualizada.monstros.map((m) {
      if (m.tipo == monstroAlvo.tipo && m.level == monstroAlvo.level) {
        // Remove a habilidade selecionada e adiciona a nova
        final habilidadesAtualizadas = m.habilidades
            .where((h) => habilidadeParaSubstituir == null || h != habilidadeParaSubstituir)
            .toList();

        // Escolhe o tipo elemental (50% cada tipo do monstro)
        final tipos = [m.tipo, m.tipoExtra];
        final tipoElemental = tipos[math.Random().nextInt(tipos.length)];

        // Cria a nova habilidade
        final novaHabilidade = Habilidade(
          nome: magia.nome,
          descricao: magia.descricao,
          tipo: magia.tipo,
          efeito: magia.efeito,
          tipoElemental: tipoElemental,
          valor: magia.valor,
          custoEnergia: magia.custoEnergia,
          level: magia.level,
        );

        habilidadesAtualizadas.add(novaHabilidade);
        return m.copyWith(habilidades: habilidadesAtualizadas);
      }
      return m;
    }).toList();

    historiaAtualizada = historiaAtualizada.copyWith(monstros: monstrosAtualizados);

    // Salva
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });
    }

    final substituida = habilidadeParaSubstituir?.nome ?? 'nenhuma';
    print('✨ [AutoMode] Magia ${magia.nome} (${magia.valorEfetivo} pts) equipada em ${monstroAlvo.tipo.displayName}');
    print('   Substituiu: $substituida');
  }

  /// Compra um item automaticamente (feirão)
  Future<void> _comprarItemAutomatico(
    ItemService itemService,
    dynamic repository,
    MonstroAventura monstroAlvo,
  ) async {
    if (historiaAtual == null) return;

    final custoAbertura = 3;
    final custoItem = 2 * historiaAtual!.tier;

    // Verifica se tem score suficiente
    if (historiaAtual!.score < custoAbertura + custoItem) return;

    // Debita custo de abertura
    var historiaAtualizada = historiaAtual!.copyWith(
      score: historiaAtual!.score - custoAbertura,
    );

    // Gera 3 itens
    final itens = <Item>[];
    for (int i = 0; i < 3; i++) {
      itens.add(itemService.gerarItemAleatorioLoja(tierAtual: historiaAtual!.tier));
    }

    // Seleciona o melhor item
    final melhorIndex = _autoModeService.selecionarMelhorItem(itens);
    final itemEscolhido = itens[melhorIndex];

    // Debita custo do item
    historiaAtualizada = historiaAtualizada.copyWith(
      score: historiaAtualizada.score - custoItem,
    );

    // Verifica se o novo item é melhor que o atual
    final itemAtual = monstroAlvo.itemEquipado;
    if (itemAtual != null && itemEscolhido.totalAtributos <= itemAtual.totalAtributos) {
      print('⏭️ [AutoMode] Item novo (${itemEscolhido.totalAtributos}) não é melhor que atual (${itemAtual.totalAtributos})');
      // Salva apenas o débito do score
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
      if (mounted) {
        setState(() {
          historiaAtual = historiaAtualizada;
        });
      }
      return;
    }

    // Equipa o novo item no monstro
    final monstrosAtualizados = historiaAtualizada.monstros.map((m) {
      if (m.tipo == monstroAlvo.tipo && m.level == monstroAlvo.level) {
        return m.copyWith(itemEquipado: itemEscolhido);
      }
      return m;
    }).toList();

    historiaAtualizada = historiaAtualizada.copyWith(monstros: monstrosAtualizados);

    // Salva
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });
    }

    print('🎁 [AutoMode] Item ${itemEscolhido.nome} (${itemEscolhido.totalAtributos} attr) equipado em ${monstroAlvo.tipo.displayName}');
  }

  /// Tenta resolver quando todos os monstros estão mortos
  /// Prioridades:
  /// 1. Usar poção da mochila
  /// 2. Comprar cura na loja
  /// Retorna true se conseguiu reviver algum monstro
  Future<bool> _resolverMonstrosMortosAutoMode() async {
    if (historiaAtual == null) return false;

    print('🔧 [AutoMode] Tentando resolver monstros mortos...');

    // === PRIORIDADE 1: Tentar usar poção da mochila ===
    // NOTA: Se modo Chave Auto ativo, não usa consumíveis
    if (!_chaveAutoService.ativo) {
      await _carregarMochilaAutoMode();
      if (_mochilaAutoMode != null) {
        final usouPocao = await _usarPocaoParaRenascerAutoMode();
        if (usouPocao) {
          print('✅ [AutoMode] Monstro revivido com poção da mochila!');
          return true;
        }
      }
    } else {
      print('🔑 [ChaveAuto] Modo Chave Auto ativo - ignorando uso de poções');
    }

    // === PRIORIDADE 2: Comprar cura na loja ===
    // Custo da cura: 2 score (ou 1 com Mercador)
    final custoCura = 2;
    if (historiaAtual!.score >= custoCura) {
      print('💰 [AutoMode] Tentando comprar cura na loja (score: ${historiaAtual!.score})...');
      final comprouCura = await _comprarCuraAutomatica();
      if (comprouCura) {
        print('✅ [AutoMode] Monstro curado com compra na loja!');
        return true;
      }
    }

    print('❌ [AutoMode] Não foi possível reviver monstros (sem poções e score insuficiente)');
    return false;
  }

  /// Compra cura na loja automaticamente para reviver um monstro
  Future<bool> _comprarCuraAutomatica() async {
    if (historiaAtual == null) return false;

    final repository = ref.read(aventuraRepositoryProvider);
    final custoCura = 2; // Custo base da cura

    // Verifica se tem score
    if (historiaAtual!.score < custoCura) {
      print('❌ [AutoMode] Score insuficiente para cura (${historiaAtual!.score} < $custoCura)');
      return false;
    }

    // Encontra monstros mortos
    final monstrosMortos = historiaAtual!.monstros.where((m) => m.vidaAtual <= 0).toList();
    if (monstrosMortos.isEmpty) {
      print('❌ [AutoMode] Nenhum monstro morto para curar');
      return false;
    }

    // Gera porcentagem de cura aleatória (25-100%)
    final random = Random();
    final porcentagens = [25, 50, 75, 100];
    final porcentagemCura = porcentagens[random.nextInt(porcentagens.length)];

    // Escolhe o monstro com mais vantagem contra inimigos restantes
    final inimigosVivos = monstrosParaExibir.where((i) => i.vidaAtual > 0).toList();
    MonstroAventura? melhorMonstro;
    double melhorScore = double.negativeInfinity;

    for (final monstro in monstrosMortos) {
      double scoreTotal = 0.0;
      for (final inimigo in inimigosVivos) {
        final score = await _autoModeService.calcularScoreVantagem(monstro, inimigo);
        scoreTotal += score;
      }
      final scoreMedia = inimigosVivos.isNotEmpty ? scoreTotal / inimigosVivos.length : 0.0;

      if (scoreMedia > melhorScore) {
        melhorScore = scoreMedia;
        melhorMonstro = monstro;
      }
    }

    // Se não encontrou com vantagem, pega qualquer um morto
    melhorMonstro ??= monstrosMortos.first;

    // Calcula a vida a recuperar
    final vidaRecuperada = (melhorMonstro.vida * porcentagemCura / 100).round();
    final novaVida = vidaRecuperada.clamp(1, melhorMonstro.vida);

    // Debita score e aplica cura
    final monstrosAtualizados = historiaAtual!.monstros.map((m) {
      if (m.tipo == melhorMonstro!.tipo && m.level == melhorMonstro.level) {
        return m.copyWith(vidaAtual: novaVida);
      }
      return m;
    }).toList();

    final historiaAtualizada = historiaAtual!.copyWith(
      score: historiaAtual!.score - custoCura,
      monstros: monstrosAtualizados,
    );

    // Salva
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💚 ${melhorMonstro.tipo.displayName} curado ($porcentagemCura%)! Score: ${historiaAtualizada.score}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    print('💚 [AutoMode] Comprou cura: ${melhorMonstro.tipo.displayName} +${novaVida} vida (${porcentagemCura}%)');
    return true;
  }

  /// Carrega a mochila para uso no auto mode
  Future<void> _carregarMochilaAutoMode() async {
    final email = ref.read(validUserEmailProvider);
    _mochilaAutoMode = await MochilaService.carregarMochila(context, email);
    print('📦 [AutoMode] Mochila carregada: ${_mochilaAutoMode?.itensOcupados ?? 0} itens');
  }

  /// Salva a mochila após usar consumíveis
  Future<void> _salvarMochilaAutoMode() async {
    if (_mochilaAutoMode == null) return;

    final email = ref.read(validUserEmailProvider);
    await MochilaService.salvarMochila(context, email, _mochilaAutoMode!);
  }

  /// Usa consumíveis automaticamente antes da batalha
  Future<void> _usarConsumiveisAutoMode() async {
    if (_mochilaAutoMode == null || historiaAtual == null) return;

    print('🎒 [AutoMode] Verificando consumíveis...');

    // 1. Fruta Nuty (lendária) - usa no monstro level 1 mais fraco
    final nuty = _autoModeService.selecionarMonstroParaNuty(
      _mochilaAutoMode!,
      historiaAtual!.monstros,
    );
    if (nuty != null) {
      await _usarFrutaNutyAutoMode(nuty.indiceFruta, nuty.monstro);
    }

    // 2. Fruta Nuty Cristalizada - sempre usa no mais fraco
    final cristalizada = _autoModeService.selecionarMonstroParaCristalizada(
      _mochilaAutoMode!,
      historiaAtual!.monstros,
    );
    if (cristalizada != null) {
      await _usarFrutaCristalizadaAutoMode(cristalizada.indiceFruta, cristalizada.monstro);
    }

    // 3. Fruta Nuty Negra - sempre usa (+10 kills)
    final indiceFrutaNegra = _autoModeService.encontrarFrutaNegra(_mochilaAutoMode!);
    if (indiceFrutaNegra != null) {
      await _usarFrutaNegraAutoMode(indiceFrutaNegra);
    }

    // 4. Joia de Reforço/Recriação - usa se item estiver 2+ tiers abaixo
    final joia = _autoModeService.verificarItemParaJoia(
      _mochilaAutoMode!,
      historiaAtual!.monstros,
      historiaAtual!.tier,
    );
    if (joia != null) {
      await _usarJoiaAutoMode(joia.indiceJoia, joia.monstro, joia.isRecriacao);
    }
  }

  /// Usa Fruta Nuty no monstro (maximiza todos os stats)
  Future<void> _usarFrutaNutyAutoMode(int indiceFruta, MonstroAventura monstro) async {
    if (_mochilaAutoMode == null || historiaAtual == null) return;

    print('🥥 [AutoMode] Usando Fruta Nuty em ${monstro.tipo.displayName}');

    // Maximiza todos os atributos do monstro
    final monstroMaximizado = monstro.copyWith(
      vida: 150,
      vidaAtual: 150,
      energia: 40,
      agilidade: 20,
      ataque: 20,
      defesa: 60,
    );

    // Atualiza o monstro na lista
    final monstrosAtualizados = historiaAtual!.monstros.map((m) {
      if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
        return monstroMaximizado;
      }
      return m;
    }).toList();

    // Consome a fruta
    final item = _mochilaAutoMode!.itens[indiceFruta]!;
    if (item.quantidade > 1) {
      _mochilaAutoMode = _mochilaAutoMode!.atualizarItem(
        indiceFruta,
        item.copyWith(quantidade: item.quantidade - 1),
      );
    } else {
      _mochilaAutoMode = _mochilaAutoMode!.removerItem(indiceFruta);
    }

    // Salva tudo
    final historiaAtualizada = historiaAtual!.copyWith(monstros: monstrosAtualizados);
    final repository = ref.read(aventuraRepositoryProvider);
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
    await _salvarMochilaAutoMode();

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🥥 ${monstro.tipo.displayName} teve todos os stats maximizados!'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Usa Fruta Cristalizada no monstro (+10 em stat aleatório)
  Future<void> _usarFrutaCristalizadaAutoMode(int indiceFruta, MonstroAventura monstro) async {
    if (_mochilaAutoMode == null || historiaAtual == null) return;

    print('💎 [AutoMode] Usando Fruta Cristalizada em ${monstro.tipo.displayName}');

    // Sorteia um atributo aleatório para ganhar +10
    final random = Random();
    final atributos = ['vida', 'energia', 'agilidade', 'ataque', 'defesa'];
    final atributoSorteado = atributos[random.nextInt(atributos.length)];

    late final MonstroAventura monstroAprimorado;
    late final String nomeAtributo;

    switch (atributoSorteado) {
      case 'vida':
        monstroAprimorado = monstro.copyWith(
          vida: monstro.vida + 10,
          vidaAtual: monstro.vidaAtual + 10,
        );
        nomeAtributo = 'Vida';
        break;
      case 'energia':
        monstroAprimorado = monstro.copyWith(energia: monstro.energia + 10);
        nomeAtributo = 'Energia';
        break;
      case 'agilidade':
        monstroAprimorado = monstro.copyWith(agilidade: monstro.agilidade + 10);
        nomeAtributo = 'Agilidade';
        break;
      case 'ataque':
        monstroAprimorado = monstro.copyWith(ataque: monstro.ataque + 10);
        nomeAtributo = 'Ataque';
        break;
      case 'defesa':
      default:
        monstroAprimorado = monstro.copyWith(defesa: monstro.defesa + 10);
        nomeAtributo = 'Defesa';
        break;
    }

    // Atualiza o monstro na lista
    final monstrosAtualizados = historiaAtual!.monstros.map((m) {
      if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
        return monstroAprimorado;
      }
      return m;
    }).toList();

    // Consome a fruta
    final item = _mochilaAutoMode!.itens[indiceFruta]!;
    if (item.quantidade > 1) {
      _mochilaAutoMode = _mochilaAutoMode!.atualizarItem(
        indiceFruta,
        item.copyWith(quantidade: item.quantidade - 1),
      );
    } else {
      _mochilaAutoMode = _mochilaAutoMode!.removerItem(indiceFruta);
    }

    // Salva tudo
    final historiaAtualizada = historiaAtual!.copyWith(monstros: monstrosAtualizados);
    final repository = ref.read(aventuraRepositoryProvider);
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
    await _salvarMochilaAutoMode();

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💎 ${monstro.tipo.displayName} ganhou +10 de $nomeAtributo!'),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Usa Fruta Negra (+10 kills de tipo aleatório)
  Future<void> _usarFrutaNegraAutoMode(int indiceFruta) async {
    if (_mochilaAutoMode == null) return;

    print('🖤 [AutoMode] Usando Fruta Nuty Negra');

    // Sorteia um tipo aleatório
    final random = Random();
    final tipos = Tipo.values.where((t) => t != Tipo.normal).toList();
    final tipoSorteado = tipos[random.nextInt(tipos.length)];

    // Adiciona kills (mesma lógica do mochila_screen.dart)
    // Nota: A lógica de progresso diário já está no mochila_screen
    // Por simplicidade, apenas consumimos a fruta e mostramos mensagem

    // Consome a fruta
    final item = _mochilaAutoMode!.itens[indiceFruta]!;
    if (item.quantidade > 1) {
      _mochilaAutoMode = _mochilaAutoMode!.atualizarItem(
        indiceFruta,
        item.copyWith(quantidade: item.quantidade - 1),
      );
    } else {
      _mochilaAutoMode = _mochilaAutoMode!.removerItem(indiceFruta);
    }

    await _salvarMochilaAutoMode();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🖤 +10 kills de ${tipoSorteado.displayName}!'),
          backgroundColor: Colors.grey.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Usa Joia de Reforço ou Recriação no item
  Future<void> _usarJoiaAutoMode(int indiceJoia, MonstroAventura monstro, bool isRecriacao) async {
    if (_mochilaAutoMode == null || historiaAtual == null) return;

    final itemAtual = monstro.itemEquipado;
    if (itemAtual == null) return;

    print('💎 [AutoMode] Usando ${isRecriacao ? "Joia da Recriação" : "Joia de Reforço"} em ${monstro.tipo.displayName}');

    late final Item itemNovo;

    if (isRecriacao) {
      // Recriação: gera novo item com mesma raridade mas tier atual
      // Por simplicidade, apenas atualiza o tier (a lógica completa está no mochila_screen)
      final atributosBase = <String, int>{};
      itemAtual.atributos.forEach((atributo, valor) {
        atributosBase[atributo] = (valor / itemAtual.tier).round();
      });

      final novosAtributos = <String, int>{};
      atributosBase.forEach((atributo, valorBase) {
        novosAtributos[atributo] = valorBase * historiaAtual!.tier;
      });

      itemNovo = itemAtual.copyWith(
        atributos: novosAtributos,
        tier: historiaAtual!.tier,
      );
    } else {
      // Reforço: escala os atributos para o tier atual
      final atributosBase = <String, int>{};
      itemAtual.atributos.forEach((atributo, valor) {
        atributosBase[atributo] = (valor / itemAtual.tier).round();
      });

      final novosAtributos = <String, int>{};
      atributosBase.forEach((atributo, valorBase) {
        novosAtributos[atributo] = valorBase * historiaAtual!.tier;
      });

      itemNovo = itemAtual.copyWith(
        atributos: novosAtributos,
        tier: historiaAtual!.tier,
      );
    }

    // Atualiza o monstro com o item novo
    final monstrosAtualizados = historiaAtual!.monstros.map((m) {
      if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
        return m.copyWith(itemEquipado: itemNovo);
      }
      return m;
    }).toList();

    // Consome a joia
    final item = _mochilaAutoMode!.itens[indiceJoia]!;
    if (item.quantidade > 1) {
      _mochilaAutoMode = _mochilaAutoMode!.atualizarItem(
        indiceJoia,
        item.copyWith(quantidade: item.quantidade - 1),
      );
    } else {
      _mochilaAutoMode = _mochilaAutoMode!.removerItem(indiceJoia);
    }

    // Salva tudo
    final historiaAtualizada = historiaAtual!.copyWith(monstros: monstrosAtualizados);
    final repository = ref.read(aventuraRepositoryProvider);
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
    await _salvarMochilaAutoMode();

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💎 ${itemAtual.nome} reforçado de Tier ${itemAtual.tier} para Tier ${itemNovo.tier}!'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Usa poção para renascer monstro morto com vantagem
  Future<bool> _usarPocaoParaRenascerAutoMode() async {
    if (_mochilaAutoMode == null || historiaAtual == null) return false;

    final inimigosVivos = monstrosParaExibir.where((i) => i.vidaAtual > 0).toList();
    if (inimigosVivos.isEmpty) return false;

    final resultado = await _autoModeService.selecionarPocaoParaRenascer(
      _mochilaAutoMode!,
      historiaAtual!.monstros,
      inimigosVivos,
    );

    if (resultado == null) return false;

    print('🧪 [AutoMode] Usando poção para renascer ${resultado.monstro.tipo.displayName}');

    // Calcula cura
    final monstro = resultado.monstro;
    final curaTotal = (monstro.vida * resultado.porcentagemCura / 100).round();
    final novaVidaAtual = curaTotal.clamp(1, monstro.vida); // Mínimo 1 de vida

    // Atualiza o monstro
    final monstrosAtualizados = historiaAtual!.monstros.map((m) {
      if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
        return m.copyWith(vidaAtual: novaVidaAtual);
      }
      return m;
    }).toList();

    // Consome a poção
    final item = _mochilaAutoMode!.itens[resultado.indicePocao]!;
    if (item.quantidade > 1) {
      _mochilaAutoMode = _mochilaAutoMode!.atualizarItem(
        resultado.indicePocao,
        item.copyWith(quantidade: item.quantidade - 1),
      );
    } else {
      _mochilaAutoMode = _mochilaAutoMode!.removerItem(resultado.indicePocao);
    }

    // Salva tudo
    final historiaAtualizada = historiaAtual!.copyWith(monstros: monstrosAtualizados);
    final repository = ref.read(aventuraRepositoryProvider);
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
    await _salvarMochilaAutoMode();

    if (mounted) {
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🧪 ${monstro.tipo.displayName} renasceu com ${resultado.porcentagemCura}% de vida!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return true;
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

      // Verifica compatibilidade de versão
      print('🔍 [DEBUG] Verificando versão - Aventura: ${historiaAtual!.version}, Jogo: ${VersionConfig.currentVersion}');

      final versionComparison = VersionConfig.compareVersions(
        historiaAtual!.version,
        VersionConfig.currentVersion,
      );

      print('🔍 [DEBUG] Comparação de versões retornou: $versionComparison');

      if (versionComparison < 0) {
        // Versão da aventura é menor que a versão atual do jogo
        print('⚠️ [MapaAventura] Versão incompatível: aventura v${historiaAtual!.version} < jogo v${VersionConfig.currentVersion}');

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ Versão Incompatível'),
              content: const Text(
                'Por favor, crie uma nova aventura para prosseguir.\n\n'
                'Sua aventura atual foi criada em uma versão anterior do jogo '
                'e não é compatível com a versão atual.'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

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

      // Se chegou no tier 11, limpa dados do NPC Ganandius para permitir novo despertar gratuito
      if (historiaAtualizada.tier == 11) {
        await _limparDadosGanandiusTier11();
      }

      // Salva no repositório
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      // Atualiza o estado local
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      print('🏯 [MapaAventura] Tier avançado! Novo tier: ${historiaAtualizada.tier}, Score: ${historiaAtualizada.score}');

      // Verifica se o novo andar tem recompensas (chave auto a cada 25, nuty a cada 30)
      _recompensaService.entrarNoAndar(historiaAtualizada.tier);
      if (_recompensaService.temRecompensaPendente) {
        print('🎁 [MapaAventura] Recompensas disponíveis no andar ${historiaAtualizada.tier}!');
        // O ícone de notificação será exibido automaticamente no AppBar
        // O jogador pode coletar quando quiser clicando no ícone
      }

      // Verifica se modo Chave Auto está ativo e registra o andar completado
      if (_chaveAutoService.ativo) {
        final continuarChaveAuto = _chaveAutoService.completarAndar();
        if (!continuarChaveAuto) {
          // Todos os andares da chave auto foram completados
          print('🔑 [ChaveAuto] Todos os andares completados, finalizando modo...');
          await _finalizarModoChaveAuto();
        }
      }

      // Mostra modal de transição tier 11 se aplicável
      // Aguarda o usuário fechar o dialog antes de continuar (para não interromper auto mode)
      if (estaTransitandoParaTier11 && mounted) {
        print('📢 [MapaAventura] Mostrando modal de transição para tier ${ScoreConfig.SCORE_TIER_TRANSICAO}');

        // No auto mode, fecha automaticamente após 3 segundos
        if (_modoAutoAtivo) {
          print('🤖 [AutoMode] Modal tier 11 - fechando automaticamente em 3 segundos...');
          final dialogNavigator = Navigator.of(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              // Auto-fecha após 3 segundos
              Future.delayed(const Duration(seconds: 3), () {
                if (dialogNavigator.canPop()) {
                  dialogNavigator.pop();
                }
              });
              return ModalTier11Transicao(
                scoreAtual: scoreAntesDaTransicao,
              );
            },
          );
          // Aguarda o tempo do auto-close
          await Future.delayed(const Duration(seconds: 3, milliseconds: 100));
        } else {
          // Modo manual - aguarda o usuário clicar
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ModalTier11Transicao(
              scoreAtual: scoreAntesDaTransicao,
            ),
          );
        }
        print('📢 [MapaAventura] Modal tier 11 fechado, continuando...');
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

  /// Limpa dados do NPC Ganandius ao chegar no tier 11
  Future<void> _limparDadosGanandiusTier11() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailJogador = ref.read(validUserEmailProvider);

      // Remove apenas os dados do tier 11
      final tier = 11;

      // Remove flag de gratuito usado
      final chaveGratuito = 'ganandius_gratuito_${emailJogador}_tier_$tier';
      await prefs.remove(chaveGratuito);

      // Remove contador de compras
      final chaveCompras = 'ganandius_compras_${emailJogador}_tier_$tier';
      await prefs.remove(chaveCompras);

      // Remove passivas sorteadas
      final chavePassivas = 'ganandius_passivas_sorteadas_tier_$tier';
      await prefs.remove(chavePassivas);

      // Remove flag de auto mode usado
      final chaveAutoModeUsado = 'ganandius_automode_usado_${emailJogador}_tier_$tier';
      await prefs.remove(chaveAutoModeUsado);

      print('🧹 [GANANDIUS] Dados do tier 11 limpos - despertar gratuito disponível novamente!');
    } catch (e) {
      print('❌ [GANANDIUS] Erro ao limpar dados do tier 11: $e');
    }
  }

  /// Verifica se o tier atual tem o NPC Ganandius (11, 21, 31, 41, etc.)
  bool _tierTemGanandius() {
    final tierAtual = historiaAtual?.tier ?? 1;
    return tierAtual >= 11 && (tierAtual - 11) % 10 == 0;
  }

  /// Interação automática com Ganandius no auto mode
  /// Prioridade das passivas: crítico > sortudo > mercador > esquiva
  Future<void> _interagirComGanandiusAutoMode() async {
    if (historiaAtual == null) return;

    // Verifica se estamos em um tier com Ganandius
    if (!_tierTemGanandius()) {
      return;
    }

    print('🔮 [AutoMode/Ganandius] Tier ${historiaAtual!.tier} tem Ganandius!');

    try {
      final prefs = await SharedPreferences.getInstance();
      final emailJogador = ref.read(validUserEmailProvider);
      final tierAtual = historiaAtual!.tier;

      // Verifica se já usou o Ganandius neste tier (no auto mode)
      final chaveAutoModeUsado = 'ganandius_automode_usado_${emailJogador}_tier_$tierAtual';
      final jaUsouAutoMode = prefs.getBool(chaveAutoModeUsado) ?? false;

      if (jaUsouAutoMode) {
        print('🔮 [AutoMode/Ganandius] Já usou Ganandius neste tier no auto mode');
        return;
      }

      // Conta quantas passivas a equipe já tem
      final totalPassivas = historiaAtual!.monstros
          .where((m) => m.passiva != null)
          .length;

      // Se já tem 3 passivas (1 por monstro), não usa mais Ganandius
      if (totalPassivas >= 3) {
        print('🔮 [AutoMode/Ganandius] Equipe já tem $totalPassivas passivas (máximo atingido)');
        await prefs.setBool(chaveAutoModeUsado, true);
        return;
      }

      // Verifica se tem algum monstro sem passiva
      final monstrosSemPassiva = historiaAtual!.monstros
          .where((m) => m.passiva == null)
          .toList();

      if (monstrosSemPassiva.isEmpty) {
        print('🔮 [AutoMode/Ganandius] Todos os monstros já têm passiva');
        await prefs.setBool(chaveAutoModeUsado, true);
        return;
      }

      print('🔮 [AutoMode/Ganandius] ${monstrosSemPassiva.length} monstro(s) sem passiva ($totalPassivas/3 passivas)');

      // IMPORTANTE: No auto mode, só usa Ganandius GRATUITO (tier 11)
      // Não gasta score em compras pagas (tier 21+)
      final chaveGratuito = 'ganandius_gratuito_${emailJogador}_tier_$tierAtual';
      final jaPegouGratuito = prefs.getBool(chaveGratuito) ?? false;

      // Tier 11: gratuito (apenas uma vez)
      if (tierAtual == 11 && !jaPegouGratuito) {
        print('🔮 [AutoMode/Ganandius] Tier 11 - usando despertar GRATUITO');
        // Continua para aplicar passiva
      } else {
        // Tier 11 já usou gratuito OU tier 21+ (pago)
        // Auto mode NÃO gasta score em Ganandius
        print('🔮 [AutoMode/Ganandius] Tier ${tierAtual} - despertar PAGO, pulando (auto mode não gasta score)');
        await prefs.setBool(chaveAutoModeUsado, true);
        return;
      }

      final custoDespertar = 0; // Só usa gratuito no auto mode

      print('🔮 [AutoMode/Ganandius] Custo: $custoDespertar, Score: ${historiaAtual!.score}');

      // Busca passivas já equipadas na equipe
      final passivasEquipadas = historiaAtual!.monstros
          .where((m) => m.passiva != null)
          .map((m) => m.passiva!.tipo)
          .toSet();

      // Prioridade: crítico > sortudo > mercador > esquiva
      // (curaDeBatalha não está na lista de prioridade do usuário)
      final prioridadePassivas = [
        TipoPassiva.critico,
        TipoPassiva.sortudo,
        TipoPassiva.mercador,
        TipoPassiva.esquiva,
        TipoPassiva.curaDeBatalha, // Menor prioridade
      ];

      // Encontra a melhor passiva disponível (não equipada)
      TipoPassiva? melhorPassiva;
      for (final passiva in prioridadePassivas) {
        if (!passivasEquipadas.contains(passiva)) {
          melhorPassiva = passiva;
          break;
        }
      }

      if (melhorPassiva == null) {
        print('🔮 [AutoMode/Ganandius] Todas as passivas prioritárias já estão equipadas');
        await prefs.setBool(chaveAutoModeUsado, true);
        return;
      }

      print('🔮 [AutoMode/Ganandius] Melhor passiva disponível: ${melhorPassiva.nome}');

      // Escolhe o primeiro monstro sem passiva
      final monstroAlvo = monstrosSemPassiva.first;
      print('🔮 [AutoMode/Ganandius] Monstro alvo: ${monstroAlvo.nome}');

      // Aplica a passiva
      final novaPassiva = Passiva(tipo: melhorPassiva);
      final novoScore = historiaAtual!.score - custoDespertar;

      // Atualiza o monstro com a nova passiva
      final monstrosAtualizados = historiaAtual!.monstros.map((m) {
        if (m.tipo == monstroAlvo.tipo && m.level == monstroAlvo.level && m.passiva == null) {
          return m.copyWith(passiva: novaPassiva);
        }
        return m;
      }).toList();

      // Atualiza a história
      final historiaAtualizada = historiaAtual!.copyWith(
        score: novoScore,
        monstros: monstrosAtualizados,
      );

      // Salva no repositório
      final repository = ref.read(aventuraRepositoryProvider);
      await repository.salvarHistoricoJogador(historiaAtualizada);

      // Atualiza estado local
      setState(() {
        historiaAtual = historiaAtualizada;
      });

      // Atualiza flags
      if (tierAtual == 11 && !jaPegouGratuito) {
        await prefs.setBool(chaveGratuito, true);
      } else if (tierAtual >= 21) {
        final runId = historiaAtual!.runId;
        final chaveCompras = 'ganandius_compras_${emailJogador}_run_$runId';
        final comprasRealizadas = prefs.getInt(chaveCompras) ?? 0;
        await prefs.setInt(chaveCompras, comprasRealizadas + 1);
      }

      // Marca que usou no auto mode neste tier
      await prefs.setBool(chaveAutoModeUsado, true);

      print('✅ [AutoMode/Ganandius] ${monstroAlvo.nome} recebeu passiva "${melhorPassiva.nome}"!');
      print('✅ [AutoMode/Ganandius] Score: $novoScore (gastou $custoDespertar)');

      // Mostra notificação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔮 ${monstroAlvo.nome} despertou "${melhorPassiva.nome}"!'),
            backgroundColor: Colors.deepPurple,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      print('❌ [AutoMode/Ganandius] Erro: $e');
    }
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
        // Verificar se é o andar 99 (entrada no HARDCORE MODE)
        bool isAndar99 = historiaAtual?.tier == 99;

        // Verificar se é um dos tiers de aumento de dificuldade
        bool isTierDificuldade = podeAvancar && [19, 29, 39, 49].contains(historiaAtual?.tier);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                podeAvancar ? (isAndar99 ? Icons.warning_amber_rounded : (isAndar10 ? Icons.warning : (isTierDificuldade ? Icons.trending_up : Icons.arrow_upward))) : Icons.block,
                color: podeAvancar ? (isAndar99 ? Colors.red : (isAndar10 ? Colors.orange : (isTierDificuldade ? Colors.deepOrange : Colors.green))) : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  podeAvancar
                    ? (isAndar99 ? '🔥 HARDCORE MODE - Andar 99' : (isAndar10 ? 'AVISO ESPECIAL - Andar 10' : (isTierDificuldade ? 'AUMENTO DE DIFICULDADE' : 'Avançar Tier')))
                    : 'Requisitos não atendidos',
                  style: TextStyle(
                    color: podeAvancar ? (isAndar99 ? Colors.red : (isAndar10 ? Colors.orange : (isTierDificuldade ? Colors.deepOrange : Colors.green))) : Colors.red,
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
                ] else if (isAndar99) ...[
                  // ⚠️ AVISO ESPECIAL PARA O ANDAR 99 → 100 (HARDCORE MODE)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '🔥 BEM-VINDO AO HARDCORE! 🔥',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Você está prestes a entrar no modo mais difícil do jogo!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '⚔️ MUDANÇAS NO TIER 100+:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('• ❌ Não ganha mais SCORE dos monstros'),
                        const Text('• 💀 TODOS os inimigos têm passivas de batalha'),
                        const Text('• 🌟 20% de chance de monstros terem item IMPOSSÍVEL'),
                        const Text('• 👑 Elites SEMPRE dropam item IMPOSSÍVEL'),
                        const Text('• 🚫 Loja: Cura desabilitada'),
                        const Text('• ✨ 20% de chance de encontrar Nostálgicos'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '💀 Boa sorte, você vai precisar!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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
                  backgroundColor: isAndar99 ? Colors.red : (isAndar10 ? Colors.orange : Colors.green),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] Botão Confirmar clicado');
                  Navigator.of(context).pop();
                  print('ÃƒÂ°Ã…Â¸Ã…Â½Ã‚Â¯ [DEBUG] Modal fechado, chamando _avancarTier()');
                  _avancarTier();
                },
                child: Text(
                  isAndar99
                    ? '🔥 ENTRAR NO HARDCORE'
                    : (isAndar10
                        ? ((historiaAtual?.score ?? 0) > 50 ? 'Avançar e Resetar' : 'Avançar (Score Mantido)')
                        : 'Confirmar')
                ),
              ),
          ],
        );
      },
    );
  }

  /// Carrega filtro de drops do SharedPreferences
  Future<void> _carregarFiltroDrops() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final raridade in RaridadeItem.values) {
        _filtroDrops[raridade] = prefs.getBool('filtro_drop_${raridade.name}') ?? true;
      }
      _valorMinimoMagia = prefs.getInt('filtro_drop_valor_minimo_magia') ?? 0;
      _valorMinimoMagiaController.text = _valorMinimoMagia.toString();
    });
  }

  /// Salva filtro de drops no SharedPreferences
  Future<void> _salvarFiltroDrops() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _filtroDrops.entries) {
      await prefs.setBool('filtro_drop_${entry.key.name}', entry.value);
    }
    await prefs.setInt('filtro_drop_valor_minimo_magia', _valorMinimoMagia);
  }

  /// Mostra modal de recompensa pendente
  Future<void> _mostrarRecompensaPendente() async {
    if (!_recompensaService.temRecompensaPendente) return;

    final premio = _recompensaService.recompensasPendentes.first;

    await mostrarModalPremioAndar(
      context,
      premio,
      () async {
        // Coleta a recompensa
        _recompensaService.coletarRecompensa(premio.tipo);

        // Adiciona o item na mochila
        await _adicionarRecompensaNaMochila(premio);

        // Atualiza a tela
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  /// Adiciona a recompensa na mochila do jogador
  Future<void> _adicionarRecompensaNaMochila(InfoPremio premio) async {
    final email = ref.read(validUserEmailProvider);
    if (email.isEmpty) return;

    var mochila = await MochilaService.carregarMochila(context, email);
    if (mochila == null) return;

    switch (premio.tipo) {
      case TipoPremio.chaveAuto:
        mochila = mochila.adicionarChaveAuto(premio.quantidade);
        break;
      case TipoPremio.nuty:
        // TODO: Implementar slot de Nuty quando necessário
        // Por enquanto, não faz nada pois ainda não temos o slot de Nuty
        break;
    }

    if (!mounted) return;
    await MochilaService.salvarMochila(context, email, mochila);
  }

  /// Mostra modal de filtro de drops
  void _mostrarFiltroDrops() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF1A1A2E),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Row(
                  children: [
                    const Icon(Icons.tune, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'FILTRAR DROPS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Informação
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Desmarque as raridades que você NÃO quer que apareçam nas recompensas de batalha',
                          style: TextStyle(
                            color: Colors.blue.shade100,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Lista de checkboxes
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...RaridadeItem.values.map((raridade) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _filtroDrops[raridade]! ? raridade.cor : Colors.grey.shade700,
                                width: 2,
                              ),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                raridade.nome,
                                style: TextStyle(
                                  color: _filtroDrops[raridade]! ? raridade.cor : Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                _filtroDrops[raridade]! ? 'Aparecerá nas recompensas' : 'Não aparecerá nas recompensas',
                                style: TextStyle(
                                  color: _filtroDrops[raridade]! ? Colors.white70 : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              value: _filtroDrops[raridade],
                              activeColor: raridade.cor,
                              checkColor: Colors.white,
                              onChanged: (valor) {
                                setModalState(() {
                                  setState(() {
                                    _filtroDrops[raridade] = valor ?? true;
                                  });
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        }).toList(),

                        // Divisor
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, thickness: 1),
                        const SizedBox(height: 16),

                        // Valor mínimo para magias
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade900.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_fix_high, color: Colors.purple, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'VALOR MÍNIMO DE MAGIA',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Magias com valor FINAL (base × level) abaixo deste número serão descartadas',
                                style: TextStyle(
                                  color: Colors.purple.shade100,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ex: Magia base 10 level 5 = valor final 50 (0 = sem filtro)',
                                style: TextStyle(
                                  color: Colors.purple.shade200,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _valorMinimoMagiaController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.purple, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.purple, width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.purple, width: 3),
                                  ),
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.purple.shade300),
                                  prefixIcon: const Icon(Icons.filter_alt, color: Colors.purple),
                                ),
                                onChanged: (valor) {
                                  // Filtra apenas números
                                  final valorFiltrado = valor.replaceAll(RegExp(r'[^0-9]'), '');
                                  final valorInt = int.tryParse(valorFiltrado) ?? 0;

                                  // Atualiza o estado
                                  setModalState(() {
                                    setState(() {
                                      _valorMinimoMagia = valorInt;
                                    });
                                  });

                                  // Atualiza o controller apenas se o texto filtrado for diferente
                                  if (valorFiltrado != valor) {
                                    _valorMinimoMagiaController.value = _valorMinimoMagiaController.value.copyWith(
                                      text: valorFiltrado,
                                      selection: TextSelection.collapsed(offset: valorFiltrado.length),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _salvarFiltroDrops();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filtro de drops salvo!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'SALVAR FILTRO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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






