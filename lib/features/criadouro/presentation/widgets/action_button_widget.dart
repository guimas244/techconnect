import 'package:flutter/material.dart';

/// Botão de ação do Criadouro
class ActionButtonWidget extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? badge; // Para mostrar quantidade disponível

  const ActionButtonWidget({
    super.key,
    required this.emoji,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: enabled ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          elevation: enabled ? 2 : 0,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 28,
                      color: enabled ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Badge de quantidade
        if (badge != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
