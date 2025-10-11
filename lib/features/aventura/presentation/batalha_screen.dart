import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/batalha.dart';
import '../models/habilidade.dart';
import '../models/item.dart';
import '../models/historia_jogador.dart';
import '../models/magia_drop.dart';
import '../models/drop.dart';
import '../services/drops_service.dart';
import '../models/progresso_diario.dart';
import '../providers/aventura_provider.dart';
import '../providers/progresso_bonus_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../tipagem/data/tipagem_repository.dart';
import '../services/item_service.dart';
import '../services/evolucao_service.dart';
import '../services/magia_service.dart';
import '../services/colecao_service.dart';
import '../services/recompensa_service.dart';
import '../../jogador/services/vantagens_service.dart';
import 'modal_monstro_desbloqueado.dart';
import '../models/item_consumivel.dart';
import '../models/mochila.dart';
import '../../../core/config/score_config.dart';
import 'modal_limite_score.dart';
import '../services/mochila_service.dart';
import 'modal_recompensas_batalha.dart';
import 'modal_monstro_inimigo.dart';
import 'modal_monstro_aventura.dart';

class _ResultadoEvolucao {
  final HistoriaJogador historiaAtualizada;
  final List<MonstroAventura> evoluidos;
  final Map<MonstroAventura, Map<String, int>> ganhos;
  final Map<MonstroAventura, Map<String, dynamic>?> habilidades;

  const _ResultadoEvolucao({
    required this.historiaAtualizada,
    required this.evoluidos,
    required this.ganhos,
    required this.habilidades,
  });
}

class _DropResultado {
  final Item? item;
  final int? tier;
  final RaridadeItem? raridade;
  final MagiaDrop? magia;
  final List<ItemConsumivel> consumiveis;
  final int moedaEvento; // Quantidade de moedas de evento

  const _DropResultado({
    this.item,
    this.tier,
    this.raridade,
    this.magia,
    this.consumiveis = const [],
    this.moedaEvento = 0,
  });
}

class _PacoteRecompensas {
  final RecompensasBatalha recompensas;
  final List<MonstroAventura> timeAtualizado;
  final Mochila mochila;
  final String emailJogador;

  const _PacoteRecompensas({
    required this.recompensas,
    required this.timeAtualizado,
    required this.mochila,
    required this.emailJogador,
  });
}
class BatalhaScreen extends ConsumerStatefulWidget {
  final MonstroAventura jogador;
  final MonstroInimigo inimigo;

  const BatalhaScreen({
    super.key,
    required this.jogador,
    required this.inimigo,
  });

  @override
  ConsumerState<BatalhaScreen> createState() => _BatalhaScreenState();
}

class _BatalhaScreenState extends ConsumerState<BatalhaScreen> {
  final Random _random = Random();
  final TipagemRepository _tipagemRepository = TipagemRepository();
  
  // Estado da batalha
  EstadoBatalha? estadoAtual;
  bool batalhaConcluida = false;
  bool salvandoResultado = false;
  bool processandoVitoria = false;
  bool processandoDerrota = false;
  bool jogadorComeca = true;
  bool itemGerado = false;
  bool evolucaoProcessada = false;
  bool monstroRaroDesbloqueado = false;
  bool scoreAtualizado = false;
  bool podeVoltarParaAventura = false;
  int turnoAtual = 1;
  bool vezDoJogador = true;
  String? ultimaAcao;
  String? vencedor;
  
  // Animações e UI
  bool mostrandoAcao = false;
  bool aguardandoContinuar = false;
  bool batalhaAutomatica = false; // Controla se está rodando batalha automática

  @override
  void initState() {
    super.initState();
    _inicializarBatalha();
    _verificarInicializacaoTipagem();
  }

  void _verificarInicializacaoTipagem() async {
    // Verifica se o sistema de tipagem está inicializado
    final isInicializado = await _tipagemRepository.isInicializadoAsync;
    if (!isInicializado) {
      print('?? [Batalha] Sistema de tipagem não inicializado, usando valores padrão');
    } else {
      print('? [Batalha] Sistema de tipagem inicializado e pronto');
    }
  }

  void _inicializarBatalha() {
    print('??? [BatalhaScreen] Inicializando batalha...');
    
    // Estado inicial da batalha
    // Aplica bônus do item equipado do jogador
    final item = widget.jogador.itemEquipado;
    final ataqueComItem = widget.jogador.ataque + (item?.ataque ?? 0);
    final defesaComItem = widget.jogador.defesa + (item?.defesa ?? 0);
    final vidaComItem = widget.jogador.vida + (item?.vida ?? 0);
    final vidaAtualComItem = widget.jogador.vidaAtual + (item?.vida ?? 0);
    final energiaComItem = widget.jogador.energia + (item?.energia ?? 0);
    final agilidadeComItem = widget.jogador.agilidade + (item?.agilidade ?? 0);

    // Aplica bônus do item equipado do inimigo (sem multiplicadores - valores fixos do JSON)
    final itemInimigo = widget.inimigo.itemEquipado;
    
    // Debug: mostra stats base do inimigo
    print('?? [DEBUG] Inimigo stats base: ATK=${widget.inimigo.ataque} DEF=${widget.inimigo.defesa} HP=${widget.inimigo.vidaAtual}/${widget.inimigo.vida} AGI=${widget.inimigo.agilidade}');
    print('?? [DEBUG] Inimigo stats com item: ATK=${widget.inimigo.ataqueTotal} DEF=${widget.inimigo.defesaTotal} HP=${widget.inimigo.vidaAtual}/${widget.inimigo.vidaTotal} AGI=${widget.inimigo.agilidadeTotal}');
    if (itemInimigo != null) {
      print('?? [DEBUG] Item do inimigo: ${itemInimigo.nome} - ATK+${itemInimigo.ataque} DEF+${itemInimigo.defesa} HP+${itemInimigo.vida} AGI+${itemInimigo.agilidade}');
    } else {
      print('?? [DEBUG] Inimigo SEM item equipado');
    }
    final ataqueInimigoTotal = widget.inimigo.ataqueTotal;
    final defesaInimigoTotal = widget.inimigo.defesaTotal;
    final vidaInimigoTotal = widget.inimigo.vidaTotal;
    // Vida atual do inimigo: JSON base + bônus do item
    final vidaAtualComBonusItem = widget.inimigo.vidaAtual + (itemInimigo?.vida ?? 0);
    final vidaAtualInimigoTotal = vidaAtualComBonusItem;
    final energiaInimigoTotal = widget.inimigo.energiaTotal;
    final agilidadeInimigoTotal = widget.inimigo.agilidadeTotal;
    
    // Determina quem começa baseado na agilidade
    jogadorComeca = agilidadeComItem >= agilidadeInimigoTotal;
    vezDoJogador = true; // Sempre inicia esperando ação do jogador (rodada completa)
    
    print('?? [Stats] Jogador: ATK=$ataqueComItem DEF=$defesaComItem HP=$vidaAtualComItem/$vidaComItem AGI=$agilidadeComItem');
    print('?? [Stats] Inimigo Lv${widget.inimigo.level}: ATK=$ataqueInimigoTotal DEF=$defesaInimigoTotal HP=$vidaAtualInimigoTotal/$vidaInimigoTotal AGI=$agilidadeInimigoTotal');
    if (itemInimigo != null) {
      print('?? [Item] Inimigo equipado: ${itemInimigo.nome}');
    }

    estadoAtual = EstadoBatalha(
      jogador: widget.jogador,
      inimigo: widget.inimigo,
      vidaAtualJogador: vidaAtualComItem, // Usa vida atual + bônus do item
      vidaAtualInimigo: vidaAtualInimigoTotal, // Usa vida atual + level multiplier
      vidaMaximaJogador: vidaComItem, // Vida máxima inicial + item
      vidaMaximaInimigo: vidaInimigoTotal, // Vida máxima + item + level
      energiaAtualJogador: energiaComItem, // Usa energia máxima (energia base + item)
      energiaAtualInimigo: energiaInimigoTotal, // Usa energia máxima (energia base + item + level)
      energiaMaximaJogador: energiaComItem, // Energia máxima inicial + item
      energiaMaximaInimigo: energiaInimigoTotal, // Energia máxima + item + level
      ataqueAtualJogador: ataqueComItem,
      defesaAtualJogador: defesaComItem,
      ataqueAtualInimigo: ataqueInimigoTotal, // Ataque + item + level
      defesaAtualInimigo: defesaInimigoTotal, // Defesa + item + level
      habilidadesUsadasJogador: [],
      habilidadesUsadasInimigo: [],
      historicoAcoes: [],
    );
    
    print('?? [Batalha] ${jogadorComeca ? "Jogador" : "Inimigo"} começa a rodada');
  }

  void _executarRodadaCompleta() {
    if (estadoAtual == null || batalhaConcluida) return;
    
    setState(() {
      mostrandoAcao = true;
      aguardandoContinuar = false;
    });
    
    // Executa rodada completa (ambos ataques) seguindo ordem de agilidade
    _executarRodadaCompletatAsync();
  }

  /// Executa a batalha inteira automaticamente até o fim
  void _resumirBatalha() {
    if (estadoAtual == null || batalhaConcluida) return;
    
    print('? [Batalha Automática] Iniciando batalha automática...');
    
    setState(() {
      batalhaAutomatica = true;
      mostrandoAcao = true;
      aguardandoContinuar = false;
    });
    
    _executarBatalhaAutomaticaAsync();
  }

  /// Executa batalha automaticamente até alguém vencer
  Future<void> _executarBatalhaAutomaticaAsync() async {
    if (estadoAtual == null || batalhaConcluida) return;
    
    EstadoBatalha estadoAtualizado = estadoAtual!;
    int maxRodadas = 50; // Limite de segurança para evitar loops infinitos
    int rodadaCount = 0;
    
    while (!batalhaConcluida && rodadaCount < maxRodadas) {
      rodadaCount++;
      print('? [Auto Battle] Rodada $rodadaCount');
      
      // Determina ordem dos ataques baseada na agilidade
      bool jogadorPrimeiro = jogadorComeca;
      
      // Primeiro ataque
      if (jogadorPrimeiro) {
        estadoAtualizado = await _executarAtaqueJogador(estadoAtualizado);
        if (estadoAtualizado.vidaAtualInimigo <= 0) {
          _finalizarBatalhaAutomatica(estadoAtualizado, 'jogador');
          return;
        }
        
        // Pequeno delay para não sobrecarregar
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Segundo ataque (inimigo)
        estadoAtualizado = await _executarAtaqueInimigo(estadoAtualizado);
        if (estadoAtualizado.vidaAtualJogador <= 0) {
          _finalizarBatalhaAutomatica(estadoAtualizado, 'inimigo');
          return;
        }
      } else {
        estadoAtualizado = await _executarAtaqueInimigo(estadoAtualizado);
        if (estadoAtualizado.vidaAtualJogador <= 0) {
          _finalizarBatalhaAutomatica(estadoAtualizado, 'inimigo');
          return;
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        estadoAtualizado = await _executarAtaqueJogador(estadoAtualizado);
        if (estadoAtualizado.vidaAtualInimigo <= 0) {
          _finalizarBatalhaAutomatica(estadoAtualizado, 'jogador');
          return;
        }
      }
      
      // Atualiza estado
      if (mounted) {
        setState(() {
          estadoAtual = estadoAtualizado;
          turnoAtual++;
        });
      }
      
      // Pequeno delay entre rodadas
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // Se chegou no limite de rodadas, empate
    if (rodadaCount >= maxRodadas) {
      print('?? [Auto Battle] Limite de rodadas atingido, finalizando como empate');
      _finalizarBatalhaAutomatica(estadoAtualizado, 'empate');
    }
  }

  /// Finaliza batalha automática e processa resultados
  void _finalizarBatalhaAutomatica(EstadoBatalha estadoFinal, String vencedorFinal) {
    print('? [Auto Battle] Finalizando batalha automática - Vencedor: $vencedorFinal');
    
    setState(() {
      batalhaAutomatica = false;
      mostrandoAcao = false;
      aguardandoContinuar = false;
    });
    
    // Usa a lógica existente de finalização
    _finalizarRodada(estadoFinal, vencedorFinal);
  }
  
  Future<void> _executarRodadaCompletatAsync() async {
    if (estadoAtual == null || batalhaConcluida) return;
    
    // Determina ordem dos ataques baseada na agilidade (usa a mesma lógica da inicialização)
    bool jogadorPrimeiro = jogadorComeca;
    
    print('?? [Rodada] Iniciando rodada completa - ${jogadorPrimeiro ? "Jogador" : "Inimigo"} ataca primeiro');
    
    EstadoBatalha estadoAtualizado = estadoAtual!;
    
    // Primeiro ataque
    if (jogadorPrimeiro) {
      estadoAtualizado = await _executarAtaqueJogador(estadoAtualizado);
      if (estadoAtualizado.vidaAtualInimigo <= 0) {
        _finalizarRodada(estadoAtualizado, 'jogador');
        return;
      }
      
      // Segundo ataque (inimigo)
      await Future.delayed(const Duration(milliseconds: 1000));
      estadoAtualizado = await _executarAtaqueInimigo(estadoAtualizado);
      if (estadoAtualizado.vidaAtualJogador <= 0) {
        _finalizarRodada(estadoAtualizado, 'inimigo');
        return;
      }
    } else {
      estadoAtualizado = await _executarAtaqueInimigo(estadoAtualizado);
      if (estadoAtualizado.vidaAtualJogador <= 0) {
        _finalizarRodada(estadoAtualizado, 'inimigo');
        return;
      }
      
      // Segundo ataque (jogador)
      await Future.delayed(const Duration(milliseconds: 1000));
      estadoAtualizado = await _executarAtaqueJogador(estadoAtualizado);
      if (estadoAtualizado.vidaAtualInimigo <= 0) {
        _finalizarRodada(estadoAtualizado, 'jogador');
        return;
      }
    }
    
    // Se chegou aqui, ambos ainda estão vivos - continua para próxima rodada
    _finalizarRodada(estadoAtualizado, null);
  }
  
  Future<EstadoBatalha> _executarAtaqueJogador(EstadoBatalha estado) async {
    // Seleciona habilidade aleatória do jogador que pode ser usada
    final habilidadesDisponiveis = widget.jogador.habilidades
        .where((h) => (h.tipo == TipoHabilidade.ofensiva || 
                      !estado.habilidadesUsadasJogador.contains(h.nome)) &&
                     h.custoEnergia <= estado.energiaAtualJogador) // Verifica se tem energia
        .toList();
    
    if (habilidadesDisponiveis.isEmpty) {
      print('?? [Jogador] Sem energia para habilidades - usando ataque básico');
      // Executa ataque básico quando não tem energia para habilidades
      return await _executarAtaqueBasico(estado, true); // true = é jogador
    }
    
    final habilidade = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    print('?? [Jogador] Usando ${habilidade.nome} (custo: ${habilidade.custoEnergia})');
    
    // Aplica habilidade e desconta energia
    var novoEstado = await _aplicarHabilidade(estado, habilidade, true);
    
    // Desconta energia (limita pela energia máxima com item durante a batalha)
    novoEstado = novoEstado.copyWith(
      energiaAtualJogador: (estado.energiaAtualJogador - habilidade.custoEnergia).clamp(0, estado.energiaMaximaJogador)
    );
    
    return novoEstado;
  }
  
  Future<EstadoBatalha> _executarAtaqueInimigo(EstadoBatalha estado) async {
    // Seleciona habilidade aleatória do inimigo que pode ser usada
    final habilidadesDisponiveis = widget.inimigo.habilidades
        .where((h) => (h.tipo == TipoHabilidade.ofensiva || 
                      !estado.habilidadesUsadasInimigo.contains(h.nome)) &&
                     h.custoEnergia <= estado.energiaAtualInimigo) // Verifica se tem energia
        .toList();
    
    if (habilidadesDisponiveis.isEmpty) {
      print('?? [Inimigo] Sem energia para habilidades - usando ataque básico');
      // Executa ataque básico quando não tem energia para habilidades
      return await _executarAtaqueBasico(estado, false); // false = é inimigo
    }
    
    final habilidade = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    print('?? [Inimigo] Usando ${habilidade.nome} (custo: ${habilidade.custoEnergia})');
    
    // Aplica habilidade e desconta energia
    var novoEstado = await _aplicarHabilidade(estado, habilidade, false);
    
    // Desconta energia (limita pela energia máxima com item durante a batalha)
    novoEstado = novoEstado.copyWith(
      energiaAtualInimigo: (estado.energiaAtualInimigo - habilidade.custoEnergia).clamp(0, estado.energiaMaximaInimigo)
    );
    
    return novoEstado;
  }
  
  void _finalizarRodada(EstadoBatalha estadoFinal, String? vencedorRodada) {
    // Prepara um resumo mais claro da rodada
    String resumoRodada = '';
    if (estadoFinal.historicoAcoes.length >= 2) {
      final ultimasAcoes = estadoFinal.historicoAcoes.sublist(estadoFinal.historicoAcoes.length - 2);
      final primeiroAtaque = ultimasAcoes[0];
      final segundoAtaque = ultimasAcoes[1];
      
      resumoRodada = 'Rodada $turnoAtual concluída!\n\n';
      resumoRodada += '1º: ${_resumirAcao(primeiroAtaque)}\n';
      resumoRodada += '2º: ${_resumirAcao(segundoAtaque)}\n\n';
      // Mostra 0 se vida negativa nos logs
      int vidaJogadorDisplay = estadoFinal.vidaAtualJogador < 0 ? 0 : estadoFinal.vidaAtualJogador;
      int vidaInimigoDisplay = estadoFinal.vidaAtualInimigo < 0 ? 0 : estadoFinal.vidaAtualInimigo;
      resumoRodada += 'Vida atual: Jogador $vidaJogadorDisplay/${widget.jogador.vida} | Inimigo $vidaInimigoDisplay/${widget.inimigo.vida}\n';
      resumoRodada += 'Energia atual: Jogador ${estadoFinal.energiaAtualJogador}/${widget.jogador.energia} | Inimigo ${estadoFinal.energiaAtualInimigo}/${widget.inimigo.energia}';
    } else if (estadoFinal.historicoAcoes.isNotEmpty) {
      final ultimaAcao = estadoFinal.historicoAcoes.last;
      resumoRodada = 'Ação executada!\n${_resumirAcao(ultimaAcao)}';
    } else {
      resumoRodada = 'Rodada executada!';
    }
    
    setState(() {
      estadoAtual = estadoFinal;
      turnoAtual++;
      mostrandoAcao = false;
      aguardandoContinuar = true;
      ultimaAcao = resumoRodada;
    });
    
    // Salva o estado após a rodada completa
    _salvarEstadoBatalha();
    
    // Se alguém morreu, finaliza batalha
    if (vencedorRodada != null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _finalizarBatalha(vencedorRodada);
      });
    }
  }
  
  String _resumirAcao(AcaoBatalha acao) {
    // Verifica se foi dano ou cura/buff baseado na diferença de vida
    bool foiDano = acao.vidaDepois < acao.vidaAntes;
    bool foiCura = acao.vidaDepois > acao.vidaAntes;
    
    if (foiDano) {
      return '${acao.atacante} causou ${acao.danoTotal} de dano';
    } else if (foiCura) {
      int cura = acao.vidaDepois - acao.vidaAntes;
      return '${acao.atacante} curou $cura de vida';
    } else {
      // Buff/suporte sem alteração de vida
      return '${acao.atacante} usou habilidade de suporte';
    }
  }
  
  void _continuarBatalha() {
    setState(() {
      aguardandoContinuar = false;
    });
    
    // Próxima rodada começa automaticamente
    Future.delayed(const Duration(milliseconds: 500), () {
      _executarRodadaCompleta();
    });
  }

  Future<EstadoBatalha> _aplicarHabilidade(EstadoBatalha estado, Habilidade habilidade, bool isJogador) async {
    if (habilidade.tipo == TipoHabilidade.suporte) {
      return _aplicarHabilidadeSuporte(estado, habilidade, isJogador);
    } else {
      return await _aplicarHabilidadeDano(estado, habilidade, isJogador);
    }
  }

  EstadoBatalha _aplicarHabilidadeSuporte(EstadoBatalha estado, Habilidade habilidade, bool isJogador) {
    String atacante = isJogador ? estado.jogador.tipo.monsterName : estado.inimigo.tipo.monsterName;
    String descricao = '';
    
    EstadoBatalha novoEstado = estado;
    
    // Aplica efeito de suporte
    switch (habilidade.efeito) {
      case EfeitoHabilidade.curarVida:
        if (isJogador) {
          int vidaAntes = estado.vidaAtualJogador;
          int novaVida = (estado.vidaAtualJogador + habilidade.valorEfetivo).clamp(0, estado.jogador.vida);
          novoEstado = estado.copyWith(vidaAtualJogador: novaVida);
          int curaReal = novaVida - vidaAntes;
          descricao = '$atacante curou $curaReal de vida (${vidaAntes}?${novaVida}) usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        } else {
          int vidaAntes = estado.vidaAtualInimigo;
          int novaVida = (estado.vidaAtualInimigo + habilidade.valorEfetivo).clamp(0, estado.inimigo.vida);
          novoEstado = estado.copyWith(vidaAtualInimigo: novaVida);
          int curaReal = novaVida - vidaAntes;
          descricao = '$atacante curou $curaReal de vida (${vidaAntes}?${novaVida}) usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        }
        break;
        
      case EfeitoHabilidade.aumentarAtaque:
        if (isJogador) {
          int ataqueAntes = estado.ataqueAtualJogador;
          int novoAtaque = estado.ataqueAtualJogador + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(ataqueAtualJogador: novoAtaque);
          descricao = '$atacante aumentou o ataque de $ataqueAntes para $novoAtaque (+${habilidade.valorEfetivo}) usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        } else {
          int ataqueAntes = estado.ataqueAtualInimigo;
          int novoAtaque = estado.ataqueAtualInimigo + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(ataqueAtualInimigo: novoAtaque);
          descricao = '$atacante aumentou o ataque de $ataqueAntes para $novoAtaque (+${habilidade.valorEfetivo}) usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        }
        break;
        
      case EfeitoHabilidade.aumentarDefesa:
        if (isJogador) {
          int defesaAntes = estado.defesaAtualJogador;
          int novaDefesa = estado.defesaAtualJogador + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(defesaAtualJogador: novaDefesa);
          descricao = '$atacante aumentou a defesa de $defesaAntes para $novaDefesa (+${habilidade.valorEfetivo}) usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        } else {
          int defesaAntes = estado.defesaAtualInimigo;
          int novaDefesa = estado.defesaAtualInimigo + habilidade.valorEfetivo;
          novoEstado = estado.copyWith(defesaAtualInimigo: novaDefesa);
          descricao = '$atacante aumentou a defesa de $defesaAntes para $novaDefesa (+${habilidade.valorEfetivo}) usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        }
        break;
        
      case EfeitoHabilidade.aumentarVida:
        if (isJogador) {
          // Aumenta vida máxima e vida atual proporcionalmente
          int vidaMaximaAntes = estado.vidaMaximaJogador;
          int vidaAtualAntes = estado.vidaAtualJogador;
          int novaVidaMaxima = vidaMaximaAntes + habilidade.valorEfetivo;
          int novaVidaAtual = vidaAtualAntes + habilidade.valorEfetivo; // Aumenta a atual também
          
          novoEstado = estado.copyWith(
            vidaMaximaJogador: novaVidaMaxima,
            vidaAtualJogador: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima de $vidaMaximaAntes para $novaVidaMaxima (+${habilidade.valorEfetivo}) e vida atual para $novaVidaAtual usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        } else {
          // Aumenta vida máxima e vida atual proporcionalmente
          int vidaMaximaAntes = estado.vidaMaximaInimigo;
          int vidaAtualAntes = estado.vidaAtualInimigo;
          int novaVidaMaxima = vidaMaximaAntes + habilidade.valorEfetivo;
          int novaVidaAtual = vidaAtualAntes + habilidade.valorEfetivo; // Aumenta a atual também
          
          novoEstado = estado.copyWith(
            vidaMaximaInimigo: novaVidaMaxima,
            vidaAtualInimigo: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima de $vidaMaximaAntes para $novaVidaMaxima (+${habilidade.valorEfetivo}) e vida atual para $novaVidaAtual usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        }
        break;
        
      case EfeitoHabilidade.aumentarEnergia:
        if (isJogador) {
          // Aumenta energia máxima e energia atual proporcionalmente
          int energiaMaximaAntes = estado.energiaMaximaJogador;
          int energiaAtualAntes = estado.energiaAtualJogador;
          int novaEnergiaMaxima = energiaMaximaAntes + habilidade.valorEfetivo;
          int novaEnergiaAtual = energiaAtualAntes + habilidade.valorEfetivo; // Aumenta a atual também
          
          novoEstado = estado.copyWith(
            energiaAtualJogador: novaEnergiaAtual,
            energiaMaximaJogador: novaEnergiaMaxima,
          );
          descricao = '$atacante aumentou a energia máxima de $energiaMaximaAntes para $novaEnergiaMaxima (+${habilidade.valorEfetivo}) e energia atual para $novaEnergiaAtual usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        } else {
          // Aumenta energia máxima e energia atual proporcionalmente
          int energiaMaximaAntes = estado.energiaMaximaInimigo;
          int energiaAtualAntes = estado.energiaAtualInimigo;
          int novaEnergiaMaxima = energiaMaximaAntes + habilidade.valorEfetivo;
          int novaEnergiaAtual = energiaAtualAntes + habilidade.valorEfetivo; // Aumenta a atual também
          
          novoEstado = estado.copyWith(
            energiaAtualInimigo: novaEnergiaAtual,
            energiaMaximaInimigo: novaEnergiaMaxima,
          );
          descricao = '$atacante aumentou a energia máxima de $energiaMaximaAntes para $novaEnergiaMaxima (+${habilidade.valorEfetivo}) e energia atual para $novaEnergiaAtual usando ${habilidade.nome}[${habilidade.tipoElemental.displayName}]';
        }
        break;
        
      default:
        descricao = '$atacante usou ${habilidade.nome}[${habilidade.tipoElemental.displayName}] (efeito: ${habilidade.valorEfetivo})';
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
    
    return novoEstado;
  }

  Future<EstadoBatalha> _aplicarHabilidadeDano(EstadoBatalha estado, Habilidade habilidade, bool isJogador) async {
    String atacante = isJogador ? estado.jogador.tipo.monsterName : estado.inimigo.tipo.monsterName;

    // CORREÇÃO: Sempre usa o tipo elemental da habilidade
    Tipo tipoAtaque = habilidade.tipoElemental;
    Tipo tipoDefensor = isJogador ? estado.inimigo.tipo : estado.jogador.tipo;

    // Calcula dano base
    int ataqueAtacante = isJogador ? estado.ataqueAtualJogador : estado.ataqueAtualInimigo;
    int defesaAlvo = isJogador ? estado.defesaAtualInimigo : estado.defesaAtualJogador;

    int danoBase = habilidade.valorEfetivo;
    int danoComAtaque = danoBase + ataqueAtacante;

    // Calcula efetividade de tipo usando tipo da habilidade
    double efetividade = await _calcularEfetividade(tipoAtaque, tipoDefensor);

    // Aplica efetividade ao dano
    int danoComTipo = (danoComAtaque * efetividade).round();
    
    // Verifica imunidade primeiro (efetividade = 0.0)
    if (efetividade == 0.0) {
      danoComTipo = 0;
    }
    
    // Define dano mínimo baseado no tipo de habilidade (só se não for imune)
    int danoMinimo = (efetividade == 0.0) ? 0 : (habilidade.tipo == TipoHabilidade.ofensiva) ? 5 : 1;
    int danoFinal = (danoComTipo - defesaAlvo).clamp(danoMinimo, danoComTipo);

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

    // Cria descrição detalhada com informações de tipo e stats
    String efetividadeTexto = _obterTextoEfetividade(efetividade);
    
    // Monta info de ataque mostrando bônus
    String ataqueInfo = ataqueAtacante.toString();
    if (isJogador && widget.jogador.itemEquipado != null) {
      final bonusAtaque = widget.jogador.itemEquipado!.ataque ?? 0;
      if (bonusAtaque > 0) {
        ataqueInfo = '${widget.jogador.ataque}+$bonusAtaque=$ataqueAtacante';
      }
    } else if (!isJogador && (widget.inimigo.itemEquipado != null || widget.inimigo.level > 1)) {
      final baseAtaque = widget.inimigo.ataque;
      final bonusItem = widget.inimigo.itemEquipado?.ataque ?? 0;
      final levelMult = 1.0 + (widget.inimigo.level - 1) * 0.1;
      if (widget.inimigo.level > 1) {
        ataqueInfo = '$baseAtaque${bonusItem > 0 ? '+$bonusItem' : ''}×${levelMult.toStringAsFixed(1)}=$ataqueAtacante';
      } else if (bonusItem > 0) {
        ataqueInfo = '$baseAtaque+$bonusItem=$ataqueAtacante';
      }
    }
    
    String descricao = '$atacante (${tipoAtaque.displayName}) usou ${habilidade.nome}[${habilidade.tipoElemental.displayName}]: $danoBase (+$ataqueInfo ataque) x${efetividade.toStringAsFixed(1)} $efetividadeTexto - $defesaAlvo defesa = $danoFinal de dano. Vida: $vidaAntes?$vidaDepois';
    
    // Adiciona mensagem especial se aplicou dano mínimo mágico ou imunidade
    if (efetividade == 0.0) {
      descricao += ' (imune - nenhum dano foi causado)';
    } else if (habilidade.tipo == TipoHabilidade.ofensiva && (danoComTipo - defesaAlvo) < 5) {
      descricao += ' (a habilidade causou 5 de dano penetrante)';
    }

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

    return novoEstado;
  }

  void _finalizarBatalha(String vencedorBatalha) {
    print('?? [BatalhaScreen] Finalizando batalha com vencedor: $vencedorBatalha');
    if (mounted) {
      setState(() {
        batalhaConcluida = true;
        vencedor = vencedorBatalha;
        // Ativa o loading de processamento quando jogador vence
        if (vencedorBatalha == 'jogador') {
          processandoVitoria = true;
        } else {
          // Ativa o loading de processamento quando jogador perde
          processandoDerrota = true;
        }
      });
    }
    
    // Se o jogador venceu, calcular score e gerar item
    if (vencedorBatalha == 'jogador') {
      print('?? [BatalhaScreen] Jogador venceu, processando score e recompensas...');
      _atualizarScoreEGerarItem();
    } else {
      // Se perdeu, salva batalha no histórico sem dar score
      _salvarBatalhaDerrota().then((_) {
        _salvarResultadoLocal().then((_) {
          if (mounted) {
            setState(() {
              processandoDerrota = false; // Desativa o loading
              podeVoltarParaAventura = true;
            });
          }
        });
      });
    }
  }

  Future<void> _atualizarScoreEGerarItem() async {
    if (scoreAtualizado) {
      print('?? [BatalhaScreen] Score já atualizado, ignorando chamada duplicada');
      return;
    }
    scoreAtualizado = true;
    
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      
      // Carrega história atual para atualizar score
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia != null) {
        // Calcula score ganho baseado no tier
        final scoreGanho = ScoreConfig.ehPosTransicao(historia.tier)
            ? ScoreConfig.SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS
            : historia.tier;

        // Calcula novo score com limite de pontos extras
        int novoScore = historia.score + scoreGanho;

        // Se tier 11+, aplica limite máximo de pontos extras (100)
        if (ScoreConfig.ehPosTransicao(historia.tier)) {
          final scoreMaximoExtras = ScoreConfig.scoreMaximoExtras;
          if (novoScore > scoreMaximoExtras) {
            novoScore = scoreMaximoExtras;
            print('⚠️ [BatalhaScreen] Score limitado ao máximo de extras: $scoreMaximoExtras');
          }
        }

        print('🎯 [BatalhaScreen] Monstro derrotado! Score ganho: $scoreGanho (tier ${historia.tier})');
        print('📊 [BatalhaScreen] Score anterior: ${historia.score}, novo score: $novoScore');
        
        // Cria registro da batalha
        final registroBatalha = RegistroBatalha(
          jogadorNome: widget.jogador.tipo.monsterName,
          inimigoNome: widget.inimigo.tipo.monsterName,
          acoes: estadoAtual?.historicoAcoes ?? [],
          vencedor: 'jogador',
          dataHora: DateTime.now(),
          vidaInicialJogador: widget.jogador.vida,
          vidaFinalJogador: estadoAtual?.vidaAtualJogador ?? 0,
          vidaInicialInimigo: widget.inimigo.vida,
          vidaFinalInimigo: estadoAtual?.vidaAtualInimigo ?? 0,
          tierNaBatalha: historia.tier,
          scoreAntes: historia.score,
          scoreDepois: novoScore,
          scoreGanho: scoreGanho,
        );
        
        // Verifica se deve mostrar modal de limite de 50 pontos
        bool mostrarModalLimite = false;
        if (ScoreConfig.ehPreTransicao(historia.tier) &&
            novoScore >= ScoreConfig.SCORE_LIMITE_PRE_TIER_11 &&
            !historia.mensagemLimite50Mostrada) {
          mostrarModalLimite = true;
        }

        // Atualiza história com novo score e histórico da batalha
        final historiaComScore = historia.copyWith(
          score: novoScore,
          historicoBatalhas: [...historia.historicoBatalhas, registroBatalha],
          mensagemLimite50Mostrada: mostrarModalLimite ? true : historia.mensagemLimite50Mostrada,
        );
        // Salva histórico apenas no HIVE (SEM atualizar ranking em vitórias)
        await repository.salvarHistoricoJogadorLocal(historiaComScore);

        print('? [BatalhaScreen] Score atualizado e batalha salva no histórico local (sem ranking)!');

        // Mostra modal de limite se necessário (após salvar)
        if (mostrarModalLimite && mounted) {
          print('⚠️ [BatalhaScreen] Score atingiu ${ScoreConfig.SCORE_LIMITE_PRE_TIER_11} - Mostrando modal de alerta');
          // Aguarda um frame para garantir que o widget está montado
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => const ModalLimiteScore(),
              );
            }
          });
        }
      }

      // ?? Processa cura pós-batalha da coleção nostálgica
      await _processarCuraPosBatalha();

      // ?? Processa desbloqueio de monstro raro se aplicável
      await _processarDesbloqueioMonstroRaro();

    } catch (e) {
      print('? [BatalhaScreen] Erro ao atualizar score: $e');
    }
    
    // Primeiro processa evolução, depois ITENS EQUIPÁVEIS (não drops/prêmios)
    await _processarEvolucaoEItens();
  }

  Future<void> _salvarBatalhaDerrota() async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);

      // Carrega história atual
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia != null) {
        // Cria registro da batalha sem dar score
        final registroBatalha = RegistroBatalha(
          jogadorNome: widget.jogador.tipo.monsterName,
          inimigoNome: widget.inimigo.tipo.monsterName,
          acoes: estadoAtual?.historicoAcoes ?? [],
          vencedor: 'inimigo',
          dataHora: DateTime.now(),
          vidaInicialJogador: widget.jogador.vida,
          vidaFinalJogador: estadoAtual?.vidaAtualJogador ?? 0,
          vidaInicialInimigo: widget.inimigo.vida,
          vidaFinalInimigo: estadoAtual?.vidaAtualInimigo ?? 0,
          tierNaBatalha: historia.tier,
          scoreAntes: historia.score,
          scoreDepois: historia.score, // Score não muda em derrota
          scoreGanho: 0, // Nenhum score ganho
        );

        // Atualiza história com histórico da batalha (sem alterar score)
        final historiaAtualizada = historia.copyWith(
          historicoBatalhas: [...historia.historicoBatalhas, registroBatalha],
        );

        // Salva histórico apenas no HIVE
        await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

        print('✅ [BatalhaScreen] Derrota registrada no histórico (sem score)!');
      }
    } catch (e) {
      print('❌ [BatalhaScreen] Erro ao salvar derrota: $e');
    }
  }

  Future<void> _processarCuraPosBatalha() async {
    try {
      print('?? [CuraPosBatalha] Iniciando processamento da cura pós-batalha...');
      final emailJogador = ref.read(validUserEmailProvider);
      final vantagensService = VantagensService();

      // Verifica quanto de cura o jogador tem da coleção nostálgica
      final curaPosBatalha = await vantagensService.obterCuraPosBatalha(emailJogador);
      print('?? [CuraPosBatalha] Cura disponível: $curaPosBatalha pontos');

      if (curaPosBatalha > 0 && estadoAtual != null) {
        final vidaAntesCura = estadoAtual!.vidaAtualJogador;
        final vidaMaxima = estadoAtual!.vidaMaximaJogador;

        // Só cura se o jogador não está com vida cheia
        if (vidaAntesCura < vidaMaxima) {
          final vidaDepoisCura = (vidaAntesCura + curaPosBatalha).clamp(0, vidaMaxima);
          final vidaCurada = vidaDepoisCura - vidaAntesCura;

          if (vidaCurada > 0) {
            // Atualiza o estado da batalha com a vida curada
            setState(() {
              estadoAtual = estadoAtual!.copyWith(vidaAtualJogador: vidaDepoisCura);
            });

            // Adiciona entrada no histórico da batalha
            final acaoCura = AcaoBatalha(
              atacante: 'Coleção Nostálgica',
              habilidadeNome: 'Cura Pós-Batalha',
              danoBase: vidaCurada,
              danoTotal: vidaCurada,
              defesaAlvo: 0,
              vidaAntes: vidaAntesCura,
              vidaDepois: vidaDepoisCura,
              descricao: 'Coleção Nostálgica restaurou $vidaCurada de vida. Vida: $vidaAntesCura?$vidaDepoisCura',
            );

            setState(() {
              estadoAtual = estadoAtual!.copyWith(
                historicoAcoes: [...estadoAtual!.historicoAcoes, acaoCura],
              );
            });

            print('?? [CuraPosBatalha] Jogador curou $vidaCurada de vida (total: $curaPosBatalha disponível)');
          }
        } else {
          print('?? [CuraPosBatalha] Jogador já está com vida cheia, não precisa de cura');
        }
      } else {
        print('?? [CuraPosBatalha] Nenhuma cura disponível da coleção nostálgica');
      }
    } catch (e) {
      print('? [CuraPosBatalha] Erro ao processar cura pós-batalha: $e');
    }
  }

  Future<void> _processarDesbloqueioMonstroRaro() async {
    try {
      // Verifica se o inimigo derrotado é um monstro raro
      if (!widget.inimigo.isRaro) {
        print('?? [Desbloqueio] Inimigo não é raro, ignorando desbloqueio');
        return;
      }

      final emailJogador = ref.read(validUserEmailProvider);
      final colecaoService = ColecaoService();

      // Verifica se o jogador já tem esse monstro desbloqueado
      final jaTemMonstro = await colecaoService.jogadorJaTemMonstro(
        emailJogador,
        widget.inimigo.tipo,
        ehNostalgico: widget.inimigo.ehNostalgico,
      );

      if (jaTemMonstro) {
        print('?? [Desbloqueio] Jogador já possui ${widget.inimigo.nome}, não adicionando novamente');
        return;
      }

      // Adiciona o monstro raro à coleção do jogador
      await colecaoService.adicionarMonstroAColecao(
        emailJogador,
        widget.inimigo.tipo,
        ehNostalgico: widget.inimigo.ehNostalgico,
      );

      print('?? [Desbloqueio] Monstro raro ${widget.inimigo.nome} desbloqueado e adicionado à coleção!');

      // Marca que houve desbloqueio para alterar o fluxo do modal
      setState(() {
        monstroRaroDesbloqueado = true;
      });

      // Mostra o modal de desbloqueio
      await _mostrarModalDesbloqueio();

    } catch (e) {
      print('? [Desbloqueio] Erro ao processar desbloqueio de monstro raro: $e');
    }
  }

  Future<void> _mostrarModalDesbloqueio() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalMonstroDesbloqueado(
        monstroDesbloqueado: widget.inimigo,
      ),
    );
  }


  Future<void> _processarEvolucaoEItens() async {
    if (evolucaoProcessada) {
      print('[BatalhaScreen] Evolucao e itens ja processados, ignorando chamada duplicada');
      return;
    }

    if (monstroRaroDesbloqueado) {
      print('[BatalhaScreen] Monstro raro desbloqueado, pulando evolucao e drops');
      evolucaoProcessada = true;
      await _finalizarBatalhaComSalvamento();
      return;
    }

    evolucaoProcessada = true;

    try {
      final pacote = await _montarRecompensasBatalha();
      if (!mounted) return;

      if (pacote == null) {
        await _finalizarBatalhaComSalvamento();
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ModalRecompensasBatalha(
          recompensas: pacote.recompensas,
          timeJogador: pacote.timeAtualizado,
          mochilaAtual: pacote.mochila,
          onEquiparItem: (monstro, item) => _equiparItemEMonstro(monstro, item),
          onDescartarItem: (item) async {
            print('[BatalhaScreen] Item descartado: ${item.nome}');
          },
          onEquiparMagia: (monstro, magia, habilidade) =>
              _equiparMagiaEMonstro(monstro, magia, habilidade),
          onDescartarMagia: (magia) async {
            print('[BatalhaScreen] Magia descartada: ${magia.nome}');
          },
          onGuardarItensNaMochila: (novosItens, slots, moedaEvento) =>
              _guardarItensNaMochila(
                pacote.emailJogador,
                pacote.mochila,
                novosItens,
                slots,
                moedaEvento: moedaEvento,
              ),
          onConcluir: _finalizarBatalhaComSalvamento,
        ),
      );
    } catch (e, stack) {
      print('[BatalhaScreen] Erro ao processar recompensas: $e');
      print(stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar recompensas: $e')),
        );
      }
      await _finalizarBatalhaComSalvamento();
    }
  }

  Future<_PacoteRecompensas?> _montarRecompensasBatalha() async {
    final emailJogador = ref.read(validUserEmailProvider);
    final repository = ref.read(aventuraRepositoryProvider);
    final evolucaoService = EvolucaoService();

    final historiaCarregada =
        await repository.carregarHistoricoJogador(emailJogador);
    if (historiaCarregada == null || historiaCarregada.monstros.isEmpty) {
      print('[BatalhaScreen] Historia do jogador nao encontrada para montar recompensas');
      return null;
    }

    final resultadoEvolucao = await _aplicarEvolucaoSeNecessario(
      historiaCarregada,
      evolucaoService,
      repository,
    );

    final historiaAtual =
        resultadoEvolucao?.historiaAtualizada ?? historiaCarregada;

    final drop = await _gerarDropParaRecompensas(historiaAtual);
    final mochila = await _carregarMochilaAtual(emailJogador);

    final recompensas = RecompensasBatalha(
      monstrosEvoluidos: resultadoEvolucao?.evoluidos ?? const [],
      ganhosAtributos: resultadoEvolucao?.ganhos ?? const {},
      habilidadesEvoluidas: resultadoEvolucao?.habilidades ?? const {},
      itemRecebido: drop.item,
      tierItem: drop.tier,
      raridadeItem: drop.raridade,
      magiaRecebida: drop.magia,
      itensConsumiveisRecebidos: drop.consumiveis,
      moedaEvento: drop.moedaEvento,
    );

    return _PacoteRecompensas(
      recompensas: recompensas,
      timeAtualizado: historiaAtual.monstros,
      mochila: mochila,
      emailJogador: emailJogador,
    );
  }

  Future<_ResultadoEvolucao?> _aplicarEvolucaoSeNecessario(
    HistoriaJogador historia,
    EvolucaoService evolucaoService,
    dynamic repository,
  ) async {
    final monstroSorteado =
        evolucaoService.sortearMonstroParaEvoluir(historia.monstros);
    if (monstroSorteado == null) {
      return null;
    }

    final levelInimigoDerrotado = widget.inimigo.level;
    final podeEvoluir =
        evolucaoService.podeEvoluir(monstroSorteado, levelInimigoDerrotado);

    var historiaAtualizada = historia;
    final evoluidos = <MonstroAventura>[];
    final ganhos = <MonstroAventura, Map<String, int>>{};
    final habilidades = <MonstroAventura, Map<String, dynamic>?>{};

    if (!podeEvoluir) {
      final resultadoHabilidade =
          evolucaoService.tentarEvoluirHabilidade(monstroSorteado, levelInimigoDerrotado);
      final monstroAtualizado =
          resultadoHabilidade['monstroAtualizado'] as MonstroAventura;

      evoluidos.add(monstroAtualizado);
      ganhos[monstroAtualizado] = {
        'levelAntes': monstroSorteado.level,
        'levelDepois': monstroAtualizado.level,
        'vida': monstroAtualizado.vida - monstroSorteado.vida,
        'energia': monstroAtualizado.energia - monstroSorteado.energia,
        'ataque': monstroAtualizado.ataque - monstroSorteado.ataque,
        'defesa': monstroAtualizado.defesa - monstroSorteado.defesa,
        'agilidade': monstroAtualizado.agilidade - monstroSorteado.agilidade,
      };

      final info = evolucaoService.criarInfoEvolucaoHabilidade(
        monstroSorteado,
        resultadoHabilidade,
      );
      final habilidadeInfo =
          info['habilidadeEvoluida'] as Map<String, dynamic>? ?? {};
      if (habilidadeInfo.isNotEmpty && habilidadeInfo['evoluiu'] == true) {
        // Buscar informações completas da habilidade antes e depois
        final habilidadeAntes = resultadoHabilidade['habilidadeAntes'] as Habilidade?;
        final habilidadeDepois = resultadoHabilidade['habilidadeDepois'] as Habilidade?;

        if (habilidadeAntes != null && habilidadeDepois != null) {
          habilidades[monstroAtualizado] = {
            'evoluiu': true,
            'nome': habilidadeDepois.nome,
            'descricao': habilidadeDepois.descricao,
            'tipo': habilidadeDepois.tipo.toString(),
            'efeito': habilidadeDepois.efeito.toString(),
            'levelAntes': habilidadeAntes.level,
            'levelDepois': habilidadeDepois.level,
            'valorAntes': habilidadeAntes.valor,
            'valorDepois': habilidadeDepois.valor,
            'valorEfetivoAntes': habilidadeAntes.valorEfetivo,
            'valorEfetivoDepois': habilidadeDepois.valorEfetivo,
            'custoEnergiaAntes': habilidadeAntes.custoEnergia,
            'custoEnergiaDepois': habilidadeDepois.custoEnergia,
          };
        }
      }

      if (resultadoHabilidade['habilidadeEvoluiu'] == true) {
        historiaAtualizada = historia.copyWith(
          monstros: historia.monstros.map((m) {
            if (m.tipo == monstroSorteado.tipo &&
                m.tipoExtra == monstroSorteado.tipoExtra &&
                m.imagem == monstroSorteado.imagem) {
              return monstroAtualizado;
            }
            return m;
          }).toList(),
        );
        await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
      }

      return _ResultadoEvolucao(
        historiaAtualizada: historiaAtualizada,
        evoluidos: evoluidos,
        ganhos: ganhos,
        habilidades: habilidades,
      );
    }

    final resultadoEvolucao =
        evolucaoService.evoluirMonstroCompleto(monstroSorteado, levelInimigoDerrotado);
    final monstroEvoluido =
        resultadoEvolucao['monstroEvoluido'] as MonstroAventura;

    evoluidos.add(monstroEvoluido);

    final infoCompleta =
        evolucaoService.criarInfoEvolucaoCompleta(monstroSorteado, resultadoEvolucao);
    final ganhosMapa = infoCompleta['ganhos'] as Map<String, dynamic>;
    ganhos[monstroEvoluido] = {
      'levelAntes': infoCompleta['levelAntes'] as int,
      'levelDepois': infoCompleta['levelDepois'] as int,
      'vida': ganhosMapa['vida'] as int,
      'energia': ganhosMapa['energia'] as int,
      'ataque': ganhosMapa['ataque'] as int,
      'defesa': ganhosMapa['defesa'] as int,
      'agilidade': ganhosMapa['agilidade'] as int,
    };

    final habilidadeInfo =
        infoCompleta['habilidadeEvoluida'] as Map<String, dynamic>? ?? {};
    if (habilidadeInfo.isNotEmpty && habilidadeInfo['evoluiu'] == true) {
      // Buscar informações completas da habilidade antes e depois
      final habilidadeAntes = resultadoEvolucao['habilidadeAntes'] as Habilidade?;
      final habilidadeDepois = resultadoEvolucao['habilidadeDepois'] as Habilidade?;

      if (habilidadeAntes != null && habilidadeDepois != null) {
        habilidades[monstroEvoluido] = {
          'evoluiu': true,
          'nome': habilidadeDepois.nome,
          'descricao': habilidadeDepois.descricao,
          'tipo': habilidadeDepois.tipo.toString(),
          'efeito': habilidadeDepois.efeito.toString(),
          'levelAntes': habilidadeAntes.level,
          'levelDepois': habilidadeDepois.level,
          'valorAntes': habilidadeAntes.valor,
          'valorDepois': habilidadeDepois.valor,
          'valorEfetivoAntes': habilidadeAntes.valorEfetivo,
          'valorEfetivoDepois': habilidadeDepois.valorEfetivo,
          'custoEnergiaAntes': habilidadeAntes.custoEnergia,
          'custoEnergiaDepois': habilidadeDepois.custoEnergia,
        };
      }
    }

    historiaAtualizada = historia.copyWith(
      monstros: historia.monstros.map((m) {
        if (m.tipo == monstroSorteado.tipo &&
            m.tipoExtra == monstroSorteado.tipoExtra &&
            m.imagem == monstroSorteado.imagem) {
          return monstroEvoluido;
        }
        return m;
      }).toList(),
    );

    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

    return _ResultadoEvolucao(
      historiaAtualizada: historiaAtualizada,
      evoluidos: evoluidos,
      ganhos: ganhos,
      habilidades: habilidades,
    );
  }

  String? _descricaoHabilidade(Map<String, dynamic> info) {
    if (info.isEmpty) return null;
    if (info['evoluiu'] == true) {
      final nome = info['nome'];
      final antes = info['levelAntes'];
      final depois = info['levelDepois'];
      if (nome != null && antes != null && depois != null) {
        return '$nome evoluiu para o nivel $depois (antes nivel $antes)';
      }
      return 'Habilidade evoluiu';
    }
    if (info['motivo'] == 'level_gap') {
      final nome = info['nome'];
      final levelAtual = info['levelAtual'];
      final levelInimigo = info['levelInimigo'];
      if (nome != null && levelAtual != null && levelInimigo != null) {
        return '$nome nao evoluiu: nivel atual $levelAtual, inimigo $levelInimigo';
      }
      return 'Habilidade nao evoluiu por diferenca de nivel';
    }
    return null;
  }

  Future<_DropResultado> _gerarDropParaRecompensas(
    HistoriaJogador historia,
  ) async {
    if (itemGerado) {
      print('[BatalhaScreen] Drop ja gerado, ignorando outra chamada');
      return const _DropResultado();
    }
    itemGerado = true;

    // DROPS: Sorteia os drops (poções/pedras) que irão para os slots especiais
    // NÃO adiciona ainda - apenas sorteia e exibe no modal
    // Só será salvo quando o jogador confirmar no modal de recompensas
    final consumiveis = <ItemConsumivel>[];
    try {
      final dropConsumivel = await DropsService.sortearDrop();
      if (dropConsumivel != null) {
        // Verifica se há espaço disponível antes de mostrar no modal
        final slotsLivres = await DropsService.slotsDisponiveis();
        if (slotsLivres > 0) {
          consumiveis.add(_converterDropConsumivel(dropConsumivel));
          print('[BatalhaScreen] Drop consumivel sorteado: ${dropConsumivel.tipo.nome} - Slots disponíveis: $slotsLivres');
        } else {
          print('[BatalhaScreen] Drop consumivel ${dropConsumivel.tipo.nome} sorteado mas sem slots (mochila cheia)');
        }
      } else {
        print('[BatalhaScreen] Nenhum drop consumivel sorteado desta vez');
      }
    } catch (e) {
      print('[BatalhaScreen] Erro ao sortear drop consumivel: $e');
    }

    final tierAtual = historia.tier;
    final itemService = ItemService();

    // Calcula drop de moeda de evento (independente de outros drops)
    final recompensaService = RecompensaService();
    final resultadoRecompensas = recompensaService.gerarRecompensasPorScore(1, tierAtual);
    final moedaEvento = resultadoRecompensas['moedaEvento'] as int;

    // ELITE: Sempre dropa item épico (nunca magia)
    if (widget.inimigo.isElite) {
      final item = itemService.gerarItemComRaridade(
        RaridadeItem.epico,
        tierAtual: tierAtual,
      );
      print('[BatalhaScreen] 🏆 Drop ÉPICO garantido por inimigo ELITE: ${item.nome}');
      return _DropResultado(
        item: item,
        tier: item.tier,
        raridade: item.raridade,
        consumiveis: consumiveis,
        moedaEvento: moedaEvento,
      );
    }

    // NÃO-ELITE: 30% magia, 70% item
    final chanceDrop = _random.nextInt(100);

    if (chanceDrop < 30) {
      final magiaService = MagiaService();
      final magia = magiaService.gerarMagiaAleatoria(tierAtual: tierAtual);
      print('[BatalhaScreen] ✨ Magia gerada: ${magia.nome} (tier $tierAtual)');
      return _DropResultado(
        magia: magia,
        consumiveis: consumiveis,
        moedaEvento: moedaEvento,
      );
    }

    // Item comum/raro/épico/lendário aleatório
    final item = itemService.gerarItemAleatorio(tierAtual: tierAtual);
    print('[BatalhaScreen] 🎒 Item gerado: ${item.nome} (${item.raridade.nome}) - tier ${item.tier}');

    return _DropResultado(
      item: item,
      tier: item.tier,
      raridade: item.raridade,
      consumiveis: consumiveis,
      moedaEvento: moedaEvento,
    );
  }

  Future<Mochila> _carregarMochilaAtual(String emailJogador) async {
    try {
      final mochila = await MochilaService.carregarMochila(context, emailJogador);
      if (mochila != null) {
        return mochila;
      }
    } catch (e) {
      print('[BatalhaScreen] Erro ao carregar mochila: $e');
    }
    return Mochila();
  }

  ItemConsumivel _converterDropConsumivel(Drop drop) {
    TipoItemConsumivel tipoConsumivel;
    RaridadeConsumivel raridade;

    switch (drop.tipo) {
      case TipoDrop.pedraReforco:
        tipoConsumivel = TipoItemConsumivel.joia;
        raridade = RaridadeConsumivel.lendario;
        break;
      case TipoDrop.pocaoVidaGrande:
        tipoConsumivel = TipoItemConsumivel.pocao;
        raridade = RaridadeConsumivel.epico;
        break;
      case TipoDrop.pocaoVidaPequena:
      default:
        tipoConsumivel = TipoItemConsumivel.pocao;
        raridade = RaridadeConsumivel.comum;
        break;
    }

    return ItemConsumivel(
      id: drop.tipo.id,
      nome: drop.tipo.nome,
      descricao: drop.tipo.descricao,
      tipo: tipoConsumivel,
      iconPath: drop.tipo.imagePath,
      quantidade: drop.quantidade,
      raridade: raridade,
    );
  }

  /// Guarda os DROPS (consumíveis) na mochila comum
  /// Adiciona os drops nos primeiros slots vazios disponíveis
  Future<void> _guardarItensNaMochila(
    String emailJogador,
    Mochila mochilaBase,
    List<ItemConsumivel> novosItens,
    Set<int> slotsParaLiberar, {
    int moedaEvento = 0,
  }) async {
    print('[BatalhaScreen] 📦 Salvando drops na mochila: ${novosItens.length} itens + $moedaEvento moedas para guardar');

    if (novosItens.isEmpty && slotsParaLiberar.isEmpty && moedaEvento == 0) {
      print('[BatalhaScreen] Nenhum drop para salvar');
      return;
    }

    // Inicia com a mochila base
    Mochila mochila = mochilaBase;

    // Adiciona moeda de evento primeiro (slot fixo 3)
    if (moedaEvento > 0) {
      print('[BatalhaScreen] 🪙 Adicionando $moedaEvento moeda(s) de evento à mochila');
      mochila = mochila.adicionarMoedaEvento(moedaEvento);
      print('[BatalhaScreen] ✅ Moeda de evento adicionada! Total: ${mochila.quantidadeMoedaEvento}');
    }

    // Primeiro, libera os slots selecionados
    if (slotsParaLiberar.isNotEmpty) {
      print('[BatalhaScreen] 🗑️ Liberando ${slotsParaLiberar.length} slots');
      final indicesOrdenados = slotsParaLiberar.toList()..sort();
      for (final index in indicesOrdenados.reversed) {
        if (index >= 0 && index < Mochila.totalSlots) {
          mochila = mochila.removerItem(index);
        }
      }
    }

    // Agora adiciona os novos drops nos primeiros slots vazios
    for (final item in novosItens) {
      try {
        print('[BatalhaScreen] 🔄 Adicionando drop à mochila: ${item.nome} (iconPath: ${item.iconPath})');

        final mochilaAtualizada = mochila.adicionarItem(item);

        if (mochilaAtualizada != null) {
          mochila = mochilaAtualizada;
          print('[BatalhaScreen] ✅ Drop ${item.nome} adicionado à mochila!');
        } else {
          print('[BatalhaScreen] ❌ Mochila cheia, não foi possível adicionar ${item.nome}');
        }
      } catch (e, stack) {
        print('[BatalhaScreen] ❌ Erro ao adicionar drop ${item.nome}: $e');
        print(stack);
      }
    }

    // Salva a mochila atualizada
    print('[BatalhaScreen] 💾 Salvando mochila atualizada...');
    await MochilaService.salvarMochila(context, emailJogador, mochila);
    print('[BatalhaScreen] ✅ Mochila salva com sucesso! Slots ocupados: ${mochila.itensOcupados}/${mochila.slotsDesbloqueados}');
  }

  /// Converte um ItemConsumivel de volta para Drop
  /// para poder salvar no DropsService
  Drop _converterItemConsumivelParaDrop(ItemConsumivel item) {
    // Identifica o tipo pelo ID
    final tipo = TipoDrop.values.firstWhere(
      (t) => t.id == item.id,
      orElse: () => TipoDrop.pocaoVidaPequena, // Fallback
    );

    return Drop(tipo: tipo, quantidade: item.quantidade);
  }

  Future<void> _equiparItemEMonstro(
    MonstroAventura monstro,
    Item item,
  ) async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia == null) return;

      final monstrosAtualizados = historia.monstros.map((m) {
        if (m.tipo == monstro.tipo &&
            m.tipoExtra == monstro.tipoExtra &&
            m.imagem == monstro.imagem) {
          return m.copyWith(itemEquipado: item);
        }
        return m;
      }).toList();

      final historiaAtualizada = historia.copyWith(monstros: monstrosAtualizados);
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      print('[BatalhaScreen] Item ${item.nome} equipado em ${monstro.tipo.monsterName}');
    } catch (e) {
      print('[BatalhaScreen] Erro ao equipar item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao equipar item: $e')),
        );
      }
    }
  }

  Future<void> _equiparMagiaEMonstro(
    MonstroAventura monstro,
    MagiaDrop magia,
    Habilidade habilidadeSubstituida,
  ) async {
    try {
      final descricaoAtualizada = magia.descricao.replaceAll(
        'TIPO_ELEMENTAL',
        monstro.tipo.name.toUpperCase(),
      );

      final novaHabilidade = Habilidade(
        nome: magia.nome,
        descricao: descricaoAtualizada,
        tipo: magia.tipo,
        efeito: magia.efeito,
        tipoElemental: monstro.tipo,
        valor: magia.valor,
        custoEnergia: magia.custoEnergia,
        level: magia.level,
      );

      final novasHabilidades = monstro.habilidades
          .map(
            (habilidade) =>
                habilidade == habilidadeSubstituida ? novaHabilidade : habilidade,
          )
          .toList();

      final monstroAtualizado = monstro.copyWith(habilidades: novasHabilidades);

      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia == null) return;

      final monstrosAtualizados = historia.monstros.map((m) {
        if (m.tipo == monstro.tipo && m.tipoExtra == monstro.tipoExtra) {
          return monstroAtualizado;
        }
        return m;
      }).toList();

      final historiaAtualizada = historia.copyWith(monstros: monstrosAtualizados);
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

      print('[BatalhaScreen] Magia ${magia.nome} equipada em ${monstro.tipo.monsterName}');
    } catch (e) {
      print('[BatalhaScreen] Erro ao equipar magia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao equipar magia: $e')),
        );
      }
    }
  }
  /// Finaliza a batalha salvando tudo e mostrando o botão para voltar
  Future<void> _finalizarBatalhaComSalvamento() async {
    print('?? [BatalhaScreen] Finalizando batalha e salvando resultado final...');

    // Registra kill no progresso diário se jogador venceu
    if (vencedor == 'jogador') {
      await _registrarKillNoProgresso();
    }

    await _salvarResultadoLocal();
    print('? [BatalhaScreen] Resultado final salvo com sucesso!');

    // Mostra botão para voltar manualmente (jogador pode ler o histórico antes)
    print('?? [BatalhaScreen] Ativando botão "Voltar para Aventura"');
    if (mounted) {
      setState(() {
        processandoVitoria = false; // Desativa o loading
        podeVoltarParaAventura = true;
      });
    }
  }

  Future<void> _registrarKillNoProgresso() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Carrega progresso atual
      final progressoJson = prefs.getString('progresso_diario');
      ProgressoDiario progresso;

      if (progressoJson != null) {
        final progressoData = jsonDecode(progressoJson) as Map<String, dynamic>;
        final progressoSalvo = ProgressoDiario.fromJson(progressoData);

        // Se é de outro dia, cria novo
        if (progressoSalvo.data != hoje) {
          progresso = ProgressoDiario(data: hoje);
        } else {
          progresso = progressoSalvo;
        }
      } else {
        progresso = ProgressoDiario(data: hoje);
      }

      // Registra kill do tipo principal do inimigo
      final tipoInimigo = widget.inimigo.tipo;
      progresso = progresso.adicionarKill(tipoInimigo);

      // Salva de volta
      final novoProgressoJson = jsonEncode(progresso.toJson());
      await prefs.setString('progresso_diario', novoProgressoJson);

      // Recarrega os bônus no provider para refletir imediatamente nos monstros
      await ref.read(progressoBonusStateProvider.notifier).reload();

      print('✅ [Progresso] Kill registrado para tipo ${tipoInimigo.name} (total: ${progresso.killsPorTipo[tipoInimigo.name]})');
    } catch (e) {
      print('❌ [Progresso] Erro ao registrar kill: $e');
    }
  }

  Future<void> _salvarResultadoLocal() async {
    if (salvandoResultado || estadoAtual == null) return;
    
    if (mounted) {
      setState(() {
        salvandoResultado = true;
      });
    }
    
    try {
      print('?? [BatalhaScreen] SAVE FIRST: Salvando resultado no Drive...');
      
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      
      // Carrega a história atual
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia == null) {
        throw Exception('História do jogador não encontrada');
      }
      
      // Sempre atualiza a vida atual do monstro do jogador, independente de quem venceu
      print('?? [DEBUG] Procurando monstro do jogador para atualizar:');
      print('  - Tipo: ${widget.jogador.tipo}');
      print('  - TipoExtra: ${widget.jogador.tipoExtra}');
      print('  - Vida atual no estado: ${estadoAtual!.vidaAtualJogador}');
      
      final monstrosAtualizados = historia.monstros.map((m) {
        print('  - Comparando com monstro: ${m.tipo} / ${m.tipoExtra} (vida atual: ${m.vidaAtual})');
        if (m.tipo == widget.jogador.tipo && m.tipoExtra == widget.jogador.tipoExtra) {
          // Calcula vida máxima do jogador com item para limitar corretamente
          final vidaMaximaComItem = m.vida + (m.itemEquipado?.vida ?? 0);
          final vidaFinal = estadoAtual!.vidaAtualJogador <= 0 ? 0 : estadoAtual!.vidaAtualJogador.clamp(0, vidaMaximaComItem);
          // Também limita a energia atual ao valor máximo base do monstro (sem item)
          final energiaFinal = estadoAtual!.energiaAtualJogador.clamp(0, m.energia);
          print('  ? MATCH! Atualizando vida de ${m.vidaAtual} para $vidaFinal (original: ${estadoAtual!.vidaAtualJogador})');
          print('  ? MATCH! Atualizando energia para $energiaFinal (original: ${estadoAtual!.energiaAtualJogador}, max base: ${m.energia})');
          
          return m.copyWith(
            vidaAtual: vidaFinal,
            energiaAtual: energiaFinal,
          );
        }
        return m;
      }).toList();
      
      // Atualiza a vida atual dos monstros inimigos
      final inimigosAtualizados = historia.monstrosInimigos.map((m) {
        if (m.tipo == widget.inimigo.tipo && 
            m.tipoExtra == widget.inimigo.tipoExtra) {
          // Limita a vida final ao valor máximo com item (valores fixos do JSON)
          final vidaFinal = estadoAtual!.vidaAtualInimigo <= 0 ? 0 : estadoAtual!.vidaAtualInimigo.clamp(0, m.vidaTotal);
          print('?? [DEBUG] Inimigo ${m.tipo.monsterName}: vida ${estadoAtual!.vidaAtualInimigo} ? salva como $vidaFinal');
          
          return m.copyWith(
            vidaAtual: vidaFinal,
          );
        }
        return m;
      }).toList();
      
      // Atualiza a história com os monstros modificados
      final historiaAtualizada = historia.copyWith(
        monstros: monstrosAtualizados,
        monstrosInimigos: inimigosAtualizados,
      );
      
      // Salva a história atualizada
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
      
      print('? [BatalhaScreen] Resultado salvo com sucesso!');
      
    } catch (e) {

      print('? [BatalhaScreen] Erro ao salvar resultado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar resultado: $e')),
        );
      }
    } finally {
      // Sempre reseta o estado de salvamento, independente de sucesso ou erro
      if (mounted) {
        setState(() {
          salvandoResultado = false;
        });
      }
    }
  }

  // Stub para ataque básico
  Future<EstadoBatalha> _executarAtaqueBasico(EstadoBatalha estado, bool isJogador) async {
    // Define variáveis usadas
    int ataqueAtual = isJogador ? estado.ataqueAtualJogador : estado.ataqueAtualInimigo;
    int defesaAlvo = isJogador ? estado.defesaAtualInimigo : estado.defesaAtualJogador;
    int vidaAntes = isJogador ? estado.vidaAtualInimigo : estado.vidaAtualJogador;
    int vidaMaximaDefensor = isJogador ? estado.inimigo.vida : estado.jogador.vida;
    String atacanteNome = isJogador ? estado.jogador.tipo.monsterName : estado.inimigo.tipo.monsterName;

    final danoCalculado = (ataqueAtual - defesaAlvo).clamp(1, ataqueAtual);
    final vidaDepois = vidaAntes - danoCalculado; // Permite vida negativa

    // Cria ação no histórico
    final energiaRestaurada = isJogador
        ? (estado.jogador.energia * 0.1).round()
        : (estado.inimigo.energia * 0.1).round();
    final acao = AcaoBatalha(
      atacante: atacanteNome,
      habilidadeNome: 'Ataque Básico',
      danoBase: ataqueAtual,
      danoTotal: danoCalculado,
      defesaAlvo: defesaAlvo,
      vidaAntes: vidaAntes,
      vidaDepois: vidaDepois,
      descricao: '$atacanteNome usou Ataque Básico[${isJogador ? widget.jogador.tipo.displayName : widget.inimigo.tipo.displayName}] por falta de energia! Causou $danoCalculado de dano e restaurou $energiaRestaurada de energia.',
    );

    // Restaura 10% da energia máxima do atacante (com item durante batalha)
    if (isJogador) {
      final energiaRestaurada = (estado.energiaMaximaJogador * 0.1).round();
      final novaEnergia = (estado.energiaAtualJogador + energiaRestaurada).clamp(0, estado.energiaMaximaJogador);
      return estado.copyWith(
        vidaAtualInimigo: vidaDepois,
        energiaAtualJogador: novaEnergia,
        historicoAcoes: [...estado.historicoAcoes, acao],
      );
    } else {
      final energiaRestaurada = (estado.energiaMaximaInimigo * 0.1).round();
      final novaEnergia = (estado.energiaAtualInimigo + energiaRestaurada).clamp(0, estado.energiaMaximaInimigo);
      return estado.copyWith(
        vidaAtualJogador: vidaDepois,
        energiaAtualInimigo: novaEnergia,
        historicoAcoes: [...estado.historicoAcoes, acao],
      );
    }
  }

  Future<void> _salvarEstadoBatalha() async {
    if (estadoAtual == null) return;
    
    // Durante batalha automática, não salva o estado a cada rodada
    if (batalhaAutomatica) {
      print('? [Auto Battle] Pulando salvamento durante batalha automática');
      return;
    }
    
    try {
      print('?? [BatalhaScreen] Salvando estado da batalha...');
      
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      
      // Carrega a história atual
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia == null) {
        throw Exception('História do jogador não encontrada');
      }
      
      // Atualiza a vida atual do jogador na história
      final monstrosAtualizados = historia.monstros.map((m) {
        if (m.tipo == widget.jogador.tipo && m.tipoExtra == widget.jogador.tipoExtra) {
          // Calcula vida máxima do jogador com item para limitar corretamente
          final vidaMaximaComItem = m.vida + (m.itemEquipado?.vida ?? 0);
          final vidaFinalJogador = estadoAtual!.vidaAtualJogador.clamp(0, vidaMaximaComItem);
          return m.copyWith(vidaAtual: vidaFinalJogador);
        }
        return m;
      }).toList();
      
      // Atualiza a vida atual dos inimigos na história  
      final inimigosAtualizados = historia.monstrosInimigos.map((m) {
        if (m.tipo == widget.inimigo.tipo && 
            m.tipoExtra == widget.inimigo.tipoExtra) {
          // Limita a vida final ao valor máximo com item (valores fixos do JSON)
          final vidaFinalInimigo = estadoAtual!.vidaAtualInimigo.clamp(0, m.vidaTotal);
          return m.copyWith(vidaAtual: vidaFinalInimigo);
        }
        return m;
      }).toList();
      
      // Salva a história atualizada com a vida atual de todos
      final historiaAtualizada = historia.copyWith(
        monstros: monstrosAtualizados,
        monstrosInimigos: inimigosAtualizados,
      );
      await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
      
      print('? [BatalhaScreen] Estado da batalha salvo!');
      
    } catch (e) {
      print('? [BatalhaScreen] Erro ao salvar estado: $e');
      // Não mostra erro na UI para não atrapalhar a batalha
    }
  }

  // ========================================
  // ?? MODAL DE DETALHAMENTO DE MONSTRO
  // ========================================
  
  void _mostrarDetalheMonstro(dynamic monstro, bool isJogador) {
    // Para monstros inimigos, usa o modal específico sem conversão
    if (!isJogador && monstro is MonstroInimigo) {
      showDialog(
        context: context,
        builder: (context) => ModalMonstroInimigo(monstro: monstro),
      );
      return;
    }
    
    // Converte MonstroInimigo para MonstroAventura se necessário
    MonstroAventura monstroAventura;
    if (monstro is MonstroAventura) {
      // ...aplica bônus do item...
      final item = monstro.itemEquipado;
      int ataque = monstro.ataque + (item?.ataque ?? 0);
      int defesa = monstro.defesa + (item?.defesa ?? 0);
      int agilidade = monstro.agilidade + (item?.agilidade ?? 0);
      int vida = monstro.vida + (item?.vida ?? 0);
      int energia = monstro.energia + (item?.energia ?? 0);
      monstroAventura = monstro.copyWith(
        ataque: ataque,
        defesa: defesa,
        agilidade: agilidade,
        vida: vida,
        energia: energia,
      );
    } else {
      // Converte MonstroInimigo para MonstroAventura
      // Adiciona logs para inspecionar dados
      debugPrint('?? [BatalhaScreen] Abrindo modal de monstro inimigo. Dados recebidos:');
      debugPrint('tipo: ${monstro.tipo}');
      debugPrint('tipoExtra: ${monstro.tipoExtra}');
      debugPrint('imagem: ${monstro.imagem}');
      // Garante que tipo e tipoExtra nunca sejam nulos
      final tipoSeguro = monstro.tipo ?? Tipo.values.first;
      final tipoExtraSeguro = monstro.tipoExtra ?? Tipo.values.first;
      monstroAventura = MonstroAventura(
        tipo: tipoSeguro,
        tipoExtra: tipoExtraSeguro,
        vida: monstro.vida,
        vidaAtual: isJogador ? estadoAtual?.vidaAtualJogador ?? monstro.vida : estadoAtual?.vidaAtualInimigo ?? monstro.vida,
        energia: monstro.energia,
        energiaAtual: monstro.energiaAtual,
        ataque: monstro.ataque,
        defesa: monstro.defesa,
        agilidade: monstro.agilidade,
        habilidades: monstro.habilidades,
        imagem: monstro.imagem,
        itemEquipado: monstro.itemEquipado,
      );
    }
    // Obtém os valores atuais do estado da batalha
    final ataqueAtual = isJogador ? estadoAtual?.ataqueAtualJogador : estadoAtual?.ataqueAtualInimigo;
    final defesaAtual = isJogador ? estadoAtual?.defesaAtualJogador : estadoAtual?.defesaAtualInimigo;
    final energiaAtual = isJogador ? estadoAtual?.energiaAtualJogador : estadoAtual?.energiaAtualInimigo;
    final energiaMaximaAtual = isJogador ? estadoAtual?.energiaMaximaJogador : estadoAtual?.energiaMaximaInimigo;
    final vidaMaximaAtual = isJogador ? estadoAtual?.vidaMaximaJogador : estadoAtual?.vidaMaximaInimigo;
    // Exibe detalhes do monstro (apenas uma vez)
    showDialog(
      context: context,
      builder: (context) => ModalMonstroAventura(
        monstro: monstroAventura,
        isBatalha: true,
        ataqueAtual: ataqueAtual,
        defesaAtual: defesaAtual,
        energiaAtual: energiaAtual,
        energiaMaximaAtual: energiaMaximaAtual,
        vidaMaximaAtual: vidaMaximaAtual,
      ),
    );
  }

  // ========================================
  // ?? SISTEMA DE EFETIVIDADE DE TIPOS
  // ========================================
  
  /// Calcula a efetividade do tipo atacante contra o tipo defensor usando as tabelas JSON
  Future<double> _calcularEfetividade(Tipo tipoAtacante, Tipo tipoDefensor) async {
    try {
      // CORRETO: Carrega a tabela de DEFESA do tipo DEFENSOR (quem recebe o ataque)
      final tabelaDefesa = await _tipagemRepository.carregarDadosTipo(tipoDefensor);
      
      if (tabelaDefesa != null && tabelaDefesa.containsKey(tipoAtacante)) {
        // O valor na tabela indica quanto de dano o defensor recebe do atacante
        final multiplicadorDano = tabelaDefesa[tipoAtacante]!;
        print('?? [Efetividade] ${tipoDefensor.displayName} recebe ${multiplicadorDano}x dano de ${tipoAtacante.displayName}');
        return multiplicadorDano;
      }
      
      // Se não encontrar na tabela, retorna efetividade normal
      print('?? [Efetividade] Não encontrada defesa de ${tipoDefensor.name} vs ${tipoAtacante.name}, usando 1.0x');
      return 1.0;
    } catch (e) {
      print('? [Efetividade] Erro ao calcular: $e');
      return 1.0; // Fallback para efetividade normal
    }
  }
  
  /// Obtém o texto descritivo da efetividade
  String _obterTextoEfetividade(double efetividade) {
    if (efetividade == 0.0) return '(Imune)';
    if (efetividade < 0.5) return '(Muito Resistente)';
    if (efetividade < 1.0) return '(Resistente)';
    if (efetividade == 1.0) return '(Normal)';
    if (efetividade < 1.5) return '(Fraco)';
    if (efetividade < 2.0) return '(Muito Fraco)';
    if (efetividade < 2.5) return '(Extremamente Fraco)';
    if (efetividade < 3.0) return '(Devastador)';
    if (efetividade < 3.5) return '(Fraqueza Extrema)';
    if (efetividade < 4.0) return '(Vulnerabilidade Total)';
    if (efetividade < 4.5) return '(Resistência Nula)';
    if (efetividade < 5.0) return '(Defesa de Papel)';
    return '(Insignificante)';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Bloqueia o botão de voltar do sistema enquanto a batalha não terminou
        return batalhaConcluida;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        appBar: AppBar(
          backgroundColor: Colors.blueGrey.shade900,
          title: Text('Batalha - Turno $turnoAtual'),
          centerTitle: true,
          elevation: 2,
          automaticallyImplyLeading: false, // Remove seta de voltar
        ),
        body: Stack(
          children: [
            // Conteúdo principal da tela
            estadoAtual == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusMonstros(),
                    const SizedBox(height: 20),
                    if (!batalhaConcluida)
                      _buildBotoesAcao(),
                    const SizedBox(height: 20),
                    if (batalhaConcluida)
                      _buildResultadoFinal()
                    else if (mostrandoAcao)
                      _buildAcaoEmAndamento()
                    else if (aguardandoContinuar)
                      _buildUltimaAcao()
                    else
                      _buildProximaAcao(),
                    const SizedBox(height: 20),
                    if (estadoAtual!.historicoAcoes.isNotEmpty)
                      _buildHistoricoBatalha(),
                    if (salvandoResultado)
                      _buildIndicadorSalvamento(),
                  ],
                ),
              ),
            // Overlay de loading durante processamento da vitória
            if (processandoVitoria)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        strokeWidth: 4,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processando batalha...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            // Overlay de loading durante processamento da derrota
            if (processandoDerrota)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        strokeWidth: 4,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processando batalha...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        // Remove bottomNavigationBar de voltar
        bottomNavigationBar: null,
      ),
    );
  }

  Widget _buildStatusMonstros() {
    return Row(
      children: [
        // Jogador
        Expanded(
          child: _buildStatusMonstro(
            nome: widget.jogador.tipo.monsterName,
            imagem: widget.jogador.imagem,
            vidaAtual: estadoAtual!.vidaAtualJogador,
            vidaMaxima: estadoAtual!.vidaMaximaJogador, // Usa vida máxima com buffs
            energiaAtual: estadoAtual!.energiaAtualJogador,
            energiaMaxima: estadoAtual!.energiaMaximaJogador, // Usa energia máxima com buffs
            cor: Colors.blue,
            isJogador: true,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Versus
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.purple,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.flash_on,
                color: Colors.purple,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Inimigo
        Expanded(
          child: _buildStatusMonstro(
            nome: widget.inimigo.tipo.monsterName,
            imagem: widget.inimigo.imagem,
            vidaAtual: estadoAtual!.vidaAtualInimigo,
            vidaMaxima: estadoAtual!.vidaMaximaInimigo, // Usa vida máxima com buffs
            energiaAtual: estadoAtual!.energiaAtualInimigo,
            energiaMaxima: estadoAtual!.energiaMaximaInimigo, // Usa energia máxima com buffs
            cor: Colors.red,
            isJogador: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMonstro({
    required String nome,
    required String imagem,
    required int vidaAtual,
    required int vidaMaxima,
    required int energiaAtual,
    required int energiaMaxima,
    required Color cor,
    required bool isJogador,
  }) {
    // Se vida negativa, mostra 0 visualmente
    double percentualVida = vidaAtual <= 0 ? 0.0 : (vidaAtual / vidaMaxima);
    double percentualEnergia = energiaAtual / energiaMaxima;
    
    return GestureDetector(
      onTap: () => _mostrarDetalheMonstro(
        isJogador ? widget.jogador : widget.inimigo,
        isJogador,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        children: [
          // Imagem
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(imagem),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Nome
          Text(
            nome,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Barra de vida
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentualVida,
              child: Container(
                decoration: BoxDecoration(
                  color: percentualVida > 0.5 
                      ? Colors.green 
                      : percentualVida > 0.25 
                          ? Colors.orange 
                          : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 2),
          
          // Vida numérica - mostra 0 se negativo, ou "MORTO" se completamente morto
          Text(
            vidaAtual <= 0 ? '0/$vidaMaxima' : '$vidaAtual/$vidaMaxima',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: vidaAtual <= 0 ? Colors.red : null,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Barra de energia
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentualEnergia,
              child: Container(
                decoration: BoxDecoration(
                  color: percentualEnergia > 0.5 
                      ? Colors.blue 
                      : percentualEnergia > 0.25 
                          ? Colors.orange 
                          : Colors.red,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 2),
          
          // Energia numérica
          Text(
            'E: $energiaAtual/$energiaMaxima',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildResultadoFinal() {
    final venceuBatalha = vencedor == 'jogador';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: venceuBatalha ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: venceuBatalha ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            venceuBatalha ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 48,
            color: venceuBatalha ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(height: 8),
          Text(
            venceuBatalha ? 'VITÓRIA!' : 'DERROTA!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: venceuBatalha ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (podeVoltarParaAventura)
            ElevatedButton.icon(
              onPressed: () {
                print('[BatalhaScreen] 🏠 Voltando para aventura...');
                // Sai da batalha, voltando para a seleção de monstro
                // que por sua vez volta automaticamente para a aventura
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true); // Retorna true para indicar que terminou
                }
              },
              icon: Icon(Icons.arrow_back),
              label: Text('Voltar para Aventura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: venceuBatalha ? Colors.green.shade600 : Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            Text(
              venceuBatalha 
                ? 'Processando batalha...'
                : 'Batalha finalizada!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildAcaoEmAndamento() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Executando rodada completa...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimaAcao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 32),
          const SizedBox(height: 8),
          Text(
            ultimaAcao ?? 'Ação executada',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProximaAcao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        'Clique em "Atacar" para executar uma rodada completa!\n(Ambos atacarão seguindo a ordem da agilidade)',
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHistoricoBatalha() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico da Batalha',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...estadoAtual!.historicoAcoes.reversed.toList().asMap().entries.map((entry) {
            final index = estadoAtual!.historicoAcoes.length - entry.key;
            final acao = entry.value;
            final isJogadorAcao = acao.atacante == widget.jogador.tipo.monsterName;
            return _buildAcaoItem(index, acao, isJogadorAcao);
          }),
        ],
      ),
    );
  }

  Widget _buildAcaoItem(int turno, AcaoBatalha acao, bool isJogadorAcao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Imagem do monstro ou ícone de cura da coleção
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: AssetImage(
                  acao.atacante == 'Coleção Nostálgica'
                      ? 'assets/icons_gerais/magia_cura.png'
                      : (isJogadorAcao ? widget.jogador.imagem : widget.inimigo.imagem),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Número do turno
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$turno',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Descrição
          Expanded(
            child: Text(
              acao.descricao,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Column(
      children: [
        if (!batalhaAutomatica) ...[
          // Botões de ação lado a lado - sempre visíveis durante a batalha
          Row(
            children: [
              // Botão Próxima Rodada
              Expanded(
                child: ElevatedButton(
                  onPressed: mostrandoAcao ? null : (aguardandoContinuar ? _continuarBatalha : _executarRodadaCompleta),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: aguardandoContinuar ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    aguardandoContinuar ? '?? Continuar' : '?? Próxima Rodada',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botão Auto Batalha
              Expanded(
                child: ElevatedButton(
                  onPressed: mostrandoAcao ? null : _resumirBatalha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '? Auto Batalha',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (batalhaAutomatica) ...[
          // Indicador de batalha automática em progresso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                Text(
                  'Executando batalha automática...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIndicadorSalvamento() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Salvando resultado no Drive...'),
        ],
      ),
    );
  }

  // ==========================================

}








