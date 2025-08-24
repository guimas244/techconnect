import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/batalha.dart';
import '../models/habilidade.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../tipagem/data/tipagem_repository.dart';

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
    vezDoJogador = jogadorComeca;
    
    // Estado inicial da batalha
    estadoAtual = EstadoBatalha(
      jogador: widget.jogador,
      inimigo: widget.inimigo,
      vidaAtualJogador: widget.jogador.vidaAtual, // Usa vida atual, não máxima
      vidaAtualInimigo: widget.inimigo.vidaAtual, // Usa vida atual, não máxima
      ataqueAtualJogador: widget.jogador.ataque,
      defesaAtualJogador: widget.jogador.defesa,
      ataqueAtualInimigo: widget.inimigo.ataque,
      defesaAtualInimigo: widget.inimigo.defesa,
      habilidadesUsadasJogador: [],
      habilidadesUsadasInimigo: [],
      historicoAcoes: [],
    );
    
    print('🏃 [Batalha] ${jogadorComeca ? "Jogador" : "Inimigo"} começa');
    
    // Se for vez do inimigo, executa automaticamente
    if (!vezDoJogador) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _executarTurnoInimigo();
      });
    }
  }

  void _executarTurnoJogador() {
    if (estadoAtual == null || batalhaConcluida) return;
    
    setState(() {
      mostrandoAcao = true;
      aguardandoContinuar = false;
    });
    
    // Seleciona habilidade aleatória do jogador
    final habilidadesDisponiveis = widget.jogador.habilidades
        .where((h) => h.tipo == TipoHabilidade.ofensiva || 
                     !estadoAtual!.habilidadesUsadasJogador.contains(h.nome))
        .toList();
    
    if (habilidadesDisponiveis.isEmpty) {
      _finalizarBatalha('inimigo');
      return;
    }
    
    final habilidade = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    
    Future.delayed(const Duration(milliseconds: 1500), () async {
      final novoEstado = await _aplicarHabilidade(estadoAtual!, habilidade, true);
      
      setState(() {
        estadoAtual = novoEstado;
        ultimaAcao = novoEstado.historicoAcoes.last.descricao;
        mostrandoAcao = false;
        aguardandoContinuar = true;
      });
      
      // Salva o estado após cada ação
      _salvarEstadoBatalha();
      
      // Verifica se o inimigo morreu
      if (novoEstado.vidaAtualInimigo <= 0) {
        _finalizarBatalha('jogador');
      }
    });
  }
  
  void _executarTurnoInimigo() {
    if (estadoAtual == null || batalhaConcluida) return;
    
    setState(() {
      mostrandoAcao = true;
      aguardandoContinuar = false;
    });
    
    // Seleciona habilidade aleatória do inimigo
    final habilidadesDisponiveis = widget.inimigo.habilidades
        .where((h) => h.tipo == TipoHabilidade.ofensiva || 
                     !estadoAtual!.habilidadesUsadasInimigo.contains(h.nome))
        .toList();
    
    if (habilidadesDisponiveis.isEmpty) {
      _finalizarBatalha('jogador');
      return;
    }
    
    final habilidade = habilidadesDisponiveis[_random.nextInt(habilidadesDisponiveis.length)];
    
    Future.delayed(const Duration(milliseconds: 1500), () async {
      final novoEstado = await _aplicarHabilidade(estadoAtual!, habilidade, false);
      
      setState(() {
        estadoAtual = novoEstado;
        ultimaAcao = novoEstado.historicoAcoes.last.descricao;
        mostrandoAcao = false;
        aguardandoContinuar = true;
      });
      
      // Salva o estado após cada ação
      _salvarEstadoBatalha();
      
      // Verifica se o jogador morreu
      if (novoEstado.vidaAtualJogador <= 0) {
        _finalizarBatalha('inimigo');
      }
      if (novoEstado.vidaAtualJogador <= 0) {
        _finalizarBatalha('inimigo');
      }
    });
  }
  
  void _continuarBatalha() {
    setState(() {
      turnoAtual++;
      vezDoJogador = !vezDoJogador;
      aguardandoContinuar = false;
    });
    
    // Executa próximo turno
    if (vezDoJogador) {
      // Aguarda um pouco para o jogador processar a ação anterior
      Future.delayed(const Duration(milliseconds: 500), () {
        // Jogador deve clicar em continuar para executar seu turno
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _executarTurnoInimigo();
      });
    }
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
          descricao = '$atacante curou ${novaVida - vidaAntes} de vida (${habilidade.nome})';
        } else {
          int vidaAntes = estado.vidaAtualInimigo;
          int novaVida = (estado.vidaAtualInimigo + habilidade.valor).clamp(0, estado.inimigo.vida);
          novoEstado = estado.copyWith(vidaAtualInimigo: novaVida);
          descricao = '$atacante curou ${novaVida - vidaAntes} de vida (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarAtaque:
        if (isJogador) {
          int novoAtaque = estado.ataqueAtualJogador + habilidade.valor;
          novoEstado = estado.copyWith(ataqueAtualJogador: novoAtaque);
          descricao = '$atacante aumentou o ataque em ${habilidade.valor} (${habilidade.nome})';
        } else {
          int novoAtaque = estado.ataqueAtualInimigo + habilidade.valor;
          novoEstado = estado.copyWith(ataqueAtualInimigo: novoAtaque);
          descricao = '$atacante aumentou o ataque em ${habilidade.valor} (${habilidade.nome})';
        }
        break;
        
      case EfeitoHabilidade.aumentarDefesa:
        if (isJogador) {
          int novaDefesa = estado.defesaAtualJogador + habilidade.valor;
          novoEstado = estado.copyWith(defesaAtualJogador: novaDefesa);
          descricao = '$atacante aumentou a defesa em ${habilidade.valor} (${habilidade.nome})';
        } else {
          int novaDefesa = estado.defesaAtualInimigo + habilidade.valor;
          novoEstado = estado.copyWith(defesaAtualInimigo: novaDefesa);
          descricao = '$atacante aumentou a defesa em ${habilidade.valor} (${habilidade.nome})';
        }
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
    
    // SAVE FIRST: Salva no Drive antes de redirecionar
    _salvarResultadoNoDrive().then((_) {
      // Após salvar, aguarda 3 segundos e volta ao mapa automaticamente
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    });
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
                  
                  // Histórico das ações
                  if (estadoAtual!.historicoAcoes.isNotEmpty)
                    _buildHistoricoBatalha(),
                  
                  const SizedBox(height: 20),
                  
                  // Botões de ação
                  if (!batalhaConcluida)
                    _buildBotoesAcao(),
                  
                  // Indicador de salvamento
                  if (salvandoResultado)
                    _buildIndicadorSalvamento(),
                  
                  // Botão de voltar (só aparece quando a batalha termina)
                  if (batalhaConcluida && !salvandoResultado)
                    _buildBotaoVoltar(),
                ],
              ),
            ),
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
            vidaMaxima: widget.jogador.vida,
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
                color: vezDoJogador ? Colors.blue.shade100 : Colors.red.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: vezDoJogador ? Colors.blue : Colors.red,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.flash_on,
                color: vezDoJogador ? Colors.blue : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vezDoJogador ? 'Sua vez' : 'Vez dele',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: vezDoJogador ? Colors.blue : Colors.red,
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
            vidaMaxima: widget.inimigo.vida,
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
    required Color cor,
    required bool isJogador,
  }) {
    double percentualVida = vidaAtual / vidaMaxima;
    
    return Container(
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
        ],
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
            vezDoJogador ? 'Executando sua ação...' : 'Inimigo está atacando...',
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
        color: vezDoJogador ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vezDoJogador ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Text(
        vezDoJogador 
            ? 'É sua vez! Clique em "Atacar" para executar uma habilidade aleatória.'
            : 'Vez do inimigo. Ele atacará automaticamente em breve.',
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
          ...estadoAtual!.historicoAcoes.asMap().entries.map((entry) {
            final index = entry.key;
            final acao = entry.value;
            final isJogadorAcao = acao.atacante == widget.jogador.tipo.displayName;
            return _buildAcaoItem(index + 1, acao, isJogadorAcao);
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
        if (vezDoJogador && aguardandoContinuar) ...[
          // Botão de continuar após ação do jogador
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _continuarBatalha,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else if (vezDoJogador && !mostrandoAcao && !aguardandoContinuar) ...[
          // Botão de atacar para o jogador
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _executarTurnoJogador,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Atacar!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else if (!vezDoJogador && aguardandoContinuar) ...[
          // Botão de continuar após ação do inimigo
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _continuarBatalha,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar',
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
