import 'dart:convert';
import 'dart:math';
import '../models/ranking_entry.dart';
import '../../../core/services/google_drive_service.dart';

class RankingService {
  static final RankingService _instance = RankingService._internal();
  factory RankingService() => _instance;
  RankingService._internal();

  final GoogleDriveService _driveService = GoogleDriveService();

  /// Gera um ID único para uma nova run/aventura
  String gerarRunId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'run_${timestamp}_$random';
  }

  /// Converte DateTime para horário de Brasília
  DateTime paraHorarioBrasilia(DateTime utc) {
    // UTC-3 (horário de Brasília)
    return utc.subtract(const Duration(hours: 3));
  }

  /// Obtém DateTime atual em horário de Brasília
  DateTime get agora {
    return paraHorarioBrasilia(DateTime.now().toUtc());
  }

  /// Formata data para nome do arquivo (YYYY-MM-DD)
  String _formatarDataParaNomeArquivo(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  /// Obtém nome do arquivo de ranking para uma data específica
  String _getNomeArquivoRanking(DateTime data) {
    return 'ranking_${_formatarDataParaNomeArquivo(data)}.json';
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
      
      // Cria nova entrada de ranking
      final novaEntrada = RankingEntry(
        runId: runId,
        email: email,
        score: score,
        dataHora: dataHoraFinal,
      );

      // Carrega ranking do dia (se existir)
      final rankingDiario = await carregarRankingDia(dataSemHora);

      // Adiciona ou atualiza a entrada
      final rankingAtualizado = rankingDiario.adicionarOuAtualizar(novaEntrada);

      // Salva no Drive
      await _salvarRankingDia(rankingAtualizado);

      print('✅ [RankingService] Ranking atualizado com sucesso para $email');
      
    } catch (e) {
      print('❌ [RankingService] Erro ao atualizar ranking: $e');
      throw Exception('Erro ao atualizar ranking: $e');
    }
  }

  /// Carrega o ranking de um dia específico
  Future<RankingDiario> carregarRankingDia(DateTime data) async {
    try {
      final dataSemHora = DateTime(data.year, data.month, data.day);
      final nomeArquivo = _getNomeArquivoRanking(dataSemHora);
      
      print('📊 [RankingService] Carregando ranking do dia: ${_formatarDataParaNomeArquivo(dataSemHora)}');

      // Tenta baixar o arquivo do Drive
      final conteudoJson = await _driveService.baixarArquivoDaPasta(nomeArquivo, 'rankings');
      
      if (conteudoJson.isEmpty) {
        // Se não existe, cria ranking vazio para o dia
        print('📊 [RankingService] Ranking não encontrado para o dia, criando novo');
        return RankingDiario(
          data: dataSemHora,
          entradas: [],
        );
      }

      final dados = json.decode(conteudoJson) as Map<String, dynamic>;
      final ranking = RankingDiario.fromJson(dados);
      
      print('✅ [RankingService] Ranking carregado: ${ranking.entradas.length} entradas');
      return ranking;
      
    } catch (e) {
      print('❌ [RankingService] Erro ao carregar ranking do dia: $e');
      // Em caso de erro, retorna ranking vazio
      final dataSemHora = DateTime(data.year, data.month, data.day);
      return RankingDiario(
        data: dataSemHora,
        entradas: [],
      );
    }
  }

  /// Salva o ranking diário no Drive
  Future<void> _salvarRankingDia(RankingDiario ranking) async {
    try {
      final nomeArquivo = _getNomeArquivoRanking(ranking.data);
      final dadosJson = ranking.toJson();
      
      print('💾 [RankingService] Salvando ranking do dia: ${_formatarDataParaNomeArquivo(ranking.data)}');
      
      await _driveService.salvarArquivoEmPasta(nomeArquivo, json.encode(dadosJson), 'rankings');
      
      print('✅ [RankingService] Ranking salvo com sucesso');
      
    } catch (e) {
      print('❌ [RankingService] Erro ao salvar ranking: $e');
      throw Exception('Erro ao salvar ranking: $e');
    }
  }

  /// Obtém os top N jogadores de um dia específico
  Future<List<RankingEntry>> getTopJogadores(DateTime data, {int limite = 10}) async {
    try {
      final ranking = await carregarRankingDia(data);
      final ordenadas = ranking.entradasOrdenadas;
      
      // Retorna apenas o melhor score de cada jogador
      final Map<String, RankingEntry> melhoresScores = {};
      
      for (final entrada in ordenadas) {
        if (!melhoresScores.containsKey(entrada.email) || 
            melhoresScores[entrada.email]!.score < entrada.score) {
          melhoresScores[entrada.email] = entrada;
        }
      }
      
      final resultado = melhoresScores.values.toList();
      resultado.sort((a, b) => b.score.compareTo(a.score));
      
      return resultado.take(limite).toList();
      
    } catch (e) {
      print('❌ [RankingService] Erro ao obter top jogadores: $e');
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

  /// Lista todas as datas que possuem ranking (últimos 30 dias)
  Future<List<DateTime>> getDataComRanking({int diasLimite = 30}) async {
    try {
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final List<DateTime> datasComRanking = [];
      
      // Verifica os últimos N dias
      for (int i = 0; i < diasLimite; i++) {
        final dataVerificar = hoje.subtract(Duration(days: i));
        final nomeArquivo = _getNomeArquivoRanking(dataVerificar);
        
        // Verifica se existe arquivo para esta data
        final conteudo = await _driveService.baixarArquivoDaPasta(nomeArquivo, 'rankings');
        if (conteudo.isNotEmpty) {
          datasComRanking.add(dataVerificar);
        }
      }
      
      // Ordena por data (mais recente primeiro)
      datasComRanking.sort((a, b) => b.compareTo(a));
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

  /// Remove uma entrada específica (por runId)
  Future<void> removerEntrada(String runId, DateTime data) async {
    try {
      final ranking = await carregarRankingDia(data);
      final entradasFiltradas = ranking.entradas.where((e) => e.runId != runId).toList();
      
      final rankingAtualizado = ranking.copyWith(entradas: entradasFiltradas);
      await _salvarRankingDia(rankingAtualizado);
      
      print('✅ [RankingService] Entrada removida: $runId');
      
    } catch (e) {
      print('❌ [RankingService] Erro ao remover entrada: $e');
      throw Exception('Erro ao remover entrada: $e');
    }
  }
}