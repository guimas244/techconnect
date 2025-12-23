import 'dart:math';
import 'monstro_explorador.dart';

/// Equipe do Modo Explorador
///
/// Composicao:
/// - 2 monstros ativos (participam das batalhas)
/// - 3 monstros no banco (1 aleatorio recebe 1 XP extra por vitoria)
class EquipeExplorador {
  final List<MonstroExplorador> monstrosAtivos; // Max 2
  final List<MonstroExplorador> monstrosBanco;   // Max 3

  // Progresso no modo
  final int tierAtual;
  final int batalhasNoTier; // Contador de batalhas (a cada 3, escolhe mapa)
  final int batalhasTotais;

  const EquipeExplorador({
    this.monstrosAtivos = const [],
    this.monstrosBanco = const [],
    this.tierAtual = 1,
    this.batalhasNoTier = 0,
    this.batalhasTotais = 0,
  });

  /// Total de monstros na equipe
  int get totalMonstros => monstrosAtivos.length + monstrosBanco.length;

  /// Verifica se a equipe esta completa
  bool get equipeCompleta => monstrosAtivos.length == 2 && monstrosBanco.length == 3;

  /// Verifica se pode iniciar batalha (minimo 1 monstro ativo)
  bool get podeIniciarBatalha => monstrosAtivos.isNotEmpty;

  /// Verifica se precisa escolher mapa (a cada 3 batalhas)
  bool get precisaEscolherMapa => batalhasNoTier > 0 && batalhasNoTier % 3 == 0;

  /// Todos os monstros (ativos + banco)
  List<MonstroExplorador> get todosMonstros => [...monstrosAtivos, ...monstrosBanco];

  /// Adiciona monstro a equipe ativa
  EquipeExplorador adicionarMonstroAtivo(MonstroExplorador monstro) {
    if (monstrosAtivos.length >= 2) {
      print('[EquipeExplorador] Equipe ativa cheia (max 2)');
      return this;
    }

    final novoMonstro = monstro.copyWith(estaAtivo: true);
    return copyWith(
      monstrosAtivos: [...monstrosAtivos, novoMonstro],
    );
  }

  /// Adiciona monstro ao banco
  EquipeExplorador adicionarMonstroAoBanco(MonstroExplorador monstro) {
    if (monstrosBanco.length >= 3) {
      print('[EquipeExplorador] Banco cheio (max 3)');
      return this;
    }

    final novoMonstro = monstro.copyWith(estaAtivo: false);
    return copyWith(
      monstrosBanco: [...monstrosBanco, novoMonstro],
    );
  }

  /// Remove monstro da equipe (por ID)
  EquipeExplorador removerMonstro(String monstroId) {
    return copyWith(
      monstrosAtivos: monstrosAtivos.where((m) => m.id != monstroId).toList(),
      monstrosBanco: monstrosBanco.where((m) => m.id != monstroId).toList(),
    );
  }

  /// Move monstro do banco para ativo
  EquipeExplorador moverParaAtivo(String monstroId) {
    final monstro = monstrosBanco.firstWhere(
      (m) => m.id == monstroId,
      orElse: () => throw Exception('Monstro nao encontrado no banco'),
    );

    if (monstrosAtivos.length >= 2) {
      print('[EquipeExplorador] Equipe ativa cheia');
      return this;
    }

    return copyWith(
      monstrosAtivos: [...monstrosAtivos, monstro.copyWith(estaAtivo: true)],
      monstrosBanco: monstrosBanco.where((m) => m.id != monstroId).toList(),
    );
  }

  /// Move monstro do ativo para banco
  EquipeExplorador moverParaBanco(String monstroId) {
    final monstro = monstrosAtivos.firstWhere(
      (m) => m.id == monstroId,
      orElse: () => throw Exception('Monstro nao encontrado nos ativos'),
    );

    if (monstrosBanco.length >= 3) {
      print('[EquipeExplorador] Banco cheio');
      return this;
    }

    return copyWith(
      monstrosAtivos: monstrosAtivos.where((m) => m.id != monstroId).toList(),
      monstrosBanco: [...monstrosBanco, monstro.copyWith(estaAtivo: false)],
    );
  }

  /// Troca posicao de dois monstros
  EquipeExplorador trocarMonstros(String monstroId1, String monstroId2) {
    final monstro1 = todosMonstros.firstWhere((m) => m.id == monstroId1);
    final monstro2 = todosMonstros.firstWhere((m) => m.id == monstroId2);

    // Se ambos estao na mesma lista, apenas troca posicao
    if (monstro1.estaAtivo == monstro2.estaAtivo) {
      if (monstro1.estaAtivo) {
        // Ambos ativos
        final novosAtivos = monstrosAtivos.map((m) {
          if (m.id == monstroId1) return monstro2;
          if (m.id == monstroId2) return monstro1;
          return m;
        }).toList();
        return copyWith(monstrosAtivos: novosAtivos);
      } else {
        // Ambos no banco
        final novosBanco = monstrosBanco.map((m) {
          if (m.id == monstroId1) return monstro2;
          if (m.id == monstroId2) return monstro1;
          return m;
        }).toList();
        return copyWith(monstrosBanco: novosBanco);
      }
    }

    // Se estao em listas diferentes, move cada um para a lista oposta
    if (monstro1.estaAtivo) {
      // monstro1 vai para banco, monstro2 vai para ativos
      return copyWith(
        monstrosAtivos: monstrosAtivos.map((m) {
          if (m.id == monstroId1) return monstro2.copyWith(estaAtivo: true);
          return m;
        }).toList(),
        monstrosBanco: monstrosBanco.map((m) {
          if (m.id == monstroId2) return monstro1.copyWith(estaAtivo: false);
          return m;
        }).toList(),
      );
    } else {
      // monstro1 vai para ativos, monstro2 vai para banco
      return copyWith(
        monstrosAtivos: monstrosAtivos.map((m) {
          if (m.id == monstroId2) return monstro1.copyWith(estaAtivo: true);
          return m;
        }).toList(),
        monstrosBanco: monstrosBanco.map((m) {
          if (m.id == monstroId1) return monstro2.copyWith(estaAtivo: false);
          return m;
        }).toList(),
      );
    }
  }

  /// Atualiza monstro na equipe
  EquipeExplorador atualizarMonstro(MonstroExplorador monstroAtualizado) {
    return copyWith(
      monstrosAtivos: monstrosAtivos.map((m) {
        return m.id == monstroAtualizado.id ? monstroAtualizado : m;
      }).toList(),
      monstrosBanco: monstrosBanco.map((m) {
        return m.id == monstroAtualizado.id ? monstroAtualizado : m;
      }).toList(),
    );
  }

  /// Adiciona XP a todos os monstros apos batalha
  /// Monstros ativos recebem XP completo
  /// 1 monstro aleatorio do banco recebe o XP completo (sorteio)
  EquipeExplorador distribuirXp(int xpBatalha) {
    final novosAtivos = monstrosAtivos.map((m) {
      return m.adicionarXp(xpBatalha);
    }).toList();

    // Se tem monstros no banco, sorteia 1 para receber o XP completo
    var novosBanco = monstrosBanco.toList();
    if (novosBanco.isNotEmpty) {
      final random = Random();
      final indiceSorteado = random.nextInt(novosBanco.length);
      novosBanco = novosBanco.asMap().entries.map((entry) {
        if (entry.key == indiceSorteado) {
          // Este monstro foi sorteado, recebe o XP completo
          return entry.value.adicionarXp(xpBatalha);
        }
        return entry.value;
      }).toList();
    }

    return copyWith(
      monstrosAtivos: novosAtivos,
      monstrosBanco: novosBanco,
    );
  }

  /// Cura todos os monstros da equipe
  EquipeExplorador curarEquipe() {
    return copyWith(
      monstrosAtivos: monstrosAtivos.map((m) => m.curar()).toList(),
      monstrosBanco: monstrosBanco.map((m) => m.curar()).toList(),
    );
  }

  /// Registra uma batalha
  EquipeExplorador registrarBatalha({bool vitoria = true}) {
    return copyWith(
      batalhasNoTier: batalhasNoTier + 1,
      batalhasTotais: batalhasTotais + 1,
    );
  }

  /// Muda o tier (apos escolha de mapa)
  EquipeExplorador mudarTier(int novoTier) {
    return copyWith(
      tierAtual: novoTier.clamp(1, 11),
      batalhasNoTier: 0, // Reseta contador
    );
  }

  factory EquipeExplorador.fromJson(Map<String, dynamic> json) {
    return EquipeExplorador(
      monstrosAtivos: (json['monstrosAtivos'] as List<dynamic>?)
          ?.map((m) => MonstroExplorador.fromJson(m))
          .toList() ?? [],
      monstrosBanco: (json['monstrosBanco'] as List<dynamic>?)
          ?.map((m) => MonstroExplorador.fromJson(m))
          .toList() ?? [],
      tierAtual: json['tierAtual'] ?? 1,
      batalhasNoTier: json['batalhasNoTier'] ?? 0,
      batalhasTotais: json['batalhasTotais'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monstrosAtivos': monstrosAtivos.map((m) => m.toJson()).toList(),
      'monstrosBanco': monstrosBanco.map((m) => m.toJson()).toList(),
      'tierAtual': tierAtual,
      'batalhasNoTier': batalhasNoTier,
      'batalhasTotais': batalhasTotais,
    };
  }

  EquipeExplorador copyWith({
    List<MonstroExplorador>? monstrosAtivos,
    List<MonstroExplorador>? monstrosBanco,
    int? tierAtual,
    int? batalhasNoTier,
    int? batalhasTotais,
  }) {
    return EquipeExplorador(
      monstrosAtivos: monstrosAtivos ?? this.monstrosAtivos,
      monstrosBanco: monstrosBanco ?? this.monstrosBanco,
      tierAtual: tierAtual ?? this.tierAtual,
      batalhasNoTier: batalhasNoTier ?? this.batalhasNoTier,
      batalhasTotais: batalhasTotais ?? this.batalhasTotais,
    );
  }
}
