import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../models/magia_drop.dart';

/// Card reutilizável para exibir informações de uma magia
/// Usado na compra individual e na biblioteca
class CardMagiaSelecao extends StatelessWidget {
  final MagiaDrop magia;
  final bool selecionada;
  final Color? corDestaque;
  final VoidCallback? onTap;
  final Widget? acaoExtra; // Botão de compra ou outro widget customizado

  const CardMagiaSelecao({
    super.key,
    required this.magia,
    this.selecionada = false,
    this.corDestaque,
    this.onTap,
    this.acaoExtra,
  });

  @override
  Widget build(BuildContext context) {
    final cor = corDestaque ?? _getCorTipoMagia();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionada ? cor.withOpacity(0.15) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionada ? cor : Colors.grey.shade300,
            width: selecionada ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primeira linha: ícone + nome + level
            Row(
              children: [
                Image.asset(
                  _getImagemTipoMagia(),
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: cor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    magia.nome,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selecionada ? cor : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Lv. ${magia.level}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Segunda linha: informações da magia
            Row(
              children: [
                // Valor (dano/cura/bônus)
                Expanded(
                  child: _buildInfoMagia(),
                ),
                const SizedBox(width: 12),
                // Custo de energia
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Remix.flashlight_fill, size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${magia.custoEnergia}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Terceira linha: descrição do efeito
            const SizedBox(height: 6),
            Text(
              _getDescricaoEfeito(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Ação extra (se fornecida)
            if (acaoExtra != null) ...[
              const SizedBox(height: 10),
              acaoExtra!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMagia() {
    final tipo = magia.tipo.toString().toLowerCase();
    final valorCalculado = magia.valor * magia.level;

    String label;
    IconData icon;
    Color cor;

    if (tipo.contains('ofensiv') || tipo.contains('dano')) {
      label = 'Dano';
      icon = Remix.sword_fill;
      cor = Colors.red.shade600;
    } else if (tipo.contains('cura')) {
      label = 'Cura';
      icon = Remix.heart_fill;
      cor = Colors.pink.shade600;
    } else if (tipo.contains('suporte') || tipo.contains('buff')) {
      label = 'Bônus';
      icon = Remix.shield_star_fill;
      cor = Colors.green.shade600;
    } else {
      label = 'Valor';
      icon = Remix.star_fill;
      cor = Colors.amber.shade600;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cor),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          '$valorCalculado',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  String _getDescricaoEfeito() {
    final efeito = magia.efeito.toString().toLowerCase();

    if (efeito.contains('dano') || efeito.contains('ataque')) {
      return 'Causa dano ao inimigo';
    } else if (efeito.contains('cura') || efeito.contains('vida')) {
      return 'Restaura vida';
    } else if (efeito.contains('defesa') || efeito.contains('escudo')) {
      return 'Aumenta defesa';
    } else if (efeito.contains('ataque') && efeito.contains('buff')) {
      return 'Aumenta ataque';
    } else if (efeito.contains('velocidade') || efeito.contains('agilidade')) {
      return 'Aumenta agilidade';
    } else if (efeito.contains('energia')) {
      return 'Restaura energia';
    } else {
      return magia.descricao.length > 50
          ? '${magia.descricao.substring(0, 47)}...'
          : magia.descricao;
    }
  }

  Color _getCorTipoMagia() {
    final tipo = magia.tipo.toString().toLowerCase();
    if (tipo.contains('ofensiv')) return Colors.red.shade700;
    if (tipo.contains('cura')) return Colors.pink.shade700;
    if (tipo.contains('suporte')) return Colors.green.shade700;
    return Colors.purple.shade700;
  }

  String _getImagemTipoMagia() {
    final tipo = magia.tipo.toString().toLowerCase();
    if (tipo.contains('ofensiv')) {
      return 'assets/icons_gerais/magia_ofensiva.png';
    } else if (tipo.contains('cura')) {
      return 'assets/icons_gerais/magia_cura.png';
    } else if (tipo.contains('suporte')) {
      return 'assets/icons_gerais/magia_suporte.png';
    } else {
      return 'assets/icons_gerais/magia.png';
    }
  }
}
