import '../../../shared/models/tipo_enum.dart';

/// Modelo para kills permanentes (não expiram)
/// Usado no modo Explorador como moeda para comprar itens
class KillsPermanentes {
  final Map<String, int> killsPorTipo; // tipo.name -> quantidade
  final DateTime ultimaAtualizacao;

  KillsPermanentes({
    Map<String, int>? killsPorTipo,
    DateTime? ultimaAtualizacao,
  })  : killsPorTipo = killsPorTipo ?? {},
        ultimaAtualizacao = ultimaAtualizacao ?? DateTime.now();

  /// Total de kills de todos os tipos
  int get totalKills {
    return killsPorTipo.values.fold(0, (sum, kills) => sum + kills);
  }

  /// Obtém kills de um tipo específico
  int getKills(Tipo tipo) {
    return killsPorTipo[tipo.name] ?? 0;
  }

  /// Adiciona kills de um tipo
  KillsPermanentes adicionarKills(Tipo tipo, int quantidade) {
    final novoMap = Map<String, int>.from(killsPorTipo);
    novoMap[tipo.name] = (novoMap[tipo.name] ?? 0) + quantidade;

    return KillsPermanentes(
      killsPorTipo: novoMap,
      ultimaAtualizacao: DateTime.now(),
    );
  }

  /// Adiciona uma única kill de um tipo
  KillsPermanentes adicionarKill(Tipo tipo) {
    return adicionarKills(tipo, 1);
  }

  /// Remove kills de um tipo (para compras na loja)
  /// Retorna null se não tiver kills suficientes
  KillsPermanentes? gastarKills(Tipo tipo, int quantidade) {
    final atual = killsPorTipo[tipo.name] ?? 0;
    if (atual < quantidade) {
      return null; // Não tem kills suficientes
    }

    final novoMap = Map<String, int>.from(killsPorTipo);
    novoMap[tipo.name] = atual - quantidade;

    return KillsPermanentes(
      killsPorTipo: novoMap,
      ultimaAtualizacao: DateTime.now(),
    );
  }

  /// Verifica se tem kills suficientes de um tipo
  bool temKillsSuficientes(Tipo tipo, int quantidade) {
    return (killsPorTipo[tipo.name] ?? 0) >= quantidade;
  }

  /// Lista de tipos com kills (ordenada por quantidade)
  List<MapEntry<Tipo, int>> get killsOrdenadas {
    final entries = <MapEntry<Tipo, int>>[];

    for (final entry in killsPorTipo.entries) {
      try {
        final tipo = Tipo.values.firstWhere((t) => t.name == entry.key);
        entries.add(MapEntry(tipo, entry.value));
      } catch (_) {
        // Ignora tipos inválidos
      }
    }

    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'killsPorTipo': killsPorTipo,
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
    };
  }

  /// Cria a partir de JSON
  factory KillsPermanentes.fromJson(Map<String, dynamic> json) {
    return KillsPermanentes(
      killsPorTipo: (json['killsPorTipo'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          {},
      ultimaAtualizacao: json['ultimaAtualizacao'] != null
          ? DateTime.parse(json['ultimaAtualizacao'] as String)
          : DateTime.now(),
    );
  }

  /// Cria cópia com modificações
  KillsPermanentes copyWith({
    Map<String, int>? killsPorTipo,
    DateTime? ultimaAtualizacao,
  }) {
    return KillsPermanentes(
      killsPorTipo: killsPorTipo ?? this.killsPorTipo,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
    );
  }

  @override
  String toString() {
    return 'KillsPermanentes(total: $totalKills, tipos: ${killsPorTipo.length})';
  }
}
