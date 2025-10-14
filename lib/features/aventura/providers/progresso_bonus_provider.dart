import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/progresso_diario.dart';
import '../../../shared/models/tipo_enum.dart';
import 'package:intl/intl.dart';

/// Provider que fornece os bônus do progresso diário (incluindo histórico válido)
final progressoBonusProvider = FutureProvider<Map<Tipo, Map<String, int>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Tenta carregar progresso salvo
  final progressoJson = prefs.getString('progresso_diario');

  if (progressoJson == null) {
    return {};
  }

  final progressoData = jsonDecode(progressoJson) as Map<String, dynamic>;
  var progresso = ProgressoDiario.fromJson(progressoData);

  // Se não é do dia de hoje, finaliza o dia anterior e cria novo dia
  if (progresso.data != hoje) {
    progresso = progresso.finalizarDia(hoje);
    // Salva o progresso atualizado
    await prefs.setString('progresso_diario', jsonEncode(progresso.toJson()));
  }

  // Carrega pontos por kill configurados
  final pontosPorKill = prefs.getInt('aventura_pontos_por_kill') ?? 2;

  // Calcula bônus para cada tipo usando kills do histórico válido + dia atual
  final bonusPorTipo = <Tipo, Map<String, int>>{};
  final killsPorTipoTotal = progresso.killsPorTipoComHistorico;

  for (final tipo in Tipo.values) {
    final kills = killsPorTipoTotal[tipo.name] ?? 0;

    if (kills == 0) {
      bonusPorTipo[tipo] = {'HP': 0, 'ATK': 0, 'DEF': 0, 'SPD': 0};
      continue;
    }

    final bonus = <String, int>{};
    for (final entry in progresso.distribuicaoAtributos.entries) {
      final atributo = entry.key;
      final porcentagem = entry.value;
      final pontos = (kills * pontosPorKill * porcentagem / 100).floor();
      bonus[atributo] = pontos;
    }

    bonusPorTipo[tipo] = bonus;
  }

  return bonusPorTipo;
});

/// Provider que mantém o estado atualizado do progresso
final progressoBonusStateProvider = StateNotifierProvider<ProgressoBonusNotifier, Map<Tipo, Map<String, int>>>((ref) {
  return ProgressoBonusNotifier();
});

class ProgressoBonusNotifier extends StateNotifier<Map<Tipo, Map<String, int>>> {
  ProgressoBonusNotifier() : super({}) {
    _loadBonus();
  }

  Future<void> _loadBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final progressoJson = prefs.getString('progresso_diario');
    if (progressoJson == null) {
      state = {};
      return;
    }

    final progressoData = jsonDecode(progressoJson) as Map<String, dynamic>;
    var progresso = ProgressoDiario.fromJson(progressoData);

    // Se não é do dia de hoje, finaliza o dia anterior e cria novo dia
    if (progresso.data != hoje) {
      progresso = progresso.finalizarDia(hoje);
      // Salva o progresso atualizado
      await prefs.setString('progresso_diario', jsonEncode(progresso.toJson()));
    }

    final pontosPorKill = prefs.getInt('aventura_pontos_por_kill') ?? 2;

    // Calcula bônus para cada tipo usando kills do histórico válido + dia atual
    final bonusPorTipo = <Tipo, Map<String, int>>{};
    final killsPorTipoTotal = progresso.killsPorTipoComHistorico;

    for (final tipo in Tipo.values) {
      final kills = killsPorTipoTotal[tipo.name] ?? 0;

      if (kills == 0) {
        bonusPorTipo[tipo] = {'HP': 0, 'ATK': 0, 'DEF': 0, 'SPD': 0};
        continue;
      }

      final bonus = <String, int>{};
      for (final entry in progresso.distribuicaoAtributos.entries) {
        final atributo = entry.key;
        final porcentagem = entry.value;
        final pontos = (kills * pontosPorKill * porcentagem / 100).floor();
        bonus[atributo] = pontos;
      }

      bonusPorTipo[tipo] = bonus;
    }

    state = bonusPorTipo;
  }

  /// Recarrega os bônus (deve ser chamado após atualizar o progresso)
  Future<void> reload() async {
    await _loadBonus();
  }

  /// Obtém os bônus para um tipo específico
  Map<String, int> getBonusParaTipo(Tipo tipo) {
    return state[tipo] ?? {'HP': 0, 'ATK': 0, 'DEF': 0, 'SPD': 0};
  }
}
