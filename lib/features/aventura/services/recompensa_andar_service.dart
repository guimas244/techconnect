import '../presentation/modal_premio_andar.dart';

/// Serviço para gerenciar recompensas baseadas em andares
/// - Chave Auto: a cada 25 andares (25, 50, 75, 100...)
/// - Nuty: a cada 30 andares (30, 60, 90, 120...)
class RecompensaAndarService {
  // Intervalos de recompensa
  static const int intervaloChaveAuto = 25;
  static const int intervaloNuty = 30;

  // Singleton
  static final RecompensaAndarService _instance = RecompensaAndarService._internal();
  factory RecompensaAndarService() => _instance;
  RecompensaAndarService._internal();

  // Lista de recompensas pendentes para o andar atual
  List<InfoPremio> _recompensasPendentes = [];

  // Getters
  List<InfoPremio> get recompensasPendentes => List.unmodifiable(_recompensasPendentes);
  bool get temRecompensaPendente => _recompensasPendentes.isNotEmpty;
  int get quantidadeRecompensas => _recompensasPendentes.length;

  /// Verifica se um andar tem recompensa de Chave Auto
  bool temRecompensaChaveAuto(int andar) {
    return andar > 0 && andar % intervaloChaveAuto == 0;
  }

  /// Verifica se um andar tem recompensa de Nuty
  bool temRecompensaNuty(int andar) {
    return andar > 0 && andar % intervaloNuty == 0;
  }

  /// Verifica se um andar tem alguma recompensa
  bool temRecompensa(int andar) {
    return temRecompensaChaveAuto(andar) || temRecompensaNuty(andar);
  }

  /// Calcula as recompensas para um determinado andar
  /// Chamado quando o jogador ENTRA no andar (não quando sai)
  List<InfoPremio> calcularRecompensasParaAndar(int andar) {
    final recompensas = <InfoPremio>[];

    if (temRecompensaChaveAuto(andar)) {
      recompensas.add(InfoPremio.chaveAuto(andar));
    }

    if (temRecompensaNuty(andar)) {
      recompensas.add(InfoPremio.nuty(andar));
    }

    return recompensas;
  }

  /// Define as recompensas pendentes ao entrar em um novo andar
  void entrarNoAndar(int andar) {
    _recompensasPendentes = calcularRecompensasParaAndar(andar);
    if (_recompensasPendentes.isNotEmpty) {
      print('🎁 [RecompensaAndarService] Andar $andar - ${_recompensasPendentes.length} recompensa(s) disponível(is)');
      for (final r in _recompensasPendentes) {
        print('   - ${r.nome}');
      }
    }
  }

  /// Remove uma recompensa específica após ser coletada
  void coletarRecompensa(TipoPremio tipo) {
    _recompensasPendentes.removeWhere((r) => r.tipo == tipo);
    print('🎁 [RecompensaAndarService] Recompensa $tipo coletada. Restantes: ${_recompensasPendentes.length}');
  }

  /// Remove a primeira recompensa da lista (para processar uma por uma)
  InfoPremio? coletarProximaRecompensa() {
    if (_recompensasPendentes.isEmpty) return null;
    final recompensa = _recompensasPendentes.removeAt(0);
    print('🎁 [RecompensaAndarService] Recompensa ${recompensa.nome} coletada. Restantes: ${_recompensasPendentes.length}');
    return recompensa;
  }

  /// Limpa todas as recompensas pendentes (ao sair do andar sem coletar)
  void limparRecompensas() {
    _recompensasPendentes = [];
    print('🎁 [RecompensaAndarService] Recompensas limpas');
  }

  /// Verifica próximo andar com recompensa de Chave Auto
  int proximoAndarChaveAuto(int andarAtual) {
    final resto = andarAtual % intervaloChaveAuto;
    if (resto == 0 && andarAtual > 0) return andarAtual;
    return andarAtual + (intervaloChaveAuto - resto);
  }

  /// Verifica próximo andar com recompensa de Nuty
  int proximoAndarNuty(int andarAtual) {
    final resto = andarAtual % intervaloNuty;
    if (resto == 0 && andarAtual > 0) return andarAtual;
    return andarAtual + (intervaloNuty - resto);
  }

  /// Reset completo do serviço
  void reset() {
    _recompensasPendentes = [];
    print('🎁 [RecompensaAndarService] Reset completo');
  }
}
