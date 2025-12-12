import '../../../shared/models/tipo_enum.dart';
import 'habilidade.dart';
import 'item.dart';
import 'passiva.dart';

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
  final bool isElite; // Se é um monstro elite
  final bool isRaro; // Se é um monstro raro da nova coleção
  final Passiva? passiva; // Passiva do inimigo (tier 11+, 5% chance)

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
    this.isElite = false, // Por padrão não é elite
    this.isRaro = false, // Por padrão não é raro
    this.passiva, // Passiva do inimigo (opcional)
  }) : vidaAtual = vidaAtual ?? vida,
       energiaAtual = energiaAtual ?? energia;

  factory MonstroInimigo.fromJson(Map<String, dynamic> json) {
    // Migra caminhos antigos de imagem para o novo formato
    String imagem = json['imagem'] ?? '';
    if (imagem.contains('assets/monstros/inicial/')) {
      imagem = imagem.replaceAll('assets/monstros/inicial/', 'assets/monstros_aventura/colecao_inicial/');
    } else if (imagem.contains('assets/monstros/nostalgico/') || imagem.contains('assets/monstros/nostalgicos/')) {
      imagem = imagem.replaceAll('assets/monstros/nostalgico/', 'assets/monstros_aventura/colecao_nostalgicos/');
      imagem = imagem.replaceAll('assets/monstros/nostalgicos/', 'assets/monstros_aventura/colecao_nostalgicos/');
    } else if (imagem.contains('assets/monstros/halloween/')) {
      imagem = imagem.replaceAll('assets/monstros/halloween/', 'assets/monstros_aventura/colecao_halloween/');
    }

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
      imagem: imagem,
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
      isElite: json['isElite'] ?? false,
      isRaro: json['isRaro'] ?? false,
      passiva: json['passiva'] != null
          ? Passiva.fromJson(json['passiva'] as Map<String, dynamic>)
          : null,
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
      'isElite': isElite,
      'isRaro': isRaro,
      'passiva': passiva?.toJson(),
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
    bool? isElite,
    bool? isRaro,
    Passiva? passiva,
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
      isElite: isElite ?? this.isElite,
      isRaro: isRaro ?? this.isRaro,
      passiva: passiva ?? this.passiva,
    );
  }

  // Getters para atributos totais (base + item equipado)
  int get vidaTotal => vida + (itemEquipado?.vida ?? 0);
  int get energiaTotal => energia + (itemEquipado?.energia ?? 0);
  int get ataqueTotal => ataque + (itemEquipado?.ataque ?? 0);
  int get defesaTotal => defesa + (itemEquipado?.defesa ?? 0);
  int get agilidadeTotal => agilidade + (itemEquipado?.agilidade ?? 0);

  // Getter para o nome do monstro (nostálgico ou inicial)
  String get nome {
    final ehNostalgico = imagem.contains('colecao_nostalgicos');
    final nomeBase = ehNostalgico ? tipo.nostalgicMonsterName : tipo.monsterName;
    return isElite ? '$nomeBase Elite' : nomeBase;
  }

  // Getter para verificar se é nostálgico
  bool get ehNostalgico => imagem.contains('colecao_nostalgicos');
}
