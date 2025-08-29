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
  Future<bool> inicializarConexao() async {
    try {
      print('🔐 [DEBUG] Iniciando conexão com Google Drive - TECH CONNECT...');
      print('🔐 [DEBUG] Chamando DriveClientFactory.create()...');
      
      final api = await DriveClientFactory.create(container: _container);
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
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 Token expirado durante salvamento, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao();
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
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 Token expirado durante listagem, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao();
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
    }
    try {
      return await _baixar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 Token expirado para $nomeArquivo, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao();
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
      } else if (pasta == 'historias') {
        arquivos = await _driveService!.listInHistoriasFolder();
      } else if (pasta == 'drops') {
        arquivos = await _driveService!.listInDropsFolder();
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
      return conteudo;
    }

    try {
      return await _baixar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 [GoogleDriveService] Token expirado ao baixar $nomeArquivo da pasta $pasta, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao();
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
      
      if (conteudo.startsWith('{') || conteudo.startsWith('[')) {
        // É JSON
        final dadosJson = json.decode(conteudo);
        
        if (pasta == 'tipagens') {
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        } else if (pasta == 'historias') {
          await _driveService!.createJsonFileInHistorias(nomeArquivo, dadosJson);
        } else if (pasta == 'drops') {
          await _driveService!.createJsonFileInDrops(nomeArquivo, dadosJson);
        } else {
          // Fallback para pasta padrão (tipagens)
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        }
      } else {
        // É texto simples - converter para JSON
        final dadosJson = {'conteudo': conteudo};
        
        if (pasta == 'tipagens') {
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        } else if (pasta == 'historias') {
          await _driveService!.createJsonFileInHistorias(nomeArquivo, dadosJson);
        } else if (pasta == 'drops') {
          await _driveService!.createJsonFileInDrops(nomeArquivo, dadosJson);
        } else {
          // Fallback para pasta padrão (tipagens)
          await _driveService!.createJsonFile(nomeArquivo, dadosJson);
        }
      }
      
      print('✅ Arquivo salvo no Drive na pasta $pasta: $nomeArquivo');
      return true;
    }

    try {
      return await _salvar();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        print('🔒 [GoogleDriveService] Token expirado ao salvar $nomeArquivo na pasta $pasta, tentando renovar...');
        _isConnected = false;
        _driveService = null;
        final conectou = await inicializarConexao();
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
}
