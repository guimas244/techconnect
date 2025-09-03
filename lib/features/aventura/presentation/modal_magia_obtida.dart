import 'package:flutter/material.dart';
import '../models/monstro_aventura.dart';
import '../models/magia_drop.dart';
import '../models/habilidade.dart';

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nova Magia Obtida!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoMagia(),
            const SizedBox(height: 16),
            _buildSelecaoMonstro(),
            if (_monstroSelecionado != null) ...[
              const SizedBox(height: 16),
              _buildSelecaoHabilidade(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Descartar'),
        ),
        ElevatedButton(
          onPressed: _monstroSelecionado != null && _habilidadeParaSubstituir != null
              ? () {
                  widget.onEquiparMagia(
                    _monstroSelecionado!,
                    widget.magia,
                    _habilidadeParaSubstituir!,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: Text('Equipar Magia'),
        ),
      ],
    );
  }

  Widget _buildInfoMagia() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.magia.nome,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.purple.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tipo: ${widget.magia.tipo.name} | Efeito: ${widget.magia.efeito.name}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(widget.magia.descricao),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip('Valor', '${widget.magia.valor}', Colors.orange),
              const SizedBox(width: 8),
              _buildInfoChip('Level', '${widget.magia.level}', Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip('Custo', '${widget.magia.custoEnergia}', Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Poder Efetivo: ${widget.magia.valorEfetivo} (${widget.magia.valor} × ${widget.magia.level})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: cor.withOpacity(0.7)),
          ),
          const SizedBox(width: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelecaoMonstro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha o monstro para equipar a magia:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.monstrosDisponiveis.length,
            itemBuilder: (context, index) {
              final monstro = widget.monstrosDisponiveis[index];
              final isSelected = _monstroSelecionado == monstro;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _monstroSelecionado = monstro;
                    _habilidadeParaSubstituir = null; // Reset seleção de habilidade
                  });
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    gradient: isSelected ? LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.1),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : null,
                  ),
                  child: Column(
                    children: [
                      // Imagem do monstro
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            color: monstro.tipo.cor.withOpacity(0.2),
                          ),
                          child: Center(
                            child: Image.asset(
                              monstro.imagem,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Nome do monstro
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          monstro.tipo.monsterName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.purple : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelecaoHabilidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha a habilidade para substituir:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          'A habilidade selecionada será removida permanentemente',
          style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            itemCount: _monstroSelecionado!.habilidades.length,
            itemBuilder: (context, index) {
              final habilidade = _monstroSelecionado!.habilidades[index];
              final isSelected = _habilidadeParaSubstituir == habilidade;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _habilidadeParaSubstituir = habilidade;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.shade100 : Colors.grey.shade50,
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.red : Colors.grey,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habilidade.nome,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isSelected ? Colors.red.shade800 : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${habilidade.tipo.name} | Lv.${habilidade.level} | Poder: ${habilidade.valorEfetivo}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 14,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}