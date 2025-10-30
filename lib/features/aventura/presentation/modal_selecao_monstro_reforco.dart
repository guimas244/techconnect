import 'package:flutter/material.dart';
import '../models/monstro_aventura.dart';

class ModalSelecaoMonstroReforco extends StatefulWidget {
  final List<MonstroAventura> monstrosDisponiveis;
  final int tierAtual;
  final Future<void> Function(MonstroAventura monstro) onReforcarItem;

  const ModalSelecaoMonstroReforco({
    super.key,
    required this.monstrosDisponiveis,
    required this.tierAtual,
    required this.onReforcarItem,
  });

  @override
  State<ModalSelecaoMonstroReforco> createState() => _ModalSelecaoMonstroReforcoState();
}

class _ModalSelecaoMonstroReforcoState extends State<ModalSelecaoMonstroReforco> {
  MonstroAventura? _monstroSelecionado;
  bool _processando = false;

  Color get _corDestaque => Colors.purple;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _corDestaque, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_fix_high, color: _corDestaque, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joia da Recriação',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recria equipamento com tier alto',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Descrição
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecione um monstro para recriar seu equipamento',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Texto "Escolha um monstro:"
            Text(
              'Escolha um monstro para equipar:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 12),

            // Grid de monstros (mesmo estilo do modal de recompensas)
            Expanded(
              child: _buildTimeJogadorGrid(
                selecionado: _monstroSelecionado,
                destaque: _corDestaque,
                onSelect: (monstro) {
                  setState(() {
                    _monstroSelecionado = monstro;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Botões
            Row(
              children: [
                IconButton(
                  onPressed: _processando
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!_processando && _monstroSelecionado != null)
                        ? () => _reforcarItem()
                        : null,
                    icon: _processando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(_processando ? 'Recriando...' : 'Recriar Equipamento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _corDestaque,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _corDestaque.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeJogadorGrid({
    required MonstroAventura? selecionado,
    required Color destaque,
    required ValueChanged<MonstroAventura> onSelect,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.monstrosDisponiveis.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final monstro = widget.monstrosDisponiveis[index];
        final selecionadoAtual = selecionado == monstro;
        return GestureDetector(
          onTap: () => onSelect(monstro),
          child: _buildMonstroCard(monstro, selecionadoAtual, destaque),
        );
      },
    );
  }

  Widget _buildMonstroCard(
    MonstroAventura monstro,
    bool selecionado,
    Color destaque,
  ) {
    final item = monstro.itemEquipado!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selecionado ? destaque.withOpacity(0.15) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selecionado ? destaque : Colors.grey.shade300,
          width: selecionado ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        children: [
          // Imagem do monstro e informações
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // Imagem
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        monstro.imagem,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.catching_pokemon,
                          color: destaque,
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Nome do monstro
                  Text(
                    monstro.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Item equipado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.raridade.cor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: item.raridade.cor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.backpack, size: 11, color: item.raridade.cor),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'T${item.tier}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.raridade.cor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Indicador de seleção
          if (selecionado)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: destaque,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reforcarItem() async {
    if (_monstroSelecionado == null) return;

    setState(() => _processando = true);

    try {
      await widget.onReforcarItem(_monstroSelecionado!);
      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao recriar: $e')),
        );
        setState(() => _processando = false);
      }
    }
  }
}
