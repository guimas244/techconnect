import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/user_provider.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class DriveClientFactory {
  static const String FOLDER_ID = "1R_WQTo21NNQyZIj3rMPaaUKj1-eGJPfV";
  static const String CLIENT_ID = "163239542287-3c3rq1k6j9k1s5fmfauvo2p6q157nbpq.apps.googleusercontent.com";

  static final List<String> scopes = [
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveReadonlyScope,
  ];

  /// Método temporário para desenvolvimento - sem OAuth
  static Future<drive.DriveApi> createDebug() async {
    print('🔐 [DEBUG] DriveClientFactory: Modo DEBUG - Sem autenticação real');
    throw Exception('Modo DEBUG: Configure o SHA-1 no Google Cloud Console primeiro');
  }

  static Future<drive.DriveApi> create({ProviderContainer? container, bool forceReauth = false}) async {
    print('🔐 [DEBUG] DriveClientFactory: Iniciando GoogleSignIn...');
    
    try {
      final gs = GoogleSignIn(
        scopes: scopes,
        // Remover clientId/serverClientId no Android - deixar só os scopes
        // serverClientId: CLIENT_ID, 
      );
      print('🔐 [DEBUG] DriveClientFactory: GoogleSignIn criado com scopes: $scopes');
      print('🔐 [DEBUG] DriveClientFactory: Usando configuração do google-services.json');
      
      print('🔐 [DEBUG] DriveClientFactory: Verificando usuário atual...');
      var account = await gs.signInSilently();
      
      // Se forçar reautenticação ou se não há conta logada
      if (forceReauth || account == null) {
        if (forceReauth && account != null) {
          print('🔐 [DEBUG] DriveClientFactory: Forçando logout antes da reautenticação...');
          await gs.signOut();
        }
        
        print('🔐 [DEBUG] DriveClientFactory: ${forceReauth ? 'Reautenticação forçada' : 'Nenhum usuário logado'}, iniciando login interativo...');
        account = await gs.signIn();
        
        if (account == null) {
          print('❌ [DEBUG] DriveClientFactory: Login cancelado pelo usuário');
          throw Exception("Login cancelado pelo usuário");
        }
      }
      
      print('✅ [DEBUG] DriveClientFactory: Usuário logado: ${account.email}');
      
      // Define o email no provider global para ser usado pela aplicação
      if (container != null) {
        print('📧 [DEBUG] DriveClientFactory: Definindo email no provider: ${account.email}');
        container.read(currentUserEmailStateProvider.notifier).state = account.email;
      }
      
      print('🔐 [DEBUG] DriveClientFactory: Obtendo headers de autenticação...');
      
      final headers = await account.authHeaders;
      print('✅ [DEBUG] DriveClientFactory: Headers obtidos: ${headers.keys.toList()}');
      
      print('🔐 [DEBUG] DriveClientFactory: Criando DriveApi...');
      final driveApi = drive.DriveApi(GoogleAuthClient(headers));
      print('✅ [DEBUG] DriveClientFactory: DriveApi criado com sucesso');
      
      return driveApi;
    } catch (e) {
      print('❌ [DEBUG] Erro na autenticação: $e');
      print('❌ [DEBUG] SOLUÇÃO: Configure o SHA-1 fingerprint no Google Cloud Console');
      print('❌ [DEBUG] SHA-1 PC ANTIGO: EE:9D:36:26:2A:AE:45:A8:00:71:22:39:A0:E1:C5:6D:39:1F:3F:1F');
      print('❌ [DEBUG] SHA-1 PC NOVO: 88:36:4B:F1:C8:D9:75:2E:C2:B5:4B:98:51:5F:BC:E0:7F:DC:DD:25');
      print('❌ [DEBUG] Package: com.example.techconnect');
      rethrow;
    }
  }

  /// Cria um cliente HTTP autenticado para outras APIs (como Sheets)
  static Future<http.Client> createHttpClient({ProviderContainer? container}) async {
    print('🔐 [DEBUG] DriveClientFactory: Criando cliente HTTP para Sheets...');
    
    try {
      final gs = GoogleSignIn(
        scopes: scopes,
      );
      
      GoogleSignInAccount? account = await gs.signInSilently();
      if (account == null) {
        print('🔐 [DEBUG] Login necessário para cliente HTTP...');
        account = await gs.signIn();
        
        if (account == null) {
          print('❌ [DEBUG] Login cancelado pelo usuário');
          throw Exception("Login cancelado pelo usuário");
        }
      }
      
      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      
      print('✅ [DEBUG] Cliente HTTP autenticado criado com sucesso');
      return client;
    } catch (e) {
      print('❌ [DEBUG] Erro ao criar cliente HTTP: $e');
      rethrow;
    }
  }
}

/// Extensão para adicionar métodos relacionados a mochila e coleção
extension DriveClientMochilaExtension on drive.DriveApi {
  /// Atualiza ou cria arquivo JSON na pasta "mochila"
  Future<String> updateOrCreateJsonFileInMochila(String fileName, Map<String, dynamic> jsonData) async {
    print('📦 [MochilaExtension] Iniciando updateOrCreate para: $fileName');

    try {
      // Busca ou cria a pasta "mochila" dentro de TECHTERRA
      final folderId = await _getOrCreateFolder('mochila', DriveClientFactory.FOLDER_ID);
      print('📁 [MochilaExtension] Pasta mochila ID: $folderId');

      // Busca arquivo existente
      print('🔍 [MochilaExtension] Buscando arquivo existente: $fileName');
      final query = "name='$fileName' and '$folderId' in parents and trashed=false";
      final fileList = await files.list(q: query, spaces: 'drive');

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Arquivo existe - ATUALIZA
        final fileId = fileList.files!.first.id!;
        print('🔄 [MochilaExtension] Arquivo encontrado! Atualizando ID: $fileId');

        final media = drive.Media(
          Stream.value(utf8.encode(json.encode(jsonData))),
          utf8.encode(json.encode(jsonData)).length,
        );

        final fileMetadata = drive.File()..mimeType = 'application/json';

        await files.update(
          fileMetadata,
          fileId,
          uploadMedia: media,
        );

        print('✅ [MochilaExtension] Arquivo ATUALIZADO com sucesso: $fileName');
        return fileId;
      } else {
        // Arquivo não existe - CRIA
        print('📝 [MochilaExtension] Arquivo não encontrado. Criando novo...');

        final media = drive.Media(
          Stream.value(utf8.encode(json.encode(jsonData))),
          utf8.encode(json.encode(jsonData)).length,
        );

        final fileMetadata = drive.File()
          ..name = fileName
          ..parents = [folderId]
          ..mimeType = 'application/json';

        final file = await files.create(
          fileMetadata,
          uploadMedia: media,
        );

        print('✅ [MochilaExtension] Arquivo CRIADO com sucesso: $fileName (ID: ${file.id})');
        return file.id!;
      }
    } catch (e, stack) {
      print('❌ [MochilaExtension] Erro ao atualizar/criar arquivo: $e');
      print(stack);
      rethrow;
    }
  }

  /// Cria ou atualiza arquivo JSON na pasta "colecao"
  Future<String> createJsonFileInColecao(String fileName, Map<String, dynamic> jsonData) async {
    print('🎨 [ColecaoExtension] Criando arquivo em coleção: $fileName');

    try {
      final folderId = await _getOrCreateFolder('colecao', DriveClientFactory.FOLDER_ID);

      final media = drive.Media(
        Stream.value(utf8.encode(json.encode(jsonData))),
        utf8.encode(json.encode(jsonData)).length,
      );

      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = 'application/json';

      final file = await files.create(
        fileMetadata,
        uploadMedia: media,
      );

      print('✅ [ColecaoExtension] Arquivo criado: $fileName (ID: ${file.id})');
      return file.id!;
    } catch (e) {
      print('❌ [ColecaoExtension] Erro ao criar arquivo: $e');
      rethrow;
    }
  }

  /// Lista arquivos na pasta "mochila"
  Future<List<drive.File>> listFilesInMochila() async {
    print('📋 [MochilaExtension] Listando arquivos na pasta mochila');

    try {
      // Busca ou cria a pasta "mochila"
      final folderId = await _getOrCreateFolder('mochila', DriveClientFactory.FOLDER_ID);
      print('📁 [MochilaExtension] Pasta mochila ID: $folderId');

      // Lista arquivos na pasta
      final query = "'$folderId' in parents and trashed=false";
      final fileList = await files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id,name,mimeType,modifiedTime)',
        pageSize: 100,
      );

      final arquivos = fileList.files ?? [];
      print('✅ [MochilaExtension] Encontrados ${arquivos.length} arquivos na pasta mochila');

      for (final arquivo in arquivos) {
        print('   - ${arquivo.name} (ID: ${arquivo.id})');
      }

      return arquivos;
    } catch (e) {
      print('❌ [MochilaExtension] Erro ao listar arquivos: $e');
      return [];
    }
  }

  /// Busca ou cria uma pasta dentro de um pai
  Future<String> _getOrCreateFolder(String folderName, String parentId) async {
    // Busca pasta existente
    final query = "name='$folderName' and '$parentId' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false";
    final folderList = await files.list(q: query, spaces: 'drive');

    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id!;
    }

    // Cria pasta
    final folderMetadata = drive.File()
      ..name = folderName
      ..parents = [parentId]
      ..mimeType = 'application/vnd.google-apps.folder';

    final folder = await files.create(folderMetadata);
    print('📁 Pasta criada: $folderName (ID: ${folder.id})');
    return folder.id!;
  }
}
