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
import '../../../core/models/atributo_jogo_enum.dart';
import '../data/aventura_repository.dart';
import '../services/colecao_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/developer_config.dart';
import '../../../core/config/score_config.dart';
import 'dart:math';

class AventuraScreen extends ConsumerStatefulWidget {
  const AventuraScreen({super.key});

  @override
  ConsumerState<AventuraScreen> createState() => _AventuraScreenState();
}

class _AventuraScreenState extends ConsumerState<AventuraScreen> {
  bool _temMudancasNaoSalvas = false;
  bool _salvandoDrive = false;
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
      return 'SALVAR LOCALMENTE';
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
      debugPrint('🎮 [AventuraScreen] Iniciando verificação LOCAL do jogador: $emailJogador');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;

      final repository = ref.read(aventuraRepositoryProvider);
      debugPrint('🎮 [AventuraScreen] Repository obtido, verificando histórico LOCAL...');

      // Verifica APENAS no HIVE (sem chamadas ao Drive)
      final temHistorico = await repository.jogadorTemHistorico(emailJogador);
      debugPrint('🎮 [AventuraScreen] Tem histórico LOCAL: $temHistorico');

      if (temHistorico) {
        debugPrint('🎮 [AventuraScreen] Carregando histórico LOCAL existente...');
        final historia = await repository.carregarHistoricoJogador(emailJogador);
        debugPrint('🎮 [AventuraScreen] História LOCAL carregada: ${historia != null}');

        if (historia != null) {
          // Verifica se a aventura expirou
          if (historia.aventuraExpirada) {
            debugPrint('⏰ [AventuraScreen] Aventura expirada, removendo do Hive...');
            await repository.removerHistoricoJogador(emailJogador);

            if (mounted) {
              // Mostra modal de aventura expirada
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mostrarModalAventuraExpirada();
              });

              ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;
              debugPrint('📝 [AventuraScreen] Estado: SEM HISTÓRICO (aventura expirada)');
            }
            return;
          }

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

    // Consulta monstros nostálgicos desbloqueados da coleção
    final emailJogador = await StorageService().getLastEmail() ?? '';
    print('🎯 [AventuraScreen] Consultando coleção de monstros nostálgicos para: $emailJogador');

    final ColecaoService colecaoService = ColecaoService();
    final monstrosNostalgicosDesbloqueados = await colecaoService.obterMonstrosNostalgicosDesbloqueados(emailJogador);

    // Cria uma lista com tipos iniciais (sempre disponíveis)
    final todosOsTiposDisponiveis = <Tipo>[];
    todosOsTiposDisponiveis.addAll(tiposDisponiveis); // 30 monstros iniciais sempre

    // Adiciona monstros nostálgicos desbloqueados (expandindo as opções)
    for (final nomeNostalgico in monstrosNostalgicosDesbloqueados) {
      try {
        final tipoNostalgico = Tipo.values.firstWhere((tipo) => tipo.name == nomeNostalgico);
        // Adiciona como opção extra na roleta (não remove o inicial)
        todosOsTiposDisponiveis.add(tipoNostalgico);
        print('🌟 [AventuraScreen] Monstro nostálgico ADICIONADO à roleta: ${tipoNostalgico.name}');
      } catch (e) {
        print('⚠️ [AventuraScreen] Monstro nostálgico não encontrado nos tipos: $nomeNostalgico');
      }
    }

    todosOsTiposDisponiveis.shuffle(random);
    print('🎲 [AventuraScreen] Total de tipos disponíveis para sorteio: ${todosOsTiposDisponiveis.length}');

    final monstrosSorteados = <MonstroAventura>[];

    // Sorteia 3 tipos únicos da lista combinada (iniciais + nostálgicos)
    final tiposUnicos = <Tipo>{};
    for (int i = 0; i < todosOsTiposDisponiveis.length && tiposUnicos.length < 3; i++) {
      tiposUnicos.add(todosOsTiposDisponiveis[i]);
    }

    // Converte o Set para List para poder iterar
    final tiposSorteados = tiposUnicos.toList();

    for (int i = 0; i < tiposSorteados.length; i++) {
      final tipo = tiposSorteados[i];
      // Sorteia tipo extra diferente do principal
      final outrosTipos = todosOsTiposDisponiveis.where((t) => t != tipo).toList();
      outrosTipos.shuffle(random);
      final tipoExtra = outrosTipos.first;

      // Gera 4 habilidades para o monstro
      final habilidades = GeradorHabilidades.gerarHabilidadesMonstro(tipo, tipoExtra);

      // Sorteia atributos usando os ranges definidos
      final vidaSorteada = AtributoJogo.vida.sortear(random);
      final energiaSorteada = AtributoJogo.energia.sortear(random);
      final agilidadeSorteada = AtributoJogo.agilidade.sortear(random);
      final ataqueSorteado = AtributoJogo.ataque.sortear(random);
      final defesaSorteada = AtributoJogo.defesa.sortear(random);

      // Determina se é um monstro nostálgico desbloqueado (60% chance para nostálgico se desbloqueado)
      final temNostalgico = monstrosNostalgicosDesbloqueados.contains(tipo.name);
      final ehNostalgico = temNostalgico && random.nextDouble() < 0.6;
      final caminhoImagem = ehNostalgico
          ? 'assets/monstros_aventura/colecao_nostalgicos/${tipo.name}.png'
          : 'assets/monstros_aventura/colecao_inicial/${tipo.name}.png';

      print('🎲 [AventuraScreen] Sorteando monstro ${tipo.name} ${ehNostalgico ? '(NOSTÁLGICO)' : '(INICIAL)'}:');
      print('   - Vida: $vidaSorteada (range: ${AtributoJogo.vida.rangeTexto})');
      print('   - Energia: $energiaSorteada (range: ${AtributoJogo.energia.rangeTexto})');
      print('   - Agilidade: $agilidadeSorteada (range: ${AtributoJogo.agilidade.rangeTexto})');
      print('   - Ataque: $ataqueSorteado (range: ${AtributoJogo.ataque.rangeTexto})');
      print('   - Defesa: $defesaSorteada (range: ${AtributoJogo.defesa.rangeTexto})');
      print('   - Imagem: $caminhoImagem');

      final monstro = MonstroAventura(
        tipo: tipo,
        tipoExtra: tipoExtra,
        imagem: caminhoImagem,
        vida: vidaSorteada,
        energia: energiaSorteada,
        agilidade: agilidadeSorteada,
        ataque: ataqueSorteado,
        defesa: defesaSorteada,
        habilidades: habilidades,
        itemEquipado: null, // Sem item inicial
      );
      monstrosSorteados.add(monstro);
    }

    return monstrosSorteados;
  }

  Future<void> _sortearMonstrosComLoading() async {
    if (historiaAtual == null) return;

    // Gera novos monstros primeiro
    final novosMonstros = await _gerarNovosMonstrosLocal();

    try {
      // Mostra animação de roleta
      if (mounted) {
        await _mostrarAnimacaoRoleta(novosMonstros);

        // Atualiza APENAS localmente, NÃO salva no Drive ainda
        setState(() {
          historiaAtual = historiaAtual!.copyWith(
            monstros: novosMonstros,
            aventuraIniciada: false,
            score: 0,
            dataCriacao: DateTime.now(), // Atualiza data de criação para agora
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
    print('🎲 [AventuraScreen] Iniciando sorteio de monstros LOCAL...');
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;

    try {
      // Sorteia monstros APENAS localmente, sem salvar
      final novosMonstros = await _gerarNovosMonstrosLocal();

      // Mostra animação de roleta
      if (mounted) {
        await _mostrarAnimacaoRoleta(novosMonstros);
      }

      // Gera um runId para a nova aventura
      final runId = DateTime.now().millisecondsSinceEpoch.toString();

      // Cria história local (SEM salvar no HIVE ainda) com data atual
      final historiaLocal = HistoriaJogador(
        email: emailJogador,
        monstros: novosMonstros,
        aventuraIniciada: false,
        score: 0,
        tier: 1,
        runId: runId,
        dataCriacao: DateTime.now(), // Data de criação no horário atual do telefone
      );

      print('🎲 [AventuraScreen] Monstros sorteados localmente');
      if (mounted) {
        setState(() {
          historiaAtual = historiaLocal;
          _temMudancasNaoSalvas = true; // Marca como não salvo
        });

        // Define estado como pode iniciar para mostrar os monstros
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monstros sorteados! Clique em "SALVAR" para confirmar.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      print('✅ [AventuraScreen] Monstros sorteados com sucesso (não salvos ainda)');
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
    print('🎮 [AventuraScreen] _botaoPrincipalAction chamado');
    print('🎮 [AventuraScreen] Estado atual:');
    print('   - _temMudancasNaoSalvas: $_temMudancasNaoSalvas');
    if (historiaAtual != null) {
      print('   - historiaAtual.aventuraIniciada: ${historiaAtual!.aventuraIniciada}');
      print('   - historiaAtual.monstros.length: ${historiaAtual!.monstros.length}');
      print('   - Texto do botão: ${_getTextoBotaoAventura()}');
      print('   - Aventura expirada: ${historiaAtual!.aventuraExpirada}');
    } else {
      print('   - historiaAtual: null');
    }

    // Verifica se a aventura expirou antes de qualquer ação
    if (historiaAtual != null && historiaAtual!.aventuraExpirada) {
      print('⏰ [AventuraScreen] Aventura expirada! Mostrando modal...');
      await _mostrarModalAventuraExpirada();
      return;
    }

    if (_temMudancasNaoSalvas) {
      print('🎮 [AventuraScreen] → Executando _salvarEIniciarAventura()');
      await _salvarEIniciarAventura();
    } else if (historiaAtual != null && historiaAtual!.aventuraIniciada) {
      print('🎮 [AventuraScreen] → Executando _continuarAventura()');
      // CONTINUAR AVENTURA: apenas navega para o mapa sem sortear nem salvar
      await _continuarAventura();
    } else if (historiaAtual != null &&
               historiaAtual!.monstros.isNotEmpty &&
               !historiaAtual!.aventuraIniciada) {
      print('🎮 [AventuraScreen] → Executando _iniciarAventura() (tem monstros)');
      // Se tem monstros mas aventura não foi iniciada, inicia diretamente
      await _iniciarAventura();
    } else {
      print('🎮 [AventuraScreen] → Executando _iniciarAventura() (sem monstros)');
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
              Text('Salvando aventura no HIVE...'),
            ],
          ),
        ),
      );

      final repository = ref.read(aventuraRepositoryProvider);

      // Salva APENAS no HIVE (sem iniciar aventura ainda)
      final sucessoSalvamento = await repository.salvarHistoricoJogador(historiaAtual!);

      if (sucessoSalvamento && mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        setState(() {
          _temMudancasNaoSalvas = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aventura salva no HIVE! Agora você pode iniciar.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha ao salvar aventura no HIVE');
      }
    } catch (e) {
      if (mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar aventura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Continua aventura existente sem sortear novos inimigos nem salvar
  Future<void> _continuarAventura() async {
    if (historiaAtual == null) return;

    try {
      print('🔄 [AventuraScreen] Continuando aventura existente...');

      // Valida se tem dados necessários para continuar
      if (historiaAtual!.mapaAventura == null || historiaAtual!.monstrosInimigos.isEmpty) {
        print('⚠️ [AventuraScreen] Dados insuficientes para continuar aventura');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados da aventura incompletos. Reinicie a aventura.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('🗺️ [AventuraScreen] Navegando para mapa: ${historiaAtual!.mapaAventura}');
      print('👾 [AventuraScreen] Inimigos existentes: ${historiaAtual!.monstrosInimigos.length}');

      // Navega diretamente para o mapa sem loading desnecessário
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapaAventuraScreen(
            mapaPath: historiaAtual!.mapaAventura!,
            monstrosInimigos: historiaAtual!.monstrosInimigos,
          ),
        ),
      );

      // Atualiza estado quando voltar da aventura
      if (mounted) {
        await _verificarEstadoJogador();
      }

      print('✅ [AventuraScreen] Retorno da aventura continuada');
    } catch (e) {
      print('❌ [AventuraScreen] Erro ao continuar aventura: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao continuar aventura: $e'),
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
      debugPrint('🚀 [AventuraScreen] Dados atuais antes de iniciar:');
      if (historiaAtual != null) {
        debugPrint('   - Monstros jogador: ${historiaAtual!.monstros.length}');
        debugPrint('   - Aventura iniciada: ${historiaAtual!.aventuraIniciada}');
        debugPrint('   - Inimigos: ${historiaAtual!.monstrosInimigos.length}');
      }

      final historiaAtualizada = await repository.iniciarAventura(emailJogador);

      if (historiaAtualizada != null) {
        debugPrint('🚀 [AventuraScreen] Aventura processada com sucesso!');
        debugPrint('💾 [AventuraScreen] Salvamento no HIVE e Drive concluído');

        if (mounted) {
          setState(() {
            historiaAtual = historiaAtualizada;
          });

          // Remove o loading ANTES de navegar
          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.aventuraIniciada;
        } else {
          debugPrint('⚠️ [AventuraScreen] Widget não está montado ao tentar atualizar estado');
        }

        // Determina se é aventura nova ou continuada
        final isAventuraNova = historiaAtualizada.aventuraIniciada &&
                               historiaAtualizada.monstrosInimigos.isNotEmpty &&
                               historiaAtualizada.mapaAventura != null;

        // Mensagem de sucesso
        final mensagem = isAventuraNova
            ? 'Aventura iniciada! Boa sorte na jornada!'
            : 'Aventura continuada! Bem-vindo de volta!';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagem),
              backgroundColor: Colors.green,
            ),
          );
        }

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
        title: const Text('Equipe'),
        centerTitle: true,
        elevation: 2,
        automaticallyImplyLeading: false, // Remove o botão voltar
        actions: [
          // Botão temporário para deletar do HIVE
          if (DeveloperConfig.ENABLE_TYPE_EDITING)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: _deletarDoHive,
              tooltip: 'Deletar aventura do HIVE (temporário)',
            ),
          // Botão para listar arquivos na pasta do Drive
          // Botão para salvar no Drive
          if (historiaAtual != null)
            IconButton(
              icon: _salvandoDrive
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _salvandoDrive ? null : _uploadParaDrive,
              tooltip: _salvandoDrive ? 'Salvando...' : 'Salvar aventura no Drive + Ranking',
            ),
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
      body: Stack(
        children: [
          Container(
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
          // Overlay de loading durante salvamento
          if (_salvandoDrive)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Salvando aventura no Drive...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                'Verificando dados locais',
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
                          SizedBox(height: 16),
                          // Botão de sincronização com Drive
                          if (DeveloperConfig.ENABLE_TYPE_EDITING)
                            SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _sincronizarComDrive,
                                  splashColor: Colors.blue.shade100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue.shade400, Colors.cyan.shade400],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.18),
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
                                          Icon(Icons.cloud_download, color: Colors.white, size: 26),
                                          Text(
                                            'SINCRONIZAR COM DRIVE',
                                            style: TextStyle(
                                              fontSize: 14,
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
        // Botão Iniciar Aventura (oculta após aventura iniciada)
        if (historiaAtual == null || !historiaAtual!.aventuraIniciada)
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
                        Icon(
                          _getIconeBotaoAventura(),
                          color: Colors.white,
                          size: 26,
                        ),
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
        // Botão Recomeçar Aventura (só aparece se aventura está iniciada)
        if (historiaAtual != null && historiaAtual!.aventuraIniciada) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _podeUsarBotaoConquistas() ? _mostrarModalRecomecarAventura : null,
                splashColor: Colors.red.shade100,
                child: Opacity(
                  opacity: _podeUsarBotaoConquistas() ? 1.0 : 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.18),
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
                          Icon(Icons.refresh, color: Colors.white, size: 26),
                          Text(
                            'RECOMEÇAR AVENTURA',
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

  Future<void> _mostrarModalRecomecarAventura() async {
    if (historiaAtual == null) return;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.red.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Recomeçar Aventura',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Sua aventura atual será encerrada PERMANENTEMENTE. O score será registrado no ranking, mas você NÃO receberá recompensas.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Score atual: ${historiaAtual != null ? ScoreConfig.formatarScoreExibicao(historiaAtual!.tier, historiaAtual!.score) : "0"} pontos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Deseja continuar?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Recomeçar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmar == true) {
      await _recomecarAventura();
    }
  }

  Future<void> _recomecarAventura() async {
    if (historiaAtual == null) return;

    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);

      // Registra score no ranking SEM gerar recompensas
      await _registrarScoreSemRecompensas(emailJogador, repository);

      // Finaliza aventura atual e inicia nova
      await _finalizarEIniciarNovaAventura();

      // Fecha loading
      if (mounted) Navigator.of(context).pop();

      // Atualiza estado local
      if (mounted) {
        setState(() {
          historiaAtual = null;
        });
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aventura recomeçada! Agora você pode sortear novos monstros.'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      // Fecha loading se aberto
      if (mounted) Navigator.of(context).pop();

      // Mostra erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao recomeçar aventura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registrarScoreSemRecompensas(String emailJogador, dynamic repository) async {
    try {
      if (historiaAtual != null) {
        int scoreReal = _calcularScoreReal(historiaAtual!);

        print('🔄 [AventuraScreen] Registrando score sem recompensas');
        print('🎯 [AventuraScreen] Score calculado: $scoreReal, Tier: ${historiaAtual!.tier}');

        // Atualiza apenas o ranking (sem gerar recompensas)
        try {
          await repository.atualizarRankingPorScore(historiaAtual!);
          print('✅ [AventuraScreen] Score registrado no ranking com sucesso!');
        } catch (e) {
          if (e.toString().contains('401') || e.toString().contains('authentication')) {
            print('🔄 [AventuraScreen] Erro 401 no ranking, renovando autenticação...');
            await GoogleDriveService().inicializarConexao();
            await repository.atualizarRankingPorScore(historiaAtual!);
            print('✅ [AventuraScreen] Score registrado após renovação da autenticação');
          } else {
            throw e;
          }
        }
      } else {
        print('⚠️ [AventuraScreen] Histórico não encontrado para registro de score');
      }
    } catch (e) {
      print('❌ [AventuraScreen] Erro ao registrar score: $e');
      throw e;
    }
  }

  Future<void> _finalizarEIniciarNovaAventura() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = AventuraRepository();

      // Carrega o historico atual para obter o runId
      print('[AventuraScreen] Carregando historico para arquivar...');
      HistoriaJogador? historiaAtual;
      try {
        historiaAtual = await repository.carregarHistoricoJogador(emailJogador);
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('authentication')) {
          print('[AventuraScreen] Erro 401 detectado, renovando autenticacao...');
          await GoogleDriveService().inicializarConexao();
          historiaAtual = await repository.carregarHistoricoJogador(emailJogador);
          print('[AventuraScreen] Historico carregado apos renovacao da autenticacao');
        } else {
          throw e;
        }
      }

      bool removeLocalSucesso = false;

      if (historiaAtual != null && historiaAtual.runId.isNotEmpty) {
        print('[AventuraScreen] RunID encontrado: ${historiaAtual.runId}, iniciando arquivamento...');
        // Arquiva o historico atual renomeando com o runId
        bool sucessoArquivamento = false;
        try {
          sucessoArquivamento = await repository.arquivarHistoricoJogador(emailJogador, historiaAtual.runId);
        } catch (e) {
          if (e.toString().contains('401') || e.toString().contains('authentication')) {
            print('[AventuraScreen] Erro 401 no arquivamento, renovando autenticacao...');
            await GoogleDriveService().inicializarConexao();
            sucessoArquivamento = await repository.arquivarHistoricoJogador(emailJogador, historiaAtual.runId);
            print('[AventuraScreen] Arquivamento realizado apos renovacao da autenticacao');
          } else {
            throw e;
          }
        }

        if (sucessoArquivamento) {
          print('[AventuraScreen] Historico arquivado com sucesso com RunID: ${historiaAtual.runId}');
        } else {
          print('[AventuraScreen] FALHA ao arquivar historico com RunID: ${historiaAtual.runId}');
        }

        removeLocalSucesso = await _removerHistoricoLocal(repository, emailJogador);
      } else {
        print('[AventuraScreen] Historia nula ou sem RunID (${historiaAtual?.runId}), removendo historico...');
        removeLocalSucesso = await _removerHistoricoLocal(repository, emailJogador);
      }

      if (!removeLocalSucesso) {
        throw Exception('Falha ao remover historico local do HIVE ao recomecar aventura');
      }

      print('[AventuraScreen] Primeira aventura disponivel');

    } catch (e) {
      print('[AventuraScreen] Erro ao finalizar e iniciar nova aventura: $e');
      throw e;
    }
  }

  Future<bool> _removerHistoricoLocal(AventuraRepository repository, String emailJogador) async {
    try {
      final sucessoLocal = await repository.removerHistoricoJogador(emailJogador);
      if (sucessoLocal) {
        print('[AventuraScreen] Historico local removido do HIVE');
      } else {
        print('[AventuraScreen] Falha ao remover historico local do HIVE');
      }
      return sucessoLocal;
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('[AventuraScreen] Erro 401 ao remover historico local, renovando autenticacao...');
        await GoogleDriveService().inicializarConexao();
        final sucessoLocal = await repository.removerHistoricoJogador(emailJogador);
        if (sucessoLocal) {
          print('[AventuraScreen] Historico local removido do HIVE apos renovacao da autenticacao');
        } else {
          print('[AventuraScreen] Falha ao remover historico local do HIVE apos renovacao da autenticacao');
        }
        return sucessoLocal;
      }

      print('[AventuraScreen] Erro ao remover historico local do HIVE: $e');
      throw e;
    }
  }

  /// Calcula score real baseado no progresso da aventura
  int _calcularScoreReal(HistoriaJogador historia) {
    int score = 0;

    // Score APENAS por batalhas realizadas (cada batalha ganha vale 15 pontos)
    // Só conta se realmente teve batalhas, não só ter iniciado aventura
    score += historia.historicoBatalhas.length * 15;

    // Score por melhorias dos monstros (só conta se realmente melhoraram)
    for (var monstro in historia.monstros) {
      // Score baseado no level do monstro (só se > 1)
      if (monstro.level > 1) {
        score += (monstro.level - 1) * 3;
      }

      // Score por item equipado (se tiver)
      if (monstro.itemEquipado != null) {
        score += 5;
      }

      // Score por habilidades melhoradas (só se level > 1)
      for (var habilidade in monstro.habilidades) {
        if (habilidade.level > 1) {
          score += (habilidade.level - 1) * 2;
        }
      }
    }

    // Score bônus por tier alto (só após ter algum progresso real)
    if (score > 0) {
      score += historia.tier * 2; // Reduzido de 10 para 2
    }

    // Score mínimo é 0 (sem progresso = sem recompensa)
    score = score.clamp(0, 100);

    print('📊 [AventuraScreen] Score calculado: $score');
    print('   - Batalhas ganhas: ${historia.historicoBatalhas.length} × 15 = ${historia.historicoBatalhas.length * 15}');
    print('   - Tier bônus: ${score > 0 ? historia.tier * 2 : 0}');
    print('   - Monstros: ${historia.monstros.length} (não dá pontos base)');
    print('   - Levels/itens dos monstros: pontos variáveis');

    return score;
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
          'Para obter novos monstros, você precisará usar o botão "Recomeçar Aventura". '
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
      await _iniciarAventura();
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
          context.go('/aventura/mapa', extra: historiaAtual);
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

  Future<void> _salvarNoDrive() async {
    if (_salvandoDrive) return; // Evita múltiplos cliques

    final emailJogador = ref.read(validUserEmailProvider);
    final repository = ref.read(aventuraRepositoryProvider);

    setState(() {
      _salvandoDrive = true;
    });

    try {
      print('💾 [AventuraScreen] Iniciando salvamento manual no Drive...');

      // Carrega a aventura atual do HIVE
      final aventuraAtual = await repository.carregarHistoricoJogador(emailJogador);

      if (aventuraAtual == null) {
        _mostrarSnackBar('Nenhuma aventura encontrada para salvar', Colors.orange);
        return;
      }

      // Força salvamento no Drive usando o método de upload manual
      final sucesso = await repository.salvarNoDriveManual(emailJogador);

      if (sucesso) {
        _mostrarSnackBar('Aventura salva no Drive com sucesso!', Colors.green);
        print('✅ [AventuraScreen] Salvamento no Drive concluído');
      } else {
        _mostrarSnackBar('Erro ao salvar no Drive', Colors.red);
        print('❌ [AventuraScreen] Falha no salvamento no Drive');
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao salvar: $e', Colors.red);
      print('❌ [AventuraScreen] Exceção durante salvamento: $e');
    } finally {
      if (mounted) {
        setState(() {
          _salvandoDrive = false;
        });
      }
    }
  }

  Future<void> _listarArquivosDrive() async {
    final emailJogador = ref.read(validUserEmailProvider);
    final driveService = GoogleDriveService();

    try {
      print('📂 [AventuraScreen] Listando arquivos na pasta do Drive...');

      // Cria o caminho com data atual e email do jogador
      final hoje = DateTime.now().subtract(const Duration(hours: 3));
      final dataFormatada = '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final caminhoCompleto = 'historias/$dataFormatada/$emailJogador';

      print('📁 [AventuraScreen] Caminho: $caminhoCompleto');

      // Lista arquivos na pasta específica
      final arquivos = await driveService.listarArquivosDaPasta(caminhoCompleto);

      if (arquivos.isEmpty) {
        print('📭 [AventuraScreen] Nenhum arquivo encontrado na pasta');
        _mostrarSnackBar('Nenhum arquivo encontrado na pasta', Colors.orange);
      } else {
        print('📋 [AventuraScreen] Arquivos encontrados:');
        for (int i = 0; i < arquivos.length; i++) {
          print('   ${i + 1}. ${arquivos[i]}');
        }
        _mostrarSnackBar('${arquivos.length} arquivo(s) encontrado(s). Ver logs.', Colors.blue);
      }
    } catch (e) {
      print('❌ [AventuraScreen] Erro ao listar arquivos: $e');
      _mostrarSnackBar('Erro ao listar arquivos: $e', Colors.red);
    }
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: cor,
          duration: const Duration(seconds: 3),
        ),
      );
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

  /// MÉTODO TEMPORÁRIO: Deleta aventura do HIVE
  Future<void> _deletarDoHive() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar do HIVE'),
        content: const Text(
          'Isso irá remover a aventura do armazenamento local (HIVE). '
          'Tem certeza que deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

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
              Text('Removendo do HIVE...'),
            ],
          ),
        ),
      );

      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);

      // Remove do HIVE
      final sucesso = await repository.removerHistoricoJogador(emailJogador);

      if (mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        if (sucesso) {
          // Atualiza estado local
          setState(() {
            historiaAtual = null;
          });
          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aventura removida do HIVE com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao remover aventura do HIVE.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sincroniza aventura local com o Drive
  /// Baixa aventura do Drive diretamente
  Future<void> _sincronizarComDrive() async {
    _baixarDoDrive();
  }

  /// Baixa aventura do Drive para local
  Future<void> _baixarDoDrive() async {
    try {
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
              Text('Baixando do Drive...'),
            ],
          ),
        ),
      );

      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);

      // Baixa do Drive
      final resultado = await repository.sincronizarComDrive(emailJogador);

      if (mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        if (resultado['sucesso']) {
          // Recarrega a tela
          await _verificarEstadoJogador();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['mensagem']),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Mostra mensagem de erro/não encontrado
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Download'),
              content: Text(resultado['mensagem']),
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
    } catch (e) {
      if (mounted) {
        // Fecha o loading se ainda estiver aberto
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Faz upload da aventura atual para Drive e atualiza ranking
  Future<void> _uploadParaDrive() async {
    // Verifica se a aventura expirou antes de salvar
    if (historiaAtual != null && historiaAtual!.aventuraExpirada) {
      print('⏰ [AventuraScreen] Tentativa de salvar aventura expirada!');
      await _mostrarModalAventuraExpirada();
      return;
    }

    try {
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
              Text('Salvando no Drive e atualizando ranking...'),
            ],
          ),
        ),
      );

      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);

      // Faz upload para Drive com ranking
      final resultado = await repository.uploadParaDriveComRanking(emailJogador);

      if (mounted) {
        // Fecha o loading
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['mensagem']),
            backgroundColor: resultado['sucesso'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fecha o loading se ainda estiver aberto
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostra animação de roleta para sorteio de monstros
  Future<void> _mostrarAnimacaoRoleta(List<dynamic> novosMonstros) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => _RoletaMonstrosWidget(
        monstrosSorteados: novosMonstros,
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
              // Ícone de aventura expirada
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

              // Botão OK
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Entendi',
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
}

/// Widget de animação da roleta de monstros
class _RoletaMonstrosWidget extends StatefulWidget {
  final List<dynamic> monstrosSorteados;

  const _RoletaMonstrosWidget({
    required this.monstrosSorteados,
  });

  @override
  State<_RoletaMonstrosWidget> createState() => _RoletaMonstrosWidgetState();
}

class _RoletaMonstrosWidgetState extends State<_RoletaMonstrosWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  List<List<String>> _imagensRolando = [[], [], []];
  bool _animacaoCompleta = false;

  @override
  void initState() {
    super.initState();
    _inicializarAnimacoes();
    _iniciarRoleta();
  }

  void _inicializarAnimacoes() {
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 500)), // Cada slot para em tempo diferente
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCirc),
      );
    }).toList();

    // Gera lista de imagens aleatórias para cada slot
    for (int i = 0; i < 3; i++) {
      _imagensRolando[i] = _gerarMonstrosParaRoleta(widget.monstrosSorteados[i]);
    }
  }

  List<String> _gerarMonstrosParaRoleta(dynamic monstroFinal) {
    final imagensAleatorias = <String>[];

    // Usar os tipos enum reais para gerar as imagens
    final tiposDisponiveis = [
      'fogo', 'agua', 'eletrico', 'gelo', 'vento', 'luz', 'trevas',
      'psiquico', 'inseto', 'voador', 'planta', 'pedra', 'terrestre',
      'marinho', 'dragao', 'fantasma', 'mistico', 'alien'
    ];

    // Adiciona 15 imagens aleatórias antes da imagem final
    for (int i = 0; i < 15; i++) {
      tiposDisponiveis.shuffle();
      imagensAleatorias.add('assets/monstros_aventura/colecao_inicial/${tiposDisponiveis.first}.png');
    }

    // Adiciona a imagem do monstro final sorteado
    imagensAleatorias.add(monstroFinal.imagem);

    return imagensAleatorias;
  }

  void _iniciarRoleta() async {
    // Inicia as animações com delay escalonado
    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: 200));
      _controllers[i].forward();
    }

    // Aguarda todas as animações terminarem
    await Future.delayed(Duration(milliseconds: 3500));

    if (mounted) {
      setState(() {
        _animacaoCompleta = true;
      });

      // Fecha a animação após um tempo
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade800, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título
              Container(
                padding: EdgeInsets.all(20),
                child: Text(
                  '🎰 SORTEANDO MONSTROS 🎰',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // Slots da roleta
              Container(
                height: 120,
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.yellow, width: 3),
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: _buildSlotRoleta(index),
                      ),
                    );
                  }),
                ),
              ),

              // Indicador de progresso
              Container(
                padding: EdgeInsets.all(20),
                child: _animacaoCompleta
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Sorteio Completo!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Sorteando...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
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

  Widget _buildSlotRoleta(int slotIndex) {
    return AnimatedBuilder(
      animation: _animations[slotIndex],
      builder: (context, child) {
        final progress = _animations[slotIndex].value;
        final imagens = _imagensRolando[slotIndex];

        // Calcula qual imagem mostrar baseado no progresso
        final indiceAtual = (progress * (imagens.length - 1)).floor();
        final proximoIndice = (indiceAtual + 1).clamp(0, imagens.length - 1);

        // Interpolação suave entre imagens (altura aumentada para 100px)
        final offset = (progress * (imagens.length - 1)) % 1;
        final alturaSlot = 100.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: alturaSlot,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Imagem atual
                Transform.translate(
                  offset: Offset(0, -alturaSlot * offset),
                  child: SizedBox(
                    height: alturaSlot,
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: indiceAtual < imagens.length
                          ? Image.asset(
                              imagens[indiceAtual],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.casino, color: Colors.white, size: 40);
                              },
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
                ),
                // Próxima imagem
                Transform.translate(
                  offset: Offset(0, alturaSlot - (alturaSlot * offset)),
                  child: SizedBox(
                    height: alturaSlot,
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: proximoIndice < imagens.length
                          ? Image.asset(
                              imagens[proximoIndice],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.casino, color: Colors.white, size: 40);
                              },
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
                ),
                // Efeito de destaque quando parar
                if (_animacaoCompleta && _controllers[slotIndex].isCompleted)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.yellow, width: 3),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
