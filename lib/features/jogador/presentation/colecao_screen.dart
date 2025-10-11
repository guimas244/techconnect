import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../monstros/aventura/models/monstro_aventura.dart';
import '../../monstros/aventura/data/monstro_aventura_repository.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/services/colecao_service.dart';
import '../../../core/services/storage_service.dart';

const _grayscaleFilter = ColorFilter.matrix([
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

const _identityFilter = ColorFilter.matrix([
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

// Provider para o repository
final monstroAventuraRepositoryProvider = Provider<MonstroAventuraRepository>((
  ref,
) {
  return MonstroAventuraRepository();
});

// Provider para lista de monstros
final monstrosListProvider = FutureProvider<List<MonstroAventura>>((ref) async {
  final repository = ref.watch(monstroAventuraRepositoryProvider);
  return await repository.listarMonstros();
});

class ColecaoScreen extends StatefulWidget {
  const ColecaoScreen({super.key});

  @override
  State<ColecaoScreen> createState() => _ColecaoScreenState();
}

class _ColecaoScreenState extends State<ColecaoScreen> with SingleTickerProviderStateMixin {
  String? monstroExpandido;
  MonstroAventura? _monstroExpandidoData; // Guarda os dados do monstro clicado
  final ColecaoService _colecaoService = ColecaoService();
  final StorageService _storageService = StorageService();
  Map<String, bool> _colecaoAtual = {};
  bool _carregandoColecao = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarColecao();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarColecao() async {
    setState(() => _carregandoColecao = true);
    try {
      final email = await _storageService.getLastEmail();
      if (email != null) {
        final colecao = await _colecaoService.carregarColecaoJogador(email);
        setState(() {
          _colecaoAtual = colecao;
          _carregandoColecao = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar coleção no catálogo: $e');
      setState(() => _carregandoColecao = false);
    }
  }

  Future<void> _refreshColecao() async {
    try {
      final email = await _storageService.getLastEmail();
      if (email != null) {
        await _colecaoService.refreshColecao(email);
        await _carregarColecao();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coleção atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar coleção: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Coleção'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Botão de refresh da coleção
          IconButton(
            icon:
                _carregandoColecao
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.refresh),
            onPressed: _carregandoColecao ? null : _refreshColecao,
            tooltip:
                _carregandoColecao ? 'Atualizando...' : 'Atualizar Coleção',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Eventos'),
          ],
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/background/templo.png',
              fit: BoxFit.cover,
            ),
          ),
          // TabBarView com as duas abas
          TabBarView(
            controller: _tabController,
            children: [
              // Aba Nostálgicos
              _buildAbaNostalgicos(),
              // Aba Halloween
              _buildAbaHalloween(),
            ],
          ),
          // Imagem expandida
          if (monstroExpandido != null && _monstroExpandidoData != null)
            GestureDetector(
              onTap: () => setState(() {
                monstroExpandido = null;
                _monstroExpandidoData = null;
              }),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.72)),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(color: Colors.black.withOpacity(0.04)),
                      ),
                    ),
                  ),
                  Center(
                    child: _buildMonstroDetalheCard(
                      context: context,
                      monstro: _monstroExpandidoData!,
                      estaBloqueado: _monstroExpandidoData!.colecao == 'colecao_inicial'
                          ? false
                          : _monstroExpandidoData!.colecao == 'colecao_halloween'
                              ? _colecaoAtual['halloween_${_monstroExpandidoData!.tipo1.name}'] != true
                              : _colecaoAtual[_monstroExpandidoData!.tipo1.name] != true,
                      heroTag: monstroExpandido!,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonstroDetalheCard({
    required BuildContext context,
    required MonstroAventura monstro,
    required bool estaBloqueado,
    required String heroTag,
  }) {
    final size = MediaQuery.of(context).size;
    final width = math.min(size.width * 0.85, 420.0);
    final height = math.min(size.height * 0.75, 520.0);
    final baseColor = monstro.tipo1.cor;

    final gradientColors =
        estaBloqueado
            ? [
              Colors.grey.shade900.withOpacity(0.9),
              Colors.grey.shade700.withOpacity(0.75),
            ]
            : [baseColor.withOpacity(0.95), baseColor.withOpacity(0.55)];

    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: width,
        constraints: BoxConstraints(maxHeight: height),
        padding: const EdgeInsets.fromLTRB(28, 38, 28, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.35),
              blurRadius: 34,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height * 0.46,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Align(
                      child: Hero(
                        tag: heroTag,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: ColorFiltered(
                            colorFilter:
                                estaBloqueado
                                    ? _grayscaleFilter
                                    : _identityFilter,
                            child: Image.asset(
                              'assets/monstros_aventura/${monstro.colecao}/${monstro.tipo1.name}.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (estaBloqueado)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              monstro.nome,
              textAlign: TextAlign.center,
              style:
                  textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ) ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 18),
            _buildTipoChip(monstro.tipo1, estaBloqueado),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoChip(Tipo tipo, bool estaBloqueado) {
    final baseColor = tipo.cor;
    final backgroundColor =
        estaBloqueado
            ? Colors.black.withOpacity(0.35)
            : baseColor.withOpacity(0.35);
    final borderColor =
        estaBloqueado ? Colors.white24 : baseColor.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            width: 32,
            child: Image.asset(
              tipo.iconAsset,
              color: estaBloqueado ? Colors.white70 : null,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) => Icon(
                    tipo.icone,
                    color: Colors.white.withOpacity(estaBloqueado ? 0.8 : 1),
                    size: 26,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIPO PRINCIPAL',
                style: TextStyle(
                  color: Colors.white.withOpacity(estaBloqueado ? 0.6 : 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                tipo.displayName,
                style: TextStyle(
                  color: Colors.white.withOpacity(estaBloqueado ? 0.85 : 1),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonstroItem(
    String nomeArquivo,
    Tipo tipo,
    MonstroAventura monstro,
    bool estaBloqueado,
  ) {
    // Usa tag única que inclui a coleção para evitar conflitos no Hero
    final tagUnico = '${monstro.colecao}_$nomeArquivo';

    return GestureDetector(
      onTap: () => setState(() {
        monstroExpandido = tagUnico;
        _monstroExpandidoData = monstro;
      }),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: tagUnico,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: ColorFiltered(
                    colorFilter:
                        estaBloqueado ? _grayscaleFilter : _identityFilter,
                    child: Image.asset(
                      'assets/monstros_aventura/${monstro.colecao}/$nomeArquivo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color:
                    estaBloqueado
                        ? Colors.grey.withOpacity(0.2)
                        : tipo.cor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                monstro.nome.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color:
                      estaBloqueado
                          ? Colors.grey.withOpacity(0.8)
                          : tipo.cor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aba dos monstros nostálgicos (coleção original)
  Widget _buildAbaNostalgicos() {
    return Consumer(
      builder: (context, ref, _) {
        final monstrosAsync = ref.watch(monstrosListProvider);
        return monstrosAsync.when(
          data: (monstros) {
            // Ordena monstros: primeiro coleção inicial, depois nostálgicos
            final monstrosOrdenados = List<MonstroAventura>.from(monstros);
            monstrosOrdenados.sort((a, b) {
              // Primeiro ordena por coleção (inicial antes de nostálgicos)
              if (a.colecao != b.colecao) {
                return a.colecao == 'colecao_inicial' ? -1 : 1;
              }
              // Depois ordena por nome do tipo
              return a.tipo1.name.compareTo(b.tipo1.name);
            });

            // Calcula progresso (total desbloqueados / total)
            final totalDesbloqueados = monstrosOrdenados
                .where((m) =>
                    m.colecao == 'colecao_inicial' ||
                    _colecaoAtual[m.tipo1.name] == true)
                .length;

            return Column(
              children: [
                // Badge de progresso
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '$totalDesbloqueados/${monstrosOrdenados.length} desbloqueados',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Grid de monstros
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: monstrosOrdenados.length,
                    itemBuilder: (context, index) {
                      final monstro = monstrosOrdenados[index];
                      final nomeArquivo = monstro.tipo1.name;
                      // Coleção inicial sempre desbloqueada, outras usam HIVE
                      final estaBloqueado = monstro.colecao == 'colecao_inicial'
                          ? false
                          : _colecaoAtual[nomeArquivo] != true;
                      return _buildMonstroItem(
                        nomeArquivo,
                        monstro.tipo1,
                        monstro,
                        estaBloqueado,
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar monstros: $error'),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Lista dos 30 tipos de monstros de eventos (Halloween)
  /// Os nomes serão buscados da coleção inicial + " Halloween"
  static const List<String> _tiposEventos = [
    'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
    'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
    'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
    'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
    'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi',
  ];

  /// Aba dos monstros de Eventos (Halloween)
  Widget _buildAbaHalloween() {
    return Consumer(
      builder: (context, ref, _) {
        final monstrosAsync = ref.watch(monstrosListProvider);
        return monstrosAsync.when(
          data: (monstrosOriginais) {
            // Cria monstros de eventos baseados nos tipos originais
            final monstrosEventos = <MonstroAventura>[];

            for (final tipoNome in _tiposEventos) {
              // Busca o monstro da coleção inicial com esse tipo
              final monstroOriginal = monstrosOriginais.firstWhere(
                (m) => m.tipo1.name == tipoNome && m.colecao == 'colecao_inicial',
                orElse: () => monstrosOriginais.firstWhere(
                  (m) => m.tipo1.name == tipoNome,
                  orElse: () => monstrosOriginais.first,
                ),
              );

              // Nome = nome original + " Halloween"
              final nomeHalloween = '${monstroOriginal.nome} Halloween';

              monstrosEventos.add(MonstroAventura(
                id: 'evento_$tipoNome',
                nome: nomeHalloween,
                tipo1: monstroOriginal.tipo1,
                tipo2: monstroOriginal.tipo2,
                criadoEm: DateTime.now(),
                colecao: 'colecao_halloween',
                isBloqueado: true,
              ));
            }

            // Calcula progresso (verifica prefixo halloween_ no HIVE)
            final totalDesbloqueados = _tiposEventos
                .where((tipo) => _colecaoAtual['halloween_$tipo'] == true)
                .length;

            return Column(
              children: [
                // Badge de progresso
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '$totalDesbloqueados/30 desbloqueados',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Grid de monstros de eventos
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: monstrosEventos.length,
                    itemBuilder: (context, index) {
                      final monstro = monstrosEventos[index];
                      final nomeArquivo = monstro.tipo1.name;
                      // Verifica se está desbloqueado no HIVE com prefixo halloween_
                      final estaBloqueado =
                          _colecaoAtual['halloween_$nomeArquivo'] != true;
                      return _buildMonstroItem(
                        nomeArquivo,
                        monstro.tipo1,
                        monstro,
                        estaBloqueado,
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar monstros: $error'),
              ],
            ),
          ),
        );
      },
    );
  }
}