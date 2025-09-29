import '../../../shared/models/tipo_enum.dart';

class ProgressoDiario {
  final String data; // Data no formato 'yyyy-MM-dd'
  final Map<String, int> killsPorTipo; // Tipo -> quantidade de kills
  final Map<String, double> distribuicaoAtributos; // Atributo -> porcentagem (0-50)

  ProgressoDiario({
    required this.data,
    Map<String, int>? killsPorTipo,
    Map<String, double>? distribuicaoAtributos,
  })  : killsPorTipo = killsPorTipo ?? {},
        distribuicaoAtributos = distribuicaoAtributos ?? {
          'HP': 0,
          'ATK': 0,
          'DEF': 0,
          'SPD': 0,
        };

  // Incrementa kills de um tipo
  ProgressoDiario adicionarKill(Tipo tipo) {
    final novoMap = Map<String, int>.from(killsPorTipo);
    final tipoNome = tipo.name;
    novoMap[tipoNome] = (novoMap[tipoNome] ?? 0) + 1;

    return ProgressoDiario(
      data: data,
      killsPorTipo: novoMap,
      distribuicaoAtributos: distribuicaoAtributos,
    );
  }

  // Atualiza distribuição de atributos
  ProgressoDiario atualizarDistribuicao(Map<String, double> novaDistribuicao) {
    return ProgressoDiario(
      data: data,
      killsPorTipo: killsPorTipo,
      distribuicaoAtributos: novaDistribuicao,
    );
  }

  // Total de kills do dia
  int get totalKills {
    return killsPorTipo.values.fold(0, (sum, kills) => sum + kills);
  }

  // Bônus de status baseado nos kills e distribuição
  Map<String, int> calcularBonus() {
    final bonus = <String, int>{};

    for (final entry in distribuicaoAtributos.entries) {
      final atributo = entry.key;
      final porcentagem = entry.value;

      // Cada kill gera 1 ponto total, distribuído pela porcentagem
      final pontos = (totalKills * porcentagem / 100).floor();
      bonus[atributo] = pontos;
    }

    return bonus;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'killsPorTipo': killsPorTipo,
      'distribuicaoAtributos': distribuicaoAtributos,
    };
  }

  factory ProgressoDiario.fromJson(Map<String, dynamic> json) {
    return ProgressoDiario(
      data: json['data'] as String,
      killsPorTipo: (json['killsPorTipo'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
      distribuicaoAtributos: (json['distribuicaoAtributos'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
    );
  }

  ProgressoDiario copyWith({
    String? data,
    Map<String, int>? killsPorTipo,
    Map<String, double>? distribuicaoAtributos,
  }) {
    return ProgressoDiario(
      data: data ?? this.data,
      killsPorTipo: killsPorTipo ?? this.killsPorTipo,
      distribuicaoAtributos: distribuicaoAtributos ?? this.distribuicaoAtributos,
    );
  }
}