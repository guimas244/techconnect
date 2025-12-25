import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/monstro_explorador.dart';

/// Service para gerenciar equipamentos do Modo Explorador
///
/// Responsabilidades:
/// - Gerar equipamentos aleatorios para loja
/// - Persistir inventario de equipamentos do jogador
/// - Calcular precos e custos de reparo
class EquipamentoService {
  static const String _boxName = 'equipamentos_explorador_box';
  static EquipamentoService? _instance;
  Box<String>? _box;
  final Random _random = Random();

  EquipamentoService._();

  factory EquipamentoService() {
    _instance ??= EquipamentoService._();
    return _instance!;
  }

  /// Inicializa o Hive box
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    try {
      _box = await Hive.openBox<String>(_boxName);
      print('[EquipamentoService] Box inicializada');
    } catch (e) {
      print('[EquipamentoService] Erro ao inicializar box: $e');
      rethrow;
    }
  }

  /// Garante que o box esta aberto
  Future<Box<String>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Chave para armazenar inventario do usuario
  String _getInventarioKey(String email) => 'inventario_$email';

  /// Chave para armazenar itens da loja
  String _getLojaKey(String email) => 'loja_$email';

  // ==================== PERSISTENCIA ====================

  /// Carrega inventario de equipamentos do usuario
  Future<List<EquipamentoExplorador>> carregarInventario(String email) async {
    try {
      final box = await _getBox();
      final json = box.get(_getInventarioKey(email));

      if (json == null || json.isEmpty) {
        print('[EquipamentoService] Inventario vazio para $email');
        return [];
      }

      final data = jsonDecode(json) as List<dynamic>;
      final equipamentos = data
          .map((e) => EquipamentoExplorador.fromJson(e as Map<String, dynamic>))
          .toList();
      print('[EquipamentoService] ${equipamentos.length} equipamentos carregados');
      return equipamentos;
    } catch (e) {
      print('[EquipamentoService] Erro ao carregar inventario: $e');
      return [];
    }
  }

  /// Salva inventario de equipamentos
  Future<bool> salvarInventario(String email, List<EquipamentoExplorador> equipamentos) async {
    try {
      final box = await _getBox();
      final json = jsonEncode(equipamentos.map((e) => e.toJson()).toList());
      await box.put(_getInventarioKey(email), json);
      print('[EquipamentoService] ${equipamentos.length} equipamentos salvos');
      return true;
    } catch (e) {
      print('[EquipamentoService] Erro ao salvar inventario: $e');
      return false;
    }
  }

  /// Adiciona equipamento ao inventario
  Future<bool> adicionarAoInventario(String email, EquipamentoExplorador equipamento) async {
    try {
      final inventario = await carregarInventario(email);
      inventario.add(equipamento);
      return await salvarInventario(email, inventario);
    } catch (e) {
      print('[EquipamentoService] Erro ao adicionar equipamento: $e');
      return false;
    }
  }

  /// Remove equipamento do inventario pelo ID
  Future<bool> removerDoInventario(String email, String equipamentoId) async {
    try {
      final inventario = await carregarInventario(email);
      inventario.removeWhere((e) => e.id == equipamentoId);
      return await salvarInventario(email, inventario);
    } catch (e) {
      print('[EquipamentoService] Erro ao remover equipamento: $e');
      return false;
    }
  }

  // ==================== PERSISTENCIA LOJA ====================

  /// Carrega itens da loja do usuario (persistidos)
  Future<List<EquipamentoExplorador>> carregarItensLoja(String email) async {
    try {
      final box = await _getBox();
      final json = box.get(_getLojaKey(email));

      if (json == null || json.isEmpty) {
        print('[EquipamentoService] Loja vazia para $email');
        return [];
      }

      final data = jsonDecode(json) as List<dynamic>;
      final equipamentos = data
          .map((e) => EquipamentoExplorador.fromJson(e as Map<String, dynamic>))
          .toList();
      print('[EquipamentoService] ${equipamentos.length} itens da loja carregados');
      return equipamentos;
    } catch (e) {
      print('[EquipamentoService] Erro ao carregar loja: $e');
      return [];
    }
  }

  /// Salva itens da loja
  Future<bool> salvarItensLoja(String email, List<EquipamentoExplorador> equipamentos) async {
    try {
      final box = await _getBox();
      final json = jsonEncode(equipamentos.map((e) => e.toJson()).toList());
      await box.put(_getLojaKey(email), json);
      print('[EquipamentoService] ${equipamentos.length} itens da loja salvos');
      return true;
    } catch (e) {
      print('[EquipamentoService] Erro ao salvar loja: $e');
      return false;
    }
  }

  /// Remove item da loja (apos compra)
  Future<bool> removerItemLoja(String email, String equipamentoId) async {
    try {
      final itensLoja = await carregarItensLoja(email);
      itensLoja.removeWhere((e) => e.id == equipamentoId);
      return await salvarItensLoja(email, itensLoja);
    } catch (e) {
      print('[EquipamentoService] Erro ao remover item da loja: $e');
      return false;
    }
  }

  /// Gera itens da loja com regras especificas:
  /// - Item 1: 50% tipo do 1o monstro ativo, 50% do 2o
  /// - Item 2: 1/3 chance para cada monstro do banco
  /// - Itens 3-6: Tipos aleatorios (podem repetir)
  List<EquipamentoExplorador> gerarItensLojaComRegras({
    required List<Tipo> tiposAtivos,
    required List<Tipo> tiposBanco,
    int tierMaximo = 11,
  }) {
    final equipamentos = <EquipamentoExplorador>[];
    final slots = SlotEquipamento.values;
    final todosOsTipos = Tipo.values;

    // Item 1: 50% do primeiro monstro ativo, 50% do segundo
    Tipo tipoItem1;
    if (tiposAtivos.isEmpty) {
      tipoItem1 = todosOsTipos[_random.nextInt(todosOsTipos.length)];
    } else if (tiposAtivos.length == 1) {
      tipoItem1 = tiposAtivos.first;
    } else {
      tipoItem1 = _random.nextBool() ? tiposAtivos[0] : tiposAtivos[1];
    }
    equipamentos.add(gerarEquipamento(
      slot: slots[0],
      tipo: tipoItem1,
      tier: _random.nextInt(tierMaximo) + 1,
    ));

    // Item 2: 1/3 chance para cada monstro do banco
    Tipo tipoItem2;
    if (tiposBanco.isEmpty) {
      tipoItem2 = todosOsTipos[_random.nextInt(todosOsTipos.length)];
    } else {
      tipoItem2 = tiposBanco[_random.nextInt(tiposBanco.length)];
    }
    equipamentos.add(gerarEquipamento(
      slot: slots[1],
      tipo: tipoItem2,
      tier: _random.nextInt(tierMaximo) + 1,
    ));

    // Itens 3-6: Tipos totalmente aleatorios
    for (int i = 2; i < 6; i++) {
      final tipoAleatorio = todosOsTipos[_random.nextInt(todosOsTipos.length)];
      equipamentos.add(gerarEquipamento(
        slot: slots[i % slots.length],
        tipo: tipoAleatorio,
        tier: _random.nextInt(tierMaximo) + 1,
      ));
    }

    // Ordena por tier
    equipamentos.sort((a, b) => a.tier.compareTo(b.tier));
    return equipamentos;
  }

  // ==================== GERACAO DE EQUIPAMENTOS ====================

  /// Gera um ID unico para equipamento
  String _gerarId() {
    return 'equip_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
  }

  /// Gera nome do equipamento baseado no slot, tipo e tier
  String _gerarNome(SlotEquipamento slot, Tipo tipo, int tier, RaridadeEquipamento raridade) {
    final prefixos = {
      RaridadeEquipamento.inferior: ['Velho', 'Gasto', 'Simples'],
      RaridadeEquipamento.normal: ['Comum', 'Basico', 'Padrao'],
      RaridadeEquipamento.raro: ['Fino', 'Aprimorado', 'Superior'],
      RaridadeEquipamento.epico: ['Magnifico', 'Excelente', 'Glorioso'],
      RaridadeEquipamento.lendario: ['Lendario', 'Mitico', 'Ancestral'],
      RaridadeEquipamento.impossivel: ['Impossivel', 'Divino', 'Supremo'],
    };

    final nomeSlot = {
      SlotEquipamento.cabeca: ['Elmo', 'Capacete', 'Coroa', 'Tiara'],
      SlotEquipamento.peito: ['Armadura', 'Peitoral', 'Colete', 'Manto'],
      SlotEquipamento.bracos: ['Bracadeiras', 'Luvas', 'Manoplas', 'Braceletes'],
    };

    final prefixo = prefixos[raridade]![_random.nextInt(prefixos[raridade]!.length)];
    final base = nomeSlot[slot]![_random.nextInt(nomeSlot[slot]!.length)];
    final sufixo = 'de ${tipo.displayName}';

    return '$prefixo $base $sufixo';
  }

  /// Calcula stats base para um tier (1-11)
  /// Tier 1 = basico, Tier 11 = maximo
  int _statBasePorTier(int tier) {
    // Progressao exponencial suave
    return (tier * tier * 0.5 + tier * 2).round();
  }

  /// Calcula multiplicador de stats por raridade
  double _multiplicadorRaridade(RaridadeEquipamento raridade) {
    switch (raridade) {
      case RaridadeEquipamento.inferior:
        return 0.7;
      case RaridadeEquipamento.normal:
        return 1.0;
      case RaridadeEquipamento.raro:
        return 1.4;
      case RaridadeEquipamento.epico:
        return 1.8;
      case RaridadeEquipamento.lendario:
        return 2.3;
      case RaridadeEquipamento.impossivel:
        return 3.0;
    }
  }

  /// Gera stats aleatorios para equipamento
  /// Cada slot tem foco diferente:
  /// - Cabeca: mais vida e defesa
  /// - Peito: equilibrado, mais energia
  /// - Bracos: mais ataque e agilidade
  Map<String, int> _gerarStats(SlotEquipamento slot, int tier, RaridadeEquipamento raridade) {
    final base = _statBasePorTier(tier);
    final mult = _multiplicadorRaridade(raridade);

    // Variacao aleatoria de 20%
    int statComVariacao(int valorBase) {
      final variacao = (valorBase * 0.2).round();
      return ((valorBase + _random.nextInt(variacao + 1) - variacao ~/ 2) * mult).round();
    }

    switch (slot) {
      case SlotEquipamento.cabeca:
        return {
          'vida': statComVariacao((base * 2.0).round()),
          'energia': statComVariacao((base * 0.5).round()),
          'ataque': statComVariacao((base * 0.3).round()),
          'defesa': statComVariacao((base * 1.5).round()),
          'agilidade': statComVariacao((base * 0.3).round()),
        };
      case SlotEquipamento.peito:
        return {
          'vida': statComVariacao((base * 1.5).round()),
          'energia': statComVariacao((base * 1.5).round()),
          'ataque': statComVariacao((base * 0.5).round()),
          'defesa': statComVariacao((base * 1.0).round()),
          'agilidade': statComVariacao((base * 0.3).round()),
        };
      case SlotEquipamento.bracos:
        return {
          'vida': statComVariacao((base * 0.5).round()),
          'energia': statComVariacao((base * 0.5).round()),
          'ataque': statComVariacao((base * 2.0).round()),
          'defesa': statComVariacao((base * 0.3).round()),
          'agilidade': statComVariacao((base * 1.2).round()),
        };
    }
  }

  /// Calcula preco do equipamento baseado no tier e raridade
  int _calcularPreco(int tier, RaridadeEquipamento raridade) {
    final basePreco = tier * 5;
    final multRaridade = raridade.nivel * 1.5;
    return (basePreco * multRaridade).round();
  }

  /// Gera um equipamento aleatorio
  EquipamentoExplorador gerarEquipamento({
    required SlotEquipamento slot,
    required Tipo tipo,
    int? tier,
    RaridadeEquipamento? raridade,
  }) {
    // Se nao especificado, gera tier e raridade aleatorios
    final tierFinal = tier ?? (_random.nextInt(11) + 1);
    final raridadeFinal = raridade ?? _sortearRaridade();

    final stats = _gerarStats(slot, tierFinal, raridadeFinal);
    final nome = _gerarNome(slot, tipo, tierFinal, raridadeFinal);
    final preco = _calcularPreco(tierFinal, raridadeFinal);

    return EquipamentoExplorador(
      id: _gerarId(),
      nome: nome,
      slot: slot,
      tipoRequerido: tipo,
      raridade: raridadeFinal,
      tier: tierFinal,
      vida: stats['vida']!,
      energia: stats['energia']!,
      ataque: stats['ataque']!,
      defesa: stats['defesa']!,
      agilidade: stats['agilidade']!,
      preco: preco,
    );
  }

  /// Sorteia raridade com pesos
  RaridadeEquipamento _sortearRaridade() {
    final valor = _random.nextInt(100);
    if (valor < 35) return RaridadeEquipamento.inferior;   // 35%
    if (valor < 65) return RaridadeEquipamento.normal;      // 30%
    if (valor < 85) return RaridadeEquipamento.raro;        // 20%
    if (valor < 95) return RaridadeEquipamento.epico;       // 10%
    if (valor < 99) return RaridadeEquipamento.lendario;    // 4%
    return RaridadeEquipamento.impossivel;                   // 1%
  }

  /// Gera lista de equipamentos para loja de um tipo especifico
  List<EquipamentoExplorador> gerarEquipamentosLoja({
    required Tipo tipo,
    int quantidade = 6,
    int? tierMinimo,
    int? tierMaximo,
  }) {
    final equipamentos = <EquipamentoExplorador>[];
    final slots = SlotEquipamento.values;

    for (int i = 0; i < quantidade; i++) {
      final slot = slots[i % slots.length];
      int tier;

      if (tierMinimo != null && tierMaximo != null) {
        tier = tierMinimo + _random.nextInt(tierMaximo - tierMinimo + 1);
      } else {
        tier = _random.nextInt(11) + 1;
      }

      equipamentos.add(gerarEquipamento(
        slot: slot,
        tipo: tipo,
        tier: tier,
      ));
    }

    // Ordena por tier
    equipamentos.sort((a, b) => a.tier.compareTo(b.tier));
    return equipamentos;
  }

  // ==================== REPARO ====================

  /// Calcula custo de reparo de um equipamento
  /// Custo = (1 - durabilidade%) * preco * 0.3
  int calcularCustoReparo(EquipamentoExplorador equipamento) {
    if (!equipamento.estaQuebrado &&
        equipamento.durabilidadeAtual == equipamento.durabilidadeMax) {
      return 0;
    }

    final percentualDano = 1 - equipamento.porcentagemDurabilidade;
    return (percentualDano * equipamento.preco * 0.3).ceil();
  }

  /// Calcula custo total de reparo para lista de equipamentos
  int calcularCustoReparoTotal(List<EquipamentoExplorador> equipamentos) {
    return equipamentos.fold(0, (total, e) => total + calcularCustoReparo(e));
  }
}
