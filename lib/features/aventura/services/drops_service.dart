import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/drop.dart';

class DropsService {
  static const String _dropsKey = 'jogador_drops';
  static const String _configKey = 'drops_config';
  static const int maxSlots = 3;

  /// Sorteia múltiplos drops (máximo 3) com chances independentes para cada item
  ///
  /// [temPassivaSortudo]: Se true, dá uma segunda chance para CADA item que não dropar
  ///
  /// Retorna um Map com:
  /// - 'drops': List<Drop> com todos os drops obtidos (máximo 3, sem repetir)
  /// - 'dropsDoSortudo': List<TipoDrop> com os tipos que vieram da passiva Sortudo
  static Future<Map<String, dynamic>> sortearMultiplosDrops({bool temPassivaSortudo = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);

    Map<TipoDrop, double> porcentagens;
    if (configJson == null) {
      // Usa valores padrão se não houver configuração
      porcentagens = {
        TipoDrop.frutaNuty: 0.5,
        TipoDrop.frutaNutyCristalizada: 0.5,
        TipoDrop.frutaNutyNegra: 0.5,
        TipoDrop.vidinha: 0.5,
        TipoDrop.joiaReforco: 1.0,
        TipoDrop.pocaoVidaGrande: 2.0,
        TipoDrop.pedraRecriacao: 2.0,
        TipoDrop.pocaoVidaPequena: 5.0,
      };
    } else {
      final Map<String, dynamic> configMap = jsonDecode(configJson);
      porcentagens = {};
      for (final entry in configMap.entries) {
        final tipo = TipoDrop.values.firstWhere((t) => t.id == entry.key);
        porcentagens[tipo] = (entry.value as num).toDouble();
      }
    }

    return _sortearMultiplosDropsComPorcentagens(porcentagens, temPassivaSortudo: temPassivaSortudo);
  }

  /// Sorteia múltiplos drops com sorteios independentes para cada item
  static Future<Map<String, dynamic>> _sortearMultiplosDropsComPorcentagens(
    Map<TipoDrop, double> porcentagens, {
    bool temPassivaSortudo = false,
  }) async {
    final random = Random();
    final dropsObtidos = <Drop>[];
    final dropsDoSortudo = <TipoDrop>[];

    print('🎲 [DropsService] Iniciando sorteio de múltiplos drops (máximo 3)');
    print('🎲 [DropsService] Passiva Sortudo: ${temPassivaSortudo ? "ATIVA" : "inativa"}');

    // Para cada tipo de drop, faz um sorteio independente
    for (final entry in porcentagens.entries) {
      // Se já temos 3 drops, para
      if (dropsObtidos.length >= 3) {
        print('🎲 [DropsService] Limite de 3 drops atingido, ignorando demais sorteios');
        break;
      }

      final tipoDrop = entry.key;
      final chanceDrop = entry.value;

      // PRIMEIRA TENTATIVA
      final sorteio1 = random.nextDouble() * 100;
      final ganhouNaTentativa1 = sorteio1 <= chanceDrop;

      print('🎲 [DropsService] ${tipoDrop.nome}: sorteio ${sorteio1.toStringAsFixed(2)}/100 <= ${chanceDrop}% ? ${ganhouNaTentativa1 ? "✅ SIM" : "❌ NÃO"}');

      if (ganhouNaTentativa1) {
        dropsObtidos.add(Drop(tipo: tipoDrop, quantidade: 1));
        continue;
      }

      // SEGUNDA TENTATIVA (SORTUDO)
      if (temPassivaSortudo) {
        final sorteio2 = random.nextDouble() * 100;
        final ganhouNaTentativa2 = sorteio2 <= chanceDrop;

        print('🍀 [SORTUDO] ${tipoDrop.nome}: sorteio ${sorteio2.toStringAsFixed(2)}/100 <= ${chanceDrop}% ? ${ganhouNaTentativa2 ? "✅ SIM" : "❌ NÃO"}');

        if (ganhouNaTentativa2) {
          dropsObtidos.add(Drop(tipo: tipoDrop, quantidade: 1));
          dropsDoSortudo.add(tipoDrop);
        }
      }
    }

    print('📊 [DropsService] Resultado final: ${dropsObtidos.length} drops obtidos');
    if (dropsDoSortudo.isNotEmpty) {
      print('🍀 [DropsService] Drops do Sortudo: ${dropsDoSortudo.map((t) => t.nome).join(", ")}');
    }

    return {
      'drops': dropsObtidos,
      'dropsDoSortudo': dropsDoSortudo,
    };
  }

  /// DEPRECATED: Use sortearMultiplosDrops() ao invés deste método
  /// Mantido apenas para compatibilidade com código antigo
  ///
  /// Sorteia um drop baseado nas porcentagens configuradas
  /// Retorna null se não ganhou nenhum drop
  ///
  /// [temPassivaSortudo]: Se true, dá uma segunda chance caso não venha drop na primeira tentativa
  ///
  /// Retorna um Map com:
  /// - 'drop': o Drop? sorteado (pode ser null)
  /// - 'veioDoSortudo': bool indicando se o drop veio da segunda chance (passiva Sortudo)
  @Deprecated('Use sortearMultiplosDrops() para suportar múltiplos drops')
  static Future<Map<String, dynamic>> sortearDrop({bool temPassivaSortudo = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);

    if (configJson == null) {
      // Usa valores padrão se não houver configuração
      // Ordem: do mais raro (menor %) para o menos raro (maior %)
      return _sortearComPorcentagens({
        TipoDrop.frutaNuty: 0.5,              // 0.5% - Lendário (prioridade 1)
        TipoDrop.frutaNutyCristalizada: 0.5,  // 0.5% - Épico (prioridade 2)
        TipoDrop.frutaNutyNegra: 0.5,         // 0.5% - Épico (prioridade 3)
        TipoDrop.vidinha: 0.5,                // 0.5% - Lendário (prioridade 4)
        TipoDrop.joiaReforco: 1.0,            // 1% - Épico (prioridade 5)
        TipoDrop.pocaoVidaGrande: 2.0,        // 2% - Épico (prioridade 6)
        TipoDrop.pedraRecriacao: 2.0,         // 2% - Lendário (prioridade 7)
        TipoDrop.pocaoVidaPequena: 5.0,       // 5% - Inferior (prioridade 8)
      }, temPassivaSortudo: temPassivaSortudo);
    }

    final Map<String, dynamic> configMap = jsonDecode(configJson);
    final Map<TipoDrop, double> porcentagens = {};

    for (final entry in configMap.entries) {
      final tipo = TipoDrop.values.firstWhere((t) => t.id == entry.key);
      porcentagens[tipo] = (entry.value as num).toDouble();
    }

    return _sortearComPorcentagens(porcentagens, temPassivaSortudo: temPassivaSortudo);
  }

  static Future<Map<String, dynamic>> _sortearComPorcentagens(
    Map<TipoDrop, double> porcentagens, {
    bool temPassivaSortudo = false,
  }) async {
    final random = Random();

    // PRIMEIRA TENTATIVA (chance normal)
    print('🎲 [DropsService] Sorteando drop (tentativa 1)...');
    for (final entry in porcentagens.entries) {
      final chance = random.nextDouble() * 100;
      if (chance <= entry.value) {
        print('✅ [DropsService] Drop obtido na primeira tentativa: ${entry.key.nome}');
        return {
          'drop': Drop(tipo: entry.key, quantidade: 1),
          'veioDoSortudo': false,
        };
      }
    }

    // ===== PASSIVA: SORTUDO =====
    // Se não ganhou nada E tem passiva Sortudo, dá uma SEGUNDA CHANCE!
    if (temPassivaSortudo) {
      print('🍀 [PASSIVA SORTUDO] Não veio drop... Tentando novamente! (segunda chance)');

      for (final entry in porcentagens.entries) {
        final chance = random.nextDouble() * 100;
        if (chance <= entry.value) {
          print('✅ [PASSIVA SORTUDO] Drop obtido na SEGUNDA tentativa: ${entry.key.nome}');
          return {
            'drop': Drop(tipo: entry.key, quantidade: 1),
            'veioDoSortudo': true,
          };
        }
      }

      print('❌ [PASSIVA SORTUDO] Nenhum drop mesmo com segunda chance');
    }

    print('❌ [DropsService] Nenhum drop obtido');
    return {
      'drop': null,
      'veioDoSortudo': false,
    };
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
