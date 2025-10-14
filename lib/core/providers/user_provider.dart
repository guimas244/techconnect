import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../services/user_cache_service.dart';

// StateProvider para manter o email do usuário logado no Google Drive
final currentUserEmailStateProvider = StateProvider<String?>((ref) => null);

// StateProvider para armazenar email do cache (carregado na inicialização)
final cachedUserEmailStateProvider = StateProvider<String?>((ref) => null);

// Provider para obter o email do usuário autenticado (Firebase -> Drive -> Cache)
final currentUserEmailProvider = Provider<String?>((ref) {
  // Primeiro tenta pegar do Firebase Auth
  final user = ref.watch(currentUserProvider);
  final firebaseEmail = user?.email;

  // Se não tiver no Firebase, pega do StateProvider (Google Drive)
  final driveEmail = ref.watch(currentUserEmailStateProvider);

  // Se não tiver no Firebase nem no Drive, pega do cache
  final cachedEmail = ref.watch(cachedUserEmailStateProvider);

  final email = firebaseEmail ?? driveEmail ?? cachedEmail;

  print('📧 [UserProvider] currentUserEmailProvider - Firebase User: $user');
  print('📧 [UserProvider] currentUserEmailProvider - Firebase Email: $firebaseEmail');
  print('📧 [UserProvider] currentUserEmailProvider - Drive Email: $driveEmail');
  print('📧 [UserProvider] currentUserEmailProvider - Cached Email: $cachedEmail');
  print('📧 [UserProvider] currentUserEmailProvider - Final Email: $email');

  return email;
});

// Provider que garante um email válido ou lança erro
final validUserEmailProvider = Provider<String>((ref) {
  final email = ref.watch(currentUserEmailProvider);
  print('📧 [UserProvider] validUserEmailProvider - Email obtido: $email');

  if (email == null || email.isEmpty) {
    print('❌ [UserProvider] validUserEmailProvider - Email inválido, lançando exceção');
    throw Exception('Usuário não está logado ou email não disponível');
  }

  print('✅ [UserProvider] validUserEmailProvider - Email válido: $email');
  return email;
});

// Provider para verificar se o usuário está logado
final isUserLoggedInProvider = Provider<bool>((ref) {
  final email = ref.watch(currentUserEmailProvider);
  final isLoggedIn = email != null && email.isNotEmpty;
  print('📧 [UserProvider] isUserLoggedInProvider - Email: $email, LoggedIn: $isLoggedIn');
  return isLoggedIn;
});
