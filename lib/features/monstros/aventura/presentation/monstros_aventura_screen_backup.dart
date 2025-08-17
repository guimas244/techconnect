import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monstro_aventura.dart';
import '../data/monstro_aventura_repository.dart';
import '../../../../shared/models/tipo_enum.dart';

// Provider para o repository
final monstroAventuraRepositoryProvider = Provider<MonstroAventuraRepository>((ref) {
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
                        _buildMenuCard(
                          context: context,
                          title: 'Catálogo de Mapas',
                          subtitle: 'Explore os mapas disponíveis',
                          icon: Icons.map,
                          color: Colors.green,
                          onTap: () => _mostrarCatalogoMapas(context),
                          enabled: true,
                        ),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(
                      fontSize: 18,
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
      MaterialPageRoute(
        builder: (context) => const CatalogoMonstrosScreen(),
      ),
    );
  }

  void _mostrarMapasEmDesenvolvimento(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catálogo de mapas em desenvolvimento...'),
        backgroundColor: Colors.orange,
      ),
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

  // Mapeamento de monstros para tipos baseado nos arquivos existentes
  final Map<String, Tipo> monstroParaTipo = {
    'agua': Tipo.agua,           // água -> água (direto)
    'alien': Tipo.alien,         // alien -> alien (direto)
    'desconhecido': Tipo.desconhecido, // desconhecido -> desconhecido (direto)
    'deus': Tipo.deus,           // deus -> deus (direto)
    'docrates': Tipo.docrates,   // docrates -> docrates (direto)
    'dragao': Tipo.dragao,       // dragão -> dragão (direto)
    'fantasma': Tipo.fantasma,   // fantasma -> fantasma (direto)
    'fera': Tipo.fera,           // fera -> fera (direto)
    'fogo': Tipo.fogo,           // fogo -> fogo (direto)
    'gelo': Tipo.gelo,           // gelo -> gelo (direto)
    'inseto': Tipo.inseto,       // inseto -> inseto (direto)
    'luz': Tipo.luz,             // luz -> luz (direto)
    'magico': Tipo.magico,       // mágico -> mágico (direto)
    'marinho': Tipo.marinho,     // marinho -> marinho (direto)
    'mistico': Tipo.mistico,     // místico -> místico (direto)
    'normal': Tipo.normal,       // normal -> normal (direto)
    'nostalgico': Tipo.nostalgico, // nostálgico -> nostálgico (direto)
    'planta': Tipo.planta,       // planta -> planta (direto)
    'psiquico': Tipo.psiquico,   // psíquico -> psíquico (direto)
    'subsolo': Tipo.subterraneo, // subsolo -> subterrâneo
    'tecnologia': Tipo.tecnologia, // tecnologia -> tecnologia (direto)
    'tempo': Tipo.tempo,         // tempo -> tempo (direto)
    'terrestre': Tipo.terrestre, // terrestre -> terrestre (direto)
    'trevas': Tipo.trevas,       // trevas -> trevas (direto)
    'venenoso': Tipo.venenoso,   // venenoso -> venenoso (direto)
    'vento': Tipo.vento,         // vento -> vento (direto)
    'voador': Tipo.voador,       // voador -> voador (direto)
    'zumbi': Tipo.zumbi,         // zumbi -> zumbi (direto)
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Monstros'),
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
          // Grid de monstros
          GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: monstroParaTipo.length,
            itemBuilder: (context, index) {
              final entry = monstroParaTipo.entries.elementAt(index);
              final nomeArquivo = entry.key;
              final tipo = entry.value;
              
              return _buildMonstroItem(nomeArquivo, tipo);
            },
          ),
          // Imagem expandida
          if (monstroExpandido != null)
            GestureDetector(
              onTap: () => setState(() => monstroExpandido = null),
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Hero(
                    tag: monstroExpandido!,
                    child: Image.asset(
                      'assets/monstros_aventura/$monstroExpandido.png',
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

  Widget _buildMonstroItem(String nomeArquivo, Tipo tipo) {
    return GestureDetector(
      onTap: () => setState(() => monstroExpandido = nomeArquivo),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: nomeArquivo,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/monstros_aventura/$nomeArquivo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: tipo.cor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                tipo.displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tipo.cor.withOpacity(0.8),
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
