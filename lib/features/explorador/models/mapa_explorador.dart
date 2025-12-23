import 'dart:math';
import '../../../shared/models/tipo_enum.dart';

/// Representa um mapa disponivel para selecao no Modo Explorador
///
/// Apos cada 3 batalhas, o jogador escolhe entre 3 mapas
/// Cada mapa tem chance de subir/descer/manter tier
class MapaExplorador {
  final String id;
  final String nome;
  final String imagem;
  final int tierDestino;
  final TendenciaTier tendencia;
  final List<Tipo> tiposInimigos; // 3 tipos nativos do mapa (referencia)
  final RaridadeMapa raridade; // 1-5 estrelas baseado em raridade
  final MapaTematico tema; // Tema do mapa (determina tipos nativos)
  final List<Tipo> tiposEncontrados; // Tipos que serao encontrados (sorteados 50/50)

  const MapaExplorador({
    required this.id,
    required this.nome,
    required this.imagem,
    required this.tierDestino,
    required this.tendencia,
    required this.tiposInimigos,
    required this.raridade,
    required this.tema,
    required this.tiposEncontrados,
  });

  /// Quantidade de inimigos no mapa (1 para boss, 3 para outros)
  int get quantidadeInimigos => raridade.isBoss ? 1 : 3;

  /// Tipo principal (primeiro da lista)
  Tipo get tipoPrincipal => tiposInimigos.isNotEmpty ? tiposInimigos.first : Tipo.normal;

  /// Verifica se um tipo e nativo deste mapa
  bool tipoNativo(Tipo tipo) => tiposInimigos.contains(tipo);

  /// Calcula bonus de HP para monstros com tipo nativo (25%)
  static const double bonusHpNativo = 0.25;

  /// Gera 3 mapas aleatorios baseados no tier atual
  static List<MapaExplorador> gerarOpcoes(int tierAtual) {
    final random = Random();
    final mapas = <MapaExplorador>[];

    // Mapa 1: Tendencia a subir
    if (tierAtual < 11) {
      mapas.add(_gerarMapa(
        tierAtual: tierAtual,
        tendencia: TendenciaTier.subir,
        random: random,
      ));
    }

    // Mapa 2: Manter tier
    mapas.add(_gerarMapa(
      tierAtual: tierAtual,
      tendencia: TendenciaTier.manter,
      random: random,
    ));

    // Mapa 3: Tendencia a descer (mais facil, mais rewards)
    if (tierAtual > 1) {
      mapas.add(_gerarMapa(
        tierAtual: tierAtual,
        tendencia: TendenciaTier.descer,
        random: random,
      ));
    }

    // Garante pelo menos 3 opcoes
    while (mapas.length < 3) {
      mapas.add(_gerarMapa(
        tierAtual: tierAtual,
        tendencia: TendenciaTier.manter,
        random: random,
      ));
    }

    return mapas.take(3).toList();
  }

  static MapaExplorador _gerarMapa({
    required int tierAtual,
    required TendenciaTier tendencia,
    required Random random,
  }) {
    // Escolhe um mapa tematico aleatorio
    final temas = List<MapaTematico>.from(MapaTematico.values);
    temas.shuffle(random);
    final tema = temas.first;

    int tierDestino;
    switch (tendencia) {
      case TendenciaTier.subir:
        tierDestino = (tierAtual + 1).clamp(1, 11);
        break;
      case TendenciaTier.manter:
        tierDestino = tierAtual;
        break;
      case TendenciaTier.descer:
        tierDestino = (tierAtual - 1).clamp(1, 11);
        break;
    }

    final raridade = _sortearRaridade(random);

    // Gera tipos que serao encontrados (50% nativo, 50% random dos outros 27)
    final quantidade = raridade.isBoss ? 1 : 3;
    final tiposEncontrados = _sortearTiposEncontrados(tema, quantidade, random);

    return MapaExplorador(
      id: '${tema.name}_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}',
      nome: tema.displayName,
      imagem: tema.imagem,
      tierDestino: tierDestino,
      tendencia: tendencia,
      tiposInimigos: tema.tiposNativos,
      raridade: raridade,
      tema: tema,
      tiposEncontrados: tiposEncontrados,
    );
  }

  /// Sorteia os tipos que serao encontrados no mapa
  /// 50% chance de ser nativo (com vantagem), 50% chance dos outros 27
  /// Nao repete tipos
  static List<Tipo> _sortearTiposEncontrados(
    MapaTematico tema,
    int quantidade,
    Random random,
  ) {
    final tiposNativosDisponiveis = List<Tipo>.from(tema.tiposNativos);
    final tiposNaoNativos = List<Tipo>.from(Tipo.values)
      ..removeWhere((t) => tema.tiposNativos.contains(t));

    final resultado = <Tipo>[];
    for (int i = 0; i < quantidade; i++) {
      if (random.nextDouble() < 0.5 && tiposNativosDisponiveis.isNotEmpty) {
        // 50% - tipo nativo (com vantagem +25% HP)
        final index = random.nextInt(tiposNativosDisponiveis.length);
        final tipo = tiposNativosDisponiveis.removeAt(index);
        resultado.add(tipo);
      } else if (tiposNaoNativos.isNotEmpty) {
        // 50% - tipo aleatorio dos outros 27 (sem vantagem)
        final index = random.nextInt(tiposNaoNativos.length);
        final tipo = tiposNaoNativos.removeAt(index);
        resultado.add(tipo);
      } else if (tiposNativosDisponiveis.isNotEmpty) {
        // Fallback: se nao tem mais nao-nativos, usa nativo
        final index = random.nextInt(tiposNativosDisponiveis.length);
        final tipo = tiposNativosDisponiveis.removeAt(index);
        resultado.add(tipo);
      }
    }
    return resultado;
  }

  /// Sorteia a raridade do mapa baseado nas chances:
  /// 1 estrela (comum) = 78%
  /// 2 estrelas (+25% XP) = 12%
  /// 3 estrelas (1 elite) = 5%
  /// 4 estrelas (todos elite) = 4%
  /// 5 estrelas (boss) = 1%
  static RaridadeMapa _sortearRaridade(Random random) {
    final sorteio = random.nextDouble() * 100;

    if (sorteio < 1) {
      return RaridadeMapa.boss; // 1%
    } else if (sorteio < 5) {
      return RaridadeMapa.todosElite; // 4%
    } else if (sorteio < 10) {
      return RaridadeMapa.umElite; // 5%
    } else if (sorteio < 22) {
      return RaridadeMapa.bonusXp; // 12%
    } else {
      return RaridadeMapa.comum; // 78%
    }
  }

  /// Descricao da tendencia
  String get descricaoTendencia {
    switch (tendencia) {
      case TendenciaTier.subir:
        return 'Dificuldade maior, mais XP';
      case TendenciaTier.manter:
        return 'Dificuldade equilibrada';
      case TendenciaTier.descer:
        return 'Mais facil, menos XP';
    }
  }

  /// XP total neste mapa (tier * 3 batalhas)
  /// Mapas de 2 estrelas tem +25% bonus
  int get xpBase {
    final base = tierDestino * 3;
    if (raridade == RaridadeMapa.bonusXp) {
      return (base * 1.25).round();
    }
    return base;
  }

  /// Kills base por vitoria neste mapa
  int get killsBase {
    return ((tierDestino / 2).ceil() + raridade.estrelas).toInt();
  }

  factory MapaExplorador.fromJson(Map<String, dynamic> json) {
    // Suporta formato antigo (tipoInimigos) e novo (tiposInimigos)
    List<Tipo> tipos;
    if (json['tiposInimigos'] != null) {
      tipos = (json['tiposInimigos'] as List<dynamic>)
          .map((t) => Tipo.values.firstWhere(
                (tipo) => tipo.name == t,
                orElse: () => Tipo.normal,
              ))
          .toList();
    } else if (json['tipoInimigos'] != null) {
      // Formato antigo - converte para lista com 1 tipo
      tipos = [
        Tipo.values.firstWhere(
          (t) => t.name == json['tipoInimigos'],
          orElse: () => Tipo.normal,
        )
      ];
    } else {
      tipos = [Tipo.normal];
    }

    // Suporta formato antigo (dificuldade) e novo (raridade)
    RaridadeMapa raridadeMapa;
    if (json['raridade'] != null) {
      raridadeMapa = RaridadeMapa.values.firstWhere(
        (r) => r.name == json['raridade'],
        orElse: () => RaridadeMapa.comum,
      );
    } else if (json['dificuldade'] != null) {
      // Converte dificuldade antiga para raridade
      final dif = json['dificuldade'] as int;
      raridadeMapa = RaridadeMapa.fromEstrelas(dif);
    } else {
      raridadeMapa = RaridadeMapa.comum;
    }

    // Suporta formato antigo (sem tema) e novo (com tema)
    MapaTematico temaMapa;
    if (json['tema'] != null) {
      temaMapa = MapaTematico.values.firstWhere(
        (t) => t.name == json['tema'],
        orElse: () => MapaTematico.floresta,
      );
    } else {
      // Tenta inferir o tema pelos tipos
      temaMapa = MapaTematico.fromTipos(tipos);
    }

    // Carrega tipos encontrados ou gera novos
    List<Tipo> tiposEncontradosCarregados;
    if (json['tiposEncontrados'] != null) {
      tiposEncontradosCarregados = (json['tiposEncontrados'] as List<dynamic>)
          .map((t) => Tipo.values.firstWhere(
                (tipo) => tipo.name == t,
                orElse: () => Tipo.normal,
              ))
          .toList();
    } else {
      // Gera tipos encontrados para compatibilidade
      final quantidade = raridadeMapa.isBoss ? 1 : 3;
      tiposEncontradosCarregados =
          _sortearTiposEncontrados(temaMapa, quantidade, Random());
    }

    return MapaExplorador(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      imagem: json['imagem'] ?? '',
      tierDestino: json['tierDestino'] ?? 1,
      tendencia: TendenciaTier.values.firstWhere(
        (t) => t.name == json['tendencia'],
        orElse: () => TendenciaTier.manter,
      ),
      tiposInimigos: tipos,
      raridade: raridadeMapa,
      tema: temaMapa,
      tiposEncontrados: tiposEncontradosCarregados,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'imagem': imagem,
      'tierDestino': tierDestino,
      'tendencia': tendencia.name,
      'tiposInimigos': tiposInimigos.map((t) => t.name).toList(),
      'raridade': raridade.name,
      'tema': tema.name,
      'tiposEncontrados': tiposEncontrados.map((t) => t.name).toList(),
    };
  }
}

/// Tendencia do tier ao escolher o mapa
enum TendenciaTier {
  subir,
  manter,
  descer;

  String get displayName {
    switch (this) {
      case TendenciaTier.subir:
        return 'Subir Tier';
      case TendenciaTier.manter:
        return 'Manter Tier';
      case TendenciaTier.descer:
        return 'Descer Tier';
    }
  }

  String get icone {
    switch (this) {
      case TendenciaTier.subir:
        return '↑';
      case TendenciaTier.manter:
        return '→';
      case TendenciaTier.descer:
        return '↓';
    }
  }
}

/// Raridade do mapa - determina bonus e tipos de inimigos
///
/// Sistema de raridade:
/// - 1 estrela (comum): 78% chance - mapa normal
/// - 2 estrelas (bonusXp): 12% chance - +25% XP
/// - 3 estrelas (umElite): 5% chance - 1 monstro elite
/// - 4 estrelas (todosElite): 4% chance - todos monstros elite
/// - 5 estrelas (boss): 1% chance - mapa de boss
///
/// === MECANICAS DO BOSS (5 estrelas) ===
///
/// O Boss e um tipo especial de inimigo que aparece em mapas 5 estrelas:
///
/// ATRIBUTOS:
/// - 3 vidas (mostradas como 3 coracoes acima do monstro)
/// - 10x mais HP do que monstros normais do mesmo tier
/// - Unico monstro que pode receber multiplos ataques por turno
///
/// BARRA DE VIDA:
/// - Mostrada acima da IMAGEM do monstro (nao do icone)
/// - Deve mostrar a porcentagem de vida atual
/// - Atualiza em tempo real durante o combate
///
/// REGENERACAO:
/// - Apos sobreviver a qualquer ataque, cura 15% do HP maximo
/// - A cura acontece imediatamente apos cada ataque recebido
///
/// SISTEMA DE VIDAS:
/// - 3 coracoes aparecem acima do monstro
/// - Quando HP chega a 0, perde 1 coracao e HP reseta para 100%
/// - Coracoes perdidos sao permanentes (nao regeneram)
/// - Boss derrotado quando perde todas as 3 vidas
///
/// RECOMPENSAS:
/// - XP: 5x o XP normal do tier
/// - Kills: 3x os kills normais
/// - Chance de drop especial (implementar depois)
enum RaridadeMapa {
  comum,      // 1 estrela - 78%
  bonusXp,    // 2 estrelas - 12%
  umElite,    // 3 estrelas - 5%
  todosElite, // 4 estrelas - 4%
  boss;       // 5 estrelas - 1%

  /// Numero de estrelas para exibicao
  int get estrelas {
    switch (this) {
      case RaridadeMapa.comum:
        return 1;
      case RaridadeMapa.bonusXp:
        return 2;
      case RaridadeMapa.umElite:
        return 3;
      case RaridadeMapa.todosElite:
        return 4;
      case RaridadeMapa.boss:
        return 5;
    }
  }

  /// Nome para exibicao
  String get displayName {
    switch (this) {
      case RaridadeMapa.comum:
        return 'Comum';
      case RaridadeMapa.bonusXp:
        return 'Bonus XP';
      case RaridadeMapa.umElite:
        return 'Elite';
      case RaridadeMapa.todosElite:
        return 'Todos Elite';
      case RaridadeMapa.boss:
        return 'Boss';
    }
  }

  /// Descricao do efeito
  String get descricao {
    switch (this) {
      case RaridadeMapa.comum:
        return 'Mapa comum';
      case RaridadeMapa.bonusXp:
        return '+25% XP';
      case RaridadeMapa.umElite:
        return '1 monstro elite';
      case RaridadeMapa.todosElite:
        return 'Todos elite';
      case RaridadeMapa.boss:
        return 'Enfrente o Boss!';
    }
  }

  /// Cor para exibicao na UI
  String get corHex {
    switch (this) {
      case RaridadeMapa.comum:
        return '#9E9E9E'; // Cinza
      case RaridadeMapa.bonusXp:
        return '#4CAF50'; // Verde
      case RaridadeMapa.umElite:
        return '#2196F3'; // Azul
      case RaridadeMapa.todosElite:
        return '#9C27B0'; // Roxo
      case RaridadeMapa.boss:
        return '#FF9800'; // Laranja/Dourado
    }
  }

  /// Se tem bonus de XP
  bool get temBonusXp => this == RaridadeMapa.bonusXp;

  /// Se tem pelo menos 1 elite
  bool get temElite => this == RaridadeMapa.umElite || this == RaridadeMapa.todosElite;

  /// Se todos sao elite
  bool get todosSaoElite => this == RaridadeMapa.todosElite;

  /// Se e mapa de boss
  bool get isBoss => this == RaridadeMapa.boss;

  /// Converte numero de estrelas para raridade
  static RaridadeMapa fromEstrelas(int estrelas) {
    switch (estrelas) {
      case 1:
        return RaridadeMapa.comum;
      case 2:
        return RaridadeMapa.bonusXp;
      case 3:
        return RaridadeMapa.umElite;
      case 4:
        return RaridadeMapa.todosElite;
      case 5:
        return RaridadeMapa.boss;
      default:
        return RaridadeMapa.comum;
    }
  }
}

/// Mapas tematicos fixos do Modo Explorador
/// Cada mapa tem 3 tipos nativos que definem:
/// - 50% de chance dos inimigos serem desse tipo
/// - +25% HP para monstros com tipo nativo (jogador e inimigo)
enum MapaTematico {
  floresta,
  oceano,
  vulcao,
  deserto,
  cidadeAbandonada,
  cemiterio,
  temploCelestial,
  dimensaoDesconhecida,
  torreMagica,
  montanha;

  /// Nome para exibicao
  String get displayName {
    switch (this) {
      case MapaTematico.floresta:
        return 'Floresta';
      case MapaTematico.oceano:
        return 'Oceano';
      case MapaTematico.vulcao:
        return 'Vulcao';
      case MapaTematico.deserto:
        return 'Deserto';
      case MapaTematico.cidadeAbandonada:
        return 'Cidade Abandonada';
      case MapaTematico.cemiterio:
        return 'Cemiterio';
      case MapaTematico.temploCelestial:
        return 'Templo Celestial';
      case MapaTematico.dimensaoDesconhecida:
        return 'Dimensao Desconhecida';
      case MapaTematico.torreMagica:
        return 'Torre Magica';
      case MapaTematico.montanha:
        return 'Montanha';
    }
  }

  /// Imagem do mapa
  String get imagem {
    switch (this) {
      case MapaTematico.floresta:
        return 'assets/mapas_aventura/floresta_verde.jpg';
      case MapaTematico.oceano:
        return 'assets/mapas_aventura/praia.jpg';
      case MapaTematico.vulcao:
        return 'assets/mapas_aventura/vulcao.jpg';
      case MapaTematico.deserto:
        return 'assets/mapas_aventura/deserto.jpg';
      case MapaTematico.cidadeAbandonada:
        return 'assets/mapas_aventura/cidade_abandonada.jpg';
      case MapaTematico.cemiterio:
        return 'assets/mapas_aventura/cemiterio.jpg';
      case MapaTematico.temploCelestial:
        return 'assets/mapas_aventura/templo_celestial.jpg';
      case MapaTematico.dimensaoDesconhecida:
        return 'assets/mapas_aventura/dimensao_desconhecida.jpg';
      case MapaTematico.torreMagica:
        return 'assets/mapas_aventura/torre_magica.jpg';
      case MapaTematico.montanha:
        return 'assets/mapas_aventura/montanha.jpg';
    }
  }

  /// 3 tipos nativos do mapa
  List<Tipo> get tiposNativos {
    switch (this) {
      case MapaTematico.floresta:
        return [Tipo.inseto, Tipo.planta, Tipo.fera];
      case MapaTematico.oceano:
        return [Tipo.marinho, Tipo.agua, Tipo.gelo];
      case MapaTematico.vulcao:
        return [Tipo.fogo, Tipo.dragao, Tipo.pedra];
      case MapaTematico.deserto:
        return [Tipo.terrestre, Tipo.vento, Tipo.venenoso];
      case MapaTematico.cidadeAbandonada:
        return [Tipo.tecnologia, Tipo.eletrico, Tipo.zumbi];
      case MapaTematico.cemiterio:
        return [Tipo.fantasma, Tipo.trevas, Tipo.nostalgico];
      case MapaTematico.temploCelestial:
        return [Tipo.luz, Tipo.deus, Tipo.mistico];
      case MapaTematico.dimensaoDesconhecida:
        return [Tipo.alien, Tipo.desconhecido, Tipo.tempo];
      case MapaTematico.torreMagica:
        return [Tipo.magico, Tipo.psiquico, Tipo.docrates];
      case MapaTematico.montanha:
        return [Tipo.voador, Tipo.subterraneo, Tipo.normal];
    }
  }

  /// Verifica se um tipo e nativo deste mapa
  bool tipoNativo(Tipo tipo) => tiposNativos.contains(tipo);

  /// Tenta inferir o tema pelos tipos (para compatibilidade)
  static MapaTematico fromTipos(List<Tipo> tipos) {
    if (tipos.isEmpty) return MapaTematico.floresta;

    final tipoPrincipal = tipos.first;
    for (final tema in MapaTematico.values) {
      if (tema.tiposNativos.contains(tipoPrincipal)) {
        return tema;
      }
    }
    return MapaTematico.floresta;
  }
}
