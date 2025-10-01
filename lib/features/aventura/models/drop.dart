enum TipoDrop {
  pocaoVidaPequena,
  pocaoVidaGrande,
  pedraReforco,
}

extension TipoDropExtension on TipoDrop {
  String get nome {
    switch (this) {
      case TipoDrop.pocaoVidaPequena:
        return 'Poção de Vida Pequena';
      case TipoDrop.pocaoVidaGrande:
        return 'Poção de Vida Grande';
      case TipoDrop.pedraReforco:
        return 'Pedra de Reforço';
    }
  }

  String get descricao {
    switch (this) {
      case TipoDrop.pocaoVidaPequena:
        return 'Cura 25% da vida de um monstro à escolha';
      case TipoDrop.pocaoVidaGrande:
        return 'Cura 100% da vida de um monstro à escolha';
      case TipoDrop.pedraReforco:
        return 'Sobe 1 level/tier de um equipamento de um monstro à escolha';
    }
  }

  String get imagePath {
    switch (this) {
      case TipoDrop.pocaoVidaPequena:
        return 'assets/drops/drop_pocao_vida_pequena.png';
      case TipoDrop.pocaoVidaGrande:
        return 'assets/drops/drop_pocao_vida_grande.png';
      case TipoDrop.pedraReforco:
        return 'assets/drops/drop_pedra_reforco.png';
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
