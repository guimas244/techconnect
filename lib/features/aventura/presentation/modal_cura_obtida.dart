import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../models/monstro_aventura.dart';

class ModalCuraObtida extends StatefulWidget {
  final int porcentagem;
  final List<MonstroAventura> monstrosDisponiveis;
  final Function(MonstroAventura, int) onCurarMonstro;

  const ModalCuraObtida({
    super.key,
    required this.porcentagem,
    required this.monstrosDisponiveis,
    required this.onCurarMonstro,
  });

  @override
  State<ModalCuraObtida> createState() => _ModalCuraObtidaState();
}

class _ModalCuraObtidaState extends State<ModalCuraObtida> {
  MonstroAventura? monstroSelecionado;
  bool isCurando = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green.withOpacity(0.15), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.healing, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cura Obtida!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Recuperação: ${widget.porcentagem}% de vida',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            
            // Efeito da cura
            Text(
              'Efeito da cura:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            _buildEfeitoCura(),
            
            const SizedBox(height: 18),

            // Monster selection
            _buildMonstroSelection(),
            const SizedBox(height: 18),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildEfeitoCura() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Remix.heart_pulse_fill, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Text(
            'Vida',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            '+${widget.porcentagem}%',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMonstroSelection() {
    // Filtra apenas monstros que precisam de cura
    final monstrosQuePrecisamCura = widget.monstrosDisponiveis.where((m) => m.vidaAtual < m.vida).toList();
    
    if (monstrosQuePrecisamCura.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Nenhum monstro precisa de cura!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos os seus monstros já estão com vida completa',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione um monstro para curar:',
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
            itemCount: monstrosQuePrecisamCura.length,
            itemBuilder: (context, index) {
              final monstro = monstrosQuePrecisamCura[index];
              final isSelected = monstroSelecionado == monstro;
              
              return GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      monstroSelecionado = monstro;
                    });
                  }
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    gradient: isSelected ? LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
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
                      // Nome e vida do monstro
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              monstro.tipo.monsterName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.green : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${monstro.vidaAtual}/${monstro.vida}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
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

  Widget _buildActionButtons() {
    final monstrosQuePrecisamCura = widget.monstrosDisponiveis.where((m) => m.vidaAtual < m.vida).toList();
    final podeUsar = monstrosQuePrecisamCura.isNotEmpty;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botão Descartar
        TextButton.icon(
          onPressed: isCurando ? null : () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.close),
          label: const Text('Descartar'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 12),
        // Botão Usar Cura
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: (monstroSelecionado != null && podeUsar) 
                ? Colors.green
                : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: (monstroSelecionado != null && podeUsar && !isCurando) ? () async {
            if (!mounted) return;

            setState(() {
              isCurando = true;
            });

            try {
              await widget.onCurarMonstro(monstroSelecionado!, widget.porcentagem);
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              print('❌ [ModalCuraObtida] Erro ao curar monstro: $e');
              if (mounted) {
                setState(() {
                  isCurando = false;
                });
                if (Navigator.of(context).canPop()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao curar monstro. Tente novamente.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          } : null,
          icon: isCurando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.healing, size: 18),
          label: Text(isCurando ? 'Curando...' : 'Usar Cura'),
        ),
      ],
    );
  }
}