import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../models/monstro_inimigo.dart';
import '../presentation/modal_monstro_inimigo.dart';

class MapaAventuraScreen extends ConsumerStatefulWidget {
  final String mapaPath;
  final List<MonstroInimigo> monstrosInimigos;

  const MapaAventuraScreen({
    super.key,
    required this.mapaPath,
    required this.monstrosInimigos,
  });

  @override
  ConsumerState<MapaAventuraScreen> createState() => _MapaAventuraScreenState();
}

class _MapaAventuraScreenState extends ConsumerState<MapaAventuraScreen> {
  late String mapaEscolhido;
  
  final List<String> mapasDisponiveis = [
    'assets/mapas_aventura/cidade_abandonada.jpg',
    'assets/mapas_aventura/deserto.jpg',
    'assets/mapas_aventura/floresta_verde.jpg',
    'assets/mapas_aventura/praia.jpg',
    'assets/mapas_aventura/vulcao.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Sorteia um mapa aleatório
    final random = Random();
    mapaEscolhido = mapasDisponiveis[random.nextInt(mapasDisponiveis.length)];
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Mapa de Aventura'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Imagem do mapa de fundo
            Positioned.fill(
              child: Image.asset(
                mapaEscolhido,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Text(
                        'Mapa não encontrado',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Pontos interativos do mapa (5 pontos fixos)
            _buildPontoMapa(0, 0.2, 0.2), // Ponto 1 - Superior esquerdo
            _buildPontoMapa(1, 0.7, 0.15), // Ponto 2 - Superior direito
            _buildPontoMapa(2, 0.5, 0.45), // Ponto 3 - Centro
            _buildPontoMapa(3, 0.25, 0.65), // Ponto 4 - Inferior esquerdo
            _buildPontoMapa(4, 0.75, 0.78), // Ponto 5 - Inferior direito (ajustado para não colar na borda)
          ],
        ),
      ),
    );
  }

  Widget _buildPontoMapa(int index, double left, double top) {
    if (index >= widget.monstrosInimigos.length) {
      return const SizedBox.shrink();
    }

    final monstro = widget.monstrosInimigos[index];
    
    // Limita a posição máxima do topo para não colar na borda inferior
    final screenHeight = MediaQuery.of(context).size.height;
    final maxTop = screenHeight * 0.85;
    final calcTop = (screenHeight * top).clamp(0, maxTop).toDouble();
    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: calcTop,
      child: GestureDetector(
        onTap: () => _mostrarModalMonstroInimigo(monstro),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: monstro.tipo.cor.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: monstro.tipo.cor.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.pets,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  void _mostrarModalMonstroInimigo(MonstroInimigo monstro) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ModalMonstroInimigo(monstro: monstro);
      },
    );
  }
}
