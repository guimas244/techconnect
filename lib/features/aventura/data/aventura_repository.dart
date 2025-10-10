import 'dart:convert';
import 'dart:math';
import '../../../core/services/google_drive_service.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/models/atributo_jogo_enum.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/item.dart';
import '../models/habilidade.dart';
import '../utils/gerador_habilidades.dart';
import '../services/item_service.dart';
import '../services/ranking_service.dart';
import '../services/aventura_hive_service.dart';
import '../services/colecao_service.dart';
import '../../tipagem/data/tipagem_repository.dart';

class AventuraRepository {
  final GoogleDriveService _driveService = GoogleDriveService();
  final TipagemRepository _tipagemRepository = TipagemRepository();
  final ItemService _itemService = ItemService();
  final RankingService _rankingService = RankingService();
  final AventuraHiveService _hiveService = AventuraHiveService();
  final ColecaoService _colecaoService = ColecaoService();

  /// Inicializa o repository (deve ser chamado no início do app)
  Future<void> init() async {
    await _hiveService.init();
  }

  /// Verifica se o jogador já tem um histórico local (HIVE)
  Future<bool> jogadorTemHistorico(String email) async {
    try {
      print('🔍 [Repository] Verificando histórico LOCAL (HIVE) para: $email');

      // Primeiro verifica no HIVE (prioridade)
      final temHistoricoLocal = await _hiveService.temAventura(email);
      print('🔍 [Repository] Tem histórico LOCAL: $temHistoricoLocal');
      return temHistoricoLocal;
    } catch (e) {
      print('❌ [Repository] Erro ao verificar histórico local: $e');
      return false;
    }
  }

  /// Carrega o histórico do jogador (HIVE prioritário)
  Future<HistoriaJogador?> carregarHistoricoJogador(String email) async {
    try {
      print('📥 [Repository] Carregando histórico LOCAL (HIVE) para: $email');

      // Carrega do HIVE (prioridade)
      final historia = await _hiveService.carregarAventura(email);

      if (historia != null) {
        print('✅ [Repository] História carregada do HIVE: ${historia.monstros.length} monstros');
        return historia;
      }

      print('📭 [Repository] Nenhum histórico encontrado no HIVE');
      return null;
    } catch (e) {
      print('❌ [Repository] Erro ao carregar histórico local: $e');
      return null;
    }
  }

  /// Salva o histórico do jogador no HIVE (local) e sincroniza com Drive
  Future<bool> salvarHistoricoJogador(HistoriaJogador historia) async {
    try {
      print('💾 [Repository] Salvando histórico LOCAL (HIVE) para: ${historia.email}');
      print('💾 [Repository] Dados da história:');
      print('   - Email: ${historia.email}');
      print('   - Monstros: ${historia.monstros.length}');
      print('   - Aventura iniciada: ${historia.aventuraIniciada}');
      print('   - Mapa: ${historia.mapaAventura}');
      print('   - Inimigos: ${historia.monstrosInimigos.length}');

      // Salva no HIVE (prioridade)
      print('💾 [Repository] Dados a serem salvos no HIVE:');
      print('   - Email: ${historia.email}');
      print('   - Monstros jogador: ${historia.monstros.length}');
      print('   - Aventura iniciada: ${historia.aventuraIniciada}');
      print('   - Mapa: ${historia.mapaAventura ?? "null"}');
      print('   - Inimigos: ${historia.monstrosInimigos.length}');

      final sucessoLocal = await _hiveService.salvarAventura(historia);

      if (sucessoLocal) {
        print('✅ [Repository] Histórico salvo localmente (HIVE)');

        // Só salva no Drive quando aventura for INICIADA (botão iniciar aventura)
        if (historia.aventuraIniciada) {
          print('🌐 [Repository] Aventura iniciada, sincronizando com Drive...');
          final sucessoDrive = await _salvarNoDrive(historia);
          if (sucessoDrive) {
            print('✅ [Repository] Histórico também salvo no Drive');
          } else {
            print('⚠️ [Repository] Falha no Drive, mas dados salvos localmente');
          }
        } else {
          print('📝 [Repository] Aventura não iniciada, mantendo apenas local');
        }

        return true;
      } else {
        print('❌ [Repository] FALHA ao salvar localmente');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [Repository] EXCEÇÃO ao salvar histórico: $e');
      print('❌ [Repository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Método privado para salvar no Drive (usado apenas quando necessário)
  Future<bool> _salvarNoDrive(HistoriaJogador historia) async {
    try {
      // Cria o caminho com data atual e email do jogador
      final hoje = DateTime.now().subtract(const Duration(hours: 3)); // Horário Brasília
      final dataFormatada = '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final caminhoCompleto = 'historias/$dataFormatada/${historia.email}';
      final nomeArquivo = 'historico_${historia.email}.json';

      print('📅 [Repository] Data atual formatada: $dataFormatada');
      print('📁 [Repository] Caminho completo: $caminhoCompleto');
      print('📄 [Repository] Nome do arquivo: $nomeArquivo');

      // Serializa JSON
      final jsonData = historia.toJson();
      final json = jsonEncode(jsonData);

      print('💾 [Repository] Salvando no Drive...');
      // Salva no Drive
      final sucesso = await _driveService.salvarArquivoEmPasta(nomeArquivo, json, caminhoCompleto);

      if (sucesso) {
        print('✅ [Repository] Arquivo salvo com sucesso no Drive em: $caminhoCompleto/$nomeArquivo');
      } else {
        print('❌ [Repository] Falha ao salvar arquivo no Drive');
      }

      return sucesso;
    } catch (e) {
      print('❌ [Repository] Erro ao salvar no Drive: $e');
      return false;
    }
  }

  /// Sincroniza dados com Drive (DOWNLOAD - baixa do Drive para HIVE local)
  Future<Map<String, dynamic>> sincronizarComDrive(String email) async {
    try {
      print('🌐 [Repository] Iniciando sincronização (download) do Drive para: $email');
      print('📝 [Repository] Buscando arquivo: historico_$email.json');

      // Cria o caminho com data atual e email do jogador
      final hoje = DateTime.now().subtract(const Duration(hours: 3));
      final dataFormatada = '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final caminhoCompleto = 'historias/$dataFormatada/$email';
      final nomeArquivo = 'historico_$email.json';

      print('📁 [Repository] Caminho completo: $caminhoCompleto/$nomeArquivo');

      // Tenta baixar do Drive
      final conteudo = await _driveService.baixarArquivoDaPasta(nomeArquivo, caminhoCompleto);

      if (conteudo.isEmpty) {
        print('📭 [Repository] Arquivo não encontrado no Drive');
        return {
          'sucesso': false,
          'mensagem': 'Nenhuma aventura encontrada no Drive para hoje ($dataFormatada).\n\nQue tal iniciar uma nova aventura?',
          'dados': null
        };
      }

      // Parse do JSON
      final jsonData = jsonDecode(conteudo);
      final historiaDownload = HistoriaJogador.fromJson(jsonData);

      // Salva no HIVE local
      final sucessoLocal = await _hiveService.salvarAventura(historiaDownload);

      if (sucessoLocal) {
        print('✅ [Repository] Sincronização concluída - dados baixados do Drive');
        return {
          'sucesso': true,
          'mensagem': 'Aventura sincronizada com sucesso do Drive!',
          'dados': historiaDownload
        };
      } else {
        print('❌ [Repository] Falha ao salvar no HIVE local');
        return {
          'sucesso': false,
          'mensagem': 'Erro ao salvar dados localmente',
          'dados': null
        };
      }
    } catch (e) {
      print('❌ [Repository] Erro na sincronização: $e');
      return {
        'sucesso': false,
        'mensagem': 'Erro ao sincronizar com Drive: $e',
        'dados': null
      };
    }
  }

  /// Salva aventura local no Drive (método para botão de salvar)
  Future<bool> salvarNoDriveManual(String email) async {
    try {
      print('🌐 [Repository] Iniciando upload manual para Drive para: $email');
      print('📝 [Repository] Nome do arquivo que será salvo: historico_$email.json');

      // Carrega aventura local do HIVE
      final aventuraLocal = await _hiveService.carregarAventura(email);
      if (aventuraLocal == null) {
        print('📭 [Repository] Nenhuma aventura local encontrada no HIVE');
        return false;
      }

      print('📤 [Repository] Enviando aventura local para o Drive...');
      // Salva no Drive
      final sucessoDrive = await _salvarNoDrive(aventuraLocal);
      if (sucessoDrive) {
        print('✅ [Repository] Upload para Drive concluído com sucesso');
        return true;
      } else {
        print('❌ [Repository] Falha no upload para Drive');
        return false;
      }
    } catch (e) {
      print('❌ [Repository] Erro no upload manual: $e');
      return false;
    }
  }

  /// Salva histórico apenas no HIVE (para atualizações durante batalha)
  Future<bool> salvarHistoricoJogadorLocal(HistoriaJogador historia) async {
    try {
      print('💾 [Repository] Salvando histórico APENAS NO HIVE (batalha)');
      print('💾 [Repository] Dados da batalha:');
      print('   - Email: ${historia.email}');
      print('   - Monstros jogador: ${historia.monstros.length}');
      print('   - Aventura iniciada: ${historia.aventuraIniciada}');
      print('   - Batalhas: ${historia.historicoBatalhas.length}');
      print('   - Score: ${historia.score}');

      // Salva APENAS no HIVE (sem Drive)
      final sucessoLocal = await _hiveService.salvarAventura(historia);

      if (sucessoLocal) {
        print('✅ [Repository] Histórico de batalha salvo localmente (HIVE)');
        return true;
      } else {
        print('❌ [Repository] FALHA ao salvar histórico de batalha localmente');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [Repository] EXCEÇÃO ao salvar histórico de batalha: $e');
      print('❌ [Repository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Faz upload da aventura atual para Drive e atualiza ranking
  Future<Map<String, dynamic>> uploadParaDriveComRanking(String email) async {
    try {
      print('🌐 [Repository] Iniciando upload para Drive com ranking para: $email');

      // Carrega a aventura atual do HIVE
      final historiaAtual = await carregarHistoricoJogador(email);

      if (historiaAtual == null) {
        return {
          'sucesso': false,
          'mensagem': 'Nenhuma aventura encontrada localmente para fazer upload.',
          'dados': null
        };
      }

      // Salva no Drive e atualiza ranking
      final sucessoUpload = await salvarHistoricoEAtualizarRanking(historiaAtual);

      if (sucessoUpload) {
        print('✅ [Repository] Upload e ranking atualizados com sucesso');
        return {
          'sucesso': true,
          'mensagem': 'Aventura salva no Drive e ranking atualizado com sucesso!',
          'dados': historiaAtual
        };
      } else {
        return {
          'sucesso': false,
          'mensagem': 'Falha ao salvar no Drive ou atualizar ranking.',
          'dados': null
        };
      }

    } catch (e) {
      print('❌ [Repository] Erro no upload com ranking: $e');
      return {
        'sucesso': false,
        'mensagem': 'Erro ao salvar: $e',
        'dados': null
      };
    }
  }

  /// Baixa aventura do Drive para HIVE (para botão de sincronização)
  Future<bool> baixarDoDrive(String email) async {
    try {
      print('📥 [Repository] Baixando aventura do Drive para: $email');

      // Cria o caminho com data atual e email do jogador
      final hoje = DateTime.now().subtract(const Duration(hours: 3)); // Horário Brasília
      final dataFormatada = '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final caminhoCompleto = 'historias/$dataFormatada/$email';
      final nomeArquivo = 'historico_$email.json';

      final conteudo = await _driveService.baixarArquivoDaPasta(nomeArquivo, caminhoCompleto);

      if (conteudo.isEmpty) {
        print('📭 [Repository] Nenhuma aventura encontrada no Drive');
        return false;
      }

      // Converte para objeto
      final json = jsonDecode(conteudo);
      final historia = HistoriaJogador.fromJson(json);

      // Salva no HIVE
      final sucessoLocal = await _hiveService.salvarAventura(historia);
      if (sucessoLocal) {
        print('✅ [Repository] Aventura baixada e salva localmente');
        return true;
      } else {
        print('❌ [Repository] Falha ao salvar localmente após download');
        return false;
      }
    } catch (e) {
      print('❌ [Repository] Erro ao baixar do Drive: $e');
      return false;
    }
  }

  /// Sorteia 3 monstros únicos para o jogador e já cria a aventura
  Future<HistoriaJogador> sortearMonstrosParaJogador(String email) async {
    // Verifica se já existe uma aventura e arquiva antes de criar uma nova
    print('🔍 [Repository] Verificando aventura existente antes de sortear novos monstros...');
    final aventuraExistente = await carregarHistoricoJogador(email);

    if (aventuraExistente != null && aventuraExistente.runId.isNotEmpty) {
      print('📦 [Repository] Aventura existente encontrada (RunID: ${aventuraExistente.runId}), arquivando antes de criar nova...');
      final sucessoArquivamento = await arquivarHistoricoJogador(email, aventuraExistente.runId);

      if (sucessoArquivamento) {
        print('✅ [Repository] Aventura anterior arquivada com sucesso');
      } else {
        print('❌ [Repository] Falha ao arquivar aventura anterior, mas continuando...');
      }
    } else if (aventuraExistente != null) {
      print('⚠️ [Repository] Aventura existente sem RunID, removendo antes de criar nova...');
      await removerHistoricoJogador(email);
    }

    // Consulta monstros nostálgicos desbloqueados da coleção
    print('🎯 [Repository] Consultando coleção de monstros nostálgicos para: $email');
    final monstrosNostalgicosDesbloqueados = await _colecaoService.obterMonstrosNostalgicosDesbloqueados(email);

    final random = Random();
    final tiposDisponiveis = Tipo.values.toList();

    // Cria uma lista com tipos iniciais (sempre disponíveis)
    final todosOsTiposDisponiveis = <Tipo>[];
    todosOsTiposDisponiveis.addAll(tiposDisponiveis); // 30 monstros iniciais sempre

    // Adiciona monstros nostálgicos desbloqueados (expandindo as opções)
    for (final nomeNostalgico in monstrosNostalgicosDesbloqueados) {
      // Converte nome do monstro nostálgico para Tipo (se existir)
      try {
        final tipoNostalgico = Tipo.values.firstWhere((tipo) => tipo.name == nomeNostalgico);
        // Adiciona como opção extra na roleta (não remove o inicial)
        todosOsTiposDisponiveis.add(tipoNostalgico);
        print('🌟 [Repository] Monstro nostálgico ADICIONADO à roleta: ${tipoNostalgico.name}');
      } catch (e) {
        print('⚠️ [Repository] Monstro nostálgico não encontrado nos tipos: $nomeNostalgico');
      }
    }

    // Embaralha todos os tipos disponíveis (iniciais + nostálgicos)
    todosOsTiposDisponiveis.shuffle(random);
    print('🎲 [Repository] Total de tipos disponíveis para sorteio: ${todosOsTiposDisponiveis.length}');
    print('📋 [Repository] Monstros nostálgicos desbloqueados: ${monstrosNostalgicosDesbloqueados.length}');
    print('🔍 [Repository] Lista nostálgicos: $monstrosNostalgicosDesbloqueados');

    final monstrosSorteados = <MonstroAventura>[];

    // Sorteia 3 tipos únicos da lista combinada
    final tiposUnicos = <Tipo>{};
    for (int i = 0; i < todosOsTiposDisponiveis.length && tiposUnicos.length < 3; i++) {
      tiposUnicos.add(todosOsTiposDisponiveis[i]);
    }

    // Converte o Set para List para poder iterar
    final tiposSorteados = tiposUnicos.toList();

    for (int i = 0; i < tiposSorteados.length; i++) {
      final tipo = tiposSorteados[i];
      // Sorteia tipo extra diferente do principal (usando todos os tipos disponíveis)
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

      // Determina se é um monstro nostálgico desbloqueado
      // Como temos duplicados na roleta, damos 60% de chance para nostálgico se desbloqueado
      final temNostalgico = monstrosNostalgicosDesbloqueados.contains(tipo.name);
      final ehNostalgico = temNostalgico && random.nextDouble() < 0.6;
      final caminhoImagem = ehNostalgico
          ? 'assets/monstros_aventura/colecao_nostalgicos/${tipo.name}.png'
          : 'assets/monstros_aventura/colecao_inicial/${tipo.name}.png';

      print('🎲 [Repository] Sorteando monstro ${tipo.name} ${ehNostalgico ? '(NOSTÁLGICO)' : '(INICIAL)'}:');
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
    
    // Seleciona um mapa aleatório para a aventura
    final mapas = [
      'assets/mapas_aventura/cidade_abandonada.jpg',
      'assets/mapas_aventura/deserto.jpg',
      'assets/mapas_aventura/floresta_verde.jpg',
      'assets/mapas_aventura/praia.jpg',
      'assets/mapas_aventura/vulcao.jpg',
    ];
    final mapaEscolhido = mapas[random.nextInt(mapas.length)];
    print('🗺️ [Repository] Mapa escolhido para nova aventura: $mapaEscolhido');

    // Sorteia 5 monstros inimigos para a aventura (tier 1 - sem itens)
    final monstrosInimigos = await _sortearMonstrosInimigos(tierAtual: 1);
    print('👾 [Repository] Sorteados ${monstrosInimigos.length} monstros inimigos');
    
    // Gera um ID único para esta run/aventura
    final runId = _rankingService.gerarRunId();
    print('🆔 [Repository] RunId gerado para nova aventura: $runId');
    
    final historia = HistoriaJogador(
      email: email,
      monstros: monstrosSorteados,
      aventuraIniciada: false, // Inicialmente false, só muda para true quando clicar "Iniciar Aventura"
      mapaAventura: mapaEscolhido,
      monstrosInimigos: monstrosInimigos,
      runId: runId,
    );
    
    // Salva localmente no HIVE (não no Drive ainda)
    print('💾 [Repository] Salvando aventura localmente...');
    final sucessoSalvamento = await salvarHistoricoJogador(historia);
    if (sucessoSalvamento) {
      print('✅ [Repository] Aventura completa criada e salva localmente com ${monstrosSorteados.length} monstros do jogador e ${monstrosInimigos.length} inimigos');
    } else {
      print('❌ [Repository] ERRO: Falha ao salvar aventura localmente!');
      throw Exception('Falha ao salvar aventura localmente');
    }
    
    return historia;
  }

  /// Verifica se todos os tipos de monstros foram baixados e estão disponíveis localmente
  Future<bool> verificarTiposBaixados() async {
    try {
      print('🔍 [Aventura] === VERIFICAÇÃO DETALHADA DE TIPOS BAIXADOS ===');
      
      // Status atual do TipagemRepository
      print('📊 [Aventura] Drive Conectado: ${_tipagemRepository.isDriveConectado}');
      print('📊 [Aventura] Foi Baixado do Drive: ${_tipagemRepository.foiBaixadoDoDrive}');
      print('📊 [Aventura] Is Inicializado: ${_tipagemRepository.isInicializado}');
      print('📊 [Aventura] Is Bloqueado: ${_tipagemRepository.isBloqueado}');
      
      // Verifica se os dados de tipagem estão disponíveis localmente
      final isInicializado = await _tipagemRepository.isInicializadoAsync;
      print('� [Aventura] Is Inicializado Async: $isInicializado');
      
      if (!isInicializado) {
        print('⚠️ [Aventura] Sistema não inicializado - verificando se pode inicializar...');
        
        // Tenta inicializar se estiver conectado ao Drive
        if (_tipagemRepository.isDriveConectado && _tipagemRepository.isBloqueado) {
          print('🔄 [Aventura] Drive conectado mas bloqueado - tentando inicializar...');
          final inicializou = await _tipagemRepository.inicializarComDrive();
          if (inicializou) {
            print('✅ [Aventura] Sistema inicializado com sucesso durante verificação!');
            return true;
          } else {
            print('❌ [Aventura] Falha na inicialização durante verificação');
            return false;
          }
        }
      }
      
      print('🔍 [Aventura] Resultado final da verificação: $isInicializado');
      return isInicializado;
    } catch (e) {
      print('❌ [Aventura] Erro ao verificar tipos baixados: $e');
      return false;
    }
  }

  /// Inicia uma nova aventura para o jogador
  Future<HistoriaJogador?> iniciarAventura(String email) async {
    try {
      print('🚀 [Repository] Iniciando aventura para: $email');
      
      // Carrega o histórico atual do HIVE
      HistoriaJogador? historiaAtual = await carregarHistoricoJogador(email);
      print('📥 [Repository] Histórico carregado do HIVE:');
      if (historiaAtual != null) {
        print('   - Email: ${historiaAtual.email}');
        print('   - Monstros jogador: ${historiaAtual.monstros.length}');
        print('   - Aventura iniciada: ${historiaAtual.aventuraIniciada}');
        print('   - Mapa: ${historiaAtual.mapaAventura ?? "null"}');
        print('   - Inimigos: ${historiaAtual.monstrosInimigos.length}');
      } else {
        print('   - Histórico é NULL');
      }

      // Se não há histórico, cria um novo
      if (historiaAtual == null) {
        print('📝 [Repository] Histórico não encontrado, criando novo histórico...');
        historiaAtual = await sortearMonstrosParaJogador(email);
        print('✅ [Repository] Novo histórico criado com aventura já iniciada');
        return historiaAtual;
      }

      // Verifica se já há uma aventura iniciada
      if (historiaAtual.aventuraIniciada) {
        print('🔄 [Repository] Aventura já iniciada! Carregando dados existentes...');
        print('🗺️ [Repository] Mapa existente: ${historiaAtual.mapaAventura}');
        print('👾 [Repository] Monstros existentes: ${historiaAtual.monstrosInimigos.length}');
        return historiaAtual; // Retorna a aventura existente
      }

      print('🆕 [Repository] Atualizando histórico existente para iniciar aventura...');
      
      // Seleciona um mapa aleatório
      final mapas = [
        'assets/mapas_aventura/cidade_abandonada.jpg',
        'assets/mapas_aventura/deserto.jpg',
        'assets/mapas_aventura/floresta_verde.jpg',
        'assets/mapas_aventura/praia.jpg',
        'assets/mapas_aventura/vulcao.jpg',
      ];
      final random = Random();
      final mapaEscolhido = mapas[random.nextInt(mapas.length)];
      print('🗺️ [Repository] Mapa escolhido para nova aventura: $mapaEscolhido');

      // Sorteia 5 monstros inimigos (apenas 1 tipo cada)
      final monstrosInimigos = await _sortearMonstrosInimigos(tierAtual: historiaAtual.tier);
      print('👾 [Repository] Sorteados ${monstrosInimigos.length} monstros inimigos');

      // Gera um novo runId se não existir ou se estiver vazio
      String runId = historiaAtual.runId;
      if (runId.isEmpty) {
        runId = _rankingService.gerarRunId();
        print('🆔 [Repository] RunId gerado para aventura atualizada: $runId');
      } else {
        print('🆔 [Repository] Usando runId existente: $runId');
      }

      // Atualiza o histórico com a aventura iniciada
      final historiaAtualizada = historiaAtual.copyWith(
        aventuraIniciada: true,
        mapaAventura: mapaEscolhido,
        monstrosInimigos: monstrosInimigos,
        runId: runId,
      );

      // Salva no Drive
      final sucesso = await salvarHistoricoJogador(historiaAtualizada);
      if (sucesso) {
        print('✅ [Repository] Nova aventura criada e salva com sucesso');
        return historiaAtualizada;
      } else {
        print('❌ [Repository] Erro ao salvar nova aventura');
        return null;
      }
    } catch (e) {
      print('❌ [Repository] Erro ao iniciar aventura: $e');
      return null;
    }
  }

  /// Sorteia 5 monstros inimigos com tipos e habilidades + monstros elite a cada 3 tiers
  Future<List<MonstroInimigo>> _sortearMonstrosInimigos({int tierAtual = 1}) async {
    final random = Random();
    final monstrosInimigos = <MonstroInimigo>[];

    // Verifica se deve spawnar monstro elite (a cada 3 tiers)
    final deveSpawnarElite = tierAtual % 3 == 0;

    print('🏆 [Repository] Tier $tierAtual: ${deveSpawnarElite ? "Com monstro elite (5+1)" : "Sem monstro elite (5)"}');

    // Sempre gera 5 monstros normais
    for (int i = 0; i < 5; i++) {
      // Escolhe um tipo principal aleatório
      final tiposDisponiveis = Tipo.values.toList();
      final tipo = tiposDisponiveis[random.nextInt(tiposDisponiveis.length)];
      
      // Sorteia tipo extra diferente do principal (todos os monstros têm 2 tipos)
      final outrosTipos = tiposDisponiveis.where((t) => t != tipo).toList();
      outrosTipos.shuffle(random);
      final tipoExtra = outrosTipos.first;
      
      // Gera 4 habilidades para o monstro
      final habilidadesBase = GeradorHabilidades.gerarHabilidadesMonstro(tipo, tipoExtra);
      
      // Aplica evolução aleatória nas habilidades baseado no tier (tier 2+)
      final habilidades = _aplicarEvolucaoHabilidadesInimigo(habilidadesBase, tierAtual, random);
      
      // Gera item equipado baseado nas regras de tier e restrições de dificuldade
      Item? itemEquipado;
      if (tierAtual == 2) {
        // Tier 2: monstros sempre usam itens de tier 1 (sem restrições ainda)
        itemEquipado = _itemService.gerarItemAleatorio(tierAtual: 1);
        print('🎯 [Repository] Monstro tier 2 recebeu item tier 1: ${itemEquipado.nome}');
      } else if (tierAtual >= 3) {
        // Tier 3+: 40% de chance de usar item de 1 tier abaixo, 60% chance de item do mesmo tier
        final chanceItem = random.nextInt(100);
        if (chanceItem < 40) {
          // Item de tier anterior COM restrições de dificuldade
          itemEquipado = _itemService.gerarItemComRestricoesTier(tierAtual: tierAtual - 1);
          print('🎯 [Repository] Monstro tier $tierAtual recebeu item tier ${tierAtual - 1}: ${itemEquipado.nome} (40% chance) - COM RESTRIÇÕES');
        } else {
          // Item do tier atual COM restrições de dificuldade
          itemEquipado = _itemService.gerarItemComRestricoesTier(tierAtual: tierAtual);
          print('🎯 [Repository] Monstro tier $tierAtual recebeu item tier $tierAtual: ${itemEquipado.nome} (60% chance) - COM RESTRIÇÕES');
        }
      } else {
        // Tier 1: sem itens
        print('🎯 [Repository] Monstro tier 1 não recebe itens');
      }

      // Sorteia nível de evolução do monstro (1 evolução por andar)
      final niveisEvolucao = tierAtual;
      print('📈 [Repository] Monstro tier $tierAtual terá $niveisEvolucao evoluções');

      // Cria monstro inimigo com atributos base + evoluções + bônus por tier
      final vidaBase = AtributoJogo.vida.sortear(random);
      final energiaBase = AtributoJogo.energia.sortear(random);

      // Aplica ganhos de evolução (por tier)
      final vidaComEvolucao = vidaBase + (niveisEvolucao * AtributoJogo.evolucaoGanhoVida.min);

      // Aplica bônus de vida por dezenas de andares (+20% a cada 10 tiers)
      final bonusPercentual = AtributoJogo.calcularBonusVidaInimigo(tierAtual);
      final vidaFinal = (vidaComEvolucao * (1.0 + bonusPercentual)).round();
      final energiaFinal = energiaBase + (niveisEvolucao * AtributoJogo.evolucaoGanhoEnergia.min);

      print('📊 [Repository] Monstro tier $tierAtual:');
      print('   - Vida base: $vidaBase');
      print('   - Evolução: +${niveisEvolucao * AtributoJogo.evolucaoGanhoVida.min} = $vidaComEvolucao');
      print('   - Bônus tier (+${(bonusPercentual * 100).toStringAsFixed(0)}%): $vidaFinal');
      print('   - Energia: $energiaBase+${niveisEvolucao * AtributoJogo.evolucaoGanhoEnergia.min}=$energiaFinal');

      final monstro = MonstroInimigo(
        tipo: tipo,
        tipoExtra: tipoExtra,
        imagem: 'assets/monstros_aventura/colecao_inicial/${tipo.name}.png',
        vida: vidaFinal,
        energia: energiaFinal,
        agilidade: AtributoJogo.agilidade.sortear(random),
        ataque: AtributoJogo.ataque.sortear(random),
        defesa: AtributoJogo.defesa.sortear(random),
        habilidades: habilidades,
        itemEquipado: itemEquipado,
        level: tierAtual, // Level = tier do mapa
      );
      
      monstrosInimigos.add(monstro);
    }

    // Gera monstro elite se for tier múltiplo de 3
    if (deveSpawnarElite) {
      print('🏆 [Repository] Gerando monstro elite para tier $tierAtual');
      final monstroElite = await _gerarMonstroElite(tierAtual, random);
      monstrosInimigos.add(monstroElite);
    }

    // 🌟 NOVO: Gera monstro raro da nova coleção se atender aos critérios
    print('🌟 [Repository] Verificando spawn de monstro raro no tier $tierAtual...');
    print('🌟 [Repository] Pode gerar monstro raro? ${AtributoJogo.podeGerarMonstroRaro(tierAtual)}');
    print('🌟 [Repository] Chance configurada: ${AtributoJogo.chanceMonstroColecoRaroPercent(tierAtual)}%');

    if (AtributoJogo.deveGerarMonstroRaro(random, tierAtual)) {
      print('🌟 [Repository] ✅ SORTEIO VENCEU! Gerando monstro RARO da nova coleção');
      final monstroRaro = await _gerarMonstroRaro(tierAtual, random);
      monstrosInimigos.add(monstroRaro);
    } else {
      print('🌟 [Repository] ❌ Sorteio perdeu, não vai gerar monstro raro desta vez');
    }

    return monstrosInimigos;
  }

  /// Gera um monstro elite com dobro de vida e item raro+
  Future<MonstroInimigo> _gerarMonstroElite(int tierAtual, Random random) async {
    // Escolhe tipos aleatórios para o monstro elite
    final tiposDisponiveis = Tipo.values.toList();
    final tipo = tiposDisponiveis[random.nextInt(tiposDisponiveis.length)];
    final outrosTipos = tiposDisponiveis.where((t) => t != tipo).toList();
    outrosTipos.shuffle(random);
    final tipoExtra = outrosTipos.first;

    // Gera habilidades para o monstro elite
    final habilidadesBase = GeradorHabilidades.gerarHabilidadesMonstro(tipo, tipoExtra);
    final habilidades = _aplicarEvolucaoHabilidadesInimigo(habilidadesBase, tierAtual, random);

    // Gera item SEMPRE raro ou superior para monstro elite COM restrições de dificuldade
    final itemElite = _itemService.gerarItemEliteComRestricoes(tierAtual: tierAtual);
    print('👑 [Repository] Monstro elite recebeu item: ${itemElite.nome} (${itemElite.raridade.nome}) - COM RESTRIÇÕES');

    // Calcula atributos base
    final vidaBase = AtributoJogo.vida.sortear(random);
    final energiaBase = AtributoJogo.energia.sortear(random);
    final niveisEvolucao = tierAtual;

    // Aplica ganhos de evolução
    final vidaComEvolucao = vidaBase + (niveisEvolucao * AtributoJogo.evolucaoGanhoVida.min);

    // Aplica bônus de vida por tier
    final bonusPercentual = AtributoJogo.calcularBonusVidaInimigo(tierAtual);
    final vidaComBonus = (vidaComEvolucao * (1.0 + bonusPercentual)).round();

    // DOBRA a vida para monstros elite
    final vidaFinalElite = vidaComBonus * 2;
    final energiaFinal = energiaBase + (niveisEvolucao * AtributoJogo.evolucaoGanhoEnergia.min);

    print('👑 [Repository] Monstro ELITE tier $tierAtual:');
    print('   - Vida normal: $vidaComBonus → Elite: $vidaFinalElite (2x)');
    print('   - Energia: $energiaFinal');
    print('   - Item elite: ${itemElite.nome}');

    return MonstroInimigo(
      tipo: tipo,
      tipoExtra: tipoExtra,
      imagem: 'assets/monstros_aventura/colecao_inicial/${tipo.name}.png', // Usa imagem do tipo como os outros
      vida: vidaFinalElite,
      energia: energiaFinal,
      agilidade: AtributoJogo.agilidade.sortear(random),
      ataque: AtributoJogo.ataque.sortear(random),
      defesa: AtributoJogo.defesa.sortear(random),
      habilidades: habilidades,
      itemEquipado: itemElite,
      level: tierAtual,
      isElite: true, // Marca como elite
    );
  }

  /// Gera um monstro raro da nova coleção (nostálgicos)
  Future<MonstroInimigo> _gerarMonstroRaro(int tierAtual, Random random) async {
    // Escolhe um tipo aleatório para o monstro raro
    final tiposDisponiveis = Tipo.values.toList();
    final tipo = tiposDisponiveis[random.nextInt(tiposDisponiveis.length)];
    final outrosTipos = tiposDisponiveis.where((t) => t != tipo).toList();
    outrosTipos.shuffle(random);
    final tipoExtra = outrosTipos.first;

    // Gera habilidades para o monstro raro
    final habilidadesBase = GeradorHabilidades.gerarHabilidadesMonstro(tipo, tipoExtra);
    final habilidades = _aplicarEvolucaoHabilidadesInimigo(habilidadesBase, tierAtual, random);

    // Monstros raros têm chance de item igual aos monstros normais (não são elite)
    Item? itemEquipado;
    if (tierAtual == 2) {
      itemEquipado = _itemService.gerarItemAleatorio(tierAtual: 1);
    } else if (tierAtual >= 3) {
      final chanceItem = random.nextInt(100);
      if (chanceItem < 40) {
        itemEquipado = _itemService.gerarItemComRestricoesTier(tierAtual: tierAtual - 1);
      } else {
        itemEquipado = _itemService.gerarItemComRestricoesTier(tierAtual: tierAtual);
      }
    }

    // Calcula atributos normais (não é elite, então não dobra vida)
    final vidaBase = AtributoJogo.vida.sortear(random);
    final energiaBase = AtributoJogo.energia.sortear(random);
    final niveisEvolucao = tierAtual;

    // Aplica ganhos de evolução
    final vidaComEvolucao = vidaBase + (niveisEvolucao * AtributoJogo.evolucaoGanhoVida.min);

    // Aplica bônus de vida por tier
    final bonusPercentual = AtributoJogo.calcularBonusVidaInimigo(tierAtual);
    final vidaFinal = (vidaComEvolucao * (1.0 + bonusPercentual)).round();
    final energiaFinal = energiaBase + (niveisEvolucao * AtributoJogo.evolucaoGanhoEnergia.min);

    print('🌟 [Repository] Monstro RARO tier $tierAtual:');
    print('   - Tipo: ${tipo.name} (Da nova coleção nostálgica)');
    print('   - Vida: $vidaFinal');
    print('   - Energia: $energiaFinal');
    print('   - Item: ${itemEquipado?.nome ?? 'Nenhum'}');

    return MonstroInimigo(
      tipo: tipo,
      tipoExtra: tipoExtra,
      imagem: 'assets/monstros_aventura/colecao_nostalgicos/${tipo.name}.png', // Imagem do monstro nostálgico
      vida: vidaFinal,
      energia: energiaFinal,
      agilidade: AtributoJogo.agilidade.sortear(random),
      ataque: AtributoJogo.ataque.sortear(random),
      defesa: AtributoJogo.defesa.sortear(random),
      habilidades: habilidades,
      itemEquipado: itemEquipado,
      level: tierAtual,
      isElite: false, // Não é elite, é monstro raro
      isRaro: true, // NOVO: Marca como monstro raro
    );
  }

  /// Aplica evolução aleatória nas habilidades dos monstros inimigos baseado no tier
  /// Tier 2+: Para cada habilidade, 20% chance level = tier, 20% chance level = tier-1
  List<Habilidade> _aplicarEvolucaoHabilidadesInimigo(List<Habilidade> habilidadesBase, int tierAtual, Random random) {
    // Tier 1: habilidades permanecem level 1
    if (tierAtual == 1) {
      return habilidadesBase;
    }
    
    final habilidadesEvoluidas = <Habilidade>[];
    
    for (final habilidade in habilidadesBase) {
      final chance = random.nextInt(100);
      int novoLevel = 1; // Level padrão

      if (chance < 20) {
        // 20% chance: level = tier do andar
        novoLevel = tierAtual;
        print('✨ [Repository] Habilidade ${habilidade.nome} evoluiu para level $novoLevel (tier atual - 20% chance)');
      } else if (chance < 40) {
        // 20% chance: level = tier - 1 (nunca abaixo de 1)
        novoLevel = (tierAtual - 1).clamp(1, tierAtual);
        print('✨ [Repository] Habilidade ${habilidade.nome} evoluiu para level $novoLevel (tier-1 - 20% chance)');
      } else {
        // 60% chance: permanece level 1 PORÉM...
        if (tierAtual >= 5) {
          // A partir do tier 5: level = 50% do tier (nunca menor que 1)
          novoLevel = (tierAtual * 0.5).round().clamp(1, tierAtual);
          print('✨ [Repository] Habilidade ${habilidade.nome} evoluiu para level $novoLevel (tier 5+ - 50% do tier $tierAtual)');
        } else {
          print('📝 [Repository] Habilidade ${habilidade.nome} permanece level 1 (60% chance)');
        }
      }

      // Cria nova habilidade com o level calculado
      final habilidadeEvoluida = Habilidade(
        nome: habilidade.nome,
        descricao: habilidade.descricao,
        tipo: habilidade.tipo,
        efeito: habilidade.efeito,
        tipoElemental: habilidade.tipoElemental,
        valor: habilidade.valor, // Valor original
        custoEnergia: habilidade.custoEnergia,
        level: novoLevel,
      );
      
      habilidadesEvoluidas.add(habilidadeEvoluida);
    }
    
    return habilidadesEvoluidas;
  }

  /// Gera novos monstros inimigos para um tier específico (método público)
  Future<List<MonstroInimigo>> gerarMonstrosInimigosPorTier(int tier) async {
    print('🆕 [Repository] Gerando monstros inimigos para tier $tier via método público');
    return await _sortearMonstrosInimigos(tierAtual: tier);
  }

  /// Atualiza o ranking quando o score de uma aventura for alterado
  Future<void> atualizarRankingPorScore(HistoriaJogador historia) async {
    try {
      print('🏆 [Repository] Atualizando ranking para: ${historia.email} - Score: ${historia.score} - RunId: ${historia.runId}');
      
      // Só atualiza o ranking se tiver runId (score pode ser 0)
      if (historia.runId.isNotEmpty) {
        await _rankingService.atualizarRanking(
          runId: historia.runId,
          email: historia.email,
          score: historia.score,
          tier: historia.tier,
        );
        print('✅ [Repository] Ranking atualizado com sucesso');
      } else {
        print('⚠️ [Repository] Ranking não atualizado: runId está vazio (${historia.runId})');
      }
    } catch (e) {
      print('❌ [Repository] Erro ao atualizar ranking: $e');
      // Não falha o salvamento por causa do ranking
    }
  }

  /// Salva histórico e atualiza ranking automaticamente
  Future<bool> salvarHistoricoEAtualizarRanking(HistoriaJogador historia) async {
    try {
      // Salva o histórico primeiro
      final sucessoSalvamento = await salvarHistoricoJogador(historia);
      
      if (sucessoSalvamento) {
        // Atualiza o ranking se o salvamento foi bem-sucedido
        await atualizarRankingPorScore(historia);
      }
      
      return sucessoSalvamento;
    } catch (e) {
      print('❌ [Repository] Erro ao salvar histórico e atualizar ranking: $e');
      return false;
    }
  }

  /// Remove completamente o histórico do jogador (local)
  Future<bool> removerHistoricoJogador(String email) async {
    try {
      print('🗑️ [Repository] Removendo histórico LOCAL para: $email');

      // Remove do HIVE
      final sucessoLocal = await _hiveService.removerAventura(email);

      if (sucessoLocal) {
        print('✅ [Repository] Histórico local removido com sucesso');
        return true;
      } else {
        print('❌ [Repository] Falha ao remover histórico local');
        return false;
      }
    } catch (e) {
      print('❌ [Repository] Erro ao remover histórico local: $e');
      return false;
    }
  }
  
  /// Arquiva o histórico atual renomeando com o runId da aventura
  Future<bool> arquivarHistoricoJogador(String email, String runId) async {
    try {
      print('📦 [Repository] INICIANDO arquivamento para: $email (RunID: $runId)');
      
      // Verifica se runId não está vazio - se estiver, gera um temporário
      String runIdFinal = runId;
      if (runId.isEmpty) {
        print('⚠️ [Repository] AVISO: runId está vazio, gerando runId temporário para arquivamento');
        runIdFinal = 'legacy_${DateTime.now().millisecondsSinceEpoch}';
        print('🆔 [Repository] RunId temporário gerado: $runIdFinal');
      }
      
      final nomeAtual = 'historico_$email.json';
      final novoNome = 'historico_${email}_$runIdFinal.json';
      
      print('📦 [Repository] Arquivo atual: $nomeAtual');
      print('📦 [Repository] Novo nome: $novoNome');
      
      // Cria o caminho com data atual (mesmo padrão usado em carregarHistoricoJogador e salvarHistoricoJogador)
      final hoje = DateTime.now().subtract(const Duration(hours: 3)); // Horário Brasília
      final dataFormatada = '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final caminhoCompleto = 'historias/$dataFormatada/$email';
      
      print('📦 [Repository] Caminho completo: $caminhoCompleto');
      print('📦 [Repository] Chamando DriveService.renomearArquivoDaPasta...');
      
      // Renomeia o arquivo no Drive usando o caminho completo
      final sucesso = await _driveService.renomearArquivoDaPasta(nomeAtual, novoNome, caminhoCompleto);
      
      if (sucesso) {
        print('✅ [Repository] Histórico arquivado com SUCESSO: $caminhoCompleto/$nomeAtual → $novoNome');
      } else {
        print('❌ [Repository] FALHA ao arquivar histórico: $caminhoCompleto/$nomeAtual → $novoNome');
        
        // Se falhar na data atual, tenta buscar nos últimos 7 dias (mesmo padrão do carregarHistoricoJogador)
        print('🔍 [Repository] Tentando arquivar nos últimos dias...');
        for (int i = 1; i <= 7; i++) {
          final dataAnterior = hoje.subtract(Duration(days: i));
          final dataAnteriorFormatada = '${dataAnterior.year.toString().padLeft(4, '0')}-${dataAnterior.month.toString().padLeft(2, '0')}-${dataAnterior.day.toString().padLeft(2, '0')}';
          final caminhoAnterior = 'historias/$dataAnteriorFormatada/$email';
          
          print('🔍 [Repository] Tentando arquivar em: $caminhoAnterior');
          final sucessoAnterior = await _driveService.renomearArquivoDaPasta(nomeAtual, novoNome, caminhoAnterior);
          
          if (sucessoAnterior) {
            print('✅ [Repository] Histórico arquivado com SUCESSO em data anterior: $caminhoAnterior/$nomeAtual → $novoNome');
            return true;
          }
        }
        
        print('❌ [Repository] Não foi possível arquivar o histórico em nenhuma das datas dos últimos 7 dias');
      }
      
      return sucesso;
    } catch (e, stackTrace) {
      print('❌ [Repository] EXCEÇÃO ao arquivar histórico: $e');
      print('❌ [Repository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Desbloqueia um monstro nostálgico para o jogador
  /// Pode ser chamado quando o jogador completa uma aventura, derrota um boss, etc.
  Future<bool> desbloquearMonstroNostalgico(String email, String nomeMonstro) async {
    try {
      print('🌟 [Repository] Desbloqueando monstro nostálgico $nomeMonstro para $email');

      final sucesso = await _colecaoService.desbloquearMonstro(email, nomeMonstro);

      if (sucesso) {
        print('✅ [Repository] Monstro $nomeMonstro desbloqueado com sucesso!');
      } else {
        print('❌ [Repository] Falha ao desbloquear monstro $nomeMonstro');
      }

      return sucesso;
    } catch (e) {
      print('❌ [Repository] Erro ao desbloquear monstro nostálgico: $e');
      return false;
    }
  }

  /// Verifica e desbloqueia monstros baseado no progresso da aventura
  /// Exemplo: desbloqueia monstro a cada 3 andares completados
  Future<void> verificarDesbloqueiosPorProgresso(String email, int tierCompletado) async {
    try {
      print('🎯 [Repository] Verificando desbloqueios para tier $tierCompletado');

      // Exemplo de regra: desbloqueia monstro nostálgico a cada 5 tiers
      if (tierCompletado % 5 == 0 && tierCompletado > 0) {
        print('🏆 [Repository] Tier $tierCompletado completado! Desbloqueando monstro nostálgico...');

        // Desbloqueia um monstro aleatório
        final sucesso = await _colecaoService.desbloquearMonstrosAleatorios(email, 1);

        if (sucesso) {
          print('🌟 [Repository] Monstro nostálgico desbloqueado como recompensa do tier $tierCompletado!');
        }
      }
    } catch (e) {
      print('❌ [Repository] Erro ao verificar desbloqueios por progresso: $e');
    }
  }
}
