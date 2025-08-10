import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../providers/tipagem_provider.dart';
import '../../../core/services/google_drive_service.dart';

class TipagemScreen extends ConsumerStatefulWidget {
  const TipagemScreen({super.key});

  @override
  ConsumerState<TipagemScreen> createState() => _TipagemScreenState();
}

class _TipagemScreenState extends ConsumerState<TipagemScreen> {
  bool _isSyncing = false;
  String _syncStatus = '';
  final GoogleDriveService _driveService = GoogleDriveService();
  final Set<String> _tiposSincronizados = <String>{}; // Tipos que foram sincronizados

  @override
  void initState() {
    super.initState();
    // Remover sincronização automática - todos os tipos disponíveis por padrão
    _initializeAllTypes();
  }

  void _initializeAllTypes() {
    // Por padrão, todos os tipos estão disponíveis (para teste)
    // Em produção, pode começar vazio e só liberar após sincronização
    setState(() {
      _tiposSincronizados.clear();
      _syncStatus = 'Sincronização com Google Drive é opcional. Todos os tipos estão disponíveis.';
    });
  }

  Future<void> _syncWithDrive() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Sincronizando com Google Drive...';
      _tiposSincronizados.clear(); // Limpa tipos sincronizados
    });

    try {
      // Buscar arquivos JSON do Google Drive
      final jsonFiles = await _driveService.listarArquivosDrive();
      
      if (jsonFiles.isNotEmpty) {
        setState(() {
          _syncStatus = 'Encontrados ${jsonFiles.length} arquivos. Carregando dados...';
        });
        
        int processedCount = 0;
        final jsonFilesFiltered = jsonFiles.where((f) => f.endsWith('.json')).toList();
        
        // Carregar dados dos JSONs
        for (final fileName in jsonFilesFiltered) {
          final jsonData = await _driveService.baixarJson(fileName);
          if (jsonData != null) {
            // Extrair o nome do tipo do arquivo (ex: "fire_tipo.json" -> "fire")
            String tipoName = fileName.replaceAll('_tipo.json', '').replaceAll('.json', '');
            
            // Tentar mapear nomes comuns de tipos
            tipoName = _mapearNomeTipo(tipoName);
            _tiposSincronizados.add(tipoName.toLowerCase());
            
            processedCount++;
            setState(() {
              _syncStatus = 'Carregando $processedCount/${jsonFilesFiltered.length} tipos...';
            });
            
            print('JSON carregado: $fileName - Tipo: $tipoName');
            
            // Pequena pausa para mostrar progresso visual
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
        
        setState(() {
          _syncStatus = 'Dados sincronizados com sucesso! ${_tiposSincronizados.length} tipos disponíveis.';
          _isSyncing = false;
        });
      } else {
        // Se não há JSONs, libera todos os tipos para teste
        setState(() {
          _syncStatus = 'Nenhum arquivo JSON encontrado. Liberando todos os tipos para edição.';
        });
        
        // Simula carregamento e libera todos os tipos
        await Future.delayed(const Duration(seconds: 2));
        
        // Adiciona todos os tipos disponíveis
        final todosOsTipos = ref.read(todosOsTiposProvider);
        for (final tipo in todosOsTipos) {
          _tiposSincronizados.add(tipo.name.toLowerCase());
        }
        
        setState(() {
          _syncStatus = 'Todos os ${_tiposSincronizados.length} tipos disponíveis para edição!';
          _isSyncing = false;
        });
      }
      
      // Limpar status após 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _syncStatus = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _syncStatus = 'Erro ao sincronizar: $e';
        _isSyncing = false;
      });
      
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _syncStatus = '';
          });
        }
      });
    }
  }

  // Função auxiliar para mapear nomes de tipos
  String _mapearNomeTipo(String nomeArquivo) {
    final mapeamentos = {
      'fire': 'Fire',
      'water': 'Water',
      'grass': 'Grass',
      'electric': 'Electric',
      'psychic': 'Psychic',
      'ice': 'Ice',
      'dragon': 'Dragon',
      'dark': 'Dark',
      'fairy': 'Fairy',
      'normal': 'Normal',
      'fighting': 'Fighting',
      'poison': 'Poison',
      'ground': 'Ground',
      'flying': 'Flying',
      'bug': 'Bug',
      'rock': 'Rock',
      'ghost': 'Ghost',
      'steel': 'Steel',
    };
    
    return mapeamentos[nomeArquivo.toLowerCase()] ?? nomeArquivo;
  }

  @override
  Widget build(BuildContext context) {
    final todosOsTipos = ref.watch(todosOsTiposProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Tipagem'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  )
                : const Icon(Icons.sync, color: Colors.white),
            onPressed: _isSyncing ? null : _syncWithDrive,
            tooltip: 'Sincronizar com Google Drive',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sistema de Tipagem',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione um tipo para configurar os multiplicadores de dano.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (_syncStatus.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isSyncing ? Colors.blue.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSyncing ? Colors.blue.shade200 : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSyncing ? Icons.sync : Icons.check_circle,
                            color: _isSyncing ? Colors.blue : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _syncStatus,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isSyncing ? Colors.blue.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tipos Disponíveis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (_isSyncing || _tiposSincronizados.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isSyncing ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSyncing ? Colors.orange.shade200 : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSyncing) ...[
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_tiposSincronizados.length} sincronizados',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_tiposSincronizados.length} disponíveis',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: todosOsTipos.length,
                itemBuilder: (context, index) {
                  final tipo = todosOsTipos[index];
                  return _buildTipoCard(context, tipo);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoCard(BuildContext context, Tipo tipo) {
    // Tipos ficam disponíveis sempre, exceto durante a sincronização
    final bool tipoDisponivel = !_isSyncing;
    final bool isBlocked = !tipoDisponivel;
    
    return GestureDetector(
      onTap: tipoDisponivel ? () {
        context.push('/admin/tipagem/dano/${tipo.name}');
      } : null,
      child: Container(
        decoration: BoxDecoration(
          color: isBlocked ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBlocked 
                ? Colors.grey.shade300 
                : tipo.cor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isBlocked ? 0.02 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Opacity(
                    opacity: isBlocked ? 0.3 : 1.0,
                    child: Image.asset(
                      tipo.iconAsset,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tipo.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isBlocked ? Colors.grey.shade500 : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (_isSyncing && !tipoDisponivel)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 4),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  else
                    Icon(
                      isBlocked ? Icons.lock : Icons.arrow_forward_ios,
                      color: isBlocked ? Colors.grey.shade400 : tipo.cor,
                      size: 16,
                    ),
                ],
              ),
            ),
            // Status badge no canto
            if (tipoDisponivel && !_isSyncing)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
