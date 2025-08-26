import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/aventura_provider.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../../../core/providers/user_provider.dart';
import 'card_monstro_aventura.dart';
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

      final temHistorico = await repository.jogadorTemHistorico(emailJogador);
      debugPrint('🎮 [AventuraScreen] Tem histórico: $temHistorico');

      if (temHistorico) {
        debugPrint('🎮 [AventuraScreen] Carregando histórico existente...');
        final historia = await repository.carregarHistoricoJogador(emailJogador);
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.casino,
                      size: 64,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Primeira Aventura!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Você ainda não possui monstros.\nSorteie 3 monstros para começar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _sortearMonstros,
                icon: const Icon(Icons.casino),
                label: const Text('SORTEAR MONSTROS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
        Row(
          children: historiaAtual!.monstros.map<Widget>((monstro) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: _buildCardMonstroBonito(monstro),
              ),
            );
          }).toList(),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  monstro.imagem,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(monstro.tipo.iconAsset, width: 32, height: 32, fit: BoxFit.contain),
                  const SizedBox(width: 8),
                  Image.asset(monstro.tipoExtra.iconAsset, width: 32, height: 32, fit: BoxFit.contain),
                ],
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

}
