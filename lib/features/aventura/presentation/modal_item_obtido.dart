import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../models/item.dart';
import '../models/monstro_aventura.dart';

class ModalItemObtido extends StatefulWidget {
  final Item item;
  final List<MonstroAventura> monstrosDisponiveis;
  final Function(MonstroAventura, Item) onEquiparItem;

  const ModalItemObtido({
    super.key,
    required this.item,
    required this.monstrosDisponiveis,
    required this.onEquiparItem,
  });

  @override
  State<ModalItemObtido> createState() => _ModalItemObtidoState();
}

class _ModalItemObtidoState extends State<ModalItemObtido> {
  MonstroAventura? monstroSelecionado;
  bool isEquipando = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              widget.item.raridade.cor.withOpacity(0.2),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Remix.treasure_map_line,
                  color: widget.item.raridade.cor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Obtido!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Selecione um monstro para equipar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Informações do item
            _buildItemInfo(),
            const SizedBox(height: 20),

            // Lista de monstros para equipar
            _buildMonstroSelection(),
            const SizedBox(height: 20),

            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.item.raridade.cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.item.raridade.cor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Nome do item
          Text(
            widget.item.nome,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.item.raridade.cor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Raridade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: widget.item.raridade.cor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.item.raridade.nome,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Atributos
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.item.atributos.entries.map((entry) {
              return _buildAtributoChip(entry.key, entry.value);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAtributoChip(String atributo, int valor) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cor),
          const SizedBox(width: 4),
          Text(
            '${atributo.toUpperCase()}: +$valor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonstroSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipar em qual monstro?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.monstrosDisponiveis.length,
            itemBuilder: (context, index) {
              final monstro = widget.monstrosDisponiveis[index];
              final isSelected = monstroSelecionado == monstro;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    monstroSelecionado = monstro;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      // Imagem do monstro
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                monstro.tipo.cor.withOpacity(0.8),
                                Colors.white,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              monstro.imagem,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Nome do monstro
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          monstro.tipo.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botão Descartar
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isEquipando ? null : () {
              Navigator.of(context).pop();
            },
            child: const Text('Descartar'),
          ),
        ),
        const SizedBox(width: 16),
        // Botão Equipar
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: monstroSelecionado != null 
                  ? Colors.blue 
                  : Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: (monstroSelecionado != null && !isEquipando) ? () async {
              setState(() {
                isEquipando = true;
              });
              
              try {
                await widget.onEquiparItem(monstroSelecionado!, widget.item);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                print('❌ [ModalItemObtido] Erro ao equipar item: $e');
                if (mounted) {
                  setState(() {
                    isEquipando = false;
                  });
                  // Mostra um erro ou tenta novamente
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao equipar item. Tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } : null,
            child: isEquipando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Equipar'),
          ),
        ),
      ],
    );
  }
}
