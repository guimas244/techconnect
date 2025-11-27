import 'enums/status_mascote.dart';

/// Taxas de degradação por minuto (baseado no planejamento)
class TaxasDegradacao {
  /// Fome: ~5% por hora = ~0.083% por minuto
  static const double fome = 0.083;

  /// Sede: ~8% por hora = ~0.133% por minuto
  static const double sede = 0.133;

  /// Higiene: ~3% por hora = ~0.05% por minuto
  static const double higiene = 0.05;

  /// Alegria: só cai após 5h offline (-10% inicial, depois -1%/hora)
  static const int horasParaPerderAlegria = 5;
  static const double alegriaPerda5hOffline = 10.0;
  static const double alegriaPerHoraOffline = 1.0;

  /// Multiplicador quando doente
  static const double multiplicadorDoente = 2.0;

  /// Multiplicador alegria quando fome/sede = 0
  static const double multiplicadorAlegriaFomeSede0 = 3.0;
}

/// Modelo principal do mascote no Criadouro
class Mascote {
  final String id;
  final String tipo; // Tipo do monstro (chave única - 1 por tipo)
  final String nome;
  final String monstroId; // ID/imagem do monstro do catálogo (skin decorativa)
  final DateTime dataCriacao;
  final DateTime ultimoAcesso;

  // Barras de status (0.0 a 100.0)
  final double fome;
  final double sede;
  final double higiene;
  final double alegria;
  final double saude;

  // Sistema de doença
  final bool estaDoente;
  final DateTime? proximaDoenca; // Quando vai ficar doente (sorteio)
  final DateTime? fimImunidade; // 24h após criação

  // Sistema de morte
  final DateTime? inicioCritico; // Quando alguma barra zerou
  final String? barraZerada; // Qual barra causou estado crítico

  // Interações do aventura
  final int acariciarDisponiveis; // Quantas vezes pode acariciar
  final int brincarDisponiveis; // Quantas vezes pode brincar

  const Mascote({
    required this.id,
    required this.tipo,
    required this.nome,
    required this.monstroId,
    required this.dataCriacao,
    required this.ultimoAcesso,
    this.fome = 75.0,
    this.sede = 75.0,
    this.higiene = 75.0,
    this.alegria = 75.0,
    this.saude = 100.0,
    this.estaDoente = false,
    this.proximaDoenca,
    this.fimImunidade,
    this.inicioCritico,
    this.barraZerada,
    this.acariciarDisponiveis = 0,
    this.brincarDisponiveis = 0,
  });

  /// Cria um novo mascote com valores iniciais
  factory Mascote.criar({
    required String tipo,
    required String nome,
    required String monstroId,
  }) {
    final agora = DateTime.now();
    return Mascote(
      id: '${agora.millisecondsSinceEpoch}',
      tipo: tipo,
      nome: nome,
      monstroId: monstroId,
      dataCriacao: agora,
      ultimoAcesso: agora,
      fome: 75.0,
      sede: 75.0,
      higiene: 75.0,
      alegria: 75.0,
      saude: 100.0,
      estaDoente: false,
      fimImunidade: agora.add(const Duration(hours: 24)), // 24h de imunidade
    );
  }

  factory Mascote.fromJson(Map<String, dynamic> json) {
    return Mascote(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      nome: json['nome'] as String,
      monstroId: json['monstroId'] as String,
      dataCriacao: DateTime.parse(json['dataCriacao'] as String),
      ultimoAcesso: DateTime.parse(json['ultimoAcesso'] as String),
      fome: (json['fome'] as num).toDouble(),
      sede: (json['sede'] as num).toDouble(),
      higiene: (json['higiene'] as num).toDouble(),
      alegria: (json['alegria'] as num).toDouble(),
      saude: (json['saude'] as num).toDouble(),
      estaDoente: json['estaDoente'] as bool? ?? false,
      proximaDoenca: json['proximaDoenca'] != null
          ? DateTime.parse(json['proximaDoenca'] as String)
          : null,
      fimImunidade: json['fimImunidade'] != null
          ? DateTime.parse(json['fimImunidade'] as String)
          : null,
      inicioCritico: json['inicioCritico'] != null
          ? DateTime.parse(json['inicioCritico'] as String)
          : null,
      barraZerada: json['barraZerada'] as String?,
      acariciarDisponiveis: json['acariciarDisponiveis'] as int? ?? 0,
      brincarDisponiveis: json['brincarDisponiveis'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'nome': nome,
      'monstroId': monstroId,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ultimoAcesso': ultimoAcesso.toIso8601String(),
      'fome': fome,
      'sede': sede,
      'higiene': higiene,
      'alegria': alegria,
      'saude': saude,
      'estaDoente': estaDoente,
      if (proximaDoenca != null)
        'proximaDoenca': proximaDoenca!.toIso8601String(),
      if (fimImunidade != null) 'fimImunidade': fimImunidade!.toIso8601String(),
      if (inicioCritico != null)
        'inicioCritico': inicioCritico!.toIso8601String(),
      if (barraZerada != null) 'barraZerada': barraZerada,
      'acariciarDisponiveis': acariciarDisponiveis,
      'brincarDisponiveis': brincarDisponiveis,
    };
  }

  Mascote copyWith({
    String? id,
    String? tipo,
    String? nome,
    String? monstroId,
    DateTime? dataCriacao,
    DateTime? ultimoAcesso,
    double? fome,
    double? sede,
    double? higiene,
    double? alegria,
    double? saude,
    bool? estaDoente,
    DateTime? proximaDoenca,
    DateTime? fimImunidade,
    DateTime? inicioCritico,
    String? barraZerada,
    int? acariciarDisponiveis,
    int? brincarDisponiveis,
    bool limparProximaDoenca = false,
    bool limparInicioCritico = false,
    bool limparBarraZerada = false,
  }) {
    return Mascote(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      monstroId: monstroId ?? this.monstroId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ultimoAcesso: ultimoAcesso ?? this.ultimoAcesso,
      fome: fome ?? this.fome,
      sede: sede ?? this.sede,
      higiene: higiene ?? this.higiene,
      alegria: alegria ?? this.alegria,
      saude: saude ?? this.saude,
      estaDoente: estaDoente ?? this.estaDoente,
      proximaDoenca:
          limparProximaDoenca ? null : (proximaDoenca ?? this.proximaDoenca),
      fimImunidade: fimImunidade ?? this.fimImunidade,
      inicioCritico:
          limparInicioCritico ? null : (inicioCritico ?? this.inicioCritico),
      barraZerada: limparBarraZerada ? null : (barraZerada ?? this.barraZerada),
      acariciarDisponiveis: acariciarDisponiveis ?? this.acariciarDisponiveis,
      brincarDisponiveis: brincarDisponiveis ?? this.brincarDisponiveis,
    );
  }

  // ============ GETTERS ============

  /// Dias que o mascote está vivo
  int get diasVivo => DateTime.now().difference(dataCriacao).inDays;

  /// Verifica se ainda tem imunidade a doenças
  bool get temImunidade {
    if (fimImunidade == null) return false;
    return DateTime.now().isBefore(fimImunidade!);
  }

  /// Verifica se alguma barra está zerada
  bool get algumBarraZerada =>
      fome <= 0 || sede <= 0 || higiene <= 0 || saude <= 0;

  /// Verifica se está em estado crítico (barra zerada há algum tempo)
  bool get estaCritico => inicioCritico != null;

  /// Tempo restante até morrer (se em estado crítico)
  Duration? get tempoAteMorrer {
    if (inicioCritico == null) return null;
    final morteEm = inicioCritico!.add(const Duration(hours: 3));
    final restante = morteEm.difference(DateTime.now());
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Verifica se o mascote deveria estar morto
  bool get deveriaMorrer {
    // Morte imediata se saúde = 0
    if (saude <= 0) return true;

    // Morte após 3h em estado crítico
    if (inicioCritico != null) {
      final tempoDecorrido = DateTime.now().difference(inicioCritico!);
      if (tempoDecorrido.inHours >= 3) return true;
    }

    return false;
  }

  /// Retorna o status visual do mascote
  StatusMascote get status {
    if (deveriaMorrer) return StatusMascote.morto;
    if (estaCritico) return StatusMascote.critico;
    if (estaDoente) return StatusMascote.doente;
    if (fome < 30) return StatusMascote.comFome;
    if (sede < 30) return StatusMascote.comSede;
    if (higiene < 30) return StatusMascote.sujo;
    if (alegria < 30) return StatusMascote.triste;
    if (fome > 70 && sede > 70 && higiene > 70 && alegria > 70 && saude > 70) {
      return StatusMascote.feliz;
    }
    return StatusMascote.normal;
  }

  /// Emoji do status atual
  String get emoji => status.emoji;

  /// Retorna emoji para uma barra específica baseado no valor
  String emojiPorBarra(String barra, double valor) {
    if (valor <= 0) return '💀';
    if (valor < 30) {
      switch (barra) {
        case 'fome':
          return '😫';
        case 'sede':
          return '🥵';
        case 'higiene':
          return '🦨';
        case 'alegria':
          return '😢';
        case 'saude':
          return '🤒';
      }
    }
    if (valor > 70) {
      switch (barra) {
        case 'fome':
          return '😋';
        case 'sede':
          return '😊';
        case 'higiene':
          return '✨';
        case 'alegria':
          return '🥰';
        case 'saude':
          return '💪';
      }
    }
    return '😐';
  }
}
