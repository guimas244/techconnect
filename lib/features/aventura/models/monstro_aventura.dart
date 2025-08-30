import 'dart:math';
import '../../../shared/models/tipo_enum.dart';
import 'habilidade.dart';
import 'item.dart';

class MonstroAventura {
  final Tipo tipo;
  final Tipo tipoExtra;
  final String imagem;
  final int vida; // Vida máxima/inicial
  final int vidaAtual; // Vida atual (após combates)
  final int energia; // Energia máxima/inicial
  final int energiaAtual; // Energia atual (após usar habilidades)
  final int agilidade;
  final int ataque;
  final int defesa;
  final List<Habilidade> habilidades;
  final Item? itemEquipado; // Item equipado (opcional)
  final int level; // Level do monstro

  const MonstroAventura({
    required this.tipo,
    required this.tipoExtra,
    required this.imagem,
    required this.vida,
    int? vidaAtual, // Opcional, padrão é vida máxima
    required this.energia,
    int? energiaAtual, // Opcional, padrão é energia máxima
    required this.agilidade,
    required this.ataque,
    required this.defesa,
    required this.habilidades,
    this.itemEquipado, // Item equipado (opcional)
    this.level = 1, // Level inicial é 1
  }) : vidaAtual = vidaAtual ?? vida,
       energiaAtual = energiaAtual ?? energia;

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
      vidaAtual: json['vidaAtual'] ?? json['vida'] ?? 50, // Se não tem vidaAtual, usa vida
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
          : null,
      level: json['level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
      'tipoExtra': tipoExtra.name,
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

  MonstroAventura copyWith({
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
    return MonstroAventura(
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

  /// Evolui o monstro: aumenta o level em 1 e tenta evoluir uma habilidade aleatória
  /// Retorna um Map com o monstro evoluído e informações sobre a habilidade
  Map<String, dynamic> evoluir({required int levelInimigoDerrrotado}) {
    if (habilidades.isEmpty) {
      // Se não tem habilidades, apenas aumenta o level
      return {
        'monstro': copyWith(level: level + 1),
        'habilidadeEvoluiu': false,
        'motivo': 'sem_habilidades',
      };
    }

    // Escolhe uma habilidade aleatória para tentar evoluir
    final random = Random();
    final indexHabilidade = random.nextInt(habilidades.length);
    final habilidadeEscolhida = habilidades[indexHabilidade];
    
    // Verifica level gap da habilidade: só evolui se habilidade <= level inimigo
    // Regra: habilidade pode evoluir se for menor ou igual ao level do inimigo
    if (habilidadeEscolhida.level > levelInimigoDerrrotado) {
      return {
        'monstro': copyWith(level: level + 1),
        'habilidadeEvoluiu': false,
        'motivo': 'level_gap_habilidade',
        'habilidadeEscolhida': habilidadeEscolhida,
        'levelInimigo': levelInimigoDerrrotado,
      };
    }
    
    // Cria nova lista de habilidades com uma evoluída
    final novasHabilidades = <Habilidade>[];
    for (int i = 0; i < habilidades.length; i++) {
      if (i == indexHabilidade) {
        novasHabilidades.add(habilidades[i].evoluir());
      } else {
        novasHabilidades.add(habilidades[i]);
      }
    }

    return {
      'monstro': copyWith(level: level + 1, habilidades: novasHabilidades),
      'habilidadeEvoluiu': true,
      'habilidadeAntes': habilidadeEscolhida,
      'habilidadeDepois': habilidades[indexHabilidade].evoluir(),
    };
  }
}
