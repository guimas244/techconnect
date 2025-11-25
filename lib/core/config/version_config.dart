class VersionConfig {
  static const String currentVersion = '2.4.0';
  
  /// Compara duas versões e retorna:
  /// 1 se version1 > version2
  /// 0 se version1 == version2
  /// -1 se version1 < version2
  static int compareVersions(String version1, String version2) {
    List<int> v1Parts = version1.split('.').map(int.parse).toList();
    List<int> v2Parts = version2.split('.').map(int.parse).toList();
    
    // Garantir que ambas as listas tenham o mesmo tamanho
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }
    
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }
  
  /// Extrai a versão do nome do jogador no formato "nome - versão"
  /// Se não tiver versão, considera como 1.0
  static String extractVersionFromPlayerName(String playerName) {
    if (playerName.contains(' - ')) {
      String version = playerName.split(' - ').last;
      // Verifica se termina com "downgrade" e remove
      if (version.endsWith(' downgrade')) {
        version = version.replaceAll(' downgrade', '');
      }
      return version;
    }
    return '1.0'; // Versão padrão para jogadores sem versão salva
  }
  
  /// Extrai apenas o nome do jogador, removendo versão e downgrade
  static String extractPlayerNameOnly(String fullPlayerName) {
    if (fullPlayerName.contains(' - ')) {
      return fullPlayerName.split(' - ').first;
    }
    return fullPlayerName;
  }
  
  /// Formata o nome do jogador com versão
  static String formatPlayerNameWithVersion(String playerName, String version, {bool isDowngrade = false}) {
    String formatted = '$playerName - $version';
    if (isDowngrade) {
      formatted += ' downgrade';
    }
    return formatted;
  }
  
  /// Verifica se é um downgrade comparado com a versão salva
  static bool isDowngrade(String currentVersion, String savedVersion) {
    return compareVersions(currentVersion, savedVersion) < 0;
  }
}