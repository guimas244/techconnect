import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

enum TipoVantagemColecao {
  curaPosBatalha(
    nome: 'Cura Pós-Batalha',
    descricao: 'Restaura vida após cada batalha vencida',
    icone: Remix.heart_add_fill,
    cor: Colors.green,
    unidade: 'HP',
  ),
  bonusExperiencia(
    nome: 'Bônus de Experiência',
    descricao: 'Aumenta a experiência ganha em batalhas',
    icone: Icons.trending_up,
    cor: Colors.amber,
    unidade: '%',
  ),
  bonusDrops(
    nome: 'Bônus de Drops',
    descricao: 'Aumenta a chance de obter itens raros',
    icone: Icons.inventory,
    cor: Colors.purple,
    unidade: '%',
  ),
  resistenciaElemental(
    nome: 'Resistência Elemental',
    descricao: 'Reduz dano de ataques elementais',
    icone: Icons.shield,
    cor: Colors.blue,
    unidade: '%',
  ),
  bonusAtaque(
    nome: 'Bônus de Ataque',
    descricao: 'Aumenta o poder de ataque de todos os monstros',
    icone: Icons.flash_on,
    cor: Colors.red,
    unidade: 'ATK',
  ),
  bonusDefesa(
    nome: 'Bônus de Defesa',
    descricao: 'Aumenta a defesa de todos os monstros',
    icone: Icons.security,
    cor: Colors.indigo,
    unidade: 'DEF',
  ),
  bonusAgilidade(
    nome: 'Bônus de Agilidade',
    descricao: 'Aumenta a velocidade de todos os monstros',
    icone: Icons.speed,
    cor: Colors.cyan,
    unidade: 'AGI',
  ),
  bonusEnergia(
    nome: 'Bônus de Energia',
    descricao: 'Aumenta a energia máxima de todos os monstros',
    icone: Icons.battery_charging_full,
    cor: Colors.orange,
    unidade: 'EN',
  );

  const TipoVantagemColecao({
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.unidade,
  });

  final String nome;
  final String descricao;
  final IconData icone;
  final Color cor;
  final String unidade;
}

enum StatusVantagem {
  ativa,
  parcial,
}

extension StatusVantagemExtension on StatusVantagem {
  String get nome {
    switch (this) {
      case StatusVantagem.ativa:
        return 'Ativa';
      case StatusVantagem.parcial:
        return 'Em Progresso';
    }
  }

  Color get cor {
    switch (this) {
      case StatusVantagem.ativa:
        return Colors.green;
      case StatusVantagem.parcial:
        return Colors.amber;
    }
  }

  IconData get icone {
    switch (this) {
      case StatusVantagem.ativa:
        return Icons.check_circle;
      case StatusVantagem.parcial:
        return Icons.hourglass_bottom;
    }
  }
}