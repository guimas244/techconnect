import '../services/google_drive_service.dart';

/// Utilitário para gerenciar pastas organizadas por data
class DateFolderManager {
  static final DateFolderManager _instance = DateFolderManager._internal();
  factory DateFolderManager() => _instance;
  DateFolderManager._internal();

  final GoogleDriveService _driveService = GoogleDriveService();

  /// Converte DateTime para horário de Brasília (UTC-3)
  DateTime paraHorarioBrasilia(DateTime utc) {
    return utc.subtract(const Duration(hours: 3));
  }

  /// Obtém DateTime atual em horário de Brasília
  DateTime get agora {
    return paraHorarioBrasilia(DateTime.now().toUtc());
  }

  /// Formata data para nome de pasta (YYYY-MM-DD)
  String formatarDataParaPasta(DateTime data) {
    return '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  /// Obtém o nome da pasta para uma data específica
  String getPastaDia(DateTime data, String prefixo) {
    final dataFormatada = formatarDataParaPasta(data);
    return '${prefixo}_$dataFormatada';
  }

  /// Cria ou busca uma pasta específica para um dia
  /// 
  /// [prefixo]: Prefixo da pasta (ex: "rankings", "historicos", "logs")
  /// [data]: Data para a qual criar/buscar a pasta (opcional, usa data atual se null)
  /// 
  /// Retorna o nome da pasta criada/encontrada
  Future<String> criarOuBuscarPastaDia(String prefixo, {DateTime? data}) async {
    try {
      final dataFinal = data ?? agora;
      final dataSemHora = DateTime(dataFinal.year, dataFinal.month, dataFinal.day);
      final nomePasta = getPastaDia(dataSemHora, prefixo);
      
      print('📁 [DateFolderManager] Criando/buscando pasta: $nomePasta');
      
      // Verifica se a pasta já existe criando um arquivo de controle temporário
      final arquivoControle = '.folder_$nomePasta';
      final conteudoExistente = await _driveService.baixarArquivoDaPasta(arquivoControle, nomePasta);
      
      if (conteudoExistente.isEmpty) {
        // Pasta não existe, cria arquivo de controle para forçar criação
        await _driveService.salvarArquivoEmPasta(arquivoControle, 'Created: ${DateTime.now().toIso8601String()}', nomePasta);
        print('✅ [DateFolderManager] Pasta criada: $nomePasta');
      } else {
        print('📁 [DateFolderManager] Pasta já existe: $nomePasta');
      }
      
      return nomePasta;
      
    } catch (e) {
      print('❌ [DateFolderManager] Erro ao criar/buscar pasta: $e');
      throw Exception('Erro ao criar/buscar pasta para data: $e');
    }
  }

  /// Salva um arquivo em uma pasta específica por data
  /// 
  /// [nomeArquivo]: Nome do arquivo a ser salvo
  /// [conteudo]: Conteúdo do arquivo
  /// [prefixo]: Prefixo da pasta
  /// [data]: Data da pasta (opcional, usa data atual se null)
  Future<void> salvarArquivoNaPastaDia({
    required String nomeArquivo,
    required String conteudo, 
    required String prefixo,
    DateTime? data,
  }) async {
    try {
      final nomePasta = await criarOuBuscarPastaDia(prefixo, data: data);
      await _driveService.salvarArquivoEmPasta(nomeArquivo, conteudo, nomePasta);
      
      print('💾 [DateFolderManager] Arquivo salvo: $nomeArquivo em $nomePasta');
      
    } catch (e) {
      print('❌ [DateFolderManager] Erro ao salvar arquivo na pasta do dia: $e');
      throw Exception('Erro ao salvar arquivo na pasta do dia: $e');
    }
  }

  /// Baixa um arquivo de uma pasta específica por data
  /// 
  /// [nomeArquivo]: Nome do arquivo a ser baixado
  /// [prefixo]: Prefixo da pasta
  /// [data]: Data da pasta (opcional, usa data atual se null)
  /// 
  /// Retorna o conteúdo do arquivo ou string vazia se não encontrado
  Future<String> baixarArquivoDaPastaDia({
    required String nomeArquivo,
    required String prefixo,
    DateTime? data,
  }) async {
    try {
      final dataFinal = data ?? agora;
      final dataSemHora = DateTime(dataFinal.year, dataFinal.month, dataFinal.day);
      final nomePasta = getPastaDia(dataSemHora, prefixo);
      
      final conteudo = await _driveService.baixarArquivoDaPasta(nomeArquivo, nomePasta);
      
      if (conteudo.isNotEmpty) {
        print('📥 [DateFolderManager] Arquivo baixado: $nomeArquivo de $nomePasta');
      } else {
        print('📥 [DateFolderManager] Arquivo não encontrado: $nomeArquivo em $nomePasta');
      }
      
      return conteudo;
      
    } catch (e) {
      print('❌ [DateFolderManager] Erro ao baixar arquivo da pasta do dia: $e');
      return '';
    }
  }

  /// Lista todas as pastas de um prefixo específico (últimos N dias)
  /// 
  /// [prefixo]: Prefixo das pastas a listar
  /// [diasLimite]: Quantidade de dias para verificar (padrão: 30)
  /// 
  /// Retorna lista de datas que possuem pastas
  Future<List<DateTime>> listarDatasComPastas(String prefixo, {int diasLimite = 30}) async {
    try {
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final List<DateTime> datasComPastas = [];
      
      // Verifica os últimos N dias
      for (int i = 0; i < diasLimite; i++) {
        final dataVerificar = hoje.subtract(Duration(days: i));
        final nomePasta = getPastaDia(dataVerificar, prefixo);
        final arquivoControle = '.folder_$nomePasta';
        
        // Verifica se existe pasta para esta data
        final conteudo = await _driveService.baixarArquivoDaPasta(arquivoControle, nomePasta);
        if (conteudo.isNotEmpty) {
          datasComPastas.add(dataVerificar);
        }
      }
      
      // Ordena por data (mais recente primeiro)
      datasComPastas.sort((a, b) => b.compareTo(a));
      
      print('📋 [DateFolderManager] Encontradas ${datasComPastas.length} pastas para prefixo: $prefixo');
      return datasComPastas;
      
    } catch (e) {
      print('❌ [DateFolderManager] Erro ao listar datas com pastas: $e');
      return [];
    }
  }

  /// Remove todos os arquivos de uma pasta específica por data
  /// CUIDADO: Esta operação é irreversível!
  /// 
  /// [prefixo]: Prefixo da pasta
  /// [data]: Data da pasta a ser limpa
  Future<void> limparPastaDia(String prefixo, DateTime data) async {
    try {
      final dataSemHora = DateTime(data.year, data.month, data.day);
      final nomePasta = getPastaDia(dataSemHora, prefixo);
      
      print('🗑️ [DateFolderManager] AVISO: Limpando pasta $nomePasta');
      
      // Por enquanto, apenas remove o arquivo de controle para "desativar" a pasta
      final arquivoControle = '.folder_$nomePasta';
      // Note: GoogleDriveService não tem método de exclusão implementado
      // Esta funcionalidade precisaria ser implementada no GoogleDriveService se necessário
      
      print('⚠️ [DateFolderManager] Funcionalidade de limpeza não implementada - requer extensão do GoogleDriveService');
      
    } catch (e) {
      print('❌ [DateFolderManager] Erro ao limpar pasta do dia: $e');
      throw Exception('Erro ao limpar pasta do dia: $e');
    }
  }
}