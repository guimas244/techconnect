import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/kills_permanentes.dart';

/// Serviço de persistência para kills permanentes usando Hive
class KillsHiveService {
  static const String _boxName = 'kills_permanentes';
  static KillsHiveService? _instance;
  Box<String>? _box;

  // Singleton pattern
  factory KillsHiveService() {
    _instance ??= KillsHiveService._internal();
    return _instance!;
  }

  KillsHiveService._internal();

  /// Inicializa o HIVE service
  Future<void> init() async {
    if (_box != null) {
      print('[KillsHiveService] Box kills_permanentes ja inicializado');
      return;
    }

    try {
      _box = await Hive.openBox<String>(_boxName);
      print('[KillsHiveService] Box kills_permanentes inicializado');
    } catch (e) {
      print('[KillsHiveService] Erro ao inicializar box: $e');
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

  /// Gera a chave para armazenamento: kills_email
  String _gerarChave(String email) {
    return 'kills_$email';
  }

  /// Salva as kills permanentes de um jogador
  Future<bool> salvarKills(String email, KillsPermanentes kills) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      final dados = {
        'email': email,
        'kills': kills.toJson(),
        'ultima_atualizacao': DateTime.now().toIso8601String(),
        'sincronizado_drive': false,
      };

      final json = jsonEncode(dados);
      await box.put(chave, json);

      print('[KillsHiveService] Kills salvas para $email: total ${kills.totalKills}');
      return true;
    } catch (e) {
      print('[KillsHiveService] Erro ao salvar kills: $e');
      return false;
    }
  }

  /// Carrega as kills permanentes de um jogador
  Future<KillsPermanentes?> carregarKills(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      final jsonString = box.get(chave);
      if (jsonString == null) {
        print('[KillsHiveService] Nenhuma kill encontrada para $email');
        return null;
      }

      final dados = jsonDecode(jsonString) as Map<String, dynamic>;
      final killsJson = dados['kills'] as Map<String, dynamic>;
      final kills = KillsPermanentes.fromJson(killsJson);

      print('[KillsHiveService] Kills carregadas para $email: total ${kills.totalKills}');
      return kills;
    } catch (e) {
      print('[KillsHiveService] Erro ao carregar kills: $e');
      return null;
    }
  }

  /// Verifica se existem kills para um jogador
  Future<bool> temKills(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);
      return box.containsKey(chave);
    } catch (e) {
      print('[KillsHiveService] Erro ao verificar kills: $e');
      return false;
    }
  }

  /// Marca kills como sincronizadas com Drive
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

      print('[KillsHiveService] Kills marcadas como sincronizadas para $email');
      return true;
    } catch (e) {
      print('[KillsHiveService] Erro ao marcar como sincronizada: $e');
      return false;
    }
  }

  /// Remove as kills de um jogador
  Future<bool> removerKills(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      await box.delete(chave);
      print('[KillsHiveService] Kills removidas para $email');
      return true;
    } catch (e) {
      print('[KillsHiveService] Erro ao remover kills: $e');
      return false;
    }
  }

  /// Lista todos os emails que têm kills
  Future<List<String>> listarEmails() async {
    try {
      final box = await _getBox();
      final emails = <String>[];

      for (final chave in box.keys) {
        if (chave.toString().startsWith('kills_')) {
          final email = chave.toString().substring(6); // Remove 'kills_'
          emails.add(email);
        }
      }

      print('[KillsHiveService] Encontrados ${emails.length} emails com kills');
      return emails;
    } catch (e) {
      print('[KillsHiveService] Erro ao listar emails: $e');
      return [];
    }
  }

  /// Limpa todas as kills (para debug)
  Future<bool> limparTodasKills() async {
    try {
      final box = await _getBox();
      await box.clear();
      print('[KillsHiveService] Todas as kills foram removidas');
      return true;
    } catch (e) {
      print('[KillsHiveService] Erro ao limpar kills: $e');
      return false;
    }
  }

  /// Estatísticas das kills
  Future<Map<String, dynamic>> obterEstatisticas() async {
    try {
      final emails = await listarEmails();
      int totalKills = 0;
      int totalJogadores = emails.length;

      for (final email in emails) {
        final kills = await carregarKills(email);
        if (kills != null) {
          totalKills += kills.totalKills;
        }
      }

      return {
        'total_jogadores': totalJogadores,
        'total_kills': totalKills,
        'media_kills_por_jogador': totalJogadores > 0
            ? (totalKills / totalJogadores).toStringAsFixed(2)
            : '0',
      };
    } catch (e) {
      print('[KillsHiveService] Erro ao obter estatisticas: $e');
      return {};
    }
  }
}
