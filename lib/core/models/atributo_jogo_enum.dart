import 'dart:math';

enum AtributoJogo {
  // Atributos base dos monstros
  vida(min: 50, max: 100),
  energia(min: 20, max: 40),
  agilidade(min: 10, max: 20),
  ataque(min: 10, max: 20),
  defesa(min: 40, max: 60),
  
  // Valores das habilidades
  habilidadeDano(min: 20, max: 50),
  habilidadeCura(min: 15, max: 40),
  habilidadeAumentarVida(min: 10, max: 30),
  habilidadeAumentarEnergia(min: 5, max: 15),
  habilidadeAumentarAtaque(min: 5, max: 15),
  habilidadeAumentarDefesa(min: 8, max: 20),
  
  // Sistema de recuperação de vida na evolução (valores em % da vida máxima)
  evolucaoRecuperacaoVida(min: 10, max: 10), // Sempre recupera exatamente 10%
  evolucaoLimiteRecuperacao(min: 50, max: 50); // Limite máximo é 50% da vida máxima

  final int min;
  final int max;
  const AtributoJogo({required this.min, required this.max});

  int sortear(Random random) {
    return min + random.nextInt(max - min + 1);
  }
  String get rangeTexto => '$min a $max';
}
