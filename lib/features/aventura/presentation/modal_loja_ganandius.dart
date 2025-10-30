import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../models/passiva.dart';
import '../../../core/config/score_config.dart';

class ModalLojaGanandius extends StatefulWidget {
  final HistoriaJogador historia;
  final Function(HistoriaJogador historiaAtualizada) onHistoriaAtualizada;
  final bool jaPegouGratuito; // Se já pegou o despertar gratuito neste tier
  final Function() onPegouGratuito; // Callback para marcar que pegou o gratuito
  final int comprasRealizadas; // Número de compras já realizadas neste tier
  final Function() onCompraRealizada; // Callback para incrementar contador de compras

  const ModalLojaGanandius({
    super.key,
    required this.historia,
    required this.onHistoriaAtualizada,
    required this.jaPegouGratuito,
    required this.onPegouGratuito,
    required this.comprasRealizadas,
    required this.onCompraRealizada,
  });

  @override
  State<ModalLojaGanandius> createState() => _ModalLojaGanandiusState();
}

class _ModalLojaGanandiusState extends State<ModalLojaGanandius> {
  late HistoriaJogador _historiaAtual;
  bool _comprando = false;

  // Verifica se a loja está fechada (tier 11 já usado)
  bool get lojaFechada {
    return _historiaAtual.tier == 11 && widget.jaPegouGratuito;
  }

  // Calcula o custo baseado no tier e número de compras
  int get custoDespertar {
    // Tier 11: gratuito (apenas uma vez)
    if (_historiaAtual.tier == 11 && !widget.jaPegouGratuito) {
      return 0;
    }

    // Tier 21+: sistema progressivo (20, 40, 60, 80...)
    if (_historiaAtual.tier >= 21) {
      return 20 + (widget.comprasRealizadas * 20);
    }

    // Não deveria chegar aqui se lojaFechada, mas retorna valor alto como segurança
    return 999999;
  }

  void _iniciarCompraDespertar() async {
    final prefs = await SharedPreferences.getInstance();
    final chavePassivas = 'ganandius_passivas_sorteadas_tier_${_historiaAtual.tier}';

    TipoPassiva passiva1;
    TipoPassiva passiva2;

    // Verifica se já existem passivas sorteadas salvas
    final passivasSalvas = prefs.getStringList(chavePassivas);

    if (passivasSalvas != null && passivasSalvas.length == 2) {
      // Carrega as passivas já sorteadas
      passiva1 = TipoPassiva.values.firstWhere((p) => p.name == passivasSalvas[0]);
      passiva2 = TipoPassiva.values.firstWhere((p) => p.name == passivasSalvas[1]);
      print('🎲 [GANANDIUS] Passivas carregadas da memória: ${passiva1.nome}, ${passiva2.nome}');
    } else {
      // Sorteia 2 passivas aleatórias
      final random = Random();
      final todasPassivas = List<TipoPassiva>.from(TipoPassiva.values);
      todasPassivas.shuffle(random);

      passiva1 = todasPassivas[0];
      passiva2 = todasPassivas[1];

      // Salva as passivas sorteadas
      await prefs.setStringList(chavePassivas, [passiva1.name, passiva2.name]);
      print('🎲 [GANANDIUS] Passivas sorteadas e salvas: ${passiva1.nome}, ${passiva2.nome}');
    }

    // Mostra modal de escolha entre as 2 passivas
    _mostrarEscolhaPassivas(passiva1, passiva2);
  }

  void _mostrarEscolhaPassivas(TipoPassiva passiva1, TipoPassiva passiva2) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade800,
                  Colors.deepPurple.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.3),
                          Colors.deepPurple.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: const Text(
                      '✨ Escolha Sua Passiva ✨',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    custoDespertar == 0
                        ? '✨ DESPERTAR GRATUITO! ✨\n\nO destino revelou duas possibilidades.\nEscolha uma para seguir seu caminho:'
                        : 'O destino revelou duas possibilidades.\nEscolha uma para seguir seu caminho:',
                    style: TextStyle(
                      color: custoDespertar == 0 ? Colors.greenAccent : const Color(0xFFCCCCCC),
                      fontSize: 14,
                      fontWeight: custoDespertar == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Opção 1
                  _buildCardEscolhaPassiva(passiva1),
                  const SizedBox(height: 16),

                  // Opção 2
                  _buildCardEscolhaPassiva(passiva2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardEscolhaPassiva(TipoPassiva tipoPassiva) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade700.withOpacity(0.6),
            Colors.deepPurple.shade800.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop(); // Fecha modal de escolha
            _selecionarMonstro(tipoPassiva);
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Ícone da passiva
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      tipoPassiva.icone,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info da passiva
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipoPassiva.nome,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tipoPassiva.descricao,
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Seta
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.amber,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _historiaAtual = widget.historia;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900.withOpacity(0.95),
              Colors.deepPurple.shade800.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header da loja
            _buildHeader(),

            // Botão de comprar despertar ou mensagem de loja fechada
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: lojaFechada
                    ? _buildLojaFechada()
                    : _buildBotaoComprarDespertar(),
              ),
            ),

            // Footer com score atual
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade900,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Loja de Ganandius',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoComprarDespertar() {
    final podeComprar = _historiaAtual.score >= custoDespertar && !_comprando;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Imagem do Ganandius
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700.withOpacity(0.6),
                  Colors.deepPurple.shade900.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/npc/negociante_ganandius.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.amber.withOpacity(0.3),
                          Colors.deepPurple.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.amber,
                    ),
                  );
                },
              ),
            ),
          ),

          // Botão de comprar
          Container(
            decoration: BoxDecoration(
              gradient: podeComprar
                  ? const LinearGradient(
                      colors: [Colors.amber, Colors.yellow],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade800],
                    ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: podeComprar ? Colors.deepPurple : Colors.grey.shade600,
                width: 3,
              ),
              boxShadow: podeComprar
                  ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: podeComprar ? _iniciarCompraDespertar : null,
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Column(
                    children: [
                      const Text(
                        '🎲 DESPERTAR ALEATÓRIO 🎲',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (custoDespertar > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$custoDespertar moedas',
                          style: TextStyle(
                            color: podeComprar ? Colors.deepPurple.shade700 : Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (!podeComprar && _historiaAtual.score < custoDespertar) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent, width: 1),
              ),
              child: const Text(
                '❌ Moedas insuficientes',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildLojaFechada() {
    final proximoAndar = ((_historiaAtual.tier ~/ 10) + 1) * 10 + 1;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700.withOpacity(0.6),
                  Colors.deepPurple.shade900.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),
                const Text(
                  '🔒 Loja Fechada 🔒',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Você já utilizou o despertar gratuito\ndeste andar.',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade900.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Text(
                    '✨ Nos encontraremos no andar $proximoAndar ✨',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'serif',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade900,
            Colors.deepPurple.shade700,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.2),
                  Colors.yellow.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Ouro: ${ScoreConfig.formatarScoreExibicao(_historiaAtual.tier, _historiaAtual.score)}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade800.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Nível: ${widget.historia.tier}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selecionarMonstro(TipoPassiva tipoPassiva) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade800,
                  Colors.deepPurple.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.deepPurple.shade900,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        tipoPassiva.icone,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Selecione o Monstro',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de monstros
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListView.builder(
                      itemCount: _historiaAtual.monstros.length,
                      itemBuilder: (context, index) {
                        final monstro = _historiaAtual.monstros[index];
                        return _buildCardMonstro(monstro, tipoPassiva);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardMonstro(MonstroAventura monstro, TipoPassiva tipoPassiva) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmarAtribuicaoPassiva(monstro, tipoPassiva),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagem do monstro
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: monstro.tipo.cor.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: monstro.tipo.cor, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      monstro.imagem,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          monstro.tipo.icone,
                          size: 32,
                          color: monstro.tipo.cor,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info do monstro
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monstro.nome,
                        style: TextStyle(
                          color: monstro.tipo.cor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monstro.tipo.displayName,
                        style: TextStyle(
                          color: monstro.tipo.cor.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (monstro.passiva != null)
                        Row(
                          children: [
                            Text(
                              monstro.passiva!.tipo.icone,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Passiva: ${monstro.passiva!.tipo.nome}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Sem passiva',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                // Seta
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.amber,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarAtribuicaoPassiva(MonstroAventura monstro, TipoPassiva tipoPassiva) {
    // Se o monstro já tem passiva, avisa que será substituída
    final temPassivaAtual = monstro.passiva != null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade800,
                  Colors.deepPurple.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚠️ Confirmação ⚠️',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (temPassivaAtual)
                    Column(
                      children: [
                        Text(
                          '${monstro.nome} já possui a passiva "${monstro.passiva!.tipo.nome}".',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Deseja SUBSTITUIR por "${tipoPassiva.nome}"?',
                          style: const TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    Text(
                      'Confirma despertar "${tipoPassiva.nome}" em ${monstro.nome}?',
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha confirmação
                          Navigator.of(context).pop(); // Fecha seleção de monstro
                          _atribuirPassiva(monstro, tipoPassiva);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.deepPurple.shade900,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  void _atribuirPassiva(MonstroAventura monstro, TipoPassiva tipoPassiva) async {
    if (_comprando) return;

    setState(() { _comprando = true; });

    try {
      // Desconta o score (se não for gratuito)
      final novoScore = _historiaAtual.score - custoDespertar;

      // Cria a nova passiva
      final novaPassiva = Passiva(tipo: tipoPassiva);

      // Atualiza o monstro com a nova passiva
      final monstrosAtualizados = _historiaAtual.monstros.map((m) {
        if (m.tipo == monstro.tipo && m.level == monstro.level) {
          return m.copyWith(passiva: novaPassiva);
        }
        return m;
      }).toList();

      // Atualiza a história
      final historiaAtualizada = _historiaAtual.copyWith(
        score: novoScore,
        monstros: monstrosAtualizados,
      );

      setState(() {
        _historiaAtual = historiaAtualizada;
      });

      widget.onHistoriaAtualizada(historiaAtualizada);

      // Marca que já pegou o gratuito (se era gratuito no tier 11)
      if (_historiaAtual.tier == 11 && !widget.jaPegouGratuito) {
        widget.onPegouGratuito();
      }

      // Incrementa contador de compras (para tier 21+)
      if (_historiaAtual.tier >= 21) {
        widget.onCompraRealizada();
      }

      // Limpa as passivas sorteadas salvas após a compra
      final prefs = await SharedPreferences.getInstance();
      final chavePassivas = 'ganandius_passivas_sorteadas_tier_${_historiaAtual.tier}';
      await prefs.remove(chavePassivas);
      print('🗑️ [GANANDIUS] Passivas sorteadas limpas da memória');

      // Fecha a loja
      Navigator.of(context).pop();

      // Mostra mensagem de sucesso
      _mostrarMensagemSucesso(
        '${monstro.nome} despertou "${tipoPassiva.nome}"!',
      );

    } catch (e) {
      _mostrarErro('Erro ao atribuir passiva: $e');
    }

    setState(() { _comprando = false; });
  }

  void _mostrarMensagemSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() { _comprando = false; });
  }
}
