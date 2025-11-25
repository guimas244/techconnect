import 'dart:math';
import '../models/item.dart';
import '../models/magia_drop.dart';
import '../config/evento_config.dart';
// Removendo import não usado
import '../services/item_service.dart';
import '../services/magia_service.dart';
// Removendo import desnecessário
import 'package:shared_preferences/shared_preferences.dart';

class RecompensaService {
  final Random _random = Random();
  final ItemService _itemService = ItemService();
  final MagiaService _magiaService = MagiaService();

  /// Carrega o filtro de raridades do SharedPreferences
  Future<Map<RaridadeItem, bool>> _carregarFiltroDrops() async {
    final prefs = await SharedPreferences.getInstance();
    final filtro = <RaridadeItem, bool>{};

    for (final raridade in RaridadeItem.values) {
      filtro[raridade] = prefs.getBool('filtro_drop_${raridade.name}') ?? true;
    }

    return filtro;
  }

  /// Carrega o valor mínimo de magia do SharedPreferences
  Future<int> _carregarValorMinimoMagia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('filtro_drop_valor_minimo_magia') ?? 0;
  }

  /// Gera recompensas baseadas no score do jogador
  /// Retorna Map com: 'itens': List<Item>, 'magias': List<MagiaDrop>, 'superDrop': bool, 'moedaEvento': int, 'moedaChave': int, 'teks': int
  Future<Map<String, dynamic>> gerarRecompensasPorScore(int score, int tierAtual) async {
    print('🎁 [RecompensaService] Gerando recompensas para score: $score, tier: $tierAtual');

    if (score < 1) {
      print('❌ [RecompensaService] Score insuficiente ($score < 1)');
      return {'itens': <Item>[], 'magias': <MagiaDrop>[], 'superDrop': false, 'moedaEvento': 0, 'moedaChave': 0, 'teks': 0};
    }

    final itens = <Item>[];
    final magias = <MagiaDrop>[];

    // 1. Drop de ITEM (70% chance fixa)
    int quantidadeItens = _calcularQuantidadeDrops(70.0);
    for (int i = 0; i < quantidadeItens; i++) {
      final item = await _gerarItemComQualidade(tierAtual, score);
      if (item != null) {
        itens.add(item);
      }
    }

    // 2. Drop de MAGIA (30% chance fixa)
    int quantidadeMagias = _calcularQuantidadeDrops(30.0);
    for (int i = 0; i < quantidadeMagias; i++) {
      final magia = await _gerarMagiaComQualidade(tierAtual, score);
      if (magia != null) {
        magias.add(magia);
      }
    }

    // 3. Super Drop (dobrar quantidade) - 1% por 2 de score
    bool superDrop = _calcularSuperDrop(score);
    if (superDrop) {
      print('🌟 [RecompensaService] SUPER DROP ATIVADO! Dobrando quantidade de itens e magias');

      // Dobra itens
      final itensOriginais = itens.length;
      for (int i = 0; i < itensOriginais; i++) {
        final item = await _gerarItemComQualidade(tierAtual, score);
        if (item != null) {
          itens.add(item);
        }
      }

      // Dobra magias
      final magiasOriginais = magias.length;
      for (int i = 0; i < magiasOriginais; i++) {
        final magia = await _gerarMagiaComQualidade(tierAtual, score);
        if (magia != null) {
          magias.add(magia);
        }
      }
    }

    // 4. Moeda de Evento (chance independente baseada no tier)
    int moedaEvento = _calcularDropMoedaEvento(tierAtual);

    // 5. Moeda Chave (chance independente baseada no tier - 10x menos que moeda evento)
    int moedaChave = _calcularDropMoedaChave(tierAtual);

    // 6. Teks - Moeda do Criadouro (chance x2 da chave, x3 após andar 50)
    int teks = _calcularDropTeks(tierAtual);

    print('🎁 [RecompensaService] Recompensas geradas: ${itens.length} itens, ${magias.length} magias, superDrop: $superDrop, moedaEvento: $moedaEvento, moedaChave: $moedaChave, teks: $teks');

    return {
      'itens': itens,
      'magias': magias,
      'superDrop': superDrop,
      'moedaEvento': moedaEvento,
      'moedaChave': moedaChave,
      'teks': teks,
    };
  }

  /// Calcula drop de moeda de evento baseado no tier
  /// Tier 1-5: 1-5% de chance
  /// Tier 6-10: 5% de chance
  /// Tier 11+: 10% de chance fixo
  ///
  /// EVENTO HALLOWEEN: ENCERRADO (flag manual em EventoConfig)
  int _calcularDropMoedaEvento(int tier) {
    // Verifica se o evento de Halloween está ativo
    if (!EventoConfig.moedaHalloweenPodeDropar) {
      // Evento encerrado - não dropa mais
      return 0;
    }

    // ========== LÓGICA DE DROP (quando evento ativo) ==========
    double chance = 0.0;

    if (tier <= 5) {
      chance = tier.toDouble(); // 1% no tier 1, 2% no tier 2, etc.
    } else if (tier <= 10) {
      chance = 5.0; // 5% fixo do tier 6 ao 10
    } else {
      chance = 10.0; // 10% fixo tier 11+
    }

    final roll = _random.nextDouble() * 100;
    final dropou = roll < chance;

    if (dropou) {
      print('🪙 [RecompensaService] MOEDA DE EVENTO DROPADA! (Tier $tier, Chance: $chance%, Roll: ${roll.toStringAsFixed(2)}%)');
      return 1;
    }

    return 0;
  }

  /// Calcula drop de Moeda Chave (10x menos chance que moeda de Halloween)
  /// Começa a dropar a partir de 01/11
  /// Tier 1-5: 0.1-0.5% de chance
  /// Tier 6-10: 0.5% de chance
  /// Tier 11+: 1.0% de chance fixo
  int _calcularDropMoedaChave(int tier) {
    // Debug: mostra data atual e se pode dropar
    final agora = DateTime.now();
    final podeDropar = EventoConfig.moedaChavePodeDropar;
    print('🔍 [RecompensaService] Verificando moeda chave - Data atual: $agora, Pode dropar: $podeDropar');

    // Verifica se a moeda chave pode dropar (a partir de 01/11)
    if (!podeDropar) {
      print('❌ [RecompensaService] Moeda chave NÃO pode dropar ainda (antes de 01/11)');
      return 0;
    }

    double chance = 0.0;
    if (tier <= 5) {
      chance = tier * 0.1; // 0.1% no tier 1, 0.2% no tier 2, etc.
    } else if (tier <= 10) {
      chance = 0.5;
    } else {
      chance = 1.0; // 1% fixo tier 11+
    }

    final roll = _random.nextDouble() * 100;
    final dropou = roll < chance;

    print('🎲 [RecompensaService] Rolando moeda chave: Tier $tier, Chance: $chance%, Roll: ${roll.toStringAsFixed(2)}%, Dropou: $dropou');

    if (dropou) {
      print('🔑 [RecompensaService] MOEDA CHAVE DROPADA! (Tier $tier, Chance: $chance%, Roll: ${roll.toStringAsFixed(2)}%)');
      return 1;
    }

    return 0;
  }

  /// Calcula drop de Teks (moeda do Criadouro)
  /// Chance = moedaChave x2 (andares 1-49)
  /// Chance = moedaChave x3 (andares 50+)
  /// Quantidade: 1-3 (andares 1-49), 2-5 (andares 50+)
  int _calcularDropTeks(int tier) {
    // Calcula o "andar" aproximado baseado no tier (tier * 10 aproximadamente)
    final andarAproximado = tier * 10;

    // Chance base igual à moedaChave
    double chanceBase = 0.0;
    if (tier <= 5) {
      chanceBase = tier * 0.1; // 0.1% no tier 1, 0.2% no tier 2, etc.
    } else if (tier <= 10) {
      chanceBase = 0.5;
    } else {
      chanceBase = 1.0; // 1% fixo tier 11+
    }

    // Multiplicador baseado no andar
    double multiplicador;
    int quantidadeMin;
    int quantidadeMax;

    if (andarAproximado >= 50) {
      multiplicador = 3.0; // x3 após andar 50
      quantidadeMin = 2;
      quantidadeMax = 5;
    } else {
      multiplicador = 2.0; // x2 antes do andar 50
      quantidadeMin = 1;
      quantidadeMax = 3;
    }

    final chanceTotal = chanceBase * multiplicador;
    final roll = _random.nextDouble() * 100;
    final dropou = roll < chanceTotal;

    print('🌱 [RecompensaService] Rolando Teks: Tier $tier (~andar $andarAproximado), Chance base: $chanceBase% x$multiplicador = $chanceTotal%, Roll: ${roll.toStringAsFixed(2)}%, Dropou: $dropou');

    if (dropou) {
      // Quantidade aleatória dentro do range
      final quantidade = quantidadeMin + _random.nextInt(quantidadeMax - quantidadeMin + 1);
      print('🌱 [RecompensaService] TEKS DROPADO! Quantidade: $quantidade (range: $quantidadeMin-$quantidadeMax)');
      return quantidade;
    }

    return 0;
  }

  /// Calcula quantidade de drops independentes (itens ou magias)
  /// chanceBase: 70% para itens, 30% para magias (chance fixa)
  /// Sorteia se dropa ou não baseado na chance
  int _calcularQuantidadeDrops(double chanceBase) {
    final tipoString = chanceBase == 70.0 ? 'ITEM' : 'MAGIA';

    final numeroSorteado = _random.nextInt(100);
    final dropou = numeroSorteado < chanceBase;

    print('🎲 [RecompensaService] Sorteio $tipoString: $numeroSorteado/100 (precisa < ${chanceBase.toInt()}) → ${dropou ? 'DROPOU' : 'não dropou'}');

    return dropou ? 1 : 0;
  }

  /// Calcula se ativa Super Drop
  /// Cada 2 de score = 1% de chance de dobrar itens
  /// Não escala além de 100%
  bool _calcularSuperDrop(int score) {
    final chanceTotal = (score ~/ 2) * 1; // 1% por cada 2 de score
    final chanceReal = chanceTotal.clamp(0, 100); // Máximo 100%
    
    print('📊 [RecompensaService] Super Drop: Score $score ÷ 2 = ${score ~/ 2} × 1% = ${chanceTotal}% (máx 100%)');
    print('📊 [RecompensaService] Chance final: ${chanceReal}%');
    
    final numeroSorteado = _random.nextInt(100);
    final ativou = numeroSorteado < chanceReal;
    print('🎲 [RecompensaService] Sorteio Super Drop: $numeroSorteado/100 (precisa < $chanceReal) → ${ativou ? '⭐ ATIVADO!' : 'não ativado'}');
    
    return ativou;
  }


  /// Gera item com qualidade melhorada baseada no score
  /// Retorna null se o item for filtrado
  Future<Item?> _gerarItemComQualidade(int tierAtual, int score) async {
    // Carrega filtro de raridades configurado pelo usuário
    final filtroRaridades = await _carregarFiltroDrops();

    // Calcula boost de qualidade: cada 10 de score = +1% de chance de subir raridade
    final boostQualidade = score ~/ 10; // 1% por cada 10 de score
    print('📊 [RecompensaService] Boost de qualidade: Score $score ÷ 10 = $boostQualidade níveis de boost');

    // Gera item normal primeiro (SEM filtro - sorteia normalmente)
    final itemBase = _itemService.gerarItemAleatorio(tierAtual: tierAtual);
    print('🎯 [RecompensaService] Item base gerado: ${itemBase.nome} (${itemBase.raridade.nome})');

    // Verifica se a raridade está permitida no filtro
    final raridadePermitida = filtroRaridades[itemBase.raridade] ?? true;
    if (!raridadePermitida) {
      print('❌ [RecompensaService] Item ${itemBase.raridade.nome} filtrado! Será descartado.');
      return null;
    }

    // Aplica melhoria de qualidade se necessário
    final raridadeMelhorada = _aplicarMelhoriaQualidade(itemBase.raridade, boostQualidade);

    // Se a raridade mudou, recria o item com nova raridade
    if (raridadeMelhorada != itemBase.raridade) {
      print('⬆️ [RecompensaService] Item melhorado: ${itemBase.raridade.nome} → ${raridadeMelhorada.nome}');
      return _itemService.gerarItemComRaridade(raridadeMelhorada, tierAtual: tierAtual);
    }

    print('📦 [RecompensaService] Item manteve raridade: ${itemBase.raridade.nome}');
    return itemBase;
  }

  /// Gera magia com level melhorado baseado no score
  /// Retorna null se a magia for filtrada por valor mínimo
  Future<MagiaDrop?> _gerarMagiaComQualidade(int tierAtual, int score) async {
    // Carrega filtro de valor mínimo configurado pelo usuário
    final valorMinimoMagia = await _carregarValorMinimoMagia();

    // Magia sempre usa a geração normal - a melhoria vem no level
    final magiaBase = _magiaService.gerarMagiaAleatoria(tierAtual: tierAtual);

    // Aplica boost de level baseado no score (cada 20 de score = chance de +1 level)
    final boostLevel = _calcularBoostLevel(score);
    final levelFinal = magiaBase.level + boostLevel;

    // Calcula o valor FINAL da magia (valor base × level final)
    final valorFinal = magiaBase.valor * levelFinal;
    print('🎯 [RecompensaService] Magia base gerada: ${magiaBase.nome} (Valor base: ${magiaBase.valor}, Level: ${magiaBase.level} + boost $boostLevel = $levelFinal, Valor FINAL: $valorFinal)');

    // Verifica se o valor FINAL da magia está acima do mínimo configurado
    if (valorMinimoMagia > 0 && valorFinal < valorMinimoMagia) {
      print('❌ [RecompensaService] Magia com valor FINAL $valorFinal filtrada! (mínimo: $valorMinimoMagia). Será descartada.');
      return null;
    }

    if (boostLevel > 0) {
      print('⬆️ [RecompensaService] Magia melhorada: level ${magiaBase.level} → ${magiaBase.level + boostLevel}');
      // Cria nova magia com level aumentado
      return MagiaDrop(
        nome: magiaBase.nome,
        descricao: magiaBase.descricao,
        tipo: magiaBase.tipo,
        efeito: magiaBase.efeito,
        valor: magiaBase.valor,
        custoEnergia: magiaBase.custoEnergia,
        level: magiaBase.level + boostLevel,
        dataObtencao: magiaBase.dataObtencao,
      );
    }

    print('✨ [RecompensaService] Magia manteve level: ${magiaBase.level}');
    return magiaBase;
  }

  /// Aplica melhoria de qualidade baseada no boost
  /// Cada boost = chance de subir uma raridade
  RaridadeItem _aplicarMelhoriaQualidade(RaridadeItem raridadeAtual, int boost) {
    if (boost <= 0) {
      print('📊 [RecompensaService] Sem boost de qualidade (boost = $boost)');
      return raridadeAtual;
    }
    
    final raridadesOrdem = [
      RaridadeItem.inferior,
      RaridadeItem.normal, 
      RaridadeItem.raro,
      RaridadeItem.epico,
      RaridadeItem.lendario,
    ];
    
    final indiceAtual = raridadesOrdem.indexOf(raridadeAtual);
    if (indiceAtual == -1) return raridadeAtual;
    
    int novoIndice = indiceAtual;
    print('📊 [RecompensaService] Tentando melhorar raridade: ${raridadeAtual.nome} (índice $indiceAtual) com $boost boosts');
    
    // Para cada boost, tenta subir uma raridade
    for (int i = 0; i < boost && novoIndice < raridadesOrdem.length - 1; i++) {
      // Chance diminui conforme sobe: 100% primeira subida, 50% segunda, 25% terceira...
      final chance = 100 ~/ (2 << i); // 100, 50, 25, 12, 6...
      final numeroSorteado = _random.nextInt(100);
      final subiu = numeroSorteado < chance;
      
      print('🎲 [RecompensaService] Boost ${i + 1}/$boost: $numeroSorteado/100 (precisa < $chance) → ${subiu ? 'SUBIU' : 'não subiu'}');
      
      if (subiu) {
        novoIndice++;
        print('📈 [RecompensaService] Nova raridade: ${raridadesOrdem[novoIndice].nome}');
      }
    }
    
    if (novoIndice != indiceAtual) {
      print('🎉 [RecompensaService] Raridade final: ${raridadeAtual.nome} → ${raridadesOrdem[novoIndice].nome}');
    } else {
      print('📦 [RecompensaService] Raridade mantida: ${raridadeAtual.nome}');
    }
    
    return raridadesOrdem[novoIndice];
  }

  /// Calcula boost de level para magias
  /// Cada 20 de score = 10% chance de +1 level
  int _calcularBoostLevel(int score) {
    final boostsDisponiveis = score ~/ 20; // Quantos boosts pode tentar
    int levelGanho = 0;
    
    print('📊 [RecompensaService] Boost de level magia: Score $score ÷ 20 = $boostsDisponiveis tentativas');
    
    for (int i = 0; i < boostsDisponiveis; i++) {
      final numeroSorteado = _random.nextInt(100);
      final ganhou = numeroSorteado < 10;
      print('🎲 [RecompensaService] Tentativa ${i + 1}/$boostsDisponiveis: $numeroSorteado/100 (precisa < 10) → ${ganhou ? '+1 LEVEL' : 'sem level'}');
      
      if (ganhou) {
        levelGanho++;
      }
    }
    
    final levelFinal = levelGanho.clamp(0, 3); // Máximo +3 levels
    print('🎯 [RecompensaService] Total boost de level: +$levelFinal (máx +3)');
    
    return levelFinal;
  }

  /// Cria texto explicativo das recompensas
  String criarResumoRecompensas(Map<String, dynamic> resultado) {
    final itens = resultado['itens'] as List<Item>;
    final magias = resultado['magias'] as List<MagiaDrop>;
    final superDrop = resultado['superDrop'] as bool;
    
    final List<String> linhas = [];
    
    if (superDrop) {
      linhas.add('🌟 SUPER DROP ATIVADO! Quantidade dobrada!');
    }
    
    linhas.add('🎁 ${itens.length + magias.length} recompensa(s) obtida(s):');
    
    for (var item in itens) {
      linhas.add('   📦 ${item.nome} (${item.raridade.name} - Tier ${item.tier})');
    }
    
    for (var magia in magias) {
      linhas.add('   ✨ ${magia.nome} (Level ${magia.level})');
    }
    
    return linhas.join('\n');
  }
}