import 'package:flutter/material.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../models/monstro_aventura.dart';
import 'package:remixicon/remixicon.dart';

class ModalMonstroAventura extends StatelessWidget {
  final MonstroAventura monstro;
  final VoidCallback? onClose;
  final bool showCloseButton;
  const ModalMonstroAventura({super.key, required this.monstro, this.onClose, this.showCloseButton = true});

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
                      fit: BoxFit.cover,
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
                        monstro.tipo.displayName,
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
                      Row(
                        children: [
                          Image.asset(monstro.tipo.iconAsset, width: 32, height: 32, fit: BoxFit.contain),
                          const SizedBox(width: 8),
                          Image.asset(monstro.tipoExtra.iconAsset, width: 32, height: 32, fit: BoxFit.contain),
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
                      _buildAtributoInfo('Energia', monstro.energia, Remix.battery_charge_fill, Colors.blue),
                      _buildAtributoInfo('Agilidade', monstro.agilidade, Remix.run_fill, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAtributoInfo('Ataque', monstro.ataque, Remix.boxing_fill, Colors.orange),
                      _buildAtributoInfo('Defesa', monstro.defesa, Remix.shield_cross_fill, Colors.purple),
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

  Widget _buildAtributoInfo(String nome, int valor, IconData icone, Color cor) {
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
        Text(
          '$valor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildVidaInfo() {
    // Calcula a cor da vida baseada na porcentagem
    double percentualVida = monstro.vidaAtual / monstro.vida;
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
        // Mostra vida atual / vida máxima
        Text(
          '${monstro.vidaAtual}/${monstro.vida}',
          style: TextStyle(
            fontSize: 14,
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
                    'Habilidades do ${monstro.tipo.displayName}',
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
                                  '${habilidade.valor}',
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
