import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/criadouro_models.dart';
import '../services/criadouro_hive_service.dart';

/// Estado completo do Criadouro
class CriadouroState {
  /// Mapa de mascotes: chave = tipo (ex: 'agumon'), valor = Mascote
  final Map<String, Mascote> mascotes;

  /// Tipo do mascote atualmente selecionado para visualização
  final String? tipoAtivo;

  /// Mapa de níveis por tipo de monstro (permanente)
  final Map<String, LevelTipo> niveis;

  final List<MascoteMorto> memorial;
  final ConfigCriadouro config;
  final InventarioCriadouro inventario;
  final int teks;
  final bool carregando;
  final String? erro;

  /// Email do jogador para persistência
  final String? emailJogador;

  const CriadouroState({
    this.mascotes = const {},
    this.tipoAtivo,
    this.niveis = const {},
    this.memorial = const [],
    this.config = const ConfigCriadouro(),
    this.inventario = const InventarioCriadouro(),
    this.teks = 0,
    this.carregando = false,
    this.erro,
    this.emailJogador,
  });

  CriadouroState copyWith({
    Map<String, Mascote>? mascotes,
    String? tipoAtivo,
    Map<String, LevelTipo>? niveis,
    List<MascoteMorto>? memorial,
    ConfigCriadouro? config,
    InventarioCriadouro? inventario,
    int? teks,
    bool? carregando,
    String? erro,
    String? emailJogador,
    bool limparTipoAtivo = false,
    bool limparErro = false,
  }) {
    return CriadouroState(
      mascotes: mascotes ?? this.mascotes,
      tipoAtivo: limparTipoAtivo ? null : (tipoAtivo ?? this.tipoAtivo),
      niveis: niveis ?? this.niveis,
      memorial: memorial ?? this.memorial,
      config: config ?? this.config,
      inventario: inventario ?? this.inventario,
      teks: teks ?? this.teks,
      carregando: carregando ?? this.carregando,
      erro: limparErro ? null : (erro ?? this.erro),
      emailJogador: emailJogador ?? this.emailJogador,
    );
  }

  /// Retorna o mascote atualmente selecionado
  Mascote? get mascoteAtivo {
    if (tipoAtivo == null) return null;
    return mascotes[tipoAtivo];
  }

  /// Verifica se tem pelo menos um mascote vivo
  bool get temMascote => mascotes.values.any((m) => !m.deveriaMorrer);

  /// Retorna lista de mascotes vivos
  List<Mascote> get mascotesVivos =>
      mascotes.values.where((m) => !m.deveriaMorrer).toList();

  /// Verifica se já tem um mascote do tipo especificado
  bool temMascoteTipo(String tipo) => mascotes.containsKey(tipo);

  /// Retorna o nível do tipo do mascote ativo
  LevelTipo? get nivelAtivo {
    if (tipoAtivo == null) return null;
    return niveis[tipoAtivo] ?? LevelTipo(tipo: tipoAtivo!);
  }

  /// Retorna o nível de um tipo específico (cria se não existir)
  LevelTipo getNivel(String tipo) {
    return niveis[tipo] ?? LevelTipo(tipo: tipo);
  }

  /// Verifica se o mascote ativo precisa de atenção urgente
  bool get precisaAtencaoUrgente {
    final mascote = mascoteAtivo;
    if (mascote == null) return false;
    return mascote.fome < 30 ||
        mascote.sede < 30 ||
        mascote.higiene < 30 ||
        mascote.alegria < 30 ||
        mascote.saude < 50 ||
        mascote.estaDoente ||
        mascote.estaCritico;
  }

  /// Verifica se algum mascote precisa de atenção
  bool get algumPrecisaAtencao {
    return mascotes.values.any((m) =>
        !m.deveriaMorrer &&
        (m.fome < 30 ||
            m.sede < 30 ||
            m.higiene < 30 ||
            m.alegria < 30 ||
            m.saude < 50 ||
            m.estaDoente ||
            m.estaCritico));
  }
}

/// Notifier para gerenciar o estado do Criadouro
class CriadouroNotifier extends StateNotifier<CriadouroState> {
  CriadouroNotifier() : super(const CriadouroState());

  final Random _random = Random();
  final CriadouroHiveService _hiveService = CriadouroHiveService();

  // ============ INICIALIZAÇÃO E PERSISTÊNCIA ============

  /// Inicializa o criadouro para um jogador (chamado no login)
  Future<void> inicializar(String email) async {
    state = state.copyWith(carregando: true, emailJogador: email);

    try {
      await _hiveService.init();
      final dados = await _hiveService.carregarCriadouro(email);

      if (dados != null) {
        state = state.copyWith(
          mascotes: dados.mascotes,
          niveis: dados.niveis,
          memorial: dados.memorial,
          inventario: dados.inventario,
          config: dados.config,
          teks: dados.teks,
          carregando: false,
          limparErro: true,
        );

        // Atualiza degradação de todos os mascotes
        atualizarDegradacaoTodos();
      } else {
        state = state.copyWith(carregando: false, limparErro: true);
      }
    } catch (e) {
      print('❌ [CriadouroNotifier] Erro ao inicializar: $e');
      state = state.copyWith(carregando: false, erro: e.toString());
    }
  }

  /// Salva o estado atual no Hive
  Future<void> _salvar() async {
    if (state.emailJogador == null) return;

    await _hiveService.salvarCriadouro(
      email: state.emailJogador!,
      mascotes: state.mascotes,
      niveis: state.niveis,
      memorial: state.memorial,
      inventario: state.inventario,
      config: state.config,
      teks: state.teks,
    );
  }

  // ============ CRIAR/CARREGAR MASCOTE ============

  /// Cria um novo mascote de um tipo específico
  Future<bool> criarMascote({
    required String tipo,
    required String nome,
    required String monstroId,
  }) async {
    // Verifica se já existe mascote desse tipo
    if (state.mascotes.containsKey(tipo)) {
      print('⚠️ [CriadouroNotifier] Já existe mascote do tipo $tipo');
      return false;
    }

    final novoMascote = Mascote.criar(
      tipo: tipo,
      nome: nome,
      monstroId: monstroId,
    );

    // Agenda primeira doença (após imunidade de 24h)
    final mascoteComDoenca = _agendarProximaDoenca(novoMascote);

    // Adiciona ao mapa de mascotes
    final novosMascotes = Map<String, Mascote>.from(state.mascotes);
    novosMascotes[tipo] = mascoteComDoenca;

    state = state.copyWith(
      mascotes: novosMascotes,
      tipoAtivo: tipo,
      limparErro: true,
    );

    await _salvar();
    return true;
  }

  /// Seleciona um mascote para visualização
  void selecionarMascote(String tipo) {
    if (!state.mascotes.containsKey(tipo)) return;
    state = state.copyWith(tipoAtivo: tipo);
  }

  /// Atualiza o nome de um mascote
  Future<void> renomearMascote(String tipo, String novoNome) async {
    if (!state.mascotes.containsKey(tipo)) return;

    final mascote = state.mascotes[tipo]!;
    final mascoteAtualizado = mascote.copyWith(nome: novoNome);

    final novosMascotes = Map<String, Mascote>.from(state.mascotes);
    novosMascotes[tipo] = mascoteAtualizado;

    state = state.copyWith(mascotes: novosMascotes);
    await _salvar();
  }

  /// Atualiza a skin (monstroId) de um mascote
  Future<void> atualizarSkin(String tipo, String novoMonstroId) async {
    if (!state.mascotes.containsKey(tipo)) return;

    final mascote = state.mascotes[tipo]!;
    final mascoteAtualizado = mascote.copyWith(monstroId: novoMonstroId);

    final novosMascotes = Map<String, Mascote>.from(state.mascotes);
    novosMascotes[tipo] = mascoteAtualizado;

    state = state.copyWith(mascotes: novosMascotes);
    await _salvar();
  }

  /// Carrega estado do Criadouro (legado - para compatibilidade)
  void carregarEstado({
    Map<String, Mascote>? mascotes,
    Map<String, LevelTipo>? niveis,
    List<MascoteMorto>? memorial,
    ConfigCriadouro? config,
    InventarioCriadouro? inventario,
    int? teks,
  }) {
    state = state.copyWith(
      mascotes: mascotes ?? {},
      niveis: niveis ?? {},
      memorial: memorial ?? [],
      config: config ?? const ConfigCriadouro(),
      inventario: inventario ?? const InventarioCriadouro(),
      teks: teks ?? 0,
      carregando: false,
    );

    // Atualiza degradação de todos os mascotes
    if (mascotes != null && mascotes.isNotEmpty) {
      atualizarDegradacaoTodos();
    }
  }

  // ============ SISTEMA DE DEGRADAÇÃO ============

  /// Atualiza degradação de todos os mascotes
  void atualizarDegradacaoTodos() {
    if (state.mascotes.isEmpty) return;

    final novosMascotes = <String, Mascote>{};
    final novoMemorial = [...state.memorial];
    bool houveMorte = false;

    for (final entry in state.mascotes.entries) {
      final resultado = _calcularDegradacao(entry.value);
      if (resultado.morreu) {
        novoMemorial.add(_criarRegistroMorte(resultado.mascote));
        houveMorte = true;
      } else {
        novosMascotes[entry.key] = resultado.mascote;
      }
    }

    state = state.copyWith(
      mascotes: novosMascotes,
      memorial: houveMorte ? novoMemorial : null,
    );

    if (houveMorte) {
      _salvar();
    }
  }

  /// Atualiza degradação do mascote ativo
  void atualizarDegradacao() {
    if (state.tipoAtivo == null || !state.mascotes.containsKey(state.tipoAtivo)) return;

    final mascote = state.mascotes[state.tipoAtivo]!;
    final resultado = _calcularDegradacao(mascote);

    if (resultado.morreu) {
      _registrarMorte(resultado.mascote);
      return;
    }

    final novosMascotes = Map<String, Mascote>.from(state.mascotes);
    novosMascotes[state.tipoAtivo!] = resultado.mascote;

    state = state.copyWith(mascotes: novosMascotes);
  }

  /// Calcula a degradação de um mascote específico
  ({Mascote mascote, bool morreu}) _calcularDegradacao(Mascote mascote) {
    final agora = DateTime.now();
    final minutosPassados = agora.difference(mascote.ultimoAcesso).inMinutes;

    if (minutosPassados <= 0) {
      return (mascote: mascote, morreu: false);
    }

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
    final mascoteAtualizado = mascote.copyWith(
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

    return (mascote: mascoteAtualizado, morreu: mascoteAtualizado.deveriaMorrer);
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

  /// Cura a doença do mascote ativo (ao usar remédio)
  Future<void> curarDoenca() async {
    final mascote = state.mascoteAtivo;
    if (mascote == null || !mascote.estaDoente) return;

    var mascoteCurado = mascote.copyWith(
      estaDoente: false,
    );

    // Agenda próxima doença
    mascoteCurado = _agendarProximaDoenca(mascoteCurado);

    _atualizarMascoteAtivo(mascoteCurado);
    await _salvar();
  }

  // ============ SISTEMA DE MORTE ============

  /// Cria um registro de morte para o memorial
  MascoteMorto _criarRegistroMorte(Mascote mascote) {
    return MascoteMorto.fromMascote(
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
  }

  /// Registra a morte do mascote no memorial e remove do mapa
  Future<void> _registrarMorte(Mascote mascote) async {
    final registro = _criarRegistroMorte(mascote);
    final novoMemorial = [...state.memorial, registro];

    // Remove mascote do mapa
    final novosMascotes = Map<String, Mascote>.from(state.mascotes);
    novosMascotes.remove(mascote.tipo);

    // Se era o ativo, limpa seleção
    final limparAtivo = state.tipoAtivo == mascote.tipo;

    state = state.copyWith(
      mascotes: novosMascotes,
      memorial: novoMemorial,
      limparTipoAtivo: limparAtivo,
    );

    await _salvar();
  }

  /// Atualiza o mascote ativo no mapa
  void _atualizarMascoteAtivo(Mascote mascoteAtualizado) {
    if (state.tipoAtivo == null) return;

    final novosMascotes = Map<String, Mascote>.from(state.mascotes);
    novosMascotes[state.tipoAtivo!] = mascoteAtualizado;

    state = state.copyWith(mascotes: novosMascotes);
  }

  // ============ INTERAÇÕES ============

  /// Acariciar o mascote ativo (+1% alegria)
  Future<void> acariciar() async {
    final mascote = state.mascoteAtivo;
    if (mascote == null) return;
    if (mascote.acariciarDisponiveis <= 0) return;

    _atualizarMascoteAtivo(mascote.copyWith(
      alegria: (mascote.alegria + 1).clamp(0.0, 100.0),
      acariciarDisponiveis: mascote.acariciarDisponiveis - 1,
      ultimoAcesso: DateTime.now(),
    ));
    await _salvar();
  }

  /// Brincar com o mascote ativo (+1% alegria)
  Future<void> brincar() async {
    final mascote = state.mascoteAtivo;
    if (mascote == null) return;
    if (mascote.brincarDisponiveis <= 0) return;

    _atualizarMascoteAtivo(mascote.copyWith(
      alegria: (mascote.alegria + 1).clamp(0.0, 100.0),
      brincarDisponiveis: mascote.brincarDisponiveis - 1,
      ultimoAcesso: DateTime.now(),
    ));
    await _salvar();
  }

  /// Dar banho no mascote ativo (+10% higiene)
  Future<void> darBanho() async {
    final mascote = state.mascoteAtivo;
    if (mascote == null) return;

    _atualizarMascoteAtivo(mascote.copyWith(
      higiene: (mascote.higiene + 10).clamp(0.0, 100.0),
      ultimoAcesso: DateTime.now(),
    ));
    await _salvar();
  }

  /// Usar um item no mascote ativo
  Future<void> usarItem(String itemId) async {
    final mascote = state.mascoteAtivo;
    if (mascote == null) return;
    if (!state.inventario.temItem(itemId)) return;

    final item = ItensCriadouro.porId(itemId);
    if (item == null) return;

    var mascoteAtualizado = mascote;

    // Aplica efeito principal
    mascoteAtualizado = _aplicarEfeito(mascoteAtualizado, item.tipoEfeito, item.valorEfeito);

    // Aplica efeito secundário se houver
    if (item.tipoEfeitoExtra != null && item.valorEfeitoExtra != null) {
      mascoteAtualizado =
          _aplicarEfeito(mascoteAtualizado, item.tipoEfeitoExtra!, item.valorEfeitoExtra!);
    }

    // Remove item do inventário
    final novoInventario = state.inventario.removerItem(itemId);

    // Se estava em estado crítico e a barra foi restaurada, sai do crítico
    if (mascoteAtualizado.estaCritico) {
      final barraRecuperada = _verificarBarraRecuperada(mascoteAtualizado);
      if (barraRecuperada) {
        mascoteAtualizado = mascoteAtualizado.copyWith(
          limparInicioCritico: true,
          limparBarraZerada: true,
        );
      }
    }

    mascoteAtualizado = mascoteAtualizado.copyWith(ultimoAcesso: DateTime.now());

    final novosMascotes = Map<String, Mascote>.from(state.mascotes);
    novosMascotes[state.tipoAtivo!] = mascoteAtualizado;

    state = state.copyWith(
      mascotes: novosMascotes,
      inventario: novoInventario,
    );

    await _salvar();
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
        return mascote.copyWith(estaDoente: false);
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

  // ============ SISTEMA DE XP E NÍVEIS ============

  /// Adiciona XP ao tipo do mascote ativo
  /// Retorna informações sobre o XP ganho e se subiu de nível
  Future<({int xpGanho, int levelAnterior, int levelAtual, bool subiuNivel})?>
      adicionarXp(int quantidade) async {
    final mascote = state.mascoteAtivo;
    if (mascote == null) return null;

    final tipo = mascote.tipo;
    final nivelAtual = state.getNivel(tipo);
    final levelAnterior = nivelAtual.level;
    final nivelNovo = nivelAtual.adicionarXp(quantidade);

    final novosNiveis = Map<String, LevelTipo>.from(state.niveis);
    novosNiveis[tipo] = nivelNovo;

    state = state.copyWith(niveis: novosNiveis);
    await _salvar();

    print(
        '⭐ [XP] $tipo: +$quantidade XP → Lv${nivelNovo.level} (${nivelNovo.xpAtual}/${nivelNovo.xpParaProximoLevel})');

    return (
      xpGanho: quantidade,
      levelAnterior: levelAnterior,
      levelAtual: nivelNovo.level,
      subiuNivel: nivelNovo.level > levelAnterior,
    );
  }

  /// Adiciona XP a um tipo específico (para uso do Aventura)
  Future<({int xpGanho, int levelAnterior, int levelAtual, bool subiuNivel})?>
      adicionarXpTipo(String tipo, int quantidade) async {
    final nivelAtual = state.getNivel(tipo);
    final levelAnterior = nivelAtual.level;
    final nivelNovo = nivelAtual.adicionarXp(quantidade);

    final novosNiveis = Map<String, LevelTipo>.from(state.niveis);
    novosNiveis[tipo] = nivelNovo;

    state = state.copyWith(niveis: novosNiveis);
    await _salvar();

    print(
        '⭐ [XP] $tipo: +$quantidade XP → Lv${nivelNovo.level} (${nivelNovo.xpAtual}/${nivelNovo.xpParaProximoLevel})');

    return (
      xpGanho: quantidade,
      levelAnterior: levelAnterior,
      levelAtual: nivelNovo.level,
      subiuNivel: nivelNovo.level > levelAnterior,
    );
  }

  /// Verifica e aplica XP de tempo (a cada 48h vivo)
  Future<({int xpGanho, bool subiuNivel})?> verificarXpTempo() async {
    final mascote = state.mascoteAtivo;
    if (mascote == null) return null;

    final tipo = mascote.tipo;
    final nivelAtual = state.getNivel(tipo);

    if (!nivelAtual.podeGanharXpTempo) return null;

    // Adiciona 10 XP e marca o tempo
    var nivelNovo = nivelAtual.adicionarXp(10);
    nivelNovo = nivelNovo.marcarXpTempo();

    final novosNiveis = Map<String, LevelTipo>.from(state.niveis);
    novosNiveis[tipo] = nivelNovo;

    state = state.copyWith(niveis: novosNiveis);
    await _salvar();

    print('⭐ [XP Tempo] $tipo: +10 XP (48h vivo)');

    return (
      xpGanho: 10,
      subiuNivel: nivelNovo.level > nivelAtual.level,
    );
  }

  /// Usa Nuty para dar XP ao mascote ativo (5-10 XP)
  Future<({int xpGanho, bool subiuNivel})?> usarNuty() async {
    final mascote = state.mascoteAtivo;
    if (mascote == null) return null;

    // XP aleatório entre 5 e 10
    final xp = 5 + _random.nextInt(6);
    final resultado = await adicionarXp(xp);

    if (resultado == null) return null;

    return (xpGanho: resultado.xpGanho, subiuNivel: resultado.subiuNivel);
  }

  // ============ ECONOMIA (TEKS) ============

  /// Adiciona Teks (drop de batalha)
  Future<void> adicionarTeks(int quantidade) async {
    state = state.copyWith(teks: state.teks + quantidade);
    await _salvar();
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

    _salvar();
    return true;
  }

  // ============ AVENTURA INTEGRATION ============

  /// Adiciona interações disponíveis a todos os mascotes (chamado ao completar andar)
  Future<void> adicionarInteracoesDoAndar() async {
    if (state.mascotes.isEmpty) return;

    final novosMascotes = <String, Mascote>{};
    for (final entry in state.mascotes.entries) {
      novosMascotes[entry.key] = entry.value.copyWith(
        acariciarDisponiveis: entry.value.acariciarDisponiveis + 1,
        brincarDisponiveis: entry.value.brincarDisponiveis + 1,
      );
    }

    state = state.copyWith(mascotes: novosMascotes);
    await _salvar();
  }

  // ============ CONFIGURAÇÕES ============

  /// Atualiza configurações de notificação
  Future<void> atualizarConfig(ConfigCriadouro novaConfig) async {
    state = state.copyWith(config: novaConfig);
    await _salvar();
  }

  // ============ SERIALIZAÇÃO ============

  /// Exporta estado para JSON (para salvar no Drive)
  Map<String, dynamic> toJson() {
    final mascotesJson = <String, dynamic>{};
    for (final entry in state.mascotes.entries) {
      mascotesJson[entry.key] = entry.value.toJson();
    }

    final niveisJson = <String, dynamic>{};
    for (final entry in state.niveis.entries) {
      niveisJson[entry.key] = entry.value.toJson();
    }

    return {
      'mascotes': mascotesJson,
      'niveis': niveisJson,
      'memorial': state.memorial.map((m) => m.toJson()).toList(),
      'config': state.config.toJson(),
      'inventario': state.inventario.toJson(),
      'teks': state.teks,
    };
  }

  /// Importa estado do JSON (ao carregar do Drive)
  void fromJson(Map<String, dynamic> json) {
    // Converte mascotes
    final mascotesJson = json['mascotes'] as Map<String, dynamic>? ?? {};
    final mascotes = <String, Mascote>{};
    for (final entry in mascotesJson.entries) {
      mascotes[entry.key] = Mascote.fromJson(entry.value as Map<String, dynamic>);
    }

    // Converte níveis
    final niveisJson = json['niveis'] as Map<String, dynamic>? ?? {};
    final niveis = <String, LevelTipo>{};
    for (final entry in niveisJson.entries) {
      niveis[entry.key] = LevelTipo.fromJson(entry.value as Map<String, dynamic>);
    }

    carregarEstado(
      mascotes: mascotes,
      niveis: niveis,
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

/// Provider para verificar se tem pelo menos um mascote vivo
final temMascoteProvider = Provider<bool>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.temMascote;
});

/// Provider para verificar se o mascote ativo precisa de atenção
final precisaAtencaoProvider = Provider<bool>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.precisaAtencaoUrgente;
});

/// Provider para verificar se algum mascote precisa de atenção
final algumPrecisaAtencaoProvider = Provider<bool>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.algumPrecisaAtencao;
});

/// Provider para o mascote ativo (selecionado)
final mascoteProvider = Provider<Mascote?>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.mascoteAtivo;
});

/// Provider para todos os mascotes
final mascotesProvider = Provider<Map<String, Mascote>>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.mascotes;
});

/// Provider para lista de mascotes vivos
final mascotesVivosProvider = Provider<List<Mascote>>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.mascotesVivos;
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

/// Provider para verificar se já tem mascote de um tipo
final temMascoteTipoProvider = Provider.family<bool, String>((ref, tipo) {
  final state = ref.watch(criadouroProvider);
  return state.temMascoteTipo(tipo);
});

/// Provider para o nível do mascote ativo
final nivelAtivoProvider = Provider<LevelTipo?>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.nivelAtivo;
});

/// Provider para obter o nível de um tipo específico
final nivelTipoProvider = Provider.family<LevelTipo, String>((ref, tipo) {
  final state = ref.watch(criadouroProvider);
  return state.getNivel(tipo);
});

/// Provider para todos os níveis
final niveisProvider = Provider<Map<String, LevelTipo>>((ref) {
  final state = ref.watch(criadouroProvider);
  return state.niveis;
});
