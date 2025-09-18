import 'dart:math';
import '../models/magia_drop.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../../core/models/atributo_jogo_enum.dart';

class MagiaService {
  final Random _random = Random();

  /// Gera uma magia aleatória para drop
  /// Não tem tipagem elemental definida (será definida quando equipada no monstro)
  MagiaDrop gerarMagiaAleatoria({int tierAtual = 1}) {
    // Sorteia tipo da magia (suporte ou ofensiva)
    final tipos = [TipoHabilidade.ofensiva, TipoHabilidade.suporte];
    final tipoSorteado = tipos[_random.nextInt(tipos.length)];
    
    // Sorteia efeito baseado no tipo
    EfeitoHabilidade efeitoSorteado;
    String prefixoDescricao;
    
    switch (tipoSorteado) {
      case TipoHabilidade.ofensiva:
        efeitoSorteado = EfeitoHabilidade.danoDirecto;
        prefixoDescricao = 'Causa dano';
        break;
      case TipoHabilidade.suporte:
        final efeitosSupporte = [
          EfeitoHabilidade.aumentarAtaque, 
          EfeitoHabilidade.aumentarDefesa, 
          EfeitoHabilidade.curarVida
        ];
        efeitoSorteado = efeitosSupporte[_random.nextInt(efeitosSupporte.length)];
        prefixoDescricao = efeitoSorteado == EfeitoHabilidade.curarVida ? 'Cura' : 'Aumenta atributos';
        break;
    }
    
    // Gera valores baseados no tier
    final valorBase = _gerarValorBaseMagia(tierAtual);
    final custoEnergia = _gerarCustoEnergia(valorBase);
    final levelMagia = _gerarLevelMagia(tierAtual);
    
    // Gera nome usando o gerador existente adaptado para magias
    final nome = _gerarNomeMagia(tipoSorteado, efeitoSorteado);
    final descricao = '$prefixoDescricao. Tipagem elemental será definida ao equipar no monstro.';
    
    return MagiaDrop(
      nome: nome,
      descricao: descricao,
      tipo: tipoSorteado,
      efeito: efeitoSorteado,
      valor: valorBase,
      custoEnergia: custoEnergia,
      level: levelMagia,
      dataObtencao: DateTime.now(),
    );
  }

  /// Gera valor base da magia usando os valores centralizados do AtributoJogo
  /// O valor é sorteado aleatoriamente entre os diferentes tipos de efeito
  int _gerarValorBaseMagia(int tier) {
    // Sorteia um valor entre os ranges das habilidades existentes
    // Isso garante que as magias tenham valores compatíveis com as habilidades normais
    final atributosSorteaveis = [
      AtributoJogo.habilidadeDano,
      AtributoJogo.habilidadeCura,
      AtributoJogo.habilidadeAumentarVida,
      AtributoJogo.habilidadeAumentarEnergia,
      AtributoJogo.habilidadeAumentarAtaque,
      AtributoJogo.habilidadeAumentarDefesa,
    ];
    
    final atributoSorteado = atributosSorteaveis[_random.nextInt(atributosSorteaveis.length)];
    return atributoSorteado.sortear(_random);
  }

  /// Gera custo de energia baseado no valor da magia
  int _gerarCustoEnergia(int valor) {
    if (valor <= 15) return 1;
    if (valor <= 25) return 2;
    if (valor <= 35) return 3;
    return 4;
  }

  /// Gera level da magia baseado no tier com chances similares aos inimigos
  int _gerarLevelMagia(int tier) {
    if (tier == 1) return 1;
    
    final chance = _random.nextInt(100);
    if (chance < 20) {
      // 20% chance: level = tier
      return tier;
    } else if (chance < 40) {
      // 20% chance: level = tier - 1 (mínimo 1)
      return (tier - 1).clamp(1, tier);
    } else {
      // 60% chance: level 1
      return 1;
    }
  }

  /// Gera nome da magia baseado no tipo e efeito
  String _gerarNomeMagia(TipoHabilidade tipo, EfeitoHabilidade efeito) {
    final prefixos = ['Magia', 'Encanto', 'Feitiço', 'Arte', 'Técnica'];
    final prefixoEscolhido = prefixos[_random.nextInt(prefixos.length)];
    
    String complemento;
    switch (tipo) {
      case TipoHabilidade.ofensiva:
        complemento = 'Destruidora';
        break;
      case TipoHabilidade.suporte:
        switch (efeito) {
          case EfeitoHabilidade.aumentarAtaque:
            complemento = 'do Poder';
            break;
          case EfeitoHabilidade.aumentarDefesa:
            complemento = 'da Proteção';
            break;
          case EfeitoHabilidade.curarVida:
            complemento = 'Curativa';
            break;
          default:
            complemento = 'de Suporte';
        }
        break;
    }
    
    // Adiciona raridade baseada no level
    final raridades = ['Menor', 'Comum', 'Rara', 'Épica', 'Lendária'];
    final indiceLevelRaridade = (_gerarLevelMagia(1) - 1).clamp(0, raridades.length - 1);
    final raridadeTexto = raridades[indiceLevelRaridade];
    
    return '$prefixoEscolhido $complemento $raridadeTexto';
  }
}