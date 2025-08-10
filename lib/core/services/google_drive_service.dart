import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../features/drive/drive_service.dart';
import '../google_drive_client.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  DriveService? _driveService;
  bool _isConnected = false;

  /// Inicializa conexão com Google Drive usando o padrão TECH CONNECT
  Future<bool> inicializarConexao() async {
    try {
      print('🔐 [DEBUG] Iniciando conexão com Google Drive - TECH CONNECT...');
      print('🔐 [DEBUG] Chamando DriveClientFactory.create()...');
      
      final api = await DriveClientFactory.create();
      print('✅ [DEBUG] DriveClientFactory.create() bem-sucedido');
      
      _driveService = DriveService(api);
      print('✅ [DEBUG] DriveService criado');
      
      // Teste básico para verificar se a conexão realmente funciona
      print('🔍 [DEBUG] Testando conexão listando arquivos...');
      final testFiles = await _driveService!.listInRootFolder();
      print('✅ [DEBUG] Teste de listagem bem-sucedido: ${testFiles.length} arquivos encontrados');
      
      _isConnected = true;
      print('✅ [DEBUG] Google Drive conectado com sucesso!');
      return true;
    } catch (e) {
      print('❌ [DEBUG] Erro detalhado ao conectar Google Drive:');
      print('❌ [DEBUG] Tipo do erro: ${e.runtimeType}');
      print('❌ [DEBUG] Mensagem: $e');
      print('❌ [DEBUG] Stack trace será exibido na próxima linha...');
      print('❌ [DEBUG] ${StackTrace.current}');
      _isConnected = false;
      return false;
    }
  }

  /// Salva um arquivo JSON no Drive (pasta TECH CONNECT)
  Future<bool> salvarJson(String tipoNome, Map<String, dynamic> jsonData) async {
    if (_driveService == null || !_isConnected) {
      print('⚠️ Google Drive não conectado, tentando conectar...');
      final conectou = await inicializarConexao();
      if (!conectou) return false;
    }

    try {
      final nomeArquivo = 'tb_${tipoNome}_defesa.json';
      print('💾 Salvando arquivo JSON no Drive: $nomeArquivo');
      
      // Verificar se a pasta TECH CONNECT foi configurada
      if (_driveService!.folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
        print('📁 [DEBUG] FOLDER_ID não configurado, criando pasta TECH CONNECT...');
        final novoFolderId = await _driveService!.criarPastaTechConnect();
        if (novoFolderId == null) {
          print('❌ Falha ao criar pasta TECH CONNECT');
          return false;
        }
        print('✅ [DEBUG] Pasta criada com ID: $novoFolderId');
        print('⚠️ [INFO] ATENÇÃO: Atualize o FOLDER_ID no código para: $novoFolderId');
        
        // Recriar DriveService com o novo FOLDER_ID
        final api = await DriveClientFactory.create();
        _driveService = DriveService(api, folderId: novoFolderId);
      }
      
      // Verificar se arquivo já existe
      final arquivosExistentes = await _driveService!.listInRootFolder();
      final arquivoExistente = arquivosExistentes.firstWhere(
        (file) => file.name == nomeArquivo,
        orElse: () => drive.File(),
      );

      if (arquivoExistente.id != null) {
        // Atualizar arquivo existente
        await _driveService!.updateJsonFile(arquivoExistente.id!, jsonData);
        print('✅ Arquivo atualizado no Drive: $nomeArquivo');
      } else {
        // Criar novo arquivo
        await _driveService!.createJsonFile(nomeArquivo, jsonData);
        print('✅ Arquivo criado no Drive: $nomeArquivo');
      }
      
      return true;
    } catch (e) {
      // Se for erro 401 (token expirado), marca como desconectado
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 Token expirado durante salvamento, marcando como desconectado');
        _isConnected = false;
        _driveService = null;
      } else {
        print('❌ Erro ao salvar JSON no Drive: $e');
      }
      return false;
    }
  }

  /// Sincroniza todos os JSONs para o Drive
  Future<bool> sincronizarTodosJsons(Map<String, Map<String, dynamic>> jsonsData) async {
    if (_driveService == null || !_isConnected) {
      final conectou = await inicializarConexao();
      if (!conectou) return false;
    }

    // Verificar se FOLDER_ID está configurado antes de tentar sincronizar
    if (_driveService!.folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
      print('⚠️ [AVISO] FOLDER_ID não configurado. Sincronização cancelada.');
      print('📋 [INFO] Para configurar: Execute a primeira sincronização individual para criar a pasta.');
      return false;
    }

    try {
      print('🔄 Iniciando sincronização TECH CONNECT: ${jsonsData.length} arquivos...');
      
      int sucessos = 0;
      for (final entry in jsonsData.entries) {
        final sucesso = await salvarJson(entry.key, entry.value);
        if (sucesso) sucessos++;
        
        // Pequena pausa para evitar rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      print('✅ Sincronização TECH CONNECT concluída: $sucessos/${jsonsData.length} arquivos');
      return sucessos == jsonsData.length;
    } catch (e) {
      print('❌ Erro na sincronização TECH CONNECT: $e');
      return false;
    }
  }

  /// Lista todos os arquivos JSON na pasta TECH CONNECT
  Future<List<String>> listarArquivosDrive() async {
    if (_driveService == null || !_isConnected) {
      final conectou = await inicializarConexao();
      if (!conectou) return [];
    }

    try {
      final arquivos = await _driveService!.listInRootFolder();
      final nomesJson = arquivos
          .where((file) => file.name?.endsWith('.json') == true)
          .map((file) => file.name!)
          .toList();
      
      print('📋 Encontrados ${nomesJson.length} JSONs na pasta TECH CONNECT');
      return nomesJson;
    } catch (e) {
      // Se for erro 401 (token expirado), marca como desconectado
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 Token expirado durante listagem, marcando como desconectado');
        _isConnected = false;
        _driveService = null;
      } else {
        print('❌ Erro ao listar arquivos do Drive: $e');
      }
      return [];
    }
  }

  /// Baixa o conteúdo de um arquivo JSON específico
  Future<Map<String, dynamic>?> baixarJson(String nomeArquivo) async {
    if (_driveService == null || !_isConnected) {
      final conectou = await inicializarConexao();
      if (!conectou) return null;
    }

    try {
      final arquivos = await _driveService!.listInRootFolder();
      final arquivo = arquivos.firstWhere(
        (file) => file.name == nomeArquivo,
        orElse: () => drive.File(),
      );

      if (arquivo.id == null) {
        print('! Arquivo não encontrado: $nomeArquivo');
        return null;
      }

      final conteudo = await _driveService!.downloadFileContent(arquivo.id!);
      return json.decode(conteudo) as Map<String, dynamic>;
    } catch (e) {
      // Se for erro 401 (token expirado), marca como desconectado
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 Token expirado para $nomeArquivo, marcando como desconectado');
        _isConnected = false;
        _driveService = null;
      } else {
        print('❌ Erro ao baixar JSON do Drive ($nomeArquivo): $e');
      }
      return null;
    }
  }

  /// Verifica se está conectado ao Drive
  bool get isConectado => _isConnected && _driveService != null;

  /// Desconecta do Drive
  Future<void> desconectar() async {
    _driveService = null;
    _isConnected = false;
    print('🔌 Desconectado do Google Drive TECH CONNECT');
  }
}
