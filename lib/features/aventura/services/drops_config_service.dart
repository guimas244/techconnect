import 'dart:convert';
import '../../../core/services/google_drive_service.dart';
import 'google_sheets_service.dart';
import 'drops_temp_config.dart';

/// Modelo para configuração de drop
class DropConfig {
  final String nome;
  final String descricao;
  final String tipo;
  final int quantidade;
  final String raridade;
  
  const DropConfig({
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.quantidade,
    required this.raridade,
  });
  
  factory DropConfig.fromJson(Map<String, dynamic> json) {
    return DropConfig(
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      tipo: json['tipo'] ?? 'item',
      quantidade: json['quantidade'] ?? 1,
      raridade: json['raridade'] ?? 'normal',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'quantidade': quantidade,
      'raridade': raridade,
    };
  }
}

/// Enum para raridades (baseado no GeradorNomesItens)
enum RaridadeDrop {
  inferior,
  normal,
  raro,
  epico,
  lendario;
  
  /// Peso para sorteio (baseado no GeradorNomesItens)
  int get peso {
    switch (this) {
      case RaridadeDrop.inferior:
        return 35; // 35%
      case RaridadeDrop.normal:
        return 30; // 30%
      case RaridadeDrop.raro:
        return 20; // 20%
      case RaridadeDrop.epico:
        return 10; // 10%
      case RaridadeDrop.lendario:
        return 5;  // 5%
    }
  }
  
  static RaridadeDrop fromString(String raridade) {
    switch (raridade.toLowerCase()) {
      case 'inferior':
        return RaridadeDrop.inferior;
      case 'normal':
        return RaridadeDrop.normal;
      case 'raro':
        return RaridadeDrop.raro;
      case 'epico':
        return RaridadeDrop.epico;
      case 'lendario':
        return RaridadeDrop.lendario;
      default:
        return RaridadeDrop.normal;
    }
  }
}

class DropsConfigService {
  final GoogleDriveService _driveService = GoogleDriveService();
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  static const String _configFileName = 'drops_techterra.xlsx';
  static const String _jsonConfigFileName = 'drops_techterra.json';
  
  // REMOVIDO o cache para sempre buscar do Drive/Sheets
  // List<DropConfig>? _cachedDrops;
  // DateTime? _lastCacheTime;
  
  /// Carrega configurações de drops SEMPRE do Google Drive (sem cache)
  Future<List<DropConfig>> carregarConfiguracaoDrops() async {
    try {
      print('🚀 [DropsConfigService] =====================================');
      print('🚀 [DropsConfigService] INICIANDO CARREGAMENTO DE CONFIGURAÇÃO');
      print('🚀 [DropsConfigService] =====================================');
      
      // Primeiro tenta carregar do Google Sheets
      print('📊 [DropsConfigService] Etapa 1: Tentando Google Sheets...');
      final configSheets = await _carregarDoGoogleSheets();
      if (configSheets.isNotEmpty) {
        print('✅ [DropsConfigService] SUCESSO! Configuração carregada do Google Sheets: ${configSheets.length} itens');
        return configSheets;
      }
      print('❌ [DropsConfigService] Google Sheets falhou ou vazio');
      
      // Fallback para JSON se existir
      print('📄 [DropsConfigService] Etapa 2: Tentando JSON do Google Drive como fallback...');
      final configJson = await _carregarDoJson();
      if (configJson.isNotEmpty) {
        print('✅ [DropsConfigService] SUCESSO! Configuração carregada do JSON: ${configJson.length} itens');
        return configJson;
      }
      print('❌ [DropsConfigService] JSON também falhou ou vazio');
      
      // Se tudo falhar, usa configuração padrão
      print('⚠️ [DropsConfigService] Etapa 3: Usando configuração HARDCODED padrão');
      final configPadrao = _obterConfiguracaoPadrao();
      
      print('✅ [DropsConfigService] Configuração padrão carregada: ${configPadrao.length} itens');
      print('🚀 [DropsConfigService] =====================================');
      return configPadrao;
      
    } catch (e) {
      print('❌ [DropsConfigService] ERRO CRÍTICO no carregamento: $e');
      print('❌ [DropsConfigService] Stack trace: ${StackTrace.current}');
      
      // Fallback para configuração padrão
      final configPadrao = _obterConfiguracaoPadrao();
      print('🚀 [DropsConfigService] Usando configuração padrão como último recurso');
      return configPadrao;
    }
  }
  
  /// Carrega configuração do Google Sheets
  Future<List<DropConfig>> _carregarDoGoogleSheets() async {
    try {
      print('📊 [DropsConfigService] Tentando carregar do Google Sheets...');
      
      // Configura ID da planilha se disponível
      if (DropsTempConfig.SPREADSHEET_ID != null) {
        print('📊 [DropsConfigService] Configurando ID da planilha: ${DropsTempConfig.SPREADSHEET_ID}');
        _sheetsService.definirIdPlanilha(DropsTempConfig.SPREADSHEET_ID!);
      }
      
      // Verifica se ID da planilha foi configurado
      if (_sheetsService.spreadsheetId == null) {
        print('⚠️ [DropsConfigService] ID da planilha não configurado em DropsTempConfig.SPREADSHEET_ID');
        return [];
      }
      
      print('📊 [DropsConfigService] ID da planilha configurado, iniciando leitura...');
      return await _sheetsService.lerDadosDaPlanilha();
      
    } catch (e) {
      print('❌ [DropsConfigService] Erro ao carregar do Google Sheets: $e');
      return [];
    }
  }
  
  /// Carrega configuração do arquivo JSON (convertido do Excel)
  Future<List<DropConfig>> _carregarDoJson() async {
    try {
      print('📄 [DropsConfigService] ========================================');
      print('📄 [DropsConfigService] INICIANDO BUSCA DO JSON NO GOOGLE DRIVE');
      print('📄 [DropsConfigService] Arquivo: $_jsonConfigFileName');
      print('📄 [DropsConfigService] Pasta: drops');
      print('📄 [DropsConfigService] ========================================');
      
      final jsonString = await _driveService.baixarArquivoDaPasta(_jsonConfigFileName, 'drops');
      
      print('📄 [DropsConfigService] Resultado do download:');
      print('📄 [DropsConfigService] Tamanho: ${jsonString.length} caracteres');
      print('📄 [DropsConfigService] Vazio: ${jsonString.isEmpty}');
      
      if (jsonString.isEmpty) {
        print('❌ [DropsConfigService] ARQUIVO JSON VAZIO OU NÃO ENCONTRADO NO DRIVE');
        return [];
      }
      
      print('📄 [DropsConfigService] Conteúdo obtido do Drive (primeiros 200 chars):');
      print('📄 [DropsConfigService] ${jsonString.length > 200 ? jsonString.substring(0, 200) + '...' : jsonString}');
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final itens = (jsonData['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      
      print('📄 [DropsConfigService] JSON decodificado:');
      print('📄 [DropsConfigService] Chaves encontradas: ${jsonData.keys.toList()}');
      print('📄 [DropsConfigService] Quantidade de itens: ${itens.length}');
      
      if (itens.isEmpty) {
        print('⚠️ [DropsConfigService] JSON ENCONTRADO MAS SEM ITENS');
        return [];
      }
      
      final configs = itens.map((item) {
        print('📄 [DropsConfigService] Processando item: ${item['nome']} - ${item['raridade']}');
        return DropConfig.fromJson(item);
      }).toList();
      
      print('✅ [DropsConfigService] SUCESSO! ${configs.length} itens carregados do JSON DO DRIVE');
      print('📄 [DropsConfigService] ========================================');
      
      return configs;
    } catch (e) {
      print('❌ [DropsConfigService] ERRO CRÍTICO ao carregar JSON: $e');
      print('❌ [DropsConfigService] Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  /// Retorna configuração padrão baseada no arquivo Excel criado
  List<DropConfig> _obterConfiguracaoPadrao() {
    return [
      // Consumíveis
      const DropConfig(
        nome: 'Poção de Vida Menor',
        descricao: 'Restaura 50 pontos de vida',
        tipo: 'consumivel',
        quantidade: 1,
        raridade: 'normal',
      ),
      const DropConfig(
        nome: 'Poção de Vida Suprema',
        descricao: 'Restaura toda a vida instantaneamente',
        tipo: 'consumivel',
        quantidade: 1,
        raridade: 'epico',
      ),
      const DropConfig(
        nome: 'Elixir da Imortalidade',
        descricao: 'Concede vida infinita por 30 segundos',
        tipo: 'consumivel',
        quantidade: 1,
        raridade: 'lendario',
      ),
      
      // Upgrades
      const DropConfig(
        nome: 'Cristal de Poder Menor',
        descricao: 'Aumenta +1 em um atributo aleatório',
        tipo: 'upgrade',
        quantidade: 1,
        raridade: 'raro',
      ),
      const DropConfig(
        nome: 'Cristal de Poder Supremo',
        descricao: 'Aumenta +2 em todos os atributos',
        tipo: 'upgrade',
        quantidade: 1,
        raridade: 'epico',
      ),
      const DropConfig(
        nome: 'Essência Divina',
        descricao: 'Aumenta +5 em todos os atributos permanentemente',
        tipo: 'upgrade',
        quantidade: 1,
        raridade: 'lendario',
      ),
      
      // Moedas
      const DropConfig(
        nome: 'Moedas de Cobre',
        descricao: 'Moedas básicas de aventura',
        tipo: 'moeda',
        quantidade: 50,
        raridade: 'inferior',
      ),
      const DropConfig(
        nome: 'Moedas de Prata',
        descricao: 'Moedas valiosas de aventura',
        tipo: 'moeda',
        quantidade: 100,
        raridade: 'normal',
      ),
      const DropConfig(
        nome: 'Moedas de Ouro',
        descricao: 'Moedas preciosas de aventura',
        tipo: 'moeda',
        quantidade: 250,
        raridade: 'raro',
      ),
      
      // Materiais
      const DropConfig(
        nome: 'Ferro Bruto',
        descricao: 'Material básico para crafting',
        tipo: 'material',
        quantidade: 5,
        raridade: 'inferior',
      ),
      const DropConfig(
        nome: 'Cristal Mágico',
        descricao: 'Material raro com propriedades mágicas',
        tipo: 'material',
        quantidade: 2,
        raridade: 'raro',
      ),
      const DropConfig(
        nome: 'Fragmento Celestial',
        descricao: 'Material lendário dos deuses',
        tipo: 'material',
        quantidade: 1,
        raridade: 'lendario',
      ),
      
      // Especiais
      const DropConfig(
        nome: 'Chave Misteriosa',
        descricao: 'Abre portas secretas nas aventuras',
        tipo: 'especial',
        quantidade: 1,
        raridade: 'raro',
      ),
      const DropConfig(
        nome: 'Pergaminho Antigo',
        descricao: 'Revela segredos do mundo TechTerra',
        tipo: 'especial',
        quantidade: 1,
        raridade: 'epico',
      ),
      const DropConfig(
        nome: 'Relíquia dos Ancestrais',
        descricao: 'Artefato com poder incalculável',
        tipo: 'especial',
        quantidade: 1,
        raridade: 'lendario',
      ),
    ];
  }
  
  /// Sorteia itens baseado na configuração atual (sempre recarrega do Drive)
  Future<List<DropConfig>> sortearDrops({int quantidadeItens = 3}) async {
    // SEMPRE recarrega configuração do Drive antes de sortear
    final configuracaoAtual = await carregarConfiguracaoDrops();
    
    if (configuracaoAtual.isEmpty) {
      print('⚠️ [DropsConfigService] Nenhuma configuração disponível');
      return [];
    }
    
    final itensSorteados = <DropConfig>[];
    final random = DateTime.now().millisecondsSinceEpoch; // Seed básico
    
    for (int i = 0; i < quantidadeItens; i++) {
      // Sorteia raridade baseado nos pesos
      final raridadeSorteada = _sortearRaridade(random + i);
      
      // Filtra itens da raridade sorteada
      final itensDisponiveis = configuracaoAtual
          .where((drop) => RaridadeDrop.fromString(drop.raridade) == raridadeSorteada)
          .toList();
      
      if (itensDisponiveis.isNotEmpty) {
        final index = (random + i * 7) % itensDisponiveis.length;
        itensSorteados.add(itensDisponiveis[index]);
      }
    }
    
    print('🎲 [DropsConfigService] Itens sorteados: ${itensSorteados.length}');
    return itensSorteados;
  }
  
  /// Sorteia raridade baseado nos pesos do GeradorNomesItens
  RaridadeDrop _sortearRaridade(int seed) {
    final random = seed % 100;
    
    if (random < 35) return RaridadeDrop.inferior;  // 0-34: 35%
    if (random < 65) return RaridadeDrop.normal;    // 35-64: 30%  
    if (random < 85) return RaridadeDrop.raro;      // 65-84: 20%
    if (random < 95) return RaridadeDrop.epico;     // 85-94: 10%
    return RaridadeDrop.lendario;                   // 95-99: 5%
  }
  
  /// Define o ID da planilha Google Sheets
  void definirIdPlanilha(String spreadsheetId) {
    _sheetsService.definirIdPlanilha(spreadsheetId);
    print('📋 [DropsConfigService] ID da planilha configurado');
  }
  
  /// Verifica se a planilha Google Sheets está acessível
  Future<bool> verificarAcessoSheets() async {
    return await _sheetsService.verificarAcessoPlanilha();
  }
  
  /// Obtém informações da planilha Google Sheets
  Future<Map<String, dynamic>?> obterInfoPlanilha() async {
    return await _sheetsService.obterInfoPlanilha();
  }
}