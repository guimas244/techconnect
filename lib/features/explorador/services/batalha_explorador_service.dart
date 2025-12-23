import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../aventura/models/monstro_aventura.dart';
import '../../aventura/models/monstro_inimigo.dart';
import '../../aventura/models/habilidade.dart';
import '../models/monstro_explorador.dart';
import '../models/mapa_explorador.dart';

/// Servico para converter monstros do explorador para o formato de batalha
class BatalhaExploradorService {

  /// Converte MonstroExplorador para MonstroAventura para usar no BatalhaScreen
  /// Se o mapa for fornecido e o monstro tiver tipo nativo, ganha +25% HP
  static MonstroAventura converterParaAventura(
    MonstroExplorador monstro, {
    MapaExplorador? mapa,
  }) {
    int vida = monstro.vidaTotal;
    int vidaAtual = monstro.vidaAtual;

    // Bonus de 25% HP se o monstro tem tipo nativo do mapa
    if (mapa != null && _temTipoNativo(monstro.tipo, monstro.tipoExtra, mapa)) {
      final bonus = (vida * MapaExplorador.bonusHpNativo).round();
      vida += bonus;
      vidaAtual += bonus;
    }

    return MonstroAventura(
      tipo: monstro.tipo,
      tipoExtra: monstro.tipoExtra,
      imagem: monstro.imagem,
      vida: vida,
      vidaAtual: vidaAtual,
      energia: monstro.energiaTotal,
      energiaAtual: monstro.energiaAtual,
      agilidade: monstro.agilidadeTotal,
      ataque: monstro.ataqueTotal,
      defesa: monstro.defesaTotal,
      habilidades: monstro.habilidades,
      level: monstro.level,
    );
  }

  /// Verifica se o monstro tem algum tipo nativo do mapa
  static bool _temTipoNativo(Tipo tipo, Tipo? tipoExtra, MapaExplorador mapa) {
    if (mapa.tipoNativo(tipo)) return true;
    if (tipoExtra != null && mapa.tipoNativo(tipoExtra)) return true;
    return false;
  }

  /// Gera um MonstroInimigo baseado no mapa e tier
  ///
  /// Sistema de tipos:
  /// - Usa os tipos pre-sorteados em mapa.tiposEncontrados
  /// - Tipos nativos (em mapa.tiposInimigos) ganham +25% HP
  ///
  /// A raridade do mapa determina se o inimigo e elite:
  /// - 3 estrelas (umElite): 1 inimigo elite (precisa controlar externamente)
  /// - 4 estrelas (todosElite): todos os inimigos sao elite
  /// - 5 estrelas (boss): mapa de boss (tratado separadamente)
  static MonstroInimigo gerarInimigo({
    required MapaExplorador mapa,
    required int tier,
    bool forcarElite = false,
    int indiceBatalha = 0, // 0, 1 ou 2 para saber qual batalha
  }) {
    // Usa o tipo pre-sorteado para esta batalha
    final Tipo tipo;
    if (indiceBatalha < mapa.tiposEncontrados.length) {
      tipo = mapa.tiposEncontrados[indiceBatalha];
    } else {
      // Fallback: usa o primeiro tipo se indice invalido
      tipo = mapa.tiposEncontrados.isNotEmpty
          ? mapa.tiposEncontrados.first
          : mapa.tipoPrincipal;
    }

    // Verifica se o tipo e nativo (tem bonus +25% HP)
    final tipoNativo = mapa.tipoNativo(tipo);

    // Determina se este inimigo e elite baseado na raridade
    bool isElite = forcarElite;
    if (mapa.raridade.todosSaoElite) {
      // 4 estrelas - todos sao elite
      isElite = true;
    } else if (mapa.raridade.temElite && indiceBatalha == 1) {
      // 3 estrelas - apenas o segundo inimigo e elite
      isElite = true;
    }

    // Calcula multiplicador baseado no tier
    double multiplicador = 1.0 + (tier - 1) * 0.12;

    // Elite tem 50% mais stats
    if (isElite) {
      multiplicador *= 1.5;
    }

    // Stats base escalados pelo tier
    double vida = (75 + tier * 15) * multiplicador;
    final ataque = (12 + tier * 3) * multiplicador;
    final defesa = (8 + tier * 2) * multiplicador;
    final agilidade = (10 + tier * 1.5) * multiplicador;
    final energia = (20 + tier * 5) * multiplicador;

    // Bonus de 25% HP para tipos nativos do mapa
    if (tipoNativo) {
      vida *= (1 + MapaExplorador.bonusHpNativo);
    }

    // Gera habilidades baseadas no tipo
    final habilidades = _gerarHabilidades(tipo, tier);

    // Determina a imagem do inimigo
    final imagem = _getImagemInimigo(tipo);

    return MonstroInimigo(
      tipo: tipo,
      tipoExtra: null,
      imagem: imagem,
      vida: vida.round(),
      vidaAtual: vida.round(),
      energia: energia.round(),
      energiaAtual: energia.round(),
      agilidade: agilidade.round(),
      ataque: ataque.round(),
      defesa: defesa.round(),
      habilidades: habilidades,
      level: tier,
      isElite: isElite,
    );
  }

  /// Gera habilidades para o inimigo baseado no tipo
  static List<Habilidade> _gerarHabilidades(Tipo tipo, int tier) {
    // Habilidade basica de ataque
    final ataqueBasico = Habilidade(
      nome: 'Ataque ${tipo.displayName}',
      descricao: 'Ataque basico',
      tipo: TipoHabilidade.ofensiva,
      efeito: EfeitoHabilidade.danoDirecto,
      tipoElemental: tipo,
      valor: 15 + tier * 3,
      custoEnergia: 0,
      level: 1,
    );

    // Habilidade especial
    final especial = Habilidade(
      nome: 'Furia ${tipo.displayName}',
      descricao: 'Ataque especial poderoso',
      tipo: TipoHabilidade.ofensiva,
      efeito: EfeitoHabilidade.danoDirecto,
      tipoElemental: tipo,
      valor: 25 + tier * 5,
      custoEnergia: 10 + tier,
      level: 1,
    );

    return [ataqueBasico, especial];
  }

  /// Retorna a imagem do inimigo baseado no tipo
  static String _getImagemInimigo(Tipo tipo) {
    // Usa as imagens da colecao inicial como inimigos
    return 'assets/monstros_aventura/colecao_inicial/${tipo.name}.png';
  }

  /// Calcula XP ganho na vitoria
  /// - Base: tier por batalha
  /// - 2 estrelas: +25% bonus
  /// - 5 estrelas (boss): 5x o normal
  static int calcularXpGanho(int tier, RaridadeMapa raridade) {
    int xp = tier;

    if (raridade.temBonusXp) {
      xp = (xp * 1.25).round();
    } else if (raridade.isBoss) {
      xp = xp * 5;
    }

    return xp;
  }

  /// Calcula kills ganhos na vitoria
  /// - Boss: 3x os kills normais
  static int calcularKillsGanho(int tier, RaridadeMapa raridade) {
    int kills = (tier / 2).ceil() + 1;

    if (raridade.isBoss) {
      kills = kills * 3;
    }

    return kills;
  }
}
