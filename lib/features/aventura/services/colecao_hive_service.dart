import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class ColecaoHiveService {
  static const String _boxName = 'colecoes';
  static ColecaoHiveService? _instance;
  Box<String>? _box;

  // Singleton pattern
  factory ColecaoHiveService() {
    _instance ??= ColecaoHiveService._internal();
    return _instance!;
  }

  ColecaoHiveService._internal();

  /// Inicializa o HIVE service
  Future<void> init() async {
    if (_box != null) {
      print('✅ [ColecaoHiveService] Box coleções já inicializado');
      return;
    }

    try {
      _box = await Hive.openBox<String>(_boxName);
      print('✅ [ColecaoHiveService] Box coleções inicializado');
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao inicializar box: $e');
      rethrow;
    }
  }

  /// Garante que o box está inicializado antes de usar
  Future<Box<String>> _getBox() async {
    if (_box == null) {
      await init();
    }
    return _box!;
  }

  /// Gera a chave para armazenamento: colecao_email
  String _gerarChave(String email) {
    return 'colecao_$email';
  }

  /// Salva a coleção de um jogador no HIVE
  Future<bool> salvarColecao(String email, Map<String, bool> colecao) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      final dados = {
        'email': email,
        'monstros': colecao,
        'ultima_atualizacao': DateTime.now().toIso8601String(),
        'sincronizado_drive': false, // Marca se foi sincronizado com Drive
      };

      final json = jsonEncode(dados);
      await box.put(chave, json);

      print('✅ [ColecaoHiveService] Coleção salva para $email: ${colecao.length} monstros');
      return true;
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao salvar coleção: $e');
      return false;
    }
  }

  /// Carrega a coleção de um jogador do HIVE
  Future<Map<String, bool>?> carregarColecao(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      final jsonString = box.get(chave);
      if (jsonString == null) {
        print('📭 [ColecaoHiveService] Nenhuma coleção encontrada para $email');
        return null;
      }

      final dados = jsonDecode(jsonString) as Map<String, dynamic>;
      final colecao = Map<String, bool>.from(dados['monstros'] ?? {});

      print('✅ [ColecaoHiveService] Coleção carregada para $email: ${colecao.length} monstros');
      return colecao;
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao carregar coleção: $e');
      return null;
    }
  }

  /// Verifica se existe coleção para um jogador
  Future<bool> temColecao(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);
      return box.containsKey(chave);
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao verificar coleção: $e');
      return false;
    }
  }

  /// Marca uma coleção como sincronizada com Drive
  Future<bool> marcarComoSincronizada(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      final jsonString = box.get(chave);
      if (jsonString == null) {
        return false;
      }

      final dados = jsonDecode(jsonString) as Map<String, dynamic>;
      dados['sincronizado_drive'] = true;
      dados['ultima_sincronizacao'] = DateTime.now().toIso8601String();

      final json = jsonEncode(dados);
      await box.put(chave, json);

      print('✅ [ColecaoHiveService] Coleção marcada como sincronizada para $email');
      return true;
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao marcar como sincronizada: $e');
      return false;
    }
  }

  /// Verifica se a coleção foi sincronizada com Drive
  Future<bool> estaSincronizada(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      final jsonString = box.get(chave);
      if (jsonString == null) {
        return false;
      }

      final dados = jsonDecode(jsonString) as Map<String, dynamic>;
      return dados['sincronizado_drive'] == true;
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao verificar sincronização: $e');
      return false;
    }
  }

  /// Remove a coleção de um jogador
  Future<bool> removerColecao(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      await box.delete(chave);
      print('✅ [ColecaoHiveService] Coleção removida para $email');
      return true;
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao remover coleção: $e');
      return false;
    }
  }

  /// Lista todos os emails que têm coleções
  Future<List<String>> listarEmails() async {
    try {
      final box = await _getBox();
      final emails = <String>[];

      for (final chave in box.keys) {
        if (chave.toString().startsWith('colecao_')) {
          final email = chave.toString().substring(8); // Remove 'colecao_'
          emails.add(email);
        }
      }

      print('📋 [ColecaoHiveService] Encontrados ${emails.length} emails com coleções');
      return emails;
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao listar emails: $e');
      return [];
    }
  }

  /// Lista dos 30 monstros nostálgicos
  static List<String> get monstrosNostalgicos => [
    'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
    'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
    'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
    'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
    'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi'
  ];

  /// Lista dos 30 monstros de Halloween
  static List<String> get monstrosHalloween => [
    'abobora', 'aranha', 'bruxa', 'caldeira', 'caveira',
    'cemiterio', 'corvo', 'espantalho', 'esqueleto', 'foice',
    'gato_preto', 'grimorio', 'lobisomem', 'lua_cheia', 'mansao',
    'mascara', 'morcego', 'morto_vivo', 'mumia', 'noite',
    'olho', 'ouija', 'pocao', 'sombra', 'tesoura',
    'tumba', 'vampiro', 'vassoura', 'vela', 'veneno'
  ];

  /// Cria uma coleção inicial com todos os monstros bloqueados
  Map<String, bool> criarColecaoInicial() {
    final colecaoInicial = <String, bool>{};

    // Adiciona nostálgicos
    for (final monstro in monstrosNostalgicos) {
      colecaoInicial[monstro] = false;
    }

    // Adiciona Halloween (prefixo halloween_ para diferenciar)
    for (final monstro in monstrosHalloween) {
      colecaoInicial['halloween_$monstro'] = false;
    }

    print('🆕 [ColecaoHiveService] Coleção inicial criada com ${colecaoInicial.length} monstros');
    print('   - Nostálgicos: ${monstrosNostalgicos.length}');
    print('   - Halloween: ${monstrosHalloween.length}');
    return colecaoInicial;
  }

  /// Limpa todas as coleções (para debug)
  Future<bool> limparTodasColecoes() async {
    try {
      final box = await _getBox();
      await box.clear();
      print('🗑️ [ColecaoHiveService] Todas as coleções foram removidas');
      return true;
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao limpar coleções: $e');
      return false;
    }
  }

  /// Estatísticas das coleções
  Future<Map<String, dynamic>> obterEstatisticas() async {
    try {
      final emails = await listarEmails();
      int totalMonstrosDesbloqueados = 0;
      int totalColecoes = emails.length;

      for (final email in emails) {
        final colecao = await carregarColecao(email);
        if (colecao != null) {
          totalMonstrosDesbloqueados += colecao.values.where((desbloqueado) => desbloqueado).length;
        }
      }

      return {
        'total_colecoes': totalColecoes,
        'total_monstros_desbloqueados': totalMonstrosDesbloqueados,
        'media_monstros_por_colecao': totalColecoes > 0 ? (totalMonstrosDesbloqueados / totalColecoes).toStringAsFixed(2) : '0',
      };
    } catch (e) {
      print('❌ [ColecaoHiveService] Erro ao obter estatísticas: $e');
      return {};
    }
  }
}