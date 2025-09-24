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
  evolucaoGanhoEnergia(min: 1, max: 1); // Ganho de energia por evolução

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
}
