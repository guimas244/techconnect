import '../../../shared/models/tipo_enum.dart';
import 'habilidade.dart';

class MonstroInimigo {
  final Tipo tipo;
  final Tipo? tipoExtra;
  final String imagem;
  final int vida;
  final int energia;
  final int agilidade;
  final int ataque;
  final int defesa;
  final List<Habilidade> habilidades;
  final String item;

  const MonstroInimigo({
    required this.tipo,
    this.tipoExtra,
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
      tipoExtra: json['tipoExtra'] != null 
          ? Tipo.values.firstWhere(
              (t) => t.name == json['tipoExtra'],
              orElse: () => Tipo.normal,
            )
          : null,
      imagem: json['imagem'] ?? '',
      vida: json['vida'] ?? 50,
      energia: json['energia'] ?? 20,
      agilidade: json['agilidade'] ?? 10,
      ataque: json['ataque'] ?? 10,
      defesa: json['defesa'] ?? 40,
      habilidades: (json['habilidades'] as List<dynamic>?)
          ?.map((h) => Habilidade.fromJson(h))
          .toList() ?? [],
      item: json['item'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
      'tipoExtra': tipoExtra?.name,
      'imagem': imagem,
      'vida': vida,
      'energia': energia,
      'agilidade': agilidade,
      'ataque': ataque,
      'defesa': defesa,
      'habilidades': habilidades.map((h) => h.toJson()).toList(),
      'item': item,
    };
  }

  MonstroInimigo copyWith({
    Tipo? tipo,
    Tipo? tipoExtra,
    String? imagem,
    int? vida,
    int? energia,
    int? agilidade,
    int? ataque,
    int? defesa,
    List<Habilidade>? habilidades,
    String? item,
  }) {
    return MonstroInimigo(
      tipo: tipo ?? this.tipo,
      tipoExtra: tipoExtra ?? this.tipoExtra,
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
