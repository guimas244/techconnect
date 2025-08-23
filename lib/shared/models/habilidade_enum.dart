import 'package:flutter/material.dart';

enum TipoHabilidade {
  suporte,
  ofensiva;

  String get nome {
    switch (this) {
      case TipoHabilidade.suporte:
        return 'Suporte';
      case TipoHabilidade.ofensiva:
        return 'Ofensiva';
    }
  }

  Color get cor {
    switch (this) {
      case TipoHabilidade.suporte:
        return Colors.white;
      case TipoHabilidade.ofensiva:
        return Colors.black;
    }
  }

  String get descricao {
    switch (this) {
      case TipoHabilidade.suporte:
        return 'Habilidades que fortalecem ou curam';
      case TipoHabilidade.ofensiva:
        return 'Habilidades que causam dano';
    }
  }
}

enum EfeitoHabilidade {
  aumentarVida,
  aumentarEnergia,
  aumentarAgilidade,
  aumentarAtaque,
  aumentarDefesa,
  curarVida,
  danoDirecto;

  String get nome {
    switch (this) {
      case EfeitoHabilidade.aumentarVida:
        return 'Aumentar Vida';
      case EfeitoHabilidade.aumentarEnergia:
        return 'Aumentar Energia';
      case EfeitoHabilidade.aumentarAgilidade:
        return 'Aumentar Agilidade';
      case EfeitoHabilidade.aumentarAtaque:
        return 'Aumentar Ataque';
      case EfeitoHabilidade.aumentarDefesa:
        return 'Aumentar Defesa';
      case EfeitoHabilidade.curarVida:
        return 'Curar Vida';
      case EfeitoHabilidade.danoDirecto:
        return 'Dano Direto';
    }
  }

  String get descricao {
    switch (this) {
      case EfeitoHabilidade.aumentarVida:
        return 'Aumenta permanentemente a vida máxima durante a luta';
      case EfeitoHabilidade.aumentarEnergia:
        return 'Aumenta permanentemente a energia máxima durante a luta';
      case EfeitoHabilidade.aumentarAgilidade:
        return 'Aumenta permanentemente a agilidade durante a luta';
      case EfeitoHabilidade.aumentarAtaque:
        return 'Aumenta permanentemente o ataque durante a luta';
      case EfeitoHabilidade.aumentarDefesa:
        return 'Aumenta permanentemente a defesa durante a luta';
      case EfeitoHabilidade.curarVida:
        return 'Recupera vida instantaneamente';
      case EfeitoHabilidade.danoDirecto:
        return 'Causa dano direto ao oponente';
    }
  }

  bool get isSuporte {
    switch (this) {
      case EfeitoHabilidade.aumentarVida:
      case EfeitoHabilidade.aumentarEnergia:
      case EfeitoHabilidade.aumentarAgilidade:
      case EfeitoHabilidade.aumentarAtaque:
      case EfeitoHabilidade.aumentarDefesa:
      case EfeitoHabilidade.curarVida:
        return true;
      case EfeitoHabilidade.danoDirecto:
        return false;
    }
  }

  TipoHabilidade get tipo {
    return isSuporte ? TipoHabilidade.suporte : TipoHabilidade.ofensiva;
  }
}
