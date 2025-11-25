import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../models/item.dart';

/// Modal do Feirão - exibe 3 itens para o jogador escolher e comprar
/// Cada item custa custoAposta adicional
class ModalFeirao extends StatefulWidget {
  final List<Item> itens;
  final int custoAposta;
  final int scoreAtual;

  const ModalFeirao({
    super.key,
    required this.itens,
    required this.custoAposta,
    required this.scoreAtual,
  });

  @override
  State<ModalFeirao> createState() => _ModalFeiraoState();
}

class _ModalFeiraoState extends State<ModalFeirao> {
  bool _comprando = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a3e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade700, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade700.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                ),
              ),
              child: Row(
                children: [
                  Icon(Remix.store_2_fill, color: Colors.amber.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Feirão',
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
                'Escolha um item para comprar por ${widget.custoAposta} pontos',
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  color: Colors.grey.shade300,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Grid de itens (com scroll)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: widget.itens.map((item) => _buildItemCard(context, item)).toList(),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
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

  Future<void> _comprarItem(Item item) async {
    setState(() => _comprando = true);

    try {
      // Aguarda para mostrar o loading
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(item);
      }
    } catch (e) {
      print('❌ [Feirão] Erro ao comprar item: $e');
      if (mounted) {
        setState(() => _comprando = false);
      }
    }
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    final podeComprar = widget.scoreAtual >= widget.custoAposta;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.raridade.cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.raridade.cor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagem da armadura
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.raridade.cor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.raridade.cor, width: 1.5),
              ),
              child: Image.asset(
                _getImagemArmadura(item),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.shield,
                  color: item.raridade.cor,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Informações do item
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    item.nome,
                    style: GoogleFonts.cinzel(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: item.raridade.cor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Raridade e tier
                  Text(
                    '${item.raridade.nome} - Tier ${item.tier}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Atributos (apenas ícones)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.atributos.entries.map((entry) {
                      return _buildAtributoIcon(entry.key, entry.value);
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Botão comprar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (podeComprar && !_comprando)
                          ? () => _comprarItem(item)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: podeComprar
                            ? item.raridade.cor
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
                            size: 16,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImagemArmadura(Item item) {
    final raridadeNome = item.raridade.nome.toLowerCase();
    switch (raridadeNome) {
      case 'inferior':
        return 'assets/armaduras/armadura_inferior.png';
      case 'normal':
        return 'assets/armaduras/armadura_normal.png';
      case 'rara':
        return 'assets/armaduras/armadura_rara.png';
      case 'épica':
      case 'epica':
        return 'assets/armaduras/armadura_epica.png';
      case 'lendária':
      case 'lendaria':
        return 'assets/armaduras/armadura_lendaria.png';
      case 'impossível':
      case 'impossivel':
        return 'assets/armaduras/armadura_impossivel.png';
      default:
        return 'assets/armaduras/armadura_normal.png';
    }
  }

  Widget _buildAtributoIcon(String atributo, int valor) {
    IconData icon;
    Color cor;

    switch (atributo) {
      case 'vida':
        icon = Remix.heart_fill;
        cor = Colors.red;
        break;
      case 'energia':
        icon = Remix.flashlight_fill;
        cor = Colors.blue;
        break;
      case 'ataque':
        icon = Remix.sword_fill;
        cor = Colors.orange;
        break;
      case 'defesa':
        icon = Remix.shield_fill;
        cor = Colors.green;
        break;
      case 'agilidade':
        icon = Remix.speed_fill;
        cor = Colors.purple;
        break;
      default:
        icon = Remix.star_fill;
        cor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cor, size: 14),
          const SizedBox(width: 3),
          Text(
            '+$valor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
