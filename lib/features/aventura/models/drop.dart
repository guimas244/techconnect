enum TipoDrop {
  pocaoVidaPequena,
  pocaoVidaGrande,
  pedraRecriacao,
  joiaReforco,
  frutaNuty,
  frutaNutyCristalizada,
  vidinha,
}

extension TipoDropExtension on TipoDrop {
  String get nome {
    switch (this) {
      case TipoDrop.pocaoVidaPequena:
        return 'Poção de Vida Pequena';
      case TipoDrop.pocaoVidaGrande:
        return 'Poção de Vida Grande';
      case TipoDrop.pedraRecriacao:
        return 'Joia da Recriação';
      case TipoDrop.joiaReforco:
        return 'Joia de Reforço';
      case TipoDrop.frutaNuty:
        return 'Fruta Nuty';
      case TipoDrop.frutaNutyCristalizada:
        return 'Fruta Nuty Cristalizada';
      case TipoDrop.vidinha:
        return 'Vidinha';
    }
  }

  String get descricao {
    switch (this) {
      case TipoDrop.pocaoVidaPequena:
        return 'Cura 25% da vida de um monstro à escolha';
      case TipoDrop.pocaoVidaGrande:
        return 'Cura 100% da vida de um monstro à escolha';
      case TipoDrop.pedraRecriacao:
        return 'Recria o equipamento mantendo a raridade e sorteando tier alto';
      case TipoDrop.joiaReforco:
        return 'Ajusta os atributos do equipamento para o tier atual';
      case TipoDrop.frutaNuty:
        return 'Maximiza todos os atributos do monstro (apenas Level 1)';
      case TipoDrop.frutaNutyCristalizada:
        return 'Adiciona +10 em um atributo aleatório do monstro';
      case TipoDrop.vidinha:
        return 'Revive automaticamente seu monstro na primeira morte em batalha';
    }
  }

  String get imagePath {
    switch (this) {
      case TipoDrop.pocaoVidaPequena:
        return 'assets/drops/drop_pocao_vida_pequena.png';
      case TipoDrop.pocaoVidaGrande:
        return 'assets/drops/drop_pocao_vida_grande.png';
      case TipoDrop.pedraRecriacao:
        return 'assets/drops/drop_pedra_recriacao.png';
      case TipoDrop.joiaReforco:
        return 'assets/drops/drop_pedra_reforco.png';
      case TipoDrop.frutaNuty:
        return 'assets/drops/drop_fruta_nuty.png';
      case TipoDrop.frutaNutyCristalizada:
        return 'assets/drops/drop_fruta_nuty_cristalizada.png';
      case TipoDrop.vidinha:
        return 'assets/drops/drop_vidinha.png';
    }
  }

  String get id {
    return name;
  }
}

class Drop {
  final TipoDrop tipo;
  final int quantidade;

  Drop({
    required this.tipo,
    this.quantidade = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.id,
      'quantidade': quantidade,
    };
  }

  factory Drop.fromJson(Map<String, dynamic> json) {
    return Drop(
      tipo: TipoDrop.values.firstWhere((t) => t.id == json['tipo']),
      quantidade: json['quantidade'] as int? ?? 1,
    );
  }

  Drop copyWith({
    TipoDrop? tipo,
    int? quantidade,
  }) {
    return Drop(
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
    );
  }
}

class ConfiguracaoDrop {
  final TipoDrop tipo;
  final double porcentagemDrop; // 1-100

  ConfiguracaoDrop({
    required this.tipo,
    required this.porcentagemDrop,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.id,
      'porcentagemDrop': porcentagemDrop,
    };
  }

  factory ConfiguracaoDrop.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoDrop(
      tipo: TipoDrop.values.firstWhere((t) => t.id == json['tipo']),
      porcentagemDrop: (json['porcentagemDrop'] as num).toDouble(),
    );
  }

  ConfiguracaoDrop copyWith({
    TipoDrop? tipo,
    double? porcentagemDrop,
  }) {
    return ConfiguracaoDrop(
      tipo: tipo ?? this.tipo,
      porcentagemDrop: porcentagemDrop ?? this.porcentagemDrop,
    );
  }
}
