/// Representa o nível e XP de um TIPO de monstro
/// O level é permanente e vinculado ao tipo, não ao mascote individual
class LevelTipo {
  final String tipo; // Tipo do monstro (ex: 'fogo', 'agua')
  final int level;
  final int xpAtual;
  final DateTime? ultimoXpTempo; // Para controle de XP a cada 48h

  const LevelTipo({
    required this.tipo,
    this.level = 1,
    this.xpAtual = 0,
    this.ultimoXpTempo,
  });

  /// XP necessário para o próximo nível
  /// Level 1: 100 XP, Level 2: 125 XP, Level 3: 150 XP...
  int get xpParaProximoLevel => 75 + (level * 25);

  /// XP que falta para subir de nível
  int get xpFaltando => xpParaProximoLevel - xpAtual;

  /// Progresso de 0.0 a 1.0 para a barra
  double get progressoXp => xpAtual / xpParaProximoLevel;

  /// Verifica se pode ganhar XP de tempo (48h)
  bool get podeGanharXpTempo {
    if (ultimoXpTempo == null) return true;
    final horasPassadas = DateTime.now().difference(ultimoXpTempo!).inHours;
    return horasPassadas >= 48;
  }

  /// Horas restantes para ganhar XP de tempo
  int get horasParaXpTempo {
    if (ultimoXpTempo == null) return 0;
    final horasPassadas = DateTime.now().difference(ultimoXpTempo!).inHours;
    return (48 - horasPassadas).clamp(0, 48);
  }

  /// Adiciona XP e retorna novo LevelTipo (possivelmente com level aumentado)
  LevelTipo adicionarXp(int quantidade) {
    int novoXp = xpAtual + quantidade;
    int novoLevel = level;

    // Verifica se subiu de nível
    int xpNecessario = 75 + (novoLevel * 25);
    while (novoXp >= xpNecessario) {
      novoXp -= xpNecessario;
      novoLevel++;
      xpNecessario = 75 + (novoLevel * 25);
    }

    return LevelTipo(
      tipo: tipo,
      level: novoLevel,
      xpAtual: novoXp,
      ultimoXpTempo: ultimoXpTempo,
    );
  }

  /// Marca que ganhou XP de tempo (48h)
  LevelTipo marcarXpTempo() {
    return LevelTipo(
      tipo: tipo,
      level: level,
      xpAtual: xpAtual,
      ultimoXpTempo: DateTime.now(),
    );
  }

  factory LevelTipo.fromJson(Map<String, dynamic> json) {
    return LevelTipo(
      tipo: json['tipo'] as String,
      level: json['level'] as int? ?? 1,
      xpAtual: json['xpAtual'] as int? ?? 0,
      ultimoXpTempo: json['ultimoXpTempo'] != null
          ? DateTime.parse(json['ultimoXpTempo'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'level': level,
      'xpAtual': xpAtual,
      if (ultimoXpTempo != null)
        'ultimoXpTempo': ultimoXpTempo!.toIso8601String(),
    };
  }

  LevelTipo copyWith({
    String? tipo,
    int? level,
    int? xpAtual,
    DateTime? ultimoXpTempo,
    bool limparUltimoXpTempo = false,
  }) {
    return LevelTipo(
      tipo: tipo ?? this.tipo,
      level: level ?? this.level,
      xpAtual: xpAtual ?? this.xpAtual,
      ultimoXpTempo:
          limparUltimoXpTempo ? null : (ultimoXpTempo ?? this.ultimoXpTempo),
    );
  }

  @override
  String toString() =>
      'LevelTipo($tipo, Lv$level, $xpAtual/${xpParaProximoLevel}XP)';
}
