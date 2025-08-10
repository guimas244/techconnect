import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  drive.DriveApi? _driveApi;

  // Pasta onde ficam os JSONs no Drive
  static const String _folderName = 'TechConnect_Tipagens';
  String? _folderId;

  /// Inicializa conexão com Google Drive
  Future<bool> inicializarConexao() async {
    try {
      print('🔐 Iniciando autenticação Google Drive...');
      
      const List<String> scopes = [
        drive.DriveApi.driveFileScope,
        drive.DriveApi.driveScope,
      ];

      // Inicializar GoogleSignIn se necessário
      await GoogleSignIn.instance.initialize();

      // Tentar autenticação leve primeiro
      await GoogleSignIn.instance.attemptLightweightAuthentication();

      // Verificar se já está logado
      GoogleSignInAccount? account = GoogleSignIn.instance.currentUser;
      
      if (account == null) {
        // Se não estiver logado, fazer login completo
        if (GoogleSignIn.instance.supportsAuthenticate()) {
          await GoogleSignIn.instance.authenticate();
          account = GoogleSignIn.instance.currentUser;
        } else {
          print('❌ Autenticação não suportada nesta plataforma');
          return false;
        }
      }

      if (account == null) {
        print('❌ Login cancelado pelo usuário');
        return false;
      }

      // Verificar se tem as permissões necessárias
      final authorization = await account.authorizationClient.authorizationForScopes(scopes);
      
      if (authorization == null) {
        // Solicitar permissões
        final newAuth = await account.authorizationClient.authorizeScopes(scopes);
        if (newAuth.accessToken == null) {
          print('❌ Permissões negadas pelo usuário');
          return false;
        }
      }

      // Obter o token de acesso atual
      final currentAuth = await account.authorizationClient.authorizationForScopes(scopes);
      if (currentAuth?.accessToken == null) {
        print('❌ Não foi possível obter token de acesso');
        return false;
      }

      // Criar as credenciais
      final credentials = AccessCredentials(
        AccessToken(
          'Bearer', 
          currentAuth!.accessToken!, 
          DateTime.now().add(const Duration(hours: 1))
        ),
        null, // refreshToken não necessário para este caso
        scopes,
      );

      final client = authenticatedClient(http.Client(), credentials);
      _driveApi = drive.DriveApi(client);

      await _criarPastaTipagens();
      
      print('✅ Google Drive conectado com sucesso!');
      return true;
    } catch (e) {
      print('❌ Erro ao conectar Google Drive: $e');
      return false;
    }
  }

  /// Cria a pasta TechConnect_Tipagens no Drive
  Future<void> _criarPastaTipagens() async {
    if (_driveApi == null) return;

    try {
      // Procura se a pasta já existe
      final query = "name='$_folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final folderList = await _driveApi!.files.list(q: query);

      if (folderList.files?.isNotEmpty == true) {
        // Pasta já existe
        _folderId = folderList.files!.first.id;
        print('📁 Pasta $_folderName encontrada: $_folderId');
      } else {
        // Criar nova pasta
        final folder = drive.File();
        folder.name = _folderName;
        folder.mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _folderId = createdFolder.id;
        print('📁 Pasta $_folderName criada: $_folderId');
      }
    } catch (e) {
      print('❌ Erro ao criar pasta no Drive: $e');
      throw Exception('Erro ao criar pasta: $e');
    }
  }

  /// Salva um arquivo JSON no Drive
  Future<bool> salvarJson(String tipoNome, Map<String, dynamic> jsonData) async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('Drive não inicializado');
    }

    try {
      final nomeArquivo = 'tb_${tipoNome}_defesa.json';
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(jsonData);
      
      print('💾 Salvando arquivo no Drive: $nomeArquivo');

      // Verifica se arquivo já existe
      final query = "name='$nomeArquivo' and parents in '$_folderId' and trashed=false";
      final fileList = await _driveApi!.files.list(q: query);

      final media = drive.Media(
        Stream.value(utf8.encode(jsonString)),
        utf8.encode(jsonString).length,
        contentType: 'application/json',
      );

      if (fileList.files?.isNotEmpty == true) {
        // Atualiza arquivo existente
        final fileId = fileList.files!.first.id!;
        await _driveApi!.files.update(drive.File(), fileId, uploadMedia: media);
        print('✅ Arquivo atualizado no Drive: $nomeArquivo');
      } else {
        // Cria novo arquivo
        final file = drive.File();
        file.name = nomeArquivo;
        file.parents = [_folderId!];
        
        await _driveApi!.files.create(file, uploadMedia: media);
        print('✅ Arquivo criado no Drive: $nomeArquivo');
      }
      
      return true;
    } catch (e) {
      print('❌ Erro ao salvar JSON no Drive: $e');
      return false;
    }
  }

  /// Sincroniza todos os JSONs para o Drive
  Future<bool> sincronizarTodosJsons(Map<String, Map<String, dynamic>> jsonsData) async {
    if (_driveApi == null) return false;

    try {
      print('🔄 Iniciando sincronização de ${jsonsData.length} arquivos...');
      
      int sucessos = 0;
      for (final entry in jsonsData.entries) {
        final sucesso = await salvarJson(entry.key, entry.value);
        if (sucesso) sucessos++;
      }
      
      print('✅ Sincronização concluída: $sucessos/${jsonsData.length} arquivos');
      return sucessos == jsonsData.length;
    } catch (e) {
      print('❌ Erro na sincronização: $e');
      return false;
    }
  }

  /// Lista todos os arquivos JSON na pasta do Drive
  Future<List<String>> listarArquivosDrive() async {
    if (_driveApi == null || _folderId == null) return [];

    try {
      final query = "parents in '$_folderId' and name contains '.json' and trashed=false";
      final fileList = await _driveApi!.files.list(q: query);
      
      return fileList.files?.map((file) => file.name ?? '').where((name) => name.isNotEmpty).toList() ?? [];
    } catch (e) {
      print('❌ Erro ao listar arquivos do Drive: $e');
      return [];
    }
  }

  /// Verifica se está conectado ao Drive
  bool get isConectado => _driveApi != null && _folderId != null;

  /// Desconecta do Drive
  Future<void> desconectar() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
    _driveApi = null;
    _folderId = null;
    _googleSignIn = null;
    print('🔌 Desconectado do Google Drive');
  }
}
