import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Serviço de autenticação biométrica
/// Gerencia Touch ID, Face ID, Fingerprint e outras formas de biometria
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static BiometricService? _instance;

  // Singleton pattern
  factory BiometricService() {
    _instance ??= BiometricService._internal();
    return _instance!;
  }

  BiometricService._internal();

  /// Verifica se o dispositivo suporta biometria
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('❌ [BiometricService] Erro ao verificar suporte do dispositivo: $e');
      return false;
    }
  }

  /// Verifica se há biometrias cadastradas no dispositivo
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('❌ [BiometricService] Erro ao verificar biometrias disponíveis: $e');
      // Verifica se é o erro específico do FragmentActivity
      if (e.toString().contains('FragmentActivity')) {
        print('❌ [BiometricService] ERRO: MainActivity precisa extends FlutterFragmentActivity');
        print('   Solução: Altere MainActivity.kt para usar FlutterFragmentActivity');
      }
      return false;
    }
  }

  /// Obtém lista de biometrias disponíveis
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('❌ [BiometricService] Erro ao obter biometrias: $e');
      return [];
    }
  }

  /// Verifica se biometria está disponível para uso
  Future<BiometricStatus> getBiometricStatus() async {
    try {
      // Verifica suporte do dispositivo
      if (!await isDeviceSupported()) {
        return BiometricStatus.notSupported;
      }

      // Verifica se pode usar biometria
      if (!await canCheckBiometrics()) {
        return BiometricStatus.notAvailable;
      }

      // Verifica se há biometrias cadastradas
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return BiometricStatus.notEnrolled;
      }

      return BiometricStatus.available;
    } catch (e) {
      print('❌ [BiometricService] Erro ao verificar status: $e');
      return BiometricStatus.unknown;
    }
  }

  /// Autentica usando biometria
  Future<BiometricAuthResult> authenticate({
    String reason = 'Confirme sua identidade para acessar o TechConnect',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // Verifica se biometria está disponível
      final status = await getBiometricStatus();
      if (status != BiometricStatus.available) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          message: _getStatusMessage(status),
        );
      }

      // Tenta autenticar
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        print('✅ [BiometricService] Autenticação biométrica bem-sucedida');
        return BiometricAuthResult(
          success: true,
          message: 'Autenticação realizada com sucesso',
        );
      } else {
        print('❌ [BiometricService] Autenticação biométrica cancelada pelo usuário');
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userCancel,
          message: 'Autenticação cancelada pelo usuário',
        );
      }
    } on PlatformException catch (e) {
      print('❌ [BiometricService] Erro na autenticação: ${e.code} - ${e.message}');

      // Verifica se é o erro específico do FragmentActivity
      if (e.message?.contains('FragmentActivity') == true) {
        print('❌ [BiometricService] ERRO: MainActivity precisa extends FlutterFragmentActivity');
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.unknown,
          message: 'Configuração incorreta do Android. Contate o desenvolvedor.',
        );
      }

      return BiometricAuthResult(
        success: false,
        errorType: _mapPlatformError(e.code),
        message: e.message ?? 'Erro desconhecido na autenticação',
      );
    } catch (e) {
      print('❌ [BiometricService] Erro inesperado: $e');
      return BiometricAuthResult(
        success: false,
        errorType: BiometricErrorType.unknown,
        message: 'Erro inesperado: $e',
      );
    }
  }

  /// Obtém o nome do tipo de biometria principal disponível
  Future<String> getPrimaryBiometricTypeName() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) return 'Biometria';

      // Prioriza Face ID/Face Unlock, depois Touch ID/Fingerprint
      if (biometrics.contains(BiometricType.face)) {
        return Platform.isIOS ? 'Face ID' : 'Reconhecimento Facial';
      }
      if (biometrics.contains(BiometricType.fingerprint)) {
        return Platform.isIOS ? 'Touch ID' : 'Digital';
      }
      if (biometrics.contains(BiometricType.iris)) {
        return 'Íris';
      }

      return 'Biometria';
    } catch (e) {
      print('❌ [BiometricService] Erro ao obter tipo de biometria: $e');
      return 'Biometria';
    }
  }

  /// Obtém ícone apropriado para o tipo de biometria
  Future<String> getPrimaryBiometricIcon() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) return '🔐';

      if (biometrics.contains(BiometricType.face)) {
        return '👤';
      }
      if (biometrics.contains(BiometricType.fingerprint)) {
        return '👆';
      }
      if (biometrics.contains(BiometricType.iris)) {
        return '👁️';
      }

      return '🔐';
    } catch (e) {
      print('❌ [BiometricService] Erro ao obter ícone: $e');
      return '🔐';
    }
  }

  /// Mapeia códigos de erro da plataforma para tipos conhecidos
  BiometricErrorType _mapPlatformError(String errorCode) {
    switch (errorCode) {
      case 'UserCancel':
      case 'user_cancel':
        return BiometricErrorType.userCancel;
      case 'UserFallback':
      case 'user_fallback':
        return BiometricErrorType.userFallback;
      case 'SystemCancel':
      case 'system_cancel':
        return BiometricErrorType.systemCancel;
      case 'TouchIDNotAvailable':
      case 'BiometricNotAvailable':
      case 'biometric_not_available':
        return BiometricErrorType.notAvailable;
      case 'TouchIDNotEnrolled':
      case 'BiometricNotEnrolled':
      case 'biometric_not_enrolled':
        return BiometricErrorType.notEnrolled;
      case 'TouchIDLockout':
      case 'BiometricLockout':
      case 'biometric_lockout':
        return BiometricErrorType.lockout;
      case 'PermanentlyLockedOut':
      case 'permanently_locked_out':
        return BiometricErrorType.permanentLockout;
      default:
        return BiometricErrorType.unknown;
    }
  }

  /// Obtém mensagem amigável baseada no status
  String _getStatusMessage(BiometricStatus status) {
    switch (status) {
      case BiometricStatus.available:
        return 'Biometria disponível';
      case BiometricStatus.notSupported:
        return 'Este dispositivo não suporta biometria';
      case BiometricStatus.notAvailable:
        return 'Biometria não disponível no momento';
      case BiometricStatus.notEnrolled:
        return 'Nenhuma biometria cadastrada no dispositivo';
      case BiometricStatus.unknown:
        return 'Status da biometria desconhecido';
    }
  }
}

/// Status da biometria no dispositivo
enum BiometricStatus {
  /// Biometria disponível e pronta para uso
  available,
  /// Dispositivo não suporta biometria
  notSupported,
  /// Biometria não está disponível (desabilitada ou erro temporário)
  notAvailable,
  /// Nenhuma biometria cadastrada no dispositivo
  notEnrolled,
  /// Status desconhecido
  unknown,
}

/// Tipos de erro na autenticação biométrica
enum BiometricErrorType {
  /// Usuário cancelou a autenticação
  userCancel,
  /// Usuário escolheu método alternativo (senha/PIN)
  userFallback,
  /// Sistema cancelou (ex: outra app entrou em foco)
  systemCancel,
  /// Biometria não disponível
  notAvailable,
  /// Nenhuma biometria cadastrada
  notEnrolled,
  /// Muitas tentativas falhas - lockout temporário
  lockout,
  /// Lockout permanente - precisa usar senha
  permanentLockout,
  /// Erro desconhecido
  unknown,
}

/// Resultado da autenticação biométrica
class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String message;

  const BiometricAuthResult({
    required this.success,
    this.errorType,
    required this.message,
  });

  @override
  String toString() {
    return 'BiometricAuthResult(success: $success, errorType: $errorType, message: $message)';
  }
}