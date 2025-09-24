import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro
/// Gerencia dados do usuário usando SharedPreferences e FlutterSecureStorage
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Chaves para armazenamento
  static const String _keyLastEmail = 'last_email';
  static const String _keyRememberEmail = 'remember_email';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserCredentials = 'user_credentials';
  static const String _keyFirstBiometricSetup = 'first_biometric_setup';

  // Singleton pattern
  factory StorageService() {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  StorageService._internal();

  /// Inicializa o serviço de armazenamento
  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      print('✅ [StorageService] Serviço de armazenamento inicializado');
    } catch (e) {
      print('❌ [StorageService] Erro ao inicializar: $e');
      rethrow;
    }
  }

  /// Garante que o serviço está inicializado
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  // ==========================================
  // MÉTODOS PARA EMAIL
  // ==========================================

  /// Salva o último email usado
  Future<bool> saveLastEmail(String email) async {
    try {
      await _ensureInitialized();
      final success = await _prefs!.setString(_keyLastEmail, email);
      if (success) {
        print('✅ [StorageService] Email salvo: ${email.substring(0, 3)}***');
      }
      return success;
    } catch (e) {
      print('❌ [StorageService] Erro ao salvar email: $e');
      return false;
    }
  }

  /// Obtém o último email usado
  Future<String?> getLastEmail() async {
    try {
      await _ensureInitialized();
      final email = _prefs!.getString(_keyLastEmail);
      if (email != null) {
        print('✅ [StorageService] Email recuperado: ${email.substring(0, 3)}***');
      }
      return email;
    } catch (e) {
      print('❌ [StorageService] Erro ao recuperar email: $e');
      return null;
    }
  }

  /// Remove o último email salvo
  Future<bool> clearLastEmail() async {
    try {
      await _ensureInitialized();
      final success = await _prefs!.remove(_keyLastEmail);
      if (success) {
        print('✅ [StorageService] Email removido');
      }
      return success;
    } catch (e) {
      print('❌ [StorageService] Erro ao remover email: $e');
      return false;
    }
  }

  // ==========================================
  // MÉTODOS PARA PREFERÊNCIA "LEMBRAR EMAIL"
  // ==========================================

  /// Define se deve lembrar o email
  Future<bool> setRememberEmail(bool remember) async {
    try {
      await _ensureInitialized();
      final success = await _prefs!.setBool(_keyRememberEmail, remember);
      print('✅ [StorageService] Preferência "lembrar email": $remember');
      return success;
    } catch (e) {
      print('❌ [StorageService] Erro ao definir preferência: $e');
      return false;
    }
  }

  /// Verifica se deve lembrar o email
  Future<bool> shouldRememberEmail() async {
    try {
      await _ensureInitialized();
      return _prefs!.getBool(_keyRememberEmail) ?? true; // true por padrão
    } catch (e) {
      print('❌ [StorageService] Erro ao verificar preferência: $e');
      return true;
    }
  }

  // ==========================================
  // MÉTODOS PARA BIOMETRIA
  // ==========================================

  /// Define se a biometria está habilitada
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      await _ensureInitialized();
      final success = await _prefs!.setBool(_keyBiometricEnabled, enabled);
      print('✅ [StorageService] Biometria habilitada: $enabled');
      return success;
    } catch (e) {
      print('❌ [StorageService] Erro ao definir biometria: $e');
      return false;
    }
  }

  /// Verifica se a biometria está habilitada
  Future<bool> isBiometricEnabled() async {
    try {
      await _ensureInitialized();
      return _prefs!.getBool(_keyBiometricEnabled) ?? false;
    } catch (e) {
      print('❌ [StorageService] Erro ao verificar biometria: $e');
      return false;
    }
  }

  /// Marca se o usuário já passou pelo setup inicial da biometria
  Future<bool> setFirstBiometricSetupDone() async {
    try {
      await _ensureInitialized();
      final success = await _prefs!.setBool(_keyFirstBiometricSetup, true);
      print('✅ [StorageService] Setup inicial de biometria marcado como concluído');
      return success;
    } catch (e) {
      print('❌ [StorageService] Erro ao marcar setup: $e');
      return false;
    }
  }

  /// Verifica se o usuário já passou pelo setup inicial da biometria
  Future<bool> isFirstBiometricSetupDone() async {
    try {
      await _ensureInitialized();
      return _prefs!.getBool(_keyFirstBiometricSetup) ?? false;
    } catch (e) {
      print('❌ [StorageService] Erro ao verificar setup: $e');
      return false;
    }
  }

  // ==========================================
  // MÉTODOS PARA CREDENCIAIS SEGURAS
  // ==========================================

  /// Salva as credenciais do usuário de forma segura
  Future<bool> saveUserCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = '$email:$password';
      await _secureStorage.write(key: _keyUserCredentials, value: credentials);
      print('✅ [StorageService] Credenciais salvas de forma segura');
      return true;
    } catch (e) {
      print('❌ [StorageService] Erro ao salvar credenciais: $e');
      return false;
    }
  }

  /// Obtém as credenciais do usuário
  Future<UserCredentials?> getUserCredentials() async {
    try {
      final credentials = await _secureStorage.read(key: _keyUserCredentials);
      if (credentials == null || !credentials.contains(':')) {
        return null;
      }

      final parts = credentials.split(':');
      if (parts.length != 2) {
        return null;
      }

      print('✅ [StorageService] Credenciais recuperadas');
      return UserCredentials(
        email: parts[0],
        password: parts[1],
      );
    } catch (e) {
      print('❌ [StorageService] Erro ao recuperar credenciais: $e');
      return null;
    }
  }

  /// Remove as credenciais salvas
  Future<bool> clearUserCredentials() async {
    try {
      await _secureStorage.delete(key: _keyUserCredentials);
      print('✅ [StorageService] Credenciais removidas');
      return true;
    } catch (e) {
      print('❌ [StorageService] Erro ao remover credenciais: $e');
      return false;
    }
  }

  // ==========================================
  // MÉTODOS UTILITÁRIOS
  // ==========================================

  /// Limpa todos os dados relacionados ao login
  Future<bool> clearAllLoginData() async {
    try {
      await _ensureInitialized();

      // Remove dados do SharedPreferences
      await _prefs!.remove(_keyLastEmail);
      await _prefs!.remove(_keyRememberEmail);
      await _prefs!.remove(_keyBiometricEnabled);
      await _prefs!.remove(_keyFirstBiometricSetup);

      // Remove credenciais seguras
      await _secureStorage.delete(key: _keyUserCredentials);

      print('✅ [StorageService] Todos os dados de login removidos');
      return true;
    } catch (e) {
      print('❌ [StorageService] Erro ao limpar dados: $e');
      return false;
    }
  }

  /// Obtém informações de debug sobre o armazenamento
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      await _ensureInitialized();

      return {
        'lastEmail': await getLastEmail(),
        'rememberEmail': await shouldRememberEmail(),
        'biometricEnabled': await isBiometricEnabled(),
        'firstSetupDone': await isFirstBiometricSetupDone(),
        'hasCredentials': (await getUserCredentials()) != null,
      };
    } catch (e) {
      print('❌ [StorageService] Erro ao obter debug info: $e');
      return {'error': e.toString()};
    }
  }
}

/// Classe para armazenar credenciais do usuário
class UserCredentials {
  final String email;
  final String password;

  const UserCredentials({
    required this.email,
    required this.password,
  });

  @override
  String toString() {
    // Não expõe a senha no toString por segurança
    return 'UserCredentials(email: ${email.substring(0, 3)}***)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCredentials &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password;

  @override
  int get hashCode => email.hashCode ^ password.hashCode;
}