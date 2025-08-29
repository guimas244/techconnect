import 'package:googleapis/sheets/v4.dart' as sheets;
import '../../../core/google_drive_client.dart';
import '../../../core/services/google_drive_service.dart';
import 'drops_config_service.dart';

class GoogleSheetsService {
  final GoogleDriveService _driveService = GoogleDriveService();
  sheets.SheetsApi? _sheetsApi;
  String? _spreadsheetId;
  
  /// Getter para verificar se spreadsheet ID foi configurado
  String? get spreadsheetId => _spreadsheetId;
  
  /// Inicializa conexão com Google Sheets
  Future<bool> inicializarSheetsApi() async {
    try {
      print('📊 [GoogleSheetsService] Inicializando Google Sheets API...');
      
      // Usa cliente HTTP autenticado
      final client = await DriveClientFactory.createHttpClient();
      _sheetsApi = sheets.SheetsApi(client);
      
      print('✅ [GoogleSheetsService] Google Sheets API inicializada');
      return true;
    } catch (e) {
      print('❌ [GoogleSheetsService] Erro ao inicializar Sheets API: $e');
      return false;
    }
  }
  
  /// Busca o ID da planilha 'drops_techterra' na pasta drops
  Future<String?> buscarIdPlanilha() async {
    if (_spreadsheetId != null) {
      return _spreadsheetId;
    }
    
    try {
      print('🔍 [GoogleSheetsService] Buscando planilha drops_techterra...');
      
      // Busca arquivo na pasta drops
      final arquivos = await _driveService.listarArquivosDrive();
      
      // Procura por arquivo que contenha 'drops_techterra' e seja do tipo Sheets
      for (final arquivo in arquivos) {
        if (arquivo.toLowerCase().contains('drops_techterra') && 
            (arquivo.toLowerCase().contains('.xlsx') || 
             arquivo.toLowerCase().contains('sheet'))) {
          
          // Para encontrar o ID real, precisamos usar a Drive API
          // Por enquanto, vamos usar uma abordagem alternativa
          print('📋 [GoogleSheetsService] Arquivo encontrado: $arquivo');
          
          // TODO: Implementar busca do ID real da planilha
          // Por enquanto, vamos assumir que o usuário vai fornecer o ID
          break;
        }
      }
      
      print('⚠️ [GoogleSheetsService] ID da planilha não implementado ainda');
      return null;
      
    } catch (e) {
      print('❌ [GoogleSheetsService] Erro ao buscar ID da planilha: $e');
      return null;
    }
  }
  
  /// Define manualmente o ID da planilha (temporário)
  void definirIdPlanilha(String spreadsheetId) {
    _spreadsheetId = spreadsheetId;
    print('📋 [GoogleSheetsService] ID da planilha definido: $spreadsheetId');
  }
  
  /// Lê dados da planilha Google Sheets
  Future<List<DropConfig>> lerDadosDaPlanilha() async {
    try {
      if (_sheetsApi == null) {
        final inicializado = await inicializarSheetsApi();
        if (!inicializado) {
          print('❌ [GoogleSheetsService] Falha ao inicializar Sheets API');
          return [];
        }
      }
      
      final spreadsheetId = _spreadsheetId ?? await buscarIdPlanilha();
      if (spreadsheetId == null) {
        print('❌ [GoogleSheetsService] ID da planilha não encontrado');
        return [];
      }
      
      print('📖 [GoogleSheetsService] Lendo dados da planilha...');
      
      // Lê dados da planilha (assumindo que os dados estão na primeira aba)
      final range = 'Configuracao_Drops!A:E'; // Colunas A até E
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        range,
      );
      
      final values = response.values;
      if (values == null || values.isEmpty) {
        print('⚠️ [GoogleSheetsService] Planilha vazia ou sem dados');
        return [];
      }
      
      // Primeira linha são os headers, pula ela
      final dadosItens = <DropConfig>[];
      for (int i = 1; i < values.length; i++) {
        final row = values[i];
        
        // Verifica se a linha tem dados suficientes
        if (row.length >= 5) {
          try {
            final config = DropConfig(
              nome: row[0]?.toString() ?? '',
              descricao: row[1]?.toString() ?? '',
              tipo: row[2]?.toString() ?? 'item',
              quantidade: int.tryParse(row[3]?.toString() ?? '1') ?? 1,
              raridade: row[4]?.toString() ?? 'normal',
            );
            
            // Só adiciona se tem nome válido
            if (config.nome.isNotEmpty) {
              dadosItens.add(config);
            }
          } catch (e) {
            print('⚠️ [GoogleSheetsService] Erro ao processar linha $i: $e');
          }
        }
      }
      
      print('✅ [GoogleSheetsService] ${dadosItens.length} itens carregados da planilha');
      return dadosItens;
      
    } catch (e) {
      print('❌ [GoogleSheetsService] Erro ao ler dados da planilha: $e');
      return [];
    }
  }
  
  /// Verifica se a planilha existe e é acessível
  Future<bool> verificarAcessoPlanilha() async {
    try {
      if (_sheetsApi == null) {
        final inicializado = await inicializarSheetsApi();
        if (!inicializado) return false;
      }
      
      final spreadsheetId = _spreadsheetId ?? await buscarIdPlanilha();
      if (spreadsheetId == null) return false;
      
      // Tenta obter informações básicas da planilha
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      
      print('✅ [GoogleSheetsService] Planilha acessível: ${spreadsheet.properties?.title}');
      return true;
      
    } catch (e) {
      print('❌ [GoogleSheetsService] Erro ao verificar acesso à planilha: $e');
      return false;
    }
  }
  
  /// Obtém informações da planilha (nome, abas, etc.)
  Future<Map<String, dynamic>?> obterInfoPlanilha() async {
    try {
      if (_sheetsApi == null) {
        final inicializado = await inicializarSheetsApi();
        if (!inicializado) return null;
      }
      
      final spreadsheetId = _spreadsheetId ?? await buscarIdPlanilha();
      if (spreadsheetId == null) return null;
      
      final spreadsheet = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      
      return {
        'titulo': spreadsheet.properties?.title,
        'abas': spreadsheet.sheets?.map((sheet) => sheet.properties?.title).toList(),
        'url': 'https://docs.google.com/spreadsheets/d/$spreadsheetId',
      };
      
    } catch (e) {
      print('❌ [GoogleSheetsService] Erro ao obter info da planilha: $e');
      return null;
    }
  }
}