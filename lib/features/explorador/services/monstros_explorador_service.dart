import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/monstro_explorador.dart';

/// Service para persistir monstros individuais do Explorador
/// Cada monstro tem seu proprio XP e level, mesmo que tenha o mesmo tipo
class MonstrosExploradorService {
  static const String _boxName = 'monstros_explorador_box';
  static MonstrosExploradorService? _instance;
  Box<String>? _box;

  MonstrosExploradorService._();

  factory MonstrosExploradorService() {
    _instance ??= MonstrosExploradorService._();
    return _instance!;
  }

  /// Inicializa o Hive box
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    try {
      _box = await Hive.openBox<String>(_boxName);
      print('[MonstrosExploradorService] Box inicializada');
    } catch (e) {
      print('[MonstrosExploradorService] Erro ao inicializar box: $e');
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

  /// Chave para armazenar lista de monstros do usuario
  String _getKey(String email) => 'monstros_$email';

  /// Carrega todos os monstros salvos do usuario
  Future<List<MonstroExplorador>> carregarMonstros(String email) async {
    try {
      final box = await _getBox();
      final json = box.get(_getKey(email));

      if (json == null || json.isEmpty) {
        print('[MonstrosExploradorService] Nenhum monstro encontrado para $email');
        return [];
      }

      final data = jsonDecode(json) as List<dynamic>;
      final monstros = data
          .map((m) => MonstroExplorador.fromJson(m as Map<String, dynamic>))
          .toList();
      print('[MonstrosExploradorService] ${monstros.length} monstros carregados');
      return monstros;
    } catch (e) {
      print('[MonstrosExploradorService] Erro ao carregar monstros: $e');
      return [];
    }
  }

  /// Salva todos os monstros do usuario
  Future<bool> salvarMonstros(String email, List<MonstroExplorador> monstros) async {
    try {
      final box = await _getBox();
      final json = jsonEncode(monstros.map((m) => m.toJson()).toList());
      await box.put(_getKey(email), json);
      print('[MonstrosExploradorService] ${monstros.length} monstros salvos');
      return true;
    } catch (e) {
      print('[MonstrosExploradorService] Erro ao salvar monstros: $e');
      return false;
    }
  }

  /// Salva um monstro individual (adiciona ou atualiza)
  Future<bool> salvarMonstro(String email, MonstroExplorador monstro) async {
    try {
      final monstros = await carregarMonstros(email);

      // Remove o monstro antigo se existir (pelo ID)
      monstros.removeWhere((m) => m.id == monstro.id);

      // Adiciona o monstro atualizado
      monstros.add(monstro);

      return await salvarMonstros(email, monstros);
    } catch (e) {
      print('[MonstrosExploradorService] Erro ao salvar monstro: $e');
      return false;
    }
  }

  /// Carrega um monstro especifico pelo ID
  Future<MonstroExplorador?> carregarMonstro(String email, String monstroId) async {
    try {
      final monstros = await carregarMonstros(email);
      return monstros.where((m) => m.id == monstroId).firstOrNull;
    } catch (e) {
      print('[MonstrosExploradorService] Erro ao carregar monstro: $e');
      return null;
    }
  }

  /// Remove um monstro pelo ID
  Future<bool> removerMonstro(String email, String monstroId) async {
    try {
      final monstros = await carregarMonstros(email);
      monstros.removeWhere((m) => m.id == monstroId);
      return await salvarMonstros(email, monstros);
    } catch (e) {
      print('[MonstrosExploradorService] Erro ao remover monstro: $e');
      return false;
    }
  }

  /// Lista monstros salvos que NAO estao na equipe atual
  /// (para mostrar na tela de adicionar monstros)
  Future<List<MonstroExplorador>> listarMonstrosDisponiveis(
    String email,
    List<String> idsNaEquipe,
  ) async {
    try {
      final monstros = await carregarMonstros(email);
      return monstros.where((m) => !idsNaEquipe.contains(m.id)).toList();
    } catch (e) {
      print('[MonstrosExploradorService] Erro ao listar monstros disponiveis: $e');
      return [];
    }
  }
}
