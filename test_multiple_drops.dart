import 'dart:math';

/// Simulação do sistema de múltiplos drops
void main() {
  print('🎮 SIMULAÇÃO DO SISTEMA DE MÚLTIPLOS DROPS\n');
  print('═' * 60);

  // Configuração das chances (igual ao DropsService)
  final porcentagens = {
    'Fruta Nuty': 0.5,
    'Fruta Nuty Cristalizada': 0.5,
    'Fruta Nuty Negra': 0.5,
    'Vidinha': 0.5,
    'Joia de Reforço': 1.0,
    'Poção de Vida Grande': 2.0,
    'Joia da Recriação': 2.0,
    'Poção de Vida Pequena': 5.0,
  };

  // Simula 100 batalhas
  final resultados = <int>[];
  final dropsComSortudo = <String>[];

  for (int batalha = 1; batalha <= 100; batalha++) {
    final resultado = simularDrops(porcentagens, temPassivaSortudo: true);
    resultados.add(resultado['total'] as int);

    if ((resultado['dropsDoSortudo'] as List).isNotEmpty) {
      dropsComSortudo.addAll((resultado['dropsDoSortudo'] as List).cast<String>());
    }

    // Mostra apenas batalhas com drops
    if (resultado['total'] > 0) {
      print('\n📊 Batalha #$batalha:');
      print('   Drops obtidos: ${resultado['total']}');
      print('   Items:');
      for (final drop in (resultado['drops'] as List)) {
        final ehDoSortudo = (resultado['dropsDoSortudo'] as List).contains(drop);
        print('      - $drop${ehDoSortudo ? " 🍀 (SORTUDO)" : ""}');
      }
    }
  }

  print('\n' + '═' * 60);
  print('\n📈 ESTATÍSTICAS FINAIS (100 batalhas):');
  print('   Total de drops: ${resultados.reduce((a, b) => a + b)}');
  print('   Média por batalha: ${(resultados.reduce((a, b) => a + b) / 100).toStringAsFixed(2)}');
  print('   Batalhas com 0 drops: ${resultados.where((r) => r == 0).length}');
  print('   Batalhas com 1 drop: ${resultados.where((r) => r == 1).length}');
  print('   Batalhas com 2 drops: ${resultados.where((r) => r == 2).length}');
  print('   Batalhas com 3 drops: ${resultados.where((r) => r == 3).length}');
  print('   Drops vindos do Sortudo: ${dropsComSortudo.length}');
  print('   🍀 Taxa de sucesso do Sortudo: ${(dropsComSortudo.length * 100 / resultados.reduce((a, b) => a + b)).toStringAsFixed(1)}%');
}

Map<String, dynamic> simularDrops(Map<String, double> porcentagens, {bool temPassivaSortudo = false}) {
  final random = Random();
  final dropsObtidos = <String>[];
  final dropsDoSortudo = <String>[];

  for (final entry in porcentagens.entries) {
    if (dropsObtidos.length >= 3) break;

    final item = entry.key;
    final chance = entry.value;

    // PRIMEIRA TENTATIVA
    final sorteio1 = random.nextDouble() * 100;
    if (sorteio1 <= chance) {
      dropsObtidos.add(item);
      continue;
    }

    // SEGUNDA TENTATIVA (SORTUDO)
    if (temPassivaSortudo) {
      final sorteio2 = random.nextDouble() * 100;
      if (sorteio2 <= chance) {
        dropsObtidos.add(item);
        dropsDoSortudo.add(item);
      }
    }
  }

  return {
    'total': dropsObtidos.length,
    'drops': dropsObtidos,
    'dropsDoSortudo': dropsDoSortudo,
  };
}
