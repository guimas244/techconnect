import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/providers/kills_permanentes_provider.dart';
import '../models/item_loja.dart';
import 'equipe_explorador_provider.dart';

/// Provider para os itens disponiveis na loja
final itensLojaProvider = StateNotifierProvider<ItensLojaNotifier, List<ItemLoja>>((ref) {
  return ItensLojaNotifier(ref);
});

/// Provider para verificar se pode comprar item
final podeComprarItemProvider = Provider.family<bool, ItemLoja>((ref, item) {
  final kills = ref.watch(killsPermanentesProvider);
  if (kills == null || item.tipoElemental == null) return false;
  return kills.temKillsSuficientes(item.tipoElemental!, item.preco);
});

/// Provider para inventario do jogador (itens comprados)
final inventarioExploradorProvider =
    StateNotifierProvider<InventarioNotifier, List<ItemLoja>>((ref) {
  return InventarioNotifier();
});

/// Provider para custo de refresh da loja (aumenta a cada refresh)
final custoRefreshLojaProvider = StateProvider<int>((ref) => 5);

/// Notifier dos itens da loja
class ItensLojaNotifier extends StateNotifier<List<ItemLoja>> {
  final Ref _ref;

  ItensLojaNotifier(this._ref) : super([]) {
    _gerarItens();
  }

  /// Gera itens aleatorios para a loja
  void _gerarItens() {
    final equipe = _ref.read(equipeExploradorProvider);
    final kills = _ref.read(killsPermanentesProvider);

    final tierAtual = equipe?.tierAtual ?? 1;

    // Converte kills para Map<Tipo, int>
    final killsPorTipo = <Tipo, int>{};
    if (kills != null) {
      for (final tipo in Tipo.values) {
        killsPorTipo[tipo] = kills.getKills(tipo);
      }
    }

    state = ItemLoja.gerarItensLoja(
      tierAtual: tierAtual,
      killsPorTipo: killsPorTipo,
      quantidade: 6,
    );
  }

  /// Atualiza loja com novos itens (paga kills)
  Future<bool> refreshLoja(Tipo tipoKill, int custo) async {
    final killsNotifier = _ref.read(killsPermanentesProvider.notifier);

    final sucesso = await killsNotifier.gastarKills(tipoKill, custo);
    if (sucesso) {
      _gerarItens();
      return true;
    }
    return false;
  }

  /// Remove item comprado da loja
  void removerItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }
}

/// Notifier do inventario do jogador
class InventarioNotifier extends StateNotifier<List<ItemLoja>> {
  InventarioNotifier() : super([]);

  /// Adiciona item ao inventario
  void adicionarItem(ItemLoja item) {
    state = [...state, item];
  }

  /// Remove item do inventario
  void removerItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Usa consumivel e remove do inventario
  bool usarConsumivel(String itemId) {
    final item = state.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item nao encontrado'),
    );

    if (!item.ehConsumivel) return false;

    removerItem(itemId);
    return true;
  }

  /// Limpa inventario
  void limpar() {
    state = [];
  }

  /// Filtra equipamentos por slot
  List<ItemLoja> equipamentosPorSlot(SlotEquipamento slot) {
    return state.where((item) => item.slot == slot).toList();
  }

  /// Filtra consumiveis
  List<ItemLoja> get consumiveis {
    return state.where((item) => item.ehConsumivel).toList();
  }
}
