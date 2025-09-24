import '../../../shared/models/tipo_enum.dart';
import 'habilidade.dart';
import 'item.dart';

class MonstroInimigo {
  final Tipo tipo;
  final Tipo? tipoExtra;
  final String imagem;
  final int vida; // Vida máxima/inicial
  final int vidaAtual; // Vida atual (após combates)
  final int energia; // Energia máxima/inicial
  final int energiaAtual; // Energia atual (após usar habilidades)
  final int agilidade;
  final int ataque;
  final int defesa;
  final List<Habilidade> habilidades;
  final Item? itemEquipado;
  final int level; // Level do monstro

  const MonstroInimigo({
    required this.tipo,
    this.tipoExtra,
    required this.imagem,
    required this.vida,
    int? vidaAtual, // Opcional, padrão é vida máxima
    required this.energia,
    int? energiaAtual, // Opcional, padrão é energia máxima
    required this.agilidade,
    required this.ataque,
    required this.defesa,
    required this.habilidades,
    this.itemEquipado,
    this.level = 1, // Level inicial é 1
  }) : vidaAtual = vidaAtual ?? vida,
       energiaAtual = energiaAtual ?? energia;

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
      vida: json['vida'] ?? 75,
      vidaAtual: (() {
        final vidaAtualJson = json['vidaAtual'];
        final vidaJson = json['vida'] ?? 75;
        final resultado = vidaAtualJson ?? vidaJson;
        print('🏥 [DEBUG] MonstroInimigo.fromJson - vidaAtual: $vidaAtualJson, vida: $vidaJson, resultado: $resultado');
        return resultado;
      })(),
      energia: json['energia'] ?? 20,
      energiaAtual: json['energiaAtual'] ?? json['energia'] ?? 20, // Se não tem energiaAtual, usa energia
      agilidade: json['agilidade'] ?? 10,
      ataque: json['ataque'] ?? 10,
      defesa: json['defesa'] ?? 40,
      habilidades: (json['habilidades'] as List<dynamic>?)
          ?.map((h) => Habilidade.fromJson(h))
          .toList() ?? [],
      itemEquipado: json['itemEquipado'] != null 
          ? Item.fromMap(json['itemEquipado'] as Map<String, dynamic>)
          : null, // Ignora o campo 'item' antigo (String) se existir
      level: json['level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
      'tipoExtra': tipoExtra?.name,
      'imagem': imagem,
      'vida': vida,
      'vidaAtual': vidaAtual,
      'energia': energia,
      'energiaAtual': energiaAtual,
      'agilidade': agilidade,
      'ataque': ataque,
      'defesa': defesa,
      'habilidades': habilidades.map((h) => h.toJson()).toList(),
      'itemEquipado': itemEquipado?.toMap(),
      'level': level,
    };
  }

  MonstroInimigo copyWith({
    Tipo? tipo,
    Tipo? tipoExtra,
    String? imagem,
    int? vida,
    int? vidaAtual,
    int? energia,
    int? energiaAtual,
    int? agilidade,
    int? ataque,
    int? defesa,
    List<Habilidade>? habilidades,
    Item? itemEquipado,
    int? level,
  }) {
    return MonstroInimigo(
      tipo: tipo ?? this.tipo,
      tipoExtra: tipoExtra ?? this.tipoExtra,
      imagem: imagem ?? this.imagem,
      vida: vida ?? this.vida,
      vidaAtual: vidaAtual ?? this.vidaAtual,
      energia: energia ?? this.energia,
      energiaAtual: energiaAtual ?? this.energiaAtual,
      agilidade: agilidade ?? this.agilidade,
      ataque: ataque ?? this.ataque,
      defesa: defesa ?? this.defesa,
      habilidades: habilidades ?? this.habilidades,
      itemEquipado: itemEquipado ?? this.itemEquipado,
      level: level ?? this.level,
    );
  }

  // Getters para atributos totais (base + item equipado)
  int get vidaTotal => vida + (itemEquipado?.vida ?? 0);
  int get energiaTotal => energia + (itemEquipado?.energia ?? 0);
  int get ataqueTotal => ataque + (itemEquipado?.ataque ?? 0);
  int get defesaTotal => defesa + (itemEquipado?.defesa ?? 0);
  int get agilidadeTotal => agilidade + (itemEquipado?.agilidade ?? 0);
}
