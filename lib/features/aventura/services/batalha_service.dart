import 'dart:math';
import '../models/batalha.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/habilidade.dart';
import '../../../shared/models/habilidade_enum.dart';

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
    
    // Estado inicial da batalha
    EstadoBatalha estado = EstadoBatalha(
      jogador: jogador,
      inimigo: inimigo,
      vidaAtualJogador: jogador.vida,
      vidaAtualInimigo: inimigo.vida,
      vidaMaximaJogador: jogador.vida, // Vida máxima inicial igual à vida base
      vidaMaximaInimigo: inimigo.vida, // Vida máxima inicial igual à vida base
      ataqueAtualJogador: jogador.ataque,
      defesaAtualJogador: jogador.defesa,
      ataqueAtualInimigo: inimigo.ataque,
      defesaAtualInimigo: inimigo.defesa,
      energiaAtualJogador: jogador.energiaAtual, // Energia atual do jogador
      energiaAtualInimigo: inimigo.energiaAtual, // Energia atual do inimigo
      habilidadesUsadasJogador: [],
      habilidadesUsadasInimigo: [],
      historicoAcoes: [],
    );

    String vencedor = '';
    
    // Determina quem começa baseado na agilidade
    bool jogadorComeca = jogador.agilidade >= inimigo.agilidade;
    print('🏃 [Batalha] ${jogadorComeca ? "Jogador" : "Inimigo"} começa (agilidade: ${jogadorComeca ? jogador.agilidade : inimigo.agilidade})');
    
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
          int novaVida = (estado.vidaAtualJogador + habilidade.valor).clamp(0, estado.jogador.vida);
          novoEstado = estado.copyWith(vidaAtualJogador: novaVida);
          descricao = '$atacante curou ${novaVida - vidaAntes} de vida (${habilidade.nome})';
        } else {
          int vidaAntes = estado.vidaAtualInimigo;
          int novaVida = (estado.vidaAtualInimigo + habilidade.valor).clamp(0, estado.inimigo.vida);
          novoEstado = estado.copyWith(vidaAtualInimigo: novaVida);
          descricao = '$atacante curou ${novaVida - vidaAntes} de vida (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarAtaque:
        if (isJogador) {
          int novoAtaque = estado.ataqueAtualJogador + habilidade.valor;
          novoEstado = estado.copyWith(ataqueAtualJogador: novoAtaque);
          descricao = '$atacante aumentou o ataque em ${habilidade.valor} (${habilidade.nome})';
        } else {
          int novoAtaque = estado.ataqueAtualInimigo + habilidade.valor;
          novoEstado = estado.copyWith(ataqueAtualInimigo: novoAtaque);
          descricao = '$atacante aumentou o ataque em ${habilidade.valor} (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarDefesa:
        if (isJogador) {
          int novaDefesa = estado.defesaAtualJogador + habilidade.valor;
          novoEstado = estado.copyWith(defesaAtualJogador: novaDefesa);
          descricao = '$atacante aumentou a defesa em ${habilidade.valor} (${habilidade.nome})';
        } else {
          int novaDefesa = estado.defesaAtualInimigo + habilidade.valor;
          novoEstado = estado.copyWith(defesaAtualInimigo: novaDefesa);
          descricao = '$atacante aumentou a defesa em ${habilidade.valor} (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarVida:
        if (isJogador) {
          int novaVidaMaxima = estado.vidaMaximaJogador + habilidade.valor;
          int novaVidaAtual = estado.vidaAtualJogador + habilidade.valor; // Também aumenta a vida atual
          novoEstado = estado.copyWith(
            vidaMaximaJogador: novaVidaMaxima,
            vidaAtualJogador: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima em ${habilidade.valor} (${habilidade.nome})';
        } else {
          int novaVidaMaxima = estado.vidaMaximaInimigo + habilidade.valor;
          int novaVidaAtual = estado.vidaAtualInimigo + habilidade.valor; // Também aumenta a vida atual
          novoEstado = estado.copyWith(
            vidaMaximaInimigo: novaVidaMaxima,
            vidaAtualInimigo: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima em ${habilidade.valor} (${habilidade.nome})';
        }
        break;
        
      default:
        descricao = '$atacante usou ${habilidade.nome} (efeito: ${habilidade.valor})';
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
      danoBase: habilidade.valor,
      danoTotal: habilidade.valor,
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
    
    // Calcula dano
    int ataqueAtacante = isJogador ? estado.ataqueAtualJogador : estado.ataqueAtualInimigo;
    int defesaAlvo = isJogador ? estado.defesaAtualInimigo : estado.defesaAtualJogador;
    
    int danoBase = habilidade.valor;
    int danoComAtaque = danoBase + ataqueAtacante;
    int danoFinal = (danoComAtaque - defesaAlvo).clamp(1, danoComAtaque); // Mínimo 1 de dano
    
    // Aplica dano
    int vidaAntes, vidaDepois;
    EstadoBatalha novoEstado;
    
    if (isJogador) {
      // Jogador ataca inimigo
      vidaAntes = estado.vidaAtualInimigo;
      vidaDepois = (estado.vidaAtualInimigo - danoFinal).clamp(0, estado.inimigo.vida);
      novoEstado = estado.copyWith(vidaAtualInimigo: vidaDepois);
    } else {
      // Inimigo ataca jogador
      vidaAntes = estado.vidaAtualJogador;
      vidaDepois = (estado.vidaAtualJogador - danoFinal).clamp(0, estado.jogador.vida);
      novoEstado = estado.copyWith(vidaAtualJogador: vidaDepois);
    }
    
    String descricao = '$atacante usou ${habilidade.nome}: $danoBase (+$ataqueAtacante ataque) - $defesaAlvo defesa = $danoFinal de dano. Vida: $vidaAntes/$vidaDepois';
    
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
