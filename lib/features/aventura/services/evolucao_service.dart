import 'dart:math';
import '../models/monstro_aventura.dart';
import '../models/habilidade.dart';

class EvolucaoService {
  final Random _random = Random();

  /// Sorteia um monstro aleatório da lista para evoluir
  MonstroAventura? sortearMonstroParaEvoluir(List<MonstroAventura> monstros) {
    if (monstros.isEmpty) return null;
    
    final indiceSorteado = _random.nextInt(monstros.length);
    return monstros[indiceSorteado];
  }

  /// Verifica se um monstro pode evoluir baseado no level gap
  /// Regra: Só evolui se monstro for MENOR OU IGUAL ao level do inimigo
  bool podeEvoluir(MonstroAventura monstroSorteado, int levelMonstroInimigo) {
    // Pode evoluir se monstro <= inimigo
    if (monstroSorteado.level <= levelMonstroInimigo) {
      print('✅ [Evolução] ${monstroSorteado.tipo.displayName} (Lv.${monstroSorteado.level}) pode evoluir contra inimigo (Lv.$levelMonstroInimigo)');
      return true;
    }
    
    // Não pode evoluir se monstro > inimigo
    print('🚫 [Evolução] ${monstroSorteado.tipo.displayName} (Lv.${monstroSorteado.level}) não evoluiu - mais poderoso que inimigo (Lv.$levelMonstroInimigo)');
    return false;
  }

  /// Evolui um monstro subindo 1 level, ganhando atributos e evoluindo 1 habilidade
  /// Regras:
  /// - +1 level
  /// - +5 pontos em 1 atributo aleatório (ataque, defesa ou agilidade)
  /// - +5 pontos em vida e energia (sempre)
  /// - +1 level em 1 habilidade aleatória
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
    
    // Nota: O levelInimigoDerrrotado será passado pelo método que chama evoluirMonstro
    // Por isso, vamos criar um método separado que recebe este parâmetro
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

  /// Evolui um monstro com atributos e habilidades, considerando level gap das habilidades
  Map<String, dynamic> evoluirMonstroCompleto(MonstroAventura monstro, int levelInimigoDerrrotado) {
    print('🌟 [Evolução] ${monstro.tipo.displayName} está evoluindo do level ${monstro.level} para ${monstro.level + 1}!');
    
    // Primeiro, tenta evoluir uma habilidade (sem evoluir o level do monstro ainda)
    final resultadoHabilidade = _tentarEvoluirHabilidadeSemLevel(monstro, levelInimigoDerrrotado);
    final monstroComHabilidadeProcessada = resultadoHabilidade['monstro'] as MonstroAventura;
    
    // Depois, aplica os ganhos de atributos E sobe o level (+1 apenas)
    final monstroComAtributos = evoluirMonstro(monstroComHabilidadeProcessada);
    
    // Retorna o resultado completo
    return {
      'monstroEvoluido': monstroComAtributos,
      'habilidadeEvoluiu': resultadoHabilidade['habilidadeEvoluiu'],
      'motivo': resultadoHabilidade['motivo'],
      'habilidadeAntes': resultadoHabilidade['habilidadeAntes'],
      'habilidadeDepois': resultadoHabilidade['habilidadeDepois'],
      'habilidadeEscolhida': resultadoHabilidade['habilidadeEscolhida'],
      'levelInimigo': resultadoHabilidade['levelInimigo'],
    };
  }

  /// Tenta evoluir apenas uma habilidade (sem evoluir o monstro)
  /// Usado quando o monstro não pode evoluir por level gap mas habilidades podem
  Map<String, dynamic> tentarEvoluirHabilidade(MonstroAventura monstro, int levelInimigoDerrrotado) {
    print('🎯 [Evolução] Tentando evoluir habilidade de ${monstro.tipo.displayName} (monstro não evoluiu por level gap)');
    
    // Usa o método do monstro para tentar evoluir uma habilidade
    final resultadoHabilidade = monstro.evoluir(levelInimigoDerrrotado: levelInimigoDerrrotado);
    final monstroComHabilidadeProcessada = resultadoHabilidade['monstro'] as MonstroAventura;
    
    // Como o monstro não deve ganhar level, vamos reverter o level mas manter as habilidades
    final monstroFinal = monstroComHabilidadeProcessada.copyWith(level: monstro.level);
    
    return {
      'monstroAtualizado': monstroFinal,
      'habilidadeEvoluiu': resultadoHabilidade['habilidadeEvoluiu'],
      'motivo': resultadoHabilidade['motivo'],
      'habilidadeAntes': resultadoHabilidade['habilidadeAntes'],
      'habilidadeDepois': resultadoHabilidade['habilidadeDepois'],
      'habilidadeEscolhida': resultadoHabilidade['habilidadeEscolhida'],
      'levelInimigo': resultadoHabilidade['levelInimigo'],
    };
  }

  /// Cria informações sobre evolução apenas de habilidade (monstro não evoluiu)
  Map<String, dynamic> criarInfoEvolucaoHabilidade(
    MonstroAventura monstroOriginal,
    Map<String, dynamic> resultadoHabilidade
  ) {
    final habilidadeEvoluiu = resultadoHabilidade['habilidadeEvoluiu'] as bool;
    
    Map<String, dynamic> infoHabilidade = {};
    
    if (habilidadeEvoluiu) {
      final habilidadeAntes = resultadoHabilidade['habilidadeAntes'] as Habilidade;
      final habilidadeDepois = resultadoHabilidade['habilidadeDepois'] as Habilidade;
      
      infoHabilidade = {
        'nome': habilidadeDepois.nome,
        'levelAntes': habilidadeAntes.level,
        'levelDepois': habilidadeDepois.level,
        'evoluiu': true,
      };
    } else {
      final motivo = resultadoHabilidade['motivo'] as String;
      if (motivo == 'level_gap_habilidade') {
        final habilidadeEscolhida = resultadoHabilidade['habilidadeEscolhida'] as Habilidade;
        final levelInimigo = resultadoHabilidade['levelInimigo'] as int;
        
        infoHabilidade = {
          'nome': habilidadeEscolhida.nome,
          'levelAtual': habilidadeEscolhida.level,
          'levelInimigo': levelInimigo,
          'evoluiu': false,
          'motivo': 'level_gap',
        };
      } else {
        infoHabilidade = {
          'evoluiu': false,
          'motivo': motivo,
        };
      }
    }
    
    return {
      'monstro': monstroOriginal.tipo.displayName,
      'monstroEvoluiu': false, // Monstro não evoluiu por level gap
      'habilidadeEvoluida': infoHabilidade,
    };
  }

  /// Cria informações sobre a evolução para exibir ao jogador (versão nova com level gap)
  Map<String, dynamic> criarInfoEvolucaoCompleta(
    MonstroAventura monstroAntes, 
    Map<String, dynamic> resultadoEvolucao
  ) {
    final monstroDepois = resultadoEvolucao['monstroEvoluido'] as MonstroAventura;
    final habilidadeEvoluiu = resultadoEvolucao['habilidadeEvoluiu'] as bool;
    
    Map<String, dynamic> infoHabilidade = {};
    
    if (habilidadeEvoluiu) {
      final habilidadeAntes = resultadoEvolucao['habilidadeAntes'] as Habilidade;
      final habilidadeDepois = resultadoEvolucao['habilidadeDepois'] as Habilidade;
      
      infoHabilidade = {
        'nome': habilidadeDepois.nome,
        'levelAntes': habilidadeAntes.level,
        'levelDepois': habilidadeDepois.level,
        'evoluiu': true,
      };
    } else {
      final motivo = resultadoEvolucao['motivo'] as String;
      if (motivo == 'level_gap_habilidade') {
        final habilidadeEscolhida = resultadoEvolucao['habilidadeEscolhida'] as Habilidade;
        final levelInimigo = resultadoEvolucao['levelInimigo'] as int;
        
        infoHabilidade = {
          'nome': habilidadeEscolhida.nome,
          'levelAtual': habilidadeEscolhida.level,
          'levelInimigo': levelInimigo,
          'evoluiu': false,
          'motivo': 'level_gap',
        };
      } else {
        infoHabilidade = {
          'evoluiu': false,
          'motivo': motivo,
        };
      }
    }
    
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
      'habilidadeEvoluida': infoHabilidade,
    };
  }

  /// Cria informações sobre a evolução para exibir ao jogador (versão antiga - mantida para compatibilidade)
  Map<String, dynamic> criarInfoEvolucao(MonstroAventura monstroAntes, MonstroAventura monstroDepois) {
    // Encontra qual habilidade evoluiu comparando os levels
    String? habilidadeEvoluida;
    int? levelAnteriorHabilidade;
    int? levelNovoHabilidade;
    
    for (int i = 0; i < monstroAntes.habilidades.length && i < monstroDepois.habilidades.length; i++) {
      final habilidadeAntes = monstroAntes.habilidades[i];
      final habilidadeDepois = monstroDepois.habilidades[i];
      
      if (habilidadeDepois.level > habilidadeAntes.level) {
        habilidadeEvoluida = habilidadeDepois.nome;
        levelAnteriorHabilidade = habilidadeAntes.level;
        levelNovoHabilidade = habilidadeDepois.level;
        break;
      }
    }
    
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
      'habilidadeEvoluida': {
        'nome': habilidadeEvoluida,
        'levelAntes': levelAnteriorHabilidade,
        'levelDepois': levelNovoHabilidade,
      },
    };
  }

  /// Tenta evoluir habilidade sem subir level do monstro
  Map<String, dynamic> _tentarEvoluirHabilidadeSemLevel(MonstroAventura monstro, int levelInimigoDerrrotado) {
    if (monstro.habilidades.isEmpty) {
      return {
        'monstro': monstro, // Sem mudanças no monstro
        'habilidadeEvoluiu': false,
        'motivo': 'sem_habilidades',
      };
    }

    // Escolhe uma habilidade aleatória para tentar evoluir
    final random = Random();
    final indexHabilidade = random.nextInt(monstro.habilidades.length);
    final habilidadeEscolhida = monstro.habilidades[indexHabilidade];
    
    // Verifica level gap da habilidade
    if (habilidadeEscolhida.level > levelInimigoDerrrotado) {
      return {
        'monstro': monstro, // Sem mudanças no monstro
        'habilidadeEvoluiu': false,
        'motivo': 'level_gap_habilidade',
        'habilidadeEscolhida': habilidadeEscolhida,
        'levelInimigo': levelInimigoDerrrotado,
      };
    }
    
    // Cria nova lista de habilidades com uma evoluída
    final novasHabilidades = <Habilidade>[];
    for (int i = 0; i < monstro.habilidades.length; i++) {
      if (i == indexHabilidade) {
        novasHabilidades.add(monstro.habilidades[i].evoluir());
      } else {
        novasHabilidades.add(monstro.habilidades[i]);
      }
    }

    return {
      'monstro': monstro.copyWith(habilidades: novasHabilidades), // SEM subir level
      'habilidadeEvoluiu': true,
      'habilidadeAntes': habilidadeEscolhida,
      'habilidadeDepois': monstro.habilidades[indexHabilidade].evoluir(),
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