import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/mapa_explorador.dart';
import '../providers/equipe_explorador_provider.dart';
import '../providers/mapas_explorador_provider.dart';
import './mapa_explorador_screen.dart';
import '../../../shared/models/tipo_enum.dart';

/// Tela de selecao de mapa do Modo Explorador
///
/// Apos cada 3 batalhas, o jogador escolhe entre 3 mapas
/// Cada mapa tem chance de subir/descer/manter tier
class SelecaoMapaScreen extends ConsumerStatefulWidget {
  const SelecaoMapaScreen({super.key});

  @override
  ConsumerState<SelecaoMapaScreen> createState() => _SelecaoMapaScreenState();
}

class _SelecaoMapaScreenState extends ConsumerState<SelecaoMapaScreen> {
  @override
  void initState() {
    super.initState();
    // Gera mapas apenas se ainda nao existirem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapasExploradorProvider.notifier).gerarMapasSePreciso();
    });
  }

  void _gerarNovosMapas() {
    ref.read(mapasExploradorProvider.notifier).gerarNovosMapas();
  }

  /// Verifica se o mapa esta desabilitado (jogador desistiu)
  bool _mapaDesabilitado(int index) {
    return ref.read(mapasExploradorProvider.notifier).isDesistido(index);
  }

  @override
  Widget build(BuildContext context) {
    final equipe = ref.watch(equipeExploradorProvider);
    final mapasState = ref.watch(mapasExploradorProvider);
    final mapasDisponiveis = mapasState.mapas;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Selecionar Mapa'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/explorador'),
        ),
        actions: [
          // Tier atual
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Tier ${equipe?.tierAtual ?? 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mapas_aventura/floresta_verde.jpg'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map, color: Colors.teal, size: 24),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Escolha seu proximo destino',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.teal),
                          tooltip: 'Gerar novos mapas',
                          onPressed: _gerarNovosMapas,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada mapa leva a um tier diferente e tem inimigos especificos',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Status da equipe
              if (equipe != null && equipe.monstrosAtivos.isEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Equipe vazia!',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Adicione monstros a equipe antes de batalhar',
                              style: TextStyle(
                                color: Colors.orange.shade200,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/explorador/equipe'),
                        child: const Text('Ir'),
                      ),
                    ],
                  ),
                ),

              // Lista de mapas
              Expanded(
                child: mapasDisponiveis == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: mapasDisponiveis.length,
                        itemBuilder: (context, index) {
                          return _buildMapaCard(mapasDisponiveis[index], equipe, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retorna o caminho do icone do tipo
  String _getIconeTipo(Tipo tipo) {
    return 'assets/tipagens/icon_tipo_${tipo.name}.png';
  }

  /// Retorna a cor da raridade do mapa
  Color _getCorRaridade(RaridadeMapa raridade) {
    switch (raridade) {
      case RaridadeMapa.comum:
        return Colors.grey;
      case RaridadeMapa.bonusXp:
        return Colors.green;
      case RaridadeMapa.umElite:
        return Colors.blue;
      case RaridadeMapa.todosElite:
        return Colors.purple;
      case RaridadeMapa.boss:
        return Colors.orange;
    }
  }

  Widget _buildMapaCard(MapaExplorador mapa, dynamic equipe, int index) {
    final desistiu = _mapaDesabilitado(index);
    final podeJogar = equipe != null && equipe.monstrosAtivos.isNotEmpty && !desistiu;

    Color corTendencia;
    IconData iconeTendencia;

    switch (mapa.tendencia) {
      case TendenciaTier.subir:
        corTendencia = Colors.green;
        iconeTendencia = Icons.arrow_upward;
        break;
      case TendenciaTier.manter:
        corTendencia = Colors.amber;
        iconeTendencia = Icons.arrow_forward;
        break;
      case TendenciaTier.descer:
        corTendencia = Colors.red;
        iconeTendencia = Icons.arrow_downward;
        break;
    }

    return GestureDetector(
      onTap: podeJogar ? () => _selecionarMapa(mapa, index) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: podeJogar
                ? mapa.tipoPrincipal.cor.withAlpha(150)
                : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Conteudo do card
            Column(
              children: [
                // Imagem do mapa
                ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Stack(
                        children: [
                          Image.asset(
                            mapa.imagem,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: mapa.tipoPrincipal.cor.withAlpha(50),
                              child: Center(
                                child: Icon(
                                  mapa.tipoPrincipal.icone,
                                  size: 48,
                                  color: mapa.tipoPrincipal.cor,
                                ),
                              ),
                            ),
                          ),
                          // Overlay com gradiente
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withAlpha(200),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Nome do mapa
                          Positioned(
                            left: 12,
                            bottom: 8,
                            child: Text(
                              mapa.nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                shadows: [
                                  Shadow(blurRadius: 4, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                          // Badge de tendencia
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: corTendencia.withAlpha(200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(iconeTendencia, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tier ${mapa.tierDestino}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Info do mapa
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Icones de tipos que serao encontrados (1 para boss, 3 para outros)
                          Row(
                            children: [
                              // Container com os tipos sorteados
                              Expanded(
                                child: Row(
                                  children: mapa.tiposEncontrados.map((tipo) {
                                    // Verifica se este tipo e nativo (tem vantagem +25% HP)
                                    final isNativo = mapa.tipoNativo(tipo);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Image.asset(
                                            _getIconeTipo(tipo),
                                            width: 32,
                                            height: 32,
                                            errorBuilder: (_, __, ___) => Icon(
                                              tipo.icone,
                                              size: 28,
                                              color: tipo.cor,
                                            ),
                                          ),
                                          // Estrela vermelha apenas para tipos nativos (+25% HP)
                                          if (isNativo)
                                            Positioned(
                                              right: -4,
                                              top: -4,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.black,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(1),
                                                child: const Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Raridade em estrelas
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < mapa.raridade.estrelas ? Icons.star : Icons.star_border,
                                        size: 16,
                                        color: _getCorRaridade(mapa.raridade),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mapa.raridade.descricao,
                                    style: TextStyle(
                                      color: _getCorRaridade(mapa.raridade),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Recompensas esperadas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // XP: Equipe + Banco
                              Column(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${mapa.xpBase} + ${mapa.xpBase}',
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              _buildRecompensa(
                                iconeTendencia,
                                mapa.tendencia.displayName,
                                corTendencia,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            // Badge "Desistiu" sobre o card
            if (desistiu)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(150),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'DESISTIU',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecompensa(IconData icone, String texto, Color cor) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 20),
        const SizedBox(height: 4),
        Text(
          texto,
          style: TextStyle(
            color: cor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _selecionarMapa(MapaExplorador mapa, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            // Mostra os tipos que serao encontrados
            ...mapa.tiposEncontrados.map((tipo) {
              final isNativo = mapa.tipoNativo(tipo);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      _getIconeTipo(tipo),
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => Icon(
                        tipo.icone,
                        size: 20,
                        color: tipo.cor,
                      ),
                    ),
                    if (isNativo)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Icon(Icons.star, size: 10, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mapa.nome,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tier destino: ${mapa.tierDestino}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Inimigos: ${mapa.tiposEncontrados.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 8),
                ...mapa.tiposEncontrados.map((tipo) {
                  final isNativo = mapa.tipoNativo(tipo);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          _getIconeTipo(tipo),
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => Icon(
                            tipo.icone,
                            size: 16,
                            color: tipo.cor,
                          ),
                        ),
                        if (isNativo)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(1),
                              child: const Icon(Icons.star, size: 8, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mapa.descricaoTendencia,
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deseja iniciar a batalha?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            onPressed: () {
              Navigator.pop(context);
              _iniciarBatalha(mapa, index);
            },
            child: const Text('Batalhar!'),
          ),
        ],
      ),
    );
  }

  /// Inicia a exploracao do mapa selecionado
  Future<void> _iniciarBatalha(MapaExplorador mapa, int index) async {
    final equipe = ref.read(equipeExploradorProvider);
    if (equipe == null || equipe.monstrosAtivos.isEmpty) return;

    // Navega para a tela de mapa com monstros
    if (!mounted) return;
    final resultado = await Navigator.push<ResultadoMapa>(
      context,
      MaterialPageRoute(
        builder: (context) => MapaExploradorScreen(mapa: mapa),
      ),
    );

    if (!mounted) return;

    if (resultado == ResultadoMapa.completado) {
      // Jogador completou o mapa - gera novos mapas (limpa desistidos automaticamente)
      ref.read(mapasExploradorProvider.notifier).gerarNovosMapas();
    } else if (resultado == ResultadoMapa.desistiu) {
      // Jogador desistiu - marca o mapa como desabilitado no provider
      ref.read(mapasExploradorProvider.notifier).marcarDesistido(index);
    }
    // Se resultado for null (voltou sem acao), nao faz nada
  }
}
