import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../models/monstro_inimigo.dart';
import '../models/historia_jogador.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../presentation/modal_monstro_inimigo.dart';
import '../presentation/selecao_monstro_screen.dart';

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
      
      print('🗺️ [MapaAventura] Verificando aventura iniciada para: $emailJogador');
      
      // Carrega a história do jogador
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      
      if (historia != null) {
        print('🗺️ [MapaAventura] História encontrada - Aventura iniciada: ${historia.aventuraIniciada}');
        
        setState(() {
          historiaAtual = historia;
          
          if (historia.aventuraIniciada && historia.mapaAventura != null) {
            // Se há aventura iniciada, usa o mapa salvo
            mapaEscolhido = historia.mapaAventura!;
            print('🗺️ [MapaAventura] Usando mapa salvo: $mapaEscolhido');
          } else {
            // Se não há aventura iniciada, sorteia um mapa aleatório
            final random = Random();
            mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
            print('🗺️ [MapaAventura] Sorteou novo mapa: $mapaEscolhido');
          }
          
          isLoading = false;
        });
      } else {
        print('❌ [MapaAventura] Nenhuma história encontrada');
        setState(() {
          final random = Random();
          mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [MapaAventura] Erro ao verificar aventura: $e');
      setState(() {
        final random = Random();
        mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
        isLoading = false;
      });
    }
  }

  List<MonstroInimigo> get monstrosParaExibir {
    // Se há história carregada e aventura iniciada, usa os monstros da história
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      print('🗺️ [MapaAventura] Usando monstros da história: ${historiaAtual!.monstrosInimigos.length}');
      return historiaAtual!.monstrosInimigos;
    }
    
    // Caso contrário, usa os monstros passados por parâmetro
    print('🗺️ [MapaAventura] Usando monstros do parâmetro: ${widget.monstrosInimigos.length}');
    return widget.monstrosInimigos;
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('Mapa de Aventura'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
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

    int tierAtual = historiaAtual?.tier ?? 1;
    int mortosNoTier = monstrosParaExibir.where((m) => m.vidaAtual <= 0).length;
    bool podeAvancarTier = mortosNoTier >= 3;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(historiaAtual?.aventuraIniciada == true 
            ? 'Aventura em Andamento' 
            : 'Mapa de Aventura'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
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
            // TIER e botão avançar
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TIER $tierAtual',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: null, // Etapa 1: desabilitado sempre
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Avançar Tier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Pontos interativos do mapa (5 pontos fixos)
            ..._buildPontosMapa(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPontosMapa() {
    final monstrosParaUsar = monstrosParaExibir;
    final pontos = <Widget>[];
    
    // Posições fixas dos pontos no mapa
    final posicoes = [
      (0.2, 0.2),   // Ponto 1 - Superior esquerdo
      (0.7, 0.15),  // Ponto 2 - Superior direito
      (0.5, 0.45),  // Ponto 3 - Centro
      (0.25, 0.65), // Ponto 4 - Inferior esquerdo
      (0.75, 0.68), // Ponto 5 - Inferior direito (mais alto)
    ];
    
    for (int i = 0; i < posicoes.length && i < monstrosParaUsar.length; i++) {
      pontos.add(_buildPontoMapa(i, posicoes[i].$1, posicoes[i].$2, monstrosParaUsar));
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
            border: Border.all(color: Colors.white, width: 3),
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
              'assets/icons_gerais/evil_monster_viral_icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarModalMonstroInimigo(MonstroInimigo monstro) {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecaoMonstroScreen(monstroInimigo: monstroInimigo),
      ),
    );
  }
}
