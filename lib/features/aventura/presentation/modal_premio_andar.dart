import 'dart:math';

import 'package:flutter/material.dart';

/// Imagens disponíveis para Nuty (escolhida aleatoriamente)
const List<String> _imagensNuty = [
  'assets/drops/drop_fruta_nuty.png',
  'assets/drops/drop_fruta_nuty_cristalizada.png',
  'assets/drops/drop_fruta_nuty_negra.png',
];

String _getImagemNutyAleatoria() {
  return _imagensNuty[Random().nextInt(_imagensNuty.length)];
}

/// Tipo de recompensa disponível
enum TipoPremio {
  chaveAuto,
  nuty,
}

/// Informações sobre um prêmio
class InfoPremio {
  final TipoPremio tipo;
  final String nome;
  final String descricao;
  final String iconPath;
  final Color cor;
  final int quantidade;
  final int andarGanho;

  const InfoPremio({
    required this.tipo,
    required this.nome,
    required this.descricao,
    required this.iconPath,
    required this.cor,
    required this.quantidade,
    required this.andarGanho,
  });

  factory InfoPremio.chaveAuto(int andar) => InfoPremio(
        tipo: TipoPremio.chaveAuto,
        nome: 'Chave Auto',
        descricao: 'Ativa o modo automático por 2 andares!',
        iconPath: 'assets/eventos/halloween/chave_auto.png',
        cor: Colors.cyan,
        quantidade: 1,
        andarGanho: andar,
      );

  factory InfoPremio.nuty(int andar) => InfoPremio(
        tipo: TipoPremio.nuty,
        nome: 'Nuty',
        descricao: 'Moeda especial do Ganandius! Ganha 1 a cada 30 andares.',
        iconPath: _getImagemNutyAleatoria(),
        cor: Colors.amber,
        quantidade: 1,
        andarGanho: andar,
      );
}

/// Modal para exibir prêmio ganho ao atingir determinado andar
class ModalPremioAndar extends StatelessWidget {
  final InfoPremio premio;
  final VoidCallback onColetar;

  const ModalPremioAndar({
    super.key,
    required this.premio,
    required this.onColetar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: premio.cor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: premio.cor.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com estrelas
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: premio.cor.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Column(
                children: [
                  // Ícone de estrela
                  Icon(
                    Icons.star,
                    color: premio.cor,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RECOMPENSA!',
                    style: TextStyle(
                      color: premio.cor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Andar ${premio.andarGanho}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Corpo com item
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Ícone do prêmio com brilho
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: premio.cor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: premio.cor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          premio.iconPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            _getIconForType(premio.tipo),
                            color: premio.cor,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nome do item
                  Text(
                    premio.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (premio.quantidade > 1)
                    Text(
                      'x${premio.quantidade}',
                      style: TextStyle(
                        color: premio.cor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Descrição
                  Text(
                    premio.descricao,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Botão coletar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onColetar();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: premio.cor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'COLETAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(TipoPremio tipo) {
    switch (tipo) {
      case TipoPremio.chaveAuto:
        return Icons.vpn_key;
      case TipoPremio.nuty:
        return Icons.monetization_on;
    }
  }
}

/// Mostra o modal de prêmio e retorna quando o usuário coletar
Future<void> mostrarModalPremioAndar(
  BuildContext context,
  InfoPremio premio,
  VoidCallback onColetar,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ModalPremioAndar(
      premio: premio,
      onColetar: onColetar,
    ),
  );
}
