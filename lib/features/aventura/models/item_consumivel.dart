import 'package:flutter/material.dart';

/// Modelo para itens consumíveis da mochila
class ItemConsumivel {
  final String id;
  final String nome;
  final String descricao;
  final TipoItemConsumivel tipo;
  final String iconPath;
  final int quantidade;
  final RaridadeConsumivel raridade;

  const ItemConsumivel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.iconPath,
    this.quantidade = 1,
    this.raridade = RaridadeConsumivel.comum,
  });

  ItemConsumivel copyWith({
    String? id,
    String? nome,
    String? descricao,
    TipoItemConsumivel? tipo,
    String? iconPath,
    int? quantidade,
    RaridadeConsumivel? raridade,
  }) {
    return ItemConsumivel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      iconPath: iconPath ?? this.iconPath,
      quantidade: quantidade ?? this.quantidade,
      raridade: raridade ?? this.raridade,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo.name,
      'iconPath': iconPath,
      'quantidade': quantidade,
      'raridade': raridade.name,
    };
  }

  factory ItemConsumivel.fromJson(Map<String, dynamic> json) {
    return ItemConsumivel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      tipo: TipoItemConsumivel.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoItemConsumivel.pocao,
      ),
      iconPath: json['iconPath'] ?? '',
      quantidade: json['quantidade'] ?? 1,
      raridade: RaridadeConsumivel.values.firstWhere(
        (e) => e.name == json['raridade'],
        orElse: () => RaridadeConsumivel.comum,
      ),
    );
  }
}

enum TipoItemConsumivel {
  pocao,
  joia,
  fruta,
  vidinha,
  pergaminho,
  elixir,
  fragmento,
  moedaEvento, // Moeda de evento (Halloween, etc) - DEPRECATED, use moedaHalloween
  moedaHalloween, // Moeda de Halloween (válida até 31/10)
  ovoEvento, // Ovo de evento (Halloween, etc)
  moedaChave, // Moeda Chave (começa a dropar em 01/11)
}

enum RaridadeConsumivel {
  inferior,
  comum,
  raro,
  epico,
  lendario,
  impossivel,
}

extension RaridadeConsumivelExtension on RaridadeConsumivel {
  String get nome {
    switch (this) {
      case RaridadeConsumivel.inferior:
        return 'Inferior';
      case RaridadeConsumivel.comum:
        return 'Comum';
      case RaridadeConsumivel.raro:
        return 'Raro';
      case RaridadeConsumivel.epico:
        return 'Épico';
      case RaridadeConsumivel.lendario:
        return 'Lendário';
      case RaridadeConsumivel.impossivel:
        return 'Impossível';
    }
  }

  Color get cor {
    switch (this) {
      case RaridadeConsumivel.inferior:
        return const Color(0xFF757575); // Cinza mais escuro
      case RaridadeConsumivel.comum:
        return const Color(0xFF9E9E9E); // Cinza
      case RaridadeConsumivel.raro:
        return const Color(0xFF2196F3); // Azul
      case RaridadeConsumivel.epico:
        return const Color(0xFF9C27B0); // Roxo
      case RaridadeConsumivel.lendario:
        return const Color(0xFFFF9800); // Laranja/Dourado
      case RaridadeConsumivel.impossivel:
        return const Color(0xFFD32F2F); // Vermelho
    }
  }
}