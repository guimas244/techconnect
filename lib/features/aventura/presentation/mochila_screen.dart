import 'package:flutter/material.dart';
import '../models/item_consumivel.dart';
import 'modal_item_consumivel.dart';

class MochilaScreen extends StatefulWidget {
  const MochilaScreen({super.key});

  @override
  State<MochilaScreen> createState() => _MochilaScreenState();
}

class _MochilaScreenState extends State<MochilaScreen> {
  // Tamanho da mochila (6x5 = 30 slots)
  static const int colunas = 6;
  static const int linhas = 5;
  static const int totalSlots = colunas * linhas;

  // Lista de itens (futuramente virá do provider/repository)
  late List<ItemConsumivel?> itens;

  @override
  void initState() {
    super.initState();
    _initializeMochila();
  }

  void _initializeMochila() {
    // Inicializa mochila vazia
    itens = List.filled(totalSlots, null);

    // Adiciona itens de exemplo (usando ícones do Material Design)
    itens[0] = const ItemConsumivel(
      id: 'pocao_vida_1',
      nome: 'Poção de Vida',
      descricao: 'Restaura 50 pontos de vida de um monstro aliado. '
          'Útil em momentos críticos durante batalhas difíceis.',
      tipo: TipoItemConsumivel.pocao,
      iconPath: '', // Usará ícone do Material Design
      quantidade: 3,
      raridade: RaridadeConsumivel.comum,
    );

    itens[1] = const ItemConsumivel(
      id: 'joia_poder_1',
      nome: 'Joia de Poder',
      descricao: 'Aumenta permanentemente +5 de ataque em um monstro. '
          'Esta gema rara contém energia cristalizada que fortalece o portador.',
      tipo: TipoItemConsumivel.joia,
      iconPath: '', // Usará ícone do Material Design
      quantidade: 1,
      raridade: RaridadeConsumivel.epico,
    );

    itens[5] = const ItemConsumivel(
      id: 'elixir_mana_1',
      nome: 'Elixir Arcano',
      descricao: 'Restaura completamente a energia de um monstro. '
          'Preparado com ingredientes místicos raros.',
      tipo: TipoItemConsumivel.elixir,
      iconPath: '', // Usará ícone do Material Design
      quantidade: 2,
      raridade: RaridadeConsumivel.raro,
    );

    itens[8] = const ItemConsumivel(
      id: 'joia_defesa_1',
      nome: 'Joia da Fortaleza',
      descricao: 'Aumenta permanentemente +5 de defesa em um monstro. '
          'Cristal endurecido que oferece proteção superior.',
      tipo: TipoItemConsumivel.joia,
      iconPath: '', // Usará ícone do Material Design
      quantidade: 1,
      raridade: RaridadeConsumivel.raro,
    );

    itens[12] = const ItemConsumivel(
      id: 'pocao_vida_super_1',
      nome: 'Super Poção de Vida',
      descricao: 'Restaura completamente a vida de um monstro. '
          'A poção definitiva para emergências.',
      tipo: TipoItemConsumivel.pocao,
      iconPath: '', // Usará ícone do Material Design
      quantidade: 1,
      raridade: RaridadeConsumivel.lendario,
    );
  }

  void _mostrarDetalhesItem(ItemConsumivel item, int index) {
    showDialog(
      context: context,
      builder: (context) => ModalItemConsumivel(
        item: item,
        onUsar: () {
          _usarItem(index);
        },
        onDescartar: () {
          _descartarItem(index);
        },
      ),
    );
  }

  void _usarItem(int index) {
    setState(() {
      final item = itens[index];
      if (item != null) {
        if (item.quantidade > 1) {
          // Diminui quantidade
          itens[index] = item.copyWith(quantidade: item.quantidade - 1);
        } else {
          // Remove item
          itens[index] = null;
        }
      }
    });

    // Mostrar mensagem de uso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${itens[index]?.nome ?? "Item"} usado com sucesso!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _descartarItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Descarte'),
        content: Text('Deseja realmente descartar ${itens[index]?.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                itens[index] = null;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item descartado'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Conta quantos slots estão ocupados
    final itensOcupados = itens.where((item) => item != null).length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.brown.shade900.withOpacity(0.95),
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: Colors.brown.shade700,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                // Ícone da mochila
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade800,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.brown.shade600,
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/icons_gerais/mochila.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.backpack,
                        size: 32,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Título e contagem
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MOCHILA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itensOcupados / $totalSlots slots ocupados',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown.shade300,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão de organizar (futuro)
                IconButton(
                  onPressed: () {
                    // Organizar itens (implementar futuramente)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Função de organizar em breve!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sort),
                  color: Colors.white70,
                  tooltip: 'Organizar itens',
                ),
              ],
            ),
          ),

          // Grid de itens
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: colunas,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: totalSlots,
                itemBuilder: (context, index) {
                  final item = itens[index];
                  return _buildSlot(item, index);
                },
              ),
            ),
          ),

          // Legenda de raridades
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              border: Border(
                top: BorderSide(
                  color: Colors.brown.shade700,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendaRaridade(RaridadeConsumivel.comum),
                const SizedBox(width: 16),
                _buildLegendaRaridade(RaridadeConsumivel.raro),
                const SizedBox(width: 16),
                _buildLegendaRaridade(RaridadeConsumivel.epico),
                const SizedBox(width: 16),
                _buildLegendaRaridade(RaridadeConsumivel.lendario),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(ItemConsumivel? item, int index) {
    final isEmpty = item == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty ? null : () => _mostrarDetalhesItem(item, index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isEmpty
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEmpty
                  ? Colors.brown.shade800.withOpacity(0.5)
                  : item.raridade.cor,
              width: isEmpty ? 1 : 2,
            ),
            boxShadow: isEmpty
                ? null
                : [
                    BoxShadow(
                      color: item.raridade.cor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: isEmpty
              ? Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.brown.shade800.withOpacity(0.3),
                    size: 20,
                  ),
                )
              : Stack(
                  children: [
                    // Ícone do item
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: item.iconPath.isEmpty
                            ? Icon(
                                _getIconForType(item.tipo),
                                size: 30,
                                color: item.raridade.cor,
                              )
                            : Image.asset(
                                item.iconPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getIconForType(item.tipo),
                                    size: 30,
                                    color: item.raridade.cor,
                                  );
                                },
                              ),
                      ),
                    ),

                    // Badge de quantidade
                    if (item.quantidade > 1)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.raridade.cor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${item.quantidade}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.raridade.cor,
                            ),
                          ),
                        ),
                      ),

                    // Ícone de tipo (canto superior esquerdo)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(item.tipo),
                          size: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLegendaRaridade(RaridadeConsumivel raridade) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: raridade.cor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: raridade.cor.withOpacity(0.5),
            blurRadius: 4,
          ),
        ],
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
    }
  }
}