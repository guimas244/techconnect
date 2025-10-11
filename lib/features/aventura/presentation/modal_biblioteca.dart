import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../models/magia_drop.dart';
import 'widgets/card_magia_selecao.dart';

/// Modal da Biblioteca - exibe 3 magias para o jogador escolher e comprar
/// Cada magia custa custoAposta adicional
class ModalBiblioteca extends StatefulWidget {
  final List<MagiaDrop> magias;
  final int custoAposta;
  final int scoreAtual;

  const ModalBiblioteca({
    super.key,
    required this.magias,
    required this.custoAposta,
    required this.scoreAtual,
  });

  @override
  State<ModalBiblioteca> createState() => _ModalBibliotecaState();
}

class _ModalBibliotecaState extends State<ModalBiblioteca> {
  bool _comprando = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a3e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2a9d8f), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a9d8f).withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Remix.book_open_fill, color: const Color(0xFF2a9d8f), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Biblioteca',
                            style: GoogleFonts.cinzel(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Remix.coin_fill, color: Colors.amber.shade300, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.scoreAtual}',
                              style: GoogleFonts.cinzel(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Descrição
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Escolha uma magia para comprar por ${widget.custoAposta} pontos',
                    style: GoogleFonts.cinzel(
                      fontSize: 14,
                      color: Colors.grey.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Lista de magias (com scroll)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: widget.magias.map((magia) => _buildMagiaCard(context, magia)).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botão Sair
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.grey.shade700.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sair',
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_comprando)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2a9d8f)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processando compra...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _comprarMagia(MagiaDrop magia) async {
    setState(() => _comprando = true);

    try {
      // Aguarda para mostrar o loading
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(magia);
      }
    } catch (e) {
      print('❌ [Biblioteca] Erro ao comprar magia: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  Widget _buildMagiaCard(BuildContext context, MagiaDrop magia) {
    final podeComprar = widget.scoreAtual >= widget.custoAposta;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CardMagiaSelecao(
        magia: magia,
        acaoExtra: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (podeComprar && !_comprando)
                ? () => _comprarMagia(magia)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: podeComprar
                  ? _getCorTipoMagia(magia)
                  : Colors.grey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  podeComprar ? Remix.coin_fill : Remix.close_circle_fill,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  podeComprar ? '${widget.custoAposta}' : 'Sem score',
                  style: GoogleFonts.cinzel(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCorTipoMagia(MagiaDrop magia) {
    final tipo = magia.tipo.toString().toLowerCase();
    if (tipo.contains('ofensiv')) return Colors.red.shade700;
    if (tipo.contains('cura')) return Colors.pink.shade700;
    if (tipo.contains('suporte')) return Colors.green.shade700;
    return Colors.purple.shade700;
  }
}
