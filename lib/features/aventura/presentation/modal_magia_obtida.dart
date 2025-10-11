import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../models/magia_drop.dart';
import '../models/monstro_aventura.dart';
import '../models/habilidade.dart';
import 'widgets/gerenciador_equipamentos_monstros.dart';

/// Modal de Magia Obtida - exibe a magia adquirida e permite equipar
class ModalMagiaObtida extends StatefulWidget {
  final MagiaDrop magia;
  final List<MonstroAventura> monstrosDisponiveis;
  final Function(MonstroAventura monstro, MagiaDrop magia, Habilidade habilidadeSubstituida) onEquiparMagia;

  const ModalMagiaObtida({
    super.key,
    required this.magia,
    required this.monstrosDisponiveis,
    required this.onEquiparMagia,
  });

  @override
  State<ModalMagiaObtida> createState() => _ModalMagiaObtidaState();
}

class _ModalMagiaObtidaState extends State<ModalMagiaObtida> {
  MonstroAventura? _monstroSelecionado;
  Habilidade? _habilidadeParaSubstituir;
  bool _equipando = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [_getCorTipoMagia().withOpacity(0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com imagem da magia
              _buildHeader(),
              const SizedBox(height: 16),

              // Informações da magia
              _buildInfoMagia(),
              const SizedBox(height: 20),

              // Seleção de monstro
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
                monstroSelecionado: _monstroSelecionado,
                corDestaque: _getCorTipoMagia(),
                onSelecionarMonstro: (monstro) {
                  setState(() {
                    _monstroSelecionado = monstro;
                    _habilidadeParaSubstituir = null; // Reset ao trocar monstro
                  });
                },
              ),

              // Seleção de habilidade para substituir
              if (_monstroSelecionado != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Escolha qual habilidade substituir:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSelecaoHabilidade(),
              ],

              const SizedBox(height: 20),

              // Botões de ação
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Imagem do tipo de magia
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getCorTipoMagia().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getCorTipoMagia(), width: 2),
          ),
          child: Image.asset(
            _getImagemTipoMagia(),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.auto_awesome,
              color: _getCorTipoMagia(),
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.magia.nome,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getCorTipoMagia(),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    widget.magia.tipo.toString().split('.').last,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lv. ${widget.magia.level}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getCorTipoMagia(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMagia() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.magia.descricao,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatChip(
                icon: Remix.flashlight_fill,
                label: 'Custo',
                value: '${widget.magia.custoEnergia}',
                color: Colors.blue,
              ),
              _buildStatChip(
                icon: Remix.sword_fill,
                label: 'Valor',
                value: '${widget.magia.valor}',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelecaoHabilidade() {
    if (_monstroSelecionado == null) return const SizedBox.shrink();

    final habilidades = _monstroSelecionado!.habilidades;

    return Column(
      children: habilidades.map((hab) {
        final selecionada = _habilidadeParaSubstituir == hab;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _habilidadeParaSubstituir = hab;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selecionada
                    ? _getCorTipoMagia().withOpacity(0.15)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selecionada ? _getCorTipoMagia() : Colors.grey.shade300,
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
                        _getImagemTipoHabilidade(hab),
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.auto_awesome,
                          size: 24,
                          color: _getCorTipoHabilidade(hab),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hab.nome,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selecionada ? _getCorTipoMagia() : Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCorTipoHabilidade(hab).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Lv. ${hab.level}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getCorTipoHabilidade(hab),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Segunda linha: informações da habilidade
                  Row(
                    children: [
                      // Valor (dano/cura/bônus)
                      Expanded(
                        child: _buildHabilidadeInfo(hab),
                      ),
                      const SizedBox(width: 12),
                      // Custo de energia
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Remix.flashlight_fill, size: 14, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${hab.custoEnergia}',
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
                    _getDescricaoEfeito(hab),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDescricaoEfeito(Habilidade hab) {
    final efeito = hab.efeito.toString().toLowerCase();

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
      return hab.descricao.length > 50
          ? '${hab.descricao.substring(0, 47)}...'
          : hab.descricao;
    }
  }

  Widget _buildHabilidadeInfo(Habilidade hab) {
    final tipo = hab.tipo.toString().toLowerCase();
    final valorCalculado = hab.valor * hab.level;

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

  Color _getCorTipoHabilidade(Habilidade hab) {
    final tipo = hab.tipo.toString().toLowerCase();
    if (tipo.contains('ofensiv')) return Colors.red.shade700;
    if (tipo.contains('cura')) return Colors.pink.shade700;
    if (tipo.contains('suporte')) return Colors.green.shade700;
    return Colors.purple.shade700;
  }

  String _getImagemTipoHabilidade(Habilidade hab) {
    final tipo = hab.tipo.toString().toLowerCase();
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

  Widget _buildActionButtons() {
    final podeEquipar = _monstroSelecionado != null && _habilidadeParaSubstituir != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botão Descartar
        TextButton.icon(
          onPressed: _equipando ? null : () {
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
            backgroundColor: podeEquipar ? _getCorTipoMagia() : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: (podeEquipar && !_equipando) ? _equiparMagia : null,
          icon: _equipando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_equipando ? 'Equipando...' : 'Equipar'),
        ),
      ],
    );
  }

  Future<void> _equiparMagia() async {
    if (_monstroSelecionado == null || _habilidadeParaSubstituir == null) return;

    setState(() => _equipando = true);

    try {
      await widget.onEquiparMagia(
        _monstroSelecionado!,
        widget.magia,
        _habilidadeParaSubstituir!,
      );
      // Não faz pop aqui, o callback já fecha o modal
    } catch (e) {
      print('❌ [ModalMagiaObtida] Erro ao equipar magia: $e');
      if (mounted) {
        setState(() => _equipando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao equipar magia. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getCorTipoMagia() {
    switch (widget.magia.tipo.toString().toLowerCase()) {
      case 'ofensivo':
        return Colors.red.shade700;
      case 'defensivo':
        return Colors.blue.shade700;
      case 'suporte':
        return Colors.green.shade700;
      case 'cura':
        return Colors.pink.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  String _getImagemTipoMagia() {
    final tipo = widget.magia.tipo.toString().toLowerCase();
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
