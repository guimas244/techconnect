import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mascote.dart';
import '../models/mascote_morto.dart';
import '../models/inventario_criadouro.dart';
import '../models/config_criadouro.dart';
import '../models/level_tipo.dart';

/// Serviço de persistência do Criadouro usando Hive
class CriadouroHiveService {
  static const String _boxName = 'criadouro';
  static CriadouroHiveService? _instance;
  Box<String>? _box;

  // Singleton pattern
  factory CriadouroHiveService() {
    _instance ??= CriadouroHiveService._internal();
    return _instance!;
  }

  CriadouroHiveService._internal();

  /// Inicializa o HIVE service
  Future<void> init() async {
    if (_box != null) {
      print('✅ [CriadouroHiveService] Box criadouro já inicializado');
      return;
    }

    try {
      _box = await Hive.openBox<String>(_boxName);
      print('✅ [CriadouroHiveService] Box criadouro inicializado');
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao inicializar box: $e');
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

  /// Gera a chave para armazenamento: criadouro_email
  String _gerarChave(String email) {
    return 'criadouro_$email';
  }

  /// Salva todos os dados do criadouro de um jogador
  Future<bool> salvarCriadouro({
    required String email,
    required Map<String, Mascote> mascotes,
    required Map<String, LevelTipo> niveis,
    required List<MascoteMorto> memorial,
    required InventarioCriadouro inventario,
    required ConfigCriadouro config,
    required int teks,
  }) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      // Converte mascotes para JSON
      final mascotesJson = <String, dynamic>{};
      for (final entry in mascotes.entries) {
        mascotesJson[entry.key] = entry.value.toJson();
      }

      // Converte níveis para JSON
      final niveisJson = <String, dynamic>{};
      for (final entry in niveis.entries) {
        niveisJson[entry.key] = entry.value.toJson();
      }

      final dados = {
        'email': email,
        'mascotes': mascotesJson,
        'niveis': niveisJson,
        'memorial': memorial.map((m) => m.toJson()).toList(),
        'inventario': inventario.toJson(),
        'config': config.toJson(),
        'teks': teks,
        'ultima_atualizacao': DateTime.now().toIso8601String(),
      };

      final json = jsonEncode(dados);
      await box.put(chave, json);

      print('✅ [CriadouroHiveService] Criadouro salvo para $email: ${mascotes.length} mascotes');
      return true;
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao salvar criadouro: $e');
      return false;
    }
  }

  /// Carrega todos os dados do criadouro de um jogador
  Future<CriadouroData?> carregarCriadouro(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);

      final jsonString = box.get(chave);
      if (jsonString == null) {
        print('📭 [CriadouroHiveService] Nenhum criadouro encontrado para $email');
        return null;
      }

      final dados = jsonDecode(jsonString) as Map<String, dynamic>;

      // Converte mascotes de JSON
      final mascotesJson = dados['mascotes'] as Map<String, dynamic>? ?? {};
      final mascotes = <String, Mascote>{};
      for (final entry in mascotesJson.entries) {
        mascotes[entry.key] = Mascote.fromJson(entry.value as Map<String, dynamic>);
      }

      // Converte níveis de JSON
      final niveisJson = dados['niveis'] as Map<String, dynamic>? ?? {};
      final niveis = <String, LevelTipo>{};
      for (final entry in niveisJson.entries) {
        niveis[entry.key] = LevelTipo.fromJson(entry.value as Map<String, dynamic>);
      }

      // Converte memorial
      final memorialJson = dados['memorial'] as List<dynamic>? ?? [];
      final memorial = memorialJson
          .map((m) => MascoteMorto.fromJson(m as Map<String, dynamic>))
          .toList();

      // Converte inventário
      final inventarioJson = dados['inventario'] as Map<String, dynamic>?;
      final inventario = inventarioJson != null
          ? InventarioCriadouro.fromJson(inventarioJson)
          : const InventarioCriadouro();

      // Converte config
      final configJson = dados['config'] as Map<String, dynamic>?;
      final config = configJson != null
          ? ConfigCriadouro.fromJson(configJson)
          : const ConfigCriadouro();

      final teks = dados['teks'] as int? ?? 0;

      print('✅ [CriadouroHiveService] Criadouro carregado para $email: ${mascotes.length} mascotes');

      return CriadouroData(
        mascotes: mascotes,
        niveis: niveis,
        memorial: memorial,
        inventario: inventario,
        config: config,
        teks: teks,
      );
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao carregar criadouro: $e');
      return null;
    }
  }

  /// Salva apenas um mascote específico (por tipo)
  Future<bool> salvarMascote(String email, Mascote mascote) async {
    try {
      final dados = await carregarCriadouro(email);
      final mascotes = dados?.mascotes ?? {};
      mascotes[mascote.tipo] = mascote;

      return await salvarCriadouro(
        email: email,
        mascotes: mascotes,
        niveis: dados?.niveis ?? {},
        memorial: dados?.memorial ?? [],
        inventario: dados?.inventario ?? const InventarioCriadouro(),
        config: dados?.config ?? const ConfigCriadouro(),
        teks: dados?.teks ?? 0,
      );
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao salvar mascote: $e');
      return false;
    }
  }

  /// Remove um mascote específico (por tipo)
  Future<bool> removerMascote(String email, String tipo) async {
    try {
      final dados = await carregarCriadouro(email);
      if (dados == null) return false;

      final mascotes = Map<String, Mascote>.from(dados.mascotes);
      mascotes.remove(tipo);

      return await salvarCriadouro(
        email: email,
        mascotes: mascotes,
        niveis: dados.niveis,
        memorial: dados.memorial,
        inventario: dados.inventario,
        config: dados.config,
        teks: dados.teks,
      );
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao remover mascote: $e');
      return false;
    }
  }

  /// Verifica se existe criadouro para um jogador
  Future<bool> temCriadouro(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);
      return box.containsKey(chave);
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao verificar criadouro: $e');
      return false;
    }
  }

  /// Atualiza apenas os teks
  Future<bool> atualizarTeks(String email, int teks) async {
    try {
      final dados = await carregarCriadouro(email);

      return await salvarCriadouro(
        email: email,
        mascotes: dados?.mascotes ?? {},
        niveis: dados?.niveis ?? {},
        memorial: dados?.memorial ?? [],
        inventario: dados?.inventario ?? const InventarioCriadouro(),
        config: dados?.config ?? const ConfigCriadouro(),
        teks: teks,
      );
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao atualizar teks: $e');
      return false;
    }
  }

  /// Limpa o criadouro de um jogador
  Future<bool> limparCriadouro(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);
      await box.delete(chave);
      print('✅ [CriadouroHiveService] Criadouro removido para $email');
      return true;
    } catch (e) {
      print('❌ [CriadouroHiveService] Erro ao remover criadouro: $e');
      return false;
    }
  }
}

/// Classe para transportar dados do criadouro
class CriadouroData {
  final Map<String, Mascote> mascotes;
  final Map<String, LevelTipo> niveis;
  final List<MascoteMorto> memorial;
  final InventarioCriadouro inventario;
  final ConfigCriadouro config;
  final int teks;

  const CriadouroData({
    required this.mascotes,
    required this.niveis,
    required this.memorial,
    required this.inventario,
    required this.config,
    required this.teks,
  });
}
