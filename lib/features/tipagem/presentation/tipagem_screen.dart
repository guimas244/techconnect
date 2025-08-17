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
  bool _isUpdating = false;
  double _updateProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    print('🔍 Verificando inicialização...');
    final isInit = await _repository.isInicializadoAsync;
    setState(() {
      _isInitialized = isInit;
    });
    print('📋 Estado da inicialização: $_isInitialized');
  }

  void _onInitialized() {
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _atualizarDadosComProgresso() async {
    setState(() {
      _isUpdating = true;
      _updateProgress = 0.0;
    });

    // Mostra SnackBar com progresso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: StatefulBuilder(
          builder: (context, setSnackState) {
            return Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                    value: _updateProgress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Atualizando dados do Google Drive...'),
                      Text(
                        '${(_updateProgress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      // Simula progresso da atualização
      final totalTipos = Tipo.values.length;
      for (int i = 0; i < totalTipos; i++) {
        setState(() {
          _updateProgress = (i + 1) / totalTipos;
        });
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await _repository.atualizarTodosDoDrive();
      
      setState(() {
        _isUpdating = false;
        _updateProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _updateProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text(
          'Tipagem',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: _isUpdating 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isUpdating ? null : _atualizarDadosComProgresso,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com informações
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Todos os ${Tipo.values.length} tipos de Pokémon estão disponíveis para edição',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Lista de tipos (formato antigo)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 80,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              itemCount: Tipo.values.length,
              itemBuilder: (context, index) {
                final tipo = Tipo.values[index];
                return _buildTipoListItem(context, tipo);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoListItem(BuildContext context, Tipo tipo) {
    return Container(
      // margin removido pois o espaçamento agora é do grid
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navega para a tela de edição do tipo
          context.go('/admin/tipagem/dano/${tipo.name}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone do tipo usando asset
              Image.asset(
                tipo.iconAsset,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback para ícone material se asset não existir
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tipo.cor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      tipo.icone,
                      color: tipo.cor,
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              
              // Informações do tipo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double fontSize = 16;
                        // Se o nome for muito longo para o espaço disponível, diminui a fonte
                        if (tipo.displayName.length > 12 || constraints.maxWidth < 100) {
                          fontSize = 13;
                        }
                        return Text(
                          tipo.displayName,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              
              // Status e seta
              Column(
                children: [
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
