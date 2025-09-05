import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../models/monstro_inimigo.dart';
import '../models/historia_jogador.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../tipagem/data/tipagem_repository.dart';
import '../presentation/modal_monstro_inimigo.dart';
import '../presentation/selecao_monstro_screen.dart';
import '../presentation/casa_vigarista_modal.dart';

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
    int scoreAtual = historiaAtual?.score ?? 0;
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
                    
                    // BOTÃO AVANÇAR
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
    
    // Adiciona pontos dos monstros
    for (int i = 0; i < posicoes.length && i < monstrosParaUsar.length; i++) {
      pontos.add(_buildPontoMapa(i, posicoes[i].$1, posicoes[i].$2, monstrosParaUsar));
    }
    
    // Adiciona Casa do Vigarista (baú de tesouro) - posição central superior
    pontos.add(_buildCasaDoVigarista(0.5, 0.25));
    
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

  Widget _buildCasaDoVigarista(double left, double top) {
    // Verifica se o jogador tem score suficiente (mínimo = 2 * tier atual)
    int tierAtual = historiaAtual?.tier ?? 1;
    int scoreAtual = historiaAtual?.score ?? 0;
    int custoMinimo = 2 * tierAtual;
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
          child: Icon(
            Icons.inventory_2_outlined, // Ícone de baú de tesouro
            color: podeAcessar ? Colors.yellow.shade100 : Colors.grey.shade300,
            size: 40,
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

    if (historiaAtual == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CasaVigaristaModal(
          historia: historiaAtual!,
          onHistoriaAtualizada: (historiaAtualizada) async {
            // Atualiza o estado local
            setState(() {
              historiaAtual = historiaAtualizada;
            });

            // Salva no repositório
            try {
              final repository = ref.read(aventuraRepositoryProvider);
              await repository.salvarHistoricoJogador(historiaAtualizada);
              print('💾 [MapaAventura] História atualizada após compra na Casa do Vigarista');
            } catch (e) {
              print('❌ [MapaAventura] Erro ao salvar história: $e');
            }
          },
        );
      },
    );
  }

  void _mostrarModalMonstroInimigo(MonstroInimigo monstro) async {
    // 🎯 PRINT DOS DADOS DE DEFESA DO MONSTRO INIMIGO
    print('🐉 [MONSTRO INIMIGO CLICADO] Tipo: ${monstro.tipo.displayName} (${monstro.tipo.name})');
    
    try {
      // Busca os dados de defesa do tipo do monstro
      final tipagemRepository = TipagemRepository();
      final dadosDefesa = await tipagemRepository.carregarDadosTipo(monstro.tipo);
      
      if (dadosDefesa != null) {
        print('💥 [DADOS DE DEFESA] Lista de dano recebido por ${monstro.tipo.displayName}:');
        print('─' * 60);
        
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
            efetividade = 'NÃO AFETA';
          } else {
            efetividade = 'NORMAL';
          }
          
          print('${atacante.displayName.padRight(15)} -> ${multiplicador.toString().padLeft(4)} (${efetividade})');
        }
        print('─' * 60);
      } else {
        print('❌ [ERRO] Não foi possível carregar dados de defesa para ${monstro.tipo.displayName}');
      }
    } catch (e) {
      print('❌ [ERRO] Erro ao buscar dados de defesa: $e');
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelecaoMonstroScreen(monstroInimigo: monstroInimigo),
      ),
    );
  }

  Future<void> _avancarTier() async {
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      
      if (historiaAtual == null) return;
      
      // Gera novos monstros para o próximo tier
      final novosMonstros = await _gerarNovosMonstrosParaTier(historiaAtual!.tier + 1);
      
      // Atualiza a história com novo tier e novos monstros (score não muda aqui)
      final historiaAtualizada = historiaAtual!.copyWith(
        tier: historiaAtual!.tier + 1,
        monstrosInimigos: novosMonstros,
      );
      
      // Salva no repositório
      await repository.salvarHistoricoJogador(historiaAtualizada);
      
      // Atualiza o estado local
      setState(() {
        historiaAtual = historiaAtualizada;
      });
      
      print('🎯 [MapaAventura] Tier avançado! Novo tier: ${historiaAtualizada.tier}, Score: ${historiaAtualizada.score}');
      
    } catch (e) {
      print('❌ [MapaAventura] Erro ao avançar tier: $e');
    }
  }

  Future<List<MonstroInimigo>> _gerarNovosMonstrosParaTier(int novoTier) async {
    // Gera novos monstros usando o repository para o novo tier
    final repository = ref.read(aventuraRepositoryProvider);
    
    print('🔄 [MapaAventura] Gerando novos monstros inimigos para tier $novoTier');
    
    // Chama o método público do repository para gerar novos monstros com itens
    final novosMonstros = await repository.gerarMonstrosInimigosPorTier(novoTier);
    
    print('✅ [MapaAventura] Novos monstros gerados com tier $novoTier');
    return novosMonstros;
  }

  void _mostrarModalAvancarTier(bool podeAvancar, int monstrosMortos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                podeAvancar ? Icons.arrow_upward : Icons.block,
                color: podeAvancar ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                podeAvancar ? 'Avançar Tier' : 'Requisitos não atendidos',
                style: TextStyle(
                  color: podeAvancar ? Colors.green : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (podeAvancar) ...[
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
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _avancarTier();
                },
                child: const Text('Confirmar'),
              ),
          ],
        );
      },
    );
  }
}
