import 'package:flutter/material.dart';

enum RaridadeItem {
  inferior(1, 'Inferior', Color(0xFF757575)), // Cinza mais escuro
  normal(2, 'Normal', Color(0xFF424242)), // Cinza escuro (ao invés de branco)
  raro(3, 'Raro', Color(0xFF388E3C)), // Verde mais escuro
  epico(4, 'Épico', Color(0xFF7B1FA2)), // Roxo mais escuro
  lendario(5, 'Lendário', Color(0xFFF57C00)), // Laranja dourado (mais contrastado)
  impossivel(6, 'Impossível', Color(0xFFD32F2F)); // Vermelho

  const RaridadeItem(this.nivel, this.nome, this.cor);
  
  final int nivel;
  final String nome;
  final Color cor;
}

class Item {
  final String id;
  final String nome;
  final RaridadeItem raridade;
  final Map<String, int> atributos; // 'vida': 5, 'ataque': 3, etc.
  final DateTime dataObtencao;
  final int tier;

  const Item({
    required this.id,
    required this.nome,
    required this.raridade,
    required this.atributos,
    required this.dataObtencao,
    this.tier = 1,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      nome: map['nome'] as String,
      raridade: RaridadeItem.values.firstWhere(
        (r) => r.nivel == map['raridade'] as int,
      ),
      atributos: Map<String, int>.from(map['atributos'] as Map),
      dataObtencao: DateTime.parse(map['dataObtencao'] as String),
      tier: map['tier'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'raridade': raridade.nivel,
      'atributos': atributos,
      'dataObtencao': dataObtencao.toIso8601String(),
      'tier': tier,
    };
  }

  Item copyWith({
    String? id,
    String? nome,
    RaridadeItem? raridade,
    Map<String, int>? atributos,
    DateTime? dataObtencao,
    int? tier,
  }) {
    return Item(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      raridade: raridade ?? this.raridade,
      atributos: atributos ?? this.atributos,
      dataObtencao: dataObtencao ?? this.dataObtencao,
      tier: tier ?? this.tier,
    );
  }

  // Getters para atributos específicos
  int get vida => atributos['vida'] ?? 0;
  int get energia => atributos['energia'] ?? 0;
  int get ataque => atributos['ataque'] ?? 0;
  int get defesa => atributos['defesa'] ?? 0;
  int get agilidade => atributos['agilidade'] ?? 0;

  // Total de atributos para cálculo de raridade
  int get totalAtributos => atributos.values.fold(0, (sum, value) => sum + value);
}
