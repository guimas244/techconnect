import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/item_consumivel.dart';

class ModalItemConsumivel extends StatefulWidget {
  final ItemConsumivel item;
  final VoidCallback? onUsar;
  final void Function(int quantidade)? onUsarComQuantidade;
  final VoidCallback? onDescartar;

  const ModalItemConsumivel({
    super.key,
    required this.item,
    this.onUsar,
    this.onUsarComQuantidade,
    this.onDescartar,
  });

  @override
  State<ModalItemConsumivel> createState() => _ModalItemConsumivelState();
}

class _ModalItemConsumivelState extends State<ModalItemConsumivel> {
  int _quantidadeSelecionada = 1;
  final TextEditingController _quantidadeController = TextEditingController(text: '1');

  bool get _mostrarSeletorQuantidade =>
      widget.item.tipo == TipoItemConsumivel.ovoEvento ||
      widget.item.tipo == TipoItemConsumivel.moedaChave;

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  void _atualizarQuantidade(int novaQuantidade) {
    final max = widget.item.quantidade;
    final valorFinal = novaQuantidade.clamp(1, max);
    setState(() {
      _quantidadeSelecionada = valorFinal;
      _quantidadeController.text = valorFinal.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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

            // Seletor de quantidade (para ovo de evento e moeda chave)
            if (_mostrarSeletorQuantidade && item.quantidade > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.amber.shade200, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Quantidade a usar (máx: ${item.quantidade})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botão diminuir
                        IconButton(
                          onPressed: _quantidadeSelecionada > 1
                              ? () => _atualizarQuantidade(_quantidadeSelecionada - 1)
                              : null,
                          icon: const Icon(Icons.remove_circle),
                          color: Colors.amber.shade700,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 8),
                        // Campo de texto para quantidade
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _quantidadeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) {
                                _atualizarQuantidade(parsed);
                              }
                            },
                            onSubmitted: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null) {
                                _atualizarQuantidade(parsed);
                              } else {
                                _atualizarQuantidade(1);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botão aumentar
                        IconButton(
                          onPressed: _quantidadeSelecionada < item.quantidade
                              ? () => _atualizarQuantidade(_quantidadeSelecionada + 1)
                              : null,
                          icon: const Icon(Icons.add_circle),
                          color: Colors.amber.shade700,
                          iconSize: 32,
                        ),
                        const SizedBox(width: 8),
                        // Botão MAX
                        ElevatedButton(
                          onPressed: () => _atualizarQuantidade(item.quantidade),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'MAX',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

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
                  if (widget.onDescartar != null)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDescartar?.call();
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

                  if (widget.onDescartar != null && (widget.onUsar != null || widget.onUsarComQuantidade != null))
                    const SizedBox(width: 12),

                  // Botão Usar (com quantidade se aplicável)
                  if (widget.onUsar != null || widget.onUsarComQuantidade != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (_mostrarSeletorQuantidade && widget.onUsarComQuantidade != null) {
                            widget.onUsarComQuantidade!(_quantidadeSelecionada);
                          } else {
                            widget.onUsar?.call();
                          }
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
                        child: Text(
                          _mostrarSeletorQuantidade && item.quantidade > 1
                              ? 'USAR $_quantidadeSelecionada'
                              : 'USAR',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Botão Fechar (se não tem ações)
                  if (widget.onUsar == null && widget.onUsarComQuantidade == null && widget.onDescartar == null)
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
      case TipoItemConsumivel.fruta:
        return Icons.apple;
      case TipoItemConsumivel.vidinha:
        return Icons.favorite;
      case TipoItemConsumivel.pergaminho:
        return Icons.article;
      case TipoItemConsumivel.elixir:
        return Icons.science;
      case TipoItemConsumivel.fragmento:
        return Icons.broken_image;
      case TipoItemConsumivel.moedaEvento:
      case TipoItemConsumivel.moedaHalloween:
        return Icons.stars;
      case TipoItemConsumivel.moedaChave:
        return Icons.key;
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
      case TipoItemConsumivel.fruta:
        return 'Fruta';
      case TipoItemConsumivel.vidinha:
        return 'Vidinha';
      case TipoItemConsumivel.pergaminho:
        return 'Pergaminho';
      case TipoItemConsumivel.elixir:
        return 'Elixir';
      case TipoItemConsumivel.fragmento:
        return 'Fragmento';
      case TipoItemConsumivel.moedaEvento:
        return 'Moeda de Evento';
      case TipoItemConsumivel.moedaHalloween:
        return 'Moeda de Halloween';
      case TipoItemConsumivel.moedaChave:
        return 'Moeda Chave';
      case TipoItemConsumivel.ovoEvento:
        return 'Ovo do Evento';
    }
  }
}