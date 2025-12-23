import 'dart:math';
import '../../../shared/models/tipo_enum.dart';

/// Representa um item disponivel na loja do Explorador
class ItemLoja {
  final String id;
  final String nome;
  final String descricao;
  final TipoItem tipoItem;
  final SlotEquipamento? slot; // Apenas para equipamentos
  final Tipo? tipoElemental; // Tipo do item (para bonus STAB)
  final int tier; // 1-11, afeta preco e stats
  final Map<String, int> bonusStats; // {'vida': 10, 'ataque': 5, etc}
  final int preco; // Em kills do mesmo tipo

  const ItemLoja({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.tipoItem,
    this.slot,
    this.tipoElemental,
    required this.tier,
    this.bonusStats = const {},
    required this.preco,
  });

  /// Gera itens aleatorios para a loja baseado no tier e kills disponiveis
  static List<ItemLoja> gerarItensLoja({
    required int tierAtual,
    required Map<Tipo, int> killsPorTipo,
    int quantidade = 6,
  }) {
    final random = Random();
    final itens = <ItemLoja>[];

    // Tipos com kills disponiveis
    final tiposComKills = killsPorTipo.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    if (tiposComKills.isEmpty) {
      tiposComKills.addAll(Tipo.values.take(5));
    }

    for (int i = 0; i < quantidade; i++) {
      final tipo = tiposComKills[random.nextInt(tiposComKills.length)];
      final tipoItem = TipoItem.values[random.nextInt(TipoItem.values.length)];

      // Tier do item varia baseado no tier atual (nunca acima)
      final tierItem = random.nextInt(tierAtual) + 1;

      itens.add(_gerarItem(
        tipo: tipo,
        tipoItem: tipoItem,
        tier: tierItem,
        random: random,
      ));
    }

    return itens;
  }

  static ItemLoja _gerarItem({
    required Tipo tipo,
    required TipoItem tipoItem,
    required int tier,
    required Random random,
  }) {
    late SlotEquipamento? slot;
    late String nome;
    late String descricao;
    late Map<String, int> bonus;
    late int precoBase;

    switch (tipoItem) {
      case TipoItem.equipCabeca:
        slot = SlotEquipamento.cabeca;
        nome = _nomesEquipCabeca[random.nextInt(_nomesEquipCabeca.length)];
        descricao = 'Equipamento de cabeca tipo ${tipo.displayName}';
        bonus = {
          'vida': 5 + (tier * 3),
          'defesa': 2 + tier,
        };
        precoBase = 10 + (tier * 5);
        break;

      case TipoItem.equipPeito:
        slot = SlotEquipamento.peito;
        nome = _nomesEquipPeito[random.nextInt(_nomesEquipPeito.length)];
        descricao = 'Armadura tipo ${tipo.displayName}';
        bonus = {
          'vida': 10 + (tier * 5),
          'defesa': 3 + (tier * 2),
        };
        precoBase = 15 + (tier * 8);
        break;

      case TipoItem.equipBracos:
        slot = SlotEquipamento.bracos;
        nome = _nomesEquipBracos[random.nextInt(_nomesEquipBracos.length)];
        descricao = 'Bracelete tipo ${tipo.displayName}';
        bonus = {
          'ataque': 3 + (tier * 2),
          'agilidade': 2 + tier,
        };
        precoBase = 12 + (tier * 6);
        break;

      case TipoItem.pocaoVida:
        slot = null;
        nome = 'Pocao de Vida ${_sufixoTier(tier)}';
        descricao = 'Recupera ${20 + tier * 10} HP';
        bonus = {'cura': 20 + (tier * 10)};
        precoBase = 5 + (tier * 2);
        break;

      case TipoItem.pocaoEnergia:
        slot = null;
        nome = 'Pocao de Energia ${_sufixoTier(tier)}';
        descricao = 'Recupera ${10 + tier * 5} energia';
        bonus = {'energia': 10 + (tier * 5)};
        precoBase = 4 + (tier * 2);
        break;

      case TipoItem.boostAtaque:
        slot = null;
        nome = 'Elixir de Forca ${_sufixoTier(tier)}';
        descricao = '+${5 + tier * 2}% ataque por 1 batalha';
        bonus = {'ataque_pct': 5 + (tier * 2)};
        precoBase = 8 + (tier * 3);
        break;

      case TipoItem.boostDefesa:
        slot = null;
        nome = 'Elixir de Defesa ${_sufixoTier(tier)}';
        descricao = '+${5 + tier * 2}% defesa por 1 batalha';
        bonus = {'defesa_pct': 5 + (tier * 2)};
        precoBase = 8 + (tier * 3);
        break;
    }

    // Adiciona sufixo do tipo ao nome do equipamento
    if (slot != null) {
      nome = '$nome ${_sufixoTipo(tipo)}';
    }

    return ItemLoja(
      id: '${tipoItem.name}_${tipo.name}_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}',
      nome: nome,
      descricao: descricao,
      tipoItem: tipoItem,
      slot: slot,
      tipoElemental: tipo,
      tier: tier,
      bonusStats: bonus,
      preco: precoBase,
    );
  }

  static String _sufixoTier(int tier) {
    if (tier <= 2) return 'Menor';
    if (tier <= 4) return 'Comum';
    if (tier <= 6) return 'Medio';
    if (tier <= 8) return 'Maior';
    if (tier <= 10) return 'Superior';
    return 'Supremo';
  }

  static String _sufixoTipo(Tipo tipo) {
    switch (tipo) {
      case Tipo.fogo:
        return 'Flamejante';
      case Tipo.agua:
        return 'Aquatico';
      case Tipo.planta:
        return 'Florestal';
      case Tipo.eletrico:
        return 'Eletrico';
      case Tipo.gelo:
        return 'Glacial';
      case Tipo.dragao:
        return 'Draconico';
      case Tipo.trevas:
        return 'Sombrio';
      case Tipo.luz:
        return 'Radiante';
      case Tipo.psiquico:
        return 'Mental';
      case Tipo.fantasma:
        return 'Espectral';
      case Tipo.pedra:
        return 'Rochoso';
      case Tipo.terrestre:
        return 'Terreno';
      case Tipo.voador:
        return 'Aereo';
      case Tipo.venenoso:
        return 'Toxico';
      case Tipo.inseto:
        return 'Insectil';
      case Tipo.fera:
        return 'Bestial';
      case Tipo.tecnologia:
        return 'Tech';
      case Tipo.magico:
        return 'Arcano';
      default:
        return 'Comum';
    }
  }

  static const _nomesEquipCabeca = [
    'Elmo',
    'Capacete',
    'Tiara',
    'Coroa',
    'Capuz',
    'Mascara',
  ];

  static const _nomesEquipPeito = [
    'Peitoral',
    'Armadura',
    'Tunica',
    'Cota',
    'Manto',
    'Veste',
  ];

  static const _nomesEquipBracos = [
    'Bracelete',
    'Manopla',
    'Luva',
    'Punho',
    'Guarda-Bracos',
    'Algema',
  ];

  /// Verifica se e equipamento
  bool get ehEquipamento =>
      tipoItem == TipoItem.equipCabeca ||
      tipoItem == TipoItem.equipPeito ||
      tipoItem == TipoItem.equipBracos;

  /// Verifica se e consumivel
  bool get ehConsumivel => !ehEquipamento;

  /// Icone do item
  String get icone {
    switch (tipoItem) {
      case TipoItem.equipCabeca:
        return '🪖';
      case TipoItem.equipPeito:
        return '🛡️';
      case TipoItem.equipBracos:
        return '🧤';
      case TipoItem.pocaoVida:
        return '❤️';
      case TipoItem.pocaoEnergia:
        return '⚡';
      case TipoItem.boostAtaque:
        return '⚔️';
      case TipoItem.boostDefesa:
        return '🛡️';
    }
  }

  factory ItemLoja.fromJson(Map<String, dynamic> json) {
    return ItemLoja(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      tipoItem: TipoItem.values.firstWhere(
        (t) => t.name == json['tipoItem'],
        orElse: () => TipoItem.pocaoVida,
      ),
      slot: json['slot'] != null
          ? SlotEquipamento.values.firstWhere(
              (s) => s.name == json['slot'],
              orElse: () => SlotEquipamento.cabeca,
            )
          : null,
      tipoElemental: json['tipoElemental'] != null
          ? Tipo.values.firstWhere(
              (t) => t.name == json['tipoElemental'],
              orElse: () => Tipo.normal,
            )
          : null,
      tier: json['tier'] ?? 1,
      bonusStats: Map<String, int>.from(json['bonusStats'] ?? {}),
      preco: json['preco'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'tipoItem': tipoItem.name,
      'slot': slot?.name,
      'tipoElemental': tipoElemental?.name,
      'tier': tier,
      'bonusStats': bonusStats,
      'preco': preco,
    };
  }
}

/// Tipo do item
enum TipoItem {
  equipCabeca,
  equipPeito,
  equipBracos,
  pocaoVida,
  pocaoEnergia,
  boostAtaque,
  boostDefesa;

  String get displayName {
    switch (this) {
      case TipoItem.equipCabeca:
        return 'Cabeca';
      case TipoItem.equipPeito:
        return 'Peito';
      case TipoItem.equipBracos:
        return 'Bracos';
      case TipoItem.pocaoVida:
        return 'Pocao HP';
      case TipoItem.pocaoEnergia:
        return 'Pocao EN';
      case TipoItem.boostAtaque:
        return 'Boost ATK';
      case TipoItem.boostDefesa:
        return 'Boost DEF';
    }
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
