import 'package:flutter/material.dart';

/// Tipos de coleções disponíveis no jogo
enum TipoColecao {
  nostalgico,
  halloween,
}

extension TipoColecaoExtension on TipoColecao {
  /// Nome da coleção
  String get nome {
    switch (this) {
      case TipoColecao.nostalgico:
        return 'Nostálgicos';
      case TipoColecao.halloween:
        return 'Halloween';
    }
  }

  /// Descrição da coleção
  String get descricao {
    switch (this) {
      case TipoColecao.nostalgico:
        return 'Monstros raros desbloqueados ao derrotar em batalha';
      case TipoColecao.halloween:
        return 'Monstros especiais de Halloween (Outubro)';
    }
  }

  /// Path dos assets da coleção
  String get assetsPath {
    switch (this) {
      case TipoColecao.nostalgico:
        return 'assets/monstros_aventura/colecao_nostalgicos';
      case TipoColecao.halloween:
        return 'assets/monstros_aventura/colecao_halloween';
    }
  }

  /// Cor temática da coleção
  Color get corTematica {
    switch (this) {
      case TipoColecao.nostalgico:
        return Colors.purple;
      case TipoColecao.halloween:
        return Colors.orange;
    }
  }

  /// Ícone da coleção
  IconData get icone {
    switch (this) {
      case TipoColecao.nostalgico:
        return Icons.stars;
      case TipoColecao.halloween:
        return Icons.celebration;
    }
  }

  /// Verifica se a coleção está ativa (disponível para visualização)
  /// Halloween só em outubro
  bool get estaAtiva {
    switch (this) {
      case TipoColecao.nostalgico:
        return true; // Sempre disponível
      case TipoColecao.halloween:
        return DateTime.now().month == 10; // Só em outubro
    }
  }

  /// Verifica se monstros desta coleção podem aparecer no mapa
  bool get apareceNoMapa {
    switch (this) {
      case TipoColecao.nostalgico:
        return true; // Aparece no mapa após desbloqueado
      case TipoColecao.halloween:
        return false; // NUNCA aparece no mapa
    }
  }
}
