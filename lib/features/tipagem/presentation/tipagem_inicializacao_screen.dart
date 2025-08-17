import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tipagem_repository.dart';
import '../../../shared/models/tipo_enum.dart';

class TipagemInicializacaoScreen extends ConsumerStatefulWidget {
  final VoidCallback onInicializado;

  const TipagemInicializacaoScreen({
    super.key,
    required this.onInicializado,
  });

  @override
  ConsumerState<TipagemInicializacaoScreen> createState() => _TipagemInicializacaoScreenState();
}

class _TipagemInicializacaoScreenState extends ConsumerState<TipagemInicializacaoScreen> {
  final TipagemRepository _repository = TipagemRepository();
  bool _isCarregando = false;
  bool _isInicializado = false; // Estado local para controle da UI
  String _statusMessage = 'Aguardando inicialização...';
  String _errorMessage = '';
  double _progresso = 0.0;
  String _progressoTexto = '';

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    print('🔍 Verificando estado de inicialização...');
    final isInit = await _repository.isInicializadoAsync;
    
    setState(() {
      _isInicializado = isInit;
      if (isInit) {
        _statusMessage = 'App já inicializado com cache local!';
        print('✅ App já inicializado, chamando callback...');
        widget.onInicializado();
      } else {
        _statusMessage = 'Necessário baixar dados do Google Drive para usar o app';
        print('❌ App não inicializado, necessário download');
      }
    });
  }

  Future<void> _inicializarComDrive() async {
    setState(() {
      _isCarregando = true;
      _errorMessage = '';
      _statusMessage = 'Conectando com Google Drive...';
      _progresso = 0.0;
      _progressoTexto = '0%';
    });

    try {
      // Conecta com Google Drive
      setState(() {
        _statusMessage = 'Conectando com Google Drive...';
        _progresso = 0.1;
        _progressoTexto = '10%';
      });
      
      if (!_repository.isDriveConectado) {
        final conectou = await _repository.conectarDrive();
        if (!conectou) {
          setState(() {
            _errorMessage = 'Falha ao conectar com Google Drive. Verifique sua conexão.';
            _statusMessage = 'Erro na conexão';
            _isCarregando = false;
            _progresso = 0.0;
            _progressoTexto = '';
          });
          return;
        }
      }

      setState(() {
        _statusMessage = 'Conexão estabelecida! Baixando dados...';
        _progresso = 0.2;
        _progressoTexto = '20%';
      });

      // Simula download progressivo dos tipos
      final totalTipos = Tipo.values.length;
      int tiposProcessados = 0;

      for (final tipo in Tipo.values) {
        setState(() {
          tiposProcessados++;
          final porcentagem = 20 + ((tiposProcessados / totalTipos) * 70); // 20% a 90%
          _progresso = porcentagem / 100;
          _progressoTexto = '${porcentagem.toInt()}%';
          _statusMessage = 'Baixando tipo ${tipo.displayName}... ($tiposProcessados/$totalTipos)';
        });

        // Pequeno delay para mostrar o progresso
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _statusMessage = 'Finalizando inicialização...';
        _progresso = 0.95;
        _progressoTexto = '95%';
      });

      // Chama a inicialização real
      final sucesso = await _repository.inicializarComDrive();
      
      setState(() {
        _progresso = 1.0;
        _progressoTexto = '100%';
      });

      if (sucesso) {
        setState(() {
          _statusMessage = 'Inicialização concluída com sucesso!';
          _isCarregando = false;
        });
        
        // Delay para mostrar a mensagem de sucesso
        await Future.delayed(const Duration(seconds: 1));
        widget.onInicializado();
      } else {
        setState(() {
          _errorMessage = 'Falha na inicialização. Verifique sua conexão com o Google Drive.';
          _statusMessage = 'Erro na inicialização';
          _isCarregando = false;
          _progresso = 0.0;
          _progressoTexto = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado: $e';
        _statusMessage = 'Erro na inicialização';
        _isCarregando = false;
        _progresso = 0.0;
        _progressoTexto = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone principal
              Icon(
                Icons.cloud_download,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              
              const SizedBox(height: 24),
              
              // Título
              Text(
                'TechConnect - Tipagem',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Status message
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Loading indicator com progresso
              if (_isCarregando) ...[
                Column(
                  children: [
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _progresso,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _progressoTexto,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ] else if (!_isInicializado) ...[
                ElevatedButton.icon(
                  onPressed: _inicializarComDrive,
                  icon: const Icon(Icons.download),
                  label: const Text('Baixar Dados do Drive'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
              
              // Error message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _inicializarComDrive,
                  child: const Text('Tentar Novamente'),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Info adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O app precisa baixar os dados de tipagem do Google Drive na primeira execução. '
                      'Após isso, você poderá usar o app normalmente.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
