import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/progresso_diario.dart';
import '../../../shared/models/tipo_enum.dart';
import 'package:intl/intl.dart';
import '../providers/progresso_bonus_provider.dart';

class ProgressoScreen extends ConsumerStatefulWidget {
  const ProgressoScreen({super.key});

  @override
  ConsumerState<ProgressoScreen> createState() => _ProgressoScreenState();
}

class _ProgressoScreenState extends ConsumerState<ProgressoScreen> {
  ProgressoDiario? progressoAtual;
  bool _mostrarDistribuicao = false;
  bool _isLoading = true;
  Tipo? _tipoSelecionado;
  int _pontosPorKill = 2;

  // Controladores para distribuição
  final Map<String, double> _distribuicaoTemp = {
    'HP': 0,
    'ATK': 0,
    'DEF': 0,
    'SPD': 0,
  };

  @override
  void initState() {
    super.initState();
    _carregarProgressoAtual();
  }

  Future<void> _carregarProgressoAtual() async {
    final prefs = await SharedPreferences.getInstance();
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Carrega pontos por kill configurados
    _pontosPorKill = prefs.getInt('aventura_pontos_por_kill') ?? 2;

    // Tenta carregar progresso salvo
    // IMPORTANTE: A configuração de distribuição é preservada entre dias
    final progressoJson = prefs.getString('progresso_diario');

    if (progressoJson != null) {
      final progressoData = jsonDecode(progressoJson) as Map<String, dynamic>;
      final progressoSalvo = ProgressoDiario.fromJson(progressoData);

      // Se é do dia anterior, limpa os kills mas mantém a distribuição
      if (progressoSalvo.data != hoje) {
        progressoAtual = ProgressoDiario(
          data: hoje,
          distribuicaoAtributos: progressoSalvo.distribuicaoAtributos, // Preserva a configuração
        );
        await _salvarProgresso(progressoAtual!);
      } else {
        progressoAtual = progressoSalvo;
      }
    } else {
      // Cria novo progresso
      progressoAtual = ProgressoDiario(data: hoje);
      await _salvarProgresso(progressoAtual!);
    }

    // Inicializa distribuição temp
    _distribuicaoTemp.addAll(progressoAtual!.distribuicaoAtributos);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _salvarProgresso(ProgressoDiario progresso) async {
    final prefs = await SharedPreferences.getInstance();
    final progressoJson = jsonEncode(progresso.toJson());
    await prefs.setString('progresso_diario', progressoJson);
  }

  Future<void> _salvarDistribuicao() async {
    if (progressoAtual == null) return;

    final novoProgresso = progressoAtual!.atualizarDistribuicao(_distribuicaoTemp);
    await _salvarProgresso(novoProgresso);

    // Recarrega os bônus no provider para refletir nos monstros
    await ref.read(progressoBonusStateProvider.notifier).reload();

    setState(() {
      progressoAtual = novoProgresso;
      _mostrarDistribuicao = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distribuição salva com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || progressoAtual == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade900,
              Colors.black,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final bonus = progressoAtual!.calcularBonusSync(pontosPorKill: _pontosPorKill);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF0f0f1e),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Colors.amber.shade700.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PROGRESSO DIÁRIO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ${progressoAtual!.totalKills} kills',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _mostrarDistribuicao = !_mostrarDistribuicao;
                        });
                      },
                      icon: Icon(
                        _mostrarDistribuicao ? Icons.close : Icons.settings,
                        color: Colors.white,
                      ),
                      tooltip: 'Configurar distribuição',
                    ),
                  ],
                ),

                // Bônus atual
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBonusStat('HP', bonus['HP'] ?? 0),
                      _buildBonusStat('ATK', bonus['ATK'] ?? 0),
                      _buildBonusStat('DEF', bonus['DEF'] ?? 0),
                      _buildBonusStat('SPD', bonus['SPD'] ?? 0),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo
          Expanded(
            child: _mostrarDistribuicao
                ? _buildDistribuicaoView()
                : _buildKillsView(),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calcularBonusTipo(Tipo tipo) {
    final kills = progressoAtual?.killsPorTipo[tipo.name] ?? 0;
    final bonus = <String, int>{};

    if (kills == 0) {
      return {'HP': 0, 'ATK': 0, 'DEF': 0, 'SPD': 0};
    }

    for (final entry in (progressoAtual?.distribuicaoAtributos ?? {}).entries) {
      final atributo = entry.key;
      final porcentagem = entry.value;
      final pontos = (kills * _pontosPorKill * porcentagem / 100).floor();
      bonus[atributo] = pontos;
    }

    return bonus;
  }

  Widget _buildBonusStat(String nome, int valor) {
    // Se houver tipo selecionado, mostra o bônus daquele tipo
    String displayText;
    if (_tipoSelecionado != null) {
      final bonusTipo = _calcularBonusTipo(_tipoSelecionado!);
      final valorTipo = bonusTipo[nome] ?? 0;
      displayText = valorTipo > 0 ? '+$valorTipo' : '-';
    } else {
      // Sem tipo selecionado, sempre mostra "-"
      displayText = '-';
    }

    return Column(
      children: [
        Text(
          nome,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayText,
          style: TextStyle(
            fontSize: 16,
            color: _tipoSelecionado != null
                ? _tipoSelecionado!.cor
                : Colors.amber.shade300,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildKillsView() {
    final tipos = Tipo.values;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: tipos.map((tipo) {
          final kills = progressoAtual!.killsPorTipo[tipo.name] ?? 0;
          return _buildTipoCard(tipo, kills);
        }).toList(),
      ),
    );
  }

  Widget _buildTipoCard(Tipo tipo, int kills) {
    final isSelected = _tipoSelecionado == tipo;

    return GestureDetector(
      onTap: () {
        setState(() {
          // Se já está selecionado, desseleciona
          _tipoSelecionado = isSelected ? null : tipo;
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? tipo.cor.withOpacity(0.2)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? tipo.cor : tipo.cor.withOpacity(0.5),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tipo.cor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
        children: [
          // Ícone do tipo
          Center(
            child: Image.asset(
              'assets/tipagens/icon_tipo_${tipo.name}.png',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.catching_pokemon,
                  size: 40,
                  color: tipo.cor,
                );
              },
            ),
          ),

          // Badge de kills (estilo monstro level) - sempre visível
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade700, Colors.amber.shade900],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    size: 11,
                    color: Colors.white,
                  ),
                  if (kills > 0) ...[
                    const SizedBox(width: 2),
                    Text(
                      '$kills',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0.5, 0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDistribuicaoView() {
    final totalDistribuido = _distribuicaoTemp.values.fold(0.0, (sum, val) => sum + val);
    final podeDistribuir = totalDistribuido <= 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Instruções
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade600, width: 2),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DISTRIBUIÇÃO DE ATRIBUTOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Distribua os pontos de progresso entre os atributos. '
                  'Cada kill do dia vira $_pontosPorKill pontos total, dividido pela porcentagem escolhida.\n\n'
                  '• Máximo de 50% em um único atributo\n'
                  '• Total deve somar até 100%',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total distribuído: ${totalDistribuido.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: podeDistribuir ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sliders de distribuição
          _buildAtributoSlider('HP', Icons.favorite),
          const SizedBox(height: 16),
          _buildAtributoSlider('ATK', Icons.flash_on),
          const SizedBox(height: 16),
          _buildAtributoSlider('DEF', Icons.shield),
          const SizedBox(height: 16),
          _buildAtributoSlider('SPD', Icons.speed),

          const SizedBox(height: 32),

          // Botão salvar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: podeDistribuir ? _salvarDistribuicao : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade700,
              ),
              child: const Text(
                'SALVAR DISTRIBUIÇÃO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtributoSlider(String nome, IconData icone) {
    final valor = _distribuicaoTemp[nome] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade700, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                nome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${valor.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: valor,
            min: 0,
            max: 50,
            divisions: 50,
            activeColor: Colors.amber.shade700,
            inactiveColor: Colors.grey.shade700,
            onChanged: (newValue) {
              setState(() {
                _distribuicaoTemp[nome] = newValue;
              });
            },
          ),
        ],
      ),
    );
  }
}