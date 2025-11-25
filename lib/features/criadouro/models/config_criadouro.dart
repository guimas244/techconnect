/// Configurações do Criadouro (notificações)
class ConfigCriadouro {
  /// Limite para notificar quando a barra ficar abaixo (em %)
  final int limiteFome;
  final int limiteSede;
  final int limiteHigiene;
  final int limiteAlegria;
  final int limiteSaude;

  /// Se deve notificar quando ficar doente
  final bool notificarDoenca;

  /// Se as notificações estão habilitadas globalmente
  final bool notificacoesAtivas;

  const ConfigCriadouro({
    this.limiteFome = 30,
    this.limiteSede = 30,
    this.limiteHigiene = 25,
    this.limiteAlegria = 20,
    this.limiteSaude = 50,
    this.notificarDoenca = true,
    this.notificacoesAtivas = true,
  });

  factory ConfigCriadouro.fromJson(Map<String, dynamic> json) {
    return ConfigCriadouro(
      limiteFome: json['limiteFome'] as int? ?? 30,
      limiteSede: json['limiteSede'] as int? ?? 30,
      limiteHigiene: json['limiteHigiene'] as int? ?? 25,
      limiteAlegria: json['limiteAlegria'] as int? ?? 20,
      limiteSaude: json['limiteSaude'] as int? ?? 50,
      notificarDoenca: json['notificarDoenca'] as bool? ?? true,
      notificacoesAtivas: json['notificacoesAtivas'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limiteFome': limiteFome,
      'limiteSede': limiteSede,
      'limiteHigiene': limiteHigiene,
      'limiteAlegria': limiteAlegria,
      'limiteSaude': limiteSaude,
      'notificarDoenca': notificarDoenca,
      'notificacoesAtivas': notificacoesAtivas,
    };
  }

  ConfigCriadouro copyWith({
    int? limiteFome,
    int? limiteSede,
    int? limiteHigiene,
    int? limiteAlegria,
    int? limiteSaude,
    bool? notificarDoenca,
    bool? notificacoesAtivas,
  }) {
    return ConfigCriadouro(
      limiteFome: limiteFome ?? this.limiteFome,
      limiteSede: limiteSede ?? this.limiteSede,
      limiteHigiene: limiteHigiene ?? this.limiteHigiene,
      limiteAlegria: limiteAlegria ?? this.limiteAlegria,
      limiteSaude: limiteSaude ?? this.limiteSaude,
      notificarDoenca: notificarDoenca ?? this.notificarDoenca,
      notificacoesAtivas: notificacoesAtivas ?? this.notificacoesAtivas,
    );
  }

  /// Retorna o limite para uma barra específica
  int limitePorBarra(String barra) {
    switch (barra) {
      case 'fome':
        return limiteFome;
      case 'sede':
        return limiteSede;
      case 'higiene':
        return limiteHigiene;
      case 'alegria':
        return limiteAlegria;
      case 'saude':
        return limiteSaude;
      default:
        return 30;
    }
  }
}
