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
      // Se for erro de autenticação, relança para o GoogleDriveService tratar
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        print('🔒 [DEBUG] Erro de autenticação detectado em criarPastaTipagens, repassando...');
        rethrow; // Relança para o GoogleDriveService capturar
      }
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
      // Se for erro de autenticação, relança para o GoogleDriveService tratar
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        print('🔒 [DEBUG] Erro de autenticação detectado em criarPastaHistorias, repassando...');
        rethrow; // Relança para o GoogleDriveService capturar
      }
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
      // Se for erro de autenticação, relança para o GoogleDriveService tratar
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        print('🔒 [DEBUG] Erro de autenticação detectado em criarPastaTechConnect, repassando...');
        rethrow; // Relança para o GoogleDriveService capturar
      }
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
    final contentBytes = utf8.encode(content);
    final media = drive.Media(
      http.ByteStream.fromBytes(contentBytes),
      contentBytes.length,
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
    final contentBytes = utf8.encode(content);
    final media = drive.Media(
      http.ByteStream.fromBytes(contentBytes),
      contentBytes.length,
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
      print('🔄 [HISTORIAS-LOG] Arquivo já existe, tentando atualizar: $name (ID: ${arquivoExistente.id})');
      try {
        final result = await updateJsonFileInHistorias(arquivoExistente.id!, jsonData);
        print('✅ [HISTORIAS-LOG] Arquivo atualizado com sucesso na pasta HISTORIAS: $name');
        return result;
      } catch (e) {
        print('❌ [HISTORIAS-LOG] ERRO ao atualizar arquivo: $e');
        print('🔍 [HISTORIAS-LOG] Tipo do erro: ${e.runtimeType}');
        print('🔍 [HISTORIAS-LOG] Conteúdo completo do erro: ${e.toString()}');
        
        // Verificar se é erro 403 especificamente
        if (e.toString().contains('403')) {
          print('🚨 [HISTORIAS-LOG] ERRO 403 DETECTADO - Sem permissão para alterar arquivo');
        }
        
        rethrow;
      }
    }
    
    print('💾 [DEBUG] Criando novo arquivo JSON na pasta HISTORIAS: $name');
    final content = const JsonEncoder.withIndent('  ').convert(jsonData);
    final contentBytes = utf8.encode(content);
    final media = drive.Media(
      http.ByteStream.fromBytes(contentBytes),
      contentBytes.length,
    );
    final meta = drive.File()
      ..name = name
      ..mimeType = 'application/json'
      ..parents = [pastaHistoriasId]; // Usar pasta HISTORIAS
    
    return await api.files.create(meta, uploadMedia: media);
  }

  Future<drive.File> updateJsonFileInHistorias(String fileId, Map<String, dynamic> jsonData) async {
    print('🔄 [HISTORIAS-LOG] Atualizando arquivo JSON na pasta HISTORIAS (ID: $fileId)');
    
    try {
      final content = const JsonEncoder.withIndent('  ').convert(jsonData);
      final contentBytes = utf8.encode(content);
      final media = drive.Media(
        http.ByteStream.fromBytes(contentBytes),
        contentBytes.length,
      );
      final meta = drive.File();
      
      print('📡 [HISTORIAS-LOG] Enviando requisição de atualização para o Drive...');
      final result = await api.files.update(meta, fileId, uploadMedia: media);
      print('✅ [HISTORIAS-LOG] Requisição de atualização concluída com sucesso');
      return result;
    } catch (e) {
      print('❌ [HISTORIAS-LOG] ERRO na requisição de atualização: $e');
      print('🔍 [HISTORIAS-LOG] Tipo do erro na atualização: ${e.runtimeType}');
      rethrow;
    }
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
    final contentBytes = utf8.encode(content);
    final media = drive.Media(
      http.ByteStream.fromBytes(contentBytes),
      contentBytes.length,
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

  /// Cria a pasta DROPS se não existir e retorna seu ID
  Future<String?> criarPastaDrops() async {
    try {
      // Primeiro verifica se a pasta já existe
      final res = await api.files.list(
        q: "trashed = false and mimeType = 'application/vnd.google-apps.folder' and name = 'DROPS' and '$folderId' in parents",
        spaces: "drive",
        $fields: "files(id,name)",
      );

      if (res.files != null && res.files!.isNotEmpty) {
        final pastaDropsId = res.files!.first.id!;
        print('✅ [DEBUG] Pasta DROPS encontrada: $pastaDropsId');
        return pastaDropsId;
      }

      // Se não existe, cria a pasta
      print('📁 [DEBUG] Criando pasta DROPS...');
      final folder = drive.File();
      folder.name = 'DROPS';
      folder.mimeType = 'application/vnd.google-apps.folder';
      folder.parents = [folderId];

      final driveFolder = await api.files.create(folder);
      print('✅ [DEBUG] Pasta DROPS criada com ID: ${driveFolder.id}');
      return driveFolder.id;
    } catch (e) {
      print('❌ [DEBUG] Erro ao criar pasta DROPS: $e');
      // Se for erro de autenticação, relança para o GoogleDriveService tratar
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        print('🔒 [DEBUG] Erro de autenticação detectado em criarPastaDrops, repassando...');
        rethrow; // Relança para o GoogleDriveService capturar
      }
      return null;
    }
  }

  /// Lista arquivos na pasta DROPS
  Future<List<drive.File>> listInDropsFolder() async {
    final pastaDropsId = await criarPastaDrops();
    if (pastaDropsId == null) {
      print('❌ [DEBUG] Não foi possível acessar pasta DROPS');
      return [];
    }

    final res = await api.files.list(
      q: "trashed = false and '$pastaDropsId' in parents",
      spaces: "drive",
      $fields: "files(id,name,mimeType,modifiedTime)",
      pageSize: 100,
    );

    return res.files ?? [];
  }

  /// Cria ou atualiza arquivo JSON na pasta DROPS
  Future<void> createJsonFileInDrops(String filename, Map<String, dynamic> jsonData) async {
    final pastaDropsId = await criarPastaDrops();
    if (pastaDropsId == null) {
      throw Exception('Não foi possível acessar pasta DROPS');
    }

    // Verificar se arquivo já existe na pasta DROPS
    final arquivosDrops = await listInDropsFolder();
    final arquivoExistente = arquivosDrops.firstWhere(
      (file) => file.name == filename,
      orElse: () => drive.File(),
    );

    if (arquivoExistente.id != null) {
      // Atualizar arquivo existente
      await updateJsonFile(arquivoExistente.id!, jsonData);
      print('✅ [DriveService] Arquivo atualizado na pasta DROPS: $filename');
    } else {
      // Criar novo arquivo na pasta DROPS
      final file = drive.File();
      file.name = filename;
      file.parents = [pastaDropsId];

      final jsonString = json.encode(jsonData);
      final jsonBytes = utf8.encode(jsonString);
      final media = drive.Media(
        Stream.fromIterable([jsonBytes]),
        jsonBytes.length,
        contentType: 'application/json',
      );

      await api.files.create(file, uploadMedia: media);
      print('✅ [DriveService] Arquivo criado na pasta DROPS: $filename');
    }
  }

  /// Cria a pasta RANKING se não existir e retorna seu ID
  Future<String?> criarPastaRanking() async {
    try {
      // Primeiro verifica se a pasta já existe
      final res = await api.files.list(
        q: "trashed = false and mimeType = 'application/vnd.google-apps.folder' and name = 'rankings' and '$folderId' in parents",
        spaces: "drive",
        $fields: "files(id,name)",
      );

      if (res.files != null && res.files!.isNotEmpty) {
        final pastaRankingId = res.files!.first.id!;
        print('✅ [DEBUG] Pasta RANKING encontrada: $pastaRankingId');
        return pastaRankingId;
      }

      // Se não existe, cria a pasta
      print('📁 [DEBUG] Criando pasta RANKING...');
      final folder = drive.File();
      folder.name = 'rankings';
      folder.mimeType = 'application/vnd.google-apps.folder';
      folder.parents = [folderId];

      final driveFolder = await api.files.create(folder);
      print('✅ [DEBUG] Pasta RANKING criada com ID: ${driveFolder.id}');
      return driveFolder.id;
    } catch (e) {
      print('❌ [DEBUG] Erro ao criar pasta RANKING: $e');
      // Se for erro de autenticação, relança para o GoogleDriveService tratar
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        print('🔒 [DEBUG] Erro de autenticação detectado em criarPastaRanking, repassando...');
        rethrow; // Relança para o GoogleDriveService capturar
      }
      return null;
    }
  }

  /// Lista arquivos na pasta RANKING
  Future<List<drive.File>> listInRankingFolder() async {
    final pastaRankingId = await criarPastaRanking();
    if (pastaRankingId == null) {
      print('❌ [DEBUG] Não foi possível acessar pasta RANKING');
      return [];
    }

    final res = await api.files.list(
      q: "trashed = false and '$pastaRankingId' in parents",
      spaces: "drive",
      $fields: "files(id,name,mimeType,modifiedTime)",
      pageSize: 100,
    );

    return res.files ?? [];
  }

  /// Cria ou atualiza arquivo JSON na pasta RANKING
  Future<void> createJsonFileInRanking(String filename, Map<String, dynamic> jsonData) async {
    final pastaRankingId = await criarPastaRanking();
    if (pastaRankingId == null) {
      throw Exception('Não foi possível acessar pasta RANKING');
    }

    // Verificar se arquivo já existe na pasta RANKING
    final arquivosRanking = await listInRankingFolder();
    final arquivoExistente = arquivosRanking.firstWhere(
      (file) => file.name == filename,
      orElse: () => drive.File(),
    );

    if (arquivoExistente.id != null) {
      // Tentar atualizar arquivo existente
      try {
        await updateJsonFileInRanking(arquivoExistente.id!, jsonData);
        print('✅ [DriveService] Arquivo atualizado na pasta RANKING: $filename');
        return; // Sucesso, não precisa criar novo
      } catch (e) {
        print('⚠️ [DriveService] Erro ao atualizar arquivo (sem permissão): $e');
        print('🔄 [DriveService] Criando novo arquivo ao invés de atualizar...');
        // Modifica o nome do arquivo para evitar conflito
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filename = '${filename.replaceAll('.json', '')}_$timestamp.json';
        print('📝 [DriveService] Novo nome de arquivo: $filename');
        // Continua para criar novo arquivo abaixo
      }
    }
    
    // Criar novo arquivo na pasta RANKING (ou quando falha ao atualizar)
    final file = drive.File();
    file.name = filename;
    file.parents = [pastaRankingId];

    final jsonString = json.encode(jsonData);
    final jsonBytes = utf8.encode(jsonString);
    final media = drive.Media(
      Stream.fromIterable([jsonBytes]),
      jsonBytes.length,
      contentType: 'application/json',
    );

    await api.files.create(file, uploadMedia: media);
    print('✅ [DriveService] Novo arquivo criado na pasta RANKING: $filename');
  }

  /// Cria arquivo JSON na pasta RANKING com subpasta por data
  Future<void> createJsonFileInRankingWithDate(String filename, Map<String, dynamic> jsonData, String dateStr) async {
    final pastaRankingId = await criarPastaRanking();
    if (pastaRankingId == null) {
      throw Exception('Não foi possível acessar pasta RANKING');
    }

    // Criar ou encontrar subpasta por data
    final subpastaId = await _criarOuEncontrarSubpasta(pastaRankingId, dateStr);
    if (subpastaId == null) {
      throw Exception('Não foi possível criar/acessar subpasta para data: $dateStr');
    }

    // Verificar se arquivo já existe na subpasta
    final arquivosSubpasta = await _listFilesInFolder(subpastaId);
    final arquivoExistente = arquivosSubpasta.firstWhere(
      (file) => file.name == filename,
      orElse: () => drive.File(),
    );

    if (arquivoExistente.id != null) {
      // Tentar atualizar arquivo existente
      try {
        await _updateJsonFile(arquivoExistente.id!, jsonData);
        print('✅ [DriveService] Arquivo atualizado na subpasta $dateStr: $filename');
        return; // Sucesso, não precisa criar novo
      } catch (e) {
        print('⚠️ [DriveService] Erro ao atualizar arquivo na subpasta: $e');
        print('🔄 [DriveService] Criando novo arquivo na subpasta...');
        // Modifica o nome do arquivo para evitar conflito
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filename = '${filename.replaceAll('.json', '')}_$timestamp.json';
        print('📝 [DriveService] Novo nome de arquivo: $filename');
      }
    }
    
    // Criar novo arquivo na subpasta
    final file = drive.File();
    file.name = filename;
    file.parents = [subpastaId];

    final jsonString = json.encode(jsonData);
    final jsonBytes = utf8.encode(jsonString);
    final media = drive.Media(
      Stream.fromIterable([jsonBytes]),
      jsonBytes.length,
      contentType: 'application/json',
    );

    await api.files.create(file, uploadMedia: media);
    print('✅ [DriveService] Novo arquivo criado na subpasta $dateStr: $filename');
  }

  /// Atualiza arquivo JSON na pasta RANKING
  Future<drive.File> updateJsonFileInRanking(String fileId, Map<String, dynamic> jsonData) async {
    print('🔄 [DEBUG] Atualizando arquivo JSON na pasta RANKING (ID: $fileId)');
    
    final content = const JsonEncoder.withIndent('  ').convert(jsonData);
    final contentBytes = utf8.encode(content);
    final media = drive.Media(
      http.ByteStream.fromBytes(contentBytes),
      contentBytes.length,
    );
    final meta = drive.File();
    return await api.files.update(meta, fileId, uploadMedia: media);
  }

  /// Baixa um arquivo específico da pasta RANKING
  /// Cria ou encontra uma subpasta dentro da pasta pai
  Future<String?> _criarOuEncontrarSubpasta(String pastaParentId, String nomeSubpasta) async {
    try {
      print('📁 [DEBUG] Criando/encontrando subpasta: $nomeSubpasta dentro de $pastaParentId');

      // Lista subpastas existentes
      final response = await api.files.list(
        q: "parents in '$pastaParentId' and mimeType='application/vnd.google-apps.folder' and name='$nomeSubpasta'",
        $fields: 'files(id, name)',
      );

      if (response.files?.isNotEmpty == true) {
        final subpastaId = response.files!.first.id!;
        print('✅ [DEBUG] Subpasta encontrada: $nomeSubpasta (ID: $subpastaId)');
        return subpastaId;
      }

      // Criar nova subpasta
      final folder = drive.File();
      folder.name = nomeSubpasta;
      folder.parents = [pastaParentId];
      folder.mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await api.files.create(folder);
      final subpastaId = createdFolder.id!;
      print('✅ [DEBUG] Subpasta criada: $nomeSubpasta (ID: $subpastaId)');
      return subpastaId;

    } catch (e) {
      print('❌ [DEBUG] Erro ao criar/encontrar subpasta $nomeSubpasta: $e');
      return null;
    }
  }

  /// Lista arquivos em uma pasta específica
  Future<List<drive.File>> _listFilesInFolder(String folderId) async {
    try {
      final response = await api.files.list(
        q: "parents in '$folderId'",
        $fields: 'files(id, name, createdTime)',
      );
      return response.files ?? [];
    } catch (e) {
      print('❌ [DEBUG] Erro ao listar arquivos na pasta $folderId: $e');
      return [];
    }
  }

  /// Atualiza um arquivo JSON genérico
  Future<void> _updateJsonFile(String fileId, Map<String, dynamic> jsonData) async {
    print('🔄 [HISTORIAS-LOG] _updateJsonFile chamado para ID: $fileId');
    
    try {
      final content = const JsonEncoder.withIndent('  ').convert(jsonData);
      final contentBytes = utf8.encode(content);
      final media = drive.Media(
        Stream.fromIterable([contentBytes]),
        contentBytes.length,
        contentType: 'application/json',
      );

      print('📡 [HISTORIAS-LOG] Enviando requisição _updateJsonFile para o Drive...');
      await api.files.update(drive.File(), fileId, uploadMedia: media);
      print('✅ [HISTORIAS-LOG] _updateJsonFile concluído com sucesso');
    } catch (e) {
      print('❌ [HISTORIAS-LOG] ERRO em _updateJsonFile: $e');
      print('🔍 [HISTORIAS-LOG] Tipo do erro em _updateJsonFile: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Lista arquivos na pasta RANKING por data específica
  Future<List<drive.File>> listInRankingFolderByDate(String dateStr) async {
    try {
      final pastaRankingId = await criarPastaRanking();
      if (pastaRankingId == null) {
        print('❌ [DEBUG] Não foi possível acessar pasta RANKING');
        return [];
      }

      // Encontra a subpasta da data
      final subpastaId = await _criarOuEncontrarSubpasta(pastaRankingId, dateStr);
      if (subpastaId == null) {
        print('❌ [DEBUG] Não foi possível acessar subpasta para data: $dateStr');
        return [];
      }

      // Lista arquivos na subpasta
      return await _listFilesInFolder(subpastaId);
    } catch (e) {
      print('❌ [DEBUG] Erro ao listar arquivos na subpasta $dateStr: $e');
      return [];
    }
  }

  /// Lista arquivos na pasta HISTORIAS por caminho específico (data/jogador)
  Future<List<drive.File>> listInHistoriasFolderByPath(String path) async {
    try {
      final pastaHistoriasId = await criarPastaHistorias();
      if (pastaHistoriasId == null) {
        print('❌ [DEBUG] Não foi possível acessar pasta HISTORIAS');
        return [];
      }

      // Divide o caminho (ex: "2025-09-04/jogador1@gmail.com")
      final partes = path.split('/');
      String pastaAtualId = pastaHistoriasId;

      // Navega através do caminho
      for (final parte in partes) {
        final subpastaId = await _criarOuEncontrarSubpasta(pastaAtualId, parte);
        if (subpastaId == null) {
          print('❌ [DEBUG] Não foi possível acessar subpasta: $parte');
          return [];
        }
        pastaAtualId = subpastaId;
      }

      // Lista arquivos na pasta final
      return await _listFilesInFolder(pastaAtualId);
    } catch (e) {
      print('❌ [DEBUG] Erro ao listar arquivos no caminho $path: $e');
      return [];
    }
  }

  /// Cria arquivo JSON na pasta HISTORIAS com caminho específico (data/jogador)
  Future<void> createJsonFileInHistoriasWithPath(String filename, Map<String, dynamic> jsonData, String path) async {
    final pastaHistoriasId = await criarPastaHistorias();
    if (pastaHistoriasId == null) {
      throw Exception('Não foi possível acessar pasta HISTORIAS');
    }

    // Divide o caminho (ex: "2025-09-04/jogador1@gmail.com")
    final partes = path.split('/');
    String pastaAtualId = pastaHistoriasId;

    // Cria/navega através do caminho
    for (final parte in partes) {
      final subpastaId = await _criarOuEncontrarSubpasta(pastaAtualId, parte);
      if (subpastaId == null) {
        throw Exception('Não foi possível criar/acessar subpasta: $parte');
      }
      pastaAtualId = subpastaId;
    }

    // Verificar se arquivo já existe na pasta final
    final arquivos = await _listFilesInFolder(pastaAtualId);
    final arquivoExistente = arquivos.firstWhere(
      (file) => file.name == filename,
      orElse: () => drive.File(),
    );

    if (arquivoExistente.id != null) {
      // Tentar atualizar arquivo existente
      try {
        await _updateJsonFile(arquivoExistente.id!, jsonData);
        print('✅ [DriveService] Arquivo atualizado em HISTORIAS/$path: $filename');
        return; // Sucesso, não precisa criar novo
      } catch (e) {
        print('❌ [HISTORIAS-LOG] ERRO ao atualizar arquivo em HISTORIAS: $e');
        print('🔍 [HISTORIAS-LOG] Tipo do erro: ${e.runtimeType}');
        print('🔍 [HISTORIAS-LOG] Conteúdo completo do erro: ${e.toString()}');
        
        // Verificar se é erro 403 especificamente
        if (e.toString().contains('403')) {
          print('🚨 [HISTORIAS-LOG] ERRO 403 DETECTADO - Sem permissão para alterar arquivo em $path');
        }
        
        print('🔄 [HISTORIAS-LOG] Criando novo arquivo...');
        // Modifica o nome do arquivo para evitar conflito
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filename = '${filename.replaceAll('.json', '')}_$timestamp.json';
        print('📝 [HISTORIAS-LOG] Novo nome de arquivo: $filename');
      }
    }
    
    // Criar novo arquivo na pasta final
    final file = drive.File();
    file.name = filename;
    file.parents = [pastaAtualId];

    final jsonString = json.encode(jsonData);
    final jsonBytes = utf8.encode(jsonString);
    final media = drive.Media(
      Stream.fromIterable([jsonBytes]),
      jsonBytes.length,
      contentType: 'application/json',
    );

    await api.files.create(file, uploadMedia: media);
    print('✅ [DriveService] Novo arquivo criado em HISTORIAS/$path: $filename');
  }

  Future<String> downloadFileFromRanking(String filename) async {
    try {
      final pastaRankingId = await criarPastaRanking();
      if (pastaRankingId == null) {
        print('❌ [DEBUG] Não foi possível acessar pasta RANKING');
        return '';
      }

      // Procura o arquivo na pasta RANKING
      final arquivosRanking = await listInRankingFolder();
      final arquivoDesejado = arquivosRanking.firstWhere(
        (file) => file.name == filename,
        orElse: () => drive.File(),
      );

      if (arquivoDesejado.id == null) {
        print('📊 [DEBUG] Arquivo $filename não encontrado na pasta RANKING');
        return '';
      }

      print('📥 [DEBUG] Baixando arquivo $filename da pasta RANKING');
      return await downloadFileContent(arquivoDesejado.id!);
      
    } catch (e) {
      print('❌ [DEBUG] Erro ao baixar arquivo da pasta RANKING: $e');
      return '';
    }
  }
  
  /// Exclui um arquivo do Drive pelo ID
  Future<void> deleteFile(String fileId) async {
    try {
      print('🗑️ [DEBUG] Excluindo arquivo com ID: $fileId');
      await api.files.delete(fileId);
      print('✅ [DEBUG] Arquivo excluído com sucesso');
    } catch (e) {
      print('❌ [DEBUG] Erro ao excluir arquivo: $e');
      throw e;
    }
  }
  
  /// Renomeia um arquivo do Drive pelo ID
  Future<void> renameFile(String fileId, String novoNome) async {
    try {
      print('✏️ [DEBUG] Renomeando arquivo com ID: $fileId → $novoNome');
      final fileMetadata = drive.File()..name = novoNome;
      await api.files.update(fileMetadata, fileId);
      print('✅ [DEBUG] Arquivo renomeado com sucesso');
    } catch (e) {
      print('❌ [DEBUG] Erro ao renomear arquivo: $e');
      throw e;
    }
  }
}
