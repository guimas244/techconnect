import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/habilidade.dart';
import '../models/item.dart';
import '../models/mochila.dart';
import '../models/item_consumivel.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../tipagem/data/tipagem_repository.dart';

/// Role/Função do monstro na equipe
/// Define quais tipos de magias cada monstro deve ter
enum RoleMonstro {
  /// Monstro 1: Full dano - 4 magias de dano direto
  atacante,
  /// Monstro 2: 2 defesa + 1 aumentar vida + 1 aumentar dano
  tank,
  /// Monstro 3: Magias com mais pontos (exceto curar vida/energia)
  flex,
}

/// Serviço que gerencia o modo automático da aventura
/// Responsável por:
/// - Selecionar o melhor monstro para cada batalha (baseado em vantagem de tipo)
/// - Selecionar a melhor habilidade de dano puro
/// - Determinar se um item deve ser equipado automaticamente
class AutoModeService {
  final TipagemRepository _tipagemRepository = TipagemRepository();

  /// Calcula o score de vantagem de um monstro contra um inimigo
  /// Considera:
  /// - Setas verdes (vantagem): multiplicador > 1.0 = EU causo mais dano
  /// - Setas vermelhas (desvantagem): multiplicador > 1.0 = EU recebo mais dano
  ///
  /// Score positivo = tenho vantagem
  /// Score negativo = tenho desvantagem
  Future<double> calcularScoreVantagem(
    MonstroAventura monstro,
    MonstroInimigo inimigo,
  ) async {
    double scoreOfensivo = 0.0;
    double scoreDefensivo = 0.0;

    try {
      // Carrega dados de defesa do inimigo (para calcular quanto dano EU causo)
      final dadosDefesaInimigo = await _tipagemRepository.carregarDadosTipo(inimigo.tipo);

      // Carrega dados de defesa do MEU monstro (para calcular quanto dano EU RECEBO)
      final dadosDefesaMeu = await _tipagemRepository.carregarDadosTipo(monstro.tipo);

      // === SCORE OFENSIVO (quanto dano EU causo) ===
      if (dadosDefesaInimigo != null) {
        // Tipo principal do meu monstro atacando o inimigo
        final efetividadePrincipal = dadosDefesaInimigo[monstro.tipo] ?? 1.0;
        // Tipo extra do meu monstro atacando o inimigo
        final efetividadeExtra = dadosDefesaInimigo[monstro.tipoExtra] ?? 1.0;

        // Converte multiplicador para score:
        // > 1.0 (super efetivo/seta verde) = score positivo
        // < 1.0 (não efetivo/seta vermelha) = score negativo
        // = 1.0 (neutro) = score 0
        scoreOfensivo += (efetividadePrincipal - 1.0) * 3.0; // Principal tem peso maior
        scoreOfensivo += (efetividadeExtra - 1.0) * 2.0;     // Extra tem peso menor

        print('⚔️ [AutoMode] Ofensivo ${monstro.tipo.displayName}/${monstro.tipoExtra.displayName} vs ${inimigo.tipo.displayName}:');
        print('   Principal: ${efetividadePrincipal}x -> score ${(efetividadePrincipal - 1.0) * 3.0}');
        print('   Extra: ${efetividadeExtra}x -> score ${(efetividadeExtra - 1.0) * 2.0}');
      }

      // === SCORE DEFENSIVO (quanto dano EU RECEBO) ===
      if (dadosDefesaMeu != null) {
        // Quanto o inimigo causa em mim
        final efetividadeInimigoContraMim = dadosDefesaMeu[inimigo.tipo] ?? 1.0;

        // Converte multiplicador para score (INVERTIDO - menos dano é melhor):
        // > 1.0 (inimigo super efetivo/seta vermelha para mim) = score NEGATIVO
        // < 1.0 (inimigo não efetivo/seta verde para mim) = score POSITIVO
        scoreDefensivo -= (efetividadeInimigoContraMim - 1.0) * 2.5; // Penaliza desvantagem defensiva

        print('🛡️ [AutoMode] Defensivo ${inimigo.tipo.displayName} vs ${monstro.tipo.displayName}:');
        print('   Multiplicador: ${efetividadeInimigoContraMim}x -> score ${-(efetividadeInimigoContraMim - 1.0) * 2.5}');
      }

      // === BÔNUS POR VIDA ===
      double bonusVida = 0.0;
      if (monstro.vidaAtual > 0) {
        final percentualVida = monstro.vidaAtual / monstro.vida;
        bonusVida = percentualVida * 0.5; // Pequeno bônus por vida alta
      }

      final scoreTotal = scoreOfensivo + scoreDefensivo + bonusVida;

      print('📊 [AutoMode] Score ${monstro.tipo.displayName}:');
      print('   Ofensivo: $scoreOfensivo | Defensivo: $scoreDefensivo | Vida: $bonusVida');
      print('   TOTAL: $scoreTotal');

      return scoreTotal;

    } catch (e) {
      print('❌ [AutoMode] Erro ao calcular vantagem: $e');
      return 0.0; // Neutro em caso de erro
    }
  }

  /// Seleciona o melhor monstro da lista para enfrentar o inimigo
  /// Retorna o monstro com maior score de vantagem que esteja vivo
  Future<MonstroAventura?> selecionarMelhorMonstro(
    List<MonstroAventura> monstros,
    MonstroInimigo inimigo,
  ) async {
    if (monstros.isEmpty) return null;

    // Filtra apenas monstros vivos
    final monstrosVivos = monstros.where((m) => m.vidaAtual > 0).toList();
    if (monstrosVivos.isEmpty) return null;

    MonstroAventura? melhorMonstro;
    double melhorScore = double.negativeInfinity;

    print('🤖 [AutoMode] Analisando ${monstrosVivos.length} monstros vivos contra ${inimigo.tipo.displayName}...');

    for (final monstro in monstrosVivos) {
      final score = await calcularScoreVantagem(monstro, inimigo);

      if (score > melhorScore) {
        melhorScore = score;
        melhorMonstro = monstro;
      }
    }

    if (melhorMonstro != null) {
      print('✅ [AutoMode] Melhor monstro: ${melhorMonstro.tipo.displayName} (score: $melhorScore)');
    }

    return melhorMonstro;
  }

  /// Seleciona a melhor habilidade de dano para usar
  /// Prioriza:
  /// 1. Habilidades ofensivas (não suporte)
  /// 2. Maior valor de dano efetivo
  /// 3. Vantagem de tipo contra o inimigo (se possível)
  Future<Habilidade?> selecionarMelhorHabilidadeDano(
    List<Habilidade> habilidades,
    int energiaAtual,
    List<String> habilidadesUsadas,
    Tipo tipoInimigo,
  ) async {
    // Filtra habilidades disponíveis
    final habilidadesDisponiveis = habilidades.where((h) {
      // Verifica se tem energia suficiente
      if (h.custoEnergia > energiaAtual) return false;

      // Verifica se já foi usada (apenas para suporte)
      if (h.tipo == TipoHabilidade.suporte && habilidadesUsadas.contains(h.nome)) {
        return false;
      }

      return true;
    }).toList();

    if (habilidadesDisponiveis.isEmpty) return null;

    // Separa habilidades ofensivas das de suporte
    final habilidadesOfensivas = habilidadesDisponiveis
        .where((h) => h.tipo == TipoHabilidade.ofensiva)
        .toList();

    // Se não tem habilidades ofensivas disponíveis, retorna null (vai usar ataque básico)
    if (habilidadesOfensivas.isEmpty) {
      print('⚠️ [AutoMode] Sem habilidades ofensivas disponíveis');
      return null;
    }

    // Carrega dados de defesa do inimigo para calcular efetividade
    final dadosDefesaInimigo = await _tipagemRepository.carregarDadosTipo(tipoInimigo);

    Habilidade? melhorHabilidade;
    double melhorDanoEsperado = double.negativeInfinity;

    for (final habilidade in habilidadesOfensivas) {
      // Calcula dano esperado considerando tipo
      double multiplicadorTipo = 1.0;
      if (dadosDefesaInimigo != null) {
        multiplicadorTipo = dadosDefesaInimigo[habilidade.tipoElemental] ?? 1.0;
      }

      // Dano esperado = valor efetivo * multiplicador de tipo
      final danoEsperado = habilidade.valorEfetivo * multiplicadorTipo;

      print('🎯 [AutoMode] ${habilidade.nome}: dano=${habilidade.valorEfetivo} x tipo=$multiplicadorTipo = $danoEsperado');

      if (danoEsperado > melhorDanoEsperado) {
        melhorDanoEsperado = danoEsperado;
        melhorHabilidade = habilidade;
      }
    }

    if (melhorHabilidade != null) {
      print('✅ [AutoMode] Melhor habilidade: ${melhorHabilidade.nome} (dano esperado: $melhorDanoEsperado)');
    }

    return melhorHabilidade;
  }

  // ============================================================
  // SISTEMA DE ROLES PARA MAGIAS
  // ============================================================

  /// Determina o role de um monstro baseado na sua posição na equipe
  /// Monstro 0 = Atacante, Monstro 1 = Tank, Monstro 2 = Flex
  RoleMonstro getRoleMonstro(List<MonstroAventura> monstros, MonstroAventura monstro) {
    final index = monstros.indexOf(monstro);
    switch (index) {
      case 0:
        return RoleMonstro.atacante;
      case 1:
        return RoleMonstro.tank;
      default:
        return RoleMonstro.flex;
    }
  }

  /// Verifica se uma magia é do tipo "aumentar energia" (SEMPRE trocar)
  bool _ehMagiaCurarEnergia(Habilidade habilidade) {
    return habilidade.tipo == TipoHabilidade.suporte &&
           habilidade.efeito == EfeitoHabilidade.aumentarEnergia;
  }

  /// Verifica se uma magia é do tipo "curar vida" (trocar por aumentar vida)
  bool _ehMagiaCurarVida(Habilidade habilidade) {
    return habilidade.tipo == TipoHabilidade.suporte &&
           habilidade.efeito == EfeitoHabilidade.curarVida;
  }

  /// Verifica se uma magia é do tipo "aumentar vida" (buff vida máxima)
  bool _ehMagiaAumentarVida(Habilidade habilidade) {
    return habilidade.tipo == TipoHabilidade.suporte &&
           habilidade.efeito == EfeitoHabilidade.aumentarVida;
  }

  /// Verifica se uma magia é do tipo "aumentar dano/ataque"
  bool _ehMagiaAumentarDano(Habilidade habilidade) {
    return habilidade.tipo == TipoHabilidade.suporte &&
           habilidade.efeito == EfeitoHabilidade.aumentarAtaque;
  }

  /// Verifica se uma magia é do tipo "aumentar defesa"
  bool _ehMagiaDefesa(Habilidade habilidade) {
    return habilidade.tipo == TipoHabilidade.suporte &&
           habilidade.efeito == EfeitoHabilidade.aumentarDefesa;
  }

  /// Verifica se uma magia é de dano direto
  bool _ehMagiaDano(Habilidade habilidade) {
    return habilidade.tipo == TipoHabilidade.ofensiva;
  }

  /// Conta quantas magias de cada tipo o monstro tem
  ({int dano, int defesa, int aumentarVida, int aumentarDano, int curarVida, int curarEnergia})
  _contarTiposMagia(MonstroAventura monstro) {
    int dano = 0, defesa = 0, aumentarVida = 0, aumentarDano = 0, curarVida = 0, curarEnergia = 0;

    for (final h in monstro.habilidades) {
      if (_ehMagiaDano(h)) dano++;
      else if (_ehMagiaDefesa(h)) defesa++;
      else if (_ehMagiaAumentarVida(h)) aumentarVida++;
      else if (_ehMagiaAumentarDano(h)) aumentarDano++;
      else if (_ehMagiaCurarVida(h)) curarVida++;
      else if (_ehMagiaCurarEnergia(h)) curarEnergia++;
    }

    return (dano: dano, defesa: defesa, aumentarVida: aumentarVida,
            aumentarDano: aumentarDano, curarVida: curarVida, curarEnergia: curarEnergia);
  }

  /// Verifica se uma magia nova é válida para o role do monstro
  /// Retorna a habilidade a substituir, ou null se não deve equipar
  Habilidade? _selecionarHabilidadeParaSubstituirComRole(
    MonstroAventura monstro,
    RoleMonstro role,
    int valorMagiaNova,
    int levelMagiaNova,
    TipoHabilidade tipoMagiaNova,
    EfeitoHabilidade efeitoMagiaNova,
  ) {
    final pontosMagiaNova = valorMagiaNova * levelMagiaNova;
    final contagem = _contarTiposMagia(monstro);

    print('🎭 [AutoMode/Role] Monstro ${monstro.tipo.displayName} é $role');
    print('   Contagem atual: dano=${contagem.dano}, defesa=${contagem.defesa}, aumentarVida=${contagem.aumentarVida}, aumentarDano=${contagem.aumentarDano}');
    print('   Magia nova: tipo=$tipoMagiaNova, efeito=$efeitoMagiaNova, pontos=$pontosMagiaNova');

    // REGRA UNIVERSAL: Sempre trocar "curar energia" por qualquer coisa
    final magiaCurarEnergia = monstro.habilidades.where(_ehMagiaCurarEnergia).firstOrNull;
    if (magiaCurarEnergia != null) {
      print('🔄 [AutoMode/Role] Encontrada magia "curar energia" - SEMPRE substituir');
      return magiaCurarEnergia;
    }

    // REGRA UNIVERSAL: Trocar "curar vida" por "aumentar vida"
    if (efeitoMagiaNova == EfeitoHabilidade.aumentarVida) {
      final magiaCurarVida = monstro.habilidades.where(_ehMagiaCurarVida).firstOrNull;
      if (magiaCurarVida != null) {
        print('🔄 [AutoMode/Role] Trocando "curar vida" por "aumentar vida"');
        return magiaCurarVida;
      }
    }

    switch (role) {
      case RoleMonstro.atacante:
        return _selecionarParaAtacante(monstro, pontosMagiaNova, tipoMagiaNova, efeitoMagiaNova);

      case RoleMonstro.tank:
        return _selecionarParaTank(monstro, pontosMagiaNova, tipoMagiaNova, efeitoMagiaNova, contagem);

      case RoleMonstro.flex:
        return _selecionarParaFlex(monstro, pontosMagiaNova, tipoMagiaNova, efeitoMagiaNova);
    }
  }

  /// ATACANTE: Só aceita magias de dano direto
  Habilidade? _selecionarParaAtacante(
    MonstroAventura monstro,
    int pontosMagiaNova,
    TipoHabilidade tipoMagiaNova,
    EfeitoHabilidade efeitoMagiaNova,
  ) {
    // Atacante só aceita magias de dano
    if (tipoMagiaNova != TipoHabilidade.ofensiva) {
      print('⏭️ [AutoMode/Atacante] Magia não é de dano, ignorando');
      return null;
    }

    // Primeiro: substituir qualquer magia de suporte por dano
    for (final h in monstro.habilidades) {
      if (h.tipo == TipoHabilidade.suporte) {
        print('🔄 [AutoMode/Atacante] Substituindo suporte ${h.nome} por dano');
        return h;
      }
    }

    // Segundo: substituir a magia de dano com menos pontos
    Habilidade? piorDano;
    int menorPontos = 999999;

    for (final h in monstro.habilidades) {
      if (h.tipo == TipoHabilidade.ofensiva && h.valorEfetivo < menorPontos) {
        menorPontos = h.valorEfetivo;
        piorDano = h;
      }
    }

    if (piorDano != null && pontosMagiaNova > menorPontos) {
      print('✅ [AutoMode/Atacante] Magia nova ($pontosMagiaNova) > pior atual ($menorPontos)');
      return piorDano;
    }

    print('❌ [AutoMode/Atacante] Magia nova não é melhor que as atuais');
    return null;
  }

  /// TANK: 2 defesa + 1 aumentar vida + 1 aumentar dano
  Habilidade? _selecionarParaTank(
    MonstroAventura monstro,
    int pontosMagiaNova,
    TipoHabilidade tipoMagiaNova,
    EfeitoHabilidade efeitoMagiaNova,
    ({int dano, int defesa, int aumentarVida, int aumentarDano, int curarVida, int curarEnergia}) contagem,
  ) {
    // Magia de DEFESA - Tank precisa de 2
    if (efeitoMagiaNova == EfeitoHabilidade.aumentarDefesa) {
      if (contagem.defesa < 2) {
        // Precisa de mais defesa - substituir qualquer coisa que não seja defesa
        for (final h in monstro.habilidades) {
          if (!_ehMagiaDefesa(h) && !_ehMagiaAumentarVida(h) && !_ehMagiaAumentarDano(h)) {
            print('✅ [AutoMode/Tank] Adicionando defesa (${contagem.defesa}/2)');
            return h;
          }
        }
        // Se não encontrou, substituir a defesa mais fraca
        return _encontrarMagiaMaisFracaDoTipo(monstro, EfeitoHabilidade.aumentarDefesa, pontosMagiaNova);
      } else {
        // Já tem 2 defesas, só substitui se for melhor
        return _encontrarMagiaMaisFracaDoTipo(monstro, EfeitoHabilidade.aumentarDefesa, pontosMagiaNova);
      }
    }

    // Magia de AUMENTAR VIDA - Tank precisa de 1
    if (efeitoMagiaNova == EfeitoHabilidade.aumentarVida) {
      if (contagem.aumentarVida < 1) {
        // Precisa de aumentar vida - substituir qualquer coisa que não seja essencial
        for (final h in monstro.habilidades) {
          if (!_ehMagiaDefesa(h) && !_ehMagiaAumentarDano(h)) {
            print('✅ [AutoMode/Tank] Adicionando aumentar vida (${contagem.aumentarVida}/1)');
            return h;
          }
        }
      }
      return _encontrarMagiaMaisFracaDoTipo(monstro, EfeitoHabilidade.aumentarVida, pontosMagiaNova);
    }

    // Magia de AUMENTAR DANO - Tank precisa de 1
    if (efeitoMagiaNova == EfeitoHabilidade.aumentarAtaque) {
      if (contagem.aumentarDano < 1) {
        // Precisa de aumentar dano - substituir qualquer coisa que não seja essencial
        for (final h in monstro.habilidades) {
          if (!_ehMagiaDefesa(h) && !_ehMagiaAumentarVida(h)) {
            print('✅ [AutoMode/Tank] Adicionando aumentar dano (${contagem.aumentarDano}/1)');
            return h;
          }
        }
      }
      return _encontrarMagiaMaisFracaDoTipo(monstro, EfeitoHabilidade.aumentarAtaque, pontosMagiaNova);
    }

    // Tank não aceita outras magias (dano, cura, etc) a menos que precise preencher slots
    print('⏭️ [AutoMode/Tank] Magia não é útil para Tank');
    return null;
  }

  /// FLEX: Aceita qualquer magia exceto curar vida/energia, prioriza pontos
  Habilidade? _selecionarParaFlex(
    MonstroAventura monstro,
    int pontosMagiaNova,
    TipoHabilidade tipoMagiaNova,
    EfeitoHabilidade efeitoMagiaNova,
  ) {
    // Flex NÃO aceita curar vida ou curar energia
    if (efeitoMagiaNova == EfeitoHabilidade.curarVida ||
        efeitoMagiaNova == EfeitoHabilidade.aumentarEnergia) {
      print('⏭️ [AutoMode/Flex] Magia de cura vida/energia ignorada');
      return null;
    }

    // Encontra a habilidade com menos pontos para substituir
    Habilidade? piorHabilidade;
    int menorPontos = 999999;

    for (final h in monstro.habilidades) {
      // Sempre pode substituir curar vida/energia
      if (_ehMagiaCurarVida(h) || _ehMagiaCurarEnergia(h)) {
        print('🔄 [AutoMode/Flex] Substituindo ${h.nome} (cura) por magia melhor');
        return h;
      }

      if (h.valorEfetivo < menorPontos) {
        menorPontos = h.valorEfetivo;
        piorHabilidade = h;
      }
    }

    // Substitui se a nova tiver mais pontos
    if (piorHabilidade != null && pontosMagiaNova > menorPontos) {
      print('✅ [AutoMode/Flex] Magia nova ($pontosMagiaNova) > pior atual ($menorPontos)');
      return piorHabilidade;
    }

    print('❌ [AutoMode/Flex] Magia nova não é melhor que as atuais');
    return null;
  }

  /// Encontra a magia mais fraca de um tipo específico
  Habilidade? _encontrarMagiaMaisFracaDoTipo(
    MonstroAventura monstro,
    EfeitoHabilidade efeito,
    int pontosMagiaNova,
  ) {
    Habilidade? maisFraca;
    int menorPontos = 999999;

    for (final h in monstro.habilidades) {
      if (h.efeito == efeito && h.valorEfetivo < menorPontos) {
        menorPontos = h.valorEfetivo;
        maisFraca = h;
      }
    }

    if (maisFraca != null && pontosMagiaNova > menorPontos) {
      return maisFraca;
    }
    return null;
  }

  /// Seleciona o melhor monstro para receber uma magia nova (COM SISTEMA DE ROLES)
  /// Retorna o monstro e a habilidade a substituir, ou null se não vale
  ({MonstroAventura monstro, Habilidade habilidade})? selecionarMonstroParaMagia(
    List<MonstroAventura> monstros,
    int valorMagia,
    int levelMagia,
    TipoHabilidade tipoMagia,
    {EfeitoHabilidade? efeitoMagia}
  ) {
    if (monstros.isEmpty) return null;

    final pontosMagia = valorMagia * levelMagia;
    final efeito = efeitoMagia ?? EfeitoHabilidade.danoDirecto;

    print('🎯 [AutoMode] Selecionando monstro para magia: tipo=$tipoMagia, efeito=$efeito, pontos=$pontosMagia');

    // Tenta equipar no monstro mais adequado baseado no role
    MonstroAventura? melhorMonstro;
    Habilidade? melhorHabilidade;
    int melhorGanho = -999999;

    for (final monstro in monstros) {
      final role = getRoleMonstro(monstros, monstro);

      final habilidade = _selecionarHabilidadeParaSubstituirComRole(
        monstro, role, valorMagia, levelMagia, tipoMagia, efeito,
      );

      if (habilidade != null) {
        final ganho = pontosMagia - habilidade.valorEfetivo;

        // Prioriza o role mais adequado para o tipo de magia
        int bonusRole = 0;
        if (tipoMagia == TipoHabilidade.ofensiva && role == RoleMonstro.atacante) {
          bonusRole = 1000; // Atacante tem prioridade para magias de dano
        } else if (tipoMagia == TipoHabilidade.suporte) {
          if (efeito == EfeitoHabilidade.aumentarDefesa && role == RoleMonstro.tank) {
            bonusRole = 1000; // Tank tem prioridade para defesa
          } else if (efeito == EfeitoHabilidade.aumentarVida && role == RoleMonstro.tank) {
            bonusRole = 800; // Tank tem prioridade para aumentar vida
          } else if (efeito == EfeitoHabilidade.aumentarAtaque && role == RoleMonstro.tank) {
            bonusRole = 600; // Tank tem prioridade para aumentar dano
          }
        }

        final ganhoComBonus = ganho + bonusRole;

        if (ganhoComBonus > melhorGanho) {
          melhorGanho = ganhoComBonus;
          melhorMonstro = monstro;
          melhorHabilidade = habilidade;
        }
      }
    }

    if (melhorMonstro != null && melhorHabilidade != null) {
      final role = getRoleMonstro(monstros, melhorMonstro);
      print('✅ [AutoMode] Magia vai para ${melhorMonstro.tipo.displayName} ($role)');
      print('   Substituindo: ${melhorHabilidade.nome}');
      return (monstro: melhorMonstro, habilidade: melhorHabilidade);
    }

    print('❌ [AutoMode] Nenhum monstro pode usar esta magia');
    return null;
  }

  /// Método legado para compatibilidade (sem efeito)
  Habilidade? selecionarHabilidadeParaSubstituir(
    MonstroAventura monstro,
    int valorMagiaNova,
    int levelMagiaNova,
    TipoHabilidade tipoMagiaNova,
  ) {
    // Usa o sistema novo com role flex como fallback
    return _selecionarHabilidadeParaSubstituirComRole(
      monstro,
      RoleMonstro.flex,
      valorMagiaNova,
      levelMagiaNova,
      tipoMagiaNova,
      tipoMagiaNova == TipoHabilidade.ofensiva
        ? EfeitoHabilidade.danoDirecto
        : EfeitoHabilidade.curarVida,
    );
  }

  /// Determina se um item novo é melhor que o item atual
  /// Compara total de atributos IGNORANDO energia
  /// Retorna true se o novo item é melhor
  bool itemNovoBelhor(Item? itemAtual, Item itemNovo) {
    if (itemAtual == null) {
      // Se não tem item, qualquer item é melhor
      print('✅ [AutoMode] Sem item equipado, equipando ${itemNovo.nome}');
      return true;
    }

    // Calcula total de pontos IGNORANDO energia
    int pontosAtual = _calcularPontosItem(itemAtual);
    int pontosNovo = _calcularPontosItem(itemNovo);

    print('📊 [AutoMode] Comparando itens:');
    print('   Atual: ${itemAtual.nome} = $pontosAtual pontos (sem energia)');
    print('   Novo: ${itemNovo.nome} = $pontosNovo pontos (sem energia)');

    if (pontosNovo > pontosAtual) {
      print('✅ [AutoMode] Item novo é melhor! Equipando...');
      return true;
    } else {
      print('❌ [AutoMode] Item atual é melhor ou igual. Mantendo...');
      return false;
    }
  }

  /// Calcula pontos totais de um item IGNORANDO energia
  int _calcularPontosItem(Item item) {
    int pontos = 0;

    // Soma todos os atributos EXCETO energia
    pontos += item.vida;
    pontos += item.ataque;
    pontos += item.defesa;
    pontos += item.agilidade;
    // NÃO soma item.energia

    return pontos;
  }

  /// Determina qual monstro da equipe deve receber um item novo
  /// Retorna o índice do monstro na lista
  /// Prioriza monstros sem item ou com item pior
  int? selecionarMonstroParaItem(List<MonstroAventura> monstros, Item itemNovo) {
    if (monstros.isEmpty) return null;

    int? melhorIndice;
    int menorPontosItem = 999999;
    bool encontrouSemItem = false;

    for (int i = 0; i < monstros.length; i++) {
      final monstro = monstros[i];

      // Prioridade 1: Monstro sem item equipado
      if (monstro.itemEquipado == null) {
        if (!encontrouSemItem) {
          encontrouSemItem = true;
          melhorIndice = i;
          menorPontosItem = 0;
        }
        continue;
      }

      // Se já encontrou um sem item, ignora monstros com item
      if (encontrouSemItem) continue;

      // Prioridade 2: Monstro com item de menor valor
      final pontosItemAtual = _calcularPontosItem(monstro.itemEquipado!);
      if (pontosItemAtual < menorPontosItem) {
        menorPontosItem = pontosItemAtual;
        melhorIndice = i;
      }
    }

    // Verifica se o item novo é melhor que o item do monstro selecionado
    if (melhorIndice != null) {
      final monstroSelecionado = monstros[melhorIndice];
      if (itemNovoBelhor(monstroSelecionado.itemEquipado, itemNovo)) {
        print('🎁 [AutoMode] Item ${itemNovo.nome} será equipado no monstro ${monstroSelecionado.tipo.displayName}');
        return melhorIndice;
      }
    }

    return null;
  }

  /// Encontra a melhor combinação de monstro x inimigo para batalhar
  /// Retorna o inimigo mais fácil de derrotar e o melhor monstro para enfrentá-lo
  /// Considera:
  /// - Vantagem de tipo (maior vantagem = mais fácil)
  /// - Vida do inimigo (menos vida = mais fácil)
  Future<({MonstroInimigo? inimigo, MonstroAventura? monstro})> selecionarMelhorCombinacao(
    List<MonstroAventura> monstros,
    List<MonstroInimigo> inimigos,
  ) async {
    // Filtra monstros e inimigos vivos
    final monstrosVivos = monstros.where((m) => m.vidaAtual > 0).toList();
    final inimigosVivos = inimigos.where((i) => i.vidaAtual > 0).toList();

    if (monstrosVivos.isEmpty || inimigosVivos.isEmpty) {
      return (inimigo: null, monstro: null);
    }

    print('🤖 [AutoMode] Analisando ${monstrosVivos.length} monstros vs ${inimigosVivos.length} inimigos...');

    MonstroInimigo? melhorInimigo;
    MonstroAventura? melhorMonstro;
    double melhorScoreCombinacao = double.negativeInfinity;

    for (final inimigo in inimigosVivos) {
      for (final monstro in monstrosVivos) {
        // Calcula score de vantagem
        final scoreVantagem = await calcularScoreVantagem(monstro, inimigo);

        // Bônus por inimigo com menos vida (mais fácil de matar)
        final percentualVidaInimigo = inimigo.vidaAtual / inimigo.vida;
        final bonusVidaBaixa = (1.0 - percentualVidaInimigo) * 2.0; // Até +2 pontos para inimigo quase morto

        // Score final da combinação
        final scoreCombinacao = scoreVantagem + bonusVidaBaixa;

        if (scoreCombinacao > melhorScoreCombinacao) {
          melhorScoreCombinacao = scoreCombinacao;
          melhorInimigo = inimigo;
          melhorMonstro = monstro;
        }
      }
    }

    if (melhorInimigo != null && melhorMonstro != null) {
      print('✅ [AutoMode] Melhor combinação:');
      print('   Inimigo: ${melhorInimigo.tipo.displayName} (${melhorInimigo.vidaAtual}/${melhorInimigo.vida} HP)');
      print('   Monstro: ${melhorMonstro.tipo.displayName} (${melhorMonstro.vidaAtual}/${melhorMonstro.vida} HP)');
      print('   Score: $melhorScoreCombinacao');
    }

    return (inimigo: melhorInimigo, monstro: melhorMonstro);
  }

  /// Seleciona o inimigo mais fácil de derrotar considerando toda a equipe
  /// Retorna o inimigo que a equipe tem mais vantagem combinada
  Future<MonstroInimigo?> selecionarInimigoMaisFacil(
    List<MonstroAventura> monstros,
    List<MonstroInimigo> inimigos,
  ) async {
    final resultado = await selecionarMelhorCombinacao(monstros, inimigos);
    return resultado.inimigo;
  }

  // ============================================================
  // MÉTODOS DE ANÁLISE DE ANDAR PARA AUTO MODE
  // ============================================================

  /// Verifica se o andar é ruim para o time
  /// Retorna true se TODOS os 3 monstros têm desvantagem contra 3+ inimigos
  Future<bool> andarEhRuim(
    List<MonstroAventura> monstros,
    List<MonstroInimigo> inimigos,
  ) async {
    final monstrosVivos = monstros.where((m) => m.vidaAtual > 0).toList();
    final inimigosVivos = inimigos.where((i) => i.vidaAtual > 0).toList();

    if (monstrosVivos.isEmpty || inimigosVivos.isEmpty) return false;

    int monstrosComDesvantagem = 0;

    for (final monstro in monstrosVivos) {
      int inimigosComDesvantagem = 0;

      for (final inimigo in inimigosVivos) {
        final score = await calcularScoreVantagem(monstro, inimigo);
        // Score negativo = desvantagem
        if (score < 0) {
          inimigosComDesvantagem++;
        }
      }

      // Monstro tem desvantagem contra 3+ inimigos
      if (inimigosComDesvantagem >= 3) {
        monstrosComDesvantagem++;
      }
    }

    // Andar é ruim se TODOS os monstros vivos têm desvantagem contra 3+ inimigos
    final ehRuim = monstrosComDesvantagem == monstrosVivos.length;

    if (ehRuim) {
      print('⚠️ [AutoMode] Andar é RUIM! Todos os $monstrosComDesvantagem monstros têm desvantagem');
    }

    return ehRuim;
  }

  /// Verifica se há algum inimigo que vale a pena atacar
  /// Retorna true se existe pelo menos uma combinação com score positivo (vantagem)
  Future<bool> temInimigoParaAtacar(
    List<MonstroAventura> monstros,
    List<MonstroInimigo> inimigos,
  ) async {
    final monstrosVivos = monstros.where((m) => m.vidaAtual > 0).toList();
    final inimigosVivos = inimigos.where((i) => i.vidaAtual > 0).toList();

    if (monstrosVivos.isEmpty || inimigosVivos.isEmpty) return false;

    for (final inimigo in inimigosVivos) {
      for (final monstro in monstrosVivos) {
        final score = await calcularScoreVantagem(monstro, inimigo);
        // Score >= 0 = neutro ou vantagem, vale a pena atacar
        if (score >= 0) {
          print('✅ [AutoMode] Encontrado inimigo atacável: ${inimigo.tipo.displayName} com ${monstro.tipo.displayName} (score: $score)');
          return true;
        }
      }
    }

    print('❌ [AutoMode] Nenhum inimigo vale a pena atacar - todos têm vantagem sobre nós');
    return false;
  }

  /// Seleciona a melhor combinação APENAS se tiver vantagem ou neutro
  /// Retorna null se todas as combinações forem desvantajosas
  Future<({MonstroInimigo? inimigo, MonstroAventura? monstro})?> selecionarMelhorCombinacaoComVantagem(
    List<MonstroAventura> monstros,
    List<MonstroInimigo> inimigos,
  ) async {
    final resultado = await selecionarMelhorCombinacao(monstros, inimigos);

    if (resultado.inimigo == null || resultado.monstro == null) {
      return null;
    }

    // Verifica se a melhor combinação tem vantagem ou é neutra
    final score = await calcularScoreVantagem(resultado.monstro!, resultado.inimigo!);

    // Se o score for muito negativo (< -1), não vale a pena atacar
    if (score < -1.0) {
      print('⚠️ [AutoMode] Melhor combinação tem score $score (muito negativo), pulando...');
      return null;
    }

    return resultado;
  }

  // ============================================================
  // MÉTODOS DE CONSUMÍVEIS PARA AUTO MODE
  // ============================================================

  /// Encontra uma poção na mochila para renascer um monstro morto
  /// Retorna o índice da poção e o monstro morto com melhor vantagem
  /// Só usa poção quando for USAR o monstro (ele precisa ter vantagem)
  Future<({int indicePocao, MonstroAventura monstro, int porcentagemCura})?>
  selecionarPocaoParaRenascer(
    Mochila mochila,
    List<MonstroAventura> monstros,
    List<MonstroInimigo> inimigosVivos,
  ) async {
    // Filtra monstros mortos
    final monstrosMortos = monstros.where((m) => m.vidaAtual <= 0).toList();
    if (monstrosMortos.isEmpty) {
      print('⏭️ [AutoMode] Nenhum monstro morto para renascer');
      return null;
    }

    // Procura poções na mochila
    int? indicePocaoGrande;
    int? indicePocaoPequena;

    for (int i = 0; i < mochila.slotsDesbloqueados; i++) {
      final item = mochila.itens[i];
      if (item == null || item.tipo != TipoItemConsumivel.pocao) continue;
      if (item.quantidade <= 0) continue;

      if (item.id == 'pocaoVidaGrande') {
        indicePocaoGrande = i;
      } else if (item.id == 'pocaoVidaPequena') {
        indicePocaoPequena = i;
      }
    }

    if (indicePocaoGrande == null && indicePocaoPequena == null) {
      print('⏭️ [AutoMode] Nenhuma poção disponível na mochila');
      return null;
    }

    // Encontra o monstro morto com melhor vantagem contra inimigos
    MonstroAventura? melhorMonstro;
    double melhorScore = double.negativeInfinity;

    for (final monstro in monstrosMortos) {
      double scoreTotal = 0.0;

      for (final inimigo in inimigosVivos) {
        final score = await calcularScoreVantagem(monstro, inimigo);
        scoreTotal += score;
      }

      final scoreMedia = scoreTotal / inimigosVivos.length;

      // Só considera se tiver vantagem positiva
      if (scoreMedia > 0 && scoreMedia > melhorScore) {
        melhorScore = scoreMedia;
        melhorMonstro = monstro;
      }
    }

    if (melhorMonstro == null) {
      print('❌ [AutoMode] Nenhum monstro morto com vantagem positiva');
      return null;
    }

    // Prefere poção grande, mas usa pequena se não tiver
    final indicePocao = indicePocaoGrande ?? indicePocaoPequena!;
    final porcentagem = indicePocaoGrande != null ? 100 : 25;

    print('🧪 [AutoMode] Usar poção ($porcentagem%) em ${melhorMonstro.tipo.displayName} (score: $melhorScore)');

    return (
      indicePocao: indicePocao,
      monstro: melhorMonstro,
      porcentagemCura: porcentagem,
    );
  }

  /// Verifica se algum item equipado precisa de Joia de Reforço/Recriação
  /// Retorna o monstro e índice da joia se encontrar item 2-3 tiers abaixo (épico/lendário)
  ({int indiceJoia, MonstroAventura monstro, bool isRecriacao})?
  verificarItemParaJoia(
    Mochila mochila,
    List<MonstroAventura> monstros,
    int tierAtual,
  ) {
    // Procura joias na mochila
    int? indiceJoiaReforco;
    int? indiceJoiaRecriacao;

    for (int i = 0; i < mochila.slotsDesbloqueados; i++) {
      final item = mochila.itens[i];
      if (item == null || item.tipo != TipoItemConsumivel.joia) continue;
      if (item.quantidade <= 0) continue;

      // Joia da Recriação = Lendária, Joia de Reforço = Épica
      if (item.raridade == RaridadeConsumivel.lendario) {
        indiceJoiaRecriacao = i;
      } else if (item.raridade == RaridadeConsumivel.epico) {
        indiceJoiaReforco = i;
      }
    }

    if (indiceJoiaReforco == null && indiceJoiaRecriacao == null) {
      return null;
    }

    // Procura item que precisa de reforço (2-3 tiers abaixo, épico ou lendário)
    for (final monstro in monstros) {
      final item = monstro.itemEquipado;
      if (item == null) continue;

      // Só usa joia em itens épicos ou lendários (não em impossível)
      if (item.raridade != RaridadeItem.epico &&
          item.raridade != RaridadeItem.lendario) continue;

      // Verifica se está 2 ou mais tiers abaixo
      final diferencaTier = tierAtual - item.tier;
      if (diferencaTier >= 2) {
        // Prefere reforço (épica) sobre recriação (lendária)
        if (indiceJoiaReforco != null) {
          print('💎 [AutoMode] Usar Joia de Reforço em ${monstro.tipo.displayName} (item tier ${item.tier} -> $tierAtual)');
          return (indiceJoia: indiceJoiaReforco, monstro: monstro, isRecriacao: false);
        } else if (indiceJoiaRecriacao != null) {
          print('✨ [AutoMode] Usar Joia da Recriação em ${monstro.tipo.displayName} (item tier ${item.tier} -> $tierAtual)');
          return (indiceJoia: indiceJoiaRecriacao, monstro: monstro, isRecriacao: true);
        }
      }
    }

    return null;
  }

  /// Encontra o monstro mais fraco (level 1) para usar Fruta Nuty
  /// Retorna o índice da fruta e o monstro se encontrar
  ({int indiceFruta, MonstroAventura monstro})?
  selecionarMonstroParaNuty(
    Mochila mochila,
    List<MonstroAventura> monstros,
  ) {
    // Procura Fruta Nuty na mochila (lendária)
    int? indiceFruta;

    for (int i = 0; i < mochila.slotsDesbloqueados; i++) {
      final item = mochila.itens[i];
      if (item == null || item.tipo != TipoItemConsumivel.fruta) continue;
      if (item.quantidade <= 0) continue;

      // Fruta Nuty = Lendária
      if (item.raridade == RaridadeConsumivel.lendario) {
        indiceFruta = i;
        break;
      }
    }

    if (indiceFruta == null) {
      return null;
    }

    // Encontra o monstro level 1 mais fraco (menor soma de stats)
    MonstroAventura? monstroMaisFraco;
    int menorStats = 999999;

    for (final monstro in monstros) {
      // Fruta Nuty só funciona em level 1
      if (monstro.level != 1) continue;

      // Calcula soma de stats (ignora vidaAtual, usa vida máxima)
      final somaStats = monstro.vida + monstro.energia + monstro.agilidade +
                        monstro.ataque + monstro.defesa;

      if (somaStats < menorStats) {
        menorStats = somaStats;
        monstroMaisFraco = monstro;
      }
    }

    if (monstroMaisFraco == null) {
      print('⏭️ [AutoMode] Nenhum monstro level 1 para usar Fruta Nuty');
      return null;
    }

    print('🥥 [AutoMode] Usar Fruta Nuty em ${monstroMaisFraco.tipo.displayName} (stats: $menorStats)');

    return (indiceFruta: indiceFruta, monstro: monstroMaisFraco);
  }

  /// Encontra Fruta Nuty Cristalizada para usar em qualquer monstro
  /// Retorna o índice da fruta e o monstro mais fraco
  ({int indiceFruta, MonstroAventura monstro})?
  selecionarMonstroParaCristalizada(
    Mochila mochila,
    List<MonstroAventura> monstros,
  ) {
    // Procura Fruta Nuty Cristalizada na mochila (épica, id != frutaNutyNegra)
    int? indiceFruta;

    for (int i = 0; i < mochila.slotsDesbloqueados; i++) {
      final item = mochila.itens[i];
      if (item == null || item.tipo != TipoItemConsumivel.fruta) continue;
      if (item.quantidade <= 0) continue;

      // Cristalizada = Épica e ID não é frutaNutyNegra
      if (item.raridade == RaridadeConsumivel.epico && item.id != 'frutaNutyNegra') {
        indiceFruta = i;
        break;
      }
    }

    if (indiceFruta == null) {
      return null;
    }

    // Usa no monstro mais fraco (menor soma de stats)
    MonstroAventura? monstroMaisFraco;
    int menorStats = 999999;

    for (final monstro in monstros) {
      final somaStats = monstro.vida + monstro.energia + monstro.agilidade +
                        monstro.ataque + monstro.defesa;

      if (somaStats < menorStats) {
        menorStats = somaStats;
        monstroMaisFraco = monstro;
      }
    }

    if (monstroMaisFraco == null) {
      return null;
    }

    print('💎 [AutoMode] Usar Fruta Cristalizada em ${monstroMaisFraco.tipo.displayName}');

    return (indiceFruta: indiceFruta, monstro: monstroMaisFraco);
  }

  /// Encontra Fruta Nuty Negra para usar (adiciona +10 kills)
  /// Retorna o índice da fruta se encontrar
  int? encontrarFrutaNegra(Mochila mochila) {
    for (int i = 0; i < mochila.slotsDesbloqueados; i++) {
      final item = mochila.itens[i];
      if (item == null || item.tipo != TipoItemConsumivel.fruta) continue;
      if (item.quantidade <= 0) continue;

      // Negra = Épica e ID é frutaNutyNegra
      if (item.raridade == RaridadeConsumivel.epico && item.id == 'frutaNutyNegra') {
        print('🖤 [AutoMode] Encontrada Fruta Nuty Negra no slot $i');
        return i;
      }
    }

    return null;
  }

  // ============================================================
  // MÉTODOS DE ANÁLISE PARA COMPRA AUTOMÁTICA (TIER 10)
  // ============================================================

  /// Analisa as magias de dano de um monstro
  /// Retorna a quantidade de magias com dano >= limiar
  int contarMagiasDeDano(MonstroAventura monstro, {int limiarDano = 400}) {
    int count = 0;
    for (final habilidade in monstro.habilidades) {
      // Só conta magias ofensivas de dano direto
      if (habilidade.tipo == TipoHabilidade.ofensiva &&
          habilidade.efeito == EfeitoHabilidade.danoDirecto) {
        if (habilidade.valorEfetivo >= limiarDano) {
          count++;
        }
      }
    }
    return count;
  }

  /// Retorna a soma do dano de todas as magias ofensivas de um monstro
  int somarDanoMagias(MonstroAventura monstro) {
    int total = 0;
    for (final habilidade in monstro.habilidades) {
      if (habilidade.tipo == TipoHabilidade.ofensiva &&
          habilidade.efeito == EfeitoHabilidade.danoDirecto) {
        total += habilidade.valorEfetivo;
      }
    }
    return total;
  }

  /// Encontra a magia mais fraca de um monstro (para substituir)
  Habilidade? encontrarMagiaMaisFraca(MonstroAventura monstro) {
    Habilidade? maisFraca;
    int menorDano = 999999;

    for (final habilidade in monstro.habilidades) {
      // Só considera magias ofensivas de dano direto
      if (habilidade.tipo == TipoHabilidade.ofensiva &&
          habilidade.efeito == EfeitoHabilidade.danoDirecto) {
        if (habilidade.valorEfetivo < menorDano) {
          menorDano = habilidade.valorEfetivo;
          maisFraca = habilidade;
        }
      }
    }

    return maisFraca;
  }

  /// Ordena monstros por prioridade de upgrade de magias
  /// Retorna lista ordenada do que mais precisa de magias boas
  List<MonstroAventura> ordenarMonstrosPorPrioridadeMagia(
    List<MonstroAventura> monstros,
  ) {
    final copia = List<MonstroAventura>.from(monstros);

    copia.sort((a, b) {
      // Conta magias boas (450+) de cada
      final magiasBoasA = contarMagiasDeDano(a, limiarDano: 450);
      final magiasBoasB = contarMagiasDeDano(b, limiarDano: 450);

      // Prioriza quem tem menos magias boas
      if (magiasBoasA != magiasBoasB) {
        return magiasBoasA.compareTo(magiasBoasB);
      }

      // Se igual, prioriza quem tem menor dano total
      return somarDanoMagias(a).compareTo(somarDanoMagias(b));
    });

    return copia;
  }

  /// Analisa se o time está pronto para tier 11 ou precisa comprar mais
  /// Retorna: 'magia' se deve comprar magia, 'item' se deve comprar item, 'pronto' se está bom
  ({String acao, MonstroAventura? monstro, String motivo}) analisarNecessidadeCompra(
    List<MonstroAventura> monstros,
    int scoreDisponivel,
    int custoCompra,
  ) {
    if (scoreDisponivel < custoCompra) {
      return (acao: 'pronto', monstro: null, motivo: 'Score insuficiente');
    }

    // Ordena por prioridade
    final ordenados = ordenarMonstrosPorPrioridadeMagia(monstros);
    if (ordenados.isEmpty) {
      return (acao: 'pronto', monstro: null, motivo: 'Sem monstros');
    }

    // Primeiro monstro (principal)
    final principal = ordenados[0];
    final magiasBoas450Principal = contarMagiasDeDano(principal, limiarDano: 450);

    // Segundo monstro (se existir)
    final segundo = ordenados.length > 1 ? ordenados[1] : null;
    final magiasBoas400Segundo = segundo != null
        ? contarMagiasDeDano(segundo, limiarDano: 400)
        : 0;

    print('🔍 [AutoMode] Análise de compra:');
    print('   Principal: ${principal.tipo.displayName} - ${magiasBoas450Principal} magias 450+');
    if (segundo != null) {
      print('   Segundo: ${segundo.tipo.displayName} - ${magiasBoas400Segundo} magias 400+');
    }

    // Se principal não tem 2+ magias de 450+, prioriza magia para ele
    if (magiasBoas450Principal < 2) {
      print('   → Precisa de MAGIA para ${principal.tipo.displayName}');
      return (
        acao: 'magia',
        monstro: principal,
        motivo: 'Principal precisa de magias 450+',
      );
    }

    // Se segundo não tem 2+ magias de 400+, compra magia para ele
    if (segundo != null && magiasBoas400Segundo < 2) {
      print('   → Precisa de MAGIA para ${segundo.tipo.displayName}');
      return (
        acao: 'magia',
        monstro: segundo,
        motivo: 'Segundo precisa de magias 400+',
      );
    }

    // Se os dois estão bons de magias, tenta melhorar item do principal
    print('   → Magias OK, tentando ITEM para ${principal.tipo.displayName}');
    return (
      acao: 'item',
      monstro: principal,
      motivo: 'Magias completas, melhorando item',
    );
  }

  /// Verifica se uma magia nova é melhor que a mais fraca do monstro
  bool magiaNovaMelhor(MonstroAventura monstro, int valorNovaMAgia, int levelNovaMagia) {
    final maisFraca = encontrarMagiaMaisFraca(monstro);
    if (maisFraca == null) return true; // Não tem magias, qualquer uma é boa

    final danoNovo = valorNovaMAgia * levelNovaMagia;
    return danoNovo > maisFraca.valorEfetivo;
  }

  /// Encontra a melhor magia de uma lista de 3 opções
  /// Retorna a magia com maior dano direto, ou null se nenhuma for boa
  int? selecionarMelhorMagia(
    List<dynamic> magias, // List<MagiaDrop>
    int limiarDano,
  ) {
    int? melhorIndex;
    int melhorDano = 0;

    for (int i = 0; i < magias.length; i++) {
      final magia = magias[i];
      // Verifica se é magia de dano direto (compara com os enums diretamente)
      if (magia.tipo == TipoHabilidade.ofensiva &&
          magia.efeito == EfeitoHabilidade.danoDirecto) {
        final dano = magia.valorEfetivo as int;
        if (dano >= limiarDano && dano > melhorDano) {
          melhorDano = dano;
          melhorIndex = i;
        }
      }
    }

    if (melhorIndex != null) {
      print('✨ [AutoMode] Melhor magia: índice $melhorIndex com dano $melhorDano');
    } else {
      print('❌ [AutoMode] Nenhuma magia de dano atende ao limiar $limiarDano');
    }

    return melhorIndex;
  }

  /// Encontra o melhor item de uma lista de 3 opções
  /// Retorna o item com maior total de atributos
  int selecionarMelhorItem(List<dynamic> itens) {
    int melhorIndex = 0;
    int melhorTotal = 0;

    for (int i = 0; i < itens.length; i++) {
      final item = itens[i];
      final total = item.totalAtributos as int;
      if (total > melhorTotal) {
        melhorTotal = total;
        melhorIndex = i;
      }
    }

    print('🎁 [AutoMode] Melhor item: índice $melhorIndex com total $melhorTotal atributos');
    return melhorIndex;
  }
}
