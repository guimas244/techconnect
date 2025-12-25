import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/equipe_explorador.dart';
import '../models/monstro_explorador.dart';
import '../services/equipamento_service.dart';
import 'equipe_explorador_provider.dart';

/// Provider do servico de equipamentos
final equipamentoServiceProvider = Provider<EquipamentoService>((ref) {
  return EquipamentoService();
});

/// Provider do inventario de equipamentos do jogador
final inventarioEquipamentosProvider =
    StateNotifierProvider<InventarioEquipamentosNotifier, List<EquipamentoExplorador>>((ref) {
  final service = ref.watch(equipamentoServiceProvider);
  final email = ref.watch(currentUserEmailProvider);
  return InventarioEquipamentosNotifier(service, email);
});

/// Provider para equipamentos da loja (por tipo) - DEPRECATED
final lojaEquipamentosProvider = FutureProvider.family<List<EquipamentoExplorador>, Tipo>((ref, tipo) async {
  final service = ref.watch(equipamentoServiceProvider);
  // Gera 6 equipamentos para o tipo (2 de cada slot)
  return service.gerarEquipamentosLoja(tipo: tipo, quantidade: 6);
});

/// Provider para itens da loja PERSISTIDOS
/// Carrega ou gera itens seguindo regras:
/// - Item 1: 50% tipo do 1o monstro ativo, 50% do 2o
/// - Item 2: 1/3 chance para cada monstro do banco
/// - Itens 3-6: Tipos aleatorios
final lojaEquipamentosPersistidosProvider =
    StateNotifierProvider<LojaEquipamentosNotifier, List<EquipamentoExplorador>>((ref) {
  final service = ref.watch(equipamentoServiceProvider);
  final email = ref.watch(currentUserEmailProvider);
  final equipe = ref.watch(equipeExploradorProvider);
  return LojaEquipamentosNotifier(service, email, equipe);
});

/// Notifier para itens da loja persistidos
class LojaEquipamentosNotifier extends StateNotifier<List<EquipamentoExplorador>> {
  final EquipamentoService _service;
  final String? _email;
  final EquipeExplorador? _equipe;

  LojaEquipamentosNotifier(this._service, this._email, this._equipe) : super([]) {
    _loadLoja();
  }

  /// Carrega itens da loja do storage ou gera novos
  Future<void> _loadLoja() async {
    final email = _email;
    if (email == null || email.isEmpty) {
      state = [];
      return;
    }

    try {
      await _service.init();
      var itens = await _service.carregarItensLoja(email);

      // Se nao ha itens, gera novos
      if (itens.isEmpty) {
        itens = await _gerarNovosItens();
      }

      state = itens;
    } catch (e) {
      state = [];
    }
  }

  /// Gera novos itens seguindo as regras
  Future<List<EquipamentoExplorador>> _gerarNovosItens() async {
    final email = _email;
    if (email == null || email.isEmpty) return [];

    // Tipos dos monstros ativos e banco
    final tiposAtivos = _equipe?.monstrosAtivos.map((m) => m.tipo).toList() ?? [];
    final tiposBanco = _equipe?.monstrosBanco.map((m) => m.tipo).toList() ?? [];
    final tierMax = _equipe?.tierAtual ?? 1;

    final itens = _service.gerarItensLojaComRegras(
      tiposAtivos: tiposAtivos,
      tiposBanco: tiposBanco,
      tierMaximo: tierMax,
    );

    // Salva os itens gerados
    await _service.salvarItensLoja(email, itens);
    return itens;
  }

  /// Remove item da loja (apos compra)
  Future<bool> removerItem(String equipamentoId) async {
    final email = _email;
    if (email == null || email.isEmpty) return false;

    state = state.where((e) => e.id != equipamentoId).toList();
    return await _service.salvarItensLoja(email, state);
  }

  /// Atualiza loja (gera novos itens) - usado no refresh
  Future<bool> atualizarLoja() async {
    final email = _email;
    if (email == null || email.isEmpty) return false;

    final novosItens = await _gerarNovosItens();
    state = novosItens;
    return true;
  }

  /// Conta itens por tipo
  int contarPorTipo(Tipo tipo) {
    return state.where((e) => e.tipoRequerido == tipo).length;
  }

  /// Filtra itens por tipo
  List<EquipamentoExplorador> filtrarPorTipo(Tipo? tipo) {
    if (tipo == null) return state;
    return state.where((e) => e.tipoRequerido == tipo).toList();
  }

  /// Recarrega loja
  Future<void> reload() async {
    await _loadLoja();
  }
}

/// Provider para calcular custo de reparo de um equipamento
final custoReparoProvider = Provider.family<int, EquipamentoExplorador>((ref, equipamento) {
  final service = ref.watch(equipamentoServiceProvider);
  return service.calcularCustoReparo(equipamento);
});

/// Notifier do inventario de equipamentos
class InventarioEquipamentosNotifier extends StateNotifier<List<EquipamentoExplorador>> {
  final EquipamentoService _service;
  final String? _email;

  InventarioEquipamentosNotifier(this._service, this._email) : super([]) {
    _loadInventario();
  }

  /// Carrega inventario do storage
  Future<void> _loadInventario() async {
    final email = _email;
    if (email == null || email.isEmpty) {
      state = [];
      return;
    }

    try {
      await _service.init();
      final inventario = await _service.carregarInventario(email);
      state = inventario;
    } catch (e) {
      state = [];
    }
  }

  /// Salva inventario
  Future<bool> _salvar() async {
    final email = _email;
    if (email == null || email.isEmpty) return false;

    try {
      return await _service.salvarInventario(email, state);
    } catch (e) {
      return false;
    }
  }

  /// Adiciona equipamento ao inventario (apos compra)
  Future<bool> adicionarEquipamento(EquipamentoExplorador equipamento) async {
    state = [...state, equipamento];
    return await _salvar();
  }

  /// Remove equipamento do inventario (ao equipar)
  Future<bool> removerEquipamento(String equipamentoId) async {
    state = state.where((e) => e.id != equipamentoId).toList();
    return await _salvar();
  }

  /// Obtem equipamento por ID
  EquipamentoExplorador? getEquipamento(String equipamentoId) {
    return state.where((e) => e.id == equipamentoId).firstOrNull;
  }

  /// Lista equipamentos compativeis com um monstro
  List<EquipamentoExplorador> equipamentosCompativeis(MonstroExplorador monstro) {
    return state.where((e) =>
      e.tipoRequerido == monstro.tipo || e.tipoRequerido == monstro.tipoExtra
    ).toList();
  }

  /// Lista equipamentos por slot
  List<EquipamentoExplorador> equipamentosPorSlot(SlotEquipamento slot) {
    return state.where((e) => e.slot == slot).toList();
  }

  /// Lista equipamentos compativeis por slot
  List<EquipamentoExplorador> equipamentosCompativeisPorSlot(
    MonstroExplorador monstro,
    SlotEquipamento slot,
  ) {
    return state.where((e) =>
      e.slot == slot &&
      (e.tipoRequerido == monstro.tipo || e.tipoRequerido == monstro.tipoExtra)
    ).toList();
  }

  /// Recarrega inventario
  Future<void> reload() async {
    await _loadInventario();
  }
}
