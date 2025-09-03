import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/historia_jogador.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../presentation/batalha_screen.dart';
import 'package:remixicon/remixicon.dart';

class SelecaoMonstroScreen extends ConsumerWidget {
  final MonstroInimigo monstroInimigo;

  const SelecaoMonstroScreen({
    super.key,
    required this.monstroInimigo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Escolha seu Monstro'),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<HistoriaJogador?>(
        future: _carregarHistoriaJogador(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Erro ao carregar seus monstros'),
            );
          }

          final historia = snapshot.data!;
          final monstros = historia.monstros;

          if (monstros.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum monstro disponível!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Inimigo
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(monstroInimigo.imagem),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INIMIGO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          Text(
                            monstroInimigo.tipo.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Vida: ${monstroInimigo.vida} | Ataque: ${monstroInimigo.ataque} | Defesa: ${monstroInimigo.defesa}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divisor
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              // Lista de monstros do jogador
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Escolha seu monstro para a batalha:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: monstros.length,
                  itemBuilder: (context, index) {
                    final monstro = monstros[index];
                    return _buildMonstroCard(context, monstro, ref);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonstroCard(BuildContext context, MonstroAventura monstro, WidgetRef ref) {
    final isMorto = monstro.vidaAtual <= 0;
    return Opacity(
      opacity: isMorto ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: monstro.tipo.cor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isMorto ? null : () => _selecionarMonstro(context, monstro, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagem do monstro
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(monstro.imagem),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Informações do monstro
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monstro.tipo.monsterName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatChip(Icons.favorite, '${monstro.vida}', Colors.red),
                          const SizedBox(width: 8),
                          _buildStatChip(Remix.sword_fill, '${monstro.ataque}', Colors.orange),
                          const SizedBox(width: 8),
                          _buildStatChip(Icons.shield, '${monstro.defesa}', Colors.blue),
                          const SizedBox(width: 8),
                          _buildStatChip(Icons.speed, '${monstro.agilidade}', Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
                // Ícone de seleção ou morto
                isMorto
                  ? Icon(Icons.close, color: Colors.grey, size: 32)
                  : Icon(Icons.play_circle_fill, color: monstro.tipo.cor, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<HistoriaJogador?> _carregarHistoriaJogador(WidgetRef ref) async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      return await repository.carregarHistoricoJogador(emailJogador);
    } catch (e) {
      print('❌ [SelecaoMonstro] Erro ao carregar história: $e');
      return null;
    }
  }

  void _selecionarMonstro(BuildContext context, MonstroAventura monstro, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatalhaScreen(
          jogador: monstro,
          inimigo: monstroInimigo,
        ),
      ),
    );
  }
}
