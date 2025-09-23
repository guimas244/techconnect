import 'package:flutter/material.dart';
import '../models/monstro_inimigo.dart';
import '../../../shared/models/habilidade_enum.dart';
import 'package:remixicon/remixicon.dart';
import 'modal_detalhe_item_equipado.dart';

class ModalMonstroInimigo extends StatelessWidget {
  final MonstroInimigo monstro;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final bool showBattleButton;
  final VoidCallback? onBattle;

  const ModalMonstroInimigo({
    super.key,
    required this.monstro,
    this.onClose,
    this.showCloseButton = true,
    this.showBattleButton = false,
    this.onBattle,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica se o monstro está morto
    final bool estaMorto = monstro.vidaAtual <= 0;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: estaMorto 
                ? [Colors.grey.withOpacity(0.8), Colors.white]
                : [monstro.tipo.cor.withOpacity(0.8), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com X de fechar (se showCloseButton for true)
            if (showCloseButton)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.black,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            if (showCloseButton) const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: estaMorto ? Colors.grey : monstro.tipo.cor, 
                      width: 3
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: estaMorto 
                            ? Colors.grey.withOpacity(0.3)
                            : monstro.tipo.cor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColorFiltered(
                      colorFilter: estaMorto
                          ? const ColorFilter.matrix([
                              0.2126, 0.7152, 0.0722, 0, 0, // Red
                              0.2126, 0.7152, 0.0722, 0, 0, // Green  
                              0.2126, 0.7152, 0.0722, 0, 0, // Blue
                              0,      0,      0,      1, 0, // Alpha
                            ])
                          : const ColorFilter.matrix([
                              1, 0, 0, 0, 0,
                              0, 1, 0, 0, 0,
                              0, 0, 1, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: Image.asset(
                        monstro.imagem,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: estaMorto 
                                ? Colors.grey.withOpacity(0.3)
                                : monstro.tipo.cor.withOpacity(0.3),
                            child: Icon(
                              Icons.pets,
                              color: estaMorto ? Colors.grey : monstro.tipo.cor,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              monstro.tipo.monsterName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: estaMorto ? Colors.grey : monstro.tipo.cor,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (estaMorto) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Remix.skull_fill,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(monstro.tipo.iconAsset, width: 32, height: 32, fit: BoxFit.contain),
                          const SizedBox(width: 8),
                          if (monstro.tipoExtra != null) 
                            Image.asset(monstro.tipoExtra!.iconAsset, width: 32, height: 32, fit: BoxFit.contain)
                          else
                            Container(width: 32, height: 32, color: Colors.transparent),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              Icon(
                                Icons.star,
                                color: estaMorto ? Colors.grey : Colors.amber,
                                size: 32,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: estaMorto ? Colors.grey : Colors.amber,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    '${monstro.level}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (monstro.itemEquipado != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _mostrarDetalheItem(context);
                              },
                              child: Stack(
                                children: [
                                  Icon(
                                    Icons.backpack,
                                    color: Colors.brown,
                                    size: 32,
                                  ),
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: monstro.itemEquipado!.raridade.cor,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: Text(
                                        '${monstro.itemEquipado!.tier}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Atributos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: monstro.tipo.cor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildVidaInfo(), // Nova função para mostrar vida atual/máxima
                      _buildAtributoInfo('Energia', monstro.energiaTotal, Remix.battery_charge_fill, Colors.blue),
                      _buildAtributoInfo('Agilidade', monstro.agilidadeTotal, Remix.run_fill, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAtributoInfo('Ataque', monstro.ataqueTotal, Remix.boxing_fill, Colors.orange),
                      _buildAtributoInfo('Defesa', monstro.defesaTotal, Remix.shield_cross_fill, Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Botão de Habilidades
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [monstro.tipo.cor, monstro.tipo.cor.withOpacity(0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: monstro.tipo.cor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _mostrarHabilidades(context),
                icon: const Icon(Remix.magic_fill, color: Colors.white, size: 20),
                label: Text(
                  'Ver Habilidades (${monstro.habilidades.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            // Botão de BATALHAR (apenas se showBattleButton for true)
            if (showBattleButton) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: estaMorto 
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : [Colors.red.shade600, Colors.red.shade800],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: estaMorto 
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: estaMorto ? null : onBattle,
                  icon: Icon(
                    estaMorto ? Remix.skull_2_fill : Remix.sword_fill, 
                    color: Colors.white, 
                    size: 20
                  ),
                  label: Text(
                    estaMorto ? 'DERROTADO' : 'BATALHAR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAtributoInfo(String nome, int valorTotal, IconData icone, Color cor) {
    // Calcula valores base e bônus do item (valores fixos do JSON)
    int valorBase = 0;
    int bonus = 0;
    int valorFinal = 0;
    
    switch (nome) {
      case 'Energia':
        valorBase = monstro.energia;
        bonus = monstro.itemEquipado?.energia ?? 0;
        valorFinal = monstro.energiaTotal;
        break;
      case 'Agilidade':
        valorBase = monstro.agilidade;
        bonus = monstro.itemEquipado?.agilidade ?? 0;
        valorFinal = monstro.agilidadeTotal;
        break;
      case 'Ataque':
        valorBase = monstro.ataque;
        bonus = monstro.itemEquipado?.ataque ?? 0;
        valorFinal = monstro.ataqueTotal;
        break;
      case 'Defesa':
        valorBase = monstro.defesa;
        bonus = monstro.itemEquipado?.defesa ?? 0;
        valorFinal = monstro.defesaTotal;
        break;
    }
    
    return Column(
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(height: 4),
        Text(
          nome,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        // Mostra valor com formato (+ bônus) se houver item
        if (bonus > 0)
          Column(
            children: [
              Text(
                '$valorFinal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              Text(
                '$valorBase (+$bonus)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          )
        else
          Text(
            '$valorFinal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
      ],
    );
  }

  Widget _buildVidaInfo() {
    // Calcula valores de vida (valores fixos do JSON)
    final vidaBase = monstro.vida;
    final bonusVida = monstro.itemEquipado?.vida ?? 0;
    final vidaMaximaTotal = monstro.vidaTotal; // vida base + item (valores fixos)
    
    // Vida atual = JSON base + bônus do item
    final vidaAtualComBonusItem = monstro.vidaAtual + bonusVida;
    
    // Calcula a cor da vida baseada na porcentagem
    double percentualVida = (vidaAtualComBonusItem / vidaMaximaTotal).clamp(0.0, 1.0);
    Color corVida = percentualVida > 0.5 
        ? Colors.green 
        : percentualVida > 0.25 
            ? Colors.orange 
            : Colors.red;
    
    return Column(
      children: [
        Icon(
          Remix.heart_pulse_fill,
          color: corVida,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          'Vida',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        // Mostra vida atual/máxima com bônus se houver
        if (bonusVida > 0)
          Column(
            children: [
              Text(
                '$vidaAtualComBonusItem/$vidaMaximaTotal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: corVida,
                ),
              ),
              Text(
                '${monstro.vidaAtual} (+$bonusVida)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          )
        else
          Text(
            '${monstro.vidaAtual}/$vidaBase',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: corVida,
            ),
          ),
        const SizedBox(height: 4),
        // Barra de vida
        Container(
          width: 50,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentualVida,
            child: Container(
              decoration: BoxDecoration(
                color: corVida,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarHabilidades(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _HabilidadesInimigoDialog(monstro: monstro),
    );
  }

  void _mostrarDetalheItem(BuildContext context) {
    if (monstro.itemEquipado != null) {
      showDialog(
        context: context,
        builder: (ctx) => ModalDetalheItemEquipado(
          item: monstro.itemEquipado!,
        ),
      );
    }
  }
}

class _HabilidadesInimigoDialog extends StatelessWidget {
  final MonstroInimigo monstro;

  const _HabilidadesInimigoDialog({required this.monstro});

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
            colors: [monstro.tipo.cor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com título e botão fechar
            Row(
              children: [
                Icon(Remix.skull_2_fill, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Habilidades Inimigas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: monstro.tipo.cor,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.black,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Lista de habilidades
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  children: monstro.habilidades.map((habilidade) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: habilidade.tipo == TipoHabilidade.suporte 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: habilidade.tipo == TipoHabilidade.suporte 
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  habilidade.tipo.nome,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: habilidade.tipo == TipoHabilidade.suporte 
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Image.asset(
                                habilidade.tipoElemental.iconAsset,
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            habilidade.nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            habilidade.descricao,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                habilidade.efeito.nome,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'LV.${habilidade.level}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⚡${habilidade.custoEnergia}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: monstro.tipo.cor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${habilidade.valorEfetivo}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: monstro.tipo.cor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
