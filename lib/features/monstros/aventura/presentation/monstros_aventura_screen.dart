import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monstro_aventura.dart';
import '../data/monstro_aventura_repository.dart';
import '../../../../shared/models/tipo_enum.dart';
import '../../../aventura/services/colecao_service.dart';
import '../../../../core/services/storage_service.dart';

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

class MonstrosAventuraScreen extends ConsumerWidget {
  const MonstrosAventuraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monstros - Aventura'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card do catálogo de monstros
                _buildMenuCard(
                  context: context,
                  title: 'Catálogo de Monstros',
                  subtitle: 'Visualize todos os monstros disponíveis',
                  icon: Icons.library_books,
                  color: Colors.blue,
                  onTap: () => _mostrarCatalogoMonstros(context),
                ),
                const SizedBox(height: 20),

                // Card do catálogo de mapas
                _buildMenuCard(
                  context: context,
                  title: 'Catálogo de Mapas',
                  subtitle: 'Explore os mapas disponíveis',
                  icon: Icons.map,
                  color: Colors.green,
                  onTap: () => _mostrarCatalogoMapas(context),
                ),
                const SizedBox(height: 20),

                // Botão de iniciar aventura
                ElevatedButton(
                  onPressed: () => _iniciarAventura(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: enabled ? 4 : 1,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: enabled ? null : Colors.grey[100],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: enabled ? color.withOpacity(0.1) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: enabled ? color : Colors.grey[500],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: enabled ? color : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? Colors.grey[700] : Colors.grey[400],
                      ),
                    ),
                    if (!enabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Em desenvolvimento',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: enabled ? Colors.grey[400] : Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarCatalogoMonstros(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CatalogoMonstrosScreen()),
    );
  }

  void _mostrarCatalogoMapas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CatalogoMapasScreen()),
    );
  }

  void _iniciarAventura(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de aventura em desenvolvimento...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class CatalogoMonstrosScreen extends StatefulWidget {
  const CatalogoMonstrosScreen({super.key});

  @override
  State<CatalogoMonstrosScreen> createState() => _CatalogoMonstrosScreenState();
}

class _CatalogoMonstrosScreenState extends State<CatalogoMonstrosScreen> {
  String? monstroExpandido;
  final ColecaoService _colecaoService = ColecaoService();
  final StorageService _storageService = StorageService();
  Map<String, bool> _colecaoAtual = {};
  bool _carregandoColecao = false;

  @override
  void initState() {
    super.initState();
    _carregarColecao();
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
        title: const Text('Catálogo de Monstros'),
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
          // Botão temporário para testes
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () async {
              final email = await _storageService.getLastEmail();
              if (email != null) {
                await _colecaoService.desbloquearMonstrosParaTeste(email);
                await _carregarColecao();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('TODOS os 30 monstros nostálgicos desbloqueados!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            tooltip: 'Desbloquear para Teste',
          ),
        ],
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
          // Grid de monstros - Mostra TODOS os monstros das duas coleções
          Consumer(
            builder: (context, ref, _) {
              final monstrosAsync = ref.watch(monstrosListProvider);
              return monstrosAsync.when(
                data: (monstros) {
                  // Ordena monstros: primeiro coleção inicial, depois nostálgicos
                  final monstrosOrdenados = List<MonstroAventura>.from(
                    monstros,
                  );
                  monstrosOrdenados.sort((a, b) {
                    // Primeiro ordena por coleção (inicial antes de nostálgicos)
                    if (a.colecao != b.colecao) {
                      return a.colecao == 'colecao_inicial' ? -1 : 1;
                    }
                    // Depois ordena por nome do tipo
                    return a.tipo1.name.compareTo(b.tipo1.name);
                  });

                  return GridView.builder(
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
                      final estaBloqueado =
                          monstro.colecao == 'colecao_inicial'
                              ? false
                              : _colecaoAtual[nomeArquivo] != true;
                      return _buildMonstroItem(
                        nomeArquivo,
                        monstro.tipo1,
                        monstro,
                        estaBloqueado,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) => Center(
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
          ),
          // Imagem expandida
          if (monstroExpandido != null)
            GestureDetector(
              onTap: () => setState(() => monstroExpandido = null),
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
                    child: Consumer(
                      builder: (context, ref, _) {
                        final monstrosAsync = ref.watch(monstrosListProvider);
                        return monstrosAsync.when(
                          data: (monstros) {
                            final partesTag = monstroExpandido!.split('_');
                            if (partesTag.length >= 2) {
                              final colecao =
                                  partesTag[0] == 'colecao' &&
                                          partesTag.length >= 2
                                      ? 'colecao_${partesTag[1]}'
                                      : partesTag[0];
                              final nomeArquivo =
                                  partesTag.length > 2
                                      ? partesTag.sublist(2).join('_')
                                      : partesTag[1];

                              final monstro = monstros.firstWhere(
                                (m) =>
                                    m.colecao == colecao &&
                                    m.tipo1.name == nomeArquivo,
                                orElse:
                                    () =>
                                        monstros.isNotEmpty
                                            ? monstros.first
                                            : MonstroAventura(
                                              id: 'temp',
                                              nome: 'Temp',
                                              tipo1: Tipo.normal,
                                              tipo2: Tipo.agua,
                                              criadoEm: DateTime.now(),
                                              colecao: 'colecao_inicial',
                                              isBloqueado: false,
                                            ),
                              );

                              final nomeArquivoCorreto = monstro.tipo1.name;
                              final estaBloqueadoExpandido =
                                  monstro.colecao == 'colecao_inicial'
                                      ? false
                                      : _colecaoAtual[nomeArquivoCorreto] !=
                                          true;

                              return _buildMonstroDetalheCard(
                                context: context,
                                monstro: monstro,
                                estaBloqueado: estaBloqueadoExpandido,
                                heroTag: monstroExpandido!,
                              );
                            }
                            return const CircularProgressIndicator();
                          },
                          loading: () => const CircularProgressIndicator(),
                          error:
                              (_, __) => const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 64,
                              ),
                        );
                      },
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
      onTap: () => setState(() => monstroExpandido = tagUnico),
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
}

// --- Catálogo de Mapas ---
class CatalogoMapasScreen extends StatefulWidget {
  const CatalogoMapasScreen({super.key});

  @override
  State<CatalogoMapasScreen> createState() => _CatalogoMapasScreenState();
}

class _CatalogoMapasScreenState extends State<CatalogoMapasScreen> {
  String? mapaExpandido;

  // Lista de mapas e descrições amigáveis
  final List<Map<String, String>> mapas = [
    {'arquivo': 'cidade_abandonada.jpg', 'descricao': 'Cidade Abandonada'},
    {'arquivo': 'deserto.jpg', 'descricao': 'Deserto'},
    {'arquivo': 'floresta_verde.jpg', 'descricao': 'Floresta Verde'},
    {'arquivo': 'praia.jpg', 'descricao': 'Praia'},
    {'arquivo': 'vulcao.jpg', 'descricao': 'Vulcão'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Mapas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background/templo.png',
              fit: BoxFit.cover,
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: mapas.length,
            itemBuilder: (context, index) {
              final mapa = mapas[index];
              return _buildMapaItem(mapa['arquivo']!, mapa['descricao']!);
            },
          ),
          if (mapaExpandido != null)
            GestureDetector(
              onTap: () => setState(() => mapaExpandido = null),
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Hero(
                    tag: mapaExpandido!,
                    child: Image.asset(
                      'assets/mapas_aventura/$mapaExpandido',
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.7,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapaItem(String arquivo, String descricao) {
    return GestureDetector(
      onTap: () => setState(() => mapaExpandido = arquivo),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: arquivo,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/mapas_aventura/$arquivo',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                descricao,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
