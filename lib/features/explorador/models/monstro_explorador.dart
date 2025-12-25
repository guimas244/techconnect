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
  // IMPORTANTE: Usa stats ATIVOS dos equipamentos (0 se quebrado)
  double get multiplicadorLevel => 1.0 + (level - 1) * 0.1; // +10% por level

  int get vidaTotal {
    final baseComLevel = (vidaBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.vidaAtiva ?? 0) +
                       (equipamentoPeito?.vidaAtiva ?? 0) +
                       (equipamentoBracos?.vidaAtiva ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get energiaTotal {
    final baseComLevel = (energiaBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.energiaAtiva ?? 0) +
                       (equipamentoPeito?.energiaAtiva ?? 0) +
                       (equipamentoBracos?.energiaAtiva ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get ataqueTotal {
    final baseComLevel = (ataqueBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.ataqueAtivo ?? 0) +
                       (equipamentoPeito?.ataqueAtivo ?? 0) +
                       (equipamentoBracos?.ataqueAtivo ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get defesaTotal {
    final baseComLevel = (defesaBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.defesaAtiva ?? 0) +
                       (equipamentoPeito?.defesaAtiva ?? 0) +
                       (equipamentoBracos?.defesaAtiva ?? 0);
    return baseComLevel + bonusEquip;
  }

  int get agilidadeTotal {
    final baseComLevel = (agilidadeBase * multiplicadorLevel).round();
    final bonusEquip = (equipamentoCabeca?.agilidadeAtiva ?? 0) +
                       (equipamentoPeito?.agilidadeAtiva ?? 0) +
                       (equipamentoBracos?.agilidadeAtiva ?? 0);
    return baseComLevel + bonusEquip;
  }

  /// Lista de todos os equipamentos equipados
  List<EquipamentoExplorador> get equipamentosEquipados {
    return [
      if (equipamentoCabeca != null) equipamentoCabeca!,
      if (equipamentoPeito != null) equipamentoPeito!,
      if (equipamentoBracos != null) equipamentoBracos!,
    ];
  }

  /// Verifica se tem algum equipamento quebrado
  bool get temEquipamentoQuebrado {
    return equipamentosEquipados.any((e) => e.estaQuebrado);
  }

  /// Conta quantos equipamentos estao quebrados
  int get quantidadeEquipamentosQuebrados {
    return equipamentosEquipados.where((e) => e.estaQuebrado).length;
  }

  /// Obtem equipamento por slot
  EquipamentoExplorador? getEquipamento(SlotEquipamento slot) {
    switch (slot) {
      case SlotEquipamento.cabeca:
        return equipamentoCabeca;
      case SlotEquipamento.peito:
        return equipamentoPeito;
      case SlotEquipamento.bracos:
        return equipamentoBracos;
    }
  }

  /// Verifica se o equipamento e compativel com o monstro
  bool equipamentoCompativel(EquipamentoExplorador equipamento) {
    return equipamento.tipoRequerido == tipo || equipamento.tipoRequerido == tipoExtra;
  }

  /// Equipa um equipamento no slot correspondente
  /// Retorna null se o equipamento nao for compativel
  MonstroExplorador? equipar(EquipamentoExplorador equipamento) {
    if (!equipamentoCompativel(equipamento)) return null;

    switch (equipamento.slot) {
      case SlotEquipamento.cabeca:
        return copyWith(equipamentoCabeca: equipamento);
      case SlotEquipamento.peito:
        return copyWith(equipamentoPeito: equipamento);
      case SlotEquipamento.bracos:
        return copyWith(equipamentoBracos: equipamento);
    }
  }

  /// Desequipa um slot
  MonstroExplorador desequipar(SlotEquipamento slot) {
    switch (slot) {
      case SlotEquipamento.cabeca:
        return copyWith(removerCabeca: true);
      case SlotEquipamento.peito:
        return copyWith(removerPeito: true);
      case SlotEquipamento.bracos:
        return copyWith(removerBracos: true);
    }
  }

  /// Usa todos os equipamentos em batalha (diminui durabilidade)
  MonstroExplorador usarEquipamentosEmBatalha() {
    return copyWith(
      equipamentoCabeca: equipamentoCabeca?.usarEmBatalha(),
      equipamentoPeito: equipamentoPeito?.usarEmBatalha(),
      equipamentoBracos: equipamentoBracos?.usarEmBatalha(),
    );
  }

  /// Repara todos os equipamentos
  MonstroExplorador repararTodosEquipamentos() {
    return copyWith(
      equipamentoCabeca: equipamentoCabeca?.reparar(),
      equipamentoPeito: equipamentoPeito?.reparar(),
      equipamentoBracos: equipamentoBracos?.reparar(),
    );
  }

  /// Repara um equipamento especifico
  MonstroExplorador repararEquipamento(SlotEquipamento slot) {
    switch (slot) {
      case SlotEquipamento.cabeca:
        return copyWith(equipamentoCabeca: equipamentoCabeca?.reparar());
      case SlotEquipamento.peito:
        return copyWith(equipamentoPeito: equipamentoPeito?.reparar());
      case SlotEquipamento.bracos:
        return copyWith(equipamentoBracos: equipamentoBracos?.reparar());
    }
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
        return 'Cabeça';
      case SlotEquipamento.peito:
        return 'Peito';
      case SlotEquipamento.bracos:
        return 'Braços';
    }
  }

  /// Icone do slot (path do asset)
  String get iconeAsset {
    switch (this) {
      case SlotEquipamento.cabeca:
        return 'assets/icons_gerais/slot_cabeca.png';
      case SlotEquipamento.peito:
        return 'assets/icons_gerais/slot_peito.png';
      case SlotEquipamento.bracos:
        return 'assets/icons_gerais/slot_bracos.png';
    }
  }

  /// Icone padrao (IconData) para fallback
  int get iconeCodePoint {
    switch (this) {
      case SlotEquipamento.cabeca:
        return 0xe3c9; // Icons.face
      case SlotEquipamento.peito:
        return 0xe8e8; // Icons.shield
      case SlotEquipamento.bracos:
        return 0xe263; // Icons.front_hand
    }
  }
}

/// Raridade do equipamento
enum RaridadeEquipamento {
  inferior(1, 'Inferior', 0xFF757575, 5),   // Cinza - 5 batalhas
  normal(2, 'Normal', 0xFF424242, 8),       // Cinza escuro - 8 batalhas
  raro(3, 'Raro', 0xFF388E3C, 12),          // Verde - 12 batalhas
  epico(4, 'Épico', 0xFF7B1FA2, 18),        // Roxo - 18 batalhas
  lendario(5, 'Lendário', 0xFFF57C00, 25),  // Laranja - 25 batalhas
  impossivel(6, 'Impossível', 0xFFD32F2F, 40); // Vermelho - 40 batalhas

  const RaridadeEquipamento(this.nivel, this.nome, this.corHex, this.durabilidadeBase);

  final int nivel;
  final String nome;
  final int corHex;
  final int durabilidadeBase;

  /// Retorna o caminho do icone de dorso baseado na raridade (legado, use iconeArmaduraPorSlot)
  String get iconeArmadura => iconeArmaduraDorso;

  /// Retorna o caminho do icone de dorso (peito) baseado na raridade
  String get iconeArmaduraDorso {
    switch (this) {
      case RaridadeEquipamento.inferior:
        return 'assets/armaduras/armadura_dorso_inferior.png';
      case RaridadeEquipamento.normal:
        return 'assets/armaduras/armadura_dorso_normal.png';
      case RaridadeEquipamento.raro:
        return 'assets/armaduras/armadura_dorso_rara.png';
      case RaridadeEquipamento.epico:
        return 'assets/armaduras/armadura_dorso_epica.png';
      case RaridadeEquipamento.lendario:
        return 'assets/armaduras/armadura_dorso_lendaria.png';
      case RaridadeEquipamento.impossivel:
        return 'assets/armaduras/armadura_dorso_impossivel.png';
    }
  }

  /// Retorna o caminho do icone de capacete (cabeca) baseado na raridade
  String get iconeArmaduraCapacete {
    switch (this) {
      case RaridadeEquipamento.inferior:
        return 'assets/armaduras/armadura_capacete_inferior.png';
      case RaridadeEquipamento.normal:
        return 'assets/armaduras/armadura_capacete_normal.png';
      case RaridadeEquipamento.raro:
        return 'assets/armaduras/armadura_capacete_rara.png';
      case RaridadeEquipamento.epico:
        return 'assets/armaduras/armadura_dorso_epica.png'; // Fallback para dorso
      case RaridadeEquipamento.lendario:
        return 'assets/armaduras/armadura_capacete_lendaria.png';
      case RaridadeEquipamento.impossivel:
        return 'assets/armaduras/armadura_capacete_impossivel.png';
    }
  }

  /// Retorna o caminho do icone de luvas (bracos) baseado na raridade
  String get iconeArmaduraLuvas {
    switch (this) {
      case RaridadeEquipamento.inferior:
        return 'assets/armaduras/armadura_luvas_inferior.png';
      case RaridadeEquipamento.normal:
        return 'assets/armaduras/armadura_luvas_normal.png';
      case RaridadeEquipamento.raro:
        return 'assets/armaduras/armadura_luvas_rara.png';
      case RaridadeEquipamento.epico:
        return 'assets/armaduras/armadura_dorso_epica.png'; // Fallback para dorso
      case RaridadeEquipamento.lendario:
        return 'assets/armaduras/armadura_luvas_lendaria.png';
      case RaridadeEquipamento.impossivel:
        return 'assets/armaduras/armadura_luvas_impossivel.png';
    }
  }

  /// Retorna o icone de armadura baseado no slot
  String iconeArmaduraPorSlot(SlotEquipamento slot) {
    switch (slot) {
      case SlotEquipamento.cabeca:
        return iconeArmaduraCapacete;
      case SlotEquipamento.peito:
        return iconeArmaduraDorso;
      case SlotEquipamento.bracos:
        return iconeArmaduraLuvas;
    }
  }
}

/// Equipamento do Modo Explorador
class EquipamentoExplorador {
  final String id;
  final String nome;
  final SlotEquipamento slot;
  final Tipo tipoRequerido; // Tipo do monstro que pode usar
  final RaridadeEquipamento raridade;
  final int tier; // Tier do equipamento (1-11)

  // Bonus de stats
  final int vida;
  final int energia;
  final int ataque;
  final int defesa;
  final int agilidade;

  // Durabilidade
  final int durabilidadeMax;
  final int durabilidadeAtual;

  // Preco em kills
  final int preco;

  EquipamentoExplorador({
    required this.id,
    required this.nome,
    required this.slot,
    required this.tipoRequerido,
    this.raridade = RaridadeEquipamento.normal,
    this.tier = 1,
    this.vida = 0,
    this.energia = 0,
    this.ataque = 0,
    this.defesa = 0,
    this.agilidade = 0,
    int? durabilidadeMax,
    int? durabilidadeAtual,
    this.preco = 10,
  }) : durabilidadeMax = durabilidadeMax ?? raridade.durabilidadeBase,
       durabilidadeAtual = durabilidadeAtual ?? durabilidadeMax ?? raridade.durabilidadeBase;

  /// Verifica se o equipamento esta quebrado
  bool get estaQuebrado => durabilidadeAtual <= 0;

  /// Porcentagem de durabilidade restante (0.0 a 1.0)
  double get porcentagemDurabilidade => durabilidadeAtual / durabilidadeMax;

  /// Retorna os stats ativos (0 se quebrado, senao normal)
  int get vidaAtiva => estaQuebrado ? 0 : vida;
  int get energiaAtiva => estaQuebrado ? 0 : energia;
  int get ataqueAtivo => estaQuebrado ? 0 : ataque;
  int get defesaAtiva => estaQuebrado ? 0 : defesa;
  int get agilidadeAtiva => estaQuebrado ? 0 : agilidade;

  /// Retorna o caminho do icone de armadura correto para este equipamento
  /// (baseado no slot e na raridade)
  String get iconeArmadura => raridade.iconeArmaduraPorSlot(slot);

  /// Usa o equipamento em batalha (diminui durabilidade)
  EquipamentoExplorador usarEmBatalha() {
    if (estaQuebrado) return this;
    return copyWith(durabilidadeAtual: durabilidadeAtual - 1);
  }

  /// Repara o equipamento (restaura durabilidade)
  EquipamentoExplorador reparar() {
    return copyWith(durabilidadeAtual: durabilidadeMax);
  }

  factory EquipamentoExplorador.fromJson(Map<String, dynamic> json) {
    final raridade = RaridadeEquipamento.values.firstWhere(
      (r) => r.name == json['raridade'],
      orElse: () => RaridadeEquipamento.normal,
    );
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
      raridade: raridade,
      tier: json['tier'] ?? 1,
      vida: json['vida'] ?? 0,
      energia: json['energia'] ?? 0,
      ataque: json['ataque'] ?? 0,
      defesa: json['defesa'] ?? 0,
      agilidade: json['agilidade'] ?? 0,
      durabilidadeMax: json['durabilidadeMax'] ?? raridade.durabilidadeBase,
      durabilidadeAtual: json['durabilidadeAtual'] ?? json['durabilidadeMax'] ?? raridade.durabilidadeBase,
      preco: json['preco'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'slot': slot.name,
      'tipoRequerido': tipoRequerido.name,
      'raridade': raridade.name,
      'tier': tier,
      'vida': vida,
      'energia': energia,
      'ataque': ataque,
      'defesa': defesa,
      'agilidade': agilidade,
      'durabilidadeMax': durabilidadeMax,
      'durabilidadeAtual': durabilidadeAtual,
      'preco': preco,
    };
  }

  EquipamentoExplorador copyWith({
    String? id,
    String? nome,
    SlotEquipamento? slot,
    Tipo? tipoRequerido,
    RaridadeEquipamento? raridade,
    int? tier,
    int? vida,
    int? energia,
    int? ataque,
    int? defesa,
    int? agilidade,
    int? durabilidadeMax,
    int? durabilidadeAtual,
    int? preco,
  }) {
    return EquipamentoExplorador(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      slot: slot ?? this.slot,
      tipoRequerido: tipoRequerido ?? this.tipoRequerido,
      raridade: raridade ?? this.raridade,
      tier: tier ?? this.tier,
      vida: vida ?? this.vida,
      energia: energia ?? this.energia,
      ataque: ataque ?? this.ataque,
      defesa: defesa ?? this.defesa,
      agilidade: agilidade ?? this.agilidade,
      durabilidadeMax: durabilidadeMax ?? this.durabilidadeMax,
      durabilidadeAtual: durabilidadeAtual ?? this.durabilidadeAtual,
      preco: preco ?? this.preco,
    );
  }
}
