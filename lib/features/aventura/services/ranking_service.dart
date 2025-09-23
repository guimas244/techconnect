import 'dart:convert';
import 'dart:math';
import '../models/ranking_entry.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/config/version_config.dart';
import '../../../core/utils/date_folder_manager.dart';

class RankingService {
  static final RankingService _instance = RankingService._internal();
  factory RankingService() => _instance;
  RankingService._internal();

  final GoogleDriveService _driveService = GoogleDriveService();
  final DateFolderManager _folderManager = DateFolderManager();

  /// Gera um ID único para uma nova run/aventura
  String gerarRunId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'run_${timestamp}_$random';
  }

  /// Converte DateTime para horário de Brasília
  DateTime paraHorarioBrasilia(DateTime utc) {
    return _folderManager.paraHorarioBrasilia(utc);
  }

  /// Obtém DateTime atual em horário de Brasília
  DateTime get agora {
    return _folderManager.agora;
  }

  /// Formata data para nome do arquivo (YYYY-MM-DD)
  String _formatarDataParaNomeArquivo(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  /// Obtém nome do arquivo de ranking para uma data específica e email
  String _getNomeArquivoRanking(DateTime data, String email) {
    return 'ranking_${email}_${_formatarDataParaNomeArquivo(data)}.json';
  }

  /// Salva ou atualiza o ranking de um jogador
  Future<void> atualizarRanking({
    required String runId,
    required String email,
    required int score,
    DateTime? dataHora,
  }) async {
    try {
      final dataHoraFinal = dataHora ?? agora;
      final dataSemHora = DateTime(dataHoraFinal.year, dataHoraFinal.month, dataHoraFinal.day);
      
      print('🏆 [RankingService] Atualizando ranking para $email - Score: $score - RunId: $runId');
      
      // Carrega o ranking individual do email para o dia
      final rankingDiario = await carregarRankingDiaEmail(dataSemHora, email);
      final entradaExistente = rankingDiario.entradas.where((e) => VersionConfig.extractPlayerNameOnly(e.email) == VersionConfig.extractPlayerNameOnly(email)).firstOrNull;
      
      // 🚨 VALIDAÇÃO ANTI-CHEAT: Verifica mudança de versão no meio da run
      final entradaMesmaRun = rankingDiario.entradas.where((e) => e.runId == runId).firstOrNull;
      if (entradaMesmaRun != null && entradaMesmaRun.version != VersionConfig.currentVersion) {
        // Detectou mudança de versão no meio da run - INVALIDA
        print('🚨 [ANTI-CHEAT] Mudança de versão detectada na run $runId: ${entradaMesmaRun.version} → ${VersionConfig.currentVersion}');
        final nomeJogador = VersionConfig.extractPlayerNameOnly(email);
        final novaEntrada = RankingEntry(
          runId: runId,
          email: VersionConfig.formatPlayerNameWithVersion(nomeJogador, 'versão inválida ($runId)'),
          score: 0, // ZERA O SCORE
          dataHora: dataHora ?? DateTime.now(),
          version: 'versão inválida ($runId)',
        );
        
        // Remove entrada anterior e adiciona a nova invalidada
        final entradasFiltradas = rankingDiario.entradas.where((e) => e.runId != runId).toList();
        entradasFiltradas.add(novaEntrada);
        final rankingAtualizado = rankingDiario.copyWith(entradas: entradasFiltradas);
        await _salvarRankingDia(rankingAtualizado, email);
        
        print('❌ [ANTI-CHEAT] Run invalidada e score zerado para $email');
        return;
      }
      
      String emailComVersao = email;
      String versaoParaSalvar = VersionConfig.currentVersion;
      
      if (entradaExistente != null) {
        // Já existe entrada, verifica versionamento
        final versaoExistente = entradaExistente.version;
        final nomeJogador = VersionConfig.extractPlayerNameOnly(email);
        
        if (VersionConfig.compareVersions(VersionConfig.currentVersion, versaoExistente) < 0) {
          // Downgrade detectado
          emailComVersao = VersionConfig.formatPlayerNameWithVersion(nomeJogador, VersionConfig.currentVersion, isDowngrade: true);
          versaoParaSalvar = VersionConfig.currentVersion;
        } else if (VersionConfig.compareVersions(VersionConfig.currentVersion, versaoExistente) > 0) {
          // Versão superior, atualiza para a versão atual
          emailComVersao = VersionConfig.formatPlayerNameWithVersion(nomeJogador, VersionConfig.currentVersion);
          versaoParaSalvar = VersionConfig.currentVersion;
        } else {
          // Versão igual, mantém a versão existente
          emailComVersao = VersionConfig.formatPlayerNameWithVersion(nomeJogador, versaoExistente);
          versaoParaSalvar = versaoExistente;
        }
      } else {
        // Primeira entrada, salva com versão atual
        final nomeJogador = VersionConfig.extractPlayerNameOnly(email);
        emailComVersao = VersionConfig.formatPlayerNameWithVersion(nomeJogador, VersionConfig.currentVersion);
        versaoParaSalvar = VersionConfig.currentVersion;
      }

      // Cria nova entrada de ranking
      final novaEntrada = RankingEntry(
        runId: runId,
        email: emailComVersao,
        score: score,
        dataHora: dataHoraFinal,
        version: versaoParaSalvar,
      );

      // Adiciona ou atualiza a entrada
      final rankingAtualizado = rankingDiario.adicionarOuAtualizar(novaEntrada);

      // Salva no Drive
      await _salvarRankingDia(rankingAtualizado, email);

      print('✅ [RankingService] Ranking atualizado com sucesso para $email');
      
    } catch (e) {
      print('❌ [RankingService] Erro ao atualizar ranking: $e');
      throw Exception('Erro ao atualizar ranking: $e');
    }
  }

  /// Carrega o ranking individual de um email para um dia específico
  Future<RankingDiario> carregarRankingDiaEmail(DateTime data, String email) async {
    try {
      final dataSemHora = DateTime(data.year, data.month, data.day);
      final nomeArquivo = _getNomeArquivoRanking(dataSemHora, email);

      print('📊 [RankingService] Carregando ranking individual para $email no dia: ${_formatarDataParaNomeArquivo(dataSemHora)}');

      // Carrega da pasta rankings com subpasta por data
      final dataFormatada = _folderManager.formatarDataParaPasta(dataSemHora);
      final pastaComData = 'rankings/$dataFormatada';
      print('🎯 [RankingService] Carregando da pasta: $pastaComData/$nomeArquivo');
      final conteudoJson = await _driveService.baixarArquivoDaPasta(nomeArquivo, pastaComData);

      if (conteudoJson.isEmpty) {
        // Se não existe, cria ranking vazio para o email no dia
        print('📊 [RankingService] Ranking individual não encontrado para $email, criando novo');
        return RankingDiario(
          data: dataSemHora,
          entradas: [],
        );
      }

      final dados = json.decode(conteudoJson) as Map<String, dynamic>;
      final ranking = RankingDiario.fromJson(dados);

      print('✅ [RankingService] Ranking individual carregado para $email: ${ranking.entradas.length} entradas');
      return ranking;

    } catch (e) {
      print('❌ [RankingService] Erro ao carregar ranking individual para $email: $e');
      // Em caso de erro, retorna ranking vazio
      final dataSemHora = DateTime(data.year, data.month, data.day);
      return RankingDiario(
        data: dataSemHora,
        entradas: [],
      );
    }
  }

  /// Carrega o ranking consolidado de um dia específico (todos os emails)
  Future<RankingDiario> carregarRankingDia(DateTime data) async {
    try {
      final dataSemHora = DateTime(data.year, data.month, data.day);

      print('📊 [RankingService] Carregando ranking consolidado do dia: ${_formatarDataParaNomeArquivo(dataSemHora)}');

      // Lista todos os arquivos da pasta da data
      final dataFormatada = _folderManager.formatarDataParaPasta(dataSemHora);
      final pastaComData = 'rankings/$dataFormatada';

      // Usar método para listar arquivos por data (precisa implementar)
      final arquivos = await _listarArquivosRankingPorData(dataSemHora);

      if (arquivos.isEmpty) {
        print('📊 [RankingService] Nenhum arquivo de ranking encontrado para o dia');
        return RankingDiario(data: dataSemHora, entradas: []);
      }

      // Consolida todas as entradas de todos os emails
      final List<RankingEntry> todasEntradas = [];

      for (final arquivo in arquivos) {
        try {
          final conteudoJson = await _driveService.baixarArquivoDaPasta(arquivo, pastaComData);
          if (conteudoJson.isNotEmpty) {
            final dados = json.decode(conteudoJson) as Map<String, dynamic>;
            final ranking = RankingDiario.fromJson(dados);
            todasEntradas.addAll(ranking.entradas);
          }
        } catch (e) {
          print('⚠️ [RankingService] Erro ao processar arquivo $arquivo: $e');
        }
      }

      final rankingConsolidado = RankingDiario(
        data: dataSemHora,
        entradas: todasEntradas,
      );

      print('✅ [RankingService] Ranking consolidado carregado: ${todasEntradas.length} entradas de ${arquivos.length} arquivos');
      return rankingConsolidado;

    } catch (e) {
      print('❌ [RankingService] Erro ao carregar ranking consolidado: $e');
      final dataSemHora = DateTime(data.year, data.month, data.day);
      return RankingDiario(data: dataSemHora, entradas: []);
    }
  }

  /// Carrega o ranking consolidado com carregamento progressivo
  /// O callback é chamado a cada arquivo carregado com o progresso
  Future<RankingDiario> carregarRankingDiaProgressivo(
    DateTime data, {
    Function(int carregados, int total, List<RankingEntry> entradasParciais)? onProgress,
  }) async {
    try {
      final dataSemHora = DateTime(data.year, data.month, data.day);
      
      print('📊 [RankingService] Carregando ranking progressivo do dia: ${_formatarDataParaNomeArquivo(dataSemHora)}');

      // Lista todos os arquivos da pasta da data
      final dataFormatada = _folderManager.formatarDataParaPasta(dataSemHora);
      final pastaComData = 'rankings/$dataFormatada';
      
      final arquivos = await _listarArquivosRankingPorData(dataSemHora);
      
      if (arquivos.isEmpty) {
        print('📊 [RankingService] Nenhum arquivo de ranking encontrado para o dia');
        onProgress?.call(0, 0, []);
        return RankingDiario(data: dataSemHora, entradas: []);
      }
      
      // Consolida todas as entradas de todos os emails progressivamente
      final List<RankingEntry> todasEntradas = [];
      final totalArquivos = arquivos.length;
      
      for (int i = 0; i < arquivos.length; i++) {
        final arquivo = arquivos[i];
        try {
          print('📄 [RankingService] Carregando arquivo ${i + 1}/$totalArquivos: $arquivo');
          
          final conteudoJson = await _driveService.baixarArquivoDaPasta(arquivo, pastaComData);
          if (conteudoJson.isNotEmpty) {
            final dados = json.decode(conteudoJson) as Map<String, dynamic>;
            final ranking = RankingDiario.fromJson(dados);
            todasEntradas.addAll(ranking.entradas);
            
            // Chama callback com progresso parcial
            onProgress?.call(i + 1, totalArquivos, List.from(todasEntradas));
            
            print('✅ [RankingService] Arquivo $arquivo processado: +${ranking.entradas.length} entradas (total: ${todasEntradas.length})');
          } else {
            // Mesmo se arquivo estiver vazio, chama o callback para atualizar progresso
            onProgress?.call(i + 1, totalArquivos, List.from(todasEntradas));
            print('⚠️ [RankingService] Arquivo $arquivo está vazio');
          }
        } catch (e) {
          print('⚠️ [RankingService] Erro ao processar arquivo $arquivo: $e');
          // Mesmo com erro, chama callback para atualizar progresso
          onProgress?.call(i + 1, totalArquivos, List.from(todasEntradas));
        }
        
        // Pequeno delay para não sobrecarregar
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      final rankingConsolidado = RankingDiario(
        data: dataSemHora,
        entradas: todasEntradas,
      );
      
      print('✅ [RankingService] Ranking progressivo finalizado: ${todasEntradas.length} entradas de ${arquivos.length} arquivos');
      return rankingConsolidado;
      
    } catch (e) {
      print('❌ [RankingService] Erro ao carregar ranking progressivo: $e');
      final dataSemHora = DateTime(data.year, data.month, data.day);
      onProgress?.call(0, 0, []);
      return RankingDiario(data: dataSemHora, entradas: []);
    }
  }

  /// Salva o ranking diário no Drive na pasta rankings por email
  Future<void> _salvarRankingDia(RankingDiario ranking, String email) async {
    try {
      final nomeArquivo = _getNomeArquivoRanking(ranking.data, email);
      final dadosJson = ranking.toJson();

      print('💾 [RankingService] Salvando ranking do dia: ${_formatarDataParaNomeArquivo(ranking.data)} para $email');

      // Salva na pasta rankings com subpasta por data
      final dataFormatada = _folderManager.formatarDataParaPasta(ranking.data);
      final pastaComData = 'rankings/$dataFormatada';
      print('🎯 [RankingService] Salvando na pasta: $pastaComData/$nomeArquivo');
      await _driveService.salvarArquivoEmPasta(nomeArquivo, json.encode(dadosJson), pastaComData);

      print('✅ [RankingService] Ranking salvo com sucesso para $email');

    } catch (e) {
      print('❌ [RankingService] Erro ao salvar ranking: $e');
      throw Exception('Erro ao salvar ranking: $e');
    }
  }

  /// Lista todos os arquivos de ranking de uma data específica
  Future<List<String>> _listarArquivosRankingPorData(DateTime data) async {
    try {
      final dataFormatada = _folderManager.formatarDataParaPasta(data);
      
      // Busca arquivos que começam com "ranking_" na pasta da data
      // Precisa usar o DriveService para listar arquivos da subpasta
      final arquivos = await _driveService.listarArquivosDaPasta('rankings/$dataFormatada');
      
      // Filtra apenas arquivos de ranking
      final arquivosRanking = arquivos.where((nome) => 
        nome.startsWith('ranking_') && nome.endsWith('.json')
      ).toList();
      
      print('📋 [RankingService] Encontrados ${arquivosRanking.length} arquivos de ranking para data $dataFormatada');
      return arquivosRanking;
      
    } catch (e) {
      print('❌ [RankingService] Erro ao listar arquivos de ranking: $e');
      return [];
    }
  }

  /// Obtém os top N jogadores de um dia específico
  Future<List<RankingEntry>> getTopJogadores(DateTime data, {int limite = 10}) async {
    try {
      final ranking = await carregarRankingDia(data);
      final ordenadas = ranking.entradasOrdenadas;
      
      // Retorna todas as entradas (cada runId é uma entrada separada)
      return ordenadas.take(limite).toList();
      
    } catch (e) {
      print('❌ [RankingService] Erro ao obter top jogadores: $e');
      return [];
    }
  }

  /// Obtém os top N jogadores de um dia específico com carregamento progressivo
  Future<List<RankingEntry>> getTopJogadoresProgressivo(
    DateTime data, {
    int limite = 10,
    Function(int carregados, int total, List<RankingEntry> topParciais)? onProgress,
  }) async {
    try {
      final ranking = await carregarRankingDiaProgressivo(data, onProgress: (carregados, total, entradas) {
        // Ordena as entradas parciais e pega o top
        final rankingParcial = RankingDiario(data: data, entradas: entradas);
        final topParcial = rankingParcial.entradasOrdenadas.take(limite).toList();
        
        // Chama callback com o top parcial
        onProgress?.call(carregados, total, topParcial);
      });
      
      final ordenadas = ranking.entradasOrdenadas;
      return ordenadas.take(limite).toList();
      
    } catch (e) {
      print('❌ [RankingService] Erro ao obter top jogadores progressivo: $e');
      return [];
    }
  }

  /// Obtém a posição de um jogador em um dia específico
  Future<int?> getPosicaoJogador(String email, DateTime data) async {
    try {
      final topJogadores = await getTopJogadores(data, limite: 999);
      
      for (int i = 0; i < topJogadores.length; i++) {
        if (topJogadores[i].email == email) {
          return i + 1; // 1-indexed
        }
      }
      
      return null; // Jogador não encontrado
      
    } catch (e) {
      print('❌ [RankingService] Erro ao obter posição do jogador: $e');
      return null;
    }
  }

  /// Obtém o melhor score de um jogador em um dia específico
  Future<int?> getMelhorScoreJogador(String email, DateTime data) async {
    try {
      final ranking = await carregarRankingDia(data);
      return ranking.getMelhorScoreJogador(email);
      
    } catch (e) {
      print('❌ [RankingService] Erro ao obter melhor score do jogador: $e');
      return null;
    }
  }

  /// Lista todas as datas que possuem ranking (últimos 30 dias) na pasta rankings
  Future<List<DateTime>> getDataComRanking({int diasLimite = 30}) async {
    try {
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final List<DateTime> datasComRanking = [];
      
      // Verifica os últimos N dias
      for (int i = 0; i < diasLimite; i++) {
        final dataVerificar = hoje.subtract(Duration(days: i));
        
        // Verifica se existe qualquer arquivo de ranking para esta data
        final arquivos = await _listarArquivosRankingPorData(dataVerificar);
        if (arquivos.isNotEmpty) {
          datasComRanking.add(dataVerificar);
        }
      }
      
      // Ordena por data (mais recente primeiro)
      datasComRanking.sort((a, b) => b.compareTo(a));
      
      print('📋 [RankingService] Encontradas ${datasComRanking.length} datas com ranking');
      return datasComRanking;
      
    } catch (e) {
      print('❌ [RankingService] Erro ao listar datas com ranking: $e');
      return [];
    }
  }

  /// Obtém estatísticas gerais de um dia
  Future<Map<String, dynamic>> getEstatisticasDia(DateTime data) async {
    try {
      final ranking = await carregarRankingDia(data);
      final entradas = ranking.entradas;
      
      if (entradas.isEmpty) {
        return {
          'totalJogadores': 0,
          'totalRuns': 0,
          'scoreMaximo': 0,
          'scoreMedio': 0,
          'scoreMinimo': 0,
        };
      }

      final scores = entradas.map((e) => e.score).toList();
      final jogadoresUnicos = entradas.map((e) => e.email).toSet();
      
      return {
        'totalJogadores': jogadoresUnicos.length,
        'totalRuns': entradas.length,
        'scoreMaximo': scores.reduce((a, b) => a > b ? a : b),
        'scoreMedio': (scores.reduce((a, b) => a + b) / scores.length).round(),
        'scoreMinimo': scores.reduce((a, b) => a < b ? a : b),
      };
      
    } catch (e) {
      print('❌ [RankingService] Erro ao obter estatísticas do dia: $e');
      return {
        'totalJogadores': 0,
        'totalRuns': 0,
        'scoreMaximo': 0,
        'scoreMedio': 0,
        'scoreMinimo': 0,
      };
    }
  }

  /// Remove uma entrada específica (por runId e email)
  Future<void> removerEntrada(String runId, DateTime data, String email) async {
    try {
      final ranking = await carregarRankingDiaEmail(data, email);
      final entradasFiltradas = ranking.entradas.where((e) => e.runId != runId).toList();
      
      final rankingAtualizado = ranking.copyWith(entradas: entradasFiltradas);
      await _salvarRankingDia(rankingAtualizado, email);
      
      print('✅ [RankingService] Entrada removida: $runId do email $email');
      
    } catch (e) {
      print('❌ [RankingService] Erro ao remover entrada: $e');
      throw Exception('Erro ao remover entrada: $e');
    }
  }
}