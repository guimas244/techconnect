import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../aventura/models/habilidade.dart';
import '../models/monstro_explorador.dart';
import '../providers/equipe_explorador_provider.dart';
import '../../aventura/providers/kills_permanentes_provider.dart';

/// Tela de batalha manual do Modo Explorador
///
/// Combate por turnos onde o jogador escolhe as acoes
class BatalhaExploradorScreen extends ConsumerStatefulWidget {
  const BatalhaExploradorScreen({super.key});

  @override
  ConsumerState<BatalhaExploradorScreen> createState() =>
      _BatalhaExploradorScreenState();
}

class _BatalhaExploradorScreenState
    extends ConsumerState<BatalhaExploradorScreen> with TickerProviderStateMixin {
  // Estado da batalha
  MonstroExplorador? _monstroAtivo;
  _InimigoExplorador? _inimigo;
  bool _turnoJogador = true;
  bool _batalhaEmAndamento = true;
  String _mensagemBatalha = 'Preparando batalha...';
  bool _processandoAcao = false;
  bool _inicializado = false;

  // Animacoes
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimacoes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      _inicializarBatalha();
      _inicializado = true;
    }
  }

  void _setupAnimacoes() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _inicializarBatalha() {
    final equipe = ref.read(equipeExploradorProvider);
    if (equipe == null || equipe.monstrosAtivos.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/explorador');
      });
      return;
    }

    setState(() {
      _monstroAtivo = equipe.monstrosAtivos.first;
      _inimigo = _gerarInimigo(equipe.tierAtual);
      _mensagemBatalha = 'Escolha sua acao!';
    });
  }

  _InimigoExplorador _gerarInimigo(int tier) {
    final random = Random();
    final tipo = Tipo.values[random.nextInt(Tipo.values.length)];
    final multiplicador = 1.0 + (tier - 1) * 0.15;

    return _InimigoExplorador(
      nome: '${tipo.monsterName} Selvagem',
      tipo: tipo,
      vidaMax: (80 * multiplicador).round(),
      vidaAtual: (80 * multiplicador).round(),
      ataque: (15 * multiplicador).round(),
      defesa: (10 * multiplicador).round(),
      tier: tier,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_monstroAtivo == null || _inimigo == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mapas_aventura/floresta_verde.jpg'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildAreaInimigo(),
              const Spacer(),
              _buildAreaJogador(),
              const SizedBox(height: 16),
              _buildMensagemBatalha(),
              const SizedBox(height: 16),
              if (_batalhaEmAndamento && _turnoJogador && !_processandoAcao)
                _buildAcoes(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _batalhaEmAndamento ? _confirmarFuga : null,
            icon: const Icon(Icons.directions_run, color: Colors.red),
            label: const Text('Fugir', style: TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Tier ${_inimigo!.tier}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaInimigo() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(!_turnoJogador ? _shakeAnimation.value : 0, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withAlpha(100)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_inimigo!.tipo.icone, color: _inimigo!.tipo.cor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _inimigo!.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _inimigo!.tipo.cor.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _inimigo!.tipo.displayName,
                    style: TextStyle(color: _inimigo!.tipo.cor, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBarraVida(
              atual: _inimigo!.vidaAtual,
              max: _inimigo!.vidaMax,
              cor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaJogador() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_turnoJogador ? _shakeAnimation.value : 0, 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.withAlpha(100)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_monstroAtivo!.tipo.icone, color: _monstroAtivo!.tipo.cor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _monstroAtivo!.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  'Lv.${_monstroAtivo!.level}',
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBarraVida(
              atual: _monstroAtivo!.vidaAtual,
              max: _monstroAtivo!.vidaTotal,
              cor: Colors.green,
              label: 'HP',
            ),
            const SizedBox(height: 8),
            _buildBarraVida(
              atual: _monstroAtivo!.energiaAtual,
              max: _monstroAtivo!.energiaTotal,
              cor: Colors.blue,
              label: 'EP',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraVida({
    required int atual,
    required int max,
    required Color cor,
    String? label,
  }) {
    final porcentagem = (atual / max).clamp(0.0, 1.0);
    return Row(
      children: [
        if (label != null) ...[
          SizedBox(
            width: 24,
            child: Text(label, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: porcentagem,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation(cor),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$atual/$max', style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMensagemBatalha() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Text(
        _mensagemBatalha,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAcoes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < _monstroAtivo!.habilidades.length && i < 2; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
                    child: _buildBotaoHabilidade(_monstroAtivo!.habilidades[i]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildBotaoAcao('Atacar', Icons.flash_on, Colors.orange, _atacarBasico)),
              const SizedBox(width: 8),
              Expanded(child: _buildBotaoAcao('Defender', Icons.shield, Colors.blue, _defender)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoHabilidade(Habilidade habilidade) {
    final podeUsar = _monstroAtivo!.energiaAtual >= habilidade.custoEnergia;
    return GestureDetector(
      onTap: podeUsar ? () => _usarHabilidade(habilidade) : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: podeUsar ? habilidade.tipoElemental.cor.withAlpha(50) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: podeUsar ? habilidade.tipoElemental.cor.withAlpha(150) : Colors.grey.shade600),
        ),
        child: Column(
          children: [
            Text(
              habilidade.nome,
              style: TextStyle(color: podeUsar ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, size: 12, color: podeUsar ? Colors.blue : Colors.grey),
                Text('${habilidade.custoEnergia}', style: TextStyle(color: podeUsar ? Colors.blue : Colors.grey, fontSize: 10)),
                const SizedBox(width: 6),
                Icon(Icons.flash_on, size: 12, color: podeUsar ? Colors.orange : Colors.grey),
                Text('${habilidade.valorEfetivo}', style: TextStyle(color: podeUsar ? Colors.orange : Colors.grey, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAcao(String label, IconData icone, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cor.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withAlpha(150)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: cor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _atacarBasico() async {
    if (_processandoAcao) return;
    setState(() {
      _processandoAcao = true;
      _mensagemBatalha = '${_monstroAtivo!.nome} ataca!';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    final dano = (_monstroAtivo!.ataqueTotal * 0.8).round();
    final danoFinal = (dano - _inimigo!.defesa * 0.3).round().clamp(1, 999);

    setState(() {
      _inimigo!.vidaAtual = (_inimigo!.vidaAtual - danoFinal).clamp(0, _inimigo!.vidaMax);
      _mensagemBatalha = 'Causou $danoFinal de dano!';
    });

    _shakeController.forward().then((_) => _shakeController.reset());
    await Future.delayed(const Duration(milliseconds: 500));
    _verificarFimBatalha();
  }

  void _usarHabilidade(Habilidade habilidade) async {
    if (_processandoAcao) return;
    if (_monstroAtivo!.energiaAtual < habilidade.custoEnergia) return;

    setState(() {
      _processandoAcao = true;
      _mensagemBatalha = '${_monstroAtivo!.nome} usa ${habilidade.nome}!';
      _monstroAtivo = _monstroAtivo!.gastarEnergia(habilidade.custoEnergia);
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (habilidade.efeito == EfeitoHabilidade.danoDirecto) {
      var dano = habilidade.valorEfetivo;
      if (habilidade.tipoElemental == _monstroAtivo!.tipo) {
        dano = (dano * 1.5).round();
      }
      final danoFinal = (dano - _inimigo!.defesa * 0.2).round().clamp(1, 999);
      setState(() {
        _inimigo!.vidaAtual = (_inimigo!.vidaAtual - danoFinal).clamp(0, _inimigo!.vidaMax);
        _mensagemBatalha = 'Causou $danoFinal de dano!';
      });
    } else if (habilidade.efeito == EfeitoHabilidade.curarVida) {
      final cura = habilidade.valorEfetivo;
      setState(() {
        _monstroAtivo = _monstroAtivo!.copyWith(
          vidaAtual: (_monstroAtivo!.vidaAtual + cura).clamp(0, _monstroAtivo!.vidaTotal),
        );
        _mensagemBatalha = 'Recuperou $cura de vida!';
      });
    }

    _shakeController.forward().then((_) => _shakeController.reset());
    await Future.delayed(const Duration(milliseconds: 500));
    _verificarFimBatalha();
  }

  void _defender() async {
    if (_processandoAcao) return;
    setState(() {
      _processandoAcao = true;
      _mensagemBatalha = '${_monstroAtivo!.nome} se defende!';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    const recuperacao = 5;
    setState(() {
      _monstroAtivo = _monstroAtivo!.copyWith(
        energiaAtual: (_monstroAtivo!.energiaAtual + recuperacao).clamp(0, _monstroAtivo!.energiaTotal),
      );
      _mensagemBatalha = 'Recuperou $recuperacao de energia!';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    _turnoInimigo(defendendo: true);
  }

  void _verificarFimBatalha() {
    if (_inimigo!.vidaAtual <= 0) {
      _vitoria();
    } else if (_monstroAtivo!.vidaAtual <= 0) {
      _derrota();
    } else {
      _turnoInimigo();
    }
  }

  void _turnoInimigo({bool defendendo = false}) async {
    setState(() {
      _turnoJogador = false;
      _mensagemBatalha = '${_inimigo!.nome} ataca!';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    var dano = _inimigo!.ataque;
    if (defendendo) dano = (dano * 0.5).round();
    final danoFinal = (dano - _monstroAtivo!.defesaTotal * 0.3).round().clamp(1, 999);

    setState(() {
      _monstroAtivo = _monstroAtivo!.receberDano(danoFinal);
      _mensagemBatalha = 'Recebeu $danoFinal de dano!';
    });

    _shakeController.forward().then((_) => _shakeController.reset());
    await Future.delayed(const Duration(milliseconds: 500));

    if (_monstroAtivo!.vidaAtual <= 0) {
      _derrota();
    } else {
      setState(() {
        _turnoJogador = true;
        _processandoAcao = false;
        _mensagemBatalha = 'Escolha sua acao!';
      });
    }
  }

  void _vitoria() async {
    setState(() {
      _batalhaEmAndamento = false;
      _mensagemBatalha = 'Vitoria!';
    });

    await Future.delayed(const Duration(seconds: 1));
    final xpGanho = _inimigo!.tier * 25;
    final killsGanho = (_inimigo!.tier / 2).ceil() + 1;

    // Salva levels atuais para comparar depois
    final equipeAntes = ref.read(equipeExploradorProvider);
    final levelsAntes = <String, int>{};
    if (equipeAntes != null) {
      for (final m in equipeAntes.todosMonstros) {
        levelsAntes[m.id] = m.level;
      }
    }

    await ref.read(equipeExploradorProvider.notifier).distribuirXp(xpGanho);
    await ref.read(killsPermanentesProvider.notifier).adicionarKills(_inimigo!.tipo, killsGanho);
    await ref.read(equipeExploradorProvider.notifier).registrarBatalha(vitoria: true);

    // Verifica quem subiu de level
    final equipeDepois = ref.read(equipeExploradorProvider);
    final monstrosQueSubiram = <String>[];
    if (equipeDepois != null) {
      for (final m in equipeDepois.todosMonstros) {
        final levelAntes = levelsAntes[m.id] ?? 0;
        if (m.level > levelAntes) {
          monstrosQueSubiram.add('${m.nome} subiu para Lv.${m.level}!');
        }
      }
    }

    if (mounted) _mostrarResultado(vitoria: true, xpGanho: xpGanho, killsGanho: killsGanho, levelUps: monstrosQueSubiram);
  }

  void _derrota() async {
    setState(() {
      _batalhaEmAndamento = false;
      _mensagemBatalha = 'Derrota...';
    });

    await Future.delayed(const Duration(seconds: 1));
    await ref.read(equipeExploradorProvider.notifier).registrarBatalha(vitoria: false);
    if (mounted) _mostrarResultado(vitoria: false);
  }

  void _mostrarResultado({required bool vitoria, int xpGanho = 0, int killsGanho = 0, List<String> levelUps = const []}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            Icon(vitoria ? Icons.emoji_events : Icons.sentiment_dissatisfied, color: vitoria ? Colors.amber : Colors.red, size: 32),
            const SizedBox(width: 12),
            Text(vitoria ? 'Vitoria!' : 'Derrota', style: TextStyle(color: vitoria ? Colors.amber : Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: vitoria
              ? [
                  _buildRecompensaItem(Icons.auto_awesome, '+$xpGanho XP', Colors.purple),
                  const SizedBox(height: 8),
                  _buildRecompensaItem(Icons.stars, '+$killsGanho Kills', Colors.teal),
                  // Level ups
                  if (levelUps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    ...levelUps.map((msg) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ]
              : [const Text('Seu monstro foi derrotado.\nTente novamente!', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center)],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.pop(context);
              context.go('/explorador');
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecompensaItem(IconData icone, String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 12),
          Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  void _confirmarFuga() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Fugir?', style: TextStyle(color: Colors.white)),
        content: const Text('Voce perdera o progresso desta batalha.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.go('/explorador');
            },
            child: const Text('Fugir'),
          ),
        ],
      ),
    );
  }
}

class _InimigoExplorador {
  final String nome;
  final Tipo tipo;
  final int vidaMax;
  int vidaAtual;
  final int ataque;
  final int defesa;
  final int tier;

  _InimigoExplorador({
    required this.nome,
    required this.tipo,
    required this.vidaMax,
    required this.vidaAtual,
    required this.ataque,
    required this.defesa,
    required this.tier,
  });
}
