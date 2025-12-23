import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../aventura/models/habilidade.dart';
import '../../aventura/services/colecao_service.dart';
import '../models/equipe_explorador.dart';
import '../models/monstro_explorador.dart';
import '../services/equipe_hive_service.dart';
import '../services/monstros_explorador_service.dart';

/// Provider do servico Hive para equipe
final equipeHiveServiceProvider = Provider<EquipeHiveService>((ref) {
  return EquipeHiveService();
});

/// Provider do servico para monstros individuais
final monstrosExploradorServiceProvider = Provider<MonstrosExploradorService>((ref) {
  return MonstrosExploradorService();
});

/// Provider da equipe do explorador
final equipeExploradorProvider =
    StateNotifierProvider<EquipeExploradorNotifier, EquipeExplorador?>((ref) {
  final hiveService = ref.watch(equipeHiveServiceProvider);
  final monstrosService = ref.watch(monstrosExploradorServiceProvider);
  final email = ref.watch(currentUserEmailProvider);
  return EquipeExploradorNotifier(hiveService, monstrosService, email);
});

/// Provider para listar monstros SALVOS (com XP/level) disponiveis para adicionar a equipe
final monstrosSalvosDisponiveisProvider = FutureProvider<List<MonstroExplorador>>((ref) async {
  final email = ref.watch(currentUserEmailProvider);
  if (email == null || email.isEmpty) return [];

  final equipe = ref.watch(equipeExploradorProvider);
  final monstrosService = ref.watch(monstrosExploradorServiceProvider);

  await monstrosService.init();

  // IDs dos monstros atualmente na equipe
  final idsNaEquipe = equipe?.todosMonstros.map((m) => m.id).toList() ?? [];

  // Retorna monstros salvos que NAO estao na equipe
  return await monstrosService.listarMonstrosDisponiveis(email, idsNaEquipe);
});

/// Provider para listar monstros NOVOS da colecao (sem XP)
final monstrosDisponiveisProvider = FutureProvider<List<MonstroDisponivel>>((ref) async {
  final email = ref.watch(currentUserEmailProvider);
  if (email == null || email.isEmpty) return [];

  final colecaoService = ColecaoService();
  final colecao = await colecaoService.carregarColecaoJogador(email);

  // Filtra apenas monstros desbloqueados
  final desbloqueados = colecao.entries
      .where((e) => e.value == true)
      .map((e) => e.key)
      .toList();

  // Converte para MonstroDisponivel
  final monstros = <MonstroDisponivel>[];
  for (final nome in desbloqueados) {
    // Ignora monstros Halloween por enquanto
    if (nome.startsWith('halloween_')) continue;

    try {
      final tipo = Tipo.values.firstWhere(
        (t) => t.name == nome,
        orElse: () => Tipo.normal,
      );

      final ehNostalgico = _ehMonstroNostalgico(nome);

      monstros.add(MonstroDisponivel(
        tipo: tipo,
        nome: ehNostalgico ? tipo.nostalgicMonsterName : tipo.monsterName,
        imagem: _getImagemMonstro(tipo, ehNostalgico),
        ehNostalgico: ehNostalgico,
      ));
    } catch (e) {
      // Ignora tipos invalidos
    }
  }

  return monstros;
});

/// Verifica se e monstro nostalgico
bool _ehMonstroNostalgico(String nome) {
  // Lista de monstros que podem ser nostalgicos
  const nostalgicos = [
    'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
    'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
    'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
    'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
    'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi'
  ];
  return nostalgicos.contains(nome);
}

/// Retorna caminho da imagem do monstro
String _getImagemMonstro(Tipo tipo, bool ehNostalgico) {
  final pasta = ehNostalgico ? 'colecao_nostalgicos' : 'colecao_inicial';
  return 'assets/monstros_aventura/$pasta/${tipo.name}.png';
}

/// Modelo para monstro disponivel na selecao
class MonstroDisponivel {
  final Tipo tipo;
  final String nome;
  final String imagem;
  final bool ehNostalgico;

  const MonstroDisponivel({
    required this.tipo,
    required this.nome,
    required this.imagem,
    this.ehNostalgico = false,
  });
}

/// Notifier da equipe do explorador
class EquipeExploradorNotifier extends StateNotifier<EquipeExplorador?> {
  final EquipeHiveService _hiveService;
  final MonstrosExploradorService _monstrosService;
  final String? _email;

  EquipeExploradorNotifier(this._hiveService, this._monstrosService, this._email) : super(null) {
    _loadEquipe();
  }

  /// Carrega equipe do storage
  Future<void> _loadEquipe() async {
    final email = _email;
    if (email == null || email.isEmpty) {
      state = const EquipeExplorador();
      return;
    }

    try {
      await _hiveService.init();
      final equipe = await _hiveService.carregarEquipe(email);
      state = equipe ?? const EquipeExplorador();
    } catch (e) {
      state = const EquipeExplorador();
    }
  }

  /// Salva equipe no storage
  Future<bool> _salvar() async {
    final email = _email;
    if (email == null || email.isEmpty || state == null) return false;

    try {
      return await _hiveService.salvarEquipe(email, state!);
    } catch (e) {
      return false;
    }
  }

  /// Adiciona monstro a equipe ativa
  Future<bool> adicionarMonstroAtivo(MonstroDisponivel monstroDisponivel) async {
    if (state == null) return false;
    if (state!.monstrosAtivos.length >= 2) return false;

    // Verifica se ja esta na equipe
    if (_monstroJaNaEquipe(monstroDisponivel.tipo)) return false;

    final novoMonstro = _criarMonstroExplorador(monstroDisponivel, estaAtivo: true);
    state = state!.adicionarMonstroAtivo(novoMonstro);
    return await _salvar();
  }

  /// Adiciona monstro ao banco
  Future<bool> adicionarMonstroAoBanco(MonstroDisponivel monstroDisponivel) async {
    if (state == null) return false;
    if (state!.monstrosBanco.length >= 3) return false;

    // Verifica se ja esta na equipe
    if (_monstroJaNaEquipe(monstroDisponivel.tipo)) return false;

    final novoMonstro = _criarMonstroExplorador(monstroDisponivel, estaAtivo: false);
    state = state!.adicionarMonstroAoBanco(novoMonstro);
    return await _salvar();
  }

  /// Verifica se monstro ja esta na equipe
  bool _monstroJaNaEquipe(Tipo tipo) {
    if (state == null) return false;
    return state!.todosMonstros.any((m) => m.tipo == tipo);
  }

  /// Cria MonstroExplorador a partir de MonstroDisponivel
  /// Usa os mesmos valores base do modo aventura (AtributoJogo)
  /// - Vida: 75
  /// - Energia: 20
  /// - Agilidade: 10
  /// - Ataque: 10
  /// - Defesa: 40
  MonstroExplorador _criarMonstroExplorador(
    MonstroDisponivel disponivel, {
    required bool estaAtivo,
  }) {
    return MonstroExplorador(
      id: '${disponivel.tipo.name}_${DateTime.now().millisecondsSinceEpoch}',
      tipo: disponivel.tipo,
      tipoExtra: disponivel.tipo, // Mesmo tipo por padrao
      imagem: disponivel.imagem,
      nome: disponivel.nome,
      vidaBase: 75, // Igual ao modo aventura (AtributoJogo.vida.min)
      energiaBase: 20, // Igual ao modo aventura (AtributoJogo.energia.min)
      ataqueBase: 10, // Igual ao modo aventura (AtributoJogo.ataque.min)
      defesaBase: 40, // Igual ao modo aventura (AtributoJogo.defesa.min)
      agilidadeBase: 10, // Igual ao modo aventura (AtributoJogo.agilidade.min)
      habilidades: _gerarHabilidadesIniciais(disponivel.tipo),
      estaAtivo: estaAtivo,
    );
  }

  /// Gera habilidades iniciais para o monstro
  List<Habilidade> _gerarHabilidadesIniciais(Tipo tipo) {
    return [
      Habilidade(
        nome: 'Ataque ${tipo.displayName}',
        descricao: 'Ataque basico do tipo ${tipo.displayName}',
        tipo: TipoHabilidade.ofensiva,
        efeito: EfeitoHabilidade.danoDirecto,
        tipoElemental: tipo,
        valor: 15,
        custoEnergia: 5,
        level: 1,
      ),
      Habilidade(
        nome: 'Golpe Forte',
        descricao: 'Golpe poderoso que causa mais dano',
        tipo: TipoHabilidade.ofensiva,
        efeito: EfeitoHabilidade.danoDirecto,
        tipoElemental: tipo,
        valor: 25,
        custoEnergia: 10,
        level: 1,
      ),
    ];
  }

  /// Remove monstro da equipe e salva no storage individual
  Future<bool> removerMonstro(String monstroId) async {
    if (state == null) return false;
    final email = _email;
    if (email == null || email.isEmpty) return false;

    // Busca o monstro antes de remover para salvar no storage individual
    final monstro = state!.todosMonstros.where((m) => m.id == monstroId).firstOrNull;
    if (monstro != null) {
      // Salva o monstro com seu XP/level no storage individual
      await _monstrosService.init();
      await _monstrosService.salvarMonstro(email, monstro);
    }

    state = state!.removerMonstro(monstroId);
    return await _salvar();
  }

  /// Move monstro do banco para ativo
  Future<bool> moverParaAtivo(String monstroId) async {
    if (state == null) return false;
    if (state!.monstrosAtivos.length >= 2) return false;

    try {
      state = state!.moverParaAtivo(monstroId);
      return await _salvar();
    } catch (e) {
      return false;
    }
  }

  /// Move monstro do ativo para banco
  Future<bool> moverParaBanco(String monstroId) async {
    if (state == null) return false;
    if (state!.monstrosBanco.length >= 3) return false;

    try {
      state = state!.moverParaBanco(monstroId);
      return await _salvar();
    } catch (e) {
      return false;
    }
  }

  /// Troca posicao de dois monstros
  Future<bool> trocarMonstros(String monstroId1, String monstroId2) async {
    if (state == null) return false;

    try {
      state = state!.trocarMonstros(monstroId1, monstroId2);
      return await _salvar();
    } catch (e) {
      return false;
    }
  }

  /// Adiciona monstro salvo (com XP/level existente) a equipe ativa
  Future<bool> adicionarMonstroSalvoAtivo(MonstroExplorador monstro) async {
    if (state == null) return false;
    if (state!.monstrosAtivos.length >= 2) return false;

    // Verifica se ja esta na equipe
    if (state!.todosMonstros.any((m) => m.id == monstro.id)) return false;

    final monstroAtivo = monstro.copyWith(estaAtivo: true);
    state = state!.adicionarMonstroAtivo(monstroAtivo);

    // Remove do storage individual pois agora esta na equipe
    final email = _email;
    if (email != null && email.isNotEmpty) {
      await _monstrosService.init();
      await _monstrosService.removerMonstro(email, monstro.id);
    }

    return await _salvar();
  }

  /// Adiciona monstro salvo (com XP/level existente) ao banco
  Future<bool> adicionarMonstroSalvoBanco(MonstroExplorador monstro) async {
    if (state == null) return false;
    if (state!.monstrosBanco.length >= 3) return false;

    // Verifica se ja esta na equipe
    if (state!.todosMonstros.any((m) => m.id == monstro.id)) return false;

    final monstroBanco = monstro.copyWith(estaAtivo: false);
    state = state!.adicionarMonstroAoBanco(monstroBanco);

    // Remove do storage individual pois agora esta na equipe
    final email = _email;
    if (email != null && email.isNotEmpty) {
      await _monstrosService.init();
      await _monstrosService.removerMonstro(email, monstro.id);
    }

    return await _salvar();
  }

  /// Distribui XP apos batalha (versao simples)
  Future<bool> distribuirXp(int xpBatalha) async {
    if (state == null) return false;

    state = state!.distribuirXp(xpBatalha);
    return await _salvar();
  }

  /// Distribui XP apos batalha e retorna resultado com info de quem ganhou
  Future<XpDistribuicaoResult?> distribuirXpComResultado(int xpBatalha) async {
    if (state == null) return null;

    final resultado = state!.distribuirXpComResultado(xpBatalha);
    state = resultado.novaEquipe;
    await _salvar();
    return resultado;
  }

  /// Cura toda a equipe
  Future<bool> curarEquipe() async {
    if (state == null) return false;

    state = state!.curarEquipe();
    return await _salvar();
  }

  /// Registra batalha
  Future<bool> registrarBatalha({bool vitoria = true}) async {
    if (state == null) return false;

    state = state!.registrarBatalha(vitoria: vitoria);
    return await _salvar();
  }

  /// Muda tier
  Future<bool> mudarTier(int novoTier) async {
    if (state == null) return false;

    state = state!.mudarTier(novoTier);
    return await _salvar();
  }

  /// Reseta equipe
  Future<bool> resetarEquipe() async {
    state = const EquipeExplorador();
    return await _salvar();
  }

  /// Recarrega equipe do storage
  Future<void> reload() async {
    await _loadEquipe();
  }
}
