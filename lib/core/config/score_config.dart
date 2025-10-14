/// Configurações do Sistema de Score V2
///
/// Este arquivo contém todos os parâmetros configuráveis relacionados ao score do jogo.
/// Os valores podem ser editados pelo painel admin quando ENABLE_TYPE_EDITING = true.
class ScoreConfig {
  /// Limite de score que pode ser salvo no ranking antes do tier 11
  ///
  /// Exemplos:
  /// - Jogador no tier 5 com 45 pontos → Salva 45
  /// - Jogador no tier 6 com 67 pontos → Salva 50 (limite)
  /// - Jogador no tier 7 com 44 pontos → Salva 44
  static int SCORE_LIMITE_PRE_TIER_11 = 50;

  /// Pontos garantidos que são salvos no ranking ao passar para o tier 11+
  ///
  /// Ao avançar para o tier 11, independente do score atual:
  /// - Score é resetado para 0
  /// - Este valor (50) é salvo no ranking como base garantida
  static int SCORE_PONTOS_GARANTIDOS_TIER_11 = 50;

  /// Pontos ganhos por vitória em batalha a partir do tier 11
  ///
  /// Tier 1-10: Ganha pontos igual ao tier (tier 5 = 5 pontos)
  /// Tier 11+: Ganha este valor fixo por vitória (padrão: 2 pontos)
  static int SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS = 2;

  /// Limite máximo total de pontos que podem ser salvos no ranking
  ///
  /// Tier 11+: 50 (garantidos) + até 100 (extras) = 150 total
  /// Este é o teto absoluto de pontuação
  static int SCORE_LIMITE_MAXIMO_TOTAL = 150;

  /// Tier onde ocorre a transição do sistema de score
  ///
  /// Antes deste tier: Sistema de score normal (limite de 50)
  /// A partir deste tier: Sistema de 50 garantidos + extras
  static int SCORE_TIER_TRANSICAO = 11;

  /// Calcula o score máximo de extras disponível no tier 11+
  ///
  /// Exemplo com valores padrão: 150 (máximo) - 50 (garantidos) = 100 extras
  static int get scoreMaximoExtras => SCORE_LIMITE_MAXIMO_TOTAL - SCORE_PONTOS_GARANTIDOS_TIER_11;

  /// Verifica se um tier está no sistema pré-transição (tier 1-10)
  static bool ehPreTransicao(int tier) => tier < SCORE_TIER_TRANSICAO;

  /// Verifica se um tier está no sistema pós-transição (tier 11+)
  static bool ehPosTransicao(int tier) => tier >= SCORE_TIER_TRANSICAO;

  /// Calcula quanto de score deve ser salvo no ranking baseado no tier
  ///
  /// Tier 1-10: min(scoreAtual, LIMITE_PRE_TIER_11)
  /// Tier 11+: min(GARANTIDOS + scoreExtra, LIMITE_MAXIMO)
  static int calcularScoreSalvar(int tier, int scoreAtual) {
    if (ehPreTransicao(tier)) {
      // Pré-tier 11: limite de 50 pontos
      return scoreAtual.clamp(0, SCORE_LIMITE_PRE_TIER_11);
    } else {
      // Tier 11+: 50 garantidos + score extra (até 150 total)
      final scoreTotal = SCORE_PONTOS_GARANTIDOS_TIER_11 + scoreAtual;
      return scoreTotal.clamp(SCORE_PONTOS_GARANTIDOS_TIER_11, SCORE_LIMITE_MAXIMO_TOTAL);
    }
  }

  /// Calcula quanto de score pode ainda ser ganho antes de atingir o limite
  static int calcularScoreDisponivel(int tier, int scoreAtual) {
    if (ehPreTransicao(tier)) {
      // Pré-tier 11: até 50 pontos
      final disponivel = SCORE_LIMITE_PRE_TIER_11 - scoreAtual;
      return disponivel.clamp(0, SCORE_LIMITE_PRE_TIER_11);
    } else {
      // Tier 11+: até 100 pontos extras
      final disponivel = scoreMaximoExtras - scoreAtual;
      return disponivel.clamp(0, scoreMaximoExtras);
    }
  }

  /// Verifica se o jogador atingiu o limite de score para o tier atual
  ///
  /// Tier 1-10: Retorna true quando atinge 50 pontos
  /// Tier 11+: SEMPRE retorna false (score ilimitado para uso na loja)
  ///
  /// IMPORTANTE: O limite de 150 no tier 11+ só se aplica ao RANKING,
  /// não ao score em si que pode crescer infinitamente para compras na loja
  static bool atingiuLimite(int tier, int scoreAtual) {
    if (ehPreTransicao(tier)) {
      return scoreAtual >= SCORE_LIMITE_PRE_TIER_11;
    } else {
      // Tier 11+: score é ilimitado (false = nunca atinge limite)
      return false;
    }
  }

  /// Formata a exibição do score baseado no tier
  ///
  /// Tier 1-10: "X" (ex: "45")
  /// Tier 11+: "50 + X" (ex: "50 + 28")
  static String formatarScoreExibicao(int tier, int scoreAtual) {
    if (ehPreTransicao(tier)) {
      return '$scoreAtual';
    } else {
      return '$SCORE_PONTOS_GARANTIDOS_TIER_11 + $scoreAtual';
    }
  }

  /// Calcula score total para exibição (incluindo pontos garantidos em tier 11+)
  ///
  /// Tier 1-10: scoreAtual
  /// Tier 11+: 50 + scoreAtual
  static int calcularScoreTotal(int tier, int scoreAtual) {
    if (ehPreTransicao(tier)) {
      return scoreAtual;
    } else {
      return SCORE_PONTOS_GARANTIDOS_TIER_11 + scoreAtual;
    }
  }

  /// Reseta valores para os padrões
  static void restaurarPadroes() {
    SCORE_LIMITE_PRE_TIER_11 = 50;
    SCORE_PONTOS_GARANTIDOS_TIER_11 = 50;
    SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS = 2;
    SCORE_LIMITE_MAXIMO_TOTAL = 150;
    SCORE_TIER_TRANSICAO = 11;
  }

  /// Valida se os valores configurados são válidos
  static bool validarConfiguracao() {
    if (SCORE_LIMITE_PRE_TIER_11 <= 0) return false;
    if (SCORE_PONTOS_GARANTIDOS_TIER_11 <= 0) return false;
    if (SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS <= 0) return false;
    if (SCORE_LIMITE_MAXIMO_TOTAL <= SCORE_PONTOS_GARANTIDOS_TIER_11) return false;
    if (SCORE_TIER_TRANSICAO <= 0) return false;
    return true;
  }

  /// Retorna descrição dos parâmetros atuais (para debug/admin)
  static String obterDescricaoConfig() {
    return '''
📊 Configuração de Score V2:
├─ Limite Pré-Tier 11: $SCORE_LIMITE_PRE_TIER_11 pontos
├─ Pontos Garantidos Tier 11+: $SCORE_PONTOS_GARANTIDOS_TIER_11 pontos
├─ Pontos por Vitória Tier 11+: $SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS pontos
├─ Limite Máximo Total: $SCORE_LIMITE_MAXIMO_TOTAL pontos
├─ Tier de Transição: $SCORE_TIER_TRANSICAO
└─ Score Extras Máximo: $scoreMaximoExtras pontos
''';
  }
}
