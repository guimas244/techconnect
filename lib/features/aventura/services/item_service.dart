import 'dart:math';
import '../models/item.dart';
import '../utils/gerador_nomes_itens.dart';

class ItemService {
  final Random _random = Random();

  /// Gera um item aleatório ao derrotar um monstro
  Item gerarItemAleatorio({int tierAtual = 1}) {
    print('🏆 [ItemService] Gerando item para tier $tierAtual');

    // Determina a quantidade de atributos (2% de 5, 3% de 4, 10% de 3, 20% de 2, resto de 1)
    int quantidadeAtributos = _determinarQuantidadeAtributos();

    // Determina a raridade baseada na quantidade de atributos
    RaridadeItem raridade = _determinarRaridade(quantidadeAtributos);

    // Gera o nome do item baseado na raridade
    String nome = GeradorNomesItens.gerarNomeItem();

    // Gera os atributos do item (com multiplicação por tier)
    Map<String, int> atributos = _gerarAtributos(quantidadeAtributos, tierAtual);

    print('✅ [ItemService] Item gerado: $nome (${raridade.nome}) | Tier: $tierAtual | Total atributos: ${atributos.values.fold(0, (sum, value) => sum + value)}');

    return Item(
      id: _gerarId(),
      nome: nome,
      raridade: raridade,
      atributos: atributos,
      dataObtencao: DateTime.now(),
      tier: tierAtual,
    );
  }

  /// Gera um item aleatório para LOJA (2x mais chance de itens melhores)
  Item gerarItemAleatorioLoja({int tierAtual = 1}) {
    print('🛒 [ItemService - LOJA] Gerando item para tier $tierAtual (drop rate melhorado!)');

    // Usa probabilidades melhoradas da loja
    int quantidadeAtributos = _determinarQuantidadeAtributosLoja();

    // Determina a raridade baseada na quantidade de atributos
    RaridadeItem raridade = _determinarRaridade(quantidadeAtributos);

    // Gera o nome do item baseado na raridade
    String nome = GeradorNomesItens.gerarNomeItem();

    // Gera os atributos do item (com multiplicação por tier)
    Map<String, int> atributos = _gerarAtributos(quantidadeAtributos, tierAtual);

    print('✅ [ItemService - LOJA] Item gerado: $nome (${raridade.nome}) | Tier: $tierAtual | Total atributos: ${atributos.values.fold(0, (sum, value) => sum + value)}');

    return Item(
      id: _gerarId(),
      nome: nome,
      raridade: raridade,
      atributos: atributos,
      dataObtencao: DateTime.now(),
      tier: tierAtual,
    );
  }

  /// Gera um item aleatório respeitando restrições de dificuldade por tier
  Item gerarItemComRestricoesTier({int tierAtual = 1}) {
    print('🔒 [ItemService] Gerando item com restrições para tier $tierAtual');

    // Aplica restrições por tier
    List<RaridadeItem> raridadesPermitidas = _obterRaridadesPermitidas(tierAtual);

    // Determina a quantidade de atributos respeitando as restrições
    int quantidadeAtributos = _determinarQuantidadeAtributosComRestricoes(raridadesPermitidas);

    // Determina a raridade baseada na quantidade de atributos (restrita)
    RaridadeItem raridade = _determinarRaridadeComRestricoes(quantidadeAtributos, raridadesPermitidas);

    // Gera o nome do item baseado na raridade
    String nome = GeradorNomesItens.gerarNomeItem();

    // Gera os atributos do item (com multiplicação por tier)
    Map<String, int> atributos = _gerarAtributos(quantidadeAtributos, tierAtual);

    print('✅ [ItemService] Item com restrições gerado: $nome (${raridade.nome}) | Tier: $tierAtual | Restrições aplicadas');

    return Item(
      id: _gerarId(),
      nome: nome,
      raridade: raridade,
      atributos: atributos,
      dataObtencao: DateTime.now(),
      tier: tierAtual,
    );
  }

  /// Determina a quantidade de atributos baseado nas probabilidades
  int _determinarQuantidadeAtributos() {
    // Usa 1-1000 para poder ter 0,5% (5 em 1000)
    int chance = _random.nextInt(1000) + 1; // 1-1000

    print('🎲 [ItemService] Sorteio quantidade atributos: $chance/1000');

    if (chance <= 5) {
      print('🎯 [ItemService] = 5 atributos MÁXIMOS (0.5% chance - Impossível)');
      return -1; // Flag especial para indicar item impossível
    }
    if (chance <= 25) {
      print('🎯 [ItemService] = 5 atributos (2% chance - Lendário)');
      return 5; // 2%
    }
    if (chance <= 55) {
      print('🎯 [ItemService] = 4 atributos (3% chance - Épico)');
      return 4; // 3%
    }
    if (chance <= 155) {
      print('🎯 [ItemService] = 3 atributos (10% chance - Raro)');
      return 3; // 10%
    }
    if (chance <= 355) {
      print('🎯 [ItemService] = 2 atributos (20% chance - Normal)');
      return 2; // 20%
    }
    print('🎯 [ItemService] = 1 atributo (64.5% chance - Inferior)');
    return 1; // 64.5%
  }

  /// Determina a quantidade de atributos para LOJA (2x mais chance de itens melhores)
  /// Impossible: 0.5% → 1%
  /// Legendary: 2% → 4%
  /// Epic: 3% → 6%
  /// Rare: 10% → 20%
  /// Normal: 20% → 40%
  /// Inferior: 64.5% → 29%
  int _determinarQuantidadeAtributosLoja() {
    int chance = _random.nextInt(1000) + 1; // 1-1000

    print('🛒 [ItemService - LOJA] Sorteio quantidade atributos: $chance/1000');

    if (chance <= 10) {
      print('🎯 [ItemService - LOJA] = 5 atributos MÁXIMOS (1% chance - Impossível)');
      return -1; // Flag especial para indicar item impossível
    }
    if (chance <= 50) {
      print('🎯 [ItemService - LOJA] = 5 atributos (4% chance - Lendário)');
      return 5; // 4%
    }
    if (chance <= 110) {
      print('🎯 [ItemService - LOJA] = 4 atributos (6% chance - Épico)');
      return 4; // 6%
    }
    if (chance <= 310) {
      print('🎯 [ItemService - LOJA] = 3 atributos (20% chance - Raro)');
      return 3; // 20%
    }
    if (chance <= 710) {
      print('🎯 [ItemService - LOJA] = 2 atributos (40% chance - Normal)');
      return 2; // 40%
    }
    print('🎯 [ItemService - LOJA] = 1 atributo (29% chance - Inferior)');
    return 1; // 29%
  }

  /// Determina a raridade baseada na quantidade de atributos
  RaridadeItem _determinarRaridade(int quantidadeAtributos) {
    switch (quantidadeAtributos) {
      case -1:
        return RaridadeItem.impossivel;
      case 5:
        return RaridadeItem.lendario;
      case 4:
        return RaridadeItem.epico;
      case 3:
        return RaridadeItem.raro;
      case 2:
        return RaridadeItem.normal;
      default:
        return RaridadeItem.inferior;
    }
  }

  /// Gera atributos aleatórios para o item (aplicando multiplicação por tier)
  Map<String, int> _gerarAtributos(int quantidade, int tier) {
    List<String> atributosDisponiveis = ['vida', 'energia', 'ataque', 'defesa', 'agilidade'];
    atributosDisponiveis.shuffle(_random);

    Map<String, int> atributos = {};

    // Se é item impossível (quantidade = -1), todos os 5 atributos no máximo
    if (quantidade == -1) {
      print('⭐ [ItemService] ITEM IMPOSSÍVEL: Todos os 5 atributos no MÁXIMO!');
      for (String atributo in ['vida', 'energia', 'ataque', 'defesa', 'agilidade']) {
        int valorMaximo = 10 * tier; // Valor máximo possível
        atributos[atributo] = valorMaximo;
        print('🎯 [ItemService] Atributo: $atributo | MÁXIMO | Tier: $tier | Final: $valorMaximo');
      }
      return atributos;
    }

    for (int i = 0; i < quantidade; i++) {
      String atributo = atributosDisponiveis[i];
      int valorBase = _random.nextInt(10) + 1; // 1-10 pontos base por atributo
      int valorFinal = valorBase * tier; // Multiplica pelo tier
      atributos[atributo] = valorFinal;

      print('🎯 [ItemService] Atributo: $atributo | Base: $valorBase | Tier: $tier | Final: $valorFinal');
    }

    return atributos;
  }

  /// Gera um ID único para o item
  String _gerarId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           _random.nextInt(1000).toString();
  }

  /// Calcula o valor estimado do item (para comparação)
  int calcularValorItem(Item item) {
    int valorBase = item.totalAtributos * 10;
    int multiplicadorRaridade = item.raridade.nivel;
    return valorBase * multiplicadorRaridade;
  }

  /// Compara dois itens e retorna qual é melhor
  bool itemEhMelhor(Item novoItem, Item? itemAtual) {
    if (itemAtual == null) return true;
    return calcularValorItem(novoItem) > calcularValorItem(itemAtual);
  }

  /// Gera um item com raridade específica
  Item gerarItemComRaridade(RaridadeItem raridade, {int tierAtual = 1}) {
    print('🏆 [ItemService] Gerando item com raridade ${raridade.nome} para tier $tierAtual');
    
    // Determina quantidade de atributos baseada na raridade
    int quantidadeAtributos = _quantidadeAtributosPorRaridade(raridade);
    
    // Gera o nome do item baseado na raridade
    String nome = GeradorNomesItens.gerarNomeItem();
    
    // Gera os atributos do item (com multiplicação por tier)
    Map<String, int> atributos = _gerarAtributos(quantidadeAtributos, tierAtual);
    
    print('✅ [ItemService] Item de raridade específica gerado: $nome (${raridade.nome}) | Tier: $tierAtual | Total atributos: ${atributos.values.fold(0, (sum, value) => sum + value)}');
    
    return Item(
      id: _gerarId(),
      nome: nome,
      raridade: raridade,
      atributos: atributos,
      dataObtencao: DateTime.now(),
      tier: tierAtual,
    );
  }

  /// Retorna quantidade de atributos baseada na raridade
  int _quantidadeAtributosPorRaridade(RaridadeItem raridade) {
    switch (raridade) {
      case RaridadeItem.impossivel:
        return -1; // Flag para item impossível
      case RaridadeItem.lendario:
        return 5;
      case RaridadeItem.epico:
        return 4;
      case RaridadeItem.raro:
        return 3;
      case RaridadeItem.normal:
        return 2;
      case RaridadeItem.inferior:
        return 1;
    }
  }

  /// Gera um item elite (sempre raro ou superior) para monstros elite
  Item gerarItemElite({int tierAtual = 1}) {
    print('👑 [ItemService] Gerando item ELITE para tier $tierAtual');

    // Calcula probabilidades para itens elite (raro, épico, lendário)
    final chance = _random.nextInt(100);
    RaridadeItem raridadeElite;

    if (chance < 10) {
      raridadeElite = RaridadeItem.lendario;
      print('👑 [ItemService] Raridade elite: LENDÁRIO (10% chance)');
    } else if (chance < 40) {
      raridadeElite = RaridadeItem.epico;
      print('👑 [ItemService] Raridade elite: ÉPICO (30% chance)');
    } else {
      raridadeElite = RaridadeItem.raro;
      print('👑 [ItemService] Raridade elite: RARO (60% chance)');
    }

    return gerarItemComRaridade(raridadeElite, tierAtual: tierAtual);
  }

  /// Gera um item elite respeitando restrições de dificuldade por tier
  /// Tier < 50: mínimo ÉPICO
  /// Tier 50+: mínimo LENDÁRIO com 10% chance de IMPOSSÍVEL
  Item gerarItemEliteComRestricoes({int tierAtual = 1}) {
    print('👑 [ItemService] Gerando item ELITE para tier $tierAtual');

    RaridadeItem raridade;
    int quantidadeAtributos;

    // ===== TIER 50+: LENDÁRIO GARANTIDO + 10% CHANCE DE IMPOSSÍVEL =====
    if (tierAtual >= 50) {
      print('👑 [ItemService] Tier 50+: Lendário garantido + 10% chance de Impossível');

      // 10% de chance de item IMPOSSÍVEL
      final chanceImpossivel = _random.nextInt(100);
      if (chanceImpossivel < 10) {
        print('👑 [ItemService] 🌟 SORTEOU IMPOSSÍVEL! (${chanceImpossivel}/100 < 10)');
        raridade = RaridadeItem.impossivel;
        quantidadeAtributos = _quantidadeAtributosPorRaridade(RaridadeItem.impossivel);
      } else {
        print('👑 [ItemService] Não sorteou impossível (${chanceImpossivel}/100 >= 10), será LENDÁRIO');
        raridade = RaridadeItem.lendario;
        quantidadeAtributos = _quantidadeAtributosPorRaridade(RaridadeItem.lendario);
      }
    } else {
      // ===== TIER < 50: ÉPICO GARANTIDO (comportamento original) =====
      print('👑 [ItemService] Tier < 50: mínimo ÉPICO');

      // Sorteia item normalmente (pode vir Lendário!)
      quantidadeAtributos = _determinarQuantidadeAtributos();
      raridade = _determinarRaridade(quantidadeAtributos);

      print('👑 [ItemService] Item sorteado: ${raridade.nome}');

      // Se vier abaixo de Épico, força para Épico (mínimo garantido)
      if (raridade.nivel < RaridadeItem.epico.nivel) {
        print('👑 [ItemService] Forçando para ÉPICO (era ${raridade.nome})');
        raridade = RaridadeItem.epico;
        quantidadeAtributos = _quantidadeAtributosPorRaridade(RaridadeItem.epico);
      } else {
        print('👑 [ItemService] Mantendo raridade sorteada: ${raridade.nome}');
      }
    }

    // Gera o nome do item
    String nome = GeradorNomesItens.gerarNomeItem();

    // Gera os atributos do item
    Map<String, int> atributos = _gerarAtributos(quantidadeAtributos, tierAtual);

    print('✅ [ItemService] Item ELITE gerado: $nome (${raridade.nome}) | Tier: $tierAtual');

    return Item(
      id: _gerarId(),
      nome: nome,
      raridade: raridade,
      atributos: atributos,
      dataObtencao: DateTime.now(),
      tier: tierAtual,
    );
  }

  /// Obtém as raridades permitidas baseado no tier (restrições de dificuldade)
  List<RaridadeItem> _obterRaridadesPermitidas(int tier) {
    if (tier >= 50) {
      // Tier 50+: apenas lendários
      print('🔒 [ItemService] Tier $tier: apenas itens LENDÁRIOS permitidos');
      return [RaridadeItem.lendario];
    } else if (tier >= 40) {
      // Tier 40+: épicos e lendários
      print('🔒 [ItemService] Tier $tier: apenas itens ÉPICOS e LENDÁRIOS permitidos');
      return [RaridadeItem.epico, RaridadeItem.lendario];
    } else if (tier >= 30) {
      // Tier 30+: raros, épicos e lendários
      print('🔒 [ItemService] Tier $tier: apenas itens RAROS, ÉPICOS e LENDÁRIOS permitidos');
      return [RaridadeItem.raro, RaridadeItem.epico, RaridadeItem.lendario];
    } else if (tier >= 20) {
      // Tier 20+: normais, raros, épicos e lendários
      print('🔒 [ItemService] Tier $tier: apenas itens NORMAIS, RAROS, ÉPICOS e LENDÁRIOS permitidos');
      return [RaridadeItem.normal, RaridadeItem.raro, RaridadeItem.epico, RaridadeItem.lendario];
    } else {
      // Tier < 20: todas as raridades
      print('🔒 [ItemService] Tier $tier: todas as raridades permitidas');
      return RaridadeItem.values;
    }
  }

  /// Determina quantidade de atributos respeitando restrições
  int _determinarQuantidadeAtributosComRestricoes(List<RaridadeItem> raridadesPermitidas) {
    int tentativas = 0;
    int quantidadeAtributos;

    do {
      quantidadeAtributos = _determinarQuantidadeAtributos();
      RaridadeItem raridadeTentativa = _determinarRaridade(quantidadeAtributos);

      if (raridadesPermitidas.contains(raridadeTentativa)) {
        print('🎯 [ItemService] Quantidade aceita: $quantidadeAtributos atributos (${raridadeTentativa.nome})');
        return quantidadeAtributos;
      }

      tentativas++;
    } while (tentativas < 100); // Limite de segurança

    // Se não conseguiu gerar uma raridade válida, força a menor permitida
    final menorRaridadePermitida = raridadesPermitidas.reduce((a, b) => a.nivel < b.nivel ? a : b);
    quantidadeAtributos = _quantidadeAtributosPorRaridade(menorRaridadePermitida);
    print('🔄 [ItemService] Forçando raridade mínima: $quantidadeAtributos atributos (${menorRaridadePermitida.nome})');

    return quantidadeAtributos;
  }

  /// Determina raridade respeitando restrições
  RaridadeItem _determinarRaridadeComRestricoes(int quantidadeAtributos, List<RaridadeItem> raridadesPermitidas) {
    RaridadeItem raridade = _determinarRaridade(quantidadeAtributos);

    if (raridadesPermitidas.contains(raridade)) {
      return raridade;
    }

    // Se a raridade não é permitida, retorna a menor permitida
    final menorRaridadePermitida = raridadesPermitidas.reduce((a, b) => a.nivel < b.nivel ? a : b);
    print('🔄 [ItemService] Raridade ajustada: ${raridade.nome} → ${menorRaridadePermitida.nome}');
    return menorRaridadePermitida;
  }
}
