import 'dart:math';

enum AtributoJogo {
  // Atributos base dos monstros
  vida(min: 75, max: 150),
  energia(min: 20, max: 40),
  agilidade(min: 10, max: 20),
  ataque(min: 10, max: 20),
  defesa(min: 40, max: 60),

  // Valores das habilidades
  habilidadeDano(min: 20, max: 50),
  habilidadeCura(min: 15, max: 40),
  habilidadeAumentarVida(min: 20, max: 70),
  habilidadeAumentarEnergia(min: 5, max: 15),
  habilidadeAumentarAtaque(min: 20, max: 50),
  habilidadeAumentarDefesa(min: 8, max: 70),
  
  // Sistema de recuperação de vida na evolução (valores em % da vida máxima)
  evolucaoRecuperacaoVida(min: 10, max: 10), // Sempre recupera exatamente 10%
  evolucaoLimiteRecuperacao(min: 50, max: 50), // Limite máximo é 50% da vida máxima

  // Ganhos de evolução por nível
  evolucaoGanhoVida(min: 25, max: 25), // Ganho de vida por evolução
  evolucaoGanhoEnergia(min: 1, max: 1), // Ganho de energia por evolução

  // Sistema de descoberta de monstros raros da nova coleção (Nostálgicos)
  // Tier 3-10: 2% de chance | Tier 11+: 3% de chance
  chanceMonstroColecoRaro(min: 2, max: 2), // 2% de chance base (tier 3-10)
  chanceMonstroColecoRaroTier11Plus(min: 4, max: 4), // 4% de chance (tier 11+)
  tierMinimoMonstroColecoRaro(min: 3, max: 3), // A partir do tier 3
  tierBoostMonstroColecoRaro(min: 11, max: 11), // Boost de chance a partir do tier 11

  // ========================================
  // SISTEMA DE DROPS - ITENS CONSUMÍVEIS
  // ========================================
  // Chances de drop de itens consumíveis após vencer batalhas
  // Valores em porcentagem (0-100)
  // Localização: lib/features/aventura/services/drops_service.dart

  dropPocaoVidaPequena(min: 5, max: 5), // 5% de chance de drop por batalha vencida
  dropPocaoVidaGrande(min: 1, max: 1), // 10% de chance de drop por batalha vencida
  dropPedraReforco(min: 1, max: 1), // 5% de chance de drop por batalha vencida

  // ========================================
  // SISTEMA DE RECOMPENSAS POR SCORE
  // ========================================
  // Mecânica de recompensas baseadas no score acumulado em batalhas
  // Localização: lib/features/aventura/services/recompensa_service.dart

  // Drops adicionais: cada 1 de score = 3% de chance de item extra
  // Exemplo: Score 10 = 30%, Score 34 = 102% (1 garantido + 2% restante)
  recompensaChancePorScore(min: 3, max: 3), // 3% por ponto de score

  // Super Drop: dobra todos os itens recebidos
  // Chance: 1% por cada 2 pontos de score (máx 100%)
  // Exemplo: Score 100 = 50% de chance de Super Drop
  recompensaSuperDropPorScore(min: 1, max: 1), // 1% por cada 2 de score

  // Chance de receber Magia ao invés de Item comum
  recompensaChanceMagia(min: 30, max: 30), // 30% magia, 70% item

  // Boost de Qualidade: melhora a raridade de itens
  // Cada 10 de score = +1 boost (cada boost = chance de subir raridade)
  // Exemplo: Score 50 = 5 tentativas de upgrade
  recompensaScorePorBoostQualidade(min: 10, max: 10), // Dividir score por 10

  // Boost de Level em Magias: aumenta o level das magias recebidas
  // Cada 20 de score = 1 tentativa de 10% de +1 level (máximo +3 levels)
  // Exemplo: Score 60 = 3 tentativas de 10% cada
  recompensaScorePorBoostLevelMagia(min: 20, max: 20), // Dividir score por 20
  recompensaChanceBoostLevelMagia(min: 10, max: 10); // 10% por tentativa

  final int min;
  final int max;
  const AtributoJogo({required this.min, required this.max});

  int sortear(Random random) {
    return min + random.nextInt(max - min + 1);
  }

  /// Calcula o bônus de vida dos inimigos baseado no tier
  /// Fórmula: +20% a cada 10 andares (tiers 10-19: +20%, 20-29: +40%, etc)
  static double calcularBonusVidaInimigo(int tier) {
    if (tier < 10) return 0.0; // Andares 1-9: sem bônus

    final dezenas = tier ~/ 10; // Quantas dezenas completas
    final bonus = dezenas * 0.20; // +20% por dezena

    return bonus;
  }

  /// Sorteia vida de inimigo com bônus baseado no tier
  int sortearVidaInimigo(Random random, int tier) {
    final vidaBase = sortear(random);
    final bonusPercentual = calcularBonusVidaInimigo(tier);
    final vidaComBonus = vidaBase * (1.0 + bonusPercentual);

    return vidaComBonus.round();
  }

  String get rangeTexto => '$min a $max';

  /// Verifica se o tier atual permite monstros raros da nova coleção (Nostálgicos)
  ///
  /// Monstros nostálgicos podem aparecer a partir do tier 3
  static bool podeGerarMonstroRaro(int tier) {
    return tier >= AtributoJogo.tierMinimoMonstroColecoRaro.min;
  }

  /// Obtém a chance (em %) de gerar monstro raro baseada no tier
  ///
  /// - Tier 3-10: 2% de chance
  /// - Tier 11+: 3% de chance (boost no endgame)
  static int chanceMonstroColecoRaroPercent(int tier) {
    if (tier >= AtributoJogo.tierBoostMonstroColecoRaro.min) {
      return AtributoJogo.chanceMonstroColecoRaroTier11Plus.min; // 3% tier 11+
    }
    return AtributoJogo.chanceMonstroColecoRaro.min; // 2% tier 3-10
  }

  /// Verifica se deve gerar monstro raro (Nostálgico) baseado na chance do tier
  ///
  /// Exemplos:
  /// - Tier 5: 2% de chance (sorteio 0-99, sucesso se < 2)
  /// - Tier 11: 3% de chance (sorteio 0-99, sucesso se < 3)
  /// - Tier 15: 3% de chance (sorteio 0-99, sucesso se < 3)
  static bool deveGerarMonstroRaro(Random random, int tier) {
    if (!podeGerarMonstroRaro(tier)) {
      print('🌟 [AtributoJogo] Tier $tier menor que o mínimo ${tierMinimoMonstroColecoRaro.min}');
      return false;
    }

    final chanceAtual = chanceMonstroColecoRaroPercent(tier);
    final sorteio = random.nextInt(100);
    final resultado = sorteio < chanceAtual;

    print('🌟 [AtributoJogo] Tier $tier - Chance: $chanceAtual% | Sorteio: $sorteio < $chanceAtual = $resultado');
    return resultado;
  }
}
