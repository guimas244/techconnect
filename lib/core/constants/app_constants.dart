class AppConstants {
  // App Info
  static const String appName = 'TechConnect';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String aventuraRoute = '/aventura';
  static const String rankingRoute = '/ranking';
  static const String adminRoute = '/admin';
  static const String tipagemRoute = '/admin/tipagem';
  static const String monstrosRoute = '/admin/monstros';
  static const String regrasRoute = '/admin/regras';

  // Novos modos de jogo
  static const String modoSelecaoRoute = '/modo-selecao';
  static const String unlockRoute = '/unlock';
  static const String exploradorRoute = '/explorador';
  static const String exploradorEquipeRoute = '/explorador/equipe';
  static const String exploradorMapaRoute = '/explorador/mapa';
  static const String exploradorBatalhaRoute = '/explorador/batalha';
  static const String exploradorLojaRoute = '/explorador/loja';
  static const String exploradorFortunaRoute = '/explorador/fortuna';
  static const String killsPermanentesRoute = '/kills-permanentes';

  // Storage Keys
  static const String userBoxKey = 'user_box';
  static const String tipagemBoxKey = 'tipagem_box';
  
  // Assets Paths
  static const String tipagemAssetsPath = 'assets/tipagens/';
  static const String tipagemJsonsPath = 'dados_json/';
  static const String aventuraJsonsPath = 'dados_json/';
  
  // Default Values
  static const double defaultDamageMultiplier = 1.0;
  static const double minDamageMultiplier = 0.0;
  static const double maxDamageMultiplier = 2.0;
  static const int sliderDivisions = 20; // 0.1 increments
}
