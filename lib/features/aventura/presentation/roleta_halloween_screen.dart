import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/providers/user_provider.dart';
import '../models/monstro_aventura.dart';
import '../services/colecao_service.dart';
import '../services/mochila_service.dart';

/// Tela da Roleta de Halloween - Sorteia 3 monstros de Halloween
class RoletaHalloweenScreen extends ConsumerStatefulWidget {
  const RoletaHalloweenScreen({super.key});

  @override
  ConsumerState<RoletaHalloweenScreen> createState() => _RoletaHalloweenScreenState();
}

class _RoletaHalloweenScreenState extends ConsumerState<RoletaHalloweenScreen>
    with TickerProviderStateMixin {
  // Lista dos 30 tipos de monstros de Halloween
  static const List<String> _tiposHalloween = [
    'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
    'eletrico', 'fantasma', 'fogo', 'gelo', 'inseto', 'luz',
    'magico', 'marinho', 'mistico', 'normal', 'nostalgico', 'pedra',
    'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo', 'terrestre',
    'trevas', 'venenoso', 'vento', 'voador', 'zumbi', 'fera',
  ];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<List<Tipo>> _roletasItens = [[], [], []];
  final List<Tipo> _resultados = [];
  bool _girando = false;
  bool _concluido = false;
  int _roletasConcluidas = 0;

  @override
  void initState() {
    super.initState();
    _inicializarRoletas();
    _iniciarAnimacao();
  }

  void _inicializarRoletas() {
    // Cria 3 controladores de animação (um para cada roleta)
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 500)), // Cada roleta para em momentos diferentes
        vsync: this,
      ),
    );

    // Gera itens aleatórios para cada roleta
    final random = Random();

    // Sorteia os 3 monstros que serão o resultado
    for (int i = 0; i < 3; i++) {
      final tipoName = _tiposHalloween[random.nextInt(_tiposHalloween.length)];
      final tipoSorteado = Tipo.values.firstWhere((t) => t.name == tipoName);
      _resultados.add(tipoSorteado);
    }

    // Para cada roleta, gera itens com o resultado no meio (posição que ficará no indicador)
    for (int i = 0; i < 3; i++) {
      final items = <Tipo>[];

      // Gera 25 itens aleatórios antes
      for (int j = 0; j < 25; j++) {
        final tipoName = _tiposHalloween[random.nextInt(_tiposHalloween.length)];
        items.add(Tipo.values.firstWhere((t) => t.name == tipoName));
      }

      // Adiciona o item sorteado (que ficará no centro)
      items.add(_resultados[i]);

      // Gera 24 itens aleatórios depois
      for (int j = 0; j < 24; j++) {
        final tipoName = _tiposHalloween[random.nextInt(_tiposHalloween.length)];
        items.add(Tipo.values.firstWhere((t) => t.name == tipoName));
      }

      _roletasItens[i] = items;
    }

    // Cria as animações com curvas suaves
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    // Listeners para detectar quando cada roleta termina
    for (int i = 0; i < 3; i++) {
      _controllers[i].addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _roletasConcluidas++;
            if (_roletasConcluidas == 3) {
              _concluido = true;
              // Aguarda 2 segundos antes de ir para as cartas
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _irParaCartas();
                }
              });
            }
          });
        }
      });
    }
  }

  void _iniciarAnimacao() {
    setState(() => _girando = true);

    // Inicia as 3 roletas com pequeno delay entre elas
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  void _irParaCartas() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CartasHalloweenScreen(
          monstrosSorteados: _resultados,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 3; i++) ...[
                        Expanded(child: _buildRoleta(i)),
                        if (i < 2) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFe76f51).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icons_gerais/roleta.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Roleta de Halloween',
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFe76f51),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleta(int index) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _roletasConcluidas > index
              ? Colors.amber
              : const Color(0xFFe76f51).withOpacity(0.3),
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Itens da roleta
            AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                final progress = _animations[index].value;
                // Calcula offset para parar no item 25 (índice do item sorteado)
                // Cada item tem 120px de altura + 4px de margem (2px em cima e 2px embaixo) = 124px
                final itemHeight = 124.0;
                final targetIndex = 25; // Índice do item sorteado
                final offset = progress * targetIndex * itemHeight;

                return Transform.translate(
                  offset: Offset(0, -offset),
                  child: Column(
                    children: _roletasItens[index].map((tipo) {
                      return Container(
                        height: 120,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: tipo.cor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/monstros_aventura/colecao_halloween/${tipo.name}.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.pets,
                                    size: 60,
                                    color: tipo.cor,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tipo.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // Indicador central
            Center(
              child: Container(
                height: 124,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Colors.amber,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),

            // Overlay de gradiente superior
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Overlay de gradiente inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Badge de conclusão
            if (_roletasConcluidas > index)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_girando && !_concluido)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFe76f51),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sorteando monstros... ($_roletasConcluidas/3)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          if (_concluido)
            Text(
              'Preparando cartas...',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// Tela de Cartas - Virar, embaralhar e selecionar
class CartasHalloweenScreen extends ConsumerStatefulWidget {
  final List<Tipo> monstrosSorteados;

  const CartasHalloweenScreen({
    super.key,
    required this.monstrosSorteados,
  });

  @override
  ConsumerState<CartasHalloweenScreen> createState() => _CartasHalloweenScreenState();
}

class _CartasHalloweenScreenState extends ConsumerState<CartasHalloweenScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _flipControllers;
  late List<AnimationController> _shuffleControllers;
  late AnimationController _revealController;

  final ColecaoService _colecaoService = ColecaoService();

  List<int> _posicoesCartas = [0, 1, 2]; // Índices das posições das cartas
  bool _cartasViradas = false;
  bool _embaralhando = false;
  bool _podeSelecionar = false;
  int? _cartaSelecionada;
  bool _revelando = false;
  bool _salvando = false; // Loading ao salvar

  @override
  void initState() {
    super.initState();
    _inicializarAnimacoes();
    _iniciarSequencia();
  }

  void _inicializarAnimacoes() {
    // Controladores de flip (virar cartas)
    _flipControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    // Controladores de shuffle (embaralhar)
    _shuffleControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    // Controlador de reveal (revelar carta selecionada)
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  Future<void> _iniciarSequencia() async {
    // Aguarda 500ms
    await Future.delayed(const Duration(milliseconds: 500));

    // 1. Vira as cartas para baixo
    await _virarCartas();

    // 2. Embaralha as cartas
    await _embaralharCartas();

    // 3. Permite seleção
    setState(() => _podeSelecionar = true);
  }

  Future<void> _virarCartas() async {
    setState(() => _cartasViradas = true);

    // Vira as 3 cartas com pequeno delay entre elas
    for (int i = 0; i < 3; i++) {
      _flipControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Aguarda a última animação terminar
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _embaralharCartas() async {
    setState(() => _embaralhando = true);

    final random = Random();

    // Faz 5 rodadas de embaralhamento
    for (int rodada = 0; rodada < 5; rodada++) {
      // Escolhe 2 cartas aleatórias para trocar
      final carta1 = random.nextInt(3);
      int carta2;
      do {
        carta2 = random.nextInt(3);
      } while (carta2 == carta1);

      // Troca as posições
      await _trocarCartas(carta1, carta2);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _embaralhando = false);
  }

  Future<void> _trocarCartas(int index1, int index2) async {
    setState(() {
      final temp = _posicoesCartas[index1];
      _posicoesCartas[index1] = _posicoesCartas[index2];
      _posicoesCartas[index2] = temp;
    });

    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _selecionarCarta(int index) {
    if (!_podeSelecionar || _revelando || _salvando) return;

    setState(() {
      _cartaSelecionada = index;
      _salvando = true; // Mostra loading
    });

    // Salva no Drive PRIMEIRO, depois mostra a carta
    _salvarEMostrarCarta(index);
  }

  Future<void> _salvarEMostrarCarta(int index) async {
    final monstroIndex = _posicoesCartas[index];
    final tipoSorteado = widget.monstrosSorteados[monstroIndex];

    print('🎃 [Halloween] Carta selecionada: ${tipoSorteado.name}');

    // 1º: Verifica ANTES de salvar se é duplicado
    final email = ref.read(validUserEmailProvider);
    final colecaoAtual = await _colecaoService.carregarColecaoJogador(email);
    final chave = 'halloween_${tipoSorteado.name}';
    final ehDuplicado = colecaoAtual[chave] == true;

    print('🎃 [Halloween] Verificando duplicado ANTES de salvar: $chave = ${colecaoAtual[chave]}');

    // 2º: Salva no Drive apenas se NÃO for duplicado
    if (!ehDuplicado) {
      await _salvarNaColecaoHalloween(tipoSorteado);
    } else {
      print('🥚 [Halloween] Monstro JÁ existe na coleção - não salvando novamente');
    }

    if (!mounted) return;

    // 3º: Esconde loading e mostra carta
    setState(() {
      _salvando = false;
      _revelando = true;
    });

    // 4º: Revela a carta com animação
    _flipControllers[index].reverse().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _retornarMonstro(tipoSorteado, ehDuplicado);
        }
      });
    });
  }

  Future<void> _retornarMonstro(Tipo tipoSorteado, bool ehDuplicado) async {
    print('🎃 [Halloween] Mostrando resultado: ${tipoSorteado.name} - Duplicado: $ehDuplicado');

    if (ehDuplicado) {
      // É duplicado - dar ovo de evento
      print('🥚 [Halloween] Monstro duplicado! Dando ovo de evento...');

      // Adiciona 1 ovo na mochila
      await _adicionarOvoNaMochila();

      // Mostra o modal do ovo
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.72)),
              ),
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(color: Colors.black.withOpacity(0.04)),
                  ),
                ),
              ),
              Center(
                child: _buildOvoDetalheCard(context: context),
              ),
            ],
          ),
        ),
      );

      // Retorna sem monstro (já tinha)
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // Não é duplicado - criar e mostrar o monstro
      final random = Random();
      final outrosTipos = Tipo.values.where((t) => t != tipoSorteado).toList();
      outrosTipos.shuffle(random);

      final monstro = MonstroAventura(
        tipo: tipoSorteado,
        tipoExtra: outrosTipos.first,
        imagem: 'assets/monstros_aventura/colecao_halloween/${tipoSorteado.name}.png',
        vida: 75 + random.nextInt(76),
        energia: 20 + random.nextInt(21),
        agilidade: 10 + random.nextInt(11),
        ataque: 10 + random.nextInt(11),
        defesa: 40 + random.nextInt(21),
        habilidades: [],
        level: 1,
      );

      // Mostra o modal de detalhes do monstro (estilo catálogo)
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.72)),
              ),
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(color: Colors.black.withOpacity(0.04)),
                  ),
                ),
              ),
              Center(
                child: _buildMonstroDetalheCard(
                  context: context,
                  monstro: monstro,
                ),
              ),
            ],
          ),
        ),
      );

      // Após fechar o modal, retorna o monstro
      if (mounted) {
        Navigator.of(context).pop(monstro);
      }
    }
  }

  Future<void> _adicionarOvoNaMochila() async {
    try {
      final email = ref.read(validUserEmailProvider);
      if (email.isEmpty) return;

      final mochila = await MochilaService.carregarMochila(context, email);
      if (mochila == null) return;

      final mochilaAtualizada = mochila.adicionarOvoEvento(1);
      await MochilaService.salvarMochila(context, email, mochilaAtualizada);

      print('✅ [Halloween] Ovo de evento adicionado à mochila!');
    } catch (e) {
      print('❌ [Halloween] Erro ao adicionar ovo: $e');
    }
  }

  Future<void> _salvarNaColecaoHalloween(Tipo tipo) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🎃 [Halloween] INICIANDO SALVAMENTO NO DRIVE');
      print('🎃 [Halloween] Monstro selecionado: ${tipo.name}');
      print('═══════════════════════════════════════════════════════');

      // Pega o email do jogador usando o provider
      final email = ref.read(validUserEmailProvider);

      print('📧 [Halloween] Email do jogador: $email');

      if (email.isEmpty) {
        print('❌ [Halloween] ERRO: Email vazio!');
        return;
      }

      print('📥 [Halloween] Carregando coleção atual do jogador...');
      // Carrega a coleção atual
      final colecaoAtual = await _colecaoService.carregarColecaoJogador(email);
      print('📦 [Halloween] Coleção carregada: ${colecaoAtual.length} monstros');

      // Adiciona o monstro de Halloween com prefixo 'halloween_'
      final chave = 'halloween_${tipo.name}';
      colecaoAtual[chave] = true;

      print('➕ [Halloween] Adicionando monstro: $chave = true');
      print('💾 [Halloween] Salvando coleção atualizada...');

      // Salva a coleção atualizada (HIVE + Drive)
      final sucesso = await _colecaoService.salvarColecaoJogador(email, colecaoAtual);

      if (sucesso) {
        print('✅ [Halloween] ✨ SUCESSO! Monstro salvo na coleção: $chave');
        print('✅ [Halloween] Arquivo salvo em: TECH CONNECT/colecao/colecao_$email.json');
      } else {
        print('❌ [Halloween] FALHA ao salvar no Drive!');
      }

      print('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      print('❌ [Halloween] ERRO CRÍTICO ao salvar na coleção:');
      print('❌ Erro: $e');
      print('❌ StackTrace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
    }
  }

  @override
  void dispose() {
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    for (var controller in _shuffleControllers) {
      controller.dispose();
    }
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 3; i++) ...[
                            Expanded(
                              child: _buildCarta(i),
                            ),
                            if (i < 2) const SizedBox(width: 16),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFe76f51).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icons_gerais/carta_verso.jpeg',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.style, size: 40, color: Color(0xFFe76f51));
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Escolha sua Carta',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFe76f51),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarta(int index) {
    final monstroIndex = _posicoesCartas[index];
    final tipo = widget.monstrosSorteados[monstroIndex];
    final foiSelecionada = _cartaSelecionada == index;

    return GestureDetector(
      onTap: () => _selecionarCarta(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(
            0.0,
            _embaralhando ? -20.0 : 0.0,
            0.0,
          )
          ..scale(foiSelecionada ? 1.05 : 1.0),
        child: AnimatedBuilder(
          animation: _flipControllers[index],
          builder: (context, child) {
            final angle = _flipControllers[index].value * pi;
            final showFront = angle < pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showFront
                  ? _buildCartaFrente(tipo)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildCartaVerso(foiSelecionada),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartaFrente(Tipo tipo) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: tipo.cor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tipo.cor,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/monstros_aventura/colecao_halloween/${tipo.name}.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.pets,
                size: 120,
                color: tipo.cor,
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            tipo.monsterName,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Halloween',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartaVerso(bool selecionada) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selecionada ? Colors.amber : const Color(0xFFe76f51),
          width: selecionada ? 4 : 3,
        ),
        boxShadow: selecionada
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          'assets/icons_gerais/carta_verso.jpeg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_salvando)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Salvando na coleção...',
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          if (!_podeSelecionar && !_revelando && !_salvando)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFe76f51),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _embaralhando ? 'Embaralhando...' : 'Preparando...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          if (_podeSelecionar && !_revelando && !_salvando)
            Text(
              'Toque em uma carta para escolher',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (_revelando && !_salvando)
            Text(
              'Revelando seu monstro...',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonstroDetalheCard({
    required BuildContext context,
    required MonstroAventura monstro,
  }) {
    final size = MediaQuery.of(context).size;
    final width = math.min(size.width * 0.85, 420.0);
    final height = math.min(size.height * 0.75, 520.0);
    final baseColor = monstro.tipo.cor;

    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: width,
        constraints: BoxConstraints(maxHeight: height),
        padding: const EdgeInsets.fromLTRB(28, 38, 28, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor.withOpacity(0.95), baseColor.withOpacity(0.55)],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.35),
              blurRadius: 34,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height * 0.46,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Align(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          monstro.imagem,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${monstro.tipo.monsterName} de Halloween',
              textAlign: TextAlign.center,
              style:
                  textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ) ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 18),
            _buildTipoChip(monstro.tipo),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoChip(Tipo tipo) {
    final baseColor = tipo.cor;
    final backgroundColor = baseColor.withOpacity(0.35);
    final borderColor = baseColor.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            width: 32,
            child: Image.asset(
              tipo.iconAsset,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) => Icon(
                    tipo.icone,
                    color: Colors.white,
                    size: 26,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIPO PRINCIPAL',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                tipo.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOvoDetalheCard({required BuildContext context}) {
    final size = MediaQuery.of(context).size;
    final width = math.min(size.width * 0.85, 420.0);
    final height = math.min(size.height * 0.75, 520.0);
    final baseColor = const Color(0xFFFF9800); // Laranja lendário

    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: width,
        constraints: BoxConstraints(maxHeight: height),
        padding: const EdgeInsets.fromLTRB(28, 38, 28, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor.withOpacity(0.95), baseColor.withOpacity(0.55)],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.35),
              blurRadius: 34,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height * 0.46,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Align(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/eventos/halloween/ovo_halloween.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.egg,
                              size: 120,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Monstro Duplicado!',
              textAlign: TextAlign.center,
              style:
                  textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ) ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Você ganhou 1 Ovo do Evento!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.35),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: baseColor.withOpacity(0.7), width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.egg,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMPENSA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Text(
                        'Ovo do Evento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
