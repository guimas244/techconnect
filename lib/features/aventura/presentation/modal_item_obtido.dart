import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../models/item.dart';
import '../models/monstro_aventura.dart';
import 'widgets/gerenciador_equipamentos_monstros.dart';

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
            Text(
              'Selecione um monstro para equipar:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            GerenciadorEquipamentosMonstros(
              monstros: widget.monstrosDisponiveis,
              monstroSelecionado: monstroSelecionado,
              corDestaque: widget.item.raridade.cor,
              onSelecionarMonstro: (monstro) {
                setState(() {
                  monstroSelecionado = monstro;
                });
              },
              onVisualizarEquipamento: _mostrarDetalhesItem,
            ),
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
              // Não faz pop aqui, o callback já fecha o modal
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

  void _mostrarDetalhesItem(Item item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.raridade.cor, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagem da armadura
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.raridade.cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: item.raridade.cor, width: 2),
                ),
                child: Image.asset(
                  _getImagemArmadura(item),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.shield,
                    color: item.raridade.cor,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.nome,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${item.raridade.nome} - Tier ${item.tier}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bônus:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...item.atributos.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_right, size: 16, color: item.raridade.cor),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.key}: +${entry.value}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
