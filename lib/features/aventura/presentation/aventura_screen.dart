import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/aventura_provider.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/google_drive_service.dart';
import 'mapa_aventura_screen.dart';
import 'modal_monstro_aventura.dart';

class AventuraScreen extends ConsumerStatefulWidget {
  const AventuraScreen({super.key});

  @override
  ConsumerState<AventuraScreen> createState() => _AventuraScreenState();
}

class _AventuraScreenState extends ConsumerState<AventuraScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('❌ [FlutterError] ${details.exceptionAsString()}');
      debugPrint('❌ [FlutterError] Stacktrace: ${details.stack}');
    };
  }
  String _getTextoBotaoAventura() {
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      return 'CONTINUAR AVENTURA';
    }
    if (historiaAtual != null && historiaAtual!.monstros.isEmpty) {
      return 'SORTEAR MONSTROS';
    }
    return 'INICIAR AVENTURA';
  }

  IconData _getIconeBotaoAventura() {
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      return Icons.play_circle_filled;
    }
    if (historiaAtual != null && historiaAtual!.monstros.isEmpty) {
      return Icons.casino;
    }
    return Icons.play_arrow;
  }

  // Mantém apenas uma definição do método _buildTipoIcon
  HistoriaJogador? historiaAtual;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🟢 [AventuraScreen] initState chamado, mounted=$mounted');
      _verificarEstadoJogador();
    });
  }

  Future<void> _verificarEstadoJogador() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      debugPrint('🎮 [AventuraScreen] Iniciando verificação do jogador: $emailJogador');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;

      final repository = ref.read(aventuraRepositoryProvider);
      debugPrint('🎮 [AventuraScreen] Repository obtido, verificando histórico...');

      bool temHistorico;
      try {
        temHistorico = await repository.jogadorTemHistorico(emailJogador);
      } catch (e) {
        debugPrint('❌ [AventuraScreen] Erro de autenticação, tentando refresh...');
        // Tenta refresh do token
        await GoogleDriveService().inicializarConexao();
        // Tenta novamente
        temHistorico = await repository.jogadorTemHistorico(emailJogador);
      }
      debugPrint('🎮 [AventuraScreen] Tem histórico: $temHistorico');

      if (temHistorico) {
        debugPrint('🎮 [AventuraScreen] Carregando histórico existente...');
        HistoriaJogador? historia;
        try {
          historia = await repository.carregarHistoricoJogador(emailJogador);
        } catch (e) {
          debugPrint('❌ [AventuraScreen] Erro de autenticação ao carregar histórico, tentando refresh...');
          await GoogleDriveService().inicializarConexao();
          historia = await repository.carregarHistoricoJogador(emailJogador);
        }
        debugPrint('🎮 [AventuraScreen] História carregada: ${historia != null}');

        if (historia != null) {
          if (mounted) {
            debugPrint('🟢 [AventuraScreen] Atualizando estado com história carregada');
            setState(() {
              historiaAtual = historia;
            });
          } else {
            debugPrint('⚠️ [AventuraScreen] Widget não está montado ao tentar atualizar estado');
          }

          // Verifica se a aventura já foi iniciada (só se widget ainda estiver montado)
          if (mounted) {
            if (historia.aventuraIniciada) {
              ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.aventuraIniciada;
              debugPrint('✅ [AventuraScreen] Estado: AVENTURA INICIADA');
            } else {
              ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;
              debugPrint('✅ [AventuraScreen] Estado: PODE INICIAR');
            }
          } else {
            debugPrint('⚠️ [AventuraScreen] Widget foi descartado, não atualizando estado do provider');
          }
        } else {
          if (mounted) {
            ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;
            debugPrint('📝 [AventuraScreen] Estado: SEM HISTÓRICO (história nula após remoção)');
          }
        }
      } else {
        if (mounted) {
          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;
          debugPrint('📝 [AventuraScreen] Estado: SEM HISTÓRICO');
        }
      }
    } catch (e, stack) {
      debugPrint('❌ [AventuraScreen] Erro na verificação: $e');
      debugPrint('❌ [AventuraScreen] Stacktrace: $stack');
      if (mounted) {
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
      }
    }
  }

  Future<void> _sortearMonstros() async {
    final emailJogador = ref.read(validUserEmailProvider);
    print('🎲 [AventuraScreen] Iniciando sorteio de monstros...');
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;
    
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      print('🎲 [AventuraScreen] Sorteando monstros...');
      final historia = await repository.sortearMonstrosParaJogador(emailJogador);
      
      print('🎲 [AventuraScreen] Monstros sorteados, atualizando estado...');
      if (mounted) {
        setState(() {
          historiaAtual = historia;
        });
        
        // Como o sorteio criou os monstros, definimos estado como pode iniciar para mostrar os monstros
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aventura criada e salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      print('✅ [AventuraScreen] Aventura completa criada com sucesso');
    } catch (e) {
      print('❌ [AventuraScreen] Erro no sorteio: $e');
      if (mounted) {
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sortear monstros: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _iniciarAventura() async {
    final emailJogador = ref.read(validUserEmailProvider);
    print('🚀 [AventuraScreen] Iniciando aventura...');
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;
    
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      debugPrint('🚀 [AventuraScreen] Chamando iniciarAventura no repository...');

      final historiaAtualizada = await repository.iniciarAventura(emailJogador);

      if (historiaAtualizada != null) {
        debugPrint('🚀 [AventuraScreen] Aventura processada com sucesso!');
        if (mounted) {
          setState(() {
            historiaAtual = historiaAtualizada;
          });
        } else {
          debugPrint('⚠️ [AventuraScreen] Widget não está montado ao tentar atualizar estado');
        }

        // Determina se é aventura nova ou continuada
        final isAventuraNova = historiaAtualizada.aventuraIniciada && 
                               historiaAtualizada.monstrosInimigos.isNotEmpty &&
                               historiaAtualizada.mapaAventura != null;

        // Navegar para o mapa de aventura e aguardar retorno
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapaAventuraScreen(
              mapaPath: historiaAtualizada.mapaAventura!,
              monstrosInimigos: historiaAtualizada.monstrosInimigos,
            ),
          ),
        );

        // Atualizar estado quando voltar da aventura
        if (mounted) {
          await _verificarEstadoJogador();
        }

        // Verifica se widget ainda está montado antes de usar ref
        if (mounted) {
          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.aventuraIniciada;

          // Mensagem diferente baseada no tipo de aventura
          final mensagem = isAventuraNova 
              ? 'Aventura iniciada! Boa sorte na jornada!'
              : 'Aventura continuada! Bem-vindo de volta!';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagem),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Falha ao iniciar aventura');
      }
    } catch (e, stack) {
      debugPrint('❌ [AventuraScreen] Erro ao iniciar aventura: $e');
      debugPrint('❌ [AventuraScreen] Stacktrace: $stack');
      
      // Verifica se widget ainda está montado antes de usar ref
      if (mounted) {
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar aventura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(aventuraEstadoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Aventura'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/templo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Título
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Bem-vindo à Aventura TechConnect!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Conteúdo baseado no estado
                Expanded(
                  child: _buildConteudoPorEstado(estado),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoPorEstado(AventuraEstado estado) {
    switch (estado) {
      case AventuraEstado.carregando:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Conectando com Google Drive',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );

      case AventuraEstado.semHistorico:
        return Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth < 400 ? constraints.maxWidth : 400.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                      padding: const EdgeInsets.all(16),
                      width: maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 32),
                              Text(
                                'Primeira Aventura!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Icon(Icons.star, color: Colors.amber, size: 32),
                            ],
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Você ainda não possui monstros.\nSorteie 3 monstros para começar sua jornada!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.deepPurple.shade400,
                            ),
                          ),
                          SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _sortearMonstros,
                                splashColor: Colors.deepPurple.shade100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade400, Colors.deepPurple.shade400],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 10,
                                      children: [
                                        Icon(Icons.casino, color: Colors.white, size: 26),
                                        Text(
                                          'SORTEAR MONSTROS',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

      case AventuraEstado.temHistorico:
      case AventuraEstado.podeIniciar:
        return _buildTelaComMonstros();

      case AventuraEstado.aventuraIniciada:
        return _buildTelaComMonstros();

      case AventuraEstado.erro:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.error,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Erro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ocorreu um erro ao carregar.\nVerifique sua conexão e tente novamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _verificarEstadoJogador,
                icon: const Icon(Icons.refresh),
                label: const Text('TENTAR NOVAMENTE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTelaComMonstros() {
    if (historiaAtual == null) {
      return const Center(child: Text('Erro: Histórico não carregado'));
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        // Cards dos monstros em linha, responsivo
        SizedBox(
          height: 160,
          child: Row(
            children: historiaAtual!.monstros.map<Widget>((monstro) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: _buildCardMonstroBonito(monstro),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 30),
        // Botão Iniciar/Continuar Aventura
        SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _iniciarAventura,
              splashColor: Colors.deepPurple.shade100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepPurple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      Icon(_getIconeBotaoAventura(), color: Colors.white, size: 26),
                      Text(
                        _getTextoBotaoAventura(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Botão Conquistas (só aparece se aventura está iniciada)
        if (historiaAtual != null && historiaAtual!.aventuraIniciada) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _irParaConquistas,
                splashColor: Colors.amber.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.white, size: 26),
                        Text(
                          'CONQUISTAS',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardMonstroBonito(dynamic monstro) {
    final isMorto = monstro.vidaAtual <= 0;
    
    return GestureDetector(
      onTap: () => _mostrarModalMonstro(monstro),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColorFiltered(
                    colorFilter: isMorto
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.matrix([
                            1, 0, 0, 0, 0,
                            0, 1, 0, 0, 0,
                            0, 0, 1, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                    child: Image.asset(
                      monstro.imagem,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Image.asset(monstro.tipo.iconAsset, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Image.asset(monstro.tipoExtra.iconAsset, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 4),
                    Stack(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 0.5),
                            ),
                            child: Text(
                              '${monstro.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
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
  }

  void _mostrarModalMonstro(MonstroAventura monstro) {
    showDialog(
      context: context,
      builder: (context) => ModalMonstroAventura(monstro: monstro),
    );
  }

  void _irParaConquistas() {
    context.go('/conquistas');
  }



}
