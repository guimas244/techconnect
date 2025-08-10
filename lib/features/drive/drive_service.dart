import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import '../../core/google_drive_client.dart';

class DriveService {
  final drive.DriveApi api;
  final String folderId;

  DriveService(this.api, {String? folderId})
      : folderId = folderId ?? DriveClientFactory.FOLDER_ID;

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

  Future<List<drive.File>> listInRootFolder() async {
    // Se FOLDER_ID ainda não foi configurado, usa o método debug
    if (folderId == "PASTE_TECH_CONNECT_FOLDER_ID_HERE") {
      print('⚠️ [DEBUG] FOLDER_ID não configurado, usando listagem debug...');
      return await listInRootFolderDebug();
    }
    
    print('🔍 [DEBUG] DriveService: Listando arquivos na pasta: $folderId');
    final res = await api.files.list(
      q: "'$folderId' in parents and trashed = false",
      spaces: "drive",
      $fields: "files(id,name,mimeType,modifiedTime,size)",
      pageSize: 100,
    );
    print('✅ [DEBUG] DriveService: Encontrados ${res.files?.length ?? 0} arquivos na pasta');
    return res.files ?? <drive.File>[];
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
    final content = const JsonEncoder.withIndent('  ').convert(jsonData);
    final media = drive.Media(
      http.ByteStream.fromBytes(utf8.encode(content)),
      content.length,
    );
    final meta = drive.File()
      ..name = name
      ..mimeType = 'application/json'
      ..parents = [folderId];
    return await api.files.create(meta, uploadMedia: media);
  }

  Future<drive.File> updateJsonFile(String fileId, Map<String, dynamic> jsonData) async {
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
}
