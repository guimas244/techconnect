import 'package:flutter/material.dart';
import '../../../shared/models/tipo_enum.dart';

class ModalNutyNegraUtilizada extends StatelessWidget {
  final Tipo tipoSorteado;
  final VoidCallback onContinuar;

  const ModalNutyNegraUtilizada({
    super.key,
    required this.tipoSorteado,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.shade800,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com ícone e título
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Column(
                children: [
                  // Ícone da fruta
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.shade800,
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      'assets/drops/drop_fruta_nuty_negra.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.apple,
                          size: 50,
                          color: Colors.purple.shade800,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Título
                  Text(
                    'FRUTA NUTY NEGRA UTILIZADA!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Badge de kills
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade800,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '+10 KILLS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corpo com tipo sorteado
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Ícone do tipo
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tipoSorteado.cor,
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      _getImagemTipo(tipoSorteado),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          tipoSorteado.icone,
                          size: 60,
                          color: tipoSorteado.cor,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Nome do tipo
                  Text(
                    tipoSorteado.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: tipoSorteado.cor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 15),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 15),

                  // Mensagem
                  Text(
                    'Você ganhou +10 kills de ${tipoSorteado.displayName}!\nOs kills foram adicionados ao progresso diário.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Botão de continuar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  String _getImagemTipo(Tipo tipo) {
    final tipoNome = tipo.name.toLowerCase();
    return 'assets/tipagens/icon_tipo_$tipoNome.png';
  }
}
