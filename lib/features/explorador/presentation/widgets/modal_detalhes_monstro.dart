import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/monstro_explorador.dart';
import '../../providers/equipe_explorador_provider.dart';
import '../../providers/equipamento_provider.dart';

/// Modal com detalhes completos do monstro
/// Inclui stats, XP, e os 3 slots de equipamento com durabilidade
class ModalDetalhesMonstro extends ConsumerWidget {
  final MonstroExplorador monstro;
  final bool isAtivo;
  final dynamic equipe;

  const ModalDetalhesMonstro({
    super.key,
    required this.monstro,
    required this.isAtivo,
    required this.equipe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de arraste
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header do monstro
            _buildHeader(),

            const SizedBox(height: 16),

            // Barra de XP
            _buildXpBar(),

            const SizedBox(height: 12),

            // Stats
            _buildStats(),

            const SizedBox(height: 16),

            // Equipamentos
            _buildEquipamentosSecao(context, ref),

            const SizedBox(height: 16),
            const Divider(color: Colors.grey),

            // Opcoes
            _buildOpcoes(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Imagem do monstro
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                monstro.imagem,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: monstro.tipo.cor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(monstro.tipo.icone, color: monstro.tipo.cor, size: 35),
                ),
              ),
            ),
            // Badge de equipamentos quebrados
            if (monstro.temEquipamentoQuebrado)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monstro.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: monstro.tipo.cor.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/tipagens/icon_tipo_${monstro.tipo.name}.png',
                          width: 14,
                          height: 14,
                          errorBuilder: (_, __, ___) => Icon(monstro.tipo.icone, color: monstro.tipo.cor, size: 11),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          monstro.tipo.displayName,
                          style: TextStyle(color: monstro.tipo.cor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (monstro.tipoExtra != monstro.tipo) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: monstro.tipoExtra.cor.withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/tipagens/icon_tipo_${monstro.tipoExtra.name}.png',
                            width: 14,
                            height: 14,
                            errorBuilder: (_, __, ___) => Icon(monstro.tipoExtra.icone, color: monstro.tipoExtra.cor, size: 11),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            monstro.tipoExtra.displayName,
                            style: TextStyle(color: monstro.tipoExtra.cor, fontSize: 11),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withAlpha(100)),
          ),
          child: Text(
            'Lv.${monstro.level}',
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildXpBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.purple, size: 16),
                  const SizedBox(width: 4),
                  const Text('XP', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                '${monstro.xpAtual} / ${monstro.xpParaProximoLevel}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: monstro.porcentagemXp,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation(Colors.purple),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('HP', monstro.vidaTotal, Colors.green, Icons.favorite),
              _buildStatItem('EN', monstro.energiaTotal, Colors.cyan, Icons.bolt),
              _buildStatItem('ATK', monstro.ataqueTotal, Colors.orange, Icons.sports_mma),
              _buildStatItem('DEF', monstro.defesaTotal, Colors.blue, Icons.shield),
              _buildStatItem('AGI', monstro.agilidadeTotal, Colors.teal, Icons.speed),
            ],
          ),
          if (monstro.equipamentosEquipados.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 8),
            Text(
              'Stats incluem bonus de equipamentos${monstro.temEquipamentoQuebrado ? " (quebrados ignorados)" : ""}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int valor, Color cor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 16),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: cor, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '$valor',
          style: TextStyle(color: cor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEquipamentosSecao(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Equipamentos',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (monstro.temEquipamentoQuebrado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${monstro.quantidadeEquipamentosQuebrados} quebrado(s)',
                        style: const TextStyle(color: Colors.red, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSlotEquipamento(SlotEquipamento.cabeca, context, ref)),
              const SizedBox(width: 8),
              Expanded(child: _buildSlotEquipamento(SlotEquipamento.peito, context, ref)),
              const SizedBox(width: 8),
              Expanded(child: _buildSlotEquipamento(SlotEquipamento.bracos, context, ref)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotEquipamento(SlotEquipamento slot, BuildContext context, WidgetRef ref) {
    final equipamento = monstro.getEquipamento(slot);

    if (equipamento == null) {
      // Slot vazio
      return GestureDetector(
        onTap: () => _abrirModalEquipar(slot, context, ref),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withAlpha(100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconData(slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
                color: Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                slot.displayName,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                'Vazio',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              ),
            ],
          ),
        ),
      );
    }

    // Slot com equipamento
    final corRaridade = Color(equipamento.raridade.corHex);
    final estaQuebrado = equipamento.estaQuebrado;

    return GestureDetector(
      onTap: () => _mostrarDetalhesEquipamento(equipamento, slot, context, ref),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: estaQuebrado
              ? Colors.grey.shade800
              : corRaridade.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: estaQuebrado ? Colors.grey.shade600 : corRaridade,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Conteudo
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagem de armadura
                  Image.asset(
                    equipamento.iconeArmadura,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    color: estaQuebrado ? Colors.grey : null,
                    errorBuilder: (_, __, ___) => Icon(
                      IconData(slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
                      color: estaQuebrado ? Colors.grey : corRaridade,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Nome (abreviado)
                  Text(
                    equipamento.raridade.nome,
                    style: TextStyle(
                      color: estaQuebrado ? Colors.grey : corRaridade,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'T${equipamento.tier}',
                    style: TextStyle(
                      color: estaQuebrado ? Colors.grey.shade500 : Colors.white70,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),

            // Barra de durabilidade (na parte inferior)
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: equipamento.porcentagemDurabilidade,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation(
                        estaQuebrado
                            ? Colors.red
                            : equipamento.porcentagemDurabilidade > 0.5
                                ? Colors.grey.shade400
                                : equipamento.porcentagemDurabilidade > 0.2
                                    ? Colors.orange
                                    : Colors.red,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${equipamento.durabilidadeAtual}/${equipamento.durabilidadeMax}',
                    style: TextStyle(
                      color: estaQuebrado ? Colors.red : Colors.grey.shade500,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),

            // Icone de quebrado
            if (estaQuebrado)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _abrirModalEquipar(SlotEquipamento slot, BuildContext context, WidgetRef ref) {
    // Obtem equipamentos compativeis do inventario
    final inventario = ref.read(inventarioEquipamentosProvider);
    final compativeis = inventario.where((e) =>
      e.slot == slot &&
      (e.tipoRequerido == monstro.tipo || e.tipoRequerido == monstro.tipoExtra)
    ).toList();

    if (compativeis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum equipamento de ${slot.displayName} compativel no inventario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipar ${slot.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ...compativeis.map((equip) => _buildEquipamentoTile(equip, slot, context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipamentoTile(EquipamentoExplorador equip, SlotEquipamento slot, BuildContext context, WidgetRef ref) {
    final corRaridade = Color(equip.raridade.corHex);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: corRaridade.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: corRaridade),
        ),
        child: Image.asset(
          equip.iconeArmadura,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            IconData(slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
            color: corRaridade,
          ),
        ),
      ),
      title: Text(
        equip.nome,
        style: TextStyle(color: corRaridade, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'T${equip.tier} | +${equip.vida}HP +${equip.ataque}ATK +${equip.defesa}DEF',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
      ),
      onTap: () async {
        Navigator.pop(context); // Fecha modal de selecao

        // Equipa o item
        final equipAnterior = await ref.read(equipeExploradorProvider.notifier)
            .equiparEquipamento(monstro.id, equip);

        // Remove do inventario
        await ref.read(inventarioEquipamentosProvider.notifier).removerEquipamento(equip.id);

        // Se tinha equipamento anterior, devolve ao inventario
        if (equipAnterior != null) {
          await ref.read(inventarioEquipamentosProvider.notifier).adicionarEquipamento(equipAnterior);
        }

        if (context.mounted) {
          Navigator.pop(context); // Fecha modal de detalhes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${equip.nome} equipado!'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      },
    );
  }

  void _mostrarDetalhesEquipamento(EquipamentoExplorador equip, SlotEquipamento slot, BuildContext context, WidgetRef ref) {
    final corRaridade = Color(equip.raridade.corHex);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: corRaridade.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corRaridade, width: 2),
                  ),
                  child: Image.asset(
                    equip.iconeArmadura,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    color: equip.estaQuebrado ? Colors.grey : null,
                    errorBuilder: (_, __, ___) => Icon(
                      IconData(slot.iconeCodePoint, fontFamily: 'MaterialIcons'),
                      color: equip.estaQuebrado ? Colors.grey : corRaridade,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equip.nome,
                        style: TextStyle(
                          color: equip.estaQuebrado ? Colors.grey : corRaridade,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${equip.raridade.nome} - Tier ${equip.tier}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Durabilidade
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: equip.estaQuebrado ? Colors.red.withAlpha(30) : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            equip.estaQuebrado ? Icons.broken_image : Icons.security,
                            color: equip.estaQuebrado ? Colors.red : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            equip.estaQuebrado ? 'QUEBRADO' : 'Durabilidade',
                            style: TextStyle(
                              color: equip.estaQuebrado ? Colors.red : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${equip.durabilidadeAtual}/${equip.durabilidadeMax}',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: equip.porcentagemDurabilidade,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation(
                        equip.estaQuebrado ? Colors.red : Colors.grey.shade400,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (equip.estaQuebrado) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Equipamento quebrado nao fornece bonus de stats',
                      style: TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEquipStatItem('HP', equip.vida, equip.vidaAtiva, Colors.green),
                  _buildEquipStatItem('EN', equip.energia, equip.energiaAtiva, Colors.cyan),
                  _buildEquipStatItem('ATK', equip.ataque, equip.ataqueAtivo, Colors.orange),
                  _buildEquipStatItem('DEF', equip.defesa, equip.defesaAtiva, Colors.blue),
                  _buildEquipStatItem('AGI', equip.agilidade, equip.agilidadeAtiva, Colors.teal),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Opcoes
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Desequipa e devolve ao inventario
                      final removido = await ref.read(equipeExploradorProvider.notifier)
                          .desequiparSlot(monstro.id, slot);
                      if (removido != null) {
                        await ref.read(inventarioEquipamentosProvider.notifier)
                            .adicionarEquipamento(removido);
                      }
                      if (context.mounted) {
                        Navigator.pop(context); // Fecha modal principal
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Equipamento removido'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Desequipar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: equip.estaQuebrado || equip.durabilidadeAtual == equip.durabilidadeMax
                        ? null
                        : () async {
                            Navigator.pop(context);
                            // TODO: Implementar reparo com custo
                            await ref.read(equipeExploradorProvider.notifier)
                                .repararEquipamento(monstro.id, slot);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Equipamento reparado!'),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.build, size: 18),
                    label: const Text('Reparar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
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

  Widget _buildEquipStatItem(String label, int valorBase, int valorAtivo, Color cor) {
    final estaReduzido = valorAtivo < valorBase;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: cor, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '+$valorAtivo',
          style: TextStyle(
            color: estaReduzido ? Colors.red : cor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            decoration: estaReduzido ? TextDecoration.lineThrough : null,
          ),
        ),
        if (estaReduzido)
          Text(
            '(+$valorBase)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
          ),
      ],
    );
  }

  Widget _buildOpcoes(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (isAtivo && (equipe?.monstrosBanco.length ?? 0) < 3)
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.teal),
            title: const Text('Mover para Banco', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Chance de +1 XP por vitoria',
              style: TextStyle(color: Colors.teal.shade300, fontSize: 11),
            ),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(equipeExploradorProvider.notifier).moverParaBanco(monstro.id);
            },
          ),

        if (!isAtivo && (equipe?.monstrosAtivos.length ?? 0) < 2)
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.amber),
            title: const Text('Mover para Ativo', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Participa das batalhas',
              style: TextStyle(color: Colors.amber.shade300, fontSize: 11),
            ),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(equipeExploradorProvider.notifier).moverParaAtivo(monstro.id);
            },
          ),

        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Remover da Equipe', style: TextStyle(color: Colors.white)),
          onTap: () async {
            Navigator.pop(context);
            await ref.read(equipeExploradorProvider.notifier).removerMonstro(monstro.id);
          },
        ),
      ],
    );
  }
}
