import 'package:flutter/material.dart';
import '../models/item_consumivel.dart';

class ModalItemConsumivel extends StatelessWidget {
  final ItemConsumivel item;
  final VoidCallback? onUsar;
  final VoidCallback? onDescartar;

  const ModalItemConsumivel({
    super.key,
    required this.item,
    this.onUsar,
    this.onDescartar,
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
            color: item.raridade.cor,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com ícone e nome
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
                  // Ícone do item
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.raridade.cor,
                        width: 2,
                      ),
                    ),
                    child: item.iconPath.isEmpty
                        ? Icon(
                            _getIconForType(item.tipo),
                            size: 60,
                            color: item.raridade.cor,
                          )
                        : Image.asset(
                            item.iconPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Se for ovo, usa a imagem JPEG sempre
                              if (item.tipo == TipoItemConsumivel.ovoEvento) {
                                return Image.asset(
                                  'assets/eventos/halloween/ovo_halloween.png',
                                  fit: BoxFit.contain,
                                );
                              }
                              return Icon(
                                _getIconForType(item.tipo),
                                size: 60,
                                color: item.raridade.cor,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 15),

                  // Nome do item
                  Text(
                    item.nome,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Raridade
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.raridade.cor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.raridade.nome.toUpperCase(),
                      style: const TextStyle(
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

            // Corpo com descrição
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo
                    Row(
                      children: [
                        Icon(
                          _getIconForType(item.tipo),
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tipo: ${_getTypeName(item.tipo)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 15),

                    // Descrição
                    Text(
                      'Descrição:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.descricao,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 15),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 15),

                    // Quantidade
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quantidade: ${item.quantidade}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Botões de ação
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Botão Descartar (apenas ícone)
                  if (onDescartar != null)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDescartar?.call();
                      },
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      iconSize: 28,
                      tooltip: 'Descartar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),

                  if (onDescartar != null && onUsar != null)
                    const SizedBox(width: 12),

                  // Botão Usar
                  if (onUsar != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onUsar?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.raridade.cor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'USAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Botão Fechar (se não tem ações)
                  if (onUsar == null && onDescartar == null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('FECHAR'),
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

  IconData _getIconForType(TipoItemConsumivel tipo) {
    switch (tipo) {
      case TipoItemConsumivel.pocao:
        return Icons.local_drink;
      case TipoItemConsumivel.joia:
        return Icons.diamond;
      case TipoItemConsumivel.pergaminho:
        return Icons.article;
      case TipoItemConsumivel.elixir:
        return Icons.science;
      case TipoItemConsumivel.fragmento:
        return Icons.broken_image;
      case TipoItemConsumivel.moedaEvento:
        return Icons.stars;
      case TipoItemConsumivel.ovoEvento:
        return Icons.egg;
    }
  }

  String _getTypeName(TipoItemConsumivel tipo) {
    switch (tipo) {
      case TipoItemConsumivel.pocao:
        return 'Poção';
      case TipoItemConsumivel.joia:
        return 'Joia';
      case TipoItemConsumivel.pergaminho:
        return 'Pergaminho';
      case TipoItemConsumivel.elixir:
        return 'Elixir';
      case TipoItemConsumivel.fragmento:
        return 'Fragmento';
      case TipoItemConsumivel.moedaEvento:
        return 'Moeda de Evento';
      case TipoItemConsumivel.ovoEvento:
        return 'Ovo do Evento';
    }
  }
}