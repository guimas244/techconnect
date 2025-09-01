import 'dart:math';
import '../models/batalha.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/habilidade.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../tipagem/data/tipagem_repository.dart';

class BatalhaService {
  final Random _random = Random();

  /// Inicia uma batalha entre um monstro do jogador e um monstro inimigo
  Future<RegistroBatalha> executarBatalha(
    MonstroAventura jogador,
    MonstroInimigo inimigo, {
    int tierAtual = 1,
    int scoreAtual = 0,
  }) async {
    print('🗡️ [Batalha] Iniciando batalha: ${jogador.tipo.displayName} vs ${inimigo.tipo.displayName}');
    
    // Calcula stats com itens e level
    final itemJogador = jogador.itemEquipado;
    final ataqueJogadorTotal = jogador.ataque + (itemJogador?.ataque ?? 0);
    final defesaJogadorTotal = jogador.defesa + (itemJogador?.defesa ?? 0);
    final vidaJogadorTotal = jogador.vida + (itemJogador?.vida ?? 0);
    final agilidadeJogadorTotal = jogador.agilidade + (itemJogador?.agilidade ?? 0);
    
    // Aplica level e item do inimigo
    final levelMultiplier = 1.0 + (inimigo.level - 1) * 0.1; // 10% por level acima de 1
    final ataqueInimigoTotal = (inimigo.ataqueTotal * levelMultiplier).round();
    final defesaInimigoTotal = (inimigo.defesaTotal * levelMultiplier).round();
    final vidaInimigoTotal = (inimigo.vidaTotal * levelMultiplier).round();
    final agilidadeInimigoTotal = (inimigo.agilidadeTotal * levelMultiplier).round();
    
    print('📊 [BatalhaService] Jogador: ATK=$ataqueJogadorTotal DEF=$defesaJogadorTotal HP=$vidaJogadorTotal AGI=$agilidadeJogadorTotal');
    print('📊 [BatalhaService] Inimigo Lv${inimigo.level}: ATK=$ataqueInimigoTotal DEF=$defesaInimigoTotal HP=$vidaInimigoTotal AGI=$agilidadeInimigoTotal');
    
    // Estado inicial da batalha
    EstadoBatalha estado = EstadoBatalha(
      jogador: jogador,
      inimigo: inimigo,
      vidaAtualJogador: jogador.vidaAtual, // Usa vida atual
      vidaAtualInimigo: inimigo.vidaAtual, // Usa vida atual
      vidaMaximaJogador: vidaJogadorTotal, // Vida + item
      vidaMaximaInimigo: vidaInimigoTotal, // Vida + item + level
      ataqueAtualJogador: ataqueJogadorTotal, // Ataque + item
      defesaAtualJogador: defesaJogadorTotal, // Defesa + item
      ataqueAtualInimigo: ataqueInimigoTotal, // Ataque + item + level
      defesaAtualInimigo: defesaInimigoTotal, // Defesa + item + level
      energiaAtualJogador: jogador.energiaAtual, // Energia atual do jogador
      energiaAtualInimigo: inimigo.energiaAtual, // Energia atual do inimigo
      habilidadesUsadasJogador: [],
      habilidadesUsadasInimigo: [],
      historicoAcoes: [],
    );

    String vencedor = '';
    
    // Determina quem começa baseado na agilidade
    bool jogadorComeca = agilidadeJogadorTotal >= agilidadeInimigoTotal;
    print('🏃 [Batalha] ${jogadorComeca ? "Jogador" : "Inimigo"} começa (agilidade: ${jogadorComeca ? agilidadeJogadorTotal : agilidadeInimigoTotal})');
    
    int turno = 1;
    
    // Loop da batalha
    while (estado.vidaAtualJogador > 0 && estado.vidaAtualInimigo > 0 && turno <= 50) {
      print('⚔️ [Batalha] === TURNO $turno ===');
      
      bool vezDoJogador = jogadorComeca ? (turno % 2 == 1) : (turno % 2 == 0);
      
      if (vezDoJogador) {
        estado = await _executarTurnoJogador(estado);
      } else {
        estado = await _executarTurnoInimigo(estado);
      }
      
      turno++;
    }
    
    // Determina o vencedor
    if (estado.vidaAtualJogador <= 0) {
      vencedor = 'inimigo';
    } else if (estado.vidaAtualInimigo <= 0) {
      vencedor = 'jogador';
    } else {
      vencedor = 'empate'; // Caso de limite de turnos
    }
    
    print('🏆 [Batalha] Vencedor: $vencedor');
    
    // Calcula score ganho apenas se o jogador venceu
    int scoreGanho = 0;
    int scoreDepois = scoreAtual;
    if (vencedor == 'jogador') {
      scoreGanho = tierAtual;
      scoreDepois = scoreAtual + scoreGanho;
    }
    
    return RegistroBatalha(
      jogadorNome: jogador.tipo.displayName,
      inimigoNome: inimigo.tipo.displayName,
      acoes: estado.historicoAcoes,
      vencedor: vencedor,
      dataHora: DateTime.now(),
      vidaInicialJogador: jogador.vida,
      vidaFinalJogador: estado.vidaAtualJogador,
      vidaInicialInimigo: inimigo.vida,
      vidaFinalInimigo: estado.vidaAtualInimigo,
      tierNaBatalha: tierAtual,
      scoreAntes: scoreAtual,
      scoreDepois: scoreDepois,
      scoreGanho: scoreGanho,
    );
  }

  Future<EstadoBatalha> _executarTurnoJogador(EstadoBatalha estado) async {
    print('👤 [Batalha] Turno do jogador');
    
    // Seleciona habilidade aleatória disponível
    final habilidadesDisponiveis = estado.jogador.habilidades
        .where((h) => h.tipo == TipoHabilidade.ofensiva || 
                     !estado.habilidadesUsadasJogador.contains(h.nome))
        .toList();
    
    if (habilidadesDisponiveis.isEmpty) {
      print('❌ [Batalha] Jogador sem habilidades disponíveis!');
      return estado;
    }
    
    final habilidadeEscolhida = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    print('🎯 [Batalha] Jogador usa: ${habilidadeEscolhida.nome}');
    
    return await _aplicarHabilidade(
      estado,
      habilidadeEscolhida,
      true, // é jogador
    );
  }

  Future<EstadoBatalha> _executarTurnoInimigo(EstadoBatalha estado) async {
    print('👹 [Batalha] Turno do inimigo');
    
    // Seleciona habilidade aleatória disponível
    final habilidadesDisponiveis = estado.inimigo.habilidades
        .where((h) => h.tipo == TipoHabilidade.ofensiva || 
                     !estado.habilidadesUsadasInimigo.contains(h.nome))
        .toList();
    
    if (habilidadesDisponiveis.isEmpty) {
      print('❌ [Batalha] Inimigo sem habilidades disponíveis!');
      return estado;
    }
    
    final habilidadeEscolhida = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    print('🎯 [Batalha] Inimigo usa: ${habilidadeEscolhida.nome}');
    
    return await _aplicarHabilidade(
      estado,
      habilidadeEscolhida,
      false, // é inimigo
    );
  }

  Future<EstadoBatalha> _aplicarHabilidade(
    EstadoBatalha estado,
    Habilidade habilidade,
    bool isJogador,
  ) async {
    if (habilidade.tipo == TipoHabilidade.suporte) {
      return await _aplicarHabilidadeSuporte(estado, habilidade, isJogador);
    } else {
      return await _aplicarHabilidadeDano(estado, habilidade, isJogador);
    }
  }

  Future<EstadoBatalha> _aplicarHabilidadeSuporte(
    EstadoBatalha estado,
    Habilidade habilidade,
    bool isJogador,
  ) async {
    String atacante = isJogador ? estado.jogador.tipo.displayName : estado.inimigo.tipo.displayName;
    String descricao = '';
    
    EstadoBatalha novoEstado = estado;
    
    // Aplica efeito de suporte
    switch (habilidade.efeito) {
      case EfeitoHabilidade.curarVida:
        if (isJogador) {
          int vidaAntes = estado.vidaAtualJogador;
          int novaVida = (estado.vidaAtualJogador + habilidade.valorEfetivo).clamp(0, estado.jogador.vida);
          novoEstado = estado.copyWith(vidaAtualJogador: novaVida);
          descricao = '$atacante curou ${novaVida - vidaAntes} de vida (${habilidade.nome})';
        } else {
          int vidaAntes = estado.vidaAtualInimigo;
          int novaVida = (estado.vidaAtualInimigo + habilidade.valorEfetivo).clamp(0, estado.inimigo.vida);
          novoEstado = estado.copyWith(vidaAtualInimigo: novaVida);
          descricao = '$atacante curou ${novaVida - vidaAntes} de vida (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarAtaque:
        if (isJogador) {
          int novoAtaque = estado.ataqueAtualJogador + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(ataqueAtualJogador: novoAtaque);
          descricao = '$atacante aumentou o ataque em ${habilidade.valorEfetivo} (${habilidade.nome})';
        } else {
          int novoAtaque = estado.ataqueAtualInimigo + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(ataqueAtualInimigo: novoAtaque);
          descricao = '$atacante aumentou o ataque em ${habilidade.valorEfetivo} (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarDefesa:
        if (isJogador) {
          int novaDefesa = estado.defesaAtualJogador + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(defesaAtualJogador: novaDefesa);
          descricao = '$atacante aumentou a defesa em ${habilidade.valorEfetivo} (${habilidade.nome})';
        } else {
          int novaDefesa = estado.defesaAtualInimigo + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(defesaAtualInimigo: novaDefesa);
          descricao = '$atacante aumentou a defesa em ${habilidade.valorEfetivo} (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarVida:
        if (isJogador) {
          int novaVidaMaxima = estado.vidaMaximaJogador + habilidade.valorEfetivo;
          int novaVidaAtual = estado.vidaAtualJogador + habilidade.valorEfetivo; // Também aumenta a vida atual
          novoEstado = estado.copyWith(
            vidaMaximaJogador: novaVidaMaxima,
            vidaAtualJogador: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima em ${habilidade.valorEfetivo} (${habilidade.nome})';
        } else {
          int novaVidaMaxima = estado.vidaMaximaInimigo + habilidade.valorEfetivo;
          int novaVidaAtual = estado.vidaAtualInimigo + habilidade.valorEfetivo; // Também aumenta a vida atual
          novoEstado = estado.copyWith(
            vidaMaximaInimigo: novaVidaMaxima,
            vidaAtualInimigo: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima em ${habilidade.valorEfetivo} (${habilidade.nome})';
        }
        break;
        
      default:
        descricao = '$atacante usou ${habilidade.nome} (efeito: ${habilidade.valorEfetivo})';
        break;
    }
    
    // Marca habilidade como usada (só para suporte)
    List<String> habilidadesUsadas = isJogador 
        ? [...estado.habilidadesUsadasJogador, habilidade.nome]
        : [...estado.habilidadesUsadasInimigo, habilidade.nome];
    
    if (isJogador) {
      novoEstado = novoEstado.copyWith(habilidadesUsadasJogador: habilidadesUsadas);
    } else {
      novoEstado = novoEstado.copyWith(habilidadesUsadasInimigo: habilidadesUsadas);
    }
    
    // Adiciona ação ao histórico
    AcaoBatalha acao = AcaoBatalha(
      atacante: atacante,
      habilidadeNome: habilidade.nome,
      danoBase: habilidade.valorEfetivo,
      danoTotal: habilidade.valorEfetivo,
      defesaAlvo: 0,
      vidaAntes: isJogador ? estado.vidaAtualJogador : estado.vidaAtualInimigo,
      vidaDepois: isJogador ? novoEstado.vidaAtualJogador : novoEstado.vidaAtualInimigo,
      descricao: descricao,
    );
    
    novoEstado = novoEstado.copyWith(
      historicoAcoes: [...estado.historicoAcoes, acao],
    );
    
    print('💚 [Batalha] $descricao');
    
    return novoEstado;
  }

  Future<EstadoBatalha> _aplicarHabilidadeDano(
    EstadoBatalha estado,
    Habilidade habilidade,
    bool isJogador,
  ) async {
    String atacante = isJogador ? estado.jogador.tipo.displayName : estado.inimigo.tipo.displayName;
    
    // 🎯 LÓGICA CORRETA: Busca dados de defesa do DEFENSOR
    final tipoHabilidadeAtacante = habilidade.tipoElemental;
    final tipoDefensor = isJogador ? estado.inimigo.tipo : estado.jogador.tipo;
    
    print('⚔️ [COMBATE] ${tipoHabilidadeAtacante.displayName} (${habilidade.nome}) atacando ${tipoDefensor.displayName} (${isJogador ? "Inimigo" : "Jogador"})');
    
    // Busca multiplicador de efetividade
    double multiplicadorEfetividade = 1.0;
    String efetividadeTexto = 'NORMAL';
    
    try {
      final tipagemRepository = TipagemRepository();
      // BUSCA DADOS DE DEFESA DO DEFENSOR (quem vai receber o dano)
      final dadosDefesaDefensor = await tipagemRepository.carregarDadosTipo(tipoDefensor);
      
      if (dadosDefesaDefensor != null) {
        // PROCURA O MULTIPLICADOR PARA O TIPO DA HABILIDADE ATACANTE
        multiplicadorEfetividade = dadosDefesaDefensor[tipoHabilidadeAtacante] ?? 1.0;
        
        // Determina texto da efetividade
        if (multiplicadorEfetividade > 1.0) {
          efetividadeTexto = 'SUPER EFETIVO';
        } else if (multiplicadorEfetividade < 1.0 && multiplicadorEfetividade > 0.0) {
          efetividadeTexto = 'POUCO EFETIVO';
        } else if (multiplicadorEfetividade == 0.0) {
          efetividadeTexto = 'NÃO AFETA';
        }
        
        print('🎯 [EFETIVIDADE] ${tipoDefensor.displayName} recebe ${(multiplicadorEfetividade * 100).toInt()}% de dano de ${tipoHabilidadeAtacante.displayName} ($efetividadeTexto)');
      } else {
        print('⚠️ [AVISO] Não foi possível carregar dados de defesa de ${tipoDefensor.displayName}, usando multiplicador padrão (1.0)');
      }
    } catch (e) {
      print('❌ [ERRO] Erro ao buscar efetividade: $e');
    }
    
    // Calcula dano
    int ataqueAtacante = isJogador ? estado.ataqueAtualJogador : estado.ataqueAtualInimigo;
    int defesaAlvo = isJogador ? estado.defesaAtualInimigo : estado.defesaAtualJogador;
    
    int danoBase = habilidade.valorEfetivo;
    int danoComAtaque = danoBase + ataqueAtacante;
    int danoAntesEfetividade = (danoComAtaque - defesaAlvo).clamp(1, danoComAtaque);
    
    // APLICA MULTIPLICADOR DE EFETIVIDADE
    double danoComEfetividade = danoAntesEfetividade * multiplicadorEfetividade;
    int danoFinal = danoComEfetividade.round().clamp(0, danoAntesEfetividade * 3); // Máximo 3x o dano base
    
    // Aplica dano
    int vidaAntes, vidaDepois;
    EstadoBatalha novoEstado;
    
    if (isJogador) {
      // Jogador ataca inimigo
      vidaAntes = estado.vidaAtualInimigo;
      vidaDepois = estado.vidaAtualInimigo - danoFinal; // Permite vida negativa
      novoEstado = estado.copyWith(vidaAtualInimigo: vidaDepois);
    } else {
      // Inimigo ataca jogador
      vidaAntes = estado.vidaAtualJogador;
      vidaDepois = estado.vidaAtualJogador - danoFinal; // Permite vida negativa
      novoEstado = estado.copyWith(vidaAtualJogador: vidaDepois);
    }
    
    // Monta descrição mais detalhada mostrando stats totais
    String ataqueInfo = ataqueAtacante.toString();
    String defesaInfo = defesaAlvo.toString();
    
    // Se é jogador, mostra se tem bônus de item
    if (isJogador && estado.jogador.itemEquipado != null) {
      final bonusAtaque = estado.jogador.itemEquipado!.ataque ?? 0;
      if (bonusAtaque > 0) {
        ataqueInfo = '${estado.jogador.ataque}+$bonusAtaque=$ataqueAtacante';
      }
    }
    
    // Se é inimigo, mostra se tem bônus de item/level
    if (!isJogador && (estado.inimigo.itemEquipado != null || estado.inimigo.level > 1)) {
      final baseAtaque = estado.inimigo.ataque;
      final bonusItem = estado.inimigo.itemEquipado?.ataque ?? 0;
      final levelMult = 1.0 + (estado.inimigo.level - 1) * 0.1;
      if (estado.inimigo.level > 1) {
        ataqueInfo = '$baseAtaque${bonusItem > 0 ? '+$bonusItem' : ''}×${levelMult.toStringAsFixed(1)}=$ataqueAtacante';
      } else if (bonusItem > 0) {
        ataqueInfo = '$baseAtaque+$bonusItem=$ataqueAtacante';
      }
    }
    
    String descricao = '$atacante usou ${habilidade.nome}: $danoBase (+$ataqueInfo ataque) - $defesaInfo defesa = $danoAntesEfetividade → ${multiplicadorEfetividade}x ($efetividadeTexto) = $danoFinal de dano. Vida: $vidaAntes→$vidaDepois';
    
    // Adiciona ação ao histórico
    AcaoBatalha acao = AcaoBatalha(
      atacante: atacante,
      habilidadeNome: habilidade.nome,
      danoBase: danoBase,
      danoTotal: danoFinal,
      defesaAlvo: defesaAlvo,
      vidaAntes: vidaAntes,
      vidaDepois: vidaDepois,
      descricao: descricao,
    );
    
    novoEstado = novoEstado.copyWith(
      historicoAcoes: [...estado.historicoAcoes, acao],
    );
    
    print('⚔️ [Batalha] $descricao');
    
    return novoEstado;
  }
}
