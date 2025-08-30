import 'magia_drop.dart';

class DropJogador {
  final String email;
  final List<DropItem> itens;
  final List<MagiaDrop> magias;
  final DateTime ultimaAtualizacao;

  const DropJogador({
    required this.email,
    required this.itens,
    required this.magias,
    required this.ultimaAtualizacao,
  });

  factory DropJogador.fromJson(Map<String, dynamic> json) {
    return DropJogador(
      email: json['email'] ?? '',
      itens: (json['itens'] as List<dynamic>?)
          ?.map((i) => DropItem.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
      magias: (json['magias'] as List<dynamic>?)
          ?.map((m) => MagiaDrop.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      ultimaAtualizacao: DateTime.parse(json['ultimaAtualizacao'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'itens': itens.map((i) => i.toJson()).toList(),
      'magias': magias.map((m) => m.toJson()).toList(),
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
    };
  }

  DropJogador copyWith({
    String? email,
    List<DropItem>? itens,
    List<MagiaDrop>? magias,
    DateTime? ultimaAtualizacao,
  }) {
    return DropJogador(
      email: email ?? this.email,
      itens: itens ?? this.itens,
      magias: magias ?? this.magias,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
    );
  }
}

class DropItem {
  final String nome;
  final String descricao;
  final String tipo;
  final int quantidade;
  final DateTime dataObtencao;
  final String raridade;

  const DropItem({
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.quantidade,
    required this.dataObtencao,
    this.raridade = 'comum',
  });

  factory DropItem.fromJson(Map<String, dynamic> json) {
    return DropItem(
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      tipo: json['tipo'] ?? 'item',
      quantidade: json['quantidade'] ?? 1,
      dataObtencao: DateTime.parse(json['dataObtencao'] ?? DateTime.now().toIso8601String()),
      raridade: json['raridade'] ?? 'comum',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'quantidade': quantidade,
      'dataObtencao': dataObtencao.toIso8601String(),
      'raridade': raridade,
    };
  }
}