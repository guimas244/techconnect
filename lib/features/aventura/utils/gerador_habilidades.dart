import 'dart:math';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../models/habilidade.dart';
import 'gerador_nomes_habilidades.dart';
import '../../../core/models/atributo_jogo_enum.dart';

class GeradorHabilidades {
  static final _random = Random();

  /// Gera 4 habilidades para um monstro baseado nos seus tipos
  static List<Habilidade> gerarHabilidadesMonstro(Tipo tipo, Tipo? tipoExtra, {int? levelCustomizado}) {
    final habilidades = <Habilidade>[];
    
    for (int i = 0; i < 4; i++) {
      habilidades.add(_gerarHabilidadeAleatoria(tipo, tipoExtra, levelCustomizado: levelCustomizado));
    }
    
    return habilidades;
  }

  static Habilidade _gerarHabilidadeAleatoria(Tipo tipo, Tipo? tipoExtra, {int? levelCustomizado}) {
    // Determina o tipo da habilidade (40% suporte, 60% ofensiva)
    final isSuporte = _random.nextDouble() < 0.4;
    final tipoHabilidade = isSuporte ? TipoHabilidade.suporte : TipoHabilidade.ofensiva;
    
    // Escolhe o tipo elemental (50% cada tipo do monstro)
    final tipos = [tipo];
    if (tipoExtra != null) tipos.add(tipoExtra);
    final tipoElemental = tipos[_random.nextInt(tipos.length)];
    
    // Determina o efeito baseado no tipo
    final efeito = _determinarEfeito(tipoHabilidade);
    
    // Gera valor baseado no efeito
    final valor = _gerarValor(efeito);
    
    // Gera custo de energia (1 a 5)
    final custoEnergia = _gerarCustoEnergia();
    
    // Gera nome e descrição usando o novo gerador
    final nome = GeradorNomesHabilidades.gerarNome(tipoElemental, efeito);
    final descricao = _gerarDescricao(efeito, valor, tipoElemental, custoEnergia);
    
    return Habilidade(
      nome: nome,
      descricao: descricao,
      tipo: tipoHabilidade,
      efeito: efeito,
      tipoElemental: tipoElemental,
      valor: valor,
      custoEnergia: custoEnergia,
      level: levelCustomizado ?? _gerarLevel(),
    );
  }

  static EfeitoHabilidade _determinarEfeito(TipoHabilidade tipo) {
    if (tipo == TipoHabilidade.suporte) {
      // 80% aumentar atributos, 20% curar vida
      final isCura = _random.nextDouble() < 0.2;
      
      if (isCura) {
        return EfeitoHabilidade.curarVida;
      } else {
        // Escolhe aleatoriamente entre os efeitos de aumento
        final efeitosAumento = [
          EfeitoHabilidade.aumentarVida,
          EfeitoHabilidade.aumentarEnergia,
          EfeitoHabilidade.aumentarAtaque,
          EfeitoHabilidade.aumentarDefesa,
        ];
        return efeitosAumento[_random.nextInt(efeitosAumento.length)];
      }
    } else {
      return EfeitoHabilidade.danoDirecto;
    }
  }

  static int _gerarValor(EfeitoHabilidade efeito) {
    switch (efeito) {
      case EfeitoHabilidade.aumentarVida:
        return AtributoJogo.habilidadeAumentarVida.sortear(_random);
      case EfeitoHabilidade.aumentarEnergia:
        return AtributoJogo.habilidadeAumentarEnergia.sortear(_random);
      case EfeitoHabilidade.aumentarAtaque:
        return AtributoJogo.habilidadeAumentarAtaque.sortear(_random);
      case EfeitoHabilidade.aumentarDefesa:
        return AtributoJogo.habilidadeAumentarDefesa.sortear(_random);
      case EfeitoHabilidade.curarVida:
        return AtributoJogo.habilidadeCura.sortear(_random);
      case EfeitoHabilidade.danoDirecto:
        return AtributoJogo.habilidadeDano.sortear(_random);
    }
  }

  /// Gera custo de energia aleatório de 1 a 5
  static int _gerarCustoEnergia() {
    return 1 + _random.nextInt(5); // 1-5
  }

  /// Gera level inicial sempre 1
  static int _gerarLevel() {
    return 1; // Sempre inicia no level 1
  }

  static String _gerarDescricao(EfeitoHabilidade efeito, int valor, Tipo tipo, int custoEnergia) {
    final sufixoTipo = _obterSufixoTipo(tipo);
    final custoTexto = ' (Custo: $custoEnergia energia)';
    
    switch (efeito) {
      case EfeitoHabilidade.aumentarVida:
        return 'Aumenta a vida máxima em $valor pontos durante toda a luta$sufixoTipo$custoTexto.';
      case EfeitoHabilidade.aumentarEnergia:
        return 'Aumenta a energia máxima em $valor pontos durante toda a luta$sufixoTipo$custoTexto.';
      case EfeitoHabilidade.aumentarAtaque:
        return 'Aumenta o ataque em $valor pontos durante toda a luta$sufixoTipo$custoTexto.';
      case EfeitoHabilidade.aumentarDefesa:
        return 'Aumenta a defesa em $valor pontos durante toda a luta$sufixoTipo$custoTexto.';
      case EfeitoHabilidade.curarVida:
        return 'Recupera $valor pontos de vida instantaneamente$sufixoTipo$custoTexto.';
      case EfeitoHabilidade.danoDirecto:
        return 'Causa $valor pontos de dano direto ao oponente$sufixoTipo$custoTexto.';
    }
  }

  static String _obterSufixoTipo(Tipo tipo) {
    switch (tipo) {
      case Tipo.normal:
        return '';
      case Tipo.planta:
        return ' usando energia natural';
      case Tipo.inseto:
        return ' com precisão insectóide';
      case Tipo.venenoso:
        return ' com toxinas';
      case Tipo.fera:
        return ' com instinto animal';
      case Tipo.fantasma:
        return ' com energia espectral';
      case Tipo.agua:
        return ' com poder aquático';
      default:
        return ' com energia especial';
    }
  }
}
