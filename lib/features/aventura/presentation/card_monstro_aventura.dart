import 'package:flutter/material.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/item.dart';

class CardMonstroAventura extends StatelessWidget {
  final String imagem;
  final Tipo tipo;
  final Tipo tipoExtra;
  final int vida;
  final int energia;
  final int agilidade;
  final int ataque;
  final int defesa;
  final Item? itemEquipado;
  final VoidCallback? onTap;

  const CardMonstroAventura({
    super.key,
    required this.imagem,
    required this.tipo,
    required this.tipoExtra,
    required this.vida,
    required this.energia,
    required this.agilidade,
    required this.ataque,
    required this.defesa,
    this.itemEquipado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        height: 210,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tipo.cor.withOpacity(0.7), Colors.white.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: tipo.cor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: tipo.cor, width: 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tipo.cor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: tipo.cor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagem,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: tipo.cor.withOpacity(0.3),
                      child: Icon(
                        Icons.pets,
                        color: tipo.cor,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Image.asset(tipo.iconAsset, width: 32, height: 32, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Image.asset(tipoExtra.iconAsset, width: 32, height: 32, fit: BoxFit.contain),
                Spacer(),
                GestureDetector(
                  onTap: itemEquipado != null
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Item Equipado'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(itemEquipado!.nome, style: TextStyle(fontWeight: FontWeight.bold, color: itemEquipado!.raridade.cor)),
                                  const SizedBox(height: 8),
                                  Text('Raridade: ${itemEquipado!.raridade.nome}', style: TextStyle(color: itemEquipado!.raridade.cor)),
                                  const SizedBox(height: 8),
                                  ...itemEquipado!.atributos.entries.map((e) => Text('${e.key}: +${e.value}', style: const TextStyle(fontSize: 14))),
                                  const SizedBox(height: 8),
                                  Text('Obtido em: ${itemEquipado!.dataObtencao.toString().substring(0, 19)}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                  child: Icon(
                    Icons.backpack,
                    color: itemEquipado != null ? itemEquipado!.raridade.cor : Colors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
            if (itemEquipado != null) ...[
              const SizedBox(height: 6),
              Text(
                itemEquipado!.nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: itemEquipado!.raridade.cor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 22),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('$vida', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (itemEquipado != null && (itemEquipado!.atributos['vida'] ?? 0) > 0)
                          Text(' (+${itemEquipado!.atributos['vida']})', style: TextStyle(color: itemEquipado!.raridade.cor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Column(
                  children: [
                    Icon(Icons.flash_on, color: Colors.blue, size: 22),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('$energia', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (itemEquipado != null && (itemEquipado!.atributos['energia'] ?? 0) > 0)
                          Text(' (+${itemEquipado!.atributos['energia']})', style: TextStyle(color: itemEquipado!.raridade.cor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Column(
                  children: [
                    Icon(Icons.speed, color: Colors.green, size: 22),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('$agilidade', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (itemEquipado != null && (itemEquipado!.atributos['agilidade'] ?? 0) > 0)
                          Text(' (+${itemEquipado!.atributos['agilidade']})', style: TextStyle(color: itemEquipado!.raridade.cor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('$ataque', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (itemEquipado != null && (itemEquipado!.atributos['ataque'] ?? 0) > 0)
                          Text(' (+${itemEquipado!.atributos['ataque']})', style: TextStyle(color: itemEquipado!.raridade.cor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Column(
                  children: [
                    Icon(Icons.security, color: Colors.purple, size: 22),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('$defesa', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (itemEquipado != null && (itemEquipado!.atributos['defesa'] ?? 0) > 0)
                          Text(' (+${itemEquipado!.atributos['defesa']})', style: TextStyle(color: itemEquipado!.raridade.cor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}
