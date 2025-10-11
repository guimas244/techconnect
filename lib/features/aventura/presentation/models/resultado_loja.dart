import '../../models/historia_jogador.dart';
import '../../models/item.dart';
import '../../models/magia_drop.dart';

/// Tipos de resultado possíveis da Casa do Vigarista
enum TipoResultado {
  item,
  magia,
  cura,
  abrirFeirao,
  abrirBiblioteca,
  nenhum,
}

/// Resultado de uma transação na Casa do Vigarista
/// Este objeto é retornado via Navigator.pop() para o MapaAventura processar
class ResultadoLoja {
  final TipoResultado tipo;
  final Item? item;
  final MagiaDrop? habilidade;
  final int? porcentagemCura;
  final List<Item>? itensFeirao;
  final List<MagiaDrop>? magiasBiblioteca;
  final HistoriaJogador historiaAtualizada;

  ResultadoLoja({
    required this.tipo,
    this.item,
    this.habilidade,
    this.porcentagemCura,
    this.itensFeirao,
    this.magiasBiblioteca,
    required this.historiaAtualizada,
  });

  @override
  String toString() {
    return 'ResultadoLoja(tipo: $tipo, historia: ${historiaAtualizada.score})';
  }
}
