import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/menu_block.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../aventura/providers/aventura_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDriveConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Não conectado ao Google Drive';
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    _checkDriveConnection();
  }

  Future<void> _checkDriveConnection() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Verificando conexão...';
    });

    try {
      // Tenta verificar se já está conectado usando inicializarConexao
      final isConnected = await _driveService.inicializarConexao();
      setState(() {
        _isDriveConnected = isConnected;
        _connectionStatus = isConnected 
            ? 'Conectado ao Google Drive' 
            : 'É necessário conectar ao Google Drive para continuar';
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isDriveConnected = false;
        _connectionStatus = 'Erro ao verificar conexão. Clique para conectar.';
        _isConnecting = false;
      });
    }
  }

  Future<void> _connectToDrive() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Conectando ao Google Drive...';
    });

    try {
      final success = await _driveService.inicializarConexao();
      setState(() {
        _isDriveConnected = success;
        _connectionStatus = success
            ? 'Conectado ao Google Drive com sucesso!'
            : 'Falha ao conectar ao Google Drive';
        _isConnecting = false;
      });
      
      if (!success) {
        throw Exception('Falha na autenticação');
      }
    } catch (e) {
      setState(() {
        _isDriveConnected = false;
        _connectionStatus = 'Erro ao conectar: $e';
        _isConnecting = false;
      });
      
      // Mostrar erro em dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro de Conexão'),
            content: Text('Não foi possível conectar ao Google Drive:\n\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _connectToDrive();
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o email do usuário do provider
    print('🏠 [HomeScreen] Iniciando build, chamando validUserEmailProvider...');
    
    try {
      // Primeiro vamos testar todos os providers
      final firebaseUser = ref.watch(currentUserProvider);
      final currentEmail = ref.watch(currentUserEmailProvider);
      final driveEmail = ref.watch(currentUserEmailStateProvider);
      
      print('🏠 [HomeScreen] Firebase User: $firebaseUser');
      print('🏠 [HomeScreen] Firebase Email: ${firebaseUser?.email}');
      print('🏠 [HomeScreen] Current Email Provider: $currentEmail');
      print('🏠 [HomeScreen] Drive Email State: $driveEmail');
      
      final userEmail = ref.watch(validUserEmailProvider);
      print('🏠 [HomeScreen] Email do usuário final: $userEmail');
      
      return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('TechConnect'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.shade200.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 32, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Status de conexão do Google Drive
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDriveConnected ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDriveConnected ? Colors.green.shade300 : Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isDriveConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isDriveConnected ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status do Google Drive',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _connectionStatus,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isDriveConnected && !_isConnecting)
                    ElevatedButton(
                      onPressed: _connectToDrive,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Conectar'),
                    ),
                  if (_isConnecting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.1,
                children: [
                  MenuBlock(
                    icon: Icons.explore,
                    label: 'Aventura',
                    color: _isDriveConnected ? Colors.blueGrey.shade700 : Colors.grey.shade400,
                    onTap: _isDriveConnected ? () async {
                      // Verifica se pode acessar aventura
                      try {
                        print('🔍 [HomeScreen] Verificando acesso à aventura...');
                        final podeAcessar = await ref.read(podeAcessarAventuraProvider.future);
                        print('🔍 [HomeScreen] Pode acessar: $podeAcessar');
                        
                        if (podeAcessar) {
                          print('✅ [HomeScreen] Navegando para aventura...');
                          context.go('/aventura');
                        } else {
                          print('❌ [HomeScreen] Acesso negado - tipos não baixados');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('É necessário baixar os tipos dos monstros primeiro.\nAcesse Administrador > Tipagem para baixar.'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        print('❌ [HomeScreen] Erro ao verificar: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao verificar dados: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } : null,
                  ),
                  MenuBlock(
                    icon: Icons.admin_panel_settings,
                    label: 'Administrador',
                    color: _isDriveConnected ? Colors.blueGrey.shade400 : Colors.grey.shade400,
                    onTap: _isDriveConnected ? () {
                      context.go('/admin');
                    } : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    // Logout simples sem Firebase
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    } catch (e) {
      print('❌ [HomeScreen] Erro ao obter email: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Usuário não está logado'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Fazer Login'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
