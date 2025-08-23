import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';

class Habilidade {
  final String nome;
  final String descricao;
  final TipoHabilidade tipo;
  final EfeitoHabilidade efeito;
  final Tipo tipoElemental;
  final int valor;

  const Habilidade({
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.efeito,
    required this.tipoElemental,
    required this.valor,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo.name,
      'efeito': efeito.name,
      'tipoElemental': tipoElemental.name,
      'valor': valor,
    };
  }

  factory Habilidade.fromJson(Map<String, dynamic> json) {
    return Habilidade(
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      tipo: TipoHabilidade.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => TipoHabilidade.ofensiva,
      ),
      efeito: EfeitoHabilidade.values.firstWhere(
        (e) => e.name == json['efeito'],
        orElse: () => EfeitoHabilidade.danoDirecto,
      ),
      tipoElemental: Tipo.values.firstWhere(
        (t) => t.name == json['tipoElemental'],
        orElse: () => Tipo.normal,
      ),
      valor: json['valor'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habilidade &&
        other.nome == nome &&
        other.tipo == tipo &&
        other.efeito == efeito &&
        other.tipoElemental == tipoElemental &&
        other.valor == valor;
  }

  @override
  int get hashCode {
    return nome.hashCode ^
        tipo.hashCode ^
        efeito.hashCode ^
        tipoElemental.hashCode ^
        valor.hashCode;
  }

  @override
  String toString() {
    return 'Habilidade($nome, $tipo, $efeito, $tipoElemental, $valor)';
  }
}
