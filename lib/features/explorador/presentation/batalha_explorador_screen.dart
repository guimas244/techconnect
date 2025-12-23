import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../../aventura/models/habilidade.dart';
import '../models/monstro_explorador.dart';
import '../models/mapa_explorador.dart';
import '../providers/equipe_explorador_provider.dart';
import '../providers/mapas_explorador_provider.dart';

/// Tela de batalha manual do Modo Explorador
///
/// Combate por turnos onde o jogador escolhe as acoes
class BatalhaExploradorScreen extends ConsumerStatefulWidget {
  /// Mapa selecionado para a batalha (opcional, pode usar provider)
  final MapaExplorador? mapa;

  const BatalhaExploradorScreen({super.key, this.mapa});

  @override
  ConsumerState<BatalhaExploradorScreen> createState() =>
      _BatalhaExploradorScreenState();
}

class _BatalhaExploradorScreenState
    extends ConsumerState<BatalhaExploradorScreen> with TickerProviderStateMixin {
  // Estado da batalha
  MonstroExplorador? _monstroAtivo;
  _InimigoExplorador? _inimigo;
  MapaExplorador? _mapaAtual;
  int _batalhaAtual = 1; // 1, 2 ou 3
  int _totalBatalhas = 3;
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

    // Usa mapa passado como parametro ou gera um aleatorio
    _mapaAtual = widget.mapa;
    _totalBatalhas = _mapaAtual?.raridade.isBoss == true ? 1 : 3;

    setState(() {
      _monstroAtivo = equipe.monstrosAtivos.first;
      _inimigo = _gerarInimigo(equipe.tierAtual);
      _mensagemBatalha = 'Batalha $_batalhaAtual/$_totalBatalhas - Escolha sua acao!';
    });
  }

  _InimigoExplorador _gerarInimigo(int tier) {
    final random = Random();

    // Usa tipo do mapa se disponivel, senao aleatorio
    Tipo tipo;
    bool isNativo = false;
    if (_mapaAtual != null && _mapaAtual!.tiposEncontrados.isNotEmpty) {
      // Pega o tipo baseado na batalha atual (ou cicla se tiver menos tipos)
      final index = (_batalhaAtual - 1) % _mapaAtual!.tiposEncontrados.length;
      tipo = _mapaAtual!.tiposEncontrados[index];
      isNativo = _mapaAtual!.tipoNativo(tipo);
    } else {
      tipo = Tipo.values[random.nextInt(Tipo.values.length)];
    }

    final tierEfetivo = _mapaAtual?.tierDestino ?? tier;
    final multiplicador = 1.0 + (tierEfetivo - 1) * 0.15;

    // Bonus de HP para tipos nativos (+25%)
    final bonusNativo = isNativo ? 1.25 : 1.0;

    // Bonus para elite e boss
    double bonusRaridade = 1.0;
    bool isBoss = false;
    if (_mapaAtual != null) {
      if (_mapaAtual!.raridade.isBoss) {
        bonusRaridade = 10.0; // Boss tem 10x mais HP
        isBoss = true;
      } else if (_mapaAtual!.raridade.todosSaoElite) {
        bonusRaridade = 2.0;
      } else if (_mapaAtual!.raridade.temElite && _batalhaAtual == 2) {
        // Elite aparece na segunda batalha
        bonusRaridade = 2.0;
      }
    }

    final vidaBase = (80 * multiplicador * bonusNativo * bonusRaridade).round();

    return _InimigoExplorador(
      nome: isBoss
          ? '${tipo.monsterName} BOSS'
          : (bonusRaridade > 1.0 ? '${tipo.monsterName} Elite' : '${tipo.monsterName} Selvagem'),
      tipo: tipo,
      vidaMax: vidaBase,
      vidaAtual: vidaBase,
      ataque: (15 * multiplicador * (bonusRaridade > 1.0 ? 1.5 : 1.0)).round(),
      defesa: (10 * multiplicador * (bonusRaridade > 1.0 ? 1.3 : 1.0)).round(),
      tier: tierEfetivo,
      isNativo: isNativo,
      isBoss: isBoss,
      vidasBoss: isBoss ? 3 : 0,
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
          // Nome do mapa e contador de batalhas
          if (_mapaAtual != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _mapaAtual!.tipoPrincipal.cor.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_batalhaAtual/$_totalBatalhas',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
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
          color: _inimigo!.isBoss
              ? Colors.orange.withAlpha(40)
              : Colors.red.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _inimigo!.isBoss
                ? Colors.orange.withAlpha(150)
                : Colors.red.withAlpha(100),
            width: _inimigo!.isBoss ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Vidas do boss (coracoes)
            if (_inimigo!.isBoss)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final temVida = index < _inimigo!.vidasBoss;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        temVida ? Icons.favorite : Icons.favorite_border,
                        color: temVida ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                    );
                  }),
                ),
              ),
            Row(
              children: [
                Icon(_inimigo!.tipo.icone, color: _inimigo!.tipo.cor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _inimigo!.nome,
                    style: TextStyle(
                      color: _inimigo!.isBoss ? Colors.orange : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _inimigo!.isBoss ? 18 : 16,
                    ),
                  ),
                ),
                // Indicador de tipo nativo
                if (_inimigo!.isNativo)
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: Colors.red, size: 12),
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
              cor: _inimigo!.isBoss ? Colors.orange : Colors.red,
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
      // Verifica se e boss com vidas restantes
      if (_inimigo!.isBoss && _inimigo!.vidasBoss > 1) {
        // Boss perde uma vida mas continua
        setState(() {
          _inimigo!.perderVidaBoss();
          _mensagemBatalha = 'O Boss perdeu uma vida! Restam ${_inimigo!.vidasBoss} vidas!';
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _turnoJogador = true;
              _processandoAcao = false;
              _mensagemBatalha = 'Batalha $_batalhaAtual/$_totalBatalhas - Escolha sua acao!';
            });
          }
        });
      } else {
        _vitoria();
      }
    } else if (_monstroAtivo!.vidaAtual <= 0) {
      _derrota();
    } else {
      // Boss regenera 15% HP apos sobreviver ataque
      if (_inimigo!.isBoss) {
        final cura = (_inimigo!.vidaMax * 0.15).round();
        _inimigo!.vidaAtual = (_inimigo!.vidaAtual + cura).clamp(0, _inimigo!.vidaMax);
      }
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
    // Calcula XP baseado no mapa (nao ganha kills neste modo)
    int xpGanho;

    if (_mapaAtual != null) {
      // Usa valores do mapa (dividido por total de batalhas)
      xpGanho = (_mapaAtual!.xpBase / _totalBatalhas).ceil();

      // Bonus para boss
      if (_mapaAtual!.raridade.isBoss) {
        xpGanho = _mapaAtual!.xpBase * 5;
      }
    } else {
      xpGanho = _inimigo!.tier * 25;
    }

    // Salva levels atuais para comparar depois
    final equipeAntes = ref.read(equipeExploradorProvider);
    final levelsAntes = <String, int>{};
    if (equipeAntes != null) {
      for (final m in equipeAntes.todosMonstros) {
        levelsAntes[m.id] = m.level;
      }
    }

    await ref.read(equipeExploradorProvider.notifier).distribuirXp(xpGanho);
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

    // Verifica se tem mais batalhas
    if (_batalhaAtual < _totalBatalhas) {
      // Mostra resultado parcial e inicia proxima batalha
      setState(() {
        _mensagemBatalha = 'Vitoria! +$xpGanho XP';
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _batalhaAtual++;
          _inimigo = _gerarInimigo(_mapaAtual?.tierDestino ?? _inimigo!.tier);
          // Recupera um pouco de energia entre batalhas
          _monstroAtivo = _monstroAtivo!.copyWith(
            energiaAtual: (_monstroAtivo!.energiaAtual + 5).clamp(0, _monstroAtivo!.energiaTotal),
          );
          _turnoJogador = true;
          _processandoAcao = false;
          _mensagemBatalha = 'Batalha $_batalhaAtual/$_totalBatalhas - Escolha sua acao!';
        });
      }
    } else {
      // Fim do mapa - mostra resultado final
      setState(() {
        _batalhaEmAndamento = false;
        _mensagemBatalha = 'Vitoria!';
      });

      await Future.delayed(const Duration(seconds: 1));

      // Atualiza tier se veio de um mapa
      if (_mapaAtual != null) {
        await ref.read(equipeExploradorProvider.notifier).mudarTier(_mapaAtual!.tierDestino);
        // Limpa mapas para gerar novos
        ref.read(mapasExploradorProvider.notifier).limparMapas();
      }

      if (mounted) {
        _mostrarResultado(
          vitoria: true,
          xpGanho: _mapaAtual?.xpBase ?? xpGanho,
          levelUps: monstrosQueSubiram,
        );
      }
    }
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

  void _mostrarResultado({required bool vitoria, int xpGanho = 0, List<String> levelUps = const []}) {
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
              Navigator.pop(context); // Fecha o dialog
              Navigator.pop(context); // Volta para seleção de mapas
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Fugir?', style: TextStyle(color: Colors.white)),
        content: const Text('Voce perdera o progresso desta batalha.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext); // Fecha o dialog
              Navigator.pop(context); // Volta para seleção de mapas
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
  final bool isNativo;
  final bool isBoss;
  int vidasBoss;

  _InimigoExplorador({
    required this.nome,
    required this.tipo,
    required this.vidaMax,
    required this.vidaAtual,
    required this.ataque,
    required this.defesa,
    required this.tier,
    this.isNativo = false,
    this.isBoss = false,
    this.vidasBoss = 0,
  });

  /// Verifica se o boss ainda tem vidas
  bool get bossVivo => !isBoss || vidasBoss > 0;

  /// Perde uma vida do boss (retorna true se morreu de vez)
  bool perderVidaBoss() {
    if (!isBoss) return true;
    vidasBoss--;
    if (vidasBoss <= 0) return true;
    // Reseta HP para 100%
    vidaAtual = vidaMax;
    return false;
  }
}
