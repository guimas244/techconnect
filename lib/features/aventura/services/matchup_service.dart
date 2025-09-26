import '../../../shared/models/tipo_enum.dart';
import '../../tipagem/data/tipagem_repository.dart';

enum MatchupVantagem {
  neutro,
  vantagem,
  desvantagem,
  superVantagem,
  superDesvantagem,
}

class MatchupService {
  final TipagemRepository _tipagemRepository;

  MatchupService(this._tipagemRepository);

  /// Calcula vantagem do atacante vs defensor
  /// Retorna multiplicador e tipo de vantagem
  Future<MatchupResult> calcularMatchup({
    required Tipo tipoAtacantePrincipal,
    Tipo? tipoAtacanteExtra,
    required Tipo tipoDefensorPrincipal,
    Tipo? tipoDefensorExtra,
    double mixOfensivo = 1.0, // 1.0 = 100% tipo principal, 0.0 = 100% tipo extra
  }) async {
    try {
      // CORREÇÃO: Carrega dados de defesa do DEFENSOR (inimigo)
      // Os dados tb_X_defesa.json contêm: "quanto X recebe de dano de cada tipo"
      final dadosDefesa = await _tipagemRepository.carregarDadosTipo(tipoDefensorPrincipal);
      if (dadosDefesa == null) {
        return MatchupResult.neutro();
      }

      // Calcula efetividade: quanto dano MEU atacante faz NO defensor
      double multiplicadorTotal = 0.0;

      // Tipo principal do atacante vs defensor
      final efetividadePrincipal = dadosDefesa[tipoAtacantePrincipal] ?? 1.0;
      multiplicadorTotal += efetividadePrincipal * mixOfensivo;

      // Tipo extra do atacante (se existir) vs defensor
      if (tipoAtacanteExtra != null) {
        final efetividadeExtra = dadosDefesa[tipoAtacanteExtra] ?? 1.0;
        multiplicadorTotal += efetividadeExtra * (1.0 - mixOfensivo);
      } else {
        // Se não tem tipo extra, o principal vale 100%
        multiplicadorTotal = efetividadePrincipal;
      }

      // Determina tipo de vantagem
      final vantagem = _determinarVantagem(multiplicadorTotal);

      // Log para debug
      print('🎯 Matchup: ${tipoAtacantePrincipal.displayName} vs ${tipoDefensorPrincipal.displayName} = ${multiplicadorTotal.toStringAsFixed(3)}x → $vantagem');

      return MatchupResult(
        multiplicador: multiplicadorTotal,
        vantagem: vantagem,
        detalhes: _gerarDetalhes(
          tipoAtacantePrincipal,
          tipoAtacanteExtra,
          tipoDefensorPrincipal,
          efetividadePrincipal,
          dadosDefesa[tipoAtacanteExtra],
          mixOfensivo,
        ),
      );

    } catch (e) {
      print('❌ Erro ao calcular matchup: $e');
      return MatchupResult.neutro();
    }
  }

  /// Determina o tipo de vantagem baseado no multiplicador
  MatchupVantagem _determinarVantagem(double multiplicador) {
    // Usa tolerância para comparação de doubles
    const double tolerancia = 0.001;

    if (multiplicador >= 1.5) {
      return MatchupVantagem.superVantagem;
    } else if (multiplicador > 1.0 + tolerancia) {
      return MatchupVantagem.vantagem;
    } else if ((multiplicador - 1.0).abs() <= tolerancia) {
      // Neutro: entre 0.999 e 1.001
      return MatchupVantagem.neutro;
    } else if (multiplicador >= 0.5) {
      return MatchupVantagem.desvantagem;
    } else {
      return MatchupVantagem.superDesvantagem;
    }
  }

  /// Gera detalhes do cálculo para debug
  String _gerarDetalhes(
    Tipo tipoPrincipal,
    Tipo? tipoExtra,
    Tipo tipoDefensor,
    double efetividadePrincipal,
    double? efetividadeExtra,
    double mixOfensivo,
  ) {
    if (tipoExtra != null && efetividadeExtra != null) {
      return '${tipoPrincipal.displayName} (${(mixOfensivo * 100).toInt()}%) = ${efetividadePrincipal.toStringAsFixed(2)}x + '
             '${tipoExtra.displayName} (${((1 - mixOfensivo) * 100).toInt()}%) = ${efetividadeExtra.toStringAsFixed(2)}x '
             'vs ${tipoDefensor.displayName}';
    } else {
      return '${tipoPrincipal.displayName} = ${efetividadePrincipal.toStringAsFixed(2)}x vs ${tipoDefensor.displayName}';
    }
  }
}

class MatchupResult {
  final double multiplicador;
  final MatchupVantagem vantagem;
  final String detalhes;

  const MatchupResult({
    required this.multiplicador,
    required this.vantagem,
    required this.detalhes,
  });

  factory MatchupResult.neutro() {
    return const MatchupResult(
      multiplicador: 1.0,
      vantagem: MatchupVantagem.neutro,
      detalhes: 'Neutro',
    );
  }

  /// Retorna true se tem alguma vantagem (normal ou super)
  bool get temVantagem => vantagem == MatchupVantagem.vantagem || vantagem == MatchupVantagem.superVantagem;

  /// Retorna true se tem alguma desvantagem (normal ou super)
  bool get temDesvantagem => vantagem == MatchupVantagem.desvantagem || vantagem == MatchupVantagem.superDesvantagem;

  /// Retorna true se é neutro
  bool get isNeutro => vantagem == MatchupVantagem.neutro;
}