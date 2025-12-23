import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/equipe_explorador.dart';

/// Service para persistir equipe do Explorador usando Hive
class EquipeHiveService {
  static const String _boxName = 'equipe_explorador_box';
  static EquipeHiveService? _instance;
  Box<String>? _box;

  EquipeHiveService._();

  factory EquipeHiveService() {
    _instance ??= EquipeHiveService._();
    return _instance!;
  }

  /// Inicializa o Hive box
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    try {
      _box = await Hive.openBox<String>(_boxName);
      print('[EquipeHiveService] Box inicializada');
    } catch (e) {
      print('[EquipeHiveService] Erro ao inicializar box: $e');
      rethrow;
    }
  }

  /// Garante que o box esta aberto
  Future<Box<String>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Chave para armazenar equipe do usuario
  String _getKey(String email) => 'equipe_$email';

  /// Carrega equipe do usuario
  Future<EquipeExplorador?> carregarEquipe(String email) async {
    try {
      final box = await _getBox();
      final json = box.get(_getKey(email));

      if (json == null || json.isEmpty) {
        print('[EquipeHiveService] Nenhuma equipe encontrada para $email');
        return null;
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      final equipe = EquipeExplorador.fromJson(data);
      print('[EquipeHiveService] Equipe carregada: ${equipe.totalMonstros} monstros');
      return equipe;
    } catch (e) {
      print('[EquipeHiveService] Erro ao carregar equipe: $e');
      return null;
    }
  }

  /// Salva equipe do usuario
  Future<bool> salvarEquipe(String email, EquipeExplorador equipe) async {
    try {
      final box = await _getBox();
      final json = jsonEncode(equipe.toJson());
      await box.put(_getKey(email), json);
      print('[EquipeHiveService] Equipe salva: ${equipe.totalMonstros} monstros');
      return true;
    } catch (e) {
      print('[EquipeHiveService] Erro ao salvar equipe: $e');
      return false;
    }
  }

  /// Remove equipe do usuario
  Future<bool> removerEquipe(String email) async {
    try {
      final box = await _getBox();
      await box.delete(_getKey(email));
      print('[EquipeHiveService] Equipe removida para $email');
      return true;
    } catch (e) {
      print('[EquipeHiveService] Erro ao remover equipe: $e');
      return false;
    }
  }

  /// Verifica se usuario tem equipe salva
  Future<bool> temEquipe(String email) async {
    try {
      final box = await _getBox();
      return box.containsKey(_getKey(email));
    } catch (e) {
      return false;
    }
  }
}
