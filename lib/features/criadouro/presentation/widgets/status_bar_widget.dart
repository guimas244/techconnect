import 'package:flutter/material.dart';

/// Widget de barra de status do mascote
class StatusBarWidget extends StatelessWidget {
  final String label;
  final String emoji;
  final double valor;
  final Color? corBarra;

  const StatusBarWidget({
    super.key,
    required this.label,
    required this.emoji,
    required this.valor,
    this.corBarra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Emoji
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          // Label
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Barra
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: valor / 100,
                minHeight: 16,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_getCorBarra()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Porcentagem
          SizedBox(
            width: 45,
            child: Text(
              '${valor.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getCorTexto(),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCorBarra() {
    if (corBarra != null) return corBarra!;
    if (valor <= 0) return Colors.black;
    if (valor < 30) return Colors.red;
    if (valor < 50) return Colors.orange;
    if (valor < 70) return Colors.yellow[700]!;
    return Colors.green;
  }

  Color _getCorTexto() {
    if (valor <= 0) return Colors.black;
    if (valor < 30) return Colors.red;
    if (valor < 50) return Colors.orange[800]!;
    return Colors.black87;
  }
}
