import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/user_helper.dart';
import '../../core/config/offline_config.dart';
import '../../core/services/user_cache_service.dart';
import '../../core/providers/user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Inicia a animação
    _animationController.forward();

    // Carrega email do cache e verifica autenticação
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Carrega email do cache se disponível (modo offline)
    if (OfflineConfig.isOfflineMode) {
      final cachedEmail = await UserCacheService.getEmailEmCache();
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        print('📧 [SplashScreen] Email carregado do cache: $cachedEmail');
        // Salva no provider para ficar disponível globalmente
        ref.read(cachedUserEmailStateProvider.notifier).state = cachedEmail;
      }
    }

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    print('🔍 [SplashScreen] Verificando autenticação...');
    OfflineConfig.printMode();

    // Verifica se o usuário está logado (Firebase ou cache)
    final isLoggedIn = await UserHelper.isLoggedIn();

    if (isLoggedIn) {
      final email = await UserHelper.getEmail();
      print('✅ [SplashScreen] Usuário autenticado: $email');
      context.go('/home');
    } else {
      print('❌ [SplashScreen] Usuário não autenticado, redirecionando para login');
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wallpaper.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Overlay muito sutil apenas para o loading
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
