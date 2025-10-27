import 'package:flutter/material.dart';
import 'dart:math';
import '../models/historia_jogador.dart';
import '../models/item.dart';
import '../models/habilidade.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../services/item_service.dart';
import '../utils/gerador_habilidades.dart';
import 'modal_item_obtido.dart';
import 'modal_magia_obtida.dart';
import 'modal_cura_obtida.dart';
import '../models/magia_drop.dart';
import '../../../core/config/score_config.dart';

class CasaVigaristaModal extends StatefulWidget {
  final HistoriaJogador historia;
  final Function(HistoriaJogador historiaAtualizada) onHistoriaAtualizada;

  const CasaVigaristaModal({
    super.key,
    required this.historia,
    required this.onHistoriaAtualizada,
  });

  @override
  State<CasaVigaristaModal> createState() => _CasaVigaristaModalState();
}

class _CasaVigaristaModalState extends State<CasaVigaristaModal> {
  final ItemService _itemService = ItemService();
  int get custoAposta => 2 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
  int get custoFeirao => ((_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier) * 1.5).ceil();
  bool _comprando = false;
  late HistoriaJogador _historiaAtual;

  @override
  void initState() {
    super.initState();
    _historiaAtual = widget.historia;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8B4513).withOpacity(0.95), // Marrom medieval
              const Color(0xFF2F1B14).withOpacity(0.95), // Marrom escuro
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 3), // Dourado
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header da loja
            _buildHeader(),
            
            // Vendedor (monstro inseto)
            _buildVendedor(),
            
            // Opções de aposta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD4AF37).withOpacity(0.2),
                            const Color(0xFF8B4513).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                      ),
                      child: const Text(
                        '🏪 Mercadorias Disponíveis 🏪',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Grid 2x2 para os ícones
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          // Item Aleatório
                          _buildIconeOpcao(
                            'assets/icons_gerais/bau.png',
                            const Color(0xFF4169E1),
                            () => _mostrarConfirmacao('Item', _apostarItem),
                          ),
                          // Magia Aleatória
                          _buildIconeOpcao(
                            'assets/icons_gerais/magia.png',
                            const Color(0xFF9932CC),
                            () => _mostrarConfirmacao('Magia', _apostarMagia),
                          ),
                          // Cura Aleatória
                          _buildIconeOpcao(
                            'assets/icons_gerais/cura.png',
                            const Color(0xFF228B22),
                            () => _mostrarConfirmacao('Cura', _apostarCura),
                          ),
                          // Feirão
                          _buildIconeOpcao(
                            Icons.store,
                            const Color(0xFFFF8C00),
                            () => _mostrarConfirmacaoFeirao(),
                            isIcon: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer com score atual
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF654321),
            const Color(0xFF2F1B14),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: Icon(Icons.store, color: const Color(0xFFD4AF37), size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Casa do Vigarista',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendedor() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF654321).withOpacity(0.8),
            const Color(0xFF2F1B14).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  Tipo.inseto.cor.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              'assets/npc/besta_Karma.png',
              width: 70,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendedor Questionável',
                  style: TextStyle(
                    color: const Color(0xFFD4AF37),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"Apostas arriscadas, recompensas incertas..."',
                  style: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF6B6B), width: 1),
                  ),
                  child: Text(
                    'Custo básico: $custoAposta | Feirão: $custoFeirao',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacao(String tipoAposta, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B4513),
                  const Color(0xFF2F1B14),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37).withOpacity(0.3),
                          const Color(0xFF8B4513).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                    ),
                    child: Text(
                      '⚖️ Confirmar Negócio ⚖️',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Deseja investir $custoAposta moedas de ouro em "$tipoAposta"?',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFCCCCCC),
                      fontFamily: 'serif',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: const Color(0xFFFFD700), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'O ouro será descontado imediatamente do seu tesouro!',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFFFF6B6B),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B0000),
                              const Color(0xFF654321),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37),
                              const Color(0xFFFFD700),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF8B4513), width: 2),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Aceitar Negócio',
                            style: TextStyle(
                              color: Color(0xFF2F1B14),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconeOpcao(dynamic icon, Color cor, VoidCallback onTap, {bool isIcon = false}) {
    bool podeComprar = _historiaAtual.score >= custoAposta && !_comprando;

    // Para o feirão, verifica se tem dinheiro suficiente para o custo especial
    if (isIcon && icon == Icons.store) {
      int custoFeirao = ((_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier) * 1.5).ceil();
      podeComprar = _historiaAtual.score >= custoFeirao && !_comprando;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: podeComprar ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: podeComprar
                  ? [
                      cor.withOpacity(0.4),
                      const Color(0xFF8B4513).withOpacity(0.3),
                    ]
                  : [
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.2),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: podeComprar ? const Color(0xFFD4AF37) : Colors.grey,
              width: 3,
            ),
            boxShadow: podeComprar ? [
              BoxShadow(
                color: cor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ] : null,
          ),
          child: Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: podeComprar
                    ? RadialGradient(
                        colors: [
                          const Color(0xFFD4AF37).withOpacity(0.6),
                          cor.withOpacity(0.4),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.4),
                          Colors.grey.withOpacity(0.3),
                        ],
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: podeComprar ? const Color(0xFFD4AF37) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isIcon
                  ? Icon(
                      icon,
                      size: 30,
                      color: podeComprar ? const Color(0xFFD4AF37) : Colors.grey,
                    )
                  : Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        icon,
                        fit: BoxFit.contain,
                        color: podeComprar ? null : Colors.grey,
                        colorBlendMode: podeComprar ? null : BlendMode.saturation,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2F1B14),
            const Color(0xFF654321),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.2),
                  const Color(0xFFFFD700).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: const Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Ouro: ${ScoreConfig.formatarScoreExibicao(_historiaAtual.tier, _historiaAtual.score)}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: const Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Nível: ${widget.historia.tier}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _apostarItem() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    setState(() { _comprando = true; });

    try {
      // Desconta o score primeiro
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      // Atualiza história local e salva
      setState(() {
        _historiaAtual = historiaAtualizada;
      });
      widget.onHistoriaAtualizada(historiaAtualizada);
      
      // Gera item aleatório baseado no tier
      final item = _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier);
      _mostrarResultadoItem(item, historiaAtualizada);
    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }
    
    setState(() { _comprando = false; });
  }

  void _apostarMagia() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    setState(() { _comprando = true; });

    try {
      // Desconta o score primeiro
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      // Atualiza história local e salva
      setState(() {
        _historiaAtual = historiaAtualizada;
      });
      widget.onHistoriaAtualizada(historiaAtualizada);
      
      // Gera habilidade aleatória
      final habilidade = _gerarHabilidadeAleatoria();
      _mostrarResultadoMagia(habilidade, historiaAtualizada);
      
    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }
    
    setState(() { _comprando = false; });
  }

  void _apostarCura() async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    setState(() { _comprando = true; });

    try {
      // Desconta o score primeiro
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      // Atualiza história local e salva
      setState(() {
        _historiaAtual = historiaAtualizada;
      });
      widget.onHistoriaAtualizada(historiaAtualizada);

      // Gera cura aleatória (1% a 100%)
      final random = Random();
      final porcentagemCura = random.nextInt(100) + 1; // 1 a 100

      _mostrarResultadoCura(porcentagemCura, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }

    setState(() { _comprando = false; });
  }

  void _mostrarConfirmacaoFeirao() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B4513),
                  const Color(0xFF2F1B14),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF8C00).withOpacity(0.3),
                          const Color(0xFF8B4513).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                    ),
                    child: Text(
                      '🏪 Feirão do Vigarista 🏪',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pague $custoFeirao moedas para ver 3 itens especiais!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFCCCCCC),
                      fontFamily: 'serif',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: const Color(0xFFFFD700), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Você poderá escolher quais itens comprar!\\nCada item custará $custoAposta moedas.',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B0000),
                              const Color(0xFF654321),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF8C00),
                              const Color(0xFFFFD700),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF8B4513), width: 2),
                        ),
                        child: ElevatedButton(
                          onPressed: _historiaAtual.score >= custoFeirao ? () {
                            Navigator.of(context).pop();
                            _abrirFeirao();
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Abrir Feirão',
                            style: TextStyle(
                              color: Color(0xFF2F1B14),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _abrirFeirao() async {
    if (_comprando || _historiaAtual.score < custoFeirao) return;

    setState(() { _comprando = true; });

    try {
      // Desconta o custo do feirão primeiro
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoFeirao,
      );

      // Atualiza história local e salva
      setState(() {
        _historiaAtual = historiaAtualizada;
      });
      widget.onHistoriaAtualizada(historiaAtualizada);

      // Gera 3 itens aleatórios baseados no tier
      List<Item> itensFeirao = [];
      for (int i = 0; i < 3; i++) {
        final item = _itemService.gerarItemAleatorio(tierAtual: _historiaAtual.tier);
        itensFeirao.add(item);
      }

      _mostrarModalFeirao(itensFeirao, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao abrir feirão: $e');
    }

    setState(() { _comprando = false; });
  }

  void _mostrarModalFeirao(List<Item> itens, HistoriaJogador historia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B4513),
                const Color(0xFF2F1B14),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF8C00).withOpacity(0.8),
                      const Color(0xFF8B4513).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: Icon(Icons.store, color: const Color(0xFFD4AF37), size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '🏪 Feirão do Vigarista 🏪',
                        style: TextStyle(
                          color: const Color(0xFFD4AF37),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          shadows: [
                            Shadow(
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Descrição
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Escolha quais itens deseja comprar por $custoAposta moedas cada',
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 16,
                    fontFamily: 'serif',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Itens
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: itens.length,
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      return _buildItemFeirao(item, historia);
                    },
                  ),
                ),
              ),
              // Footer com botão de sair
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2F1B14),
                      const Color(0xFF654321),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD4AF37).withOpacity(0.2),
                            const Color(0xFFFFD700).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on, color: const Color(0xFFD4AF37), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Ouro: ${ScoreConfig.formatarScoreExibicao(_historiaAtual.tier, _historiaAtual.score)}',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B0000),
                            const Color(0xFF654321),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Sair do Feirão',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
    );
  }

  Widget _buildItemFeirao(Item item, HistoriaJogador historia) {
    bool podeComprar = _historiaAtual.score >= custoAposta && !_comprando;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF654321).withOpacity(0.6),
            const Color(0xFF8B4513).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome e raridade do item
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.raridade.cor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: item.raridade.cor, width: 1),
                ),
                child: Text(
                  item.raridade.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.nome,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Descrição
          Text(
            'Item de qualidade ${item.raridade.nome} obtido no Feirão',
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // Stats do item
          Row(
            children: [
              _buildStatChip('Ataque', '+${item.ataque}', Colors.red),
              const SizedBox(width: 8),
              _buildStatChip('Defesa', '+${item.defesa}', Colors.blue),
              const SizedBox(width: 8),
              _buildStatChip('Vida', '+${item.vida}', Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          // Botão de comprar
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: podeComprar
                    ? LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37),
                          const Color(0xFFFFD700),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade600,
                          Colors.grey.shade400,
                        ],
                      ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: podeComprar ? const Color(0xFF8B4513) : Colors.grey,
                  width: 2,
                ),
              ),
              child: ElevatedButton(
                onPressed: podeComprar ? () => _comprarItemFeirao(item, historia) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: podeComprar ? const Color(0xFF2F1B14) : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comprar por $custoAposta moedas',
                      style: TextStyle(
                        color: podeComprar ? const Color(0xFF2F1B14) : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: cor),
          ),
          const SizedBox(width: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  void _comprarItemFeirao(Item item, HistoriaJogador historia) async {
    if (_comprando || _historiaAtual.score < custoAposta) return;

    setState(() { _comprando = true; });

    try {
      // Desconta o custo do item
      final historiaAtualizada = _historiaAtual.copyWith(
        score: _historiaAtual.score - custoAposta,
      );

      // Atualiza história local
      setState(() {
        _historiaAtual = historiaAtualizada;
      });
      widget.onHistoriaAtualizada(historiaAtualizada);

      // Fecha o modal do feirão
      Navigator.of(context).pop();

      // Mostra o modal de item obtido
      _mostrarResultadoItem(item, historiaAtualizada);

    } catch (e) {
      _mostrarErro('Erro ao comprar item: $e');
    }

    setState(() { _comprando = false; });
  }

  Habilidade _gerarHabilidadeAleatoria() {
    final random = Random();
    final tipos = Tipo.values;
    final tipoAleatorio = tipos[random.nextInt(tipos.length)];
    final tierAtual = widget.historia.tier;
    
    final habilidades = GeradorHabilidades.gerarHabilidadesMonstro(tipoAleatorio, null, levelCustomizado: tierAtual);
    
    if (habilidades.isNotEmpty) {
      // A habilidade já foi gerada com o level correto
      return habilidades.first;
    }
    
    // Habilidade fallback também usa o tier atual
    return Habilidade(
      nome: 'Habilidade Misteriosa',
      descricao: 'Uma habilidade obtida na Casa do Vigarista',
      tipo: TipoHabilidade.ofensiva,
      efeito: EfeitoHabilidade.danoDirecto,
      tipoElemental: tipoAleatorio,
      valor: 10 * tierAtual, // Valor escalado com o tier
      custoEnergia: (5 * tierAtual).clamp(5, 50), // Custo escalado mas limitado
      level: tierAtual, // Level igual ao tier atual
    );
  }

  void _mostrarResultadoItem(Item item, HistoriaJogador historia) {
    // Usa o modal existente de item obtido
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalItemObtido(
        item: item,
        monstrosDisponiveis: historia.monstros,
        onEquiparItem: (monstro, itemObtido) async {
          // Atualiza o monstro com o novo item
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(itemEquipado: itemObtido);
            }
            return m;
          }).toList();
          
          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);
          
          // Fecha a Casa do Vigarista após equipar o item
          Navigator.of(context).pop(); // Fecha o Casa do Vigarista
          
          _mostrarMensagemSucesso('Item ${itemObtido.nome} equipado em ${monstro.tipo.displayName}!');
        },
      ),
    );
  }

  void _mostrarResultadoMagia(Habilidade habilidade, HistoriaJogador historia) {
    
    // Converte Habilidade para MagiaDrop
    final magia = MagiaDrop(
      nome: habilidade.nome,
      descricao: habilidade.descricao,
      tipo: habilidade.tipo,
      efeito: habilidade.efeito,
      valor: habilidade.valor,
      custoEnergia: habilidade.custoEnergia,
      level: habilidade.level,
      dataObtencao: DateTime.now(),
    );
    
    // Usa o modal existente de magia obtida
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalMagiaObtida(
        magia: magia,
        monstrosDisponiveis: historia.monstros,
        onEquiparMagia: (monstro, magiaObtida, habilidadeSubstituida) async {
          // Escolhe o tipo elemental (50% cada tipo do monstro)
          final tipos = [monstro.tipo, monstro.tipoExtra];
          final tipoElemental = tipos[Random().nextInt(tipos.length)];

          // Converte MagiaDrop de volta para Habilidade
          final novaHabilidade = Habilidade(
            nome: magiaObtida.nome,
            descricao: magiaObtida.descricao,
            tipo: magiaObtida.tipo,
            efeito: magiaObtida.efeito,
            tipoElemental: tipoElemental, // Sorteia entre os tipos do monstro (50% cada)
            valor: magiaObtida.valor,
            custoEnergia: magiaObtida.custoEnergia,
            level: magiaObtida.level,
          );
          
          // Substitui a habilidade no monstro
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              final novasHabilidades = m.habilidades.map((h) {
                return h == habilidadeSubstituida ? novaHabilidade : h;
              }).toList();
              return m.copyWith(habilidades: novasHabilidades);
            }
            return m;
          }).toList();
          
          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);
          
          // Fecha a Casa do Vigarista após equipar a magia
          Navigator.of(context).pop(); // Fecha o Casa do Vigarista
          
          _mostrarMensagemSucesso('${monstro.tipo.displayName} aprendeu ${novaHabilidade.nome}!');
        },
      ),
    );
  }

  void _mostrarResultadoCura(int porcentagem, HistoriaJogador historia) {
    // Usa o modal existente de cura obtida
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalCuraObtida(
        porcentagem: porcentagem,
        monstrosDisponiveis: historia.monstros,
        onCurarMonstro: (monstro, porcentagemCura) async {
          // Calcula a cura
          final curaTotal = (monstro.vida * porcentagemCura / 100).round();
          final novaVidaAtual = (monstro.vidaAtual + curaTotal).clamp(0, monstro.vida);
          
          // Atualiza o monstro com a nova vida
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(vidaAtual: novaVidaAtual);
            }
            return m;
          }).toList();
          
          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);
          
          // Fecha a Casa do Vigarista após curar o monstro
          Navigator.of(context).pop(); // Fecha o Casa do Vigarista
          
          _mostrarMensagemSucesso('${monstro.tipo.displayName} foi curado em $porcentagemCura%!');
        },
      ),
    );
  }


  void _mostrarMensagemSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() { _comprando = false; });
  }
}