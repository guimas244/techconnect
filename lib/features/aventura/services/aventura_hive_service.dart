import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/historia_jogador.dart';

class AventuraHiveService {
  static const String _boxName = 'aventuras';
  static AventuraHiveService? _instance;
  Box<String>? _box;

  // Singleton pattern
  factory AventuraHiveService() {
    _instance ??= AventuraHiveService._internal();
    return _instance!;
  }

  AventuraHiveService._internal();

  /// Inicializa o HIVE service
  Future<void> init() async {
    if (_box != null) {
      print('✅ [HiveService] Box aventuras já inicializado');
      return;
    }

    try {
      _box = await Hive.openBox<String>(_boxName);
      print('✅ [HiveService] Box aventuras inicializado');
    } catch (e) {
      print('❌ [HiveService] Erro ao inicializar box: $e');
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

  /// Obtém a data atual formatada (horário Brasília)
  String _getDataAtual() {
    final hoje = DateTime.now().subtract(const Duration(hours: 3)); // Horário Brasília
    return '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
  }

  /// Gera a chave para armazenamento: email_data
  String _gerarChave(String email) {
    final dataAtual = _getDataAtual();
    return '${email}_$dataAtual';
  }

  /// Salva a aventura no HIVE
  Future<bool> salvarAventura(HistoriaJogador historia) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(historia.email);
      final json = historia.toJson();

      // Converte Map para JSON string para armazenar no HIVE
      final jsonString = jsonEncode(json);

      await box.put(chave, jsonString);
      print('✅ [HiveService] Aventura salva: $chave');
      return true;
    } catch (e) {
      print('❌ [HiveService] Erro ao salvar aventura: $e');
      return false;
    }
  }

  /// Carrega a aventura do HIVE
  Future<HistoriaJogador?> carregarAventura(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);
      final jsonString = box.get(chave);

      if (jsonString == null) {
        print('📭 [HiveService] Nenhuma aventura encontrada para: $chave');
        return null;
      }

      // Parse da string JSON de volta para Map
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final historia = HistoriaJogador.fromJson(json);

      print('✅ [HiveService] Aventura carregada: $chave');
      return historia;
    } catch (e) {
      print('❌ [HiveService] Erro ao carregar aventura: $e');
      return null;
    }
  }

  /// Verifica se existe aventura no HIVE
  Future<bool> temAventura(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);
      final existe = box.containsKey(chave);
      print('🔍 [HiveService] Aventura existe ($chave): $existe');
      return existe;
    } catch (e) {
      print('❌ [HiveService] Erro ao verificar aventura: $e');
      return false;
    }
  }

  /// Remove a aventura do HIVE
  Future<bool> removerAventura(String email) async {
    try {
      final box = await _getBox();
      final chave = _gerarChave(email);
      await box.delete(chave);
      print('🗑️ [HiveService] Aventura removida: $chave');
      return true;
    } catch (e) {
      print('❌ [HiveService] Erro ao remover aventura: $e');
      return false;
    }
  }

  /// Lista todas as aventuras armazenadas (para debug)
  Future<List<String>> listarAventuras() async {
    try {
      final box = await _getBox();
      return box.keys.cast<String>().toList();
    } catch (e) {
      print('❌ [HiveService] Erro ao listar aventuras: $e');
      return [];
    }
  }

  /// Limpa todas as aventuras (para debug)
  Future<void> limparTudo() async {
    try {
      final box = await _getBox();
      await box.clear();
      print('🧹 [HiveService] Todas as aventuras foram removidas');
    } catch (e) {
      print('❌ [HiveService] Erro ao limpar aventuras: $e');
    }
  }

}