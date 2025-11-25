import 'package:flutter/material.dart';
import '../../models/mascote.dart';

/// Widget que exibe o mascote com seu status visual
class MascoteDisplayWidget extends StatelessWidget {
  final Mascote mascote;
  final double tamanho;

  const MascoteDisplayWidget({
    super.key,
    required this.mascote,
    this.tamanho = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Container do mascote
        Stack(
          alignment: Alignment.center,
          children: [
            // Imagem do monstro
            Container(
              width: tamanho,
              height: tamanho,
              decoration: BoxDecoration(
                color: _getCorFundo(),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getCorBorda(),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getCorBorda().withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.asset(
                  mascote.monstroId,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        '🐣',
                        style: TextStyle(fontSize: tamanho * 0.5),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Emoji de status no canto
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  mascote.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            // Indicador de doença
            if (mascote.estaDoente)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🤢', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4),
                      Text(
                        'DOENTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Indicador de estado crítico
            if (mascote.estaCritico)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('☠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        _tempoRestante(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Nome do mascote
        Text(
          mascote.nome,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Dias vivo
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📅 ', style: TextStyle(fontSize: 16)),
            Text(
              '${mascote.diasVivo} dias vivo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getCorFundo() {
    if (mascote.estaCritico) return Colors.red[50]!;
    if (mascote.estaDoente) return Colors.orange[50]!;
    if (mascote.status.name == 'feliz') return Colors.green[50]!;
    return Colors.grey[100]!;
  }

  Color _getCorBorda() {
    if (mascote.estaCritico) return Colors.red;
    if (mascote.estaDoente) return Colors.orange;
    if (mascote.status.name == 'feliz') return Colors.green;
    return Colors.grey[400]!;
  }

  String _tempoRestante() {
    final tempo = mascote.tempoAteMorrer;
    if (tempo == null) return '';
    final horas = tempo.inHours;
    final minutos = tempo.inMinutes % 60;
    return '${horas}h ${minutos}m';
  }
}
