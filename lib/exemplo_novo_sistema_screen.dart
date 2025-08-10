import 'package:flutter/material.dart';
import '../features/tipagem/data/tipagem_repository.dart';
import '../shared/models/tipo_enum.dart';

class ExemploNovoSistemaScreen extends StatefulWidget {
  const ExemploNovoSistemaScreen({super.key});

  @override
  State<ExemploNovoSistemaScreen> createState() => _ExemploNovoSistemaScreenState();
}

class _ExemploNovoSistemaScreenState extends State<ExemploNovoSistemaScreen> {
  final TipagemRepository _repository = TipagemRepository();
  String _statusMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  void _verificarEstado() {
    setState(() {
      if (_repository.isBloqueado) {
        _statusMessage = '🚫 APP BLOQUEADO - Precisa inicializar com Google Drive primeiro!';
      } else if (_repository.isInicializado) {
        _statusMessage = '✅ APP INICIALIZADO - Dados disponíveis para uso!';
      } else {
        _statusMessage = '❓ Estado indefinido';
      }
    });
  }

  Future<void> _inicializarApp() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Inicializando com Google Drive...';
    });

    final sucesso = await _repository.inicializarComDrive();
    
    setState(() {
      _isLoading = false;
      if (sucesso) {
        _statusMessage = '✅ APP INICIALIZADO COM SUCESSO!\n'
            'Todos os ${Tipo.values.length} tipos baixados do Drive.';
      } else {
        _statusMessage = '❌ FALHA NA INICIALIZAÇÃO\n'
            'Verifique sua conexão com Google Drive.';
      }
    });
  }

  Future<void> _exemploCarregarDados() async {
    if (_repository.isBloqueado) {
      setState(() {
        _statusMessage = '🚫 Não é possível carregar dados - App bloqueado!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '📊 Carregando dados do tipo Água...';
    });

    final dados = await _repository.carregarDadosTipo(Tipo.agua);
    
    setState(() {
      _isLoading = false;
      if (dados != null) {
        _statusMessage = '✅ DADOS CARREGADOS!\n'
            'Tipo Água tem ${dados.length} valores de defesa:\n'
            'Ex: vs Fogo = ${dados[Tipo.fogo]}, vs Planta = ${dados[Tipo.planta]}';
      } else {
        _statusMessage = '❌ Falha ao carregar dados do tipo Água';
      }
    });
  }

  Future<void> _exemploSalvarDados() async {
    if (_repository.isBloqueado) {
      setState(() {
        _statusMessage = '🚫 Não é possível salvar dados - App bloqueado!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '💾 Salvando dados modificados...';
    });

    // Cria dados modificados de exemplo
    final dadosModificados = <Tipo, double>{};
    for (final tipo in Tipo.values) {
      dadosModificados[tipo] = 1.5; // Exemplo: todos com 1.5x de dano
    }

    final sucesso = await _repository.salvarDadosTipo(Tipo.fogo, dadosModificados);
    
    setState(() {
      _isLoading = false;
      if (sucesso) {
        _statusMessage = '✅ DADOS SALVOS COM SUCESSO!\n'
            'Tipo Fogo atualizado (Local + Google Drive)';
      } else {
        _statusMessage = '❌ Falha ao salvar dados';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Teste do Novo Sistema'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status atual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _repository.isBloqueado ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _repository.isBloqueado ? Colors.red : Colors.green,
                ),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _repository.isBloqueado ? Colors.red.shade800 : Colors.green.shade800,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informações do estado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Estado do Sistema',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow('Bloqueado', _repository.isBloqueado),
                    _buildStatusRow('Inicializado', _repository.isInicializado),
                    _buildStatusRow('Baixado do Drive', _repository.foiBaixadoDoDrive),
                    _buildStatusRow('Drive Conectado', _repository.isDriveConectado),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões de teste
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _repository.isBloqueado ? _inicializarApp : null,
                icon: const Icon(Icons.cloud_download),
                label: const Text('🚀 Inicializar com Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: !_repository.isBloqueado ? _exemploCarregarDados : null,
                icon: const Icon(Icons.folder_open),
                label: const Text('📊 Carregar Dados (Água)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: !_repository.isBloqueado ? _exemploSalvarDados : null,
                icon: const Icon(Icons.save),
                label: const Text('💾 Salvar Dados (Fogo)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Explicação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Como funciona o novo sistema:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. App inicia BLOQUEADO até baixar dados do Drive'),
                  Text('2. Após inicializar, todos os dados ficam disponíveis'),
                  Text('3. Dados são salvos: Memória → Local → Google Drive'),
                  Text('4. Uma única fonte de verdade centralizada'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text('$label: ${status ? "SIM" : "NÃO"}'),
        ],
      ),
    );
  }
}
