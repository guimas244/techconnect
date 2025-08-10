/// Utilitário para configuração inicial do TECH CONNECT
/// Execute este script uma vez para obter o FOLDER_ID do Google Drive

import '../features/drive/drive_service.dart';
import 'google_drive_client.dart';

class TechConnectSetup {
  /// Configuração inicial: cria pasta TECH CONNECT e retorna o FOLDER_ID
  static Future<String?> configurarPrimeiroPasso() async {
    try {
      print('🚀 [SETUP] Iniciando configuração TECH CONNECT...');
      
      // 1. Conectar ao Google Drive
      print('🔐 [SETUP] Conectando ao Google Drive...');
      final api = await DriveClientFactory.create();
      
      // 2. Criar serviço temporário sem FOLDER_ID
      final driveService = DriveService(api, folderId: null);
      
      // 3. Criar pasta TECH CONNECT
      print('📁 [SETUP] Criando pasta TECH CONNECT...');
      final folderId = await driveService.criarPastaTechConnect();
      
      if (folderId != null) {
        print('✅ [SETUP] Configuração concluída!');
        print('📋 [SETUP] Cole este FOLDER_ID no código:');
        print('🎯 [SETUP] FOLDER_ID: $folderId');
        print('');
        print('⚠️ [SETUP] PRÓXIMO PASSO:');
        print('   1. Abra: lib/core/google_drive_client.dart');
        print('   2. Substitua: "PASTE_TECH_CONNECT_FOLDER_ID_HERE"');
        print('   3. Por: "$folderId"');
        print('   4. Reinicie o aplicativo');
        
        return folderId;
      } else {
        print('❌ [SETUP] Falha na configuração');
        return null;
      }
    } catch (e) {
      print('❌ [SETUP] Erro: $e');
      return null;
    }
  }
  
  /// Testa se a configuração está funcionando
  static Future<bool> testarConfiguracao() async {
    try {
      print('🧪 [TESTE] Testando configuração TECH CONNECT...');
      
      final api = await DriveClientFactory.create();
      final driveService = DriveService(api);
      
      if (driveService.folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
        print('⚠️ [TESTE] FOLDER_ID ainda não configurado');
        return false;
      }
      
      // Testar listagem na pasta
      final arquivos = await driveService.listInRootFolder();
      print('✅ [TESTE] Pasta encontrada com ${arquivos.length} arquivos');
      
      return true;
    } catch (e) {
      print('❌ [TESTE] Erro: $e');
      return false;
    }
  }
}
