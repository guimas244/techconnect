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

  const HistoriaJogador({
    required this.email,
    required this.monstros,
    this.aventuraIniciada = false,
    this.mapaAventura,
    this.monstrosInimigos = const [],
    this.tier = 1,
    this.score = 0,
    this.historicoBatalhas = const [],
  });

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
    );
  }
}
