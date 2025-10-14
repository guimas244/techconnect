import '../../../shared/models/tipo_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EntradaDiaria {
  final String dataEntrada; // Data que foi feito (formato 'yyyy-MM-dd')
  final String dataValidade; // Data que expira (formato 'yyyy-MM-dd')
  final int totalKills;
  final Map<String, int> killsPorTipo;

  EntradaDiaria({
    required this.dataEntrada,
    required this.dataValidade,
    required this.totalKills,
    required this.killsPorTipo,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataEntrada': dataEntrada,
      'dataValidade': dataValidade,
      'totalKills': totalKills,
      'killsPorTipo': killsPorTipo,
    };
  }

  factory EntradaDiaria.fromJson(Map<String, dynamic> json) {
    return EntradaDiaria(
      dataEntrada: json['dataEntrada'] as String,
      dataValidade: json['dataValidade'] as String,
      totalKills: json['totalKills'] as int,
      killsPorTipo: (json['killsPorTipo'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
    );
  }

  bool get estaValido {
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dataValidadeDate = DateFormat('yyyy-MM-dd').parse(dataValidade);
    final hojeDate = DateFormat('yyyy-MM-dd').parse(hoje);
    return hojeDate.isBefore(dataValidadeDate) || hojeDate.isAtSameMomentAs(dataValidadeDate);
  }
}

class ProgressoDiario {
  final String data; // Data no formato 'yyyy-MM-dd'
  final Map<String, int> killsPorTipo; // Tipo -> quantidade de kills (do dia atual)
  final Map<String, double> distribuicaoAtributos; // Atributo -> porcentagem (0-50)
  final List<EntradaDiaria> historico; // Histórico de entradas diárias

  ProgressoDiario({
    required this.data,
    Map<String, int>? killsPorTipo,
    Map<String, double>? distribuicaoAtributos,
    List<EntradaDiaria>? historico,
  })  : killsPorTipo = killsPorTipo ?? {},
        distribuicaoAtributos = distribuicaoAtributos ?? {
          'HP': 25,
          'ATK': 25,
          'DEF': 25,
          'SPD': 25,
        },
        historico = historico ?? [];

  // Incrementa kills de um tipo
  ProgressoDiario adicionarKill(Tipo tipo) {
    final novoMap = Map<String, int>.from(killsPorTipo);
    final tipoNome = tipo.name;
    novoMap[tipoNome] = (novoMap[tipoNome] ?? 0) + 1;

    return ProgressoDiario(
      data: data,
      killsPorTipo: novoMap,
      distribuicaoAtributos: distribuicaoAtributos,
      historico: historico,
    );
  }

  // Finaliza o dia e move para o histórico (validade de 3 dias)
  ProgressoDiario finalizarDia(String novaData) {
    // Se não tem kills, não adiciona no histórico
    if (totalKills == 0) {
      return ProgressoDiario(
        data: novaData,
        distribuicaoAtributos: distribuicaoAtributos,
        historico: _limparHistoricoExpirado(),
      );
    }

    // Calcula validade: entrada dia X expira no início do dia X+3
    final dataEntradaDate = DateFormat('yyyy-MM-dd').parse(data);
    final dataValidadeDate = dataEntradaDate.add(const Duration(days: 3));
    final dataValidade = DateFormat('yyyy-MM-dd').format(dataValidadeDate);

    final novaEntrada = EntradaDiaria(
      dataEntrada: data,
      dataValidade: dataValidade,
      totalKills: totalKills,
      killsPorTipo: Map<String, int>.from(killsPorTipo),
    );

    final novoHistorico = [...historico, novaEntrada];

    return ProgressoDiario(
      data: novaData,
      distribuicaoAtributos: distribuicaoAtributos,
      historico: novoHistorico,
    );
  }

  // Remove entradas expiradas do histórico
  List<EntradaDiaria> _limparHistoricoExpirado() {
    return historico.where((entrada) => entrada.estaValido).toList();
  }

  // Obtém histórico válido (não expirado)
  List<EntradaDiaria> get historicoValido {
    return _limparHistoricoExpirado();
  }

  // Calcula total de kills considerando histórico válido + dia atual
  int get totalKillsComHistorico {
    final killsHistorico = historicoValido.fold<int>(
      0,
      (sum, entrada) => sum + entrada.totalKills,
    );
    return killsHistorico + totalKills;
  }

  // Obtém kills por tipo considerando histórico válido + dia atual
  Map<String, int> get killsPorTipoComHistorico {
    final resultado = <String, int>{};

    // Adiciona kills do histórico válido
    for (final entrada in historicoValido) {
      for (final tipo in entrada.killsPorTipo.entries) {
        resultado[tipo.key] = (resultado[tipo.key] ?? 0) + tipo.value;
      }
    }

    // Adiciona kills do dia atual
    for (final tipo in killsPorTipo.entries) {
      resultado[tipo.key] = (resultado[tipo.key] ?? 0) + tipo.value;
    }

    return resultado;
  }

  // Atualiza distribuição de atributos
  ProgressoDiario atualizarDistribuicao(Map<String, double> novaDistribuicao) {
    return ProgressoDiario(
      data: data,
      killsPorTipo: killsPorTipo,
      distribuicaoAtributos: novaDistribuicao,
      historico: historico,
    );
  }

  // Total de kills do dia
  int get totalKills {
    return killsPorTipo.values.fold(0, (sum, kills) => sum + kills);
  }

  // Bônus de status baseado nos kills e distribuição
  Future<Map<String, int>> calcularBonus() async {
    final bonus = <String, int>{};
    final prefs = await SharedPreferences.getInstance();
    final pontosPorKill = prefs.getInt('aventura_pontos_por_kill') ?? 2;

    for (final entry in distribuicaoAtributos.entries) {
      final atributo = entry.key;
      final porcentagem = entry.value;

      // Cada kill gera pontos configuráveis (padrão: 2), distribuído pela porcentagem
      final pontos = (totalKills * pontosPorKill * porcentagem / 100).floor();
      bonus[atributo] = pontos;
    }

    return bonus;
  }

  // Versão síncrona com valor padrão para compatibilidade
  Map<String, int> calcularBonusSync({int pontosPorKill = 2}) {
    final bonus = <String, int>{};

    for (final entry in distribuicaoAtributos.entries) {
      final atributo = entry.key;
      final porcentagem = entry.value;

      final pontos = (totalKills * pontosPorKill * porcentagem / 100).floor();
      bonus[atributo] = pontos;
    }

    return bonus;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'killsPorTipo': killsPorTipo,
      'distribuicaoAtributos': distribuicaoAtributos,
      'historico': historico.map((e) => e.toJson()).toList(),
    };
  }

  factory ProgressoDiario.fromJson(Map<String, dynamic> json) {
    return ProgressoDiario(
      data: json['data'] as String,
      killsPorTipo: (json['killsPorTipo'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
      distribuicaoAtributos: (json['distribuicaoAtributos'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      historico: (json['historico'] as List<dynamic>?)
          ?.map((e) => EntradaDiaria.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  ProgressoDiario copyWith({
    String? data,
    Map<String, int>? killsPorTipo,
    Map<String, double>? distribuicaoAtributos,
    List<EntradaDiaria>? historico,
  }) {
    return ProgressoDiario(
      data: data ?? this.data,
      killsPorTipo: killsPorTipo ?? this.killsPorTipo,
      distribuicaoAtributos: distribuicaoAtributos ?? this.distribuicaoAtributos,
      historico: historico ?? this.historico,
    );
  }
}