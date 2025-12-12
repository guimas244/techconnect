import 'package:flutter/material.dart';
import '../models/item_consumivel.dart';

/// Modal para exibir os drops coletados durante o modo Chave Auto
/// Permite ao jogador escolher quais itens equipar (máx 3)
class ModalChaveAutoDrops extends StatefulWidget {
  final List<ItemConsumivel> dropsDisponiveis;
  final Function(List<ItemConsumivel>) onConfirmar;

  const ModalChaveAutoDrops({
    super.key,
    required this.dropsDisponiveis,
    required this.onConfirmar,
  });

  @override
  State<ModalChaveAutoDrops> createState() => _ModalChaveAutoDropsState();
}

class _ModalChaveAutoDropsState extends State<ModalChaveAutoDrops> {
  final Set<int> _itensSelecionados = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueGrey.shade900,
              Colors.blueGrey.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyan.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vpn_key,
                      color: Colors.cyan,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo Auto Finalizado!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Selecione os itens para equipar',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de drops
            Flexible(
              child: widget.dropsDisponiveis.isEmpty
                  ? _buildSemDrops()
                  : _buildListaDrops(),
            ),

            // Botão confirmar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _itensSelecionados.isEmpty
                        ? 'Continuar sem itens'
                        : 'Equipar ${_itensSelecionados.length} ${_itensSelecionados.length == 1 ? 'item' : 'itens'}',
                    style: const TextStyle(
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

  Widget _buildSemDrops() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Colors.white38,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum item consumível foi encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaDrops() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.dropsDisponiveis.length,
      itemBuilder: (context, index) {
        final item = widget.dropsDisponiveis[index];
        final selecionado = _itensSelecionados.contains(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (selecionado) {
                _itensSelecionados.remove(index);
              } else {
                _itensSelecionados.add(index);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selecionado
                  ? Colors.cyan.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selecionado
                    ? Colors.cyan
                    : item.raridade.cor.withOpacity(0.5),
                width: selecionado ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Checkbox visual
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selecionado ? Colors.cyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selecionado ? Colors.cyan : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: selecionado
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),

                // Ícone do item
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.raridade.cor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.raridade.cor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      item.iconPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2,
                        color: item.raridade.cor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info do item
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nome,
                        style: TextStyle(
                          color: item.raridade.cor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.raridade.nome,
                        style: TextStyle(
                          color: item.raridade.cor.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantidade
                if (item.quantidade > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x${item.quantidade}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmar() {
    final itensSelecionados = _itensSelecionados
        .map((index) => widget.dropsDisponiveis[index])
        .toList();

    widget.onConfirmar(itensSelecionados);
    Navigator.of(context).pop();
  }
}

/// Mostra o modal de drops da Chave Auto
Future<List<ItemConsumivel>?> mostrarModalChaveAutoDrops(
  BuildContext context,
  List<ItemConsumivel> drops,
) async {
  List<ItemConsumivel>? resultado;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ModalChaveAutoDrops(
      dropsDisponiveis: drops,
      onConfirmar: (itens) {
        resultado = itens;
      },
    ),
  );

  return resultado;
}
