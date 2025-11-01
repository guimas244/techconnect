import 'item_consumivel.dart';

class Mochila {
  final List<ItemConsumivel?> itens; // 30 slots (6x5)
  final int slotsDesbloqueados; // Quantidade de slots desbloqueados

  static const int totalSlots = 30;
  static const int slotsIniciaisDesbloqueados = 3;
  static const int slotMoedaEvento = 3; // Posição 4 (índice 3) é reservada para moeda de evento/Halloween
  static const int slotOvoEvento = 4; // Posição 5 (índice 4) é reservada para ovo de evento
  static const int slotMoedaChave = 5; // Posição 6 (índice 5) é reservada para moeda chave

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

  // Obtém quantidade de moeda de evento
  int get quantidadeMoedaEvento {
    final moeda = itens[slotMoedaEvento];
    if (moeda != null && moeda.tipo == TipoItemConsumivel.moedaEvento) {
      return moeda.quantidade;
    }
    return 0;
  }

  // Adiciona moedas de evento
  Mochila adicionarMoedaEvento(int quantidade) {
    final novosItens = List<ItemConsumivel?>.from(itens);
    final moedaAtual = novosItens[slotMoedaEvento];

    if (moedaAtual != null && moedaAtual.tipo == TipoItemConsumivel.moedaEvento) {
      // Atualiza quantidade existente
      novosItens[slotMoedaEvento] = moedaAtual.copyWith(
        quantidade: moedaAtual.quantidade + quantidade,
      );
    } else {
      // Cria nova moeda de evento
      novosItens[slotMoedaEvento] = ItemConsumivel(
        id: 'moeda_evento',
        nome: 'Moeda de Evento',
        descricao: 'Moeda especial de evento',
        tipo: TipoItemConsumivel.moedaEvento,
        iconPath: 'assets/eventos/halloween/moeda_halloween.png',
        quantidade: quantidade,
        raridade: RaridadeConsumivel.lendario,
      );
    }

    return copyWith(itens: novosItens);
  }

  // Remove moedas de evento (retorna null se não tiver moedas suficientes)
  Mochila? removerMoedaEvento(int quantidade) {
    final moedaAtual = itens[slotMoedaEvento];

    if (moedaAtual == null || moedaAtual.tipo != TipoItemConsumivel.moedaEvento) {
      return null; // Não tem moeda
    }

    if (moedaAtual.quantidade < quantidade) {
      return null; // Não tem moedas suficientes
    }

    final novosItens = List<ItemConsumivel?>.from(itens);
    final novaQuantidade = moedaAtual.quantidade - quantidade;

    // Mantém a moeda mesmo com 0 quantidade
    novosItens[slotMoedaEvento] = moedaAtual.copyWith(quantidade: novaQuantidade);

    return copyWith(itens: novosItens);
  }

  // Inicializa moeda de evento com 0 se não existir
  Mochila inicializarMoedaEvento() {
    if (itens[slotMoedaEvento] == null) {
      return adicionarMoedaEvento(0);
    }
    return this;
  }

  // Obtém quantidade de ovo de evento
  int get quantidadeOvoEvento {
    final ovo = itens[slotOvoEvento];
    if (ovo != null && ovo.tipo == TipoItemConsumivel.ovoEvento) {
      return ovo.quantidade;
    }
    return 0;
  }

  // Adiciona ovos de evento
  Mochila adicionarOvoEvento(int quantidade) {
    final novosItens = List<ItemConsumivel?>.from(itens);
    final ovoAtual = novosItens[slotOvoEvento];

    if (ovoAtual != null && ovoAtual.tipo == TipoItemConsumivel.ovoEvento) {
      // Atualiza quantidade existente
      novosItens[slotOvoEvento] = ovoAtual.copyWith(
        quantidade: ovoAtual.quantidade + quantidade,
      );
    } else {
      // Cria novo ovo de evento
      novosItens[slotOvoEvento] = ItemConsumivel(
        id: 'ovo_evento',
        nome: 'Ovo do Evento',
        descricao: 'Ovo especial de evento que pode ser usado para surpresas!',
        tipo: TipoItemConsumivel.ovoEvento,
        iconPath: 'assets/eventos/halloween/ovo_halloween.png',
        quantidade: quantidade,
        raridade: RaridadeConsumivel.lendario,
      );
    }

    return copyWith(itens: novosItens);
  }

  // Remove ovos de evento (retorna null se não tiver ovos suficientes)
  Mochila? removerOvoEvento(int quantidade) {
    final ovoAtual = itens[slotOvoEvento];

    if (ovoAtual == null || ovoAtual.tipo != TipoItemConsumivel.ovoEvento) {
      return null; // Não tem ovo
    }

    if (ovoAtual.quantidade < quantidade) {
      return null; // Não tem ovos suficientes
    }

    final novosItens = List<ItemConsumivel?>.from(itens);
    final novaQuantidade = ovoAtual.quantidade - quantidade;

    // Mantém o ovo mesmo com 0 quantidade
    novosItens[slotOvoEvento] = ovoAtual.copyWith(quantidade: novaQuantidade);

    return copyWith(itens: novosItens);
  }

  // Inicializa ovo de evento com 0 se não existir
  Mochila inicializarOvoEvento() {
    if (itens[slotOvoEvento] == null) {
      return adicionarOvoEvento(0);
    }
    return this;
  }

  // Obtém quantidade de moeda chave
  int get quantidadeMoedaChave {
    final moeda = itens[slotMoedaChave];
    if (moeda != null && moeda.tipo == TipoItemConsumivel.moedaChave) {
      return moeda.quantidade;
    }
    return 0;
  }

  // Adiciona moedas chave
  Mochila adicionarMoedaChave(int quantidade) {
    final novosItens = List<ItemConsumivel?>.from(itens);
    final moedaAtual = novosItens[slotMoedaChave];

    if (moedaAtual != null && moedaAtual.tipo == TipoItemConsumivel.moedaChave) {
      // Atualiza quantidade existente
      novosItens[slotMoedaChave] = moedaAtual.copyWith(
        quantidade: moedaAtual.quantidade + quantidade,
      );
    } else {
      // Cria nova moeda chave
      novosItens[slotMoedaChave] = ItemConsumivel(
        id: 'moeda_chave',
        nome: 'Moeda Chave',
        descricao: 'Moeda especial em formato de chave',
        tipo: TipoItemConsumivel.moedaChave,
        iconPath: 'assets/eventos/halloween/moeda_chave.png',
        quantidade: quantidade,
        raridade: RaridadeConsumivel.lendario,
      );
    }

    return copyWith(itens: novosItens);
  }

  // Remove moedas chave (retorna null se não tiver moedas suficientes)
  Mochila? removerMoedaChave(int quantidade) {
    final moedaAtual = itens[slotMoedaChave];

    if (moedaAtual == null || moedaAtual.tipo != TipoItemConsumivel.moedaChave) {
      return null; // Não tem moeda
    }

    if (moedaAtual.quantidade < quantidade) {
      return null; // Não tem moedas suficientes
    }

    final novosItens = List<ItemConsumivel?>.from(itens);
    final novaQuantidade = moedaAtual.quantidade - quantidade;

    // Mantém a moeda mesmo com 0 quantidade
    novosItens[slotMoedaChave] = moedaAtual.copyWith(quantidade: novaQuantidade);

    return copyWith(itens: novosItens);
  }

  // Inicializa moeda chave com 0 se não existir
  Mochila inicializarMoedaChave() {
    if (itens[slotMoedaChave] == null) {
      return adicionarMoedaChave(0);
    }
    return this;
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