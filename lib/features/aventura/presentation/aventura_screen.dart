import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/aventura_provider.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../models/drop_jogador.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/google_drive_service.dart';
import '../services/drops_service.dart';
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
    return 'INICIAR AVENTURA';
  }

  IconData _getIconeBotaoAventura() {
    if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      return Icons.play_circle_filled;
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

          // Verifica se a aventura já foi iniciada
          if (historia.aventuraIniciada) {
            ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.aventuraIniciada;
            debugPrint('✅ [AventuraScreen] Estado: AVENTURA INICIADA');
          } else {
            ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;
            debugPrint('✅ [AventuraScreen] Estado: PODE INICIAR');
          }
        } else {
          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
          debugPrint('❌ [AventuraScreen] Estado: ERRO (história nula)');
        }
      } else {
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;
        debugPrint('📝 [AventuraScreen] Estado: SEM HISTÓRICO');
      }
    } catch (e, stack) {
      debugPrint('❌ [AventuraScreen] Erro na verificação: $e');
      debugPrint('❌ [AventuraScreen] Stacktrace: $stack');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
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
      setState(() {
        historiaAtual = historia;
      });
      
      // Como o sorteio já cria a aventura completa, definimos estado como aventura iniciada
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.aventuraIniciada;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aventura criada e salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      print('✅ [AventuraScreen] Aventura completa criada com sucesso');
    } catch (e) {
      print('❌ [AventuraScreen] Erro no sorteio: $e');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sortear monstros: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

        // Navegar para o mapa de aventura
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapaAventuraScreen(
              mapaPath: historiaAtualizada.mapaAventura!,
              monstrosInimigos: historiaAtualizada.monstrosInimigos,
            ),
          ),
        );

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
      } else {
        throw Exception('Falha ao iniciar aventura');
      }
    } catch (e, stack) {
      debugPrint('❌ [AventuraScreen] Erro ao iniciar aventura: $e');
      debugPrint('❌ [AventuraScreen] Stacktrace: $stack');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar aventura: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        // Botão Iniciar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _iniciarAventura();
            },
            icon: Icon(_getIconeBotaoAventura()),
            label: Text(_getTextoBotaoAventura()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Botões de recompensas (só aparecem se aventura está iniciada)
        if (historiaAtual != null && historiaAtual!.aventuraIniciada) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _receberRecompensas(),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Receber Recompensas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _visualizarDrops(),
                  icon: const Icon(Icons.inventory),
                  label: const Text('Ver Prêmios'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCardMonstroBonito(dynamic monstro) {
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
                  child: Image.asset(
                    monstro.imagem,
                    fit: BoxFit.contain,
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

  Future<void> _receberRecompensas() async {
    try {
      // Mostra confirmação antes de finalizar aventura
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Finalizar Aventura'),
            ],
          ),
          content: const Text(
            'Ao receber as recompensas, sua aventura atual será finalizada e uma nova será iniciada.\n\nDeseja continuar?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Receber Recompensas'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      // Mostra loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final emailJogador = ref.read(validUserEmailProvider);
      final dropsService = DropsService();

      // Adiciona recompensas mockadas
      await dropsService.adicionarRecompensasMockadas(emailJogador);

      // Finaliza aventura atual e inicia nova
      await _finalizarEIniciarNovaAventura();

      // Fecha loading
      if (mounted) Navigator.of(context).pop();

      // Mostra sucesso
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.green),
                SizedBox(width: 8),
                Text('Recompensas Recebidas!'),
              ],
            ),
            content: const Text(
              'Suas recompensas foram coletadas e uma nova aventura foi iniciada!\n\nVisualize seus prêmios no botão "Ver Prêmios".',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ótimo!'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      // Fecha loading se aberto
      if (mounted) Navigator.of(context).pop();

      // Mostra erro
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Erro'),
              ],
            ),
            content: Text('Erro ao receber recompensas: $e'),
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

  Future<void> _finalizarEIniciarNovaAventura() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);

      // Cria nova história do zero (sem aventura iniciada)
      final novaHistoria = HistoriaJogador(
        email: emailJogador,
        monstros: [],
        aventuraIniciada: false,
        mapaAventura: null,
        monstrosInimigos: [],
        tier: 1,
        score: 0,
        historicoBatalhas: [],
      );

      // Salva nova história
      await repository.salvarHistoricoJogador(novaHistoria);

      // Atualiza estado local
      setState(() {
        historiaAtual = novaHistoria;
      });

      // Atualiza estado do provider
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;

      print('✅ [AventuraScreen] Nova aventura iniciada após receber recompensas');

    } catch (e) {
      print('❌ [AventuraScreen] Erro ao finalizar e iniciar nova aventura: $e');
      throw e;
    }
  }

  Future<void> _visualizarDrops() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final dropsService = DropsService();

      final drops = await dropsService.carregarDrops(emailJogador);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _ModalVisualizarDrops(drops: drops),
      );

    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Erro'),
              ],
            ),
            content: Text('Erro ao carregar prêmios: $e'),
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

class _ModalVisualizarDrops extends StatelessWidget {
  final DropJogador? drops;

  const _ModalVisualizarDrops({required this.drops});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Seus Prêmios',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: drops == null || drops!.itens.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum prêmio coletado ainda',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete aventuras e colete recompensas!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: drops!.itens.length,
                      itemBuilder: (context, index) {
                        final item = drops!.itens[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getCorTipo(item.tipo),
                              child: Icon(
                                _getIconeTipo(item.tipo),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              item.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.descricao),
                                const SizedBox(height: 4),
                                Text(
                                  'Obtido em: ${_formatarData(item.dataObtencao)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: item.quantidade > 1
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${item.quantidade}x',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            if (drops != null && drops!.itens.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total: ${drops!.itens.length} prêmios coletados',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCorTipo(String tipo) {
    switch (tipo) {
      case 'consumivel': return Colors.green;
      case 'upgrade': return Colors.purple;
      case 'moeda': return Colors.amber;
      default: return Colors.blue;
    }
  }

  IconData _getIconeTipo(String tipo) {
    switch (tipo) {
      case 'consumivel': return Icons.local_drink;
      case 'upgrade': return Icons.upgrade;
      case 'moeda': return Icons.monetization_on;
      default: return Icons.inventory;
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }
}
