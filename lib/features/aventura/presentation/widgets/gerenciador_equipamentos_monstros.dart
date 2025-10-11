import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/monstro_aventura.dart';

/// Widget componentizado para gerenciar equipamentos dos monstros
/// Exibe um grid de 3 monstros com seus equipamentos e permite selecionar um deles
///
/// Usado em:
/// - Modal de Recompensas de Batalha
/// - Casa do Vigarista (em breve)
/// - Qualquer lugar que precise selecionar um monstro para equipar algo
class GerenciadorEquipamentosMonstros extends StatelessWidget {
  /// Lista de monstros disponíveis (geralmente os 3 do time)
  final List<MonstroAventura> monstros;

  /// Monstro atualmente selecionado
  final MonstroAventura? monstroSelecionado;

  /// Cor de destaque para o monstro selecionado
  final Color corDestaque;

  /// Callback quando um monstro é selecionado
  final ValueChanged<MonstroAventura> onSelecionarMonstro;

  /// Callback quando clica no ícone do equipamento (mochila)
  /// Se null, não mostra o ícone de equipamento
  final ValueChanged<Item>? onVisualizarEquipamento;

  const GerenciadorEquipamentosMonstros({
    super.key,
    required this.monstros,
    required this.monstroSelecionado,
    required this.corDestaque,
    required this.onSelecionarMonstro,
    this.onVisualizarEquipamento,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monstros.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final monstro = monstros[index];
        final selecionado = monstroSelecionado == monstro;
        return GestureDetector(
          onTap: () => onSelecionarMonstro(monstro),
          child: _buildMonstroCard(monstro, selecionado),
        );
      },
    );
  }

  Widget _buildMonstroCard(MonstroAventura monstro, bool selecionado) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selecionado
            ? corDestaque.withOpacity(0.2)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selecionado ? corDestaque : Colors.grey.shade300,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Imagem do monstro e informações
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        monstro.imagem,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.catching_pokemon,
                          color: corDestaque,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    monstro.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Lv. ${monstro.level}',
                    style: TextStyle(
                      fontSize: 10,
                      color: corDestaque,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Seção da mochila (equipamento)
          if (monstro.itemEquipado != null)
            GestureDetector(
              onTap: onVisualizarEquipamento != null
                  ? () => onVisualizarEquipamento!(monstro.itemEquipado!)
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.backpack,
                  color: monstro.itemEquipado!.raridade.cor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
