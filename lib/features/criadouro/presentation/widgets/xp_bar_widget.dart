import 'package:flutter/material.dart';
import '../../models/level_tipo.dart';

/// Widget que exibe a barra de XP e level do mascote
class XpBarWidget extends StatelessWidget {
  final LevelTipo nivel;
  final bool mostrarDetalhes;

  const XpBarWidget({
    super.key,
    required this.nivel,
    this.mostrarDetalhes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.purple.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level e estrelas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLevelBadge(),
              if (mostrarDetalhes) ...[
                const SizedBox(width: 8),
                _buildStars(),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Barra de XP
          _buildXpBar(),

          // Valores de XP
          if (mostrarDetalhes) ...[
            const SizedBox(height: 4),
            _buildXpText(),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Lv ${nivel.level}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars() {
    // Mostra estrelas baseado no level (1-5 estrelas por "tier")
    final starsInTier = ((nivel.level - 1) % 5) + 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < starsInTier ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildXpBar() {
    return Column(
      children: [
        // Barra de progresso
        Stack(
          children: [
            // Background
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Progresso
            FractionallySizedBox(
              widthFactor: nivel.progressoXp.clamp(0.0, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            // Texto centralizado
            Positioned.fill(
              child: Center(
                child: Text(
                  '${nivel.xpAtual}/${nivel.xpParaProximoLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildXpText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'XP',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
        Text(
          'Faltam ${nivel.xpFaltando} XP',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Widget compacto de XP para mostrar em cards de seleção
class XpBarCompact extends StatelessWidget {
  final LevelTipo nivel;

  const XpBarCompact({
    super.key,
    required this.nivel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.amber,
            size: 10,
          ),
          const SizedBox(width: 2),
          Text(
            'Lv${nivel.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
