class AppConstants {
  // App Info
  static const String appName = 'TechConnect';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String aventuraRoute = '/aventura';
  static const String adminRoute = '/admin';
  static const String tipagemRoute = '/admin/tipagem';
  static const String monstrosRoute = '/admin/monstros';
  static const String regrasRoute = '/admin/regras';
  
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
