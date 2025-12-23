import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/equipe_explorador.dart';
import '../models/mapa_explorador.dart';
import '../models/monstro_explorador.dart';
import '../providers/equipe_explorador_provider.dart';
import '../../aventura/presentation/batalha_screen.dart';
import '../../aventura/models/monstro_inimigo.dart';
import '../services/batalha_explorador_service.dart';

/// Resultado da exploracao do mapa
enum ResultadoMapa {
  /// Jogador completou o mapa (derrotou todos os monstros)
  completado,
  /// Jogador desistiu do mapa
  desistiu,
}

/// Tela de mapa do Modo Explorador
///
/// Mostra um mapa com monstros posicionados em pontos aleatorios.
/// Ao clicar no monstro, abre modal simples com opcao de batalhar.
class MapaExploradorScreen extends ConsumerStatefulWidget {
  /// O mapa selecionado para explorar
  final MapaExplorador mapa;

  const MapaExploradorScreen({super.key, required this.mapa});

  @override
  ConsumerState<MapaExploradorScreen> createState() => _MapaExploradorScreenState();
}

class _MapaExploradorScreenState extends ConsumerState<MapaExploradorScreen>
    with TickerProviderStateMixin {
  // Posicoes dos monstros no mapa (geradas uma vez)
  List<_MonstroNoMapa> _monstrosNoMapa = [];

  // Resultado de cada monstro: true = jogador venceu, false = jogador perdeu
  // Se nao esta no mapa, ainda nao foi batalha
  final Map<int, bool> _resultados = {};

  // Overlay de animacao de XP/Level
  OverlayEntry? _xpOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gerarMonstrosNoMapa();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _xpOverlay?.remove();
    super.dispose();
  }

  void _gerarMonstrosNoMapa() {
    final random = Random();
    _monstrosNoMapa = [];
    _resultados.clear();

    // Quantidade de monstros: 1 para boss, 3 para outros
    final quantidade = widget.mapa.raridade.isBoss ? 1 : 3;

    // Posicoes possiveis no mapa (evita bordas)
    final posicoesBase = [
      (0.2, 0.25),
      (0.7, 0.22),
      (0.45, 0.38),
      (0.25, 0.50),
      (0.70, 0.48),
      (0.50, 0.60),
    ];

    // Embaralha e pega as primeiras posicoes
    final posicoes = List<(double, double)>.from(posicoesBase)..shuffle(random);

    for (int i = 0; i < quantidade && i < widget.mapa.tiposEncontrados.length; i++) {
      final tipo = widget.mapa.tiposEncontrados[i];
      final isNativo = widget.mapa.tipoNativo(tipo);
      final isBoss = widget.mapa.raridade.isBoss;
      final isElite = widget.mapa.raridade.todosSaoElite ||
                      (widget.mapa.raridade.temElite && i == 1);

      _monstrosNoMapa.add(_MonstroNoMapa(
        tipo: tipo,
        tipoSecundario: _sortearTipoSecundario(tipo, random),
        posX: posicoes[i].$1,
        posY: posicoes[i].$2,
        isNativo: isNativo,
        isBoss: isBoss,
        isElite: isElite,
      ));
    }
  }

  Tipo _sortearTipoSecundario(Tipo tipoPrincipal, Random random) {
    // Sorteia um tipo diferente do principal
    final tipos = Tipo.values.where((t) => t != tipoPrincipal).toList();
    return tipos[random.nextInt(tipos.length)];
  }

  @override
  Widget build(BuildContext context) {
    final equipe = ref.watch(equipeExploradorProvider);

    if (_monstrosNoMapa.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    // Verifica se todos foram batalha (vencidos pelo jogador)
    final vitorias = _resultados.values.where((v) => v == true).length;
    final todosVencidos = vitorias >= _monstrosNoMapa.length;
    final tierAtual = equipe?.tierAtual ?? 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(widget.mapa.nome),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Volta sem desistir, progresso salvo
        ),
        actions: [
          // Botao desistir
          TextButton.icon(
            icon: const Icon(Icons.flag, color: Colors.red, size: 18),
            label: const Text('Desistir', style: TextStyle(color: Colors.red)),
            onPressed: _confirmarDesistencia,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Imagem do mapa de fundo
          Positioned.fill(
            child: Image.asset(
              widget.mapa.imagem,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: widget.mapa.tipoPrincipal.cor.withAlpha(50),
              ),
            ),
          ),

          // Overlay escuro
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(100),
            ),
          ),

          // Header com info do tier e botao avancar (estilo aventura)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: _buildHeaderTier(equipe, tierAtual, todosVencidos),
          ),

          // Monstros no mapa
          ..._monstrosNoMapa.asMap().entries.map((entry) {
            final index = entry.key;
            final monstro = entry.value;
            final resultado = _resultados[index]; // null = nao batalhou, true = venceu, false = perdeu
            return _buildMonstroNoMapa(index, monstro, resultado);
          }),
        ],
      ),
    );
  }

  /// Header estilo aventura: Tier + progresso + botao avancar
  Widget _buildHeaderTier(dynamic equipe, int tierAtual, bool podeAvancar) {
    final vitoriasNoMapa = _resultados.values.where((v) => v == true).length;
    final totalNoMapa = _monstrosNoMapa.length;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.mapa.tipoPrincipal.cor.withAlpha(150)),
      ),
      child: Row(
        children: [
          // TIER
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'TIER $tierAtual',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // PROGRESSO
          Expanded(
            flex: 3,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Raridade
                  ...List.generate(widget.mapa.raridade.estrelas, (i) =>
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$vitoriasNoMapa/$totalNoMapa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTAO AVANCAR (estilo aventura)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: podeAvancar ? _avancarMapa : null,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: podeAvancar
                      ? Colors.green.withAlpha(200)
                      : Colors.grey.withAlpha(100),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: podeAvancar ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// resultado: null = nao batalhou, true = jogador venceu, false = jogador perdeu
  Widget _buildMonstroNoMapa(int index, _MonstroNoMapa monstro, bool? resultado) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Tamanho do circulo (maior para boss)
    final tamanho = monstro.isBoss ? 80.0 : 60.0;

    // Monstro esta desabilitado se ja houve batalha (vitoria ou derrota)
    final desabilitado = resultado != null;

    return Positioned(
      left: screenWidth * monstro.posX - tamanho / 2,
      top: screenHeight * monstro.posY,
      child: GestureDetector(
        onTap: desabilitado ? null : () => _mostrarModalMonstro(index, monstro),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: desabilitado ? 0.5 : 1.0,
          child: Container(
            width: tamanho,
            height: tamanho,
            decoration: BoxDecoration(
              color: monstro.tipo.cor.withAlpha(50),
              shape: BoxShape.circle,
              border: Border.all(
                color: monstro.isBoss
                    ? Colors.orange
                    : (monstro.isElite ? Colors.amber : monstro.tipo.cor),
                width: monstro.isBoss ? 4 : (monstro.isElite ? 3 : 2),
              ),
              boxShadow: desabilitado ? null : [
                BoxShadow(
                  color: monstro.tipo.cor.withAlpha(150),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Imagem do monstro dentro do circulo
                ClipOval(
                  child: Image.asset(
                    'assets/monstros_aventura/colecao_inicial/${monstro.tipo.name}.png',
                    width: tamanho,
                    height: tamanho,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        monstro.tipo.icone,
                        size: tamanho * 0.5,
                        color: monstro.tipo.cor,
                      ),
                    ),
                  ),
                ),
                // Indicador de nativo (estrela) - so mostra se nao batalhou ainda
                if (monstro.isNativo && !desabilitado)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: const Icon(Icons.star, size: 12, color: Colors.red),
                    ),
                  ),
                // Caveira para resultado da batalha
                // Vermelho = jogador venceu (derrotou), Verde = jogador perdeu (monstro fugiu)
                if (resultado != null)
                  Positioned(
                    top: -6,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: resultado ? Colors.red : Colors.green,
                          width: 1,
                        ),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.skull,
                        size: 10,
                        color: resultado ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarModalMonstro(int index, _MonstroNoMapa monstro) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titulo com nome
              Text(
                monstro.isBoss
                    ? '${monstro.tipo.monsterName} BOSS'
                    : (monstro.isElite
                        ? '${monstro.tipo.monsterName} Elite'
                        : monstro.tipo.monsterName),
                style: TextStyle(
                  color: monstro.isBoss ? Colors.orange : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Imagem do monstro
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: monstro.tipo.cor.withAlpha(50),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: monstro.tipo.cor,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/monstros_aventura/colecao_inicial/${monstro.tipo.name}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      monstro.tipo.icone,
                      size: 60,
                      color: monstro.tipo.cor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dois tipos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTipoChip(monstro.tipo, isPrimario: true),
                  const SizedBox(width: 8),
                  _buildTipoChip(monstro.tipoSecundario, isPrimario: false),
                ],
              ),

              // Indicador de nativo
              if (monstro.isNativo)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'Tipo Nativo (+25% HP)',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botoes
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _iniciarBatalha(index, monstro);
                      },
                      child: const Text(
                        'BATALHAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoChip(Tipo tipo, {required bool isPrimario}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tipo.cor.withAlpha(isPrimario ? 150 : 80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tipo.cor,
          width: isPrimario ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tipo.icone, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            tipo.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isPrimario ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Modal para selecionar qual monstro usar na batalha
  Future<MonstroExplorador?> _mostrarSelecaoMonstro(List<MonstroExplorador> monstros) async {
    // Se so tem um monstro, retorna ele direto
    if (monstros.length == 1) {
      return monstros.first;
    }

    return showDialog<MonstroExplorador>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha seu Monstro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...monstros.map((m) => _buildMonstroSelecaoItem(m)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonstroSelecaoItem(MonstroExplorador monstro) {
    final vidaPercent = monstro.vidaAtual / monstro.vidaTotal;
    final energiaPercent = monstro.energiaAtual / monstro.energiaTotal;

    return GestureDetector(
      onTap: () => Navigator.pop(context, monstro),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: monstro.tipo.cor.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: monstro.tipo.cor.withAlpha(100)),
        ),
        child: Row(
          children: [
            // Imagem do monstro
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: monstro.tipo.cor.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(color: monstro.tipo.cor),
              ),
              child: ClipOval(
                child: Image.asset(
                  monstro.imagem,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    monstro.tipo.icone,
                    color: monstro.tipo.cor,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info do monstro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        monstro.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lv.${monstro.level}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Tipos do monstro
                      Image.asset(
                        'assets/tipagens/icon_tipo_${monstro.tipo.name}.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => Icon(
                          monstro.tipo.icone,
                          size: 16,
                          color: monstro.tipo.cor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/tipagens/icon_tipo_${monstro.tipoExtra.name}.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => Icon(
                          monstro.tipoExtra.icone,
                          size: 16,
                          color: monstro.tipoExtra.cor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Barra de vida
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: vidaPercent,
                            backgroundColor: Colors.grey.shade700,
                            valueColor: AlwaysStoppedAnimation(
                              vidaPercent > 0.5 ? Colors.green : (vidaPercent > 0.25 ? Colors.orange : Colors.red),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${monstro.vidaAtual}/${monstro.vidaTotal}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Barra de energia
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: energiaPercent,
                            backgroundColor: Colors.grey.shade700,
                            valueColor: const AlwaysStoppedAnimation(Colors.amber),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${monstro.energiaAtual}/${monstro.energiaTotal}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Seta indicando que pode clicar
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Future<void> _iniciarBatalha(int index, _MonstroNoMapa monstro) async {
    final equipe = ref.read(equipeExploradorProvider);
    if (equipe == null || equipe.monstrosAtivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione monstros a equipe primeiro!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostra modal para selecionar qual monstro usar
    final monstroEscolhido = await _mostrarSelecaoMonstro(equipe.monstrosAtivos);
    if (monstroEscolhido == null) return; // Cancelou

    // Converte monstro do jogador para formato da batalha
    final jogador = BatalhaExploradorService.converterParaAventura(
      monstroEscolhido,
      mapa: widget.mapa,
    );

    // Cria inimigo
    final tier = widget.mapa.tierDestino;
    final inimigo = _criarInimigo(monstro, tier);

    // Navega para batalha
    if (!mounted) return;
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BatalhaScreen(
          jogador: jogador,
          inimigo: inimigo,
          equipeCompleta: equipe.monstrosAtivos
              .map((m) => BatalhaExploradorService.converterParaAventura(m, mapa: widget.mapa))
              .toList(),
          modoExplorador: true, // Ativa opcao de fugir
        ),
      ),
    );

    // Processa resultado
    if (resultado == true) {
      // Vitoria - marca como vencido (caveira vermelha = jogador venceu)
      setState(() {
        _resultados[index] = true;
      });

      // Distribui XP (nao ganha kills neste modo)
      final xpGanho = BatalhaExploradorService.calcularXpGanho(
        tier,
        widget.mapa.raridade,
      );

      // Usa o novo metodo que retorna info de quem ganhou XP
      final xpResult = await ref.read(equipeExploradorProvider.notifier).distribuirXpComResultado(xpGanho);
      await ref.read(equipeExploradorProvider.notifier).registrarBatalha(vitoria: true);

      // Mostra animacao de XP ganho
      if (mounted && xpResult != null) {
        await _mostrarAnimacaoXp(xpResult);
      }
    } else if (resultado == false) {
      // Derrota - marca como perdido (caveira verde = jogador perdeu)
      setState(() {
        _resultados[index] = false;
      });
      await ref.read(equipeExploradorProvider.notifier).registrarBatalha(vitoria: false);
    }
    // Se resultado for null (fuga), nao marca nada - monstro continua disponivel
  }

  /// Mostra animacao de XP ganho subindo na tela
  Future<void> _mostrarAnimacaoXp(XpDistribuicaoResult xpResult) async {
    final overlay = Overlay.of(context);
    final futures = <Future>[];

    // Animacao para monstro ativo (lado esquerdo)
    if (xpResult.monstroAtivoPremiado != null) {
      futures.add(_animarMonstroXp(
        overlay: overlay,
        monstro: xpResult.monstroAtivoPremiado!,
        xpGanho: xpResult.xpGanho,
        subiuLevel: xpResult.ativoSubiuLevel,
        novoLevel: xpResult.novoLevelAtivo,
        posicaoX: 0.3,
      ));
    }

    // Animacao para monstro do banco (lado direito) - simultaneo
    if (xpResult.monstroBancoPremiado != null) {
      futures.add(_animarMonstroXp(
        overlay: overlay,
        monstro: xpResult.monstroBancoPremiado!,
        xpGanho: xpResult.xpGanho,
        subiuLevel: xpResult.bancoSubiuLevel,
        novoLevel: xpResult.novoLevelBanco,
        posicaoX: 0.7,
      ));
    }

    // Espera ambas terminarem
    await Future.wait(futures);
  }

  /// Anima um monstro recebendo XP
  Future<void> _animarMonstroXp({
    required OverlayState overlay,
    required MonstroExplorador monstro,
    required int xpGanho,
    required bool subiuLevel,
    int? novoLevel,
    required double posicaoX,
  }) async {
    final screenSize = MediaQuery.of(context).size;
    final startY = screenSize.height * 0.5;
    final centerX = screenSize.width * posicaoX;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _XpAnimationWidget(
        monstro: monstro,
        xpGanho: xpGanho,
        subiuLevel: subiuLevel,
        novoLevel: novoLevel,
        startX: centerX,
        startY: startY,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Espera a animacao terminar
    await Future.delayed(const Duration(milliseconds: 2000));
  }

  MonstroInimigo _criarInimigo(_MonstroNoMapa monstro, int tier) {
    final multiplicador = 1.0 + (tier - 1) * 0.15;

    // Bonus para tipos nativos, elite e boss
    double bonusVida = 1.0;
    if (monstro.isNativo) bonusVida *= 1.25;
    if (monstro.isElite) bonusVida *= 2.0;
    if (monstro.isBoss) bonusVida *= 10.0;

    final vidaTotal = (100 * multiplicador * bonusVida).round();

    return MonstroInimigo(
      tipo: monstro.tipo,
      tipoExtra: monstro.tipoSecundario,
      imagem: 'assets/monstros_aventura/colecao_inicial/${monstro.tipo.name}.png',
      vida: vidaTotal,
      vidaAtual: vidaTotal,
      energia: 20,
      agilidade: (10 * multiplicador).round(),
      ataque: (15 * multiplicador * (monstro.isElite || monstro.isBoss ? 1.5 : 1.0)).round(),
      defesa: (10 * multiplicador).round(),
      isElite: monstro.isElite || monstro.isBoss,
      isRaro: monstro.isBoss,
      habilidades: [],
    );
  }

  void _avancarMapa() {
    // Atualiza tier baseado na tendencia do mapa
    ref.read(equipeExploradorProvider.notifier).mudarTier(widget.mapa.tierDestino);

    // Retorna para a tela de selecao com resultado de completado
    Navigator.pop(context, ResultadoMapa.completado);
  }

  void _confirmarDesistencia() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Desistir do Mapa?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voce perdera todo o progresso deste mapa.\nDeseja desistir?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              // Retorna para a tela de selecao com resultado de desistiu
              Navigator.pop(context, ResultadoMapa.desistiu);
            },
            child: const Text('Desistir'),
          ),
        ],
      ),
    );
  }
}

/// Representa um monstro posicionado no mapa
class _MonstroNoMapa {
  final Tipo tipo;
  final Tipo tipoSecundario;
  final double posX;
  final double posY;
  final bool isNativo;
  final bool isBoss;
  final bool isElite;

  const _MonstroNoMapa({
    required this.tipo,
    required this.tipoSecundario,
    required this.posX,
    required this.posY,
    this.isNativo = false,
    this.isBoss = false,
    this.isElite = false,
  });
}

/// Widget de animacao de XP ganho
/// Mostra imagem do monstro em circulo com "+X XP" subindo e desaparecendo
class _XpAnimationWidget extends StatefulWidget {
  final MonstroExplorador monstro;
  final int xpGanho;
  final bool subiuLevel;
  final int? novoLevel;
  final double startX;
  final double startY;
  final VoidCallback onComplete;

  const _XpAnimationWidget({
    required this.monstro,
    required this.xpGanho,
    required this.subiuLevel,
    this.novoLevel,
    required this.startX,
    required this.startY,
    required this.onComplete,
  });

  @override
  State<_XpAnimationWidget> createState() => _XpAnimationWidgetState();
}

class _XpAnimationWidgetState extends State<_XpAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Animacao de posicao (sobe)
    _positionAnimation = Tween<double>(
      begin: 0,
      end: -150,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Animacao de opacidade (desaparece no final)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    // Animacao de escala (pulsa no inicio)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              left: widget.startX - 50,
              top: widget.startY + _positionAnimation.value,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circulo com imagem do monstro
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: widget.monstro.tipo.cor.withAlpha(50),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.subiuLevel ? Colors.amber : Colors.green,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.subiuLevel ? Colors.amber : Colors.green).withAlpha(150),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              widget.monstro.imagem,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                widget.monstro.tipo.icone,
                size: 35,
                color: widget.monstro.tipo.cor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Texto de XP ganho ou Level Up
        if (widget.subiuLevel) ...[
          // Level Up - icone de XP amarelo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                'Lv.${widget.novoLevel}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black),
                    Shadow(blurRadius: 8, color: Colors.amber),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          // XP ganho - verde
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '+',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '${widget.xpGanho} XP',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black),
                    Shadow(blurRadius: 8, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
