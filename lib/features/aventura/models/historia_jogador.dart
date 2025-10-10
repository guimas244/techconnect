import 'monstro_aventura.dart';
import 'monstro_inimigo.dart';
import 'batalha.dart';

class HistoriaJogador {
  final String email;
  final List<MonstroAventura> monstros;
  final bool aventuraIniciada;
  final String? mapaAventura;
  final List<MonstroInimigo> monstrosInimigos;
  final int tier;
  final int score;
  final List<RegistroBatalha> historicoBatalhas;
  final String runId; // ID único para cada run/aventura
  final DateTime dataCriacao; // Data de criação da aventura
  final int refreshsRestantes; // Quantidade de refreshs restantes (máximo 5 por run)
  final bool mensagemLimite50Mostrada; // Flag para controlar se mensagem de limite foi exibida

  HistoriaJogador({
    required this.email,
    required this.monstros,
    this.aventuraIniciada = false,
    this.mapaAventura,
    this.monstrosInimigos = const [],
    this.tier = 1,
    this.score = 0,
    this.historicoBatalhas = const [],
    String? runId,
    DateTime? dataCriacao,
    this.refreshsRestantes = 5, // Inicia com 5 refreshs
    this.mensagemLimite50Mostrada = false, // Inicia como false
  }) : runId = runId ?? '',
       dataCriacao = dataCriacao ?? DateTime.utc(2000); // Default para aventuras antigas

  factory HistoriaJogador.fromJson(Map<String, dynamic> json) {
    return HistoriaJogador(
      email: json['email'] ?? '',
      monstros: (json['monstros'] as List<dynamic>?)
          ?.map((m) => MonstroAventura.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      aventuraIniciada: json['aventuraIniciada'] ?? false,
      mapaAventura: json['mapaAventura'],
      monstrosInimigos: (json['monstrosInimigos'] as List<dynamic>?)
          ?.map((m) => MonstroInimigo.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      tier: json['tier'] ?? 1,
      score: json['score'] ?? 0,
      historicoBatalhas: (json['historicoBatalhas'] as List<dynamic>?)
          ?.map((b) => RegistroBatalha.fromJson(b as Map<String, dynamic>))
          .toList() ?? [],
      runId: json['runId'] ?? '',
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.parse(json['dataCriacao'])
          : DateTime.utc(2000), // Default para aventuras antigas sem data
      refreshsRestantes: json['refreshsRestantes'] ?? 5, // Default 5 para aventuras antigas
      mensagemLimite50Mostrada: json['mensagemLimite50Mostrada'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'monstros': monstros.map((m) => m.toJson()).toList(),
      'aventuraIniciada': aventuraIniciada,
      'mapaAventura': mapaAventura,
      'monstrosInimigos': monstrosInimigos.map((m) => m.toJson()).toList(),
      'tier': tier,
      'score': score,
      'historicoBatalhas': historicoBatalhas.map((b) => b.toJson()).toList(),
      'runId': runId,
      'dataCriacao': dataCriacao.toIso8601String(),
      'refreshsRestantes': refreshsRestantes,
      'mensagemLimite50Mostrada': mensagemLimite50Mostrada,
    };
  }

  HistoriaJogador copyWith({
    String? email,
    List<MonstroAventura>? monstros,
    bool? aventuraIniciada,
    String? mapaAventura,
    List<MonstroInimigo>? monstrosInimigos,
    int? tier,
    int? score,
    List<RegistroBatalha>? historicoBatalhas,
    String? runId,
    DateTime? dataCriacao,
    int? refreshsRestantes,
    bool? mensagemLimite50Mostrada,
  }) {
    return HistoriaJogador(
      email: email ?? this.email,
      monstros: monstros ?? this.monstros,
      aventuraIniciada: aventuraIniciada ?? this.aventuraIniciada,
      mapaAventura: mapaAventura ?? this.mapaAventura,
      monstrosInimigos: monstrosInimigos ?? this.monstrosInimigos,
      tier: tier ?? this.tier,
      score: score ?? this.score,
      historicoBatalhas: historicoBatalhas ?? this.historicoBatalhas,
      runId: runId ?? this.runId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      refreshsRestantes: refreshsRestantes ?? this.refreshsRestantes,
      mensagemLimite50Mostrada: mensagemLimite50Mostrada ?? this.mensagemLimite50Mostrada,
    );
  }

  /// Verifica se a aventura expirou (passou da meia-noite do horário de Brasília)
  bool get aventuraExpirada {
    // Horário atual de Brasília (UTC-3)
    final agora = DateTime.now().toUtc().subtract(const Duration(hours: 3));

    // Data de criação convertida para horário de Brasília
    final dataCriacaoBrasilia = dataCriacao.toUtc().subtract(const Duration(hours: 3));

    // Verifica se estamos em dias diferentes
    final agoraData = DateTime(agora.year, agora.month, agora.day);
    final criacaoData = DateTime(dataCriacaoBrasilia.year, dataCriacaoBrasilia.month, dataCriacaoBrasilia.day);

    return agoraData.isAfter(criacaoData);
  }
}
