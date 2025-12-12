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
import '../services/auto_mode_service.dart';
import '../../../shared/models/tipo_enum.dart';
import 'package:remixicon/remixicon.dart';

class SelecaoMonstroScreen extends ConsumerStatefulWidget {
  final MonstroInimigo monstroInimigo;
  final bool autoMode; // Modo automático - seleciona melhor monstro automaticamente

  const SelecaoMonstroScreen({
    super.key,
    required this.monstroInimigo,
    this.autoMode = false,
  });

  @override
  ConsumerState<SelecaoMonstroScreen> createState() => _SelecaoMonstroScreenState();
}

class _SelecaoMonstroScreenState extends ConsumerState<SelecaoMonstroScreen> {
  final AutoModeService _autoModeService = AutoModeService();
  bool _processandoAutoMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoMode) {
      // Agenda execução do auto mode após o primeiro frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _executarAutoMode();
      });
    }
  }

  Future<void> _executarAutoMode() async {
    if (_processandoAutoMode) return;

    setState(() {
      _processandoAutoMode = true;
    });

    try {
      print('🤖 [AutoMode] Iniciando seleção automática de monstro...');

      // Carrega história do jogador
      final historia = await _carregarHistoriaJogador(ref);
      if (historia == null || historia.monstros.isEmpty) {
        print('❌ [AutoMode] Sem monstros disponíveis');
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      // Seleciona o melhor monstro
      final melhorMonstro = await _autoModeService.selecionarMelhorMonstro(
        historia.monstros,
        widget.monstroInimigo,
      );

      if (melhorMonstro == null) {
        print('❌ [AutoMode] Nenhum monstro vivo disponível');
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      print('✅ [AutoMode] Monstro selecionado: ${melhorMonstro.tipo.displayName}');

      if (!mounted) return;

      // Vai direto para a batalha com modo auto ativado
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BatalhaScreen(
            jogador: melhorMonstro,
            inimigo: widget.monstroInimigo,
            equipeCompleta: historia.monstros,
            autoMode: true, // Passa o modo auto para a batalha
          ),
        ),
      );

      if (!mounted) return;

      if (resultado == true && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      print('❌ [AutoMode] Erro: $e');
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se estiver em modo auto e processando, mostra loading
    if (widget.autoMode && _processandoAutoMode) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '🤖 Modo Automático',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecionando melhor monstro...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      onTap: () => _mostrarDetalheMonstroInimigo(context, widget.monstroInimigo),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.monstroInimigo.tipo.cor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.monstroInimigo.tipo.cor.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.monstroInimigo.tipo.cor.withValues(alpha: 0.3),
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
                                  image: AssetImage(widget.monstroInimigo.imagem),
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
                                      image: AssetImage(widget.monstroInimigo.tipo.iconAsset),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                if (widget.monstroInimigo.tipoExtra != null) ...[
                                  const SizedBox(width: 4),
                                  // Tipo extra
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      image: DecorationImage(
                                        image: AssetImage(widget.monstroInimigo.tipoExtra!.iconAsset),
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
                            widget.monstroInimigo.tipo.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Vida: ${widget.monstroInimigo.vida} | Ataque: ${widget.monstroInimigo.ataque} | Defesa: ${widget.monstroInimigo.defesa}',
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
                        monstro.nome,
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
        _buildSingleDanoDefensivoIndicator(widget.monstroInimigo.tipo, monstro.tipo, ref),
        const SizedBox(width: 4),
        // Dano que o tipo principal do inimigo causa no meu tipo extra
        _buildSingleDanoDefensivoIndicator(widget.monstroInimigo.tipo, monstro.tipoExtra, ref),
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
        tipoDefensorPrincipal: widget.monstroInimigo.tipo, // Apenas tipo principal do inimigo
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

  Future<void> _selecionarMonstro(BuildContext context, MonstroAventura monstro, WidgetRef ref) async {
    // Carrega história para passar equipe completa (para verificar passivas)
    HistoriaJogador? historia;
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      historia = await repository.carregarHistoricoJogador(emailJogador);
    } catch (e) {
      print('❌ [SelecaoMonstro] Erro ao carregar história: $e');
    }

    if (!context.mounted) return;

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BatalhaScreen(
          jogador: monstro,
          inimigo: widget.monstroInimigo,
          equipeCompleta: historia?.monstros ?? [],
        ),
      ),
    );

    if (!context.mounted) return;

    if (resultado == true && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
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


