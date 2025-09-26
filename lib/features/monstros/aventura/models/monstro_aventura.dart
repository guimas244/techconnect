import 'dart:typed_data';
import '../../../../shared/models/tipo_enum.dart';

class MonstroAventura {
  final String id;
  final String nome;
  final Tipo tipo1;
  final Tipo tipo2;
  final String? imagemUrl;
  final Uint8List? imagemBytes;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final String colecao; // 'colecao_inicial' ou 'colecao_nostalgicos'
  final bool isBloqueado; // true para monstros nostálgicos por padrão

  MonstroAventura({
    required this.id,
    required this.nome,
    required this.tipo1,
    required this.tipo2,
    this.imagemUrl,
    this.imagemBytes,
    required this.criadoEm,
    this.atualizadoEm,
    required this.colecao,
    this.isBloqueado = false,
  });

  // Validação para não aceitar tipos iguais
  bool get tiposValidos => tipo1 != tipo2;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo1': tipo1.name,
      'tipo2': tipo2.name,
      'imagemUrl': imagemUrl,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
      'colecao': colecao,
      'isBloqueado': isBloqueado,
    };
  }

  factory MonstroAventura.fromJson(Map<String, dynamic> json) {
    return MonstroAventura(
      id: json['id'],
      nome: json['nome'],
      tipo1: Tipo.values.firstWhere((t) => t.name == json['tipo1']),
      tipo2: Tipo.values.firstWhere((t) => t.name == json['tipo2']),
      imagemUrl: json['imagemUrl'],
      criadoEm: DateTime.parse(json['criadoEm']),
      atualizadoEm: json['atualizadoEm'] != null
          ? DateTime.parse(json['atualizadoEm'])
          : null,
      colecao: json['colecao'] ?? 'colecao_inicial',
      isBloqueado: json['isBloqueado'] ?? false,
    );
  }

  MonstroAventura copyWith({
    String? id,
    String? nome,
    Tipo? tipo1,
    Tipo? tipo2,
    String? imagemUrl,
    Uint8List? imagemBytes,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? colecao,
    bool? isBloqueado,
  }) {
    return MonstroAventura(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo1: tipo1 ?? this.tipo1,
      tipo2: tipo2 ?? this.tipo2,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      imagemBytes: imagemBytes ?? this.imagemBytes,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      colecao: colecao ?? this.colecao,
      isBloqueado: isBloqueado ?? this.isBloqueado,
    );
  }

  @override
  String toString() {
    return 'MonstroAventura(id: $id, nome: $nome, tipo1: ${tipo1.displayName}, tipo2: ${tipo2.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonstroAventura &&
        other.id == id &&
        other.nome == nome &&
        other.tipo1 == tipo1 &&
        other.tipo2 == tipo2;
  }

  @override
  int get hashCode {
    return Object.hash(id, nome, tipo1, tipo2);
  }
}
