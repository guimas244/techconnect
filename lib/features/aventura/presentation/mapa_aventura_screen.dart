import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      body: Stack(
        children: [
          // Imagem do mapa de fundo
          Positioned.fill(
            child: Image.asset(
              widget.mapaPath,
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
          _buildPontoMapa(0, 0.2, 0.3), // Ponto 1 - Superior esquerdo
          _buildPontoMapa(1, 0.7, 0.2), // Ponto 2 - Superior direito
          _buildPontoMapa(2, 0.5, 0.5), // Ponto 3 - Centro
          _buildPontoMapa(3, 0.3, 0.7), // Ponto 4 - Inferior esquerdo
          _buildPontoMapa(4, 0.8, 0.8), // Ponto 5 - Inferior direito
        ],
      ),
    );
  }

  Widget _buildPontoMapa(int index, double left, double top) {
    if (index >= widget.monstrosInimigos.length) {
      return const SizedBox.shrink();
    }

    final monstro = widget.monstrosInimigos[index];
    
    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: MediaQuery.of(context).size.height * top,
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
