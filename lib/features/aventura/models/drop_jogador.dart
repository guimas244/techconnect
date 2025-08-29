class DropJogador {
  final String email;
  final List<DropItem> itens;
  final DateTime ultimaAtualizacao;

  const DropJogador({
    required this.email,
    required this.itens,
    required this.ultimaAtualizacao,
  });

  factory DropJogador.fromJson(Map<String, dynamic> json) {
    return DropJogador(
      email: json['email'] ?? '',
      itens: (json['itens'] as List<dynamic>?)
          ?.map((i) => DropItem.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
      ultimaAtualizacao: DateTime.parse(json['ultimaAtualizacao'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'itens': itens.map((i) => i.toJson()).toList(),
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
    };
  }

  DropJogador copyWith({
    String? email,
    List<DropItem>? itens,
    DateTime? ultimaAtualizacao,
  }) {
    return DropJogador(
      email: email ?? this.email,
      itens: itens ?? this.itens,
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

  const DropItem({
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.quantidade,
    required this.dataObtencao,
  });

  factory DropItem.fromJson(Map<String, dynamic> json) {
    return DropItem(
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      tipo: json['tipo'] ?? 'item',
      quantidade: json['quantidade'] ?? 1,
      dataObtencao: DateTime.parse(json['dataObtencao'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'quantidade': quantidade,
      'dataObtencao': dataObtencao.toIso8601String(),
    };
  }
}