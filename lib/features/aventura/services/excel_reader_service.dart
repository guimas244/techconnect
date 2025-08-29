import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import '../../../core/google_drive_client.dart';
import '../models/drop_jogador.dart';

class ExcelReaderService {
  drive.DriveApi? _driveApi;
  static const String DROPS_FOLDER_NAME = 'drops';
  static const String EXCEL_FILE_NAME = 'drops_techterra.xlsx';
  
  /// Inicializa conexão com Google Drive
  Future<bool> _inicializarDriveApi() async {
    try {
      print('📊 [ExcelReaderService] Inicializando Drive API...');
      _driveApi = await DriveClientFactory.create();
      print('✅ [ExcelReaderService] Drive API inicializada');
      return true;
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao inicializar Drive API: $e');
      return false;
    }
  }
  
  /// Busca a pasta drops dentro da pasta raiz TECH CONNECT
  Future<String?> _buscarPastaDrops() async {
    try {
      print('🔍 [ExcelReaderService] Buscando pasta drops...');
      
      // Lista arquivos na pasta raiz (FOLDER_ID)
      final response = await _driveApi!.files.list(
        q: "parents in '${DriveClientFactory.FOLDER_ID}' and name='$DROPS_FOLDER_NAME' and mimeType='application/vnd.google-apps.folder'",
        spaces: 'drive',
      );
      
      if (response.files != null && response.files!.isNotEmpty) {
        final pastaDropsId = response.files!.first.id!;
        print('✅ [ExcelReaderService] Pasta drops encontrada: $pastaDropsId');
        return pastaDropsId;
      }
      
      print('❌ [ExcelReaderService] Pasta drops não encontrada');
      return null;
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao buscar pasta drops: $e');
      return null;
    }
  }
  
  /// Busca o arquivo drops_techterra na pasta drops (Excel ou Google Sheets)
  Future<Map<String, String>?> _buscarArquivoDrops(String pastaDropsId) async {
    try {
      print('🔍 [ExcelReaderService] Buscando arquivo drops_techterra...');
      
      // Lista todos os arquivos na pasta drops
      final response = await _driveApi!.files.list(
        q: "parents in '$pastaDropsId'",
        spaces: 'drive',
      );
      
      if (response.files != null && response.files!.isNotEmpty) {
        // Procura por arquivos que comecem com 'drops_techterra'
        for (final arquivo in response.files!) {
          final nome = arquivo.name ?? '';
          if (nome.toLowerCase().contains('drops_techterra')) {
            print('✅ [ExcelReaderService] Arquivo drops encontrado: $nome (ID: ${arquivo.id}, Tipo: ${arquivo.mimeType})');
            return {
              'id': arquivo.id!,
              'nome': nome,
              'tipo': arquivo.mimeType ?? 'unknown'
            };
          }
        }
      }
      
      print('❌ [ExcelReaderService] Arquivo drops_techterra não encontrado');
      return null;
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao buscar arquivo: $e');
      return null;
    }
  }
  
  /// Lê o conteúdo do arquivo Excel e imprime no console
  Future<void> lerEImprimirExcel() async {
    try {
      print('🚀 [ExcelReaderService] Iniciando leitura do arquivo Excel...');
      
      // Inicializa Drive API se necessário
      if (_driveApi == null) {
        final inicializado = await _inicializarDriveApi();
        if (!inicializado) {
          print('❌ [ExcelReaderService] Falha ao inicializar Drive API');
          return;
        }
      }
      
      // Busca pasta drops
      final pastaDropsId = await _buscarPastaDrops();
      if (pastaDropsId == null) {
        print('❌ [ExcelReaderService] Pasta drops não encontrada');
        return;
      }
      
      // Busca arquivo drops_techterra
      final arquivoInfo = await _buscarArquivoDrops(pastaDropsId);
      if (arquivoInfo == null) {
        print('❌ [ExcelReaderService] Arquivo drops_techterra não encontrado');
        return;
      }
      
      final arquivoId = arquivoInfo['id']!;
      final nomeArquivo = arquivoInfo['nome']!;
      final tipoArquivo = arquivoInfo['tipo']!;
      
      // Verifica o tipo do arquivo e processa adequadamente
      if (tipoArquivo.contains('spreadsheet')) {
        // É um Google Sheets - usa Sheets API
        await _lerGoogleSheets(arquivoId, nomeArquivo);
      } else {
        // É um arquivo Excel ou outro - baixa diretamente
        await _lerArquivoBinario(arquivoId, nomeArquivo, tipoArquivo);
      }
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao ler arquivo Excel: $e');
      
      // Tenta uma abordagem alternativa - listar todos os arquivos
      try {
        print('🔄 [ExcelReaderService] Tentando abordagem alternativa...');
        await _tentarLeituraAlternativa();
      } catch (e2) {
        print('❌ [ExcelReaderService] Erro na abordagem alternativa: $e2');
      }
    }
  }
  
  /// Lê dados de um Google Sheets usando Drive API (export como CSV)
  Future<void> _lerGoogleSheets(String spreadsheetId, String nomeArquivo) async {
    try {
      print('📊 [ExcelReaderService] Lendo Google Sheets: $nomeArquivo');
      print('=' * 60);
      
      // Exporta o Google Sheets como CSV usando Drive API
      print('📖 [ExcelReaderService] Exportando Google Sheets como CSV...');
      final media = await _driveApi!.files.export(
        spreadsheetId,
        'text/csv',
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      // Lê os dados CSV
      final List<int> dataBytes = [];
      if (media is drive.Media) {
        await for (List<int> chunk in media.stream) {
          dataBytes.addAll(chunk);
        }
      }
      
      if (dataBytes.isNotEmpty) {
        // Converte bytes para string
        final String csvContent = utf8.decode(dataBytes);
        
        print('📄 Nome da planilha: $nomeArquivo');
        print('📊 Tamanho dos dados: ${dataBytes.length} bytes');
        print('🔍 Formato: CSV (exportado do Google Sheets)');
        print('');
        print('📋 CONTEÚDO COMPLETO DA PLANILHA:');
        print('-' * 60);
        
        // Processa linha por linha
        final linhas = csvContent.split('\n');
        int numeroLinha = 1;
        
        for (final linha in linhas) {
          final linhaTrimmed = linha.trim();
          if (linhaTrimmed.isNotEmpty) {
            // Se a linha tem vírgulas, assume que são colunas separadas
            if (linhaTrimmed.contains(',')) {
              final colunas = linhaTrimmed.split(',');
              final conteudoFormatado = colunas.map((col) => col.trim()).join(' | ');
              print('Linha $numeroLinha: $conteudoFormatado');
            } else {
              print('Linha $numeroLinha: $linhaTrimmed');
            }
            numeroLinha++;
          }
        }
        
        print('-' * 60);
        print('✅ [ExcelReaderService] Total de ${numeroLinha - 1} linhas lidas da planilha');
        print('💡 Dados extraídos com sucesso do Google Sheets!');
        
      } else {
        print('❌ [ExcelReaderService] Nenhum dado foi exportado');
      }
      
      print('=' * 60);
      print('✅ [ExcelReaderService] Google Sheets lido com sucesso usando Drive API!');
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao ler Google Sheets: $e');
      print('💡 Tentando abordagem alternativa...');
      
      // Fallback: tenta baixar como arquivo binário
      try {
        await _lerArquivoBinario(spreadsheetId, nomeArquivo, 'application/vnd.google-apps.spreadsheet');
      } catch (e2) {
        print('❌ [ExcelReaderService] Erro na abordagem alternativa: $e2');
      }
    }
  }
  
  /// Lê arquivo binário (Excel, etc.)
  Future<void> _lerArquivoBinario(String arquivoId, String nomeArquivo, String tipoArquivo) async {
    try {
      print('📖 [ExcelReaderService] Baixando arquivo binário: $nomeArquivo');
      final media = await _driveApi!.files.get(
        arquivoId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      // Lê os bytes do arquivo
      final List<int> dataBytes = [];
      if (media is drive.Media) {
        await for (List<int> chunk in media.stream) {
          dataBytes.addAll(chunk);
        }
      }
      
      if (dataBytes.isNotEmpty) {
        print('📋 [ExcelReaderService] ARQUIVO BINÁRIO BAIXADO:');
        print('=' * 60);
        print('📄 Nome do arquivo: $nomeArquivo');
        print('📊 Tamanho: ${dataBytes.length} bytes');
        print('🔍 Tipo: $tipoArquivo');
        print('=' * 60);
        
        // Mostra os primeiros bytes em formato legível
        print('🔍 Cabeçalho do arquivo (primeiros 50 bytes em hex):');
        final hexHeader = dataBytes.take(50).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        print('   $hexHeader');
        
        // Tenta encontrar strings legíveis no arquivo
        print('🔍 Tentando extrair texto legível do arquivo:');
        final String content = String.fromCharCodes(dataBytes);
        
        // Busca por palavras alfanuméricas simples
        final regex = RegExp(r'[a-zA-Z]{3,}');
        final matches = regex.allMatches(content);
        
        int count = 0;
        final Set<String> foundTexts = {};
        
        for (final match in matches) {
          final text = match.group(0);
          if (text != null && text.length >= 3 && !foundTexts.contains(text)) {
            foundTexts.add(text);
            print('   Texto encontrado: "$text"');
            count++;
            if (count >= 20) break;
          }
        }
        
        if (count == 0) {
          print('   Nenhum texto legível encontrado - arquivo está comprimido/codificado');
        }
        
        print('=' * 60);
        print('✅ [ExcelReaderService] Arquivo binário lido com sucesso!');
      } else {
        print('❌ [ExcelReaderService] Arquivo vazio ou não foi possível baixar');
      }
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao ler arquivo binário: $e');
    }
  }
  
  /// Tenta uma abordagem alternativa para ler o arquivo
  Future<void> _tentarLeituraAlternativa() async {
    try {
      // Busca pasta drops
      final pastaDropsId = await _buscarPastaDrops();
      if (pastaDropsId == null) return;
      
      // Lista todos os arquivos na pasta drops para debug
      print('🔍 [ExcelReaderService] Listando todos os arquivos na pasta drops:');
      final response = await _driveApi!.files.list(
        q: "parents in '$pastaDropsId'",
        spaces: 'drive',
      );
      
      if (response.files != null) {
        for (final arquivo in response.files!) {
          print('📄 Arquivo encontrado: ${arquivo.name} (ID: ${arquivo.id}, MimeType: ${arquivo.mimeType})');
          
          // Se encontrar o arquivo Excel, tenta baixar como binário
          if (arquivo.name == EXCEL_FILE_NAME) {
            print('📖 [ExcelReaderService] Tentando download direto do arquivo...');
            
            try {
              final media = await _driveApi!.files.get(
                arquivo.id!,
                downloadOptions: drive.DownloadOptions.fullMedia,
              );
              
              final List<int> dataBytes = [];
              if (media is drive.Media) {
                await for (List<int> chunk in media.stream) {
                  dataBytes.addAll(chunk);
                }
              }
              
              print('✅ [ExcelReaderService] Arquivo baixado com sucesso!');
              print('📊 Tamanho do arquivo: ${dataBytes.length} bytes');
              
              // Tenta extrair algumas strings do arquivo
              final String content = String.fromCharCodes(dataBytes);
              final regex = RegExp(r'[a-zA-Z]{4,}');
              final matches = regex.allMatches(content);
              
              print('🔍 Palavras encontradas no arquivo:');
              int count = 0;
              final Set<String> foundWords = {};
              
              for (final match in matches.take(15)) {
                final text = match.group(0);
                if (text != null && !foundWords.contains(text)) {
                  foundWords.add(text);
                  print('   "$text"');
                  count++;
                }
              }
              
              if (count == 0) {
                print('   Nenhuma palavra legível encontrada');
              }
              
            } catch (e) {
              print('❌ [ExcelReaderService] Erro no download: $e');
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro na leitura alternativa: $e');
    }
  }

  /// Lê e retorna os dados do Excel como lista de itens estruturados
  Future<List<Map<String, String>>> lerDadosDoExcel() async {
    final List<Map<String, String>> itens = [];
    
    try {
      print('📊 [ExcelReaderService] Lendo dados estruturados do Excel...');
      
      // Inicializa Drive API se necessário
      if (_driveApi == null) {
        final inicializado = await _inicializarDriveApi();
        if (!inicializado) {
          print('❌ [ExcelReaderService] Falha ao inicializar Drive API');
          return itens;
        }
      }
      
      // Busca pasta drops
      final pastaDropsId = await _buscarPastaDrops();
      if (pastaDropsId == null) {
        print('❌ [ExcelReaderService] Pasta drops não encontrada');
        return itens;
      }
      
      // Busca arquivo drops_techterra
      final arquivoInfo = await _buscarArquivoDrops(pastaDropsId);
      if (arquivoInfo == null) {
        print('❌ [ExcelReaderService] Arquivo drops_techterra não encontrado');
        return itens;
      }
      
      final arquivoId = arquivoInfo['id']!;
      final tipoArquivo = arquivoInfo['tipo']!;
      
      // Verifica o tipo do arquivo e processa adequadamente
      if (tipoArquivo.contains('spreadsheet')) {
        // É um Google Sheets - exporta como CSV e processa
        itens.addAll(await _lerDadosGoogleSheets(arquivoId));
      } else {
        print('⚠️ [ExcelReaderService] Arquivo não é Google Sheets, não é possível processar dados estruturados');
      }
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao ler dados do Excel: $e');
    }
    
    print('✅ [ExcelReaderService] ${itens.length} itens estruturados lidos do Excel');
    return itens;
  }

  /// Lê dados estruturados de um Google Sheets
  Future<List<Map<String, String>>> _lerDadosGoogleSheets(String spreadsheetId) async {
    final List<Map<String, String>> itens = [];
    
    try {
      // Exporta o Google Sheets como CSV usando Drive API
      final media = await _driveApi!.files.export(
        spreadsheetId,
        'text/csv',
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      // Lê os dados CSV
      final List<int> dataBytes = [];
      if (media is drive.Media) {
        await for (List<int> chunk in media.stream) {
          dataBytes.addAll(chunk);
        }
      }
      
      if (dataBytes.isNotEmpty) {
        // Converte bytes para string
        final String csvContent = utf8.decode(dataBytes);
        
        // Processa linha por linha
        final linhas = csvContent.split('\n');
        
        // Primeira linha são os cabeçalhos
        if (linhas.isNotEmpty) {
          final cabecalhos = linhas[0].split(',').map((h) => h.trim()).toList();
          print('📋 [ExcelReaderService] Cabeçalhos encontrados: $cabecalhos');
          
          // Processa as linhas de dados (pula a primeira linha dos cabeçalhos)
          for (int i = 1; i < linhas.length; i++) {
            final linha = linhas[i].trim();
            if (linha.isNotEmpty) {
              final valores = linha.split(',').map((v) => v.trim()).toList();
              
              // Cria um mapa com os dados da linha
              final Map<String, String> item = {};
              for (int j = 0; j < cabecalhos.length && j < valores.length; j++) {
                item[cabecalhos[j]] = valores[j];
              }
              
              // Só adiciona se tem nome válido
              if (item.isNotEmpty && item.values.any((v) => v.isNotEmpty)) {
                itens.add(item);
              }
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao ler dados estruturados do Google Sheets: $e');
    }
    
    return itens;
  }

  /// Lê e retorna um item aleatório do Excel como DropItem
  Future<DropItem?> lerItemAleatorioDoExcel() async {
    try {
      // Lê todos os dados do Excel
      final itens = await lerDadosDoExcel();
      
      if (itens.isEmpty) {
        print('⚠️ [ExcelReaderService] Nenhum item encontrado no Excel');
        return null;
      }
      
      // Seleciona um item aleatório
      final random = Random();
      final itemSelecionado = itens[random.nextInt(itens.length)];
      
      print('🎲 [ExcelReaderService] Item selecionado aleatoriamente: ${itemSelecionado}');
      
      // Converte para DropItem - assumindo as colunas padrão
      final nome = itemSelecionado['nome'] ?? itemSelecionado['Nome'] ?? 'Item Desconhecido';
      final descricao = itemSelecionado['descricao'] ?? itemSelecionado['Descrição'] ?? 'Sem descrição';
      final tipo = itemSelecionado['tipo'] ?? itemSelecionado['Tipo'] ?? 'item';
      final quantidadeStr = itemSelecionado['quantidade'] ?? itemSelecionado['Quantidade'] ?? '1';
      final quantidade = int.tryParse(quantidadeStr) ?? 1;
      
      final dropItem = DropItem(
        nome: nome,
        descricao: descricao,
        tipo: tipo,
        quantidade: quantidade,
        dataObtencao: DateTime.now(),
      );
      
      print('✅ [ExcelReaderService] Item convertido para DropItem: ${dropItem.nome}');
      return dropItem;
      
    } catch (e) {
      print('❌ [ExcelReaderService] Erro ao ler item aleatório do Excel: $e');
      return null;
    }
  }
}