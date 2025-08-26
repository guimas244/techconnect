import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../models/item.dart';

class ModalDetalheItemEquipado extends StatelessWidget {
  final Item item;

  const ModalDetalheItemEquipado({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [item.raridade.cor.withOpacity(0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backpack, color: item.raridade.cor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.nome,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: item.raridade.cor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Nível: ${item.raridade.nome}',
              style: TextStyle(
                fontSize: 16,
                color: item.raridade.cor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Atributos aumentados:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            ...item.atributos.entries.map((entry) => _buildAtributoLinha(entry.key, entry.value)),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtributoLinha(String atributo, int valor) {
    IconData icon;
    Color cor;
    String nome;
    switch (atributo) {
      case 'vida':
        icon = Remix.heart_fill;
        cor = Colors.red;
        nome = 'Vida';
        break;
      case 'energia':
        icon = Remix.flashlight_fill;
        cor = Colors.blue;
        nome = 'Energia';
        break;
      case 'ataque':
        icon = Remix.sword_fill;
        cor = Colors.orange;
        nome = 'Ataque';
        break;
      case 'defesa':
        icon = Remix.shield_fill;
        cor = Colors.green;
        nome = 'Defesa';
        break;
      case 'agilidade':
        icon = Remix.speed_fill;
        cor = Colors.purple;
        nome = 'Agilidade';
        break;
      default:
        icon = Remix.star_fill;
        cor = Colors.grey;
        nome = atributo;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 22),
          const SizedBox(width: 10),
          Text(
            nome,
            style: TextStyle(fontWeight: FontWeight.w600, color: cor, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            '+$valor',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
