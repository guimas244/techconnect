/// Configuração para modo offline
///
/// Esta classe controla se o app está em modo offline (100% local)
/// ou modo online (com sincronização no Google Drive)
class OfflineConfig {
  /// Define se o app está em modo offline
  ///
  /// true = Modo OFFLINE (todos os dados salvos apenas localmente)
  /// false = Modo ONLINE (sincroniza com Google Drive)
  static const bool isOfflineMode = true;

  /// Nome da versão
  static const String versionName = 'Offline';

  /// Mensagens de debug
  static void printMode() {
    if (isOfflineMode) {
      print('🔌 [OfflineConfig] Modo OFFLINE ativado - Todos os dados salvos localmente');
    } else {
      print('☁️ [OfflineConfig] Modo ONLINE ativado - Sincronização com Google Drive habilitada');
    }
  }
}
