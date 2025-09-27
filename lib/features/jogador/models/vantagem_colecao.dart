import '../../../core/models/vantagem_colecao_enum.dart';
import '../../../shared/models/tipo_enum.dart';

class VantagemColecao {
  final String id;
  final String nomeColecao;
  final String descricaoColecao;
  final TipoVantagemColecao tipoVantagem;
  final double valor;
  final int monstrosRequeridos;
  final int monstrosDesbloqueados;
  final List<Tipo> tiposRequeridos;
  final String imagemColecao;
  final bool ehNostalgica;

  const VantagemColecao({
    required this.id,
    required this.nomeColecao,
    required this.descricaoColecao,
    required this.tipoVantagem,
    required this.valor,
    required this.monstrosRequeridos,
    required this.monstrosDesbloqueados,
    required this.tiposRequeridos,
    required this.imagemColecao,
    this.ehNostalgica = false,
  });

  StatusVantagem get status {
    if (monstrosDesbloqueados >= monstrosRequeridos) {
      return StatusVantagem.ativa;
    } else {
      return StatusVantagem.parcial;
    }
  }

  double get progresso => (monstrosDesbloqueados / monstrosRequeridos).clamp(0.0, 1.0);

  double get valorAtual {
    switch (status) {
      case StatusVantagem.ativa:
        return valor;
      case StatusVantagem.parcial:
        // Vantagem parcial proporcional ao progresso
        return valor * progresso;
    }
  }

  String get valorFormatado {
    final valorExibido = status == StatusVantagem.ativa ? valor : valorAtual;

    switch (tipoVantagem.unidade) {
      case '%':
        return '+${valorExibido.toStringAsFixed(1)}%';
      case 'HP':
      case 'ATK':
      case 'DEF':
      case 'AGI':
      case 'EN':
        return '+${valorExibido.toStringAsFixed(0)} ${tipoVantagem.unidade}';
      default:
        return '+${valorExibido.toStringAsFixed(1)}';
    }
  }

  String get progressoTexto => '$monstrosDesbloqueados/$monstrosRequeridos monstros';

  VantagemColecao copyWith({
    String? id,
    String? nomeColecao,
    String? descricaoColecao,
    TipoVantagemColecao? tipoVantagem,
    double? valor,
    int? monstrosRequeridos,
    int? monstrosDesbloqueados,
    List<Tipo>? tiposRequeridos,
    String? imagemColecao,
    bool? ehNostalgica,
  }) {
    return VantagemColecao(
      id: id ?? this.id,
      nomeColecao: nomeColecao ?? this.nomeColecao,
      descricaoColecao: descricaoColecao ?? this.descricaoColecao,
      tipoVantagem: tipoVantagem ?? this.tipoVantagem,
      valor: valor ?? this.valor,
      monstrosRequeridos: monstrosRequeridos ?? this.monstrosRequeridos,
      monstrosDesbloqueados: monstrosDesbloqueados ?? this.monstrosDesbloqueados,
      tiposRequeridos: tiposRequeridos ?? this.tiposRequeridos,
      imagemColecao: imagemColecao ?? this.imagemColecao,
      ehNostalgica: ehNostalgica ?? this.ehNostalgica,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VantagemColecao && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VantagemColecao(id: $id, nomeColecao: $nomeColecao, status: ${status.nome}, progresso: ${(progresso * 100).toStringAsFixed(1)}%)';
  }
}