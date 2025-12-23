import '../../../shared/models/tipo_enum.dart';
import '../../aventura/models/habilidade.dart';

/// Monstro do Modo Explorador
///
/// Diferente do MonstroAventura, este monstro:
/// - Tem sistema de XP proprio
/// - Pode evoluir de level
/// - Tem 3 slots de equipamento (cabeca, peito, bracos)
/// - Mantem estado entre batalhas
class MonstroExplorador {
  final String id; // ID unico do monstro na equipe
  final Tipo tipo;
  final Tipo tipoExtra;
  final String imagem;
  final String nome;

  // Stats base (escalam com level)
  final int vidaBase;
  final int energiaBase;
  final int ataqueBase;
  final int defesaBase;
  final int agilidadeBase;

  // Stats atuais (durante batalha)
  final int vidaAtual;
  final int energiaAtual;

  // Sistema de XP e Level
  final int level;
  final int xpAtual;
  final int xpParaProximoLevel;

  // Habilidades
  final List<Habilidade> habilidades;

  // Equipamentos (3 slots)
  final EquipamentoExplorador? equipamentoCabeca;
  final EquipamentoExplorador? equipamentoPeito;
  final EquipamentoExplorador? equipamentoBracos;

  // Posicao na equipe
  final bool estaAtivo; // true = equipe ativa (2), false = banco (3)

  const MonstroExplorador({
    required this.id,
    required this.tipo,
    required this.tipoExtra,
    required this.imagem,
    required this.nome,
    required this.vidaBase,
    required this.energiaBase,
    required this.ataqueBase,
    required this.defesaBase,
    required this.agilidadeBase,
    int? vidaAtual,
    int? energiaAtual,
    this.level = 1,
    this.xpAtual = 0,
    this.xpParaProximoLevel = 100,
    this.habilidades = const [],
    this.equipamentoCabeca,
    this.equipamentoPeito,
    this.equipamentoBracos,
    this.estaAtivo = false,
  }) : vidaAtual = vidaAtual ?? vidaBase,
       energiaAtual = energiaAtual ?? energiaBase;

  // Getters para stats totais (base * multiplicador de level + equipamentos)
  double get multiplicadorLevel => 1.0 + (level - 1) * 0.1; // +10% por level

  int get vidaTotal {
    final baseComLevel = (vidaBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.vida ?? 0) +
                       (equipamentoPeito?.vida ?? 0) +
                       (equipamentoBracos?.vida ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get energiaTotal {
    final baseComLevel = (energiaBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.energia ?? 0) +
                       (equipamentoPeito?.energia ?? 0) +
                       (equipamentoBracos?.energia ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get ataqueTotal {
    final baseComLevel = (ataqueBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.ataque ?? 0) +
                       (equipamentoPeito?.ataque ?? 0) +
                       (equipamentoBracos?.ataque ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get defesaTotal {
    final baseComLevel = (defesaBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.defesa ?? 0) +
                       (equipamentoPeito?.defesa ?? 0) +
                       (equipamentoBracos?.defesa ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get agilidadeTotal {
    final baseComLevel = (agilidadeBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.agilidade ?? 0) +
                       (equipamentoPeito?.agilidade ?? 0) +
                       (equipamentoBracos?.agilidade ?? 0);
    return baseComLevel + bonusEquip;
  }

  /// Calcula XP necessario para o proximo level
  static int calcularXpParaLevel(int level) {
    // Formula: 100 * level^1.5
    return (100 * (level * 1.5)).round();
  }

  /// Adiciona XP e verifica se subiu de level
  MonstroExplorador adicionarXp(int quantidade) {
    var novoXp = xpAtual + quantidade;
    var novoLevel = level;
    var novoXpParaProximo = xpParaProximoLevel;

    // Verifica level ups
    while (novoXp >= novoXpParaProximo) {
      novoXp -= novoXpParaProximo;
      novoLevel++;
      novoXpParaProximo = calcularXpParaLevel(novoLevel);
    }

    return copyWith(
      level: novoLevel,
      xpAtual: novoXp,
      xpParaProximoLevel: novoXpParaProximo,
      // Restaura vida/energia ao subir de level
      vidaAtual: novoLevel > level ? vidaTotal : null,
      energiaAtual: novoLevel > level ? energiaTotal : null,
    );
  }

  /// Cura o monstro (restaura vida e energia)
  MonstroExplorador curar() {
    return copyWith(
      vidaAtual: vidaTotal,
      energiaAtual: energiaTotal,
    );
  }

  /// Recebe dano
  MonstroExplorador receberDano(int dano) {
    final novaVida = (vidaAtual - dano).clamp(0, vidaTotal);
    return copyWith(vidaAtual: novaVida);
  }

  /// Gasta energia
  MonstroExplorador gastarEnergia(int custo) {
    final novaEnergia = (energiaAtual - custo).clamp(0, energiaTotal);
    return copyWith(energiaAtual: novaEnergia);
  }

  /// Verifica se esta vivo
  bool get estaVivo => vidaAtual > 0;

  /// Porcentagem de vida
  double get porcentagemVida => vidaAtual / vidaTotal;

  /// Porcentagem de energia
  double get porcentagemEnergia => energiaAtual / energiaTotal;

  /// Porcentagem de XP
  double get porcentagemXp => xpAtual / xpParaProximoLevel;

  factory MonstroExplorador.fromJson(Map<String, dynamic> json) {
    return MonstroExplorador(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: Tipo.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => Tipo.normal,
      ),
      tipoExtra: Tipo.values.firstWhere(
        (t) => t.name == json['tipoExtra'],
        orElse: () => Tipo.normal,
      ),
      imagem: json['imagem'] ?? '',
      nome: json['nome'] ?? '',
      vidaBase: json['vidaBase'] ?? 100,
      energiaBase: json['energiaBase'] ?? 50,
      ataqueBase: json['ataqueBase'] ?? 20,
      defesaBase: json['defesaBase'] ?? 20,
      agilidadeBase: json['agilidadeBase'] ?? 15,
      vidaAtual: json['vidaAtual'],
      energiaAtual: json['energiaAtual'],
      level: json['level'] ?? 1,
      xpAtual: json['xpAtual'] ?? 0,
      xpParaProximoLevel: json['xpParaProximoLevel'] ?? 100,
      habilidades: (json['habilidades'] as List<dynamic>?)
          ?.map((h) => Habilidade.fromJson(h))
          .toList() ?? [],
      equipamentoCabeca: json['equipamentoCabeca'] != null
          ? EquipamentoExplorador.fromJson(json['equipamentoCabeca'])
          : null,
      equipamentoPeito: json['equipamentoPeito'] != null
          ? EquipamentoExplorador.fromJson(json['equipamentoPeito'])
          : null,
      equipamentoBracos: json['equipamentoBracos'] != null
          ? EquipamentoExplorador.fromJson(json['equipamentoBracos'])
          : null,
      estaAtivo: json['estaAtivo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.name,
      'tipoExtra': tipoExtra.name,
      'imagem': imagem,
      'nome': nome,
      'vidaBase': vidaBase,
      'energiaBase': energiaBase,
      'ataqueBase': ataqueBase,
      'defesaBase': defesaBase,
      'agilidadeBase': agilidadeBase,
      'vidaAtual': vidaAtual,
      'energiaAtual': energiaAtual,
      'level': level,
      'xpAtual': xpAtual,
      'xpParaProximoLevel': xpParaProximoLevel,
      'habilidades': habilidades.map((h) => h.toJson()).toList(),
      'equipamentoCabeca': equipamentoCabeca?.toJson(),
      'equipamentoPeito': equipamentoPeito?.toJson(),
      'equipamentoBracos': equipamentoBracos?.toJson(),
      'estaAtivo': estaAtivo,
    };
  }

  MonstroExplorador copyWith({
    String? id,
    Tipo? tipo,
    Tipo? tipoExtra,
    String? imagem,
    String? nome,
    int? vidaBase,
    int? energiaBase,
    int? ataqueBase,
    int? defesaBase,
    int? agilidadeBase,
    int? vidaAtual,
    int? energiaAtual,
    int? level,
    int? xpAtual,
    int? xpParaProximoLevel,
    List<Habilidade>? habilidades,
    EquipamentoExplorador? equipamentoCabeca,
    EquipamentoExplorador? equipamentoPeito,
    EquipamentoExplorador? equipamentoBracos,
    bool? estaAtivo,
    bool removerCabeca = false,
    bool removerPeito = false,
    bool removerBracos = false,
  }) {
    return MonstroExplorador(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      tipoExtra: tipoExtra ?? this.tipoExtra,
      imagem: imagem ?? this.imagem,
      nome: nome ?? this.nome,
      vidaBase: vidaBase ?? this.vidaBase,
      energiaBase: energiaBase ?? this.energiaBase,
      ataqueBase: ataqueBase ?? this.ataqueBase,
      defesaBase: defesaBase ?? this.defesaBase,
      agilidadeBase: agilidadeBase ?? this.agilidadeBase,
      vidaAtual: vidaAtual ?? this.vidaAtual,
      energiaAtual: energiaAtual ?? this.energiaAtual,
      level: level ?? this.level,
      xpAtual: xpAtual ?? this.xpAtual,
      xpParaProximoLevel: xpParaProximoLevel ?? this.xpParaProximoLevel,
      habilidades: habilidades ?? this.habilidades,
      equipamentoCabeca: removerCabeca ? null : (equipamentoCabeca ?? this.equipamentoCabeca),
      equipamentoPeito: removerPeito ? null : (equipamentoPeito ?? this.equipamentoPeito),
      equipamentoBracos: removerBracos ? null : (equipamentoBracos ?? this.equipamentoBracos),
      estaAtivo: estaAtivo ?? this.estaAtivo,
    );
  }
}

/// Slot de equipamento
enum SlotEquipamento {
  cabeca,
  peito,
  bracos;

  String get displayName {
    switch (this) {
      case SlotEquipamento.cabeca:
        return 'Cabeca';
      case SlotEquipamento.peito:
        return 'Peito';
      case SlotEquipamento.bracos:
        return 'Bracos';
    }
  }
}

/// Equipamento do Modo Explorador
class EquipamentoExplorador {
  final String id;
  final String nome;
  final SlotEquipamento slot;
  final Tipo tipoRequerido; // Tipo do monstro que pode usar
  final int tier; // Tier do equipamento (1-11)

  // Bonus de stats
  final int vida;
  final int energia;
  final int ataque;
  final int defesa;
  final int agilidade;

  // Preco em kills
  final int preco;

  const EquipamentoExplorador({
    required this.id,
    required this.nome,
    required this.slot,
    required this.tipoRequerido,
    this.tier = 1,
    this.vida = 0,
    this.energia = 0,
    this.ataque = 0,
    this.defesa = 0,
    this.agilidade = 0,
    this.preco = 10,
  });

  factory EquipamentoExplorador.fromJson(Map<String, dynamic> json) {
    return EquipamentoExplorador(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      slot: SlotEquipamento.values.firstWhere(
        (s) => s.name == json['slot'],
        orElse: () => SlotEquipamento.cabeca,
      ),
      tipoRequerido: Tipo.values.firstWhere(
        (t) => t.name == json['tipoRequerido'],
        orElse: () => Tipo.normal,
      ),
      tier: json['tier'] ?? 1,
      vida: json['vida'] ?? 0,
      energia: json['energia'] ?? 0,
      ataque: json['ataque'] ?? 0,
      defesa: json['defesa'] ?? 0,
      agilidade: json['agilidade'] ?? 0,
      preco: json['preco'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'slot': slot.name,
      'tipoRequerido': tipoRequerido.name,
      'tier': tier,
      'vida': vida,
      'energia': energia,
      'ataque': ataque,
      'defesa': defesa,
      'agilidade': agilidade,
      'preco': preco,
    };
  }
}
