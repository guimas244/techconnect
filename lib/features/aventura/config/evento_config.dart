/// Configurações de eventos do jogo
class EventoConfig {
  /// Flag manual para controlar se o evento de Halloween está ativo
  /// DESATIVADO MANUALMENTE - Evento encerrado
  static const bool eventoHalloweenAtivo = false;

  /// Data de término do evento de Halloween (01/11)
  /// Após esta data:
  /// - Moeda de Halloween para de dropar
  /// - Moeda Chave começa a dropar
  /// - Roleta da loja fica bloqueada
  static final DateTime dataFimHalloween = DateTime(DateTime.now().year, 11, 1);

  /// Verifica se a moeda de Halloween ainda pode dropar
  /// Para de dropar em 01/11
  static bool get moedaHalloweenPodeDropar {
    return eventoHalloweenAtivo;
  }

  /// Verifica se a moeda chave pode dropar
  /// Começa a dropar em 01/11
  static bool get moedaChavePodeDropar {
    final agora = DateTime.now();
    return agora.isAfter(dataFimHalloween) || agora.isAtSameMomentAs(dataFimHalloween);
  }

  /// Verifica se a roleta da loja está disponível
  /// Fica bloqueada a partir de 01/11
  static bool get roletaLojaDisponivel {
    return eventoHalloweenAtivo;
  }

  /// Chance base de drop da moeda de Halloween (em porcentagem)
  /// Esta chance vai crescendo ao longo do evento
  static const double chanceMoedaHalloween = 5.0; // 5%

  /// Chance de drop da moeda chave (10x menor que a moeda de Halloween)
  static const double chanceMoedaChave = 0.5; // 0.5% (10x menos que 5%)
}
