import '../../../shared/models/tipo_enum.dart';
import 'habilidade.dart';

class MonstroAventura {
  final Tipo tipo;
  final Tipo tipoExtra;
  final String imagem;
  final int vida;
  final int energia;
  final int agilidade;
  final int ataque;
  final int defesa;
  final List<Habilidade> habilidades;
  final String item;

  const MonstroAventura({
    required this.tipo,
    required this.tipoExtra,
    required this.imagem,
    required this.vida,
    required this.energia,
    required this.agilidade,
    required this.ataque,
    required this.defesa,
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
      energia: json['energia'] ?? 20,
      agilidade: json['agilidade'] ?? 10,
      ataque: json['ataque'] ?? 10,
      defesa: json['defesa'] ?? 40,
      habilidades: (json['habilidades'] as List<dynamic>?)
          ?.map((h) => Habilidade.fromJson(h))
          .toList() ?? [],
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
      'agilidade': agilidade,
      'ataque': ataque,
      'defesa': defesa,
      'habilidades': habilidades.map((h) => h.toJson()).toList(),
      'item': item,
    };
  }

  MonstroAventura copyWith({
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
    return MonstroAventura(
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
