import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../core/services/biometric_service.dart';
import '../core/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      // Inicializa storage service
      await _storageService.init();

      // Carrega dados salvos
      await _loadSavedData();

      // Verifica se biometria está disponível
      await _checkBiometricAvailability();

      // Se biometria está habilitada e disponível, tenta login automático
      if (_isBiometricEnabled && _isBiometricAvailable) {
        // Pequeno delay para UI caregar completamente
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _attemptBiometricLogin(autoLogin: true);
        }
      }
    } catch (e) {
      print('❌ [LoginScreen] Erro na inicialização: $e');
      // Continua normalmente mesmo com erro
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

          // Preenche email se deve lembrar
          if (rememberEmail && lastEmail != null) {
            _emailController.text = lastEmail;
          }
        });
      }

      print('✅ [LoginScreen] Dados carregados - Email: ${lastEmail != null}, Biometria: $biometricEnabled');
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

      print('✅ [LoginScreen] Biometria - Disponível: $isAvailable, Tipo: $typeName');
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

  /// Login tradicional com email e senha
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email e senha são obrigatórios.');
      return;
    }

    setState(() => _loading = true);

    try {
      // Login simplificado sem Firebase - apenas para acesso ao app
      if (email.isNotEmpty && password.length >= 6) {
        // Simula login bem-sucedido
        await Future.delayed(const Duration(seconds: 1));

        // Salva dados do usuário se login foi bem-sucedido
        await _saveUserDataAfterLogin(email, password);

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
      } else {
        _showError('Senha deve ter pelo menos 6 caracteres.');
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
      // Não interfere no fluxo de login mesmo com erro
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

        // Simula processamento
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          if (!autoLogin) {
            _showSuccess('Autenticação biométrica realizada com sucesso!');
          }
          context.go('/home');
        }
      } else {
        // Só mostra erro se não for login automático ou se não foi cancelado pelo usuário
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
              backgroundColor: Colors.blueGrey.shade900,
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

  /// Habilita/desabilita biometria
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

  /// Limpa dados do último email
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

  /// MÉTODO DE DEBUG - Reseta todas as configurações de biometria
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

  /// MÉTODO DE DEBUG - Força exibição do dialog de biometria
  Future<void> _forceShowBiometricDialog() async {
    if (_isBiometricAvailable) {
      // Força o dialog mesmo se já foi configurado
      await _showBiometricSetupDialogForced();
    } else {
      _showError('Biometria não está disponível neste dispositivo.');
    }
  }

  /// Versão forçada do dialog de setup (para debug)
  Future<void> _showBiometricSetupDialogForced() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_biometricIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text('Configurar $_biometricTypeName')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isBiometricEnabled
              ? 'Biometria já está habilitada. Quer reconfigurá-la?'
              : 'Quer habilitar $_biometricTypeName para fazer login mais rápido?'),
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade900,
              foregroundColor: Colors.white,
            ),
            child: Text(_isBiometricEnabled ? 'Reconfigurar' : 'Habilitar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _enableBiometric();
    }
  }

  /// MÉTODO DE DEBUG - Mostra informações de debug
  Future<void> _showDebugInfo() async {
    try {
      final debugInfo = await _storageService.getDebugInfo();
      final biometricStatus = await _biometricService.getBiometricStatus();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📱 Biometria Disponível: $_isBiometricAvailable'),
                Text('🔐 Biometria Habilitada: $_isBiometricEnabled'),
                Text('📊 Status: $biometricStatus'),
                Text('🆔 Tipo: $_biometricTypeName'),
                const SizedBox(height: 16),
                const Text('💾 Armazenamento:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...debugInfo.entries.map((entry) =>
                  Text('${entry.key}: ${entry.value}')
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Erro ao obter debug info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE), // Cinza claro metálico
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.blueGrey.shade200, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Column(
                      children: [
                        Text(
                          'TECH',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: 'RobotoMono',
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [Colors.blueGrey.shade700, Colors.blueGrey.shade300],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        Text(
                          'CONNECT',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: 'RobotoMono',
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [Colors.blueGrey.shade300, Colors.blueGrey.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Campo de email com botão de limpar
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
                              color: Colors.blueGrey.shade400,
                              tooltip: 'Remover email salvo',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Campo de senha
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
                          activeColor: Colors.blueGrey.shade700,
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
                                color: Colors.blueGrey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botão principal de login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    // Separador "OU" e botão de biometria (se disponível)
                    if (_isBiometricAvailable) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.blueGrey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.blueGrey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botão de login biométrico
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueGrey.shade700,
                            side: BorderSide(color: Colors.blueGrey.shade400, width: 2),
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
                            onPressed: _loading ? null : _enableBiometric,
                            child: Text(
                              'Habilitar $_biometricTypeName',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
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
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: _resetBiometricSettings,
                            child: Text(
                              'Resetar Biometria',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _forceShowBiometricDialog,
                            child: Text(
                              'Forçar Dialog',
                              style: TextStyle(
                                color: Colors.blue.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _showDebugInfo,
                            child: Text(
                              'Debug Info',
                              style: TextStyle(
                                color: Colors.green.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      style: const TextStyle(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade700),
        filled: true,
        fillColor: Colors.blueGrey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade400, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent.shade200, width: 2),
        ),
      ),
      keyboardType: obscure ? TextInputType.visiblePassword : TextInputType.emailAddress,
    );
  }
}
