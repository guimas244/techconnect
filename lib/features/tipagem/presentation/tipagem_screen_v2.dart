import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../data/tipagem_repository.dart';
import 'tipagem_inicializacao_screen.dart';

class TipagemScreen extends ConsumerStatefulWidget {
  const TipagemScreen({super.key});

  @override
  ConsumerState<TipagemScreen> createState() => _TipagemScreenState();
}

class _TipagemScreenState extends ConsumerState<TipagemScreen> {
  final TipagemRepository _repository = TipagemRepository();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  void _checkInitialization() {
    setState(() {
      _isInitialized = _repository.isInicializado;
    });
  }

  void _onInitialized() {
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se não foi inicializado, mostra a tela de inicialização
    if (!_isInitialized) {
      return TipagemInicializacaoScreen(
        onInicializado: _onInitialized,
      );
    }

    // Se foi inicializado, mostra a tela principal
    return _buildMainScreen(context);
  }

  Widget _buildMainScreen(BuildContext context) {
    // Remove a referência ao provider por enquanto

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Tipagem',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Atualizando dados do Google Drive...'),
                  duration: Duration(seconds: 2),
                ),
              );
              
              await _repository.atualizarTodosDoDrive();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Dados atualizados com sucesso!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D2D2D), Color(0xFF1E1E1E)],
          ),
        ),
        child: Column(
          children: [
            // Header com informações
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_done,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Dados sincronizados com Google Drive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todos os ${Tipo.values.length} tipos de Pokémon estão disponíveis para edição',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Grid de tipos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: Tipo.values.length,
                  itemBuilder: (context, index) {
                    final tipo = Tipo.values[index];
                    return _buildTipoCard(context, tipo);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoCard(BuildContext context, Tipo tipo) {
    return GestureDetector(
      onTap: () {
        // Navega para a tela de edição do tipo
        context.go('/admin/tipagem/dano/${tipo.name}');
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tipo.cor.withOpacity(0.8),
              tipo.cor.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tipo.cor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone do tipo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tipo.icone,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Nome do tipo
              Text(
                tipo.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              // Status (sempre disponível)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Text(
                  'Disponível',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
