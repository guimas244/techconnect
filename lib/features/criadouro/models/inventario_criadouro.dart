import 'item_criadouro.dart';

/// Inventário do jogador no Criadouro (itens comprados)
class InventarioCriadouro {
  /// Mapa de item ID -> quantidade
  final Map<String, int> itens;

  const InventarioCriadouro({
    this.itens = const {},
  });

  factory InventarioCriadouro.fromJson(Map<String, dynamic> json) {
    return InventarioCriadouro(
      itens: Map<String, int>.from(json['itens'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itens': itens,
    };
  }

  InventarioCriadouro copyWith({
    Map<String, int>? itens,
  }) {
    return InventarioCriadouro(
      itens: itens ?? this.itens,
    );
  }

  /// Quantidade de um item específico
  int quantidadeDeItem(String itemId) => itens[itemId] ?? 0;

  /// Verifica se tem pelo menos 1 unidade do item
  bool temItem(String itemId) => quantidadeDeItem(itemId) > 0;

  /// Adiciona itens ao inventário
  InventarioCriadouro adicionarItem(String itemId, [int quantidade = 1]) {
    final novosItens = Map<String, int>.from(itens);
    novosItens[itemId] = (novosItens[itemId] ?? 0) + quantidade;
    return copyWith(itens: novosItens);
  }

  /// Remove itens do inventário
  InventarioCriadouro removerItem(String itemId, [int quantidade = 1]) {
    final novosItens = Map<String, int>.from(itens);
    final atual = novosItens[itemId] ?? 0;
    if (atual <= quantidade) {
      novosItens.remove(itemId);
    } else {
      novosItens[itemId] = atual - quantidade;
    }
    return copyWith(itens: novosItens);
  }

  /// Lista todos os itens com suas quantidades
  List<({ItemCriadouro item, int quantidade})> get todosItens {
    final lista = <({ItemCriadouro item, int quantidade})>[];
    for (final entry in itens.entries) {
      final item = ItensCriadouro.porId(entry.key);
      if (item != null && entry.value > 0) {
        lista.add((item: item, quantidade: entry.value));
      }
    }
    return lista;
  }

  /// Total de itens no inventário
  int get totalItens => itens.values.fold(0, (sum, qty) => sum + qty);
}
