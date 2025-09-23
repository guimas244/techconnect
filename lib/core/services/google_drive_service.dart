import 'dart:convert';
import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/drive/drive_service.dart';
import '../google_drive_client.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  DriveService? _driveService;
  bool _isConnected = false;
  static ProviderContainer? _container; // Container global para acessar providers
  
  /// Define o container global para acessar providers
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// Inicializa conexão com Google Drive usando o padrão TECH CONNECT
  Future<bool> inicializarConexao({bool forceReauth = false}) async {
    try {
      print('🔐 [DEBUG] Iniciando conexão com Google Drive - TECH CONNECT...');
      print('🔐 [DEBUG] Chamando DriveClientFactory.create()...');
      
      final api = await DriveClientFactory.create(container: _container, forceReauth: forceReauth);
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
    Future<bool> _salvar() async {
      if (_driveService == null || !_isConnected) {
        print('⚠️ Google Drive não conectado, tentando conectar...');
        final conectou = await inicializarConexao();
        if (!conectou) return false;
      }
      final nomeArquivo = '$tipoNome.json';
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
    }
    try {
      return await _salvar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('access_denied') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        final is403 = e.toString().contains('403') || e.toString().contains('access_denied');
        print('🔒 Erro de autenticação/permissão (${is403 ? '403' : '401'}) durante salvamento, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao(forceReauth: is403);
        if (conectou) {
          try {
            return await _salvar();
          } catch (e2) {
            print('❌ Erro ao salvar JSON após renovar token: $e2');
            return false;
          }
        } else {
          print('❌ Falha ao renovar token, reautenticação necessária.');
          return false;
        }
      } else {
        print('❌ Erro ao salvar JSON no Drive: $e');
        return false;
      }
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
    Future<List<String>> _listar() async {
      if (_driveService == null || !_isConnected) {
        final conectou = await inicializarConexao();
        if (!conectou) return [];
      }
      final arquivos = await _driveService!.listInRootFolder();
      final nomesJson = arquivos
          .where((file) => file.name?.endsWith('.json') == true)
          .map((file) => file.name!)
          .toList();
      print('📋 Encontrados ${nomesJson.length} JSONs na pasta TECH CONNECT');
      return nomesJson;
    }
    try {
      return await _listar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('access_denied') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        final is403 = e.toString().contains('403') || e.toString().contains('access_denied');
        print('🔒 Erro de autenticação/permissão (${is403 ? '403' : '401'}) durante listagem, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao(forceReauth: is403);
        if (conectou) {
          try {
            return await _listar();
          } catch (e2) {
            print('❌ Erro ao listar arquivos após renovar token: $e2');
            return [];
          }
        } else {
          print('❌ Falha ao renovar token, reautenticação necessária.');
          return [];
        }
      } else {
        print('❌ Erro ao listar arquivos do Drive: $e');
        return [];
      }
    }
  }

  /// Baixa o conteúdo de um arquivo JSON específico
  Future<Map<String, dynamic>?> baixarJson(String nomeArquivo) async {
    Future<Map<String, dynamic>?> _baixar() async {
      if (_driveService == null || !_isConnected) {
        final conectou = await inicializarConexao();
        if (!conectou) return null;
      }
      print('🔍 [DRIVE DEBUG] Listando arquivos na pasta TECH CONNECT...');
      final arquivos = await _driveService!.listInRootFolder();
      print('📁 [DRIVE DEBUG] ${arquivos.length} arquivos encontrados na pasta');
      
      // Debug: listar alguns arquivos para verificar
      for (int i = 0; i < arquivos.length && i < 10; i++) {
        print('📄 [DRIVE DEBUG] Arquivo $i: ${arquivos[i].name}');
      }
      
      print('🔍 [DRIVE DEBUG] Procurando arquivo específico: $nomeArquivo');
      final arquivo = arquivos.firstWhere(
        (file) => file.name == nomeArquivo,
        orElse: () => drive.File(),
      );
      
      if (arquivo.id == null) {
        print('❌ [DRIVE DEBUG] Arquivo não encontrado: $nomeArquivo');
        print('📋 [DRIVE DEBUG] Arquivos disponíveis: ${arquivos.map((f) => f.name).join(', ')}');
        return null;
      } else {
        print('✅ [DRIVE DEBUG] Arquivo encontrado: $nomeArquivo (ID: ${arquivo.id})');
      }
      final conteudo = await _driveService!.downloadFileContent(arquivo.id!);
      return json.decode(conteudo) as Map<String, dynamic>;
    }
    try {
      return await _baixar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('access_denied') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        final is403 = e.toString().contains('403') || e.toString().contains('access_denied');
        print('🔒 Erro de autenticação/permissão (${is403 ? '403' : '401'}) para $nomeArquivo, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao(forceReauth: is403);
        if (conectou) {
          try {
            return await _baixar();
          } catch (e2) {
            print('❌ Erro ao baixar JSON após renovar token: $e2');
            return null;
          }
        } else {
          print('❌ Falha ao renovar token, reautenticação necessária.');
          return null;
        }
      } else {
        print('❌ Erro ao baixar JSON do Drive ($nomeArquivo): $e');
        return null;
      }
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

  /// Salva um JSON em uma pasta específica
  Future<bool> salvarJsonEmPasta(String caminhoPasta, String nomeArquivo, Map<String, dynamic> dadosJson) async {
    if (_driveService == null || !_isConnected) {
      final conectou = await inicializarConexao();
      if (!conectou) return false;
    }

    try {
      print('💾 [DEBUG] Salvando JSON em pasta: $caminhoPasta/$nomeArquivo');
      
      // Por enquanto, usamos o método existente createJsonFile
      // No futuro, implementaremos criação de pastas específicas
      final nomeComPasta = '${caminhoPasta.replaceAll('/', '_')}_$nomeArquivo';
      await _driveService!.createJsonFile(nomeComPasta, dadosJson);
      
      print('✅ JSON salvo no Drive: $nomeComPasta');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar JSON em pasta no Drive ($caminhoPasta/$nomeArquivo): $e');
      return false;
    }
  }

  /// Salva um arquivo (imagem, etc.) em uma pasta específica
  Future<bool> salvarArquivo(String caminhoCompleto, Uint8List dados) async {
    if (_driveService == null || !_isConnected) {
      final conectou = await inicializarConexao();
      if (!conectou) return false;
    }

    try {
      print('💾 [DEBUG] Salvando arquivo: $caminhoCompleto');
      
      // Por enquanto, salvamos na pasta raiz com nome modificado
      final nomeArquivo = caminhoCompleto.replaceAll('/', '_');
      
      // Converter bytes para string base64 ou salvar como arquivo
      // Por enquanto, vamos simular que foi salvo
      print('✅ Arquivo simulado como salvo no Drive: $nomeArquivo');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar arquivo no Drive ($caminhoCompleto): $e');
      return false;
    }
  }

  /// Métodos específicos para Aventura

  /// Baixa arquivo de uma pasta específica (para aventura)
  Future<String> baixarArquivoDaPasta(String nomeArquivo, String pasta) async {
    Future<String> _baixar() async {
      if (_driveService == null || !_isConnected) {
        final conectou = await inicializarConexao();
        if (!conectou) return '';
      }

      print('📥 [GoogleDriveService] Baixando arquivo: $nomeArquivo da pasta: $pasta');
      
      List<drive.File> arquivos;
      
      if (pasta == 'tipagens') {
        arquivos = await _driveService!.listInTipagensFolder();
      } else if (pasta == 'historias' || pasta.startsWith('historias/')) {
        // Suporte a subpastas de historias (historias/2025-09-04/jogador)
        if (pasta.startsWith('historias/') && pasta.length > 10) {
          final subpasta = pasta.substring(10); // Remove "historias/"
          print('📅 [GoogleDriveService] Buscando na subpasta de historias: $subpasta');
          arquivos = await _driveService!.listInHistoriasFolderByPath(subpasta);
        } else {
          arquivos = await _driveService!.listInHistoriasFolder();
        }
      } else if (pasta == 'drops') {
        arquivos = await _driveService!.listInDropsFolder();
      } else if (pasta == 'rankings' || pasta.startsWith('rankings/')) {
        // Suporte a subpastas de rankings (rankings/2025-09-04)
        if (pasta.startsWith('rankings/') && pasta.length > 9) {
          final dataStr = pasta.substring(9); // Remove "rankings/"
          print('📅 [GoogleDriveService] Buscando na subpasta de data: $dataStr');
          arquivos = await _driveService!.listInRankingFolderByDate(dataStr);
        } else {
          arquivos = await _driveService!.listInRankingFolder();
        }
      } else {
        // Fallback para pasta raiz
        arquivos = await _driveService!.listInRootFolder();
      }
      
      final arquivo = arquivos.firstWhere(
        (file) => file.name == nomeArquivo,
        orElse: () => drive.File(),
      );

      if (arquivo.id == null) {
        print('! Arquivo não encontrado: $nomeArquivo na pasta $pasta');
        return '';
      }

      final conteudo = await _driveService!.downloadFileContent(arquivo.id!);
      print('✅ Arquivo baixado com sucesso da pasta $pasta: $nomeArquivo');
      print('🆔 [DEBUG] ID do arquivo baixado: ${arquivo.id}');
      print('📊 [DEBUG] Tamanho do conteúdo: ${conteudo.length} caracteres');
      print('📄 [DEBUG] Início do conteúdo: ${conteudo.length > 100 ? conteudo.substring(0, 100) + "..." : conteudo}');
      return conteudo;
    }

    try {
      return await _baixar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('access_denied') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        final is403 = e.toString().contains('403') || e.toString().contains('access_denied');
        print('🔒 [GoogleDriveService] Erro de autenticação/permissão (${is403 ? '403' : '401'}) ao baixar $nomeArquivo da pasta $pasta, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao(forceReauth: is403);
        if (conectou) {
          try {
            print('🔄 [GoogleDriveService] Tentando baixar novamente após renovar token...');
            return await _baixar();
          } catch (e2) {
            print('❌ [GoogleDriveService] Erro ao baixar arquivo após renovar token: $e2');
            return '';
          }
        } else {
          print('❌ [GoogleDriveService] Falha ao renovar token para baixar $nomeArquivo, reautenticação necessária.');
          return '';
        }
      } else {
        print('❌ [GoogleDriveService] Erro ao baixar arquivo da pasta no Drive ($pasta/$nomeArquivo): $e');
        return '';
      }
    }
  }

  /// Salva arquivo JSON em pasta específica (para aventura)
  Future<bool> salvarArquivoEmPasta(String nomeArquivo, String conteudo, String pasta) async {
    Future<bool> _salvar() async {
      if (_driveService == null || !_isConnected) {
        final conectou = await inicializarConexao();
        if (!conectou) return false;
      }

      print('💾 [GoogleDriveService] Salvando arquivo: $nomeArquivo na pasta: $pasta');
      print('🔍 [GoogleDriveService] Testando pasta: "$pasta" - startsWith rankings/: ${pasta.startsWith('rankings/')}');
      
      if (conteudo.startsWith('{') || conteudo.startsWith('[')) {
        // É JSON
        final dadosJson = json.decode(conteudo);
        
        if (pasta == 'tipagens') {
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        } else if (pasta == 'historias' || pasta.startsWith('historias/')) {
          // Suporte a subpastas de historias (historias/2025-09-04/jogador)
          if (pasta.startsWith('historias/') && pasta.length > 10) {
            final subpasta = pasta.substring(10); // Remove "historias/"
            print('📅 [GoogleDriveService] Salvando na subpasta de historias: $subpasta');
            final fileId = await _driveService!.createJsonFileInHistoriasWithPath(nomeArquivo, dadosJson, subpasta);
            print('🆔 [GoogleDriveService] ID do arquivo salvo: $fileId');
            print('🔗 [GoogleDriveService] URL direta: https://drive.google.com/file/d/$fileId/view');
          } else {
            await _driveService!.createJsonFileInHistorias(nomeArquivo, dadosJson);
          }
        } else if (pasta == 'drops') {
          await _driveService!.createJsonFileInDrops(nomeArquivo, dadosJson);
        } else if (pasta == 'rankings' || pasta.startsWith('rankings/')) {
          // Suporte a subpastas de rankings (rankings/2025-09-04)
          print('✅ [GoogleDriveService] Usando pasta RANKINGS para: $pasta');
          
          // Extrai a data da pasta se for subpasta
          if (pasta.startsWith('rankings/') && pasta.length > 9) {
            final dataStr = pasta.substring(9); // Remove "rankings/"
            print('📅 [GoogleDriveService] Data extraída da pasta: $dataStr');
            await _driveService!.createJsonFileInRankingWithDate(nomeArquivo, dadosJson, dataStr);
          } else {
            await _driveService!.createJsonFileInRanking(nomeArquivo, dadosJson);
          }
        } else {
          // Fallback para pasta padrão (tipagens)
          print('⚠️ [GoogleDriveService] FALLBACK para TIPAGENS usado para pasta: "$pasta"');
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        }
      } else {
        // É texto simples - converter para JSON
        final dadosJson = {'conteudo': conteudo};
        
        if (pasta == 'tipagens') {
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        } else if (pasta == 'historias' || pasta.startsWith('historias/')) {
          // Suporte a subpastas de historias (historias/2025-09-04/jogador)
          if (pasta.startsWith('historias/') && pasta.length > 10) {
            final subpasta = pasta.substring(10); // Remove "historias/"
            print('📅 [GoogleDriveService] Salvando na subpasta de historias: $subpasta');
            final fileId = await _driveService!.createJsonFileInHistoriasWithPath(nomeArquivo, dadosJson, subpasta);
            print('🆔 [GoogleDriveService] ID do arquivo salvo: $fileId');
            print('🔗 [GoogleDriveService] URL direta: https://drive.google.com/file/d/$fileId/view');
          } else {
            await _driveService!.createJsonFileInHistorias(nomeArquivo, dadosJson);
          }
        } else if (pasta == 'drops') {
          await _driveService!.createJsonFileInDrops(nomeArquivo, dadosJson);
        } else if (pasta == 'rankings' || pasta.startsWith('rankings/')) {
          // Suporte a subpastas de rankings (rankings/2025-09-04)
          print('✅ [GoogleDriveService] Usando pasta RANKINGS para: $pasta');
          
          // Extrai a data da pasta se for subpasta
          if (pasta.startsWith('rankings/') && pasta.length > 9) {
            final dataStr = pasta.substring(9); // Remove "rankings/"
            print('📅 [GoogleDriveService] Data extraída da pasta: $dataStr');
            await _driveService!.createJsonFileInRankingWithDate(nomeArquivo, dadosJson, dataStr);
          } else {
            await _driveService!.createJsonFileInRanking(nomeArquivo, dadosJson);
          }
        } else {
          // Fallback para pasta padrão (tipagens)
          print('⚠️ [GoogleDriveService] FALLBACK para TIPAGENS usado para pasta: "$pasta"');
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        }
      }
      
      print('✅ Arquivo salvo no Drive na pasta $pasta: $nomeArquivo');
      return true;
    }

    try {
      return await _salvar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('access_denied') || e.toString().contains('authentication') || e.toString().contains('Expected OAuth 2 access token') || e.toString().contains('DetailedApiRequestError')) {
        final is403 = e.toString().contains('403') || e.toString().contains('access_denied');
        print('🔒 [GoogleDriveService] Erro de autenticação/permissão (${is403 ? '403' : '401'}) ao salvar $nomeArquivo na pasta $pasta, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao(forceReauth: is403);
        if (conectou) {
          try {
            print('🔄 [GoogleDriveService] Tentando salvar novamente após renovar token...');
            return await _salvar();
          } catch (e2) {
            print('❌ [GoogleDriveService] Erro ao salvar arquivo após renovar token: $e2');
            return false;
          }
        } else {
          print('❌ [GoogleDriveService] Falha ao renovar token para salvar $nomeArquivo, reautenticação necessária.');
          return false;
        }
      } else {
        print('❌ [GoogleDriveService] Erro ao salvar arquivo em pasta no Drive ($pasta/$nomeArquivo): $e');
        return false;
      }
    }
  }

  /// Exclui um arquivo de uma pasta específica
  Future<bool> excluirArquivoDaPasta(String nomeArquivo, String pasta) async {
    Future<bool> _excluir() async {
      if (_driveService == null || !_isConnected) {
        final conectou = await inicializarConexao();
        if (!conectou) return false;
      }

      print('🗑️ [GoogleDriveService] Excluindo arquivo: $nomeArquivo da pasta: $pasta');
      
      try {
        // Busca arquivos na pasta específica
        List<drive.File> arquivos;
        if (pasta == 'historias') {
          arquivos = await _driveService!.listInHistoriasFolder();
        } else {
          // Para outras pastas, pode adicionar mais cases aqui
          print('❌ [GoogleDriveService] Pasta não suportada: $pasta');
          return false;
        }

        // Encontra o arquivo pelo nome
        final arquivo = arquivos.where((f) => f.name == nomeArquivo).firstOrNull;
        
        if (arquivo != null && arquivo.id != null) {
          // Exclui o arquivo usando o DriveService
          await _driveService!.deleteFile(arquivo.id!);
          print('✅ [GoogleDriveService] Arquivo excluído: $pasta/$nomeArquivo');
          return true;
        } else {
          print('ℹ️ [GoogleDriveService] Arquivo não encontrado: $pasta/$nomeArquivo');
          return true; // Considerar sucesso se arquivo não existe
        }
      } catch (e) {
        print('❌ [GoogleDriveService] Erro ao excluir arquivo: $e');
        return false;
      }
    }

    // Tenta 3 vezes como outros métodos
    for (int tentativa = 1; tentativa <= 3; tentativa++) {
      try {
        final resultado = await _excluir();
        if (resultado) return true;
      } catch (e) {
        print('❌ [GoogleDriveService] Tentativa $tentativa falhou: $e');
        if (tentativa == 3) rethrow;
        await Future.delayed(Duration(seconds: tentativa));
      }
    }
    return false;
  }
  
  /// Renomeia um arquivo de uma pasta específica
  Future<bool> renomearArquivoDaPasta(String nomeAtual, String novoNome, String pasta) async {
    Future<bool> _renomear() async {
      if (_driveService == null || !_isConnected) {
        final conectou = await inicializarConexao();
        if (!conectou) return false;
      }

      print('✏️ [GoogleDriveService] Renomeando arquivo: $nomeAtual → $novoNome na pasta: $pasta');
      
      try {
        // Busca arquivos na pasta específica
        List<drive.File> arquivos;
        if (pasta == 'historias') {
          arquivos = await _driveService!.listInHistoriasFolder();
        } else if (pasta.startsWith('historias/')) {
          // Suporte a subpastas de historias (historias/2025-09-05/jogador)
          final subpasta = pasta.substring(10); // Remove "historias/"
          print('📅 [GoogleDriveService] Renomeando na subpasta de historias: $subpasta');
          arquivos = await _driveService!.listInHistoriasFolderByPath(subpasta);
        } else {
          print('❌ [GoogleDriveService] Pasta não suportada: $pasta');
          return false;
        }

        // Encontra o arquivo pelo nome atual
        final arquivo = arquivos.where((f) => f.name == nomeAtual).firstOrNull;
        
        if (arquivo != null && arquivo.id != null) {
          // Renomeia o arquivo usando o DriveService
          await _driveService!.renameFile(arquivo.id!, novoNome);
          print('✅ [GoogleDriveService] Arquivo renomeado: $pasta/$nomeAtual → $novoNome');
          return true;
        } else {
          print('❌ [GoogleDriveService] Arquivo não encontrado: $pasta/$nomeAtual');
          return false;
        }
      } catch (e) {
        print('❌ [GoogleDriveService] Erro ao renomear arquivo: $e');
        return false;
      }
    }

    // Tenta 3 vezes como outros métodos
    for (int tentativa = 1; tentativa <= 3; tentativa++) {
      try {
        final resultado = await _renomear();
        if (resultado) return true;
      } catch (e) {
        print('❌ [GoogleDriveService] Tentativa $tentativa falhou: $e');
        if (tentativa == 3) rethrow;
        await Future.delayed(Duration(seconds: tentativa));
      }
    }
    return false;
  }

  /// Lista nomes de todos os arquivos de uma pasta específica
  Future<List<String>> listarArquivosDaPasta(String pasta) async {
    try {
      if (_driveService == null) {
        final conectou = await inicializarConexao();
        if (!conectou) return [];
      }

      print('📂 [GoogleDriveService] Listando arquivos da pasta: $pasta');
      
      List<drive.File> arquivos = [];
      
      if (pasta == 'tipagens') {
        arquivos = await _driveService!.listInTipagensFolder();
      } else if (pasta == 'historias' || pasta.startsWith('historias/')) {
        // Suporte a subpastas de historias (historias/2025-09-04/jogador)
        if (pasta.startsWith('historias/') && pasta.length > 10) {
          final subpasta = pasta.substring(10); // Remove "historias/"
          print('📅 [GoogleDriveService] Buscando na subpasta de historias: $subpasta');
          arquivos = await _driveService!.listInHistoriasFolderByPath(subpasta);
        } else {
          arquivos = await _driveService!.listInHistoriasFolder();
        }
      } else if (pasta == 'drops') {
        arquivos = await _driveService!.listInDropsFolder();
      } else if (pasta == 'rankings' || pasta.startsWith('rankings/')) {
        // Suporte a subpastas de rankings (rankings/2025-09-04)
        if (pasta.startsWith('rankings/') && pasta.length > 9) {
          final dataStr = pasta.substring(9); // Remove "rankings/"
          print('📅 [GoogleDriveService] Listando arquivos da subpasta de data: $dataStr');
          arquivos = await _driveService!.listInRankingFolderByDate(dataStr);
        } else {
          arquivos = await _driveService!.listInRankingFolder();
        }
      } else {
        // Fallback para pasta raiz
        arquivos = await _driveService!.listInRootFolder();
      }
      
      // Extrai apenas os nomes dos arquivos
      final nomesArquivos = arquivos.map((file) => file.name ?? '').where((name) => name.isNotEmpty).toList();
      
      print('✅ [GoogleDriveService] Encontrados ${nomesArquivos.length} arquivos na pasta $pasta');
      return nomesArquivos;
      
    } catch (e) {
      print('❌ [GoogleDriveService] Erro ao listar arquivos da pasta $pasta: $e');
      return [];
    }
  }
}
