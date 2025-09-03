import 'package:flutter/material.dart';
import '../../../shared/models/habilidade_enum.dart';
import 'modal_detalhe_item_equipado.dart';
import '../models/monstro_aventura.dart';
import 'package:remixicon/remixicon.dart';
// Garante que RemixIcon está disponível

class ModalMonstroAventura extends StatelessWidget {
  final MonstroAventura monstro;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final int? ataqueAtual;
  final int? defesaAtual;
  final int? energiaAtual;
  final int? energiaMaximaAtual; // Energia máxima com buffs
  final int? vidaMaximaAtual; // Vida máxima com buffs
  final bool isBatalha;
  
  const ModalMonstroAventura({
    super.key, 
    required this.monstro, 
    this.onClose, 
    this.showCloseButton = true,
    this.ataqueAtual,
    this.defesaAtual,
    this.energiaAtual,
    this.energiaMaximaAtual,
    this.vidaMaximaAtual,
    this.isBatalha = false,
  });

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
            colors: [monstro.tipo.cor.withOpacity(0.8), Colors.white],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: monstro.tipo.cor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: monstro.tipo.cor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      monstro.imagem,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: monstro.tipo.cor.withOpacity(0.3),
                          child: Icon(
                            Icons.pets,
                            color: monstro.tipo.cor,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monstro.tipo.monsterName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: monstro.tipo.cor,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calcula quantos ícones teremos
                            int iconCount = 3; // tipo, tipoExtra, level (sempre presentes)
                            iconCount += monstro.itemEquipado != null ? 1 : 0; // mochila
                            iconCount += monstro.vidaAtual <= 0 ? 1 : 0; // skull
                            
                            // Define tamanhos baseados na largura disponível
                            final double maxWidth = constraints.maxWidth;
                            final double availableForIcons = maxWidth - 20; // margem de segurança
                            final double iconSize = (availableForIcons / iconCount).clamp(16.0, 32.0);
                            final double spacing = iconSize <= 24 ? 2.0 : (iconSize <= 28 ? 4.0 : 6.0);
                            
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Image.asset(
                                    monstro.tipo.iconAsset, 
                                    width: iconSize, 
                                    height: iconSize, 
                                    fit: BoxFit.contain
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Flexible(
                                  child: Image.asset(
                                    monstro.tipoExtra.iconAsset, 
                                    width: iconSize, 
                                    height: iconSize, 
                                    fit: BoxFit.contain
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: monstro.itemEquipado != null
                                        ? () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => ModalDetalheItemEquipado(
                                                item: monstro.itemEquipado!,
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Stack(
                                      children: [
                                        Icon(
                                          Icons.backpack,
                                          color: monstro.itemEquipado != null ? Colors.brown : Colors.grey,
                                          size: iconSize,
                                        ),
                                        if (monstro.itemEquipado != null)
                                          Positioned(
                                            right: iconSize <= 24 ? 0 : -2,
                                            top: iconSize <= 24 ? 0 : -2,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: iconSize <= 24 ? 1 : 3, 
                                                vertical: iconSize <= 24 ? 0.5 : 1
                                              ),
                                              decoration: BoxDecoration(
                                                color: monstro.itemEquipado!.raridade.cor,
                                                borderRadius: BorderRadius.circular(iconSize <= 24 ? 3 : 5),
                                                border: Border.all(color: Colors.white, width: 0.5),
                                              ),
                                              child: Text(
                                                '${monstro.itemEquipado!.tier}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: (iconSize * 0.25).clamp(6.0, 10.0),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Flexible(
                                  child: Stack(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: iconSize,
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: iconSize <= 24 ? 1 : 3, 
                                            vertical: iconSize <= 24 ? 0.5 : 1
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius: BorderRadius.circular(iconSize <= 24 ? 3 : 5),
                                            border: Border.all(color: Colors.white, width: 0.5),
                                          ),
                                          child: Text(
                                            '${monstro.level}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: (iconSize * 0.25).clamp(6.0, 10.0),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (monstro.vidaAtual <= 0) ...[
                                  SizedBox(width: spacing),
                                  Flexible(
                                    child: Icon(Remix.skull_fill, color: Colors.red, size: iconSize),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
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
                      _buildEnergiaInfo(), // Nova função para mostrar energia atual/máxima
                      _buildAtributoInfo('Agilidade', monstro.agilidade, Remix.run_fill, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAtributoInfo(
                        'Ataque', 
                        isBatalha && ataqueAtual != null ? ataqueAtual! : monstro.ataque, 
                        Remix.boxing_fill, 
                        Colors.orange,
                        valorOriginal: isBatalha && ataqueAtual != null ? monstro.ataque : null,
                      ),
                      _buildAtributoInfo(
                        'Defesa', 
                        isBatalha && defesaAtual != null ? defesaAtual! : monstro.defesa, 
                        Remix.shield_cross_fill, 
                        Colors.green,
                        valorOriginal: isBatalha && defesaAtual != null ? monstro.defesa : null,
                      ),
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
            // Removido o botão "Fechar" da parte inferior
          ],
        ),
      ),
    );
  }

  Widget _buildAtributoInfo(String nome, int valor, IconData icone, Color cor, {int? valorOriginal}) {
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
        Builder(
          builder: (context) {
            int bonusItem = 0;
            if (monstro.itemEquipado != null) {
              switch (nome.toLowerCase()) {
                case 'vida':
                  bonusItem = monstro.itemEquipado!.atributos['vida'] ?? 0;
                  break;
                case 'energia':
                  bonusItem = monstro.itemEquipado!.atributos['energia'] ?? 0;
                  break;
                case 'ataque':
                  bonusItem = monstro.itemEquipado!.atributos['ataque'] ?? 0;
                  break;
                case 'defesa':
                  bonusItem = monstro.itemEquipado!.atributos['defesa'] ?? 0;
                  break;
                case 'agilidade':
                  bonusItem = monstro.itemEquipado!.atributos['agilidade'] ?? 0;
                  break;
              }
            }
            
            // Calcula buff total (item + habilidade de batalha)
            int buffHabilidade = 0;
            if (isBatalha) {
              switch (nome.toLowerCase()) {
                case 'ataque':
                  buffHabilidade = ataqueAtual != null ? ataqueAtual! - monstro.ataque - bonusItem : 0;
                  break;
                case 'defesa':
                  buffHabilidade = defesaAtual != null ? defesaAtual! - monstro.defesa - bonusItem : 0;
                  break;
              }
            }
            
            int bonusTotal = bonusItem + buffHabilidade;
            if (bonusTotal > 0) {
              return Text(
                '$valor (+$bonusTotal)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              );
            } else {
              return Text(
                '$valor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildVidaInfo() {
    // Usa vida máxima com buffs se estiver em batalha
    final vidaMaxima = isBatalha && vidaMaximaAtual != null ? vidaMaximaAtual! : monstro.vida;
    
    // Calcula a cor da vida baseada na porcentagem, garantindo que seja entre 0.0 e 1.0
    double percentualVida = (monstro.vidaAtual / vidaMaxima).clamp(0.0, 1.0);
    Color corVida = percentualVida > 0.5 
        ? Colors.green 
        : percentualVida > 0.25 
            ? Colors.orange 
            : Colors.red;
    
    // Determina se há buff de vida
    final temBuffVida = isBatalha && vidaMaxima > monstro.vida;
    final buffVida = temBuffVida ? vidaMaxima - monstro.vida : 0;
    
    return Column(
      children: [
        Icon(
          Remix.heart_pulse_fill,
          color: Colors.red,
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
        // Mostra vida atual / vida máxima (com buff se houver)
        Text(
          temBuffVida ? '${monstro.vidaAtual}/$vidaMaxima (+$buffVida)' : '${monstro.vidaAtual}/$vidaMaxima',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.red,
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

  Widget _buildEnergiaInfo() {
    // Usa energiaAtual se estiver em batalha, senão usa energia padrão
    final energiaAtualValue = isBatalha && energiaAtual != null ? energiaAtual! : monstro.energiaAtual;
    // Usa energia máxima com buffs se estiver em batalha
    final energiaMaxima = isBatalha && energiaMaximaAtual != null ? energiaMaximaAtual! : monstro.energia;
    
    // Calcula a cor da energia baseada na porcentagem, garantindo que seja entre 0.0 e 1.0
    double percentualEnergia = (energiaAtualValue / energiaMaxima).clamp(0.0, 1.0);
    Color corEnergia = percentualEnergia > 0.5 
        ? Colors.blue 
        : percentualEnergia > 0.25 
            ? Colors.orange 
            : Colors.red;
    
    // Determina se há buff de energia
    final temBuffEnergia = isBatalha && energiaMaxima > monstro.energia;
    final buffEnergia = temBuffEnergia ? energiaMaxima - monstro.energia : 0;
    
    return Column(
      children: [
        Icon(
          Remix.battery_charge_fill,
          color: Colors.blue,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          'Energia',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        // Mostra energia atual / energia máxima (com buffs se houver)
        Text(
          temBuffEnergia ? '$energiaAtualValue/$energiaMaxima (+$buffEnergia)' : '$energiaAtualValue/$energiaMaxima',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        // Barra de energia
        Container(
          width: 50,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentualEnergia,
            child: Container(
              decoration: BoxDecoration(
                color: corEnergia,
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
      builder: (context) => _HabilidadesDialog(monstro: monstro),
    );
  }
}

class _HabilidadesDialog extends StatelessWidget {
  final MonstroAventura monstro;

  const _HabilidadesDialog({required this.monstro});

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
                Icon(Remix.magic_fill, color: monstro.tipo.cor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Habilidades do ${monstro.tipo.monsterName}',
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
                              const SizedBox(width: 8),
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
                              Expanded(
                                child: Text(
                                  habilidade.efeito.nome,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
