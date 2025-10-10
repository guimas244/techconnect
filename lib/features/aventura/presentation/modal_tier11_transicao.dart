import 'package:flutter/material.dart';
import '../../../core/config/score_config.dart';

/// Modal especial que aparece ao avançar do tier 10 para o tier 11
///
/// Informa sobre:
/// - 50 pontos garantidos salvos no ranking
/// - Reset do score para 0
/// - Novo sistema de pontuação (2 pontos por vitória)
/// - Limite máximo de 150 pontos
class ModalTier11Transicao extends StatelessWidget {
  final int scoreAtual;

  const ModalTier11Transicao({
    super.key,
    required this.scoreAtual,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Azul escuro
              Color(0xFF0D47A1), // Azul médio
              Color(0xFF01579B), // Azul claro
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.amber.shade400,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade400.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com celebração
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade600,
                    Colors.orange.shade700,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 40,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'PARABÉNS!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VOCÊ ALCANÇOU O ANDAR ${ScoreConfig.SCORE_TIER_TRANSICAO}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pontuação Salva
                  _buildInfoCard(
                    icon: Icons.save_alt,
                    iconColor: Colors.green.shade400,
                    title: '🏆 PONTUAÇÃO FINAL SALVA',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seu score foi registrado no ranking como:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade400,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber.shade300,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${ScoreConfig.SCORE_PONTOS_GARANTIDOS_TIER_11} PONTOS GARANTIDOS',
                                style: TextStyle(
                                  color: Colors.amber.shade300,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Reset de Score
                  _buildInfoCard(
                    icon: Icons.refresh,
                    iconColor: Colors.orange.shade400,
                    title: '⚠️ RESET DE SCORE',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ao entrar no andar 11, seu score voltará para:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.shade400,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$scoreAtual',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.red.shade400,
                                  decorationThickness: 3,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white70,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '0',
                                style: TextStyle(
                                  color: Colors.orange.shade300,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'pontos',
                                  style: TextStyle(
                                    color: Colors.orange.shade200,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade200,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mas não se preocupe! Os ${ScoreConfig.SCORE_PONTOS_GARANTIDOS_TIER_11} pontos já estão salvos no ranking!',
                                  style: TextStyle(
                                    color: Colors.blue.shade100,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Novo Sistema
                  _buildInfoCard(
                    icon: Icons.auto_awesome,
                    iconColor: Colors.purple.shade300,
                    title: '✨ NOVO SISTEMA DE PONTUAÇÃO',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'A partir do andar 11:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBulletPoint(
                          '• Cada vitória = +${ScoreConfig.SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS} pontos extras',
                          Colors.green.shade300,
                        ),
                        _buildBulletPoint(
                          '• Esses pontos extras podem ultrapassar os ${ScoreConfig.SCORE_PONTOS_GARANTIDOS_TIER_11}',
                          Colors.blue.shade300,
                        ),
                        _buildBulletPoint(
                          '• Limite total: ${ScoreConfig.SCORE_LIMITE_MAXIMO_TOTAL} pontos (${ScoreConfig.SCORE_PONTOS_GARANTIDOS_TIER_11} garantidos + ${ScoreConfig.scoreMaximoExtras} extras)',
                          Colors.amber.shade300,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mensagem motivacional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade700.withOpacity(0.5),
                          Colors.blue.shade700.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          color: Colors.purple.shade200,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Boa sorte no endgame! 🚀',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botão
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade400,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    'VAMOS LÁ! 🚀',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
