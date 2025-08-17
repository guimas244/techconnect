import 'package:flutter/material.dart';

enum Tipo {
  normal('Normal'),
  planta('Planta'),
  inseto('Inseto'),
  venenoso('Venenoso'),
  fera('Fera'),
  zumbi('Zumbi'),
  marinho('Marinho'),
  voador('Voador'),
  subterraneo('Subterrâneo'),
  terrestre('Terrestre'),
  fogo('Fogo'),
  gelo('Gelo'),
  agua('Água'),
  vento('Vento'),
  eletrico('Elétrico'),
  pedra('Pedra'),
  luz('Luz'),
  trevas('Trevas'),
  nostalgico('Nostálgico'),
  mistico('Místico'),
  dragao('Dragão'),
  alien('Alien'),
  docrates('Dócrates'),
  fantasma('Fantasma'),
  psiquico('Psíquico'),
  magico('Mágico'),
  tecnologia('Tecnologia'),
  tempo('Tempo'),
  desconhecido('Desconhecido'),
  deus('Deus');

  final String descricao;
  const Tipo(this.descricao);

  String get displayName => descricao;

  Color get cor {
    switch (this) {
      case Tipo.normal:
        return Colors.grey.shade600;
      case Tipo.planta:
        return Colors.green;
      case Tipo.inseto:
        return Colors.lightGreen.shade700;
      case Tipo.venenoso:
        return Colors.purple;
      case Tipo.fera:
        return Colors.brown;
      case Tipo.zumbi:
        return Colors.grey.shade800;
      case Tipo.marinho:
        return Colors.cyan;
      case Tipo.voador:
        return Colors.lightBlue;
      case Tipo.subterraneo:
        return Colors.brown.shade800;
      case Tipo.terrestre:
        return Colors.orange.shade800;
      case Tipo.fogo:
        return Colors.red;
      case Tipo.gelo:
        return Colors.lightBlue.shade300;
      case Tipo.agua:
        return Colors.blue;
      case Tipo.vento:
        return Colors.teal.shade300;
      case Tipo.eletrico:
        return Colors.yellow.shade600;
      case Tipo.pedra:
        return Colors.grey.shade700;
      case Tipo.luz:
        return Colors.amber.shade700;
      case Tipo.trevas:
        return Colors.black;
      case Tipo.nostalgico:
        return Colors.pink.shade300;
      case Tipo.mistico:
        return Colors.indigo;
      case Tipo.dragao:
        return Colors.red.shade800;
      case Tipo.alien:
        return Colors.green.shade300;
      case Tipo.docrates:
        return Colors.orange;
      case Tipo.fantasma:
        return Colors.purple.shade300;
      case Tipo.psiquico:
        return Colors.pink;
      case Tipo.magico:
        return Colors.deepPurple;
      case Tipo.tecnologia:
        return Colors.blueGrey;
      case Tipo.tempo:
        return Colors.amber;
      case Tipo.desconhecido:
        return Colors.grey.shade400;
      case Tipo.deus:
        return Colors.amber.shade600;
    }
  }

  IconData get icone {
    switch (this) {
      case Tipo.normal:
        return Icons.circle_outlined;
      case Tipo.planta:
        return Icons.grass;
      case Tipo.inseto:
        return Icons.bug_report;
      case Tipo.venenoso:
        return Icons.dangerous;
      case Tipo.fera:
        return Icons.pets;
      case Tipo.zumbi:
        return Icons.sentiment_very_dissatisfied;
      case Tipo.marinho:
        return Icons.waves;
      case Tipo.voador:
        return Icons.flight;
      case Tipo.subterraneo:
        return Icons.terrain;
      case Tipo.terrestre:
        return Icons.landscape;
      case Tipo.fogo:
        return Icons.local_fire_department;
      case Tipo.gelo:
        return Icons.ac_unit;
      case Tipo.agua:
        return Icons.water_drop;
      case Tipo.vento:
        return Icons.air;
      case Tipo.eletrico:
        return Icons.flash_on;
      case Tipo.pedra:
        return Icons.emoji_nature;
      case Tipo.luz:
        return Icons.light_mode;
      case Tipo.trevas:
        return Icons.dark_mode;
      case Tipo.nostalgico:
        return Icons.favorite;
      case Tipo.mistico:
        return Icons.auto_fix_high;
      case Tipo.dragao:
        return Icons.whatshot;
      case Tipo.alien:
        return Icons.psychology;
      case Tipo.docrates:
        return Icons.science;
      case Tipo.fantasma:
        return Icons.visibility_off;
      case Tipo.psiquico:
        return Icons.psychology_alt;
      case Tipo.magico:
        return Icons.stars;
      case Tipo.tecnologia:
        return Icons.precision_manufacturing;
      case Tipo.tempo:
        return Icons.access_time;
      case Tipo.desconhecido:
        return Icons.help_outline;
      case Tipo.deus:
        return Icons.brightness_7;
    }
  }

  String get iconAsset {
    switch (this) {
      case Tipo.normal:
        return 'assets/tipagens/icon_tipo_normal.png';
      case Tipo.planta:
        return 'assets/tipagens/icon_tipo_planta.png';
      case Tipo.inseto:
        return 'assets/tipagens/icon_tipo_inseto.png';
      case Tipo.venenoso:
        return 'assets/tipagens/icon_tipo_venenoso.png';
      case Tipo.fera:
        return 'assets/tipagens/icon_tipo_fera.png';
      case Tipo.zumbi:
        return 'assets/tipagens/icon_tipo_zumbi.png';
      case Tipo.marinho:
        return 'assets/tipagens/icon_tipo_marinho.png';
      case Tipo.voador:
        return 'assets/tipagens/icon_tipo_voador.png';
      case Tipo.subterraneo:
        return 'assets/tipagens/icon_tipo_subterraneo.png';
      case Tipo.terrestre:
        return 'assets/tipagens/icon_tipo_terrestre.png';
      case Tipo.fogo:
        return 'assets/tipagens/icon_tipo_fogo.png';
      case Tipo.gelo:
        return 'assets/tipagens/icon_tipo_gelo.png';
      case Tipo.agua:
        return 'assets/tipagens/icon_tipo_agua.png';
      case Tipo.vento:
        return 'assets/tipagens/icon_tipo_vento.png';
      case Tipo.eletrico:
        return 'assets/tipagens/icon_tipo_eletrico.png';
      case Tipo.pedra:
        return 'assets/tipagens/icon_tipo_pedra.png';
      case Tipo.luz:
        return 'assets/tipagens/icon_tipo_luz.png';
      case Tipo.trevas:
        return 'assets/tipagens/icon_tipo_trevas.png';
      case Tipo.nostalgico:
        return 'assets/tipagens/icon_tipo_nostalgico.png';
      case Tipo.mistico:
        return 'assets/tipagens/icon_tipo_mistico.png';
      case Tipo.dragao:
        return 'assets/tipagens/icon_tipo_dragao.png';
      case Tipo.alien:
        return 'assets/tipagens/icon_tipo_alien.png';
      case Tipo.docrates:
        return 'assets/tipagens/icon_tipo_docrates.png';
      case Tipo.fantasma:
        return 'assets/tipagens/icon_tipo_desconhecido.png'; // Usando desconhecido como fallback
      case Tipo.psiquico:
        return 'assets/tipagens/icon_tipo_desconhecido.png'; // Usando desconhecido como fallback
      case Tipo.magico:
        return 'assets/tipagens/icon_tipo_magico.png';
      case Tipo.tecnologia:
        return 'assets/tipagens/icon_tipo_desconhecido.png'; // Usando desconhecido como fallback
      case Tipo.tempo:
        return 'assets/tipagens/icon_tipo_desconhecido.png'; // Usando desconhecido como fallback
      case Tipo.desconhecido:
        return 'assets/tipagens/icon_tipo_desconhecido.png';
      case Tipo.deus:
        return 'assets/tipagens/icon_tipo_deus.png';
    }
  }
}
