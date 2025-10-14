import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_cache_service.dart';

/// Helper para obter dados do usuário (Firebase ou Cache)
class UserHelper {
  /// Obtém o email do usuário atual
  /// Tenta primeiro do Firebase, depois do cache local
  static Future<String> getEmail() async {
    // Tenta pegar do Firebase primeiro
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.email != null) {
      return firebaseUser.email!;
    }

    // Se não tiver no Firebase, pega do cache
    final emailCache = await UserCacheService.getEmailEmCache();
    if (emailCache != null && emailCache.isNotEmpty) {
      return emailCache;
    }

    // Fallback
    return 'usuario@local.com';
  }

  /// Obtém o UID do usuário atual
  static Future<String> getUid() async {
    // Tenta pegar do Firebase primeiro
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.uid;
    }

    // Se não tiver no Firebase, pega do cache
    final uidCache = await UserCacheService.getUidEmCache();
    if (uidCache != null && uidCache.isNotEmpty) {
      return uidCache;
    }

    // Fallback
    return 'local_user_uid';
  }

  /// Verifica se o usuário está logado (Firebase ou Cache)
  static Future<bool> isLoggedIn() async {
    // Verifica Firebase
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return true;
    }

    // Verifica cache
    return await UserCacheService.temUsuarioEmCache();
  }
}
