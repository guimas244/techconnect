import 'dart:math';
import '../models/monstro_aventura.dart';

class EvolucaoService {
  final Random _random = Random();

  /// Sorteia um monstro aleatório da lista para evoluir
  MonstroAventura? sortearMonstroParaEvoluir(List<MonstroAventura> monstros) {
    if (monstros.isEmpty) return null;
    
    final indiceSorteado = _random.nextInt(monstros.length);
    return monstros[indiceSorteado];
  }

  /// Verifica se um monstro pode evoluir baseado no level gap
  /// Regra: Se o monstro sorteado for 1+ levels acima do derrotado, não evolui
  bool podeEvoluir(MonstroAventura monstroSorteado, int levelMonstroInimigo) {
    final levelGap = monstroSorteado.level - levelMonstroInimigo;
    
    // Se o gap for 1 ou mais, não pode evoluir (muito mais poderoso)
    if (levelGap >= 1) {
      print('🚫 [Evolução] ${monstroSorteado.tipo.displayName} (Lv.${monstroSorteado.level}) não evoluiu - muito mais poderoso que inimigo (Lv.$levelMonstroInimigo)');
      return false;
    }
    
    print('✅ [Evolução] ${monstroSorteado.tipo.displayName} (Lv.${monstroSorteado.level}) pode evoluir contra inimigo (Lv.$levelMonstroInimigo)');
    return true;
  }

  /// Evolui um monstro subindo 1 level e ganhando atributos
  /// Regras:
  /// - +1 level
  /// - +5 pontos em 1 atributo aleatório (ataque, defesa ou agilidade)
  /// - +5 pontos em vida e energia (sempre)
  MonstroAventura evoluirMonstro(MonstroAventura monstro) {
    print('🌟 [Evolução] ${monstro.tipo.displayName} está evoluindo do level ${monstro.level} para ${monstro.level + 1}!');
    
    // Lista de atributos que podem ganhar +5 pontos aleatoriamente
    final atributosDisponiveis = ['ataque', 'defesa', 'agilidade'];
    final atributoSorteado = atributosDisponiveis[_random.nextInt(atributosDisponiveis.length)];
    
    // Calcula os novos atributos
    int novoAtaque = monstro.ataque;
    int novaDefesa = monstro.defesa;
    int novaAgilidade = monstro.agilidade;
    int novaVida = monstro.vida + 5; // Sempre ganha +5 vida
    int novaEnergia = monstro.energia + 5; // Sempre ganha +5 energia
    
    // Aplica +5 no atributo sorteado
    switch (atributoSorteado) {
      case 'ataque':
        novoAtaque += 5;
        break;
      case 'defesa':
        novaDefesa += 5;
        break;
      case 'agilidade':
        novaAgilidade += 5;
        break;
    }
    
    print('🎯 [Evolução] Atributo sorteado: $atributoSorteado (+5)');
    print('📈 [Evolução] Ganhos: +5 vida, +5 energia, +5 $atributoSorteado');
    
    // Mantém a vida atual proporcional se o monstro não estava com vida cheia
    int novaVidaAtual = monstro.vidaAtual;
    if (monstro.vidaAtual == monstro.vida) {
      // Se estava com vida cheia, continua com vida cheia
      novaVidaAtual = novaVida;
    } else {
      // Se não estava com vida cheia, ganha +5 na vida atual também
      novaVidaAtual = (monstro.vidaAtual + 5).clamp(0, novaVida);
    }
    
    // Mesma lógica para energia
    int novaEnergiaAtual = monstro.energiaAtual;
    if (monstro.energiaAtual == monstro.energia) {
      // Se estava com energia cheia, continua com energia cheia
      novaEnergiaAtual = novaEnergia;
    } else {
      // Se não estava com energia cheia, ganha +5 na energia atual também
      novaEnergiaAtual = (monstro.energiaAtual + 5).clamp(0, novaEnergia);
    }
    
    return monstro.copyWith(
      level: monstro.level + 1,
      ataque: novoAtaque,
      defesa: novaDefesa,
      agilidade: novaAgilidade,
      vida: novaVida,
      vidaAtual: novaVidaAtual,
      energia: novaEnergia,
      energiaAtual: novaEnergiaAtual,
    );
  }

  /// Cria informações sobre a evolução para exibir ao jogador
  Map<String, dynamic> criarInfoEvolucao(MonstroAventura monstroAntes, MonstroAventura monstroDepois) {
    return {
      'monstro': monstroDepois.tipo.displayName,
      'levelAntes': monstroAntes.level,
      'levelDepois': monstroDepois.level,
      'ganhos': {
        'vida': monstroDepois.vida - monstroAntes.vida,
        'energia': monstroDepois.energia - monstroAntes.energia,
        'ataque': monstroDepois.ataque - monstroAntes.ataque,
        'defesa': monstroDepois.defesa - monstroAntes.defesa,
        'agilidade': monstroDepois.agilidade - monstroAntes.agilidade,
      },
    };
  }

  /// Cria informações quando não há evolução por level gap
  Map<String, dynamic> criarInfoSemEvolucao(MonstroAventura monstroSorteado, int levelInimigo) {
    return {
      'monstro': monstroSorteado.tipo.displayName,
      'levelMonstro': monstroSorteado.level,
      'levelInimigo': levelInimigo,
      'motivo': 'level_gap',
      'mensagem': 'muito mais poderoso que o inimigo derrotado',
    };
  }
}