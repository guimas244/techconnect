import 'enums/causa_morte.dart';

/// Registro de um mascote que morreu (para o Memorial)
class MascoteMorto {
  final String id;
  final String nome;
  final String monstroId; // Imagem do monstro
  final int diasVivido;
  final CausaMorte causaMorte;
  final DateTime dataMorte;
  final Map<String, double> estatisticasFinais; // Valores das barras ao morrer

  const MascoteMorto({
    required this.id,
    required this.nome,
    required this.monstroId,
    required this.diasVivido,
    required this.causaMorte,
    required this.dataMorte,
    required this.estatisticasFinais,
  });

  factory MascoteMorto.fromJson(Map<String, dynamic> json) {
    return MascoteMorto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      monstroId: json['monstroId'] as String,
      diasVivido: json['diasVivido'] as int,
      causaMorte: CausaMorte.values.firstWhere(
        (c) => c.name == json['causaMorte'],
        orElse: () => CausaMorte.saude,
      ),
      dataMorte: DateTime.parse(json['dataMorte'] as String),
      estatisticasFinais:
          Map<String, double>.from(json['estatisticasFinais'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'monstroId': monstroId,
      'diasVivido': diasVivido,
      'causaMorte': causaMorte.name,
      'dataMorte': dataMorte.toIso8601String(),
      'estatisticasFinais': estatisticasFinais,
    };
  }

  /// Cria um registro de morte a partir de um mascote
  factory MascoteMorto.fromMascote({
    required String id,
    required String nome,
    required String monstroId,
    required DateTime dataCriacao,
    required double fome,
    required double sede,
    required double higiene,
    required double alegria,
    required double saude,
    required bool estaDoente,
    required String? barraZerada,
  }) {
    // Determina a causa da morte
    CausaMorte causa;
    if (saude <= 0) {
      causa = CausaMorte.saude;
    } else if (barraZerada == 'fome' || fome <= 0) {
      causa = CausaMorte.fome;
    } else if (barraZerada == 'sede' || sede <= 0) {
      causa = CausaMorte.sede;
    } else if (barraZerada == 'higiene' || higiene <= 0) {
      causa = CausaMorte.higiene;
    } else if (estaDoente) {
      causa = CausaMorte.doenca;
    } else {
      causa = CausaMorte.saude;
    }

    return MascoteMorto(
      id: id,
      nome: nome,
      monstroId: monstroId,
      diasVivido: DateTime.now().difference(dataCriacao).inDays,
      causaMorte: causa,
      dataMorte: DateTime.now(),
      estatisticasFinais: {
        'fome': fome,
        'sede': sede,
        'higiene': higiene,
        'alegria': alegria,
        'saude': saude,
      },
    );
  }

  /// Descrição formatada da morte
  String get descricaoMorte =>
      '${causaMorte.emoji} ${causaMorte.descricao} após $diasVivido dias';

  /// Data formatada
  String get dataFormatada =>
      '${dataMorte.day.toString().padLeft(2, '0')}/${dataMorte.month.toString().padLeft(2, '0')}/${dataMorte.year}';
}
