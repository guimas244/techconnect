import '../../../shared/models/tipo_enum.dart';


class MonstroAventura {
  final Tipo tipo;
  final Tipo tipoExtra;
  final String imagem;
  final int vida;
  final int energia;
  final List<String> habilidades;
  final String item;

  const MonstroAventura({
    required this.tipo,
    required this.tipoExtra,
    required this.imagem,
    required this.vida,
    required this.energia,
    required this.habilidades,
    required this.item,
  });

  factory MonstroAventura.fromJson(Map<String, dynamic> json) {
    return MonstroAventura(
      tipo: Tipo.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => Tipo.normal,
      ),
      tipoExtra: Tipo.values.firstWhere(
        (t) => t.name == json['tipoExtra'],
        orElse: () => Tipo.normal,
      ),
      imagem: json['imagem'] ?? '',
      vida: json['vida'] ?? 50,
      energia: json['energia'] ?? 50,
      habilidades: List<String>.from(json['habilidades'] ?? ['TODO', 'TODO', 'TODO', 'TODO']),
      item: json['item'] ?? 'TODO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
      'tipoExtra': tipoExtra.name,
      'imagem': imagem,
      'vida': vida,
      'energia': energia,
      'habilidades': habilidades,
      'item': item,
    };
  }

  MonstroAventura copyWith({
    Tipo? tipo,
    Tipo? tipoExtra,
    String? imagem,
    int? vida,
    int? energia,
    List<String>? habilidades,
    String? item,
  }) {
    return MonstroAventura(
      tipo: tipo ?? this.tipo,
      tipoExtra: tipoExtra ?? this.tipoExtra,
      imagem: imagem ?? this.imagem,
      vida: vida ?? this.vida,
      energia: energia ?? this.energia,
      habilidades: habilidades ?? this.habilidades,
      item: item ?? this.item,
    );
  }
}
