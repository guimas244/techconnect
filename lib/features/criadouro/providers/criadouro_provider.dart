import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/criadouro_models.dart';

/// Estado completo do Criadouro
class CriadouroState {
  final Mascote? mascote;
  final List<MascoteMorto> memorial;
  final ConfigCriadouro config;
  final InventarioCriadouro inventario;
  final int teks;
  final bool carregando;
  final String? erro;

  const CriadouroState({
    this.mascote,
    this.memorial = const [],
    this.config = const ConfigCriadouro(),
    this.inventario = const InventarioCriadouro(),
    this.teks = 0,
    this.carregando = false,
    this.erro,
  });

  CriadouroState copyWith({
    Mascote? mascote,
    List<MascoteMorto>? memorial,
    ConfigCriadouro? config,
    InventarioCriadouro? inventario,
    int? teks,
    bool? carregando,
    String? erro,
    bool limparMascote = false,
    bool limparErro = false,
  }) {
    return CriadouroState(
      mascote: limparMascote ? null : (mascote ?? this.mascote),
      memorial: memorial ?? this.memorial,
      config: config ?? this.config,
      inventario: inventario ?? this.inventario,
      teks: teks ?? this.teks,
      carregando: carregando ?? this.carregando,
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }

  /// Verifica se tem um mascote vivo
  bool get temMascote => mascote != null && !mascote!.deveriaMorrer;

  /// Verifica se o mascote precisa de atenção urgente
  bool get precisaAtencaoUrgente {
    if (mascote == null) return false;
    return mascote!.fome < 30 ||
        mascote!.sede < 30 ||
        mascote!.higiene < 30 ||
        mascote!.alegria < 30 ||
        mascote!.saude < 50 ||
        mascote!.estaDoente ||
        mascote!.estaCritico;
  }
}

/// Notifier para gerenciar o estado do Criadouro
class CriadouroNotifier extends StateNotifier<CriadouroState> {
  CriadouroNotifier() : super(const CriadouroState());

  final Random _random = Random();

  // ============ CRIAR/CARREGAR MASCOTE ============

  /// Cria um novo mascote
  void criarMascote({required String nome, required String monstroId}) {
    final novoMascote = Mascote.criar(nome: nome, monstroId: monstroId);

    // Agenda primeira doença (após imunidade de 24h)
    final mascoteComDoenca = _agendarProximaDoenca(novoMascote);

    state = state.copyWith(mascote: mascoteComDoenca, limparErro: true);
  }

  /// Carrega estado do Criadouro (chamado ao iniciar app)
  void carregarEstado({
    Mascote? mascote,
    List<MascoteMorto>? memorial,
    ConfigCriadouro? config,
    InventarioCriadouro? inventario,
    int? teks,
  }) {
    state = state.copyWith(
      mascote: mascote,
      memorial: memorial ?? [],
      config: config ?? const ConfigCriadouro(),
      inventario: inventario ?? const InventarioCriadouro(),
      teks: teks ?? 0,
      carregando: false,
    );

    // Se tem mascote, atualiza degradação desde último acesso
    if (mascote != null) {
      atualizarDegradacao();
    }
  }

  // ============ SISTEMA DE DEGRADAÇÃO ============

  /// Atualiza todas as barras baseado no tempo decorrido
  void atualizarDegradacao() {
    if (state.mascote == null) return;

    final mascote = state.mascote!;
    final agora = DateTime.now();
    final minutosPassados = agora.difference(mascote.ultimoAcesso).inMinutes;

    if (minutosPassados <= 0) return;

    // Multiplicador se estiver doente
    final multiplicador =
        mascote.estaDoente ? TaxasDegradacao.multiplicadorDoente : 1.0;

    // Calcula degradação de cada barra
    double novaFome = mascote.fome -
        (minutosPassados * TaxasDegradacao.fome * multiplicador);
    double novaSede = mascote.sede -
        (minutosPassados * TaxasDegradacao.sede * multiplicador);
    double novaHigiene = mascote.higiene -
        (minutosPassados * TaxasDegradacao.higiene * multiplicador);
    double novaAlegria = mascote.alegria;
    double novaSaude = mascote.saude;

    // Alegria: só cai após 5h offline
    final horasOffline = minutosPassados / 60;
    if (horasOffline >= TaxasDegradacao.horasParaPerderAlegria) {
      // Perde 10% ao passar de 5h
      novaAlegria -= TaxasDegradacao.alegriaPerda5hOffline;
      // Perde 1% por hora adicional
      final horasAlem5h = horasOffline - TaxasDegradacao.horasParaPerderAlegria;
      novaAlegria -= horasAlem5h * TaxasDegradacao.alegriaPerHoraOffline;
    }

    // Se fome ou sede = 0, alegria cai 3x mais rápido
    if (novaFome <= 0 || novaSede <= 0) {
      final perdaExtra = minutosPassados *
          0.05 *
          TaxasDegradacao.multiplicadorAlegriaFomeSede0;
      novaAlegria -= perdaExtra;
    }

    // Cascata de dano durante estado crítico
    if (mascote.estaCritico) {
      final horasCritico =
          agora.difference(mascote.inicioCritico!).inMinutes / 60;

      if (mascote.barraZerada == 'fome') {
        novaSaude -= horasCritico * 5; // -5% saúde por hora
        novaAlegria -= horasCritico * 3; // -3% alegria por hora
      } else if (mascote.barraZerada == 'sede') {
        novaSaude -= horasCritico * 8; // -8% saúde por hora
        novaAlegria -= horasCritico * 3;
      } else if (mascote.barraZerada == 'higiene') {
        novaSaude -= horasCritico * 2; // -2% saúde por hora (infecção)
      }
    }

    // Clampa valores entre 0 e 100
    novaFome = novaFome.clamp(0.0, 100.0);
    novaSede = novaSede.clamp(0.0, 100.0);
    novaHigiene = novaHigiene.clamp(0.0, 100.0);
    novaAlegria = novaAlegria.clamp(0.0, 100.0);
    novaSaude = novaSaude.clamp(0.0, 100.0);

    // Verifica se entrou em estado crítico
    String? barraZerada;
    DateTime? inicioCritico = mascote.inicioCritico;

    if (!mascote.estaCritico) {
      if (novaFome <= 0) {
        barraZerada = 'fome';
        inicioCritico = agora;
      } else if (novaSede <= 0) {
        barraZerada = 'sede';
        inicioCritico = agora;
      } else if (novaHigiene <= 0) {
        barraZerada = 'higiene';
        inicioCritico = agora;
      }
    }

    // Verifica doença agendada
    bool novoEstaDoente = mascote.estaDoente;
    DateTime? novaProximaDoenca = mascote.proximaDoenca;

    if (!mascote.estaDoente &&
        mascote.proximaDoenca != null &&
        agora.isAfter(mascote.proximaDoenca!)) {
      novoEstaDoente = true;
      novaProximaDoenca = null;
    }

    // Atualiza mascote
    var mascoteAtualizado = mascote.copyWith(
      fome: novaFome,
      sede: novaSede,
      higiene: novaHigiene,
      alegria: novaAlegria,
      saude: novaSaude,
      ultimoAcesso: agora,
      estaDoente: novoEstaDoente,
      proximaDoenca: novaProximaDoenca,
      limparProximaDoenca: novaProximaDoenca == null && mascote.proximaDoenca != null,
      inicioCritico: inicioCritico,
      barraZerada: barraZerada ?? mascote.barraZerada,
    );

    // Verifica se morreu
    if (mascoteAtualizado.deveriaMorrer) {
      _registrarMorte(mascoteAtualizado);
      return;
    }

    state = state.copyWith(mascote: mascoteAtualizado);
  }

  // ============ SISTEMA DE DOENÇA ============

  /// Agenda próxima doença baseado nas condições atuais
  Mascote _agendarProximaDoenca(Mascote mascote) {
    // Se ainda tem imunidade, não agenda
    if (mascote.temImunidade) {
      // Agenda para depois da imunidade
      final aposImunidade = mascote.fimImunidade!;
      final horasSorteio = _sortearHorasParaDoenca(mascote);
      return mascote.copyWith(
        proximaDoenca: aposImunidade.add(Duration(hours: horasSorteio)),
      );
    }

    final horasSorteio = _sortearHorasParaDoenca(mascote);
    return mascote.copyWith(
      proximaDoenca: DateTime.now().add(Duration(hours: horasSorteio)),
    );
  }

  /// Sorteia quantas horas até a próxima doença
  int _sortearHorasParaDoenca(Mascote mascote) {
    // Base: 1 a 30 horas
    int minHoras = 1;
    int maxHoras = 30;

    // Modificadores por alegria
    if (mascote.alegria > 70) {
      maxHoras = 40; // Mais tempo saudável
    } else if (mascote.alegria < 30) {
      maxHoras = 20; // Fica doente mais rápido
    }

    // Modificador por higiene
    double multiplicador = 1.0;
    if (mascote.higiene <= 0) {
      multiplicador = 0.5; // Metade do tempo
    }

    final horasSorteadas = minHoras + _random.nextInt(maxHoras - minHoras + 1);
    return (horasSorteadas * multiplicador).round().clamp(1, 40);
  }

  /// Cura a doença do mascote (ao usar remédio)
  void curarDoenca() {
    if (state.mascote == null || !state.mascote!.estaDoente) return;

    var mascoteCurado = state.mascote!.copyWith(
      estaDoente: false,
    );

    // Agenda próxima doença
    mascoteCurado = _agendarProximaDoenca(mascoteCurado);

    state = state.copyWith(mascote: mascoteCurado);
  }

  // ============ SISTEMA DE MORTE ============

  /// Registra a morte do mascote no memorial
  void _registrarMorte(Mascote mascote) {
    final registro = MascoteMorto.fromMascote(
      id: mascote.id,
      nome: mascote.nome,
      monstroId: mascote.monstroId,
      dataCriacao: mascote.dataCriacao,
      fome: mascote.fome,
      sede: mascote.sede,
      higiene: mascote.higiene,
      alegria: mascote.alegria,
      saude: mascote.saude,
      estaDoente: mascote.estaDoente,
      barraZerada: mascote.barraZerada,
    );

    final novoMemorial = [...state.memorial, registro];

    state = state.copyWith(
      memorial: novoMemorial,
      limparMascote: true,
    );
  }

  // ============ INTERAÇÕES ============

  /// Acariciar o mascote (+1% alegria)
  void acariciar() {
    if (state.mascote == null) return;
    if (state.mascote!.acariciarDisponiveis <= 0) return;

    state = state.copyWith(
      mascote: state.mascote!.copyWith(
        alegria: (state.mascote!.alegria + 1).clamp(0.0, 100.0),
        acariciarDisponiveis: state.mascote!.acariciarDisponiveis - 1,
        ultimoAcesso: DateTime.now(),
      ),
    );
  }

  /// Brincar com o mascote (+1% alegria)
  void brincar() {
    if (state.mascote == null) return;
    if (state.mascote!.brincarDisponiveis <= 0) return;

    state = state.copyWith(
      mascote: state.mascote!.copyWith(
        alegria: (state.mascote!.alegria + 1).clamp(0.0, 100.0),
        brincarDisponiveis: state.mascote!.brincarDisponiveis - 1,
        ultimoAcesso: DateTime.now(),
      ),
    );
  }

  /// Dar banho no mascote (+10% higiene)
  void darBanho() {
    if (state.mascote == null) return;

    state = state.copyWith(
      mascote: state.mascote!.copyWith(
        higiene: (state.mascote!.higiene + 10).clamp(0.0, 100.0),
        ultimoAcesso: DateTime.now(),
      ),
    );
  }

  /// Usar um item no mascote
  void usarItem(String itemId) {
    if (state.mascote == null) return;
    if (!state.inventario.temItem(itemId)) return;

    final item = ItensCriadouro.porId(itemId);
    if (item == null) return;

    var mascote = state.mascote!;

    // Aplica efeito principal
    mascote = _aplicarEfeito(mascote, item.tipoEfeito, item.valorEfeito);

    // Aplica efeito secundário se houver
    if (item.tipoEfeitoExtra != null && item.valorEfeitoExtra != null) {
      mascote =
          _aplicarEfeito(mascote, item.tipoEfeitoExtra!, item.valorEfeitoExtra!);
    }

    // Remove item do inventário
    final novoInventario = state.inventario.removerItem(itemId);

    // Se estava em estado crítico e a barra foi restaurada, sai do crítico
    if (mascote.estaCritico) {
      final barraRecuperada = _verificarBarraRecuperada(mascote);
      if (barraRecuperada) {
        mascote = mascote.copyWith(
          limparInicioCritico: true,
          limparBarraZerada: true,
        );
      }
    }

    state = state.copyWith(
      mascote: mascote.copyWith(ultimoAcesso: DateTime.now()),
      inventario: novoInventario,
    );
  }

  Mascote _aplicarEfeito(Mascote mascote, TipoEfeito tipo, double valor) {
    switch (tipo) {
      case TipoEfeito.fome:
        return mascote.copyWith(
          fome: (mascote.fome + valor).clamp(0.0, 100.0),
        );
      case TipoEfeito.sede:
        return mascote.copyWith(
          sede: (mascote.sede + valor).clamp(0.0, 100.0),
        );
      case TipoEfeito.higiene:
        return mascote.copyWith(
          higiene: (mascote.higiene + valor).clamp(0.0, 100.0),
        );
      case TipoEfeito.alegria:
        return mascote.copyWith(
          alegria: (mascote.alegria + valor).clamp(0.0, 100.0),
        );
      case TipoEfeito.saude:
        return mascote.copyWith(
          saude: (mascote.saude + valor).clamp(0.0, 100.0),
        );
      case TipoEfeito.curarDoenca:
        curarDoenca();
        return state.mascote ?? mascote;
    }
  }

  bool _verificarBarraRecuperada(Mascote mascote) {
    switch (mascote.barraZerada) {
      case 'fome':
        return mascote.fome > 0;
      case 'sede':
        return mascote.sede > 0;
      case 'higiene':
        return mascote.higiene > 0;
      default:
        return false;
    }
  }

  // ============ ECONOMIA (TEKS) ============

  /// Adiciona Teks (drop de batalha)
  void adicionarTeks(int quantidade) {
    state = state.copyWith(teks: state.teks + quantidade);
  }

  /// Compra um item da loja
  bool comprarItem(String itemId, [int quantidade = 1]) {
    final item = ItensCriadouro.porId(itemId);
    if (item == null) return false;

    final custoTotal = item.preco * quantidade;
    if (state.teks < custoTotal) return false;

    state = state.copyWith(
      teks: state.teks - custoTotal,
      inventario: state.inventario.adicionarItem(itemId, quantidade),
    );

    return true;
  }

  // ============ AVENTURA INTEGRATION ============

  /// Adiciona interações disponíveis (chamado ao completar andar)
  void adicionarInteracoesDoAndar() {
    if (state.mascote == null) return;

    state = state.copyWith(
      mascote: state.mascote!.copyWith(
        acariciarDisponiveis: state.mascote!.acariciarDisponiveis + 1,
        brincarDisponiveis: state.mascote!.brincarDisponiveis + 1,
      ),
    );
  }

  // ============ CONFIGURAÇÕES ============

  /// Atualiza configurações de notificação
  void atualizarConfig(ConfigCriadouro novaConfig) {
    state = state.copyWith(config: novaConfig);
  }

  // ============ SERIALIZAÇÃO ============

  /// Exporta estado para JSON (para salvar no Drive)
  Map<String, dynamic> toJson() {
    return {
      'mascote': state.mascote?.toJson(),
      'memorial': state.memorial.map((m) => m.toJson()).toList(),
      'config': state.config.toJson(),
      'inventario': state.inventario.toJson(),
      'teks': state.teks,
    };
  }

  /// Importa estado do JSON (ao carregar do Drive)
  void fromJson(Map<String, dynamic> json) {
    carregarEstado(
      mascote: json['mascote'] != null
          ? Mascote.fromJson(json['mascote'] as Map<String, dynamic>)
          : null,
      memorial: (json['memorial'] as List<dynamic>?)
              ?.map(
                  (m) => MascoteMorto.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      config: json['config'] != null
          ? ConfigCriadouro.fromJson(json['config'] as Map<String, dynamic>)
          : const ConfigCriadouro(),
      inventario: json['inventario'] != null
          ? InventarioCriadouro.fromJson(
              json['inventario'] as Map<String, dynamic>)
          : const InventarioCriadouro(),
      teks: json['teks'] as int? ?? 0,
    );
  }
}

/// Provider principal do Criadouro
final criadouroProvider =
    StateNotifierProvider<CriadouroNotifier, CriadouroState>((ref) {
  return CriadouroNotifier();
});

/// Provider para verificar se tem mascote
final temMascoteProvider = Provider<bool>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.temMascote;
});

/// Provider para verificar se precisa de atenção
final precisaAtencaoProvider = Provider<bool>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.precisaAtencaoUrgente;
});

/// Provider para o mascote atual
final mascoteProvider = Provider<Mascote?>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.mascote;
});

/// Provider para o saldo de Teks
final teksProvider = Provider<int>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.teks;
});

/// Provider para o inventário
final inventarioProvider = Provider<InventarioCriadouro>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.inventario;
});

/// Provider para o memorial
final memorialProvider = Provider<List<MascoteMorto>>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.memorial;
});
