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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [widget.item.raridade.cor.withOpacity(0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.backpack, color: widget.item.raridade.cor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.nome,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.item.raridade.cor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tier ${widget.item.tier}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Nível: ${widget.item.raridade.nome}',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.item.raridade.cor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            
            // Atributos
            Text(
              'Atributos aumentados:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.item.atributos.entries.map((entry) => _buildAtributoLinha(entry.key, entry.value)),
            
            const SizedBox(height: 18),

            // Monster selection
            _buildMonstroSelection(),
            const SizedBox(height: 18),

            // Action buttons
            _buildActionButtons(),
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
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
          'Selecione um monstro para equipar:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
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
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? widget.item.raridade.cor : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    gradient: isSelected ? LinearGradient(
                      colors: [
                        widget.item.raridade.cor.withOpacity(0.1),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : null,
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
                            color: monstro.tipo.cor.withOpacity(0.2),
                          ),
                          child: Center(
                            child: Image.asset(
                              monstro.imagem,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Nome do monstro
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          monstro.tipo.monsterName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? widget.item.raridade.cor : Colors.grey.shade700,
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botão Descartar
        TextButton.icon(
          onPressed: isEquipando ? null : () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
          label: const Text('Descartar'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 12),
        // Botão Equipar
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: monstroSelecionado != null 
                ? widget.item.raridade.cor
                : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao equipar item. Tente novamente.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } : null,
          icon: isEquipando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.backpack, size: 18),
          label: Text(isEquipando ? 'Equipando...' : 'Equipar'),
        ),
      ],
    );
  }
}
