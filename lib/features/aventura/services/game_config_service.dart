import 'dart:convert';
import '../../../core/services/google_drive_service.dart';

/// Modelo para configuração de um drop individual
class DropChanceConfig {
  final String id;
  final String nome;
  final double chance; // porcentagem (0.0 - 100.0)
  final String categoria; // 'drop', 'consumivel', 'evento'
  final bool ativo;

  const DropChanceConfig({
    required this.id,
    required this.nome,
    required this.chance,
    required this.categoria,
    this.ativo = true,
  });

  factory DropChanceConfig.fromJson(Map<String, dynamic> json) {
    return DropChanceConfig(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      chance: (json['chance'] as num?)?.toDouble() ?? 0.0,
      categoria: json['categoria'] ?? 'drop',
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'chance': chance,
      'categoria': categoria,
      'ativo': ativo,
    };
  }

  DropChanceConfig copyWith({
    String? id,
    String? nome,
    double? chance,
    String? categoria,
    bool? ativo,
  }) {
    return DropChanceConfig(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      chance: chance ?? this.chance,
      categoria: categoria ?? this.categoria,
      ativo: ativo ?? this.ativo,
    );
  }
}

/// Modelo para configuração geral do jogo
class GameConfig {
  final String versao;
  final String atualizadoEm;
  final double multiplicadorDrop; // 1x, 2x, etc
  final List<DropChanceConfig> drops;

  const GameConfig({
    required this.versao,
    required this.atualizadoEm,
    required this.multiplicadorDrop,
    required this.drops,
  });

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      versao: json['versao'] ?? '1.0',
      atualizadoEm: json['atualizadoEm'] ?? '',
      multiplicadorDrop: (json['multiplicadorDrop'] as num?)?.toDouble() ?? 1.0,
      drops: (json['drops'] as List<dynamic>?)
              ?.map((e) => DropChanceConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'versao': versao,
      'atualizadoEm': atualizadoEm,
      'multiplicadorDrop': multiplicadorDrop,
      'drops': drops.map((e) => e.toJson()).toList(),
    };
  }

  GameConfig copyWith({
    String? versao,
    String? atualizadoEm,
    double? multiplicadorDrop,
    List<DropChanceConfig>? drops,
  }) {
    return GameConfig(
      versao: versao ?? this.versao,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      multiplicadorDrop: multiplicadorDrop ?? this.multiplicadorDrop,
      drops: drops ?? this.drops,
    );
  }

  /// Retorna a configuração padrão com todos os drops
  static GameConfig padrao() {
    return GameConfig(
      versao: '1.0',
      atualizadoEm: DateTime.now().toIso8601String(),
      multiplicadorDrop: 1.0,
      drops: [
        // === DROPS DE BATALHA ===
        const DropChanceConfig(
          id: 'pocaoVidaPequena',
          nome: 'Poção de Vida Pequena',
          chance: 5.0,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'pocaoVidaGrande',
          nome: 'Poção de Vida Grande',
          chance: 2.0,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'pedraRecriacao',
          nome: 'Joia da Recriação',
          chance: 2.0,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'joiaReforco',
          nome: 'Joia de Reforço',
          chance: 1.0,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'frutaNuty',
          nome: 'Fruta Nuty',
          chance: 0.5,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'frutaNutyCristalizada',
          nome: 'Fruta Nuty Cristalizada',
          chance: 0.5,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'frutaNutyNegra',
          nome: 'Fruta Nuty Negra',
          chance: 0.5,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'vidinha',
          nome: 'Vidinha',
          chance: 0.5,
          categoria: 'drop',
        ),
        const DropChanceConfig(
          id: 'jaulinha',
          nome: 'Jaulinha',
          chance: 0.2,
          categoria: 'drop',
        ),

        // === CONSUMÍVEIS DE EVENTO ===
        const DropChanceConfig(
          id: 'moedaEvento',
          nome: 'Moeda de Evento (Halloween)',
          chance: 5.0,
          categoria: 'evento',
          ativo: false, // Evento inativo
        ),
        const DropChanceConfig(
          id: 'ovoEvento',
          nome: 'Ovo de Evento',
          chance: 3.0,
          categoria: 'evento',
        ),
        const DropChanceConfig(
          id: 'moedaChave',
          nome: 'Moeda Chave',
          chance: 5.0,
          categoria: 'evento',
        ),
        const DropChanceConfig(
          id: 'chaveAuto',
          nome: 'Chave Auto',
          chance: 1.0,
          categoria: 'evento',
        ),

        // === RECOMPENSAS DE ANDAR ===
        const DropChanceConfig(
          id: 'recompensaAndar',
          nome: 'Recompensa de Andar',
          chance: 100.0,
          categoria: 'andar',
          ativo: true,
        ),
      ],
    );
  }
}

/// Service para gerenciar configurações do jogo no Google Drive
class GameConfigService {
  static final GameConfigService _instance = GameConfigService._internal();
  factory GameConfigService() => _instance;
  GameConfigService._internal();

  final GoogleDriveService _driveService = GoogleDriveService();
  static const String _configFileName = 'game_config.json';
  static const String _configFolder = 'configuracoes';

  GameConfig? _cachedConfig;
  DateTime? _lastFetch;

  /// Carrega a configuração do jogo (do cache ou do Drive)
  Future<GameConfig> carregarConfiguracao({bool forceRefresh = false}) async {
    // Usa cache se disponível e não expirou (5 minutos)
    if (!forceRefresh &&
        _cachedConfig != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      print('📦 [GameConfigService] Usando configuração em cache');
      return _cachedConfig!;
    }

    try {
      print('🔍 [GameConfigService] Carregando configuração do Drive...');

      // Garante conexão
      if (!_driveService.isConectado) {
        await _driveService.inicializarConexao();
      }

      // Tenta baixar do Drive
      final conteudo = await _driveService.baixarArquivoDaPasta(
        _configFileName,
        _configFolder,
      );

      if (conteudo.isNotEmpty) {
        final json = jsonDecode(conteudo) as Map<String, dynamic>;
        _cachedConfig = GameConfig.fromJson(json);
        _lastFetch = DateTime.now();
        print('✅ [GameConfigService] Configuração carregada do Drive');
        return _cachedConfig!;
      }

      // Se não existe, cria configuração padrão
      print('📝 [GameConfigService] Criando configuração padrão no Drive...');
      _cachedConfig = GameConfig.padrao();
      await _salvarConfiguracao(_cachedConfig!);
      _lastFetch = DateTime.now();
      return _cachedConfig!;
    } catch (e) {
      print('❌ [GameConfigService] Erro ao carregar: $e');
      // Retorna configuração padrão em caso de erro
      return GameConfig.padrao();
    }
  }

  /// Salva a configuração no Drive
  Future<bool> _salvarConfiguracao(GameConfig config) async {
    try {
      final jsonData = config.toJson();
      final conteudo = jsonEncode(jsonData);

      // Usa o método de salvar em pasta do GoogleDriveService
      return await _driveService.salvarArquivoEmPasta(
        _configFileName,
        conteudo,
        _configFolder,
      );
    } catch (e) {
      print('❌ [GameConfigService] Erro ao salvar: $e');
      return false;
    }
  }

  /// Retorna o multiplicador de drop atual
  Future<double> obterMultiplicadorDrop() async {
    final config = await carregarConfiguracao();
    return config.multiplicadorDrop;
  }

  /// Retorna a chance de um drop específico (já com multiplicador aplicado)
  Future<double> obterChanceDrop(String dropId) async {
    final config = await carregarConfiguracao();
    final dropConfig = config.drops.firstWhere(
      (d) => d.id == dropId,
      orElse: () => const DropChanceConfig(
        id: '',
        nome: '',
        chance: 0.0,
        categoria: 'drop',
      ),
    );

    if (!dropConfig.ativo) return 0.0;

    return dropConfig.chance * config.multiplicadorDrop;
  }

  /// Retorna todas as configurações de drops
  Future<List<DropChanceConfig>> obterTodasChances() async {
    final config = await carregarConfiguracao();
    return config.drops;
  }

  /// Invalida o cache para forçar recarregamento
  void invalidarCache() {
    _cachedConfig = null;
    _lastFetch = null;
    print('🗑️ [GameConfigService] Cache invalidado');
  }

  /// Verifica se a pasta de configurações existe e cria se necessário
  Future<bool> inicializarPastaConfiguracoes() async {
    try {
      print('📁 [GameConfigService] Verificando pasta de configurações...');

      if (!_driveService.isConectado) {
        await _driveService.inicializarConexao();
      }

      // Tenta carregar - se não existir, será criada
      await carregarConfiguracao();

      print('✅ [GameConfigService] Pasta de configurações pronta');
      return true;
    } catch (e) {
      print('❌ [GameConfigService] Erro ao inicializar pasta: $e');
      return false;
    }
  }
}