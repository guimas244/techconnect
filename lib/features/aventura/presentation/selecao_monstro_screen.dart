import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/historia_jogador.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../presentation/batalha_screen.dart';
import 'modal_monstro_aventura.dart';
import 'modal_monstro_inimigo.dart';
import '../services/matchup_service.dart';
import '../../../shared/models/tipo_enum.dart';
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
                    // Imagem e tipos do monstro inimigo com borda
                    GestureDetector(
                      onTap: () => _mostrarDetalheMonstroInimigo(context, monstroInimigo),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: monstroInimigo.tipo.cor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: monstroInimigo.tipo.cor.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: monstroInimigo.tipo.cor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Imagem do monstro inimigo
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
                            const SizedBox(height: 8),
                            // Tipos do monstro inimigo
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tipo principal
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    image: DecorationImage(
                                      image: AssetImage(monstroInimigo.tipo.iconAsset),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                if (monstroInimigo.tipoExtra != null) ...[
                                  const SizedBox(width: 4),
                                  // Tipo extra
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      image: DecorationImage(
                                        image: AssetImage(monstroInimigo.tipoExtra!.iconAsset),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
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
                // Imagem e tipos do monstro com borda
                GestureDetector(
                  onTap: () => _mostrarDetalheMonstro(context, monstro),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: monstro.tipo.cor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: monstro.tipo.cor.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: monstro.tipo.cor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
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
                        const SizedBox(height: 8),
                        // Tipos do monstro
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tipo principal
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: AssetImage(monstro.tipo.iconAsset),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Tipo extra
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: AssetImage(monstro.tipoExtra.iconAsset),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                      const SizedBox(height: 6),
                      // 3ª linha: Dano que EU causo NO inimigo
                      Row(
                        children: [
                          Icon(Remix.sword_fill, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          _buildDanoOfensivoIndicators(context, monstro, ref),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 4ª linha: Dano que EU recebo DO inimigo
                      Row(
                        children: [
                          Icon(Icons.shield, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          _buildDanoDefensivoIndicators(context, monstro, ref),
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

  // 3ª linha: Dano que MEU monstro causa NO inimigo
  Widget _buildDanoOfensivoIndicators(BuildContext context, MonstroAventura monstro, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dano do tipo principal do meu monstro no inimigo
        _buildSingleDanoOfensivoIndicator(monstro.tipo, ref),
        const SizedBox(width: 4),
        // Dano do tipo extra do meu monstro no inimigo
        _buildSingleDanoOfensivoIndicator(monstro.tipoExtra, ref),
      ],
    );
  }

  // 4ª linha: Dano que EU recebo DO inimigo
  Widget _buildDanoDefensivoIndicators(BuildContext context, MonstroAventura monstro, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dano que o tipo principal do inimigo causa no meu tipo principal
        _buildSingleDanoDefensivoIndicator(monstroInimigo.tipo, monstro.tipo, ref),
        const SizedBox(width: 4),
        // Dano que o tipo principal do inimigo causa no meu tipo extra
        _buildSingleDanoDefensivoIndicator(monstroInimigo.tipo, monstro.tipoExtra, ref),
      ],
    );
  }

  // Indicador ofensivo: MEU tipo vs INIMIGO
  Widget _buildSingleDanoOfensivoIndicator(Tipo meuTipo, WidgetRef ref) {
    return FutureBuilder<MatchupResult>(
      future: _calcularDanoOfensivo(meuTipo, ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 16, height: 16);
        }

        final resultado = snapshot.data!;

        String iconAsset;
        if (resultado.temVantagem) {
          iconAsset = 'assets/icons_gerais/tabela_vantagem.png';
        } else if (resultado.temDesvantagem) {
          iconAsset = 'assets/icons_gerais/tabela_desvantagem.png';
        } else {
          iconAsset = 'assets/icons_gerais/tabela_igual.png';
        }

        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            iconAsset,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  // Indicador defensivo: INIMIGO vs MEU tipo
  Widget _buildSingleDanoDefensivoIndicator(Tipo tipoInimigo, Tipo meuTipo, WidgetRef ref) {
    return FutureBuilder<MatchupResult>(
      future: _calcularDanoDefensivo(tipoInimigo, meuTipo, ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 16, height: 16);
        }

        final resultado = snapshot.data!;

        String iconAsset;
        if (resultado.temVantagem) {
          iconAsset = 'assets/icons_gerais/tabela_desvantagem.png'; // Inverso: se inimigo tem vantagem, eu levo mais dano
        } else if (resultado.temDesvantagem) {
          iconAsset = 'assets/icons_gerais/tabela_vantagem.png'; // Inverso: se inimigo tem desvantagem, eu levo menos dano
        } else {
          iconAsset = 'assets/icons_gerais/tabela_igual.png';
        }

        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            iconAsset,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  // Calcula dano ofensivo: MEU tipo ataca INIMIGO
  Future<MatchupResult> _calcularDanoOfensivo(Tipo meuTipo, WidgetRef ref) async {
    try {
      final matchupService = ref.read(matchupServiceProvider);

      // MEU tipo ataca o tipo principal do INIMIGO
      return await matchupService.calcularMatchup(
        tipoAtacantePrincipal: meuTipo,
        tipoAtacanteExtra: null, // Apenas um tipo por vez
        tipoDefensorPrincipal: monstroInimigo.tipo, // Apenas tipo principal do inimigo
        tipoDefensorExtra: null, // Ignora tipo extra do inimigo conforme solicitado
        mixOfensivo: 1.0, // 100% do meu tipo
      );
    } catch (e) {
      print('❌ Erro ao calcular dano ofensivo: $e');
      return MatchupResult.neutro();
    }
  }

  // Calcula dano defensivo: INIMIGO ataca MEU tipo
  Future<MatchupResult> _calcularDanoDefensivo(Tipo tipoInimigo, Tipo meuTipo, WidgetRef ref) async {
    try {
      final matchupService = ref.read(matchupServiceProvider);

      // Tipo principal do INIMIGO ataca MEU tipo
      return await matchupService.calcularMatchup(
        tipoAtacantePrincipal: tipoInimigo, // Apenas tipo principal do inimigo
        tipoAtacanteExtra: null, // Apenas um tipo por vez
        tipoDefensorPrincipal: meuTipo, // MEU tipo defendendo
        tipoDefensorExtra: null, // Apenas um tipo por vez
        mixOfensivo: 1.0, // 100% do tipo do inimigo
      );
    } catch (e) {
      print('❌ Erro ao calcular dano defensivo: $e');
      return MatchupResult.neutro();
    }
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

  void _mostrarDetalheMonstro(BuildContext context, MonstroAventura monstro) {
    showDialog(
      context: context,
      builder: (context) => ModalMonstroAventura(monstro: monstro),
    );
  }

  void _mostrarDetalheMonstroInimigo(BuildContext context, MonstroInimigo monstroInimigo) {
    showDialog(
      context: context,
      builder: (context) => ModalMonstroInimigo(monstro: monstroInimigo),
    );
  }

}
