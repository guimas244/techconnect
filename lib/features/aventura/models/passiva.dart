enum TipoPassiva {
  critico,
  esquiva,
  curaDeBatalha,
  mercador,
  sortudo,
}

extension TipoPassivaExtension on TipoPassiva {
  String get nome {
    switch (this) {
      case TipoPassiva.critico:
        return 'Crítico';
      case TipoPassiva.esquiva:
        return 'Esquiva';
      case TipoPassiva.curaDeBatalha:
        return 'Cura de Batalha';
      case TipoPassiva.mercador:
        return 'Mercador';
      case TipoPassiva.sortudo:
        return 'Sortudo';
    }
  }

  String get descricao {
    switch (this) {
      case TipoPassiva.critico:
        return '10% de chance de crítico (dobra o dano)';
      case TipoPassiva.esquiva:
        return '10% de chance de esquivar (não leva o ataque)';
      case TipoPassiva.curaDeBatalha:
        return 'Toda cura recebida é dobrada (regen e habilidades de cura)';
      case TipoPassiva.mercador:
        return 'Todos os itens da loja Karma custam metade do preço';
      case TipoPassiva.sortudo:
        return 'Dobra a chance de encontrar drops em todas as batalhas';
    }
  }

  String get icone {
    switch (this) {
      case TipoPassiva.critico:
        return '⚔️';
      case TipoPassiva.esquiva:
        return '💨';
      case TipoPassiva.curaDeBatalha:
        return '❤️';
      case TipoPassiva.mercador:
        return '💰';
      case TipoPassiva.sortudo:
        return '🍀';
    }
  }
}

class Passiva {
  final TipoPassiva tipo;

  const Passiva({
    required this.tipo,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
    };
  }

  factory Passiva.fromJson(Map<String, dynamic> json) {
    return Passiva(
      tipo: TipoPassiva.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => TipoPassiva.critico,
      ),
    );
  }

  Passiva copyWith({
    TipoPassiva? tipo,
  }) {
    return Passiva(
      tipo: tipo ?? this.tipo,
    );
  }
}
