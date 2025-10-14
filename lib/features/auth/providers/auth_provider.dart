import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/user_cache_service.dart';
import '../../../core/config/offline_config.dart';

// Estados possíveis da autenticação
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier para gerenciar o estado de autenticação Firebase
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthNotifier() : super(const AuthState(status: AuthStatus.initial)) {
    _initAuth();
  }

  /// Inicializa autenticação (com auto-login em modo offline)
  Future<void> _initAuth() async {
    // MODO OFFLINE: Tenta fazer auto-login do cache
    if (OfflineConfig.isOfflineMode) {
      print('🔌 [AuthProvider] Modo OFFLINE - Verificando cache de usuário');
      final temCache = await UserCacheService.temUsuarioEmCache();

      if (temCache) {
        final userData = await UserCacheService.carregarUsuario();
        if (userData != null) {
          print('✅ [AuthProvider] Usuário carregado do cache (modo offline)');
          // Cria um "usuário fake" apenas com os dados do cache
          // Não precisa fazer login no Firebase em modo offline
          state = const AuthState(status: AuthStatus.authenticated);
          return;
        }
      }
    }

    // Escuta mudanças no estado de autenticação (apenas em modo online)
    _firebaseAuth.authStateChanges().listen((User? user) {
      print('🔐 [AuthProvider] authStateChanges - User: $user');
      print('🔐 [AuthProvider] authStateChanges - Email: ${user?.email}');
      if (user != null) {
        print('✅ [AuthProvider] Usuário autenticado: ${user.email}');
        // Salva no cache quando autentica
        UserCacheService.salvarUsuario(user);
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        print('❌ [AuthProvider] Usuário não autenticado');
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Salva usuário no cache
      if (userCredential.user != null) {
        await UserCacheService.salvarUsuario(userCredential.user!);
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        user: userCredential.user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Usuário não encontrado';
          break;
        case 'wrong-password':
          errorMessage = 'Senha incorreta';
          break;
        case 'user-disabled':
          errorMessage = 'Usuário desabilitado';
          break;
        case 'too-many-requests':
          errorMessage = 'Muitas tentativas. Tente novamente mais tarde';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        default:
          errorMessage = 'Erro ao fazer login: ${e.message}';
      }
      
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      state = AuthState(
        status: AuthStatus.authenticated, 
        user: userCredential.user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'A senha é muito fraca';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este email já está em uso';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        default:
          errorMessage = 'Erro ao criar conta: ${e.message}';
      }
      
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Limpa cache do usuário
    await UserCacheService.limparCache();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Obtém email do usuário (do Firebase ou cache)
  Future<String?> getEmail() async {
    // Primeiro tenta pegar do usuário autenticado
    if (state.user != null) {
      return state.user!.email;
    }

    // Se não tiver, pega do cache
    return await UserCacheService.getEmailEmCache();
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  print('🔐 [AuthProvider] currentUserProvider - AuthState: ${authState.status}');
  print('🔐 [AuthProvider] currentUserProvider - User: $user');
  print('🔐 [AuthProvider] currentUserProvider - Email: ${user?.email}');
  return user;
});
