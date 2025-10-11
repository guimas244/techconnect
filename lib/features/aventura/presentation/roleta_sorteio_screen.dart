import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/monstro_aventura.dart';

/// Tela de roleta de sorteio de 1 monstro único
class RoletaSorteioScreen extends StatefulWidget {
  final MonstroAventura monstroSorteado;

  const RoletaSorteioScreen({
    super.key,
    required this.monstroSorteado,
  });

  @override
  State<RoletaSorteioScreen> createState() => _RoletaSorteioScreenState();
}

class _RoletaSorteioScreenState extends State<RoletaSorteioScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _mostrarResultado = false;

  @override
  void initState() {
    super.initState();

    // Animação de rotação
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: math.pi * 8, // 4 voltas completas
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Inicia a animação
    _iniciarRoleta();
  }

  Future<void> _iniciarRoleta() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _controller.forward();

    // Mostra o resultado após a animação
    setState(() {
      _mostrarResultado = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons_gerais/roleta.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Roleta de Sorteio',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFe76f51),
                    ),
                  ),
                ],
              ),
            ),

            // Área da roleta
            Expanded(
              child: Center(
                child: _mostrarResultado
                    ? _buildResultado()
                    : _buildRoletaGirando(),
              ),
            ),

            // Botão de continuar (só aparece após resultado)
            if (_mostrarResultado)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(widget.monstroSorteado),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe76f51),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Adicionar à Equipe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoletaGirando() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: 200,
            height: 280,
            decoration: BoxDecoration(
              color: widget.monstroSorteado.tipo.cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.monstroSorteado.tipo.cor,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: widget.monstroSorteado.tipo.cor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultado() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.monstroSorteado.tipo.cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.monstroSorteado.tipo.cor,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagem do monstro
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Image.asset(
                    widget.monstroSorteado.imagem,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.pets,
                        size: 100,
                        color: widget.monstroSorteado.tipo.cor,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Nome do monstro
                Text(
                  widget.monstroSorteado.tipo.monsterName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.monstroSorteado.tipo.cor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Tipo
                Text(
                  widget.monstroSorteado.tipo.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                // Level
                Text(
                  'Level ${widget.monstroSorteado.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
