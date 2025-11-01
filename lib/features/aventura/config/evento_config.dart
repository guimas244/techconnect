/// Configurações de eventos do jogo
class EventoConfig {
  /// Data de término do evento de Halloween (01/11)
  /// Após esta data:
  /// - Moeda de Halloween para de dropar
  /// - Moeda Chave começa a dropar
  /// - Roleta da loja fica bloqueada
  static final DateTime dataFimHalloween = DateTime(DateTime.now().year, 11, 1);

  /// Verifica se estamos no período do evento de Halloween
  /// Halloween vai de 01/10 até 31/10 (meia-noite)
  static bool get eventoHalloweenAtivo {
    final agora = DateTime.now();
    final anoAtual = agora.year;

    // Início: 01/10 00:00
    final inicioHalloween = DateTime(anoAtual, 10, 1);

    // Fim: 01/11 00:00 (ou seja, até 31/10 23:59:59)
    final fimHalloween = DateTime(anoAtual, 11, 1);

    return agora.isAfter(inicioHalloween) && agora.isBefore(fimHalloween);
  }

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
