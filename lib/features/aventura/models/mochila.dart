import 'item_consumivel.dart';

class Mochila {
  final List<ItemConsumivel?> itens; // 30 slots (6x5)
  final int slotsDesbloqueados; // Quantidade de slots desbloqueados

  static const int totalSlots = 30;
  static const int slotsIniciaisDesbloqueados = 3;
  // SLOTS DE EVENTO - LINHA 5 (ÚLTIMA LINHA) - Índices 24-29
  static const int slotOvoEvento = 24; // 1º slot da linha 5 (índice 24) - Ovo de Halloween
  static const int slotMoedaChave = 27; // 4º slot da linha 5 (índice 27) - Moeda Chave
  // Slots antigos mantidos para compatibilidade de migração
  static const int slotMoedaEventoAntigo = 3; // Slot antigo da moeda de Halloween (será convertido em ovo)
  static const int slotOvoEventoAntigo = 4; // Slot antigo do ovo de Halloween

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

  /// Migra itens de evento dos slots antigos (3, 4, 5) para os novos slots (24, 27)
  /// Converte moedas de Halloween em ovos (somando as quantidades)
  Mochila migrarItensEventoParaLinha5() {
    final novosItens = List<ItemConsumivel?>.from(itens);

    print('🔄 [Mochila] Iniciando migração de itens de evento para linha 5...');

    // 1. Pega quantidades dos slots antigos
    int quantidadeMoedasHalloween = 0;
    int quantidadeOvos = 0;
    int quantidadeMoedaChave = 0;

    // Slot 3: Moeda de Halloween antiga
    final moedaAntiga = novosItens[slotMoedaEventoAntigo];
    if (moedaAntiga != null && (moedaAntiga.tipo == TipoItemConsumivel.moedaEvento ||
        moedaAntiga.tipo == TipoItemConsumivel.moedaHalloween)) {
      quantidadeMoedasHalloween = moedaAntiga.quantidade;
      print('🪙 [Mochila] Encontradas $quantidadeMoedasHalloween moedas de Halloween no slot 3');
      novosItens[slotMoedaEventoAntigo] = null; // Limpa slot antigo
    }

    // Slot 4: Ovo antigo
    final ovoAntigo = novosItens[slotOvoEventoAntigo];
    if (ovoAntigo != null && ovoAntigo.tipo == TipoItemConsumivel.ovoEvento) {
      quantidadeOvos = ovoAntigo.quantidade;
      print('🥚 [Mochila] Encontrados $quantidadeOvos ovos no slot 4');
      novosItens[slotOvoEventoAntigo] = null; // Limpa slot antigo
    }

    // Slot 5: Moeda chave antiga (se existir)
    if (novosItens.length > 5) {
      final moedaChaveAntiga = novosItens[5];
      if (moedaChaveAntiga != null && moedaChaveAntiga.tipo == TipoItemConsumivel.moedaChave) {
        quantidadeMoedaChave = moedaChaveAntiga.quantidade;
        print('🔑 [Mochila] Encontradas $quantidadeMoedaChave moedas chave no slot 5');
        novosItens[5] = null; // Limpa slot antigo
      }
    }

    // 2. Converte moedas de Halloween em ovos
    final totalOvos = quantidadeOvos + quantidadeMoedasHalloween;
    print('✨ [Mochila] Convertendo $quantidadeMoedasHalloween moedas em ovos. Total de ovos: $totalOvos');

    // 3. Coloca ovos no novo slot 24 (1º da linha 5)
    if (totalOvos > 0) {
      novosItens[slotOvoEvento] = ItemConsumivel(
        id: 'ovo_evento',
        nome: 'Ovo do Evento',
        descricao: 'Ovo especial de evento que pode ser usado para surpresas!',
        tipo: TipoItemConsumivel.ovoEvento,
        iconPath: 'assets/eventos/halloween/ovo_halloween.png',
        quantidade: totalOvos,
        raridade: RaridadeConsumivel.lendario,
      );
      print('🥚 [Mochila] Ovos colocados no slot 24 (linha 5, posição 1)');
    } else {
      // Inicializa com 0 para reservar o espaço
      novosItens[slotOvoEvento] = ItemConsumivel(
        id: 'ovo_evento',
        nome: 'Ovo do Evento',
        descricao: 'Ovo especial de evento que pode ser usado para surpresas!',
        tipo: TipoItemConsumivel.ovoEvento,
        iconPath: 'assets/eventos/halloween/ovo_halloween.png',
        quantidade: 0,
        raridade: RaridadeConsumivel.lendario,
      );
    }

    // 4. Coloca moeda chave no novo slot 27 (4º da linha 5)
    if (quantidadeMoedaChave > 0) {
      novosItens[slotMoedaChave] = ItemConsumivel(
        id: 'moeda_chave',
        nome: 'Moeda Chave',
        descricao: 'Moeda especial em formato de chave. Muito rara!',
        tipo: TipoItemConsumivel.moedaChave,
        iconPath: 'assets/eventos/halloween/moeda_chave.png',
        quantidade: quantidadeMoedaChave,
        raridade: RaridadeConsumivel.lendario,
      );
      print('🔑 [Mochila] Moeda chave colocada no slot 27 (linha 5, posição 4)');
    } else {
      // Inicializa com 0 para reservar o espaço
      novosItens[slotMoedaChave] = ItemConsumivel(
        id: 'moeda_chave',
        nome: 'Moeda Chave',
        descricao: 'Moeda especial em formato de chave. Muito rara!',
        tipo: TipoItemConsumivel.moedaChave,
        iconPath: 'assets/eventos/halloween/moeda_chave.png',
        quantidade: 0,
        raridade: RaridadeConsumivel.lendario,
      );
    }

    print('✅ [Mochila] Migração concluída! Ovos: $totalOvos (slot 24), Moeda chave: $quantidadeMoedaChave (slot 27)');

    return copyWith(itens: novosItens);
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