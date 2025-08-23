import '../../../shared/models/tipo_enum.dart';

class MonstroInimigo {
  final Tipo tipo;
  final String imagem;
  final int vida;
  final int energia;
  final int agilidade;
  final int ataque;
  final int defesa;
  final List<String> habilidades;
  final String item;

  const MonstroInimigo({
    required this.tipo,
    required this.imagem,
    required this.vida,
    required this.energia,
    required this.agilidade,
    required this.ataque,
    required this.defesa,
    required this.habilidades,
    required this.item,
  });

  factory MonstroInimigo.fromJson(Map<String, dynamic> json) {
    return MonstroInimigo(
      tipo: Tipo.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => Tipo.normal,
      ),
      imagem: json['imagem'] ?? '',
      vida: json['vida'] ?? 50,
      energia: json['energia'] ?? 20,
      agilidade: json['agilidade'] ?? 10,
      ataque: json['ataque'] ?? 10,
      defesa: json['defesa'] ?? 40,
      habilidades: List<String>.from(json['habilidades'] ?? []),
      item: json['item'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
      'imagem': imagem,
      'vida': vida,
      'energia': energia,
      'agilidade': agilidade,
      'ataque': ataque,
      'defesa': defesa,
      'habilidades': habilidades,
      'item': item,
    };
  }

  MonstroInimigo copyWith({
    Tipo? tipo,
    String? imagem,
    int? vida,
    int? energia,
    int? agilidade,
    int? ataque,
    int? defesa,
    List<String>? habilidades,
    String? item,
  }) {
    return MonstroInimigo(
      tipo: tipo ?? this.tipo,
      imagem: imagem ?? this.imagem,
      vida: vida ?? this.vida,
      energia: energia ?? this.energia,
      agilidade: agilidade ?? this.agilidade,
      ataque: ataque ?? this.ataque,
      defesa: defesa ?? this.defesa,
      habilidades: habilidades ?? this.habilidades,
      item: item ?? this.item,
    );
  }
}
