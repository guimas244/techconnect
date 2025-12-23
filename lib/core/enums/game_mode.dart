/// Enum que define os modos de jogo disponíveis no TechTerra
enum GameMode {
  /// Modo Unlock - Automático, foco em desbloquear monstros e passivas
  /// - Batalhas automáticas
  /// - Desbloqueia monstros de coleção
  /// - Obtém passivas
  /// - Kills são permanentes
  /// - Sem eventos
  unlock,

  /// Modo Explorador - Manual, foco em farm e estratégia
  /// - Batalhas manuais (jogador escolhe ações)
  /// - 2 monstros ativos + 3 no banco
  /// - Sistema de XP e level up
  /// - 3 slots de equipamento
  /// - Kills são moeda de troca
  /// - Lojas por tipagem
  explorador,
}

/// Extensão para adicionar funcionalidades ao GameMode
extension GameModeExtension on GameMode {
  /// Nome de exibição do modo
  String get displayName {
    switch (this) {
      case GameMode.unlock:
        return 'Modo Unlock';
      case GameMode.explorador:
        return 'Modo Explorador';
    }
  }

  /// Descrição curta do modo
  String get descricao {
    switch (this) {
      case GameMode.unlock:
        return 'Batalhas automáticas para desbloquear monstros e passivas';
      case GameMode.explorador:
        return 'Aventura estratégica com equipe de 2 monstros';
    }
  }

  /// Ícone do modo (usando Material Icons)
  String get iconName {
    switch (this) {
      case GameMode.unlock:
        return 'lock_open';
      case GameMode.explorador:
        return 'explore';
    }
  }
}
