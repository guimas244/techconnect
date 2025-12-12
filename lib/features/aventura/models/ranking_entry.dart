class RankingEntry {
  final String runId; // ID único da run/aventura
  final String email; // Email do jogador
  final int score; // Score obtido
  final DateTime dataHora; // Data e hora em horário de Brasília
  final String version; // Versão do jogo quando foi salvo
  final int andar; // Andar (tier) em que o jogador estava no momento do salvamento
  final int killsTotais; // Total de kills do jogador no momento do salvamento

  const RankingEntry({
    required this.runId,
    required this.email,
    required this.score,
    required this.dataHora,
    required this.version,
    this.andar = 0, // Default 0 para entradas antigas
    this.killsTotais = 0, // Default 0 para entradas antigas
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      runId: json['runId'] ?? '',
      email: json['email'] ?? '',
      score: json['score'] ?? 0,
      dataHora: DateTime.parse(json['dataHora']),
      version: json['version'] ?? '1.0', // Versão padrão para entradas antigas
      andar: json['andar'] ?? 0, // Default 0 para entradas antigas
      killsTotais: json['killsTotais'] ?? 0, // Default 0 para entradas antigas
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runId': runId,
      'email': email,
      'score': score,
      'dataHora': dataHora.toIso8601String(),
      'version': version,
      'andar': andar,
      'killsTotais': killsTotais,
    };
  }

  RankingEntry copyWith({
    String? runId,
    String? email,
    int? score,
    DateTime? dataHora,
    String? version,
    int? andar,
    int? killsTotais,
  }) {
    return RankingEntry(
      runId: runId ?? this.runId,
      email: email ?? this.email,
      score: score ?? this.score,
      dataHora: dataHora ?? this.dataHora,
      version: version ?? this.version,
      andar: andar ?? this.andar,
      killsTotais: killsTotais ?? this.killsTotais,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingEntry &&
          runtimeType == other.runtimeType &&
          runId == other.runId;

  @override
  int get hashCode => runId.hashCode;

  @override
  String toString() {
    return 'RankingEntry{runId: $runId, email: $email, score: $score, dataHora: $dataHora, version: $version, andar: $andar, killsTotais: $killsTotais}';
  }
}

/// Modelo para representar o ranking diário
class RankingDiario {
  final DateTime data; // Data do ranking (sem horário)
  final List<RankingEntry> entradas; // Lista de entradas do dia

  const RankingDiario({
    required this.data,
    required this.entradas,
  });

  factory RankingDiario.fromJson(Map<String, dynamic> json) {
    return RankingDiario(
      data: DateTime.parse(json['data']),
      entradas: (json['entradas'] as List<dynamic>?)
          ?.map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toIso8601String(),
      'entradas': entradas.map((e) => e.toJson()).toList(),
    };
  }

  /// Retorna as entradas ordenadas por score (maior para menor)
  List<RankingEntry> get entradasOrdenadas {
    final lista = List<RankingEntry>.from(entradas);
    lista.sort((a, b) => b.score.compareTo(a.score));
    return lista;
  }

  /// Adiciona uma nova entrada ou atualiza se já existir (mesmo runId)
  RankingDiario adicionarOuAtualizar(RankingEntry novaEntrada) {
    final listaAtualizada = List<RankingEntry>.from(entradas);
    
    // Remove entrada existente com mesmo runId, se houver
    listaAtualizada.removeWhere((entrada) => entrada.runId == novaEntrada.runId);
    
    // Adiciona a nova entrada
    listaAtualizada.add(novaEntrada);
    
    return RankingDiario(
      data: data,
      entradas: listaAtualizada,
    );
  }

  /// Retorna a posição de um jogador específico (1-indexed), ou null se não encontrado
  int? getPosicaoJogador(String email) {
    final ordenadas = entradasOrdenadas;
    for (int i = 0; i < ordenadas.length; i++) {
      if (ordenadas[i].email == email) {
        return i + 1; // 1-indexed
      }
    }
    return null;
  }

  /// Retorna o melhor score de um jogador específico
  int? getMelhorScoreJogador(String email) {
    final entradasJogador = entradas.where((e) => e.email == email);
    if (entradasJogador.isEmpty) return null;
    
    return entradasJogador.map((e) => e.score).reduce((a, b) => a > b ? a : b);
  }

  RankingDiario copyWith({
    DateTime? data,
    List<RankingEntry>? entradas,
  }) {
    return RankingDiario(
      data: data ?? this.data,
      entradas: entradas ?? this.entradas,
    );
  }

  @override
  String toString() {
    return 'RankingDiario{data: $data, entradas: ${entradas.length}}';
  }
}