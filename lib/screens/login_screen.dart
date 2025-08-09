import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro de login'),
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

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Email e senha são obrigatórios.');
      return;
    }
    setState(() => _loading = true);
    try {
      // Garante que o Firebase está inicializado
      if (FirebaseAuth.instance.app == null) {
        _showError('Firebase não inicializado. Reinicie o app.');
        return;
      }
      final user = await AuthService().signInWithEmail(email, password);
      if (user != null) {
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    _CustomTextField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      obscure: false,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    _CustomTextField(
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      obscure: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 32),
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          // TODO: Implementar login com Google
                        },
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text(
                          'Entrar com Google',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
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
