import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/batalha.dart';
import '../models/habilidade.dart';
import '../models/item.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../tipagem/data/tipagem_repository.dart';
import '../services/item_service.dart';
import 'modal_monstro_aventura.dart';
import 'modal_item_obtido.dart';

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
  bool jogadorComeca = true;
  bool itemGerado = false;
  int turnoAtual = 1;
  bool vezDoJogador = true;
  String? ultimaAcao;
  String? vencedor;
  
  // Animações e UI
  bool mostrandoAcao = false;
  bool aguardandoContinuar = false;

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
      print('⚠️ [Batalha] Sistema de tipagem não inicializado, usando valores padrão');
    } else {
      print('✅ [Batalha] Sistema de tipagem inicializado e pronto');
    }
  }

  void _inicializarBatalha() {
    print('🗡️ [BatalhaScreen] Inicializando batalha...');
    
    // Determina quem começa baseado na agilidade
    jogadorComeca = widget.jogador.agilidade >= widget.inimigo.agilidade;
    vezDoJogador = true; // Sempre inicia esperando ação do jogador (rodada completa)
    
    // Estado inicial da batalha
    estadoAtual = EstadoBatalha(
      jogador: widget.jogador,
      inimigo: widget.inimigo,
      vidaAtualJogador: widget.jogador.vidaAtual, // Usa vida atual, não máxima
      vidaAtualInimigo: widget.inimigo.vidaAtual, // Usa vida atual, não máxima
      vidaMaximaJogador: widget.jogador.vida, // Vida máxima inicial
      vidaMaximaInimigo: widget.inimigo.vida, // Vida máxima inicial
      energiaAtualJogador: widget.jogador.energiaAtual, // Energia atual do jogador
      energiaAtualInimigo: widget.inimigo.energiaAtual, // Energia atual do inimigo
      ataqueAtualJogador: widget.jogador.ataque,
      defesaAtualJogador: widget.jogador.defesa,
      ataqueAtualInimigo: widget.inimigo.ataque,
      defesaAtualInimigo: widget.inimigo.defesa,
      habilidadesUsadasJogador: [],
      habilidadesUsadasInimigo: [],
      historicoAcoes: [],
    );
    
    print('🏃 [Batalha] ${jogadorComeca ? "Jogador" : "Inimigo"} começa a rodada');
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
  
  Future<void> _executarRodadaCompletatAsync() async {
    if (estadoAtual == null || batalhaConcluida) return;
    
    // Determina ordem dos ataques baseada na agilidade
    bool jogadorPrimeiro = widget.jogador.agilidade >= widget.inimigo.agilidade;
    
    print('🎯 [Rodada] Iniciando rodada completa - ${jogadorPrimeiro ? "Jogador" : "Inimigo"} ataca primeiro');
    
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
      print('⚠️ [Jogador] Sem energia para habilidades - usando ataque básico');
      // Executa ataque básico quando não tem energia para habilidades
      return await _executarAtaqueBasico(estado, true); // true = é jogador
    }
    
    final habilidade = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    print('⚔️ [Jogador] Usando ${habilidade.nome} (custo: ${habilidade.custoEnergia})');
    
    // Aplica habilidade e desconta energia
    var novoEstado = await _aplicarHabilidade(estado, habilidade, true);
    
    // Desconta energia
    novoEstado = novoEstado.copyWith(
      energiaAtualJogador: (estado.energiaAtualJogador - habilidade.custoEnergia).clamp(0, widget.jogador.energia)
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
      print('⚠️ [Inimigo] Sem energia para habilidades - usando ataque básico');
      // Executa ataque básico quando não tem energia para habilidades
      return await _executarAtaqueBasico(estado, false); // false = é inimigo
    }
    
    final habilidade = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    print('⚔️ [Inimigo] Usando ${habilidade.nome} (custo: ${habilidade.custoEnergia})');
    
    // Aplica habilidade e desconta energia
    var novoEstado = await _aplicarHabilidade(estado, habilidade, false);
    
    // Desconta energia
    novoEstado = novoEstado.copyWith(
      energiaAtualInimigo: (estado.energiaAtualInimigo - habilidade.custoEnergia).clamp(0, widget.inimigo.energia)
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
      resumoRodada += 'Vida atual: Jogador ${estadoFinal.vidaAtualJogador}/${widget.jogador.vida} | Inimigo ${estadoFinal.vidaAtualInimigo}/${widget.inimigo.vida}\n';
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
          int curaReal = novaVida - vidaAntes;
          descricao = '$atacante curou $curaReal de vida (${vidaAntes}→${novaVida}) usando ${habilidade.nome}';
        } else {
          int vidaAntes = estado.vidaAtualInimigo;
          int novaVida = (estado.vidaAtualInimigo + habilidade.valor).clamp(0, estado.inimigo.vida);
          novoEstado = estado.copyWith(vidaAtualInimigo: novaVida);
          int curaReal = novaVida - vidaAntes;
          descricao = '$atacante curou $curaReal de vida (${vidaAntes}→${novaVida}) usando ${habilidade.nome}';
        }
        break;
        
      case EfeitoHabilidade.aumentarAtaque:
        if (isJogador) {
          int ataqueAntes = estado.ataqueAtualJogador;
          int novoAtaque = estado.ataqueAtualJogador + habilidade.valor;
          novoEstado = estado.copyWith(ataqueAtualJogador: novoAtaque);
          descricao = '$atacante aumentou o ataque de $ataqueAntes para $novoAtaque (+${habilidade.valor}) usando ${habilidade.nome}';
        } else {
          int ataqueAntes = estado.ataqueAtualInimigo;
          int novoAtaque = estado.ataqueAtualInimigo + habilidade.valor;
          novoEstado = estado.copyWith(ataqueAtualInimigo: novoAtaque);
          descricao = '$atacante aumentou o ataque de $ataqueAntes para $novoAtaque (+${habilidade.valor}) usando ${habilidade.nome}';
        }
        break;
        
      case EfeitoHabilidade.aumentarDefesa:
        if (isJogador) {
          int defesaAntes = estado.defesaAtualJogador;
          int novaDefesa = estado.defesaAtualJogador + habilidade.valor;
          novoEstado = estado.copyWith(defesaAtualJogador: novaDefesa);
          descricao = '$atacante aumentou a defesa de $defesaAntes para $novaDefesa (+${habilidade.valor}) usando ${habilidade.nome}';
        } else {
          int defesaAntes = estado.defesaAtualInimigo;
          int novaDefesa = estado.defesaAtualInimigo + habilidade.valor;
          novoEstado = estado.copyWith(defesaAtualInimigo: novaDefesa);
          descricao = '$atacante aumentou a defesa de $defesaAntes para $novaDefesa (+${habilidade.valor}) usando ${habilidade.nome}';
        }
        break;
        
      case EfeitoHabilidade.aumentarVida:
        if (isJogador) {
          // Aumenta vida máxima e vida atual proporcionalmente
          int vidaMaximaAntes = estado.vidaMaximaJogador;
          int vidaAtualAntes = estado.vidaAtualJogador;
          int novaVidaMaxima = vidaMaximaAntes + habilidade.valor;
          int novaVidaAtual = vidaAtualAntes + habilidade.valor; // Aumenta a atual também
          
          novoEstado = estado.copyWith(
            vidaMaximaJogador: novaVidaMaxima,
            vidaAtualJogador: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima de $vidaMaximaAntes para $novaVidaMaxima (+${habilidade.valor}) e vida atual para $novaVidaAtual usando ${habilidade.nome}';
        } else {
          // Aumenta vida máxima e vida atual proporcionalmente
          int vidaMaximaAntes = estado.vidaMaximaInimigo;
          int vidaAtualAntes = estado.vidaAtualInimigo;
          int novaVidaMaxima = vidaMaximaAntes + habilidade.valor;
          int novaVidaAtual = vidaAtualAntes + habilidade.valor; // Aumenta a atual também
          
          novoEstado = estado.copyWith(
            vidaMaximaInimigo: novaVidaMaxima,
            vidaAtualInimigo: novaVidaAtual,
          );
          descricao = '$atacante aumentou a vida máxima de $vidaMaximaAntes para $novaVidaMaxima (+${habilidade.valor}) e vida atual para $novaVidaAtual usando ${habilidade.nome}';
        }
        break;
        
      case EfeitoHabilidade.aumentarEnergia:
        // Por enquanto só mostra o uso, energia não é usada em batalha
        descricao = '$atacante aumentou a energia em ${habilidade.valor} pontos usando ${habilidade.nome}';
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
    
    return novoEstado;
  }

  Future<EstadoBatalha> _aplicarHabilidadeDano(EstadoBatalha estado, Habilidade habilidade, bool isJogador) async {
    String atacante = isJogador ? estado.jogador.tipo.displayName : estado.inimigo.tipo.displayName;
    
    // Determina tipos do atacante e defensor
    Tipo tipoAtacante = isJogador ? estado.jogador.tipo : estado.inimigo.tipo;
    Tipo tipoDefensor = isJogador ? estado.inimigo.tipo : estado.jogador.tipo; // Considera apenas o primeiro tipo para receber dano
    
    // Calcula dano base
    int ataqueAtacante = isJogador ? estado.ataqueAtualJogador : estado.ataqueAtualInimigo;
    int defesaAlvo = isJogador ? estado.defesaAtualInimigo : estado.defesaAtualJogador;
    
    int danoBase = habilidade.valor;
    int danoComAtaque = danoBase + ataqueAtacante;
    
    // Calcula efetividade de tipo
    double efetividade = await _calcularEfetividade(tipoAtacante, tipoDefensor);
    
    // Aplica efetividade ao dano
    int danoComTipo = (danoComAtaque * efetividade).round();
    int danoFinal = (danoComTipo - defesaAlvo).clamp(1, danoComTipo); // Mínimo 1 de dano
    
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
    
    // Cria descrição detalhada com informações de tipo
    String efetividadeTexto = _obterTextoEfetividade(efetividade);
    String descricao = '$atacante (${tipoAtacante.displayName}) usou ${habilidade.nome}: $danoBase (+$ataqueAtacante ataque) x${efetividade.toStringAsFixed(1)} $efetividadeTexto - $defesaAlvo defesa = $danoFinal de dano. Vida: $vidaAntes→$vidaDepois';
    
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
    setState(() {
      batalhaConcluida = true;
      vencedor = vencedorBatalha;
    });
    
    // Se o jogador venceu, gerar item
    if (vencedorBatalha == 'jogador') {
      _gerarEMostrarItem();
    } else {
      // Se perdeu, apenas salva e volta
      _salvarResultadoNoDrive().then((_) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      });
    }
  }

  Future<void> _gerarEMostrarItem() async {
    if (itemGerado) return;
    itemGerado = true;
    try {
      // Gera um item aleatório
      final itemService = ItemService();
      final itemObtido = itemService.gerarItemAleatorio();
      print('🎁 [BatalhaScreen] Item gerado: ${itemObtido.nome} (${itemObtido.raridade.name})');
      // Carrega os monstros do jogador para seleção
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia == null || historia.monstros.isEmpty) {
        throw Exception('Nenhum monstro encontrado para equipar item');
      }
      // Mostra modal de seleção de item
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ModalItemObtido(
            item: itemObtido,
            monstrosDisponiveis: historia.monstros,
            onEquiparItem: (monstro, item) async {
              await _equiparItemEMonstro(monstro, item);
              Navigator.of(context).pop();
            },
          ),
        );
      }
      // Após equipar item, salva tudo e volta ao mapa
      _salvarResultadoNoDrive().then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      });
    } catch (e) {
      print('❌ [BatalhaScreen] Erro ao gerar item: $e');
      // Em caso de erro, apenas salva e volta
      _salvarResultadoNoDrive().then((_) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      });
    }
  }

  Future<void> _equiparItemEMonstro(MonstroAventura monstro, Item item) async {
    try {
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      // Carrega história atual
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia == null) return;
      // Atualiza o monstro com o item equipado
      final monstrosAtualizados = historia.monstros.map((m) {
        if (m.tipo == monstro.tipo && m.tipoExtra == monstro.tipoExtra) {
          return m.copyWith(itemEquipado: item);
        }
        return m;
      }).toList();
      // Salva a história com o item equipado imediatamente
      final historiaAtualizada = historia.copyWith(monstros: monstrosAtualizados);
      await repository.salvarHistoricoJogador(historiaAtualizada);
      print('✅ [BatalhaScreen] Item equipado e salvo no histórico em ${monstro.tipo.displayName}!');
    } catch (e) {
      print('❌ [BatalhaScreen] Erro ao equipar item: $e');
    }
  }

  Future<void> _salvarResultadoNoDrive() async {
    if (salvandoResultado || estadoAtual == null) return;
    
    setState(() {
      salvandoResultado = true;
    });
    
    try {
      print('💾 [BatalhaScreen] SAVE FIRST: Salvando resultado no Drive...');
      
      final emailJogador = ref.read(validUserEmailProvider);
      final repository = ref.read(aventuraRepositoryProvider);
      
      // Carrega a história atual
      final historia = await repository.carregarHistoricoJogador(emailJogador);
      if (historia == null) {
        throw Exception('História do jogador não encontrada');
      }
      
      // Sempre atualiza a vida atual do monstro do jogador, independente de quem venceu
      print('🔍 [DEBUG] Procurando monstro do jogador para atualizar:');
      print('  - Tipo: ${widget.jogador.tipo}');
      print('  - TipoExtra: ${widget.jogador.tipoExtra}');
      print('  - Vida atual no estado: ${estadoAtual!.vidaAtualJogador}');
      
      final monstrosAtualizados = historia.monstros.map((m) {
        print('  - Comparando com monstro: ${m.tipo} / ${m.tipoExtra} (vida atual: ${m.vidaAtual})');
        if (m.tipo == widget.jogador.tipo && m.tipoExtra == widget.jogador.tipoExtra) {
          print('  ✅ MATCH! Atualizando vida de ${m.vidaAtual} para ${estadoAtual!.vidaAtualJogador}');
          // Atualiza a vida atual do monstro (seja vitória ou derrota)
          return m.copyWith(
            vidaAtual: estadoAtual!.vidaAtualJogador,
          );
        }
        return m;
      }).toList();
      
      // Atualiza a vida atual dos monstros inimigos
      final inimigosAtualizados = historia.monstrosInimigos.map((m) {
        if (m.tipo == widget.inimigo.tipo && 
            m.tipoExtra == widget.inimigo.tipoExtra) {
          // Atualiza a vida atual do inimigo
          return m.copyWith(
            vidaAtual: estadoAtual!.vidaAtualInimigo,
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
      await repository.salvarHistoricoJogador(historiaAtualizada);
      
      print('✅ [BatalhaScreen] Resultado salvo com sucesso!');
      
    } catch (e) {
      print('❌ [BatalhaScreen] Erro ao salvar resultado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar resultado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          salvandoResultado = false;
        });
      }
    }
  }

  // 🗡️ ATAQUE BÁSICO (QUANDO SEM ENERGIA)
  // ========================================
  
  Future<EstadoBatalha> _executarAtaqueBasico(EstadoBatalha estado, bool isJogador) async {
    final atacanteNome = isJogador ? widget.jogador.tipo.displayName : widget.inimigo.tipo.displayName;
    final vidaMaximaDefensor = isJogador ? widget.inimigo.vida : widget.jogador.vida;
    
    // Calcula o ataque básico sem habilidades
    final ataqueAtual = isJogador ? estado.ataqueAtualJogador : estado.ataqueAtualInimigo;
    final defesaAlvo = isJogador ? estado.defesaAtualInimigo : estado.defesaAtualJogador;
    final vidaAntes = isJogador ? estado.vidaAtualInimigo : estado.vidaAtualJogador;
    
    // Cálculo simples de dano: ataque - defesa (mínimo 1)
    final danoCalculado = (ataqueAtual - defesaAlvo).clamp(1, ataqueAtual);
    final vidaDepois = (vidaAntes - danoCalculado).clamp(0, vidaMaximaDefensor);
    
    // Cria ação no histórico
    final acao = AcaoBatalha(
      atacante: atacanteNome,
      habilidadeNome: 'Ataque Básico',
      danoBase: ataqueAtual,
      danoTotal: danoCalculado,
      defesaAlvo: defesaAlvo,
      vidaAntes: vidaAntes,
      vidaDepois: vidaDepois,
      descricao: '$atacanteNome usou Ataque Básico por falta de energia! Causou $danoCalculado de dano.',
    );
    
    // Atualiza estado
    if (isJogador) {
      return estado.copyWith(
        vidaAtualInimigo: vidaDepois,
        historicoAcoes: [...estado.historicoAcoes, acao],
      );
    } else {
      return estado.copyWith(
        vidaAtualJogador: vidaDepois,
        historicoAcoes: [...estado.historicoAcoes, acao],
      );
    }
  }

  Future<void> _salvarEstadoBatalha() async {
    if (estadoAtual == null) return;
    
    try {
      print('💾 [BatalhaScreen] Salvando estado da batalha...');
      
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
          // Atualiza a vida atual do monstro
          return m.copyWith(vidaAtual: estadoAtual!.vidaAtualJogador);
        }
        return m;
      }).toList();
      
      // Atualiza a vida atual dos inimigos na história  
      final inimigosAtualizados = historia.monstrosInimigos.map((m) {
        if (m.tipo == widget.inimigo.tipo && 
            m.tipoExtra == widget.inimigo.tipoExtra) {
          // Atualiza a vida atual do inimigo
          return m.copyWith(vidaAtual: estadoAtual!.vidaAtualInimigo);
        }
        return m;
      }).toList();
      
      // Salva a história atualizada com a vida atual de todos
      final historiaAtualizada = historia.copyWith(
        monstros: monstrosAtualizados,
        monstrosInimigos: inimigosAtualizados,
      );
      await repository.salvarHistoricoJogador(historiaAtualizada);
      
      print('✅ [BatalhaScreen] Estado da batalha salvo!');
      
    } catch (e) {
      print('❌ [BatalhaScreen] Erro ao salvar estado: $e');
      // Não mostra erro na UI para não atrapalhar a batalha
    }
  }

  // ========================================
  // 🔍 MODAL DE DETALHAMENTO DE MONSTRO
  // ========================================
  
  void _mostrarDetalheMonstro(dynamic monstro, bool isJogador) {
    // Converte MonstroInimigo para MonstroAventura se necessário
    MonstroAventura monstroAventura;
    
    if (monstro is MonstroAventura) {
      monstroAventura = monstro;
    } else {
      // Converte MonstroInimigo para MonstroAventura
      monstroAventura = MonstroAventura(
        tipo: monstro.tipo,
        tipoExtra: monstro.tipoExtra,
        vida: monstro.vida,
        vidaAtual: isJogador ? estadoAtual?.vidaAtualJogador ?? monstro.vida : estadoAtual?.vidaAtualInimigo ?? monstro.vida,
        energia: monstro.energia, // Usa energia real do inimigo
        energiaAtual: monstro.energiaAtual, // Usa energia atual real do inimigo
        ataque: monstro.ataque,
        defesa: monstro.defesa,
        agilidade: monstro.agilidade,
        habilidades: monstro.habilidades,
        imagem: monstro.imagem,
        itemEquipado: null, // Sem item para inimigos
      );
    }
    
    // Obtém os valores atuais do estado da batalha
    final ataqueAtual = isJogador ? estadoAtual?.ataqueAtualJogador : estadoAtual?.ataqueAtualInimigo;
    final defesaAtual = isJogador ? estadoAtual?.defesaAtualJogador : estadoAtual?.defesaAtualInimigo;
    final energiaAtual = isJogador ? estadoAtual?.energiaAtualJogador : estadoAtual?.energiaAtualInimigo;
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
        vidaMaximaAtual: vidaMaximaAtual,
      ),
    );
  }

  // ========================================
  // 🎯 SISTEMA DE EFETIVIDADE DE TIPOS
  // ========================================
  
  /// Calcula a efetividade do tipo atacante contra o tipo defensor usando as tabelas JSON
  Future<double> _calcularEfetividade(Tipo tipoAtacante, Tipo tipoDefensor) async {
    try {
      // CORRETO: Carrega a tabela de DEFESA do tipo DEFENSOR (quem recebe o ataque)
      final tabelaDefesa = await _tipagemRepository.carregarDadosTipo(tipoDefensor);
      
      if (tabelaDefesa != null && tabelaDefesa.containsKey(tipoAtacante)) {
        // O valor na tabela indica quanto de dano o defensor recebe do atacante
        final multiplicadorDano = tabelaDefesa[tipoAtacante]!;
        print('🎯 [Efetividade] ${tipoDefensor.name} recebe ${multiplicadorDano}x dano de ${tipoAtacante.name}');
        return multiplicadorDano;
      }
      
      // Se não encontrar na tabela, retorna efetividade normal
      print('⚠️ [Efetividade] Não encontrada defesa de ${tipoDefensor.name} vs ${tipoAtacante.name}, usando 1.0x');
      return 1.0;
    } catch (e) {
      print('❌ [Efetividade] Erro ao calcular: $e');
      return 1.0; // Fallback para efetividade normal
    }
  }
  
  /// Obtém o texto descritivo da efetividade
  String _obterTextoEfetividade(double efetividade) {
    if (efetividade >= 2.0) return '(Super Efetivo!)';
    if (efetividade > 1.0) return '(Efetivo)';
    if (efetividade == 1.0) return '(Normal)';
    if (efetividade > 0.5) return '(Pouco Efetivo)';
    if (efetividade > 0.0) return '(Não Muito Efetivo)';
    return '(Não Afeta)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: Text('Batalha - Turno $turnoAtual'),
        centerTitle: true,
        elevation: 2,
      ),
      body: estadoAtual == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status dos monstros
                  _buildStatusMonstros(),
                  
                  const SizedBox(height: 20),
                  
                  // Botões de ação (movido para cima)
                  if (!batalhaConcluida)
                    _buildBotoesAcao(),
                  
                  const SizedBox(height: 20),
                  
                  // Ação atual ou resultado
                  if (batalhaConcluida)
                    _buildResultadoFinal()
                  else if (mostrandoAcao)
                    _buildAcaoEmAndamento()
                  else if (aguardandoContinuar)
                    _buildUltimaAcao()
                  else
                    _buildProximaAcao(),
                  
                  const SizedBox(height: 20),
                  
                  // Histórico das ações (movido para baixo)
                  if (estadoAtual!.historicoAcoes.isNotEmpty)
                    _buildHistoricoBatalha(),
                  
                  // Indicador de salvamento
                  if (salvandoResultado)
                    _buildIndicadorSalvamento(),
                ],
              ),
            ),
            bottomNavigationBar: batalhaConcluida && !salvandoResultado
                ? Container(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 30, // Espaço adicional para botões virtuais
                      top: 10,
                    ),
                    child: _buildBotaoVoltar(),
                  )
                : null,
    );
  }

  Widget _buildStatusMonstros() {
    return Row(
      children: [
        // Jogador
        Expanded(
          child: _buildStatusMonstro(
            nome: widget.jogador.tipo.displayName,
            imagem: widget.jogador.imagem,
            vidaAtual: estadoAtual!.vidaAtualJogador,
            vidaMaxima: estadoAtual!.vidaMaximaJogador, // Usa vida máxima com buffs
            energiaAtual: estadoAtual!.energiaAtualJogador,
            energiaMaxima: widget.jogador.energia,
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
            nome: widget.inimigo.tipo.displayName,
            imagem: widget.inimigo.imagem,
            vidaAtual: estadoAtual!.vidaAtualInimigo,
            vidaMaxima: estadoAtual!.vidaMaximaInimigo, // Usa vida máxima com buffs
            energiaAtual: estadoAtual!.energiaAtualInimigo,
            energiaMaxima: widget.inimigo.energia, // Energia real do inimigo
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
    double percentualVida = vidaAtual / vidaMaxima;
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
          
          // Vida numérica
          Text(
            '$vidaAtual/$vidaMaxima',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
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
          Text(
            'Retornando ao mapa em breve...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
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
            final isJogadorAcao = acao.atacante == widget.jogador.tipo.displayName;
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
          // Imagem do monstro
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: AssetImage(
                  isJogadorAcao ? widget.jogador.imagem : widget.inimigo.imagem,
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
        if (aguardandoContinuar) ...[
          // Botão de continuar após rodada completa
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _continuarBatalha,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar para Próxima Rodada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else if (!mostrandoAcao) ...[
          // Botão de executar rodada completa
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _executarRodadaCompleta,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Atacar! (Rodada Completa)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  Widget _buildBotaoVoltar() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade900,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Voltar ao Mapa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
