import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço para cache de usuário local (login persistente)
class UserCacheService {
  static const String _keyEmail = 'cached_user_email';
  static const String _keyDisplayName = 'cached_user_display_name';
  static const String _keyPhotoUrl = 'cached_user_photo_url';
  static const String _keyUid = 'cached_user_uid';
  static const String _keyIsLoggedIn = 'cached_user_is_logged_in';

  /// Salva dados do usuário no cache local
  static Future<void> salvarUsuario(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyEmail, user.email ?? '');
      await prefs.setString(_keyDisplayName, user.displayName ?? '');
      await prefs.setString(_keyPhotoUrl, user.photoURL ?? '');
      await prefs.setString(_keyUid, user.uid);
      await prefs.setBool(_keyIsLoggedIn, true);

      print('✅ [UserCache] Usuário salvo no cache: ${user.email}');
    } catch (e) {
      print('❌ [UserCache] Erro ao salvar usuário: $e');
    }
  }

  /// Salva usuário no cache a partir de um Map (para modo offline)
  static Future<void> salvarUsuarioFromMap(Map<String, String> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyEmail, userData['email'] ?? '');
      await prefs.setString(_keyDisplayName, userData['displayName'] ?? '');
      await prefs.setString(_keyPhotoUrl, userData['photoUrl'] ?? '');
      await prefs.setString(_keyUid, userData['uid'] ?? '');
      await prefs.setBool(_keyIsLoggedIn, true);

      print('✅ [UserCache] Usuário salvo no cache (modo offline): ${userData['email']}');
    } catch (e) {
      print('❌ [UserCache] Erro ao salvar usuário: $e');
    }
  }

  /// Verifica se existe um usuário em cache
  static Future<bool> temUsuarioEmCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print('❌ [UserCache] Erro ao verificar cache: $e');
      return false;
    }
  }

  /// Carrega dados do usuário do cache
  static Future<Map<String, String>?> carregarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) {
        return null;
      }

      final email = prefs.getString(_keyEmail) ?? '';
      final displayName = prefs.getString(_keyDisplayName) ?? '';
      final photoUrl = prefs.getString(_keyPhotoUrl) ?? '';
      final uid = prefs.getString(_keyUid) ?? '';

      if (email.isEmpty || uid.isEmpty) {
        return null;
      }

      print('✅ [UserCache] Usuário carregado do cache: $email');

      return {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'uid': uid,
      };
    } catch (e) {
      print('❌ [UserCache] Erro ao carregar usuário: $e');
      return null;
    }
  }

  /// Limpa o cache do usuário (logout)
  static Future<void> limparCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyEmail);
      await prefs.remove(_keyDisplayName);
      await prefs.remove(_keyPhotoUrl);
      await prefs.remove(_keyUid);
      await prefs.setBool(_keyIsLoggedIn, false);

      print('✅ [UserCache] Cache do usuário limpo');
    } catch (e) {
      print('❌ [UserCache] Erro ao limpar cache: $e');
    }
  }

  /// Obtém email do usuário em cache
  static Future<String?> getEmailEmCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyEmail);
    } catch (e) {
      return null;
    }
  }

  /// Obtém UID do usuário em cache
  static Future<String?> getUidEmCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUid);
    } catch (e) {
      return null;
    }
  }
}
