import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../tipagem/data/tipagem_repository.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/config/version_config.dart';
import '../../aventura/services/game_config_service.dart';

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
  final GameConfigService _gameConfigService = GameConfigService();
  GameConfig? _gameConfig;
  double _multiplicadorDrop = 1.0;
  bool _carregandoConfig = false;

  @override
  void initState() {
    super.initState();
    _checkDriveConnection();
  }

  Future<void> _carregarConfiguracaoDrops() async {
    if (_carregandoConfig) return;

    setState(() => _carregandoConfig = true);

    try {
      final config = await _gameConfigService.carregarConfiguracao();
      if (mounted) {
        setState(() {
          _gameConfig = config;
          _multiplicadorDrop = config.multiplicadorDrop;
          _carregandoConfig = false;
        });
      }
    } catch (e) {
      print('❌ [HomeScreen] Erro ao carregar config de drops: $e');
      if (mounted) {
        setState(() => _carregandoConfig = false);
      }
    }
  }

  void _mostrarModalDrops() {
    final config = _gameConfig ?? GameConfig.padrao();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            const Text('Chances de Drop'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Multiplicador atual
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _multiplicadorDrop > 1
                      ? Colors.amber.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _multiplicadorDrop > 1
                        ? Colors.amber.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Multiplicador Atual:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_multiplicadorDrop.toStringAsFixed(_multiplicadorDrop % 1 == 0 ? 0 : 1)}x',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _multiplicadorDrop > 1
                            ? Colors.amber.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Base -> Atual',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(),
              // Lista de drops (ativos e inativos)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: config.drops.map((drop) {
                      final chanceBase = drop.chance;
                      final estaAtivo = drop.ativo;
                      final chanceAtual = estaAtivo ? chanceBase * _multiplicadorDrop : 0.0;
                      final corCategoria = _corCategoria(drop.categoria);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Opacity(
                          opacity: estaAtivo ? 1.0 : 0.5,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: estaAtivo ? corCategoria : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  drop.nome,
                                  style: TextStyle(
                                    fontSize: 13,
                                    decoration: estaAtivo ? null : TextDecoration.lineThrough,
                                    color: estaAtivo ? null : Colors.grey,
                                  ),
                                ),
                              ),
                              Text(
                                '${_formatarChance(chanceBase)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 12,
                                color: estaAtivo
                                    ? (_multiplicadorDrop > 1
                                        ? Colors.amber.shade600
                                        : Colors.grey.shade400)
                                    : Colors.red.shade300,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                estaAtivo
                                    ? '${_formatarChance(chanceAtual)}%'
                                    : '0%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: estaAtivo
                                      ? (_multiplicadorDrop > 1
                                          ? Colors.amber.shade700
                                          : Colors.grey.shade700)
                                      : Colors.red.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Legenda
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildLegendaItem('Drop', Colors.blue),
                  _buildLegendaItem('Evento', Colors.purple),
                  _buildLegendaItem('Andar', Colors.green),
                  _buildLegendaItem('Inativo', Colors.grey, isInativo: true),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Color _corCategoria(String categoria) {
    switch (categoria) {
      case 'drop':
        return Colors.blue;
      case 'evento':
        return Colors.purple;
      case 'andar':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatarChance(double chance) {
    if (chance >= 1) {
      return chance.toStringAsFixed(chance % 1 == 0 ? 0 : 1);
    } else {
      return chance.toStringAsFixed(2);
    }
  }

  Widget _buildLegendaItem(String label, Color cor, {bool isInativo = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            decoration: isInativo ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
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

      // Carrega configuração de drops após conectar
      if (isConnected) {
        _carregarConfiguracaoDrops();
      }
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

      // Carrega configuração de drops após conectar
      if (success) {
        _carregarConfiguracaoDrops();
      }

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
              // Header com duas colunas
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Coluna 1: Info do jogo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'TECHTERRA',
                            style: TextStyle(
                              fontSize: 22,
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
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, color: Colors.grey.shade600, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Divisor vertical
                    Container(
                      width: 1,
                      height: 70,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    // Coluna 2: Info de drops (clicável)
                    Expanded(
                      child: GestureDetector(
                        onTap: _mostrarModalDrops,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: _multiplicadorDrop > 1 ? Colors.amber.shade600 : Colors.grey.shade500,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'DROP',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _multiplicadorDrop > 1
                                    ? Colors.amber.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _multiplicadorDrop > 1
                                      ? Colors.amber.shade400
                                      : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: _carregandoConfig
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      '${_multiplicadorDrop.toStringAsFixed(_multiplicadorDrop % 1 == 0 ? 0 : 1)}x',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _multiplicadorDrop > 1
                                            ? Colors.amber.shade800
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _multiplicadorDrop > 1 ? 'Bônus ativo!' : 'Toque para ver',
                              style: TextStyle(
                                fontSize: 10,
                                color: _multiplicadorDrop > 1
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade500,
                                fontWeight: _multiplicadorDrop > 1 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      _buildMenuCard(
                        icon: Icons.explore,
                        label: 'Aventura',
                        color: _isDriveConnected ? const Color(0xFF3182CE) : Colors.grey,
                        onTap: _isDriveConnected ? () => context.go('/modo-selecao') : null,
                      ),
                      _buildMenuCard(
                        icon: Icons.leaderboard,
                        label: 'Ranking',
                        color: _isDriveConnected ? const Color(0xFFE53E3E) : Colors.grey,
                        onTap: _isDriveConnected ? () => context.go('/ranking') : null,
                      ),
                      _buildMenuCard(
                        icon: Icons.admin_panel_settings,
                        label: 'Admin',
                        color: _isDriveConnected ? const Color(0xFF3182CE) : Colors.grey,
                        onTap: _isDriveConnected ? () => context.go('/admin') : null,
                      ),
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
