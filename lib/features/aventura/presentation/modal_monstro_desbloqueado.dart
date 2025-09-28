import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/monstro_inimigo.dart';
import '../../../shared/models/tipo_enum.dart';

class ModalMonstroDesbloqueado extends StatelessWidget {
  final MonstroInimigo monstroDesbloqueado;

  const ModalMonstroDesbloqueado({
    super.key,
    required this.monstroDesbloqueado,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade800,
              Colors.purple.shade900,
              Colors.black87,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AutoSizeText(
                    'MONSTRO DE COLEÇÃO DESBLOQUEADO!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    minFontSize: 12,
                    maxFontSize: 18,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 30,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Imagem do monstro
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.amber,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  color: Colors.white,
                  child: Image.asset(
                    monstroDesbloqueado.imagem,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nome do monstro
            AutoSizeText(
              monstroDesbloqueado.nome,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              minFontSize: 16,
              maxFontSize: 22,
              textAlign: TextAlign.center,
            ),

            // Tipo do monstro
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTipoChip(monstroDesbloqueado.tipo),
              ],
            ),

            const SizedBox(height: 20),

            // Mensagem de desbloqueio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                'Você desbloqueou um monstro raro da nova coleção!\n\nAgora você pode utiliza-lo em futuras aventuras!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 25),

            // Botão OK
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
              ),
              child: Text(
                'CONTINUAR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoChip(Tipo tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tipo.cor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        tipo.displayName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}