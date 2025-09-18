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
import '../../../shared/models/tipo_enum.dart';
import '../utils/gerador_habilidades.dart';
import '../../../shared/models/atributos_jogo_enum.dart';
import 'dart:math';

class AventuraScreen extends ConsumerStatefulWidget {
  const AventuraScreen({super.key});

  @override
  ConsumerState<AventuraScreen> createState() => _AventuraScreenState();
}

class _AventuraScreenState extends ConsumerState<AventuraScreen> {
  bool _temMudancasNaoSalvas = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('❌ [FlutterError] ${details.exceptionAsString()}');
      debugPrint('❌ [FlutterError] Stacktrace: ${details.stack}');
    };
  }
  String _getTextoBotaoAventura() {
    if (_temMudancasNaoSalvas) {
      return 'SALVAR';
    }
    if (historiaAtual != null && historiaAtual!.monstros.isEmpty) {
      return 'SORTEAR MONSTROS';
    }
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      return 'CONTINUAR AVENTURA';
    }
    if (historiaAtual != null && !historiaAtual!.aventuraIniciada) {
      return 'INICIAR AVENTURA';
    }
    return 'INICIAR AVENTURA';
  }

  IconData _getIconeBotaoAventura() {
    if (_temMudancasNaoSalvas) {
      return Icons.save;
    }
    if (historiaAtual != null && historiaAtual!.monstros.isEmpty) {
      return Icons.casino;
    }
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      return Icons.play_circle_filled;
    }
    if (historiaAtual != null && !historiaAtual!.aventuraIniciada) {
      return Icons.play_arrow;
    }
    return Icons.play_arrow;
  }

  bool _podeUsarBotaoAventura() {
    // Botão sempre habilitado quando há mudanças para salvar
    if (_temMudancasNaoSalvas) {
      return true;
    }
    // Comportamento normal quando não há mudanças
    return true;
  }

  bool _podeUsarBotaoConquistas() {
    // Desabilitado quando há mudanças não salvas
    return !_temMudancasNaoSalvas &&
           historiaAtual != null &&
           historiaAtual!.aventuraIniciada;
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

  Future<List<MonstroAventura>> _gerarNovosMonstrosLocal() async {
    final random = Random();
    final tiposDisponiveis = Tipo.values.toList();
    tiposDisponiveis.shuffle(random);

    final monstrosSorteados = <MonstroAventura>[];

    // Sorteia 3 tipos únicos (mesma lógica do repository)
    for (int i = 0; i < 3 && i < tiposDisponiveis.length; i++) {
      final tipo = tiposDisponiveis[i];
      // Sorteia tipo extra diferente do principal
      final outrosTipos = tiposDisponiveis.where((t) => t != tipo).toList();
      outrosTipos.shuffle(random);
      final tipoExtra = outrosTipos.first;

      // Gera 4 habilidades para o monstro
      final habilidades = GeradorHabilidades.gerarHabilidadesMonstro(tipo, tipoExtra);

      // Sorteia atributos usando os ranges definidos
      final monstro = MonstroAventura(
        tipo: tipo,
        tipoExtra: tipoExtra,
        imagem: 'assets/monstros_aventura/${tipo.name}.png',
        vida: AtributoJogo.vida.sortearValor(random),
        energia: AtributoJogo.energia.sortearValor(random),
        agilidade: AtributoJogo.agilidade.sortearValor(random),
        ataque: AtributoJogo.ataque.sortearValor(random),
        defesa: AtributoJogo.defesa.sortearValor(random),
        habilidades: habilidades,
        itemEquipado: null, // Sem item inicial
      );
      monstrosSorteados.add(monstro);
    }

    return monstrosSorteados;
  }

  Future<void> _sortearMonstrosComLoading() async {
    if (historiaAtual == null) return;

    // Mostra dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sorteando novos monstros...'),
          ],
        ),
      ),
    );

    try {
      // Simula o tempo de processamento
      await Future.delayed(const Duration(milliseconds: 1000));

      // APENAS sorteia novos monstros SEM salvar no Drive - criando localmente
      final novosMonstros = await _gerarNovosMonstrosLocal();

      if (mounted) {
        // Fecha o dialog de loading
        Navigator.of(context).pop();

        // Atualiza APENAS localmente, NÃO salva no Drive ainda
        setState(() {
          historiaAtual = historiaAtual!.copyWith(
            monstros: novosMonstros,
            aventuraIniciada: false,
            score: 0,
          );
          _temMudancasNaoSalvas = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novos monstros sorteados! Clique em "Salvar" para confirmar.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fecha o dialog de loading
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sortear novos monstros: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  Future<void> _botaoPrincipalAction() async {
    if (_temMudancasNaoSalvas) {
      await _salvarEIniciarAventura();
    } else if (historiaAtual != null &&
               historiaAtual!.monstros.isNotEmpty &&
               !historiaAtual!.aventuraIniciada) {
      // Se tem monstros mas aventura não foi iniciada, mostra aviso
      await _mostrarModalContinuarAventura();
    } else {
      await _iniciarAventura();
    }
  }

  Future<void> _salvarEIniciarAventura() async {
    if (historiaAtual == null || !_temMudancasNaoSalvas) return;

    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Salvando nova aventura...'),
            ],
          ),
        ),
      );

      final repository = ref.read(aventuraRepositoryProvider);

      // Primeiro salva a história atualizada com os novos monstros
      final sucessoSalvamento = await repository.salvarHistoricoJogador(historiaAtual!);

      if (sucessoSalvamento) {
        // Depois inicia uma nova aventura (sorteia novos inimigos)
        final aventuraCompleta = await repository.iniciarAventura(historiaAtual!.email);

        if (aventuraCompleta != null && mounted) {
          // Fecha o loading
          Navigator.of(context).pop();

          setState(() {
            historiaAtual = aventuraCompleta;
            _temMudancasNaoSalvas = false;
          });

          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.aventuraIniciada;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nova aventura iniciada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Falha ao salvar histórico no Drive');
      }
    } catch (e) {
      if (mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar e iniciar aventura: $e'),
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
            _voltarParaHome();
          },
        ),
        actions: [
          if (historiaAtual != null)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: (historiaAtual?.score == 0 && historiaAtual?.aventuraIniciada == false)
                    ? Colors.white
                    : Colors.grey,
              ),
              onPressed: (historiaAtual?.score == 0 && historiaAtual?.aventuraIniciada == false)
                  ? _mostrarModalReiniciarAventura
                  : null,
              tooltip: (historiaAtual?.score == 0 && historiaAtual?.aventuraIniciada == false)
                  ? 'Sortear novos monstros'
                  : historiaAtual?.aventuraIniciada == true
                      ? 'Não é possível reiniciar (aventura já iniciada)'
                      : 'Não é possível reiniciar (score > 0)',
            ),
        ],
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
              onTap: _podeUsarBotaoAventura() ? _botaoPrincipalAction : null,
              splashColor: Colors.deepPurple.shade100,
              child: Opacity(
                opacity: _podeUsarBotaoAventura() ? 1.0 : 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _temMudancasNaoSalvas
                          ? [Colors.green.shade400, Colors.teal.shade400]
                          : [Colors.orange.shade400, Colors.deepPurple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_temMudancasNaoSalvas ? Colors.green : Colors.orange).withOpacity(0.18),
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
                onTap: _podeUsarBotaoConquistas() ? _irParaConquistas : null,
                splashColor: Colors.amber.shade100,
                child: Opacity(
                  opacity: _podeUsarBotaoConquistas() ? 1.0 : 0.5,
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

  Future<void> _voltarParaHome() async {
    if (_temMudancasNaoSalvas) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mudanças não salvas'),
          content: const Text(
            'Você tem mudanças não salvas que serão perdidas se voltar. '
            'Tem certeza que deseja sair sem salvar?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair sem salvar'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _mostrarModalContinuarAventura() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continuar Aventura'),
        content: const Text(
          'Ao continuar, você não poderá mais sortear novos monstros pelo menu de aventura. '
          'Apenas pela tela de conquistas será possível obter novos monstros. '
          'Tem certeza que deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _iniciarAventuraComFlag();
    }
  }

  Future<void> _iniciarAventuraComFlag() async {
    if (historiaAtual == null) return;

    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Iniciando aventura...'),
            ],
          ),
        ),
      );

      // Atualiza a flag aventuraIniciada para true
      final historiaAtualizada = historiaAtual!.copyWith(aventuraIniciada: true);

      // Salva no Drive a história com flag atualizada
      final repository = ref.read(aventuraRepositoryProvider);
      final sucessoSalvamento = await repository.salvarHistoricoJogador(historiaAtualizada);

      if (sucessoSalvamento && mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        setState(() {
          historiaAtual = historiaAtualizada;
        });

        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.aventuraIniciada;

        // Vai para a tela do mapa da aventura
        if (mounted) {
          context.go('/aventura/mapa');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aventura iniciada! Botão refresh desabilitado.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha ao salvar no Drive');
      }
    } catch (e) {
      if (mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar aventura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarModalReiniciarAventura() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Aventura'),
        content: const Text(
          'Isso irá sortear 3 novos monstros para você. '
          'Tem certeza que deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _sortearMonstrosComLoading();
    }
  }




}
