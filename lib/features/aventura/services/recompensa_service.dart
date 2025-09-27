import 'dart:math';
import '../models/item.dart';
import '../models/magia_drop.dart';
// Removendo import não usado
import '../services/item_service.dart';
import '../services/magia_service.dart';
// Removendo import desnecessário

class RecompensaService {
  final Random _random = Random();
  final ItemService _itemService = ItemService();
  final MagiaService _magiaService = MagiaService();

  /// Gera recompensas baseadas no score do jogador
  /// Retorna Map com: 'itens': List<Item>, 'magias': List<MagiaDrop>, 'superDrop': bool
  Map<String, dynamic> gerarRecompensasPorScore(int score, int tierAtual) {
    print('🎁 [RecompensaService] Gerando recompensas para score: $score, tier: $tierAtual');
    
    if (score < 1) {
      print('❌ [RecompensaService] Score insuficiente ($score < 1)');
      return {'itens': <Item>[], 'magias': <MagiaDrop>[], 'superDrop': false};
    }

    // 1. Drop fixo garantido
    final recompensas = <dynamic>[];
    recompensas.add(_gerarItemOuMagia(tierAtual, score));
    
    // 2. Drops adicionais baseados no score (3% por score)
    int dropsAdicionais = _calcularDropsAdicionais(score);
    for (int i = 0; i < dropsAdicionais; i++) {
      recompensas.add(_gerarItemOuMagia(tierAtual, score));
    }
    
    // 3. Super Drop (dobrar quantidade) - 1% por 2 de score
    bool superDrop = _calcularSuperDrop(score);
    if (superDrop) {
      print('🌟 [RecompensaService] SUPER DROP ATIVADO! Dobrando quantidade de itens');
      final recompensasOriginais = List.from(recompensas);
      for (var _ in recompensasOriginais) {
        recompensas.add(_gerarItemOuMagia(tierAtual, score));
      }
    }
    
    // Separa itens e magias
    final itens = <Item>[];
    final magias = <MagiaDrop>[];
    
    for (var recompensa in recompensas) {
      if (recompensa is Item) {
        itens.add(recompensa);
      } else if (recompensa is MagiaDrop) {
        magias.add(recompensa);
      }
    }
    
    print('🎁 [RecompensaService] Recompensas geradas: ${itens.length} itens, ${magias.length} magias, superDrop: $superDrop');
    
    return {
      'itens': itens,
      'magias': magias,
      'superDrop': superDrop,
    };
  }

  /// Calcula quantos drops adicionais baseado no score
  /// Cada 1 de score = 3% de chance de drop adicional
  /// Se passar de 100%, é garantido e o excesso vai para o próximo
  int _calcularDropsAdicionais(int score) {
    final chanceTotal = score * 3; // 3% por score
    int dropsGarantidos = chanceTotal ~/ 100; // Quantos drops são garantidos
    int chanceRestante = chanceTotal % 100; // Chance restante em %
    
    print('📊 [RecompensaService] Drops adicionais: Score $score × 3% = ${chanceTotal}% total');
    print('📊 [RecompensaService] = $dropsGarantidos garantidos + ${chanceRestante}% restante');
    
    // Sorteia para a chance restante
    if (chanceRestante > 0) {
      final numeroSorteado = _random.nextInt(100);
      final ganhouExtra = numeroSorteado < chanceRestante;
      print('🎲 [RecompensaService] Sorteio extra: $numeroSorteado/100 (precisa < $chanceRestante) → ${ganhouExtra ? 'GANHOU' : 'não ganhou'}');
      if (ganhouExtra) {
        dropsGarantidos++;
      }
    }
    
    print('🎯 [RecompensaService] Total drops adicionais: $dropsGarantidos');
    return dropsGarantidos;
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

  /// Gera um item ou magia com qualidade melhorada baseada no score
  /// Cada 10 de score = +1% chance de raridade melhor
  dynamic _gerarItemOuMagia(int tierAtual, int score) {
    // 30% magia, 70% item (mesmo do sistema atual)
    final numeroSorteado = _random.nextInt(100);
    final ehMagia = numeroSorteado < 30;
    print('🎲 [RecompensaService] Tipo de recompensa: $numeroSorteado/100 (< 30 = magia) → ${ehMagia ? 'MAGIA' : 'ITEM'}');
    
    if (ehMagia) {
      return _gerarMagiaComQualidade(tierAtual, score);
    } else {
      return _gerarItemComQualidade(tierAtual, score);
    }
  }

  /// Gera item com qualidade melhorada baseada no score
  Item _gerarItemComQualidade(int tierAtual, int score) {
    // Calcula boost de qualidade: cada 10 de score = +1% de chance de subir raridade
    final boostQualidade = score ~/ 10; // 1% por cada 10 de score
    print('📊 [RecompensaService] Boost de qualidade: Score $score ÷ 10 = $boostQualidade níveis de boost');

    // Gera item normal primeiro
    final itemBase = _itemService.gerarItemAleatorio(tierAtual: tierAtual);
    print('🎯 [RecompensaService] Item base gerado: ${itemBase.nome} (${itemBase.raridade.nome})');

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
  MagiaDrop _gerarMagiaComQualidade(int tierAtual, int score) {
    // Magia sempre usa a geração normal - a melhoria vem no level
    final magiaBase = _magiaService.gerarMagiaAleatoria(tierAtual: tierAtual);
    print('🎯 [RecompensaService] Magia base gerada: ${magiaBase.nome} (Level ${magiaBase.level})');
    
    // Aplica boost de level baseado no score (cada 20 de score = chance de +1 level)
    final boostLevel = _calcularBoostLevel(score);
    
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