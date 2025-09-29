import 'item_consumivel.dart';

class Mochila {
  final List<ItemConsumivel?> itens; // 30 slots (6x5)
  final int slotsDesbloqueados; // Quantidade de slots desbloqueados

  static const int totalSlots = 30;
  static const int slotsIniciaisDesbloqueados = 3;

  Mochila({
    List<ItemConsumivel?>? itens,
    int? slotsDesbloqueados,
  })  : itens = itens ?? List.filled(totalSlots, null),
        slotsDesbloqueados = slotsDesbloqueados ?? slotsIniciaisDesbloqueados;

  // Adiciona item na primeira posição vazia desbloqueada
  Mochila adicionarItem(ItemConsumivel item) {
    final novosItens = List<ItemConsumivel?>.from(itens);

    // Procura primeira posição vazia desbloqueada
    for (int i = 0; i < slotsDesbloqueados; i++) {
      if (novosItens[i] == null) {
        novosItens[i] = item;
        return copyWith(itens: novosItens);
      }
    }

    // Se não achou espaço, retorna sem modificar
    return this;
  }

  // Remove item de uma posição
  Mochila removerItem(int index) {
    if (index < 0 || index >= totalSlots) return this;

    final novosItens = List<ItemConsumivel?>.from(itens);
    novosItens[index] = null;
    return copyWith(itens: novosItens);
  }

  // Atualiza item em uma posição
  Mochila atualizarItem(int index, ItemConsumivel item) {
    if (index < 0 || index >= totalSlots) return this;

    final novosItens = List<ItemConsumivel?>.from(itens);
    novosItens[index] = item;
    return copyWith(itens: novosItens);
  }

  // Verifica se está cheia (slots desbloqueados)
  bool get estaCheia {
    for (int i = 0; i < slotsDesbloqueados; i++) {
      if (itens[i] == null) return false;
    }
    return true;
  }

  // Conta itens ocupados (apenas nos slots desbloqueados)
  int get itensOcupados {
    int count = 0;
    for (int i = 0; i < slotsDesbloqueados; i++) {
      if (itens[i] != null) count++;
    }
    return count;
  }

  Map<String, dynamic> toJson() {
    return {
      'itens': itens.map((item) => item?.toJson()).toList(),
      'slotsDesbloqueados': slotsDesbloqueados,
    };
  }

  factory Mochila.fromJson(Map<String, dynamic> json) {
    final itensList = (json['itens'] as List<dynamic>?)
        ?.map((item) => item != null
            ? ItemConsumivel.fromJson(item as Map<String, dynamic>)
            : null)
        .toList() ?? List.filled(totalSlots, null);

    // Garante que sempre tenha 30 slots
    while (itensList.length < totalSlots) {
      itensList.add(null);
    }
    if (itensList.length > totalSlots) {
      itensList.removeRange(totalSlots, itensList.length);
    }

    return Mochila(
      itens: itensList,
      slotsDesbloqueados: json['slotsDesbloqueados'] as int? ?? slotsIniciaisDesbloqueados,
    );
  }

  Mochila copyWith({
    List<ItemConsumivel?>? itens,
    int? slotsDesbloqueados,
  }) {
    return Mochila(
      itens: itens ?? this.itens,
      slotsDesbloqueados: slotsDesbloqueados ?? this.slotsDesbloqueados,
    );
  }
}