import 'monstro_aventura.dart';
import 'monstro_inimigo.dart';

class RegistroBatalha {
  final String jogadorNome;
  final String inimigoNome;
  final List<AcaoBatalha> acoes;
  final String vencedor;
  final DateTime dataHora;
  final int vidaInicialJogador;
  final int vidaFinalJogador;
  final int vidaInicialInimigo;
  final int vidaFinalInimigo;
  final int tierNaBatalha;
  final int scoreAntes;
  final int scoreDepois;
  final int scoreGanho;

  const RegistroBatalha({
    required this.jogadorNome,
    required this.inimigoNome,
    required this.acoes,
    required this.vencedor,
    required this.dataHora,
    required this.vidaInicialJogador,
    required this.vidaFinalJogador,
    required this.vidaInicialInimigo,
    required this.vidaFinalInimigo,
    required this.tierNaBatalha,
    required this.scoreAntes,
    required this.scoreDepois,
    required this.scoreGanho,
  });

  Map<String, dynamic> toJson() {
    return {
      'jogadorNome': jogadorNome,
      'inimigoNome': inimigoNome,
      'acoes': acoes.map((a) => a.toJson()).toList(),
      'vencedor': vencedor,
      'dataHora': dataHora.toIso8601String(),
      'vidaInicialJogador': vidaInicialJogador,
      'vidaFinalJogador': vidaFinalJogador,
      'vidaInicialInimigo': vidaInicialInimigo,
      'vidaFinalInimigo': vidaFinalInimigo,
      'tierNaBatalha': tierNaBatalha,
      'scoreAntes': scoreAntes,
      'scoreDepois': scoreDepois,
      'scoreGanho': scoreGanho,
    };
  }

  factory RegistroBatalha.fromJson(Map<String, dynamic> json) {
    return RegistroBatalha(
      jogadorNome: json['jogadorNome'] ?? '',
      inimigoNome: json['inimigoNome'] ?? '',
      acoes: (json['acoes'] as List<dynamic>?)
          ?.map((a) => AcaoBatalha.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      vencedor: json['vencedor'] ?? '',
      dataHora: DateTime.parse(json['dataHora'] ?? DateTime.now().toIso8601String()),
      vidaInicialJogador: json['vidaInicialJogador'] ?? 0,
      vidaFinalJogador: json['vidaFinalJogador'] ?? 0,
      vidaInicialInimigo: json['vidaInicialInimigo'] ?? 0,
      vidaFinalInimigo: json['vidaFinalInimigo'] ?? 0,
      tierNaBatalha: json['tierNaBatalha'] ?? 1,
      scoreAntes: json['scoreAntes'] ?? 0,
      scoreDepois: json['scoreDepois'] ?? 0,
      scoreGanho: json['scoreGanho'] ?? 0,
    );
  }
}

class AcaoBatalha {
  final String atacante;
  final String habilidadeNome;
  final int danoBase;
  final int danoTotal;
  final int defesaAlvo;
  final int vidaAntes;
  final int vidaDepois;
  final String descricao;

  const AcaoBatalha({
    required this.atacante,
    required this.habilidadeNome,
    required this.danoBase,
    required this.danoTotal,
    required this.defesaAlvo,
    required this.vidaAntes,
    required this.vidaDepois,
    required this.descricao,
  });

  Map<String, dynamic> toJson() {
    return {
      'atacante': atacante,
      'habilidadeNome': habilidadeNome,
      'danoBase': danoBase,
      'danoTotal': danoTotal,
      'defesaAlvo': defesaAlvo,
      'vidaAntes': vidaAntes,
      'vidaDepois': vidaDepois,
      'descricao': descricao,
    };
  }

  factory AcaoBatalha.fromJson(Map<String, dynamic> json) {
    return AcaoBatalha(
      atacante: json['atacante'] ?? '',
      habilidadeNome: json['habilidadeNome'] ?? '',
      danoBase: json['danoBase'] ?? 0,
      danoTotal: json['danoTotal'] ?? 0,
      defesaAlvo: json['defesaAlvo'] ?? 0,
      vidaAntes: json['vidaAntes'] ?? 0,
      vidaDepois: json['vidaDepois'] ?? 0,
      descricao: json['descricao'] ?? '',
    );
  }
}

class EstadoBatalha {
  final MonstroAventura jogador;
  final MonstroInimigo inimigo;
  final int vidaAtualJogador;
  final int vidaAtualInimigo;
  final int vidaMaximaJogador; // Vida máxima com buffs
  final int vidaMaximaInimigo; // Vida máxima com buffs
  final int energiaAtualJogador;
  final int energiaAtualInimigo;
  final int ataqueAtualJogador;
  final int defesaAtualJogador;
  final int ataqueAtualInimigo;
  final int defesaAtualInimigo;
  final List<String> habilidadesUsadasJogador;
  final List<String> habilidadesUsadasInimigo;
  final List<AcaoBatalha> historicoAcoes;

  const EstadoBatalha({
    required this.jogador,
    required this.inimigo,
    required this.vidaAtualJogador,
    required this.vidaAtualInimigo,
    required this.vidaMaximaJogador,
    required this.vidaMaximaInimigo,
    required this.energiaAtualJogador,
    required this.energiaAtualInimigo,
    required this.ataqueAtualJogador,
    required this.defesaAtualJogador,
    required this.ataqueAtualInimigo,
    required this.defesaAtualInimigo,
    required this.habilidadesUsadasJogador,
    required this.habilidadesUsadasInimigo,
    required this.historicoAcoes,
  });

  EstadoBatalha copyWith({
    MonstroAventura? jogador,
    MonstroInimigo? inimigo,
    int? vidaAtualJogador,
    int? vidaAtualInimigo,
    int? vidaMaximaJogador,
    int? vidaMaximaInimigo,
    int? energiaAtualJogador,
    int? energiaAtualInimigo,
    int? ataqueAtualJogador,
    int? defesaAtualJogador,
    int? ataqueAtualInimigo,
    int? defesaAtualInimigo,
    List<String>? habilidadesUsadasJogador,
    List<String>? habilidadesUsadasInimigo,
    List<AcaoBatalha>? historicoAcoes,
  }) {
    return EstadoBatalha(
      jogador: jogador ?? this.jogador,
      inimigo: inimigo ?? this.inimigo,
      vidaAtualJogador: vidaAtualJogador ?? this.vidaAtualJogador,
      vidaAtualInimigo: vidaAtualInimigo ?? this.vidaAtualInimigo,
      vidaMaximaJogador: vidaMaximaJogador ?? this.vidaMaximaJogador,
      vidaMaximaInimigo: vidaMaximaInimigo ?? this.vidaMaximaInimigo,
      energiaAtualJogador: energiaAtualJogador ?? this.energiaAtualJogador,
      energiaAtualInimigo: energiaAtualInimigo ?? this.energiaAtualInimigo,
      ataqueAtualJogador: ataqueAtualJogador ?? this.ataqueAtualJogador,
      defesaAtualJogador: defesaAtualJogador ?? this.defesaAtualJogador,
      ataqueAtualInimigo: ataqueAtualInimigo ?? this.ataqueAtualInimigo,
      defesaAtualInimigo: defesaAtualInimigo ?? this.defesaAtualInimigo,
      habilidadesUsadasJogador: habilidadesUsadasJogador ?? this.habilidadesUsadasJogador,
      habilidadesUsadasInimigo: habilidadesUsadasInimigo ?? this.habilidadesUsadasInimigo,
      historicoAcoes: historicoAcoes ?? this.historicoAcoes,
    );
  }
}
