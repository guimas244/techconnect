import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/drop.dart';

class DropsService {
  static const String _dropsKey = 'jogador_drops';
  static const String _configKey = 'drops_config';
  static const int maxSlots = 3;

  /// Sorteia um drop baseado nas porcentagens configuradas
  /// Retorna null se não ganhou nenhum drop
  static Future<Drop?> sortearDrop() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);

    if (configJson == null) {
      // Usa valores padrão se não houver configuração
      // Ordem: do mais raro (menor %) para o menos raro (maior %)
      return _sortearComPorcentagens({
        TipoDrop.frutaNuty: 0.5,           // 0.5% - Lendário (prioridade 1)
        TipoDrop.joiaReforco: 1.0,         // 1% - Épico (prioridade 2)
        TipoDrop.pocaoVidaGrande: 2.0,     // 2% - Épico (prioridade 3)
        TipoDrop.pedraRecriacao: 2.0,      // 2% - Lendário (prioridade 4)
        TipoDrop.pocaoVidaPequena: 5.0,    // 5% - Inferior (prioridade 5)
      });
    }

    final Map<String, dynamic> configMap = jsonDecode(configJson);
    final Map<TipoDrop, double> porcentagens = {};

    for (final entry in configMap.entries) {
      final tipo = TipoDrop.values.firstWhere((t) => t.id == entry.key);
      porcentagens[tipo] = (entry.value as num).toDouble();
    }

    return _sortearComPorcentagens(porcentagens);
  }

  static Future<Drop?> _sortearComPorcentagens(Map<TipoDrop, double> porcentagens) async {
    final random = Random();

    // Tenta sortear cada tipo de drop
    for (final entry in porcentagens.entries) {
      final chance = random.nextDouble() * 100;
      if (chance <= entry.value) {
        return Drop(tipo: entry.key, quantidade: 1);
      }
    }

    return null; // Não ganhou nenhum drop
  }

  /// Adiciona um drop à mochila do jogador
  /// Retorna true se conseguiu adicionar, false se a mochila está cheia
  static Future<bool> adicionarDrop(Drop drop) async {
    final dropsAtuais = await carregarDrops();

    print('[DropsService] 📦 Adicionando drop: ${drop.tipo.nome}');
    print('[DropsService] 📊 Drops atuais: ${dropsAtuais.length}/$maxSlots slots ocupados');
    for (var entry in dropsAtuais.entries) {
      print('[DropsService]    - ${entry.key.nome}: x${entry.value}');
    }

    // Verifica se já tem esse tipo de drop
    if (dropsAtuais.containsKey(drop.tipo)) {
      // Já tem, incrementa a quantidade ao invés de rejeitar
      print('[DropsService] ⚠️ Já existe ${drop.tipo.nome}, incrementando quantidade');
      dropsAtuais[drop.tipo] = dropsAtuais[drop.tipo]! + drop.quantidade;
      await _salvarDrops(dropsAtuais);
      print('[DropsService] ✅ Quantidade atualizada: ${dropsAtuais[drop.tipo]}');
      return true;
    }

    // Verifica se ainda tem slots disponíveis
    if (dropsAtuais.length >= maxSlots) {
      print('[DropsService] ❌ Sem slots disponíveis (${dropsAtuais.length}/$maxSlots)');
      return false; // Mochila cheia
    }

    // Adiciona o drop
    dropsAtuais[drop.tipo] = drop.quantidade;
    await _salvarDrops(dropsAtuais);
    print('[DropsService] ✅ Drop adicionado com sucesso!');
    print('[DropsService] 📊 Slots agora: ${dropsAtuais.length}/$maxSlots');
    return true;
  }

  /// Carrega os drops do jogador
  static Future<Map<TipoDrop, int>> carregarDrops() async {
    final prefs = await SharedPreferences.getInstance();
    final dropsJson = prefs.getString(_dropsKey);

    if (dropsJson == null) {
      return {};
    }

    final Map<String, dynamic> dropsMap = jsonDecode(dropsJson);
    final Map<TipoDrop, int> drops = {};

    for (final entry in dropsMap.entries) {
      try {
        final tipo = TipoDrop.values.firstWhere((t) => t.id == entry.key);
        drops[tipo] = entry.value as int;
      } catch (e) {
        print('Erro ao carregar drop: $e');
      }
    }

    return drops;
  }

  static Future<void> _salvarDrops(Map<TipoDrop, int> drops) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> dropsMap = {};

    for (final entry in drops.entries) {
      dropsMap[entry.key.id] = entry.value;
    }

    await prefs.setString(_dropsKey, jsonEncode(dropsMap));
  }

  /// Remove um drop da mochila (quando usado)
  static Future<void> removerDrop(TipoDrop tipo) async {
    final dropsAtuais = await carregarDrops();
    dropsAtuais.remove(tipo);
    await _salvarDrops(dropsAtuais);
  }

  /// Verifica quantos slots estão disponíveis
  static Future<int> slotsDisponiveis() async {
    final drops = await carregarDrops();
    return maxSlots - drops.length;
  }
}
