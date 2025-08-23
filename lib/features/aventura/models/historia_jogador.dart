import 'monstro_aventura.dart';

class HistoriaJogador {
  final String email;
  final List<MonstroAventura> monstros;

  const HistoriaJogador({
    required this.email,
    required this.monstros,
  });

  factory HistoriaJogador.fromJson(Map<String, dynamic> json) {
    return HistoriaJogador(
      email: json['email'] ?? '',
      monstros: (json['monstros'] as List<dynamic>?)
          ?.map((m) => MonstroAventura.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'monstros': monstros.map((m) => m.toJson()).toList(),
    };
  }

  HistoriaJogador copyWith({
    String? email,
    List<MonstroAventura>? monstros,
  }) {
    return HistoriaJogador(
      email: email ?? this.email,
      monstros: monstros ?? this.monstros,
    );
  }
}
