import '../../../shared/models/habilidade_enum.dart';

class MagiaDrop {
  final String nome;
  final String descricao;
  final TipoHabilidade tipo;
  final EfeitoHabilidade efeito;
  final int valor; // Valor base da habilidade
  final int custoEnergia;
  final int level;
  final DateTime dataObtencao;

  const MagiaDrop({
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.efeito,
    required this.valor,
    required this.custoEnergia,
    required this.level,
    required this.dataObtencao,
  });

  factory MagiaDrop.fromJson(Map<String, dynamic> json) {
    return MagiaDrop(
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
      valor: json['valor'] ?? 0,
      custoEnergia: json['custoEnergia'] ?? 1,
      level: json['level'] ?? 1,
      dataObtencao: DateTime.parse(json['dataObtencao'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo.name,
      'efeito': efeito.name,
      'valor': valor,
      'custoEnergia': custoEnergia,
      'level': level,
      'dataObtencao': dataObtencao.toIso8601String(),
    };
  }

  /// Calcula o valor efetivo da magia baseado no level
  int get valorEfetivo => valor * level;
}