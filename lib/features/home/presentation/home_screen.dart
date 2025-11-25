import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/menu_block.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../aventura/providers/aventura_provider.dart';
import '../../tipagem/data/tipagem_repository.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/config/version_config.dart';

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
      
      if (isConnected) {
        setState(() {
          _connectionStatus = 'Conectado ao Google Drive - Inicializando tipos...';
        });
        
        // 🔥 INICIALIZAÇÃO AUTOMÁTICA DO SISTEMA DE TIPAGEM
        try {
          print('🚀 [HomeScreen] Inicializando sistema de tipagem automaticamente...');
          final tipagemRepository = TipagemRepository();
          
          // Diagnóstico detalhado
          print('📊 [HomeScreen] === DIAGNÓSTICO DETALHADO DE TIPAGEM ===');
          print('📊 [HomeScreen] Drive Conectado: ${tipagemRepository.isDriveConectado}');
          print('📊 [HomeScreen] Foi Baixado do Drive: ${tipagemRepository.foiBaixadoDoDrive}');
          print('📊 [HomeScreen] Is Inicializado: ${tipagemRepository.isInicializado}');
          print('📊 [HomeScreen] Is Bloqueado: ${tipagemRepository.isBloqueado}');
          
          final isInicializadoAsync = await tipagemRepository.isInicializadoAsync;
          print('📊 [HomeScreen] Is Inicializado Async: $isInicializadoAsync');
          
          // Verifica cache/dados locais salvos
          setState(() {
            _connectionStatus = 'Verificando dados locais salvos (Hive)...';
          });
          
          print('🗃️ [HomeScreen] Verificando dados salvos no Hive para cada tipo...');
          int tiposEncontrados = 0;
          for (final tipo in Tipo.values) {
            try {
              final dados = await tipagemRepository.carregarDadosTipo(tipo);
              if (dados != null && dados.isNotEmpty) {
                tiposEncontrados++;
                print('✅ [HomeScreen] Tipo ${tipo.name}: ${dados.length} dados encontrados');
              } else {
                print('❌ [HomeScreen] Tipo ${tipo.name}: NENHUM DADO ENCONTRADO');
              }
            } catch (e) {
              print('❌ [HomeScreen] Tipo ${tipo.name}: ERRO - $e');
            }
          }
          
          print('📊 [HomeScreen] RESUMO: $tiposEncontrados/${Tipo.values.length} tipos encontrados no Hive');
          
          if (tiposEncontrados >= Tipo.values.length) {
            print('✅ [HomeScreen] Todos os tipos estão salvos no Hive - Sistema pronto!');
            setState(() {
              _connectionStatus = 'Conectado ao Google Drive - Todos os tipos disponíveis!';
            });
          } else if (!isInicializadoAsync) {
            print('⚠️ [HomeScreen] Tipos incompletos, iniciando download e salvamento...');
            setState(() {
              _connectionStatus = 'Baixando e salvando tipos no dispositivo...';
            });
            
            final inicializacaoSucesso = await tipagemRepository.inicializarComDrive();
            
            if (inicializacaoSucesso) {
              print('✅ [HomeScreen] Sistema de tipagem inicializado e salvo com sucesso!');
              setState(() {
                _connectionStatus = 'Conectado ao Google Drive - Tipos baixados e salvos!';
              });
            } else {
              print('❌ [HomeScreen] Falha na inicialização do sistema de tipagem');
              setState(() {
                _connectionStatus = 'Conectado ao Google Drive - Erro no download dos tipos';
              });
            }
          } else {
            print('✅ [HomeScreen] Sistema já inicializado mas alguns tipos podem estar faltando');
            setState(() {
              _connectionStatus = 'Conectado ao Google Drive - Sistema parcialmente pronto';
            });
          }
        } catch (e) {
          print('❌ [HomeScreen] Erro na inicialização automática: $e');
          setState(() {
            _connectionStatus = 'Conectado ao Google Drive - Erro no diagnóstico: $e';
          });
        }
      }
      
      setState(() {
        _isDriveConnected = isConnected;
        if (!isConnected) {
          _connectionStatus = 'É necessário conectar ao Google Drive para continuar';
        }
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
      
      if (success) {
        setState(() {
          _connectionStatus = 'Conectado ao Google Drive - Inicializando tipos...';
        });
        
        // 🔥 INICIALIZAÇÃO AUTOMÁTICA DO SISTEMA DE TIPAGEM
        try {
          print('🚀 [HomeScreen] Conectado! Inicializando sistema de tipagem...');
          final tipagemRepository = TipagemRepository();
          
          // Diagnóstico detalhado
          print('📊 [HomeScreen] === DIAGNÓSTICO DETALHADO DE TIPAGEM (CONNECT) ===');
          print('📊 [HomeScreen] Drive Conectado: ${tipagemRepository.isDriveConectado}');
          print('📊 [HomeScreen] Foi Baixado do Drive: ${tipagemRepository.foiBaixadoDoDrive}');
          print('📊 [HomeScreen] Is Inicializado: ${tipagemRepository.isInicializado}');
          print('📊 [HomeScreen] Is Bloqueado: ${tipagemRepository.isBloqueado}');
          
          final isInicializadoAsync = await tipagemRepository.isInicializadoAsync;
          print('📊 [HomeScreen] Is Inicializado Async: $isInicializadoAsync');
          
          setState(() {
            _connectionStatus = 'Verificando dados locais salvos (Hive)...';
          });
          
          print('🗃️ [HomeScreen] Verificando dados salvos no Hive para cada tipo...');
          int tiposEncontrados = 0;
          for (final tipo in Tipo.values) {
            try {
              final dados = await tipagemRepository.carregarDadosTipo(tipo);
              if (dados != null && dados.isNotEmpty) {
                tiposEncontrados++;
                print('✅ [HomeScreen] Tipo ${tipo.name}: ${dados.length} dados encontrados');
              } else {
                print('❌ [HomeScreen] Tipo ${tipo.name}: NENHUM DADO ENCONTRADO');
              }
            } catch (e) {
              print('❌ [HomeScreen] Tipo ${tipo.name}: ERRO - $e');
            }
          }
          
          print('📊 [HomeScreen] RESUMO: $tiposEncontrados/${Tipo.values.length} tipos encontrados no Hive');
          
          if (tiposEncontrados >= Tipo.values.length) {
            print('✅ [HomeScreen] Todos os tipos estão salvos no Hive - Sistema pronto!');
            setState(() {
              _connectionStatus = 'Conectado ao Google Drive - Todos os tipos disponíveis!';
            });
          } else {
            print('⚠️ [HomeScreen] Iniciando download e salvamento completo no Hive...');
            setState(() {
              _connectionStatus = 'Baixando e salvando tipos no dispositivo...';
            });
            
            final inicializacaoSucesso = await tipagemRepository.inicializarComDrive();
            
            if (inicializacaoSucesso) {
              print('✅ [HomeScreen] Sistema de tipagem inicializado e salvo no Hive com sucesso!');
              setState(() {
                _connectionStatus = 'Conectado ao Google Drive - Tipos baixados e salvos no dispositivo!';
              });
            } else {
              print('❌ [HomeScreen] Falha na inicialização do sistema de tipagem');
              setState(() {
                _connectionStatus = 'Conectado ao Google Drive - Erro no download dos tipos';
              });
            }
          }
        } catch (e) {
          print('❌ [HomeScreen] Erro na inicialização automática: $e');
          setState(() {
            _connectionStatus = 'Conectado ao Google Drive - Erro no diagnóstico: $e';
          });
        }
      }
      
      setState(() {
        _isDriveConnected = success;
        if (!success) {
          _connectionStatus = 'Falha ao conectar ao Google Drive';
        }
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
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mapas_aventura/deserto.jpg'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TECHTERRA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${VersionConfig.currentVersion}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status do Google Drive
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDriveConnected ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDriveConnected ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDriveConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: _isDriveConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _connectionStatus,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (!_isDriveConnected && !_isConnecting)
                      TextButton(
                        onPressed: _connectToDrive,
                        child: const Text('Conectar'),
                      ),
                    if (_isConnecting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Menu principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      // 1. Aventura
                      _buildMenuCard(
                        icon: Icons.explore,
                        label: 'Aventura',
                        color: _isDriveConnected ? const Color(0xFF3182CE) : Colors.grey,
                        onTap: _isDriveConnected ? () async {
                          try {
                            final podeAcessar = await ref.read(podeAcessarAventuraProvider.future);
                            if (podeAcessar) {
                              context.go('/aventura');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('É necessário baixar os tipos dos monstros primeiro.\nAcesse Administrador > Tipagem para baixar.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } : null,
                      ),
                      // 2. Criação (Criadouro)
                      _buildMenuCard(
                        icon: Icons.pets,
                        label: 'Criação',
                        color: _isDriveConnected ? const Color(0xFF9C27B0) : Colors.grey,
                        onTap: _isDriveConnected ? () => context.go('/criadouro') : null,
                      ),
                      // 3. Ranking
                      _buildMenuCard(
                        icon: Icons.leaderboard,
                        label: 'Ranking',
                        color: _isDriveConnected ? const Color(0xFFE53E3E) : Colors.grey,
                        onTap: _isDriveConnected ? () => context.go('/ranking') : null,
                      ),
                      // 4. Admin
                      _buildMenuCard(
                        icon: Icons.admin_panel_settings,
                        label: 'Admin',
                        color: _isDriveConnected ? const Color(0xFF3182CE) : Colors.grey,
                        onTap: _isDriveConnected ? () => context.go('/admin') : null,
                      ),
                      // 5. Jogador
                      _buildMenuCard(
                        icon: Icons.person,
                        label: 'Jogador',
                        color: _isDriveConnected ? const Color(0xFF38A169) : Colors.grey,
                        onTap: _isDriveConnected ? () => context.go('/jogador') : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botão de logout
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
