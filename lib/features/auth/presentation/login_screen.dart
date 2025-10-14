import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/user_cache_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();
  final _storageService = StorageService();

  bool _loading = false;
  bool _rememberEmail = true;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricTypeName = 'Biometria';
  String _biometricIcon = '🔐';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Inicializa os serviços e carrega dados salvos
  Future<void> _initializeServices() async {
    try {
      await _storageService.init();
      await _loadSavedData();
      await _checkBiometricAvailability();

      // Login automático por biometria se habilitado
      if (_isBiometricEnabled && _isBiometricAvailable) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _attemptBiometricLogin(autoLogin: true);
        }
      }
    } catch (e) {
      print('❌ [LoginScreen] Erro na inicialização: $e');
    }
  }

  /// Carrega dados salvos do usuário
  Future<void> _loadSavedData() async {
    try {
      final lastEmail = await _storageService.getLastEmail();
      final rememberEmail = await _storageService.shouldRememberEmail();
      final biometricEnabled = await _storageService.isBiometricEnabled();

      if (mounted) {
        setState(() {
          _rememberEmail = rememberEmail;
          _isBiometricEnabled = biometricEnabled;

          if (rememberEmail && lastEmail != null) {
            _emailController.text = lastEmail;
          }
        });
      }
    } catch (e) {
      print('❌ [LoginScreen] Erro ao carregar dados: $e');
    }
  }

  /// Verifica disponibilidade da biometria
  Future<void> _checkBiometricAvailability() async {
    try {
      final status = await _biometricService.getBiometricStatus();
      final isAvailable = status == BiometricStatus.available;

      String typeName = 'Biometria';
      String icon = '🔐';

      if (isAvailable) {
        typeName = await _biometricService.getPrimaryBiometricTypeName();
        icon = await _biometricService.getPrimaryBiometricIcon();
      }

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _biometricTypeName = typeName;
          _biometricIcon = icon;
        });
      }
    } catch (e) {
      print('❌ [LoginScreen] Erro ao verificar biometria: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Erro de login'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email e senha são obrigatórios.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Usa o AuthProvider para fazer login via Firebase
      await ref.read(authProvider.notifier).signInWithEmail(email, password);

      // Verifica o estado após a tentativa de login
      final authState = ref.read(authProvider);

      if (authState.status == AuthStatus.authenticated) {
        // Salva dados do usuário após login bem-sucedido
        await _saveUserDataAfterLogin(email, password);

        // Salva email no provider para ficar disponível globalmente
        final cachedEmail = await UserCacheService.getEmailEmCache();
        if (cachedEmail != null && cachedEmail.isNotEmpty) {
          ref.read(cachedUserEmailStateProvider.notifier).state = cachedEmail;
        }

        // Pergunta sobre biometria se ainda não foi configurada
        final firstSetupDone = await _storageService.isFirstBiometricSetupDone();
        print('🔍 [LoginScreen] Debug biometria:');
        print('   - _isBiometricAvailable: $_isBiometricAvailable');
        print('   - _isBiometricEnabled: $_isBiometricEnabled');
        print('   - firstSetupDone: $firstSetupDone');

        if (_isBiometricAvailable && !_isBiometricEnabled && !firstSetupDone) {
          print('✅ [LoginScreen] Mostrando dialog de setup de biometria');
          await _showBiometricSetupDialog();
        } else {
          print('❌ [LoginScreen] Não mostra dialog de biometria - Razões:');
          if (!_isBiometricAvailable) print('   - Biometria não disponível');
          if (_isBiometricEnabled) print('   - Biometria já habilitada');
          if (firstSetupDone) print('   - Setup já foi feito antes');
        }

        if (mounted) {
          _showSuccess('Login realizado com sucesso!');
          context.go('/home');
        }
      } else if (authState.status == AuthStatus.error) {
        _showError(authState.errorMessage ?? 'Erro ao fazer login');
      }
    } catch (e) {
      _showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Salva dados do usuário após login bem-sucedido
  Future<void> _saveUserDataAfterLogin(String email, String password) async {
    try {
      // Salva email se o usuário quer lembrar
      if (_rememberEmail) {
        await _storageService.saveLastEmail(email);
      } else {
        await _storageService.clearLastEmail();
      }

      // Atualiza preferência de lembrar email
      await _storageService.setRememberEmail(_rememberEmail);

      // Salva credenciais de forma segura para login biométrico
      if (_isBiometricEnabled || _isBiometricAvailable) {
        await _storageService.saveUserCredentials(
          email: email,
          password: password,
        );
      }

      print('✅ [LoginScreen] Dados do usuário salvos');
    } catch (e) {
      print('❌ [LoginScreen] Erro ao salvar dados: $e');
    }
  }

  /// Tenta fazer login usando biometria
  Future<void> _attemptBiometricLogin({bool autoLogin = false}) async {
    try {
      if (!_isBiometricAvailable || !_isBiometricEnabled) {
        if (!autoLogin) {
          _showError('Biometria não está disponível ou habilitada.');
        }
        return;
      }

      setState(() => _loading = true);

      // Obtém credenciais salvas
      final credentials = await _storageService.getUserCredentials();
      if (credentials == null) {
        if (!autoLogin) {
          _showError('Credenciais não encontradas. Faça login normal primeiro.');
        }
        return;
      }

      // Autentica usando biometria
      final reason = autoLogin
          ? 'Use $_biometricTypeName para acessar rapidamente'
          : 'Confirme sua identidade com $_biometricTypeName';

      final authResult = await _biometricService.authenticate(reason: reason);

      if (authResult.success) {
        // Preenche campos com credenciais salvas
        _emailController.text = credentials.email;
        _passwordController.text = credentials.password;

        // Faz login com Firebase usando as credenciais
        await ref.read(authProvider.notifier).signInWithEmail(
          credentials.email,
          credentials.password,
        );

        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.authenticated && mounted) {
          if (!autoLogin) {
            _showSuccess('Autenticação biométrica realizada com sucesso!');
          }
          context.go('/home');
        }
      } else {
        if (!autoLogin || authResult.errorType != BiometricErrorType.userCancel) {
          _showError(authResult.message);
        }
      }
    } catch (e) {
      if (!autoLogin) {
        _showError('Erro na autenticação biométrica: $e');
      }
      print('❌ [LoginScreen] Erro na autenticação biométrica: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Mostra dialog para configurar biometria
  Future<void> _showBiometricSetupDialog() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_biometricIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text('Usar $_biometricTypeName?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quer habilitar $_biometricTypeName para fazer login mais rápido?'),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.speed, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Login mais rápido e conveniente')),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.security, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Suas credenciais ficam seguras')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3182CE),
              foregroundColor: Colors.white,
            ),
            child: const Text('Habilitar'),
          ),
        ],
      ),
    );

    // Marca que o usuário já viu o setup
    await _storageService.setFirstBiometricSetupDone();

    if (result == true) {
      await _enableBiometric();
    }
  }

  /// Habilita biometria
  Future<void> _enableBiometric() async {
    try {
      await _storageService.setBiometricEnabled(true);
      if (mounted) {
        setState(() {
          _isBiometricEnabled = true;
        });
        _showSuccess('$_biometricTypeName habilitada com sucesso!');
      }
    } catch (e) {
      _showError('Erro ao habilitar biometria: $e');
    }
  }

  /// MÉTODO DE DEBUG - Reseta configurações
  Future<void> _resetBiometricSettings() async {
    try {
      await _storageService.clearAllLoginData();
      if (mounted) {
        setState(() {
          _isBiometricEnabled = false;
          _emailController.clear();
          _passwordController.clear();
        });
        _showSuccess('✅ Configurações resetadas! Faça login novamente.');
      }
    } catch (e) {
      _showError('Erro ao resetar configurações: $e');
    }
  }

  /// MÉTODO DE DEBUG - Força dialog de biometria
  Future<void> _forceShowBiometricDialog() async {
    if (_isBiometricAvailable) {
      await _showBiometricSetupDialog();
    } else {
      _showError('Biometria não está disponível neste dispositivo.');
    }
  }

  /// Limpa email salvo
  Future<void> _clearLastEmail() async {
    try {
      await _storageService.clearLastEmail();
      if (mounted) {
        setState(() {
          _emailController.clear();
        });
        _showSuccess('Email removido');
      }
    } catch (e) {
      _showError('Erro ao remover email: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mapas_aventura/floresta_verde.jpg'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo/Título
                      const Text(
                        'TECHTERRA',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entre em sua aventura',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email field com botão de limpar
                      Stack(
                        children: [
                          _CustomTextField(
                            label: 'Email',
                            icon: Icons.email_outlined,
                            obscure: false,
                            controller: _emailController,
                          ),
                          if (_emailController.text.isNotEmpty)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                onPressed: _clearLastEmail,
                                icon: const Icon(Icons.clear, size: 20),
                                color: Colors.grey.shade400,
                                tooltip: 'Remover email salvo',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Password field
                      _CustomTextField(
                        label: 'Senha',
                        icon: Icons.lock_outline,
                        obscure: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 16),

                      // Checkbox "Lembrar email"
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberEmail,
                            onChanged: (value) {
                              setState(() {
                                _rememberEmail = value ?? true;
                              });
                            },
                            activeColor: const Color(0xFF3182CE),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberEmail = !_rememberEmail;
                                });
                              },
                              child: Text(
                                'Lembrar meu email',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3182CE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, 
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Acessar',
                                  style: TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      // Separador "OU" e botão de biometria (se disponível)
                      if (_isBiometricAvailable) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OU',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade400)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Botão de login biométrico
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3182CE),
                              side: const BorderSide(color: Color(0xFF3182CE), width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loading || !_isBiometricEnabled
                                ? null
                                : () => _attemptBiometricLogin(autoLogin: false),
                            icon: Text(
                              _biometricIcon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            label: Text(
                              _isBiometricEnabled
                                  ? 'Usar $_biometricTypeName'
                                  : '$_biometricTypeName não configurada',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Link para configurar biometria se não estiver habilitada
                        if (!_isBiometricEnabled) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _loading ? null : _forceShowBiometricDialog,
                              child: Text(
                                'Habilitar $_biometricTypeName',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],

                      // MENU DEBUG - Remover em produção
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: _resetBiometricSettings,
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _forceShowBiometricDialog,
                            child: Text(
                              'Biometria',
                              style: TextStyle(
                                color: Colors.blue.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class _CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;

  const _CustomTextField({
    required this.label,
    required this.icon,
    required this.obscure,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF2D3748), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3182CE), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      keyboardType: obscure ? TextInputType.visiblePassword : TextInputType.emailAddress,
    );
  }
}
