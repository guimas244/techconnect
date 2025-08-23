import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import '../../core/google_drive_client.dart';

class DriveService {
  final drive.DriveApi api;
  String folderId; // Mudou de final para String para permitir alteração

  DriveService(this.api, {String? folderId})
      : folderId = folderId ?? DriveClientFactory.FOLDER_ID;

  /// Método para criar/encontrar a pasta TIPAGENS dentro da pasta principal
  Future<String?> criarPastaTipagens() async {
    try {
      print('📁 [DEBUG] Verificando se pasta TIPAGENS existe dentro da pasta principal...');
      
      // Procurar por pasta TIPAGENS dentro da pasta configurada (FOLDER_ID)
      final res = await api.files.list(
        q: "name = 'tipagens' and mimeType = 'application/vnd.google-apps.folder' and trashed = false and '$folderId' in parents",
        spaces: "drive",
        $fields: "files(id,name)",
        pageSize: 10,
      );
      
      if (res.files != null && res.files!.isNotEmpty) {
        final pastaExistente = res.files!.first;
        print('✅ [DEBUG] Pasta TIPAGENS já existe: ${pastaExistente.id}');
        return pastaExistente.id;
      }
      
      // Se não existe, criar nova pasta TIPAGENS dentro da pasta principal
      print('📁 [DEBUG] Criando pasta TIPAGENS dentro da pasta principal...');
      final meta = drive.File()
        ..name = 'tipagens'
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [folderId]; // Criar dentro da pasta principal
      
      final novaPasta = await api.files.create(meta);
      print('✅ [DEBUG] Pasta TIPAGENS criada: ${novaPasta.id}');
      print('📋 [INFO] Pasta TIPAGENS ID: ${novaPasta.id}');
      
      return novaPasta.id;
    } catch (e) {
      print('❌ [DEBUG] Erro ao criar pasta TIPAGENS: $e');
      return null;
    }
  }

  /// Método para criar/encontrar a pasta HISTORIAS dentro da pasta principal
  Future<String?> criarPastaHistorias() async {
    try {
      print('📁 [DEBUG] Verificando se pasta HISTORIAS existe dentro da pasta principal...');
      
      // Procurar por pasta HISTORIAS dentro da pasta configurada (FOLDER_ID)
      final res = await api.files.list(
        q: "name = 'historias' and mimeType = 'application/vnd.google-apps.folder' and trashed = false and '$folderId' in parents",
        spaces: "drive",
        $fields: "files(id,name)",
        pageSize: 10,
      );
      
      if (res.files != null && res.files!.isNotEmpty) {
        final pastaExistente = res.files!.first;
        print('✅ [DEBUG] Pasta HISTORIAS já existe: ${pastaExistente.id}');
        return pastaExistente.id;
      }
      
      // Se não existe, criar nova pasta HISTORIAS dentro da pasta principal
      print('📁 [DEBUG] Criando pasta HISTORIAS dentro da pasta principal...');
      final meta = drive.File()
        ..name = 'historias'
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [folderId]; // Criar dentro da pasta principal
      
      final novaPasta = await api.files.create(meta);
      print('✅ [DEBUG] Pasta HISTORIAS criada: ${novaPasta.id}');
      print('📋 [INFO] Pasta HISTORIAS ID: ${novaPasta.id}');
      
      return novaPasta.id;
    } catch (e) {
      print('❌ [DEBUG] Erro ao criar pasta HISTORIAS: $e');
      return null;
    }
  }

  /// Método para criar a pasta TECH CONNECT se não existir
  Future<String?> criarPastaTechConnect() async {
    try {
      print('📁 [DEBUG] Verificando se pasta TECH CONNECT existe...');
      
      // Primeiro, procurar por pasta existente
      final res = await api.files.list(
        q: "name = 'TECH CONNECT' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: "drive",
        $fields: "files(id,name)",
        pageSize: 10,
      );
      
      if (res.files != null && res.files!.isNotEmpty) {
        final pastaExistente = res.files!.first;
        print('✅ [DEBUG] Pasta TECH CONNECT já existe: ${pastaExistente.id}');
        return pastaExistente.id;
      }
      
      // Se não existe, criar nova pasta
      print('📁 [DEBUG] Criando pasta TECH CONNECT...');
      final meta = drive.File()
        ..name = 'TECH CONNECT'
        ..mimeType = 'application/vnd.google-apps.folder';
      
      final novaPasta = await api.files.create(meta);
      print('✅ [DEBUG] Pasta TECH CONNECT criada: ${novaPasta.id}');
      print('📋 [INFO] FOLDER_ID para usar no código: ${novaPasta.id}');
      
      return novaPasta.id;
    } catch (e) {
      print('❌ [DEBUG] Erro ao criar pasta TECH CONNECT: $e');
      return null;
    }
  }

  /// Método temporário para listar arquivos na raiz (para debug sem FOLDER_ID)
  Future<List<drive.File>> listInRootFolderDebug() async {
    print('🔍 [DEBUG] DriveService: Listando arquivos na raiz para debug...');
    final res = await api.files.list(
      q: "trashed = false and name contains 'TECH'",
      spaces: "drive", 
      $fields: "files(id,name,mimeType,modifiedTime,size)",
      pageSize: 20,
    );
    print('✅ [DEBUG] DriveService: Encontrados ${res.files?.length ?? 0} arquivos');
    return res.files ?? <drive.File>[];
  }

  /// Lista arquivos na pasta TIPAGENS (onde ficam os arquivos JSON)
  Future<List<drive.File>> listTipagensFolder() async {
    if (folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
      print('⚠️ [DEBUG] FOLDER_ID não configurado, usando listagem debug...');
      return await listInRootFolderDebug();
    }
    
    // Primeiro, encontrar/criar a pasta TIPAGENS
    final pastaTipagensId = await criarPastaTipagens();
    if (pastaTipagensId == null) {
      print('❌ [DEBUG] Não foi possível encontrar pasta TIPAGENS');
      return <drive.File>[];
    }
    
    print('🔍 [DEBUG] DriveService: Listando arquivos na pasta TIPAGENS: $pastaTipagensId');
    final res = await api.files.list(
      q: "'$pastaTipagensId' in parents and trashed = false",
      spaces: "drive",
      $fields: "files(id,name,mimeType,modifiedTime,size)",
      pageSize: 100,
    );
    print('✅ [DEBUG] DriveService: Encontrados ${res.files?.length ?? 0} arquivos na pasta TIPAGENS');
    return res.files ?? <drive.File>[];
  }

  Future<List<drive.File>> listInRootFolder() async {
    // Para compatibilidade, agora lista a pasta TIPAGENS por padrão
    return await listTipagensFolder();
  }

  Future<drive.File> createSubfolder(String name) async {
    final meta = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [folderId];
    return await api.files.create(meta);
  }

  Future<drive.File> createTextFile(String name, String content) async {
    final media = drive.Media(
      http.ByteStream.fromBytes(utf8.encode(content)),
      content.length,
    );
    final meta = drive.File()
      ..name = name
      ..mimeType = 'text/plain'
      ..parents = [folderId];
    return await api.files.create(meta, uploadMedia: media);
  }

  Future<drive.File> createJsonFile(String name, Map<String, dynamic> jsonData) async {
    // Verificar se FOLDER_ID está configurado antes de tentar salvar
    if (folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
      print('⚠️ [DEBUG] FOLDER_ID não configurado, não é possível salvar arquivos');
      throw Exception('FOLDER_ID não configurado. Configure o ID da pasta no Google Drive.');
    }
    
    // Criar/encontrar pasta TIPAGENS
    final pastaTipagensId = await criarPastaTipagens();
    if (pastaTipagensId == null) {
      print('❌ [DEBUG] Não foi possível criar pasta TIPAGENS');
      throw Exception('Falha ao criar pasta TIPAGENS');
    }
    
    final content = const JsonEncoder.withIndent('  ').convert(jsonData);
    final media = drive.Media(
      http.ByteStream.fromBytes(utf8.encode(content)),
      content.length,
    );
    final meta = drive.File()
      ..name = name
      ..mimeType = 'application/json'
      ..parents = [pastaTipagensId]; // Usar pasta TIPAGENS ao invés da pasta principal
    
    print('💾 [DEBUG] Criando arquivo JSON na pasta TIPAGENS: $name');
    return await api.files.create(meta, uploadMedia: media);
  }

  Future<drive.File> createJsonFileInHistorias(String name, Map<String, dynamic> jsonData) async {
    // Verificar se FOLDER_ID está configurado antes de tentar salvar
    if (folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
      print('⚠️ [DEBUG] FOLDER_ID não configurado, não é possível salvar arquivos');
      throw Exception('FOLDER_ID não configurado. Configure o ID da pasta no Google Drive.');
    }
    
    // Criar/encontrar pasta HISTORIAS
    final pastaHistoriasId = await criarPastaHistorias();
    if (pastaHistoriasId == null) {
      print('❌ [DEBUG] Não foi possível criar pasta HISTORIAS');
      throw Exception('Falha ao criar pasta HISTORIAS');
    }
    
    // Verificar se arquivo já existe
    print('🔍 [DEBUG] Verificando se arquivo já existe: $name');
    final arquivosExistentes = await listInHistoriasFolder();
    final arquivoExistente = arquivosExistentes.where((file) => file.name == name).firstOrNull;
    
    if (arquivoExistente != null && arquivoExistente.id != null) {
      print('🔄 [DEBUG] Arquivo já existe, atualizando: $name (ID: ${arquivoExistente.id})');
      return await updateJsonFileInHistorias(arquivoExistente.id!, jsonData);
    }
    
    print('💾 [DEBUG] Criando novo arquivo JSON na pasta HISTORIAS: $name');
    final content = const JsonEncoder.withIndent('  ').convert(jsonData);
    final media = drive.Media(
      http.ByteStream.fromBytes(utf8.encode(content)),
      content.length,
    );
    final meta = drive.File()
      ..name = name
      ..mimeType = 'application/json'
      ..parents = [pastaHistoriasId]; // Usar pasta HISTORIAS
    
    return await api.files.create(meta, uploadMedia: media);
  }

  Future<drive.File> updateJsonFileInHistorias(String fileId, Map<String, dynamic> jsonData) async {
    print('� [DEBUG] Atualizando arquivo JSON na pasta HISTORIAS (ID: $fileId)');
    
    final content = const JsonEncoder.withIndent('  ').convert(jsonData);
    final media = drive.Media(
      http.ByteStream.fromBytes(utf8.encode(content)),
      content.length,
    );
    final meta = drive.File();
    return await api.files.update(meta, fileId, uploadMedia: media);
  }

  Future<drive.File> updateJsonFile(String fileId, Map<String, dynamic> jsonData) async {
    // Verificar se FOLDER_ID está configurado antes de tentar atualizar
    if (folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
      print('⚠️ [DEBUG] FOLDER_ID não configurado, não é possível atualizar arquivos');
      throw Exception('FOLDER_ID não configurado. Configure o ID da pasta no Google Drive.');
    }
    
    // Para atualizações, também usar pasta TIPAGENS
    final pastaTipagensId = await criarPastaTipagens();
    if (pastaTipagensId == null) {
      print('❌ [DEBUG] Não foi possível encontrar pasta TIPAGENS');
      throw Exception('Falha ao encontrar pasta TIPAGENS');
    }
    
    final content = const JsonEncoder.withIndent('  ').convert(jsonData);
    final media = drive.Media(
      http.ByteStream.fromBytes(utf8.encode(content)),
      content.length,
    );
    final meta = drive.File();
    return await api.files.update(meta, fileId, uploadMedia: media);
  }

  Future<String> downloadFileContent(String fileId) async {
    final response = await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  /// Lista arquivos na pasta TIPAGENS
  Future<List<drive.File>> listInTipagensFolder() async {
    final pastaTipagensId = await criarPastaTipagens();
    if (pastaTipagensId == null) {
      print('❌ [DEBUG] Não foi possível acessar pasta TIPAGENS');
      return [];
    }

    final res = await api.files.list(
      q: "trashed = false and '$pastaTipagensId' in parents",
      spaces: "drive",
      $fields: "files(id,name,mimeType,modifiedTime)",
      pageSize: 100,
    );

    return res.files ?? [];
  }

  /// Lista arquivos na pasta HISTORIAS
  Future<List<drive.File>> listInHistoriasFolder() async {
    final pastaHistoriasId = await criarPastaHistorias();
    if (pastaHistoriasId == null) {
      print('❌ [DEBUG] Não foi possível acessar pasta HISTORIAS');
      return [];
    }

    final res = await api.files.list(
      q: "trashed = false and '$pastaHistoriasId' in parents",
      spaces: "drive",
      $fields: "files(id,name,mimeType,modifiedTime)",
      pageSize: 100,
    );

    return res.files ?? [];
  }
}
