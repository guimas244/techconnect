import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/progresso_diario.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/services/google_drive_service.dart';
import '../../../core/providers/user_provider.dart';
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
  bool _mostrarHistorico = false;
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

  // Variáveis para salvar/baixar kills do Drive
  bool _salvandoKills = false;
  bool _baixandoKills = false;

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
    final progressoJson = prefs.getString('progresso_diario');

    if (progressoJson != null) {
      final progressoData = jsonDecode(progressoJson) as Map<String, dynamic>;
      var progressoSalvo = ProgressoDiario.fromJson(progressoData);

      // Se é do dia anterior, finaliza o dia e cria novo
      if (progressoSalvo.data != hoje) {
        progressoSalvo = progressoSalvo.finalizarDia(hoje);
        await _salvarProgresso(progressoSalvo);
      }

      progressoAtual = progressoSalvo;
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

  Future<void> _salvarKillsNoDrive() async {
    final emailUsuario = ref.read(validUserEmailProvider);
    if (emailUsuario.isEmpty) {
      _mostrarSnackBar('Erro: Usuário não identificado', isErro: true);
      return;
    }

    setState(() => _salvandoKills = true);

    try {
      // Carrega progresso do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final progressoJson = prefs.getString('progresso_diario');

      if (progressoJson == null || progressoJson.isEmpty) {
        _mostrarSnackBar('Nenhum progresso de kills para salvar', isErro: true);
        return;
      }

      final progressoData = jsonDecode(progressoJson) as Map<String, dynamic>;

      // Adiciona metadados
      progressoData['email'] = emailUsuario;
      progressoData['salvadoEm'] = DateTime.now().toIso8601String();

      // Inicializa conexão e salva no Drive
      final driveService = GoogleDriveService();
      await driveService.inicializarConexao();
      final filename = '${emailUsuario.replaceAll('@', '_').replaceAll('.', '_')}_kills.json';

      await driveService.driveService.createJsonFileInProgresso(filename, progressoData);

      _mostrarSnackBar('Kills salvos no Drive com sucesso!');
    } catch (e) {
      print('Erro ao salvar kills no Drive: $e');
      _mostrarSnackBar('Erro ao salvar: $e', isErro: true);
    } finally {
      if (mounted) {
        setState(() => _salvandoKills = false);
      }
    }
  }

  Future<void> _baixarKillsDoDrive() async {
    final emailUsuario = ref.read(validUserEmailProvider);
    if (emailUsuario.isEmpty) {
      _mostrarSnackBar('Erro: Usuário não identificado', isErro: true);
      return;
    }

    setState(() => _baixandoKills = true);

    try {
      // Inicializa conexão e baixa do Drive
      final driveService = GoogleDriveService();
      await driveService.inicializarConexao();
      final filename = '${emailUsuario.replaceAll('@', '_').replaceAll('.', '_')}_kills.json';

      final conteudo = await driveService.driveService.downloadFileFromProgresso(filename);

      if (conteudo.isEmpty) {
        _mostrarSnackBar('Nenhum backup de kills encontrado no Drive', isErro: true);
        return;
      }

      final progressoData = jsonDecode(conteudo) as Map<String, dynamic>;

      // Remove metadados antes de salvar localmente
      progressoData.remove('email');
      progressoData.remove('salvadoEm');

      // Salva no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('progresso_diario', jsonEncode(progressoData));

      // Recarrega o progresso na tela
      await _carregarProgressoAtual();

      // Mostra informações do progresso baixado
      final progresso = ProgressoDiario.fromJson(progressoData);
      final totalKills = progresso.totalKillsComHistorico;
      final diasHistorico = progresso.historico.length;

      _mostrarSnackBar('Kills restaurados! Total: $totalKills kills, $diasHistorico dias no histórico');
    } catch (e) {
      print('Erro ao baixar kills do Drive: $e');
      _mostrarSnackBar('Erro ao baixar: $e', isErro: true);
    } finally {
      if (mounted) {
        setState(() => _baixandoKills = false);
      }
    }
  }

  void _mostrarSnackBar(String mensagem, {bool isErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
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
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _mostrarHistorico = !_mostrarHistorico;
                          if (_mostrarHistorico) _mostrarDistribuicao = false;
                        });
                      },
                      icon: Icon(
                        _mostrarHistorico ? Icons.close : Icons.history,
                        color: Colors.white,
                      ),
                      tooltip: 'Ver histórico',
                    ),
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
                            'Hoje: ${progressoAtual!.totalKills} kills | Total: ${progressoAtual!.totalKillsComHistorico} kills',
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
                          if (_mostrarDistribuicao) _mostrarHistorico = false;
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
            child: _mostrarHistorico
                ? _buildHistoricoView()
                : _mostrarDistribuicao
                    ? _buildDistribuicaoView()
                    : _buildKillsView(),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calcularBonusTipo(Tipo tipo) {
    // Usa kills do histórico válido + dia atual
    final killsTotal = progressoAtual?.killsPorTipoComHistorico ?? {};
    final kills = killsTotal[tipo.name] ?? 0;
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

  Widget _buildHistoricoView() {
    final historicoCompleto = progressoAtual?.historicoCompleto ?? [];
    final hoje = progressoAtual?.data ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final killsHoje = progressoAtual?.killsPorTipo ?? {};
    final totalKillsHoje = progressoAtual?.totalKills ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botões de Salvar/Baixar Kills do Drive
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'BACKUP NO DRIVE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Botão Salvar Kills
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _salvandoKills ? null : _salvarKillsNoDrive,
                        icon: _salvandoKills
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload, size: 18),
                        label: Text(_salvandoKills ? 'Salvando...' : 'Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botão Baixar Kills
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _baixandoKills ? null : _baixarKillsDoDrive,
                        icon: _baixandoKills
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_download, size: 18),
                        label: Text(_baixandoKills ? 'Baixando...' : 'Restaurar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Informação sobre validade
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade600, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cada entrada dura 3 dias inteiros a partir da data de entrada',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DIA ATUAL (HOJE)
          if (totalKillsHoje > 0) ...[
            _buildEntradaCard(
              dataEntrada: hoje,
              dataValidade: DateFormat('yyyy-MM-dd').format(
                DateFormat('yyyy-MM-dd').parse(hoje).add(const Duration(days: 3)),
              ),
              totalKills: totalKillsHoje,
              killsPorTipo: killsHoje,
              isHoje: true,
              estaValido: true,
            ),
          ],

          // Lista de entradas do histórico (incluindo expiradas)
          ...historicoCompleto.reversed.map((entrada) {
            return _buildEntradaCard(
              dataEntrada: entrada.dataEntrada,
              dataValidade: entrada.dataValidade,
              totalKills: entrada.totalKills,
              killsPorTipo: entrada.killsPorTipo,
              isHoje: false,
              estaValido: entrada.estaValido,
            );
          }),

          // Mensagem se não tem nada
          if (historicoCompleto.isEmpty && totalKillsHoje == 0) ...[
            const SizedBox(height: 40),
            Icon(Icons.history, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Nenhum histórico disponível',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas conquistas diárias aparecerão aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntradaCard({
    required String dataEntrada,
    required String dataValidade,
    required int totalKills,
    required Map<String, int> killsPorTipo,
    required bool isHoje,
    required bool estaValido,
  }) {
    final dataEntradaFormatada = DateFormat('dd/MM/yyyy').format(
      DateFormat('yyyy-MM-dd').parse(dataEntrada),
    );
    final dataValidadeFormatada = DateFormat('dd/MM/yyyy').format(
      DateFormat('yyyy-MM-dd').parse(dataValidade),
    );

    // Define cores baseadas no status da entrada
    Color corBorda;
    Color corFundo;
    double larguraBorda;

    if (isHoje) {
      corBorda = Colors.green.shade400;
      corFundo = Colors.indigo.shade900.withOpacity(0.5);
      larguraBorda = 3;
    } else if (!estaValido) {
      // Entrada expirada
      corBorda = Colors.grey.shade700;
      corFundo = Colors.black.withOpacity(0.2);
      larguraBorda = 2;
    } else {
      // Entrada válida
      corBorda = Colors.amber.shade700;
      corFundo = Colors.black.withOpacity(0.3);
      larguraBorda = 2;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: corBorda,
          width: larguraBorda,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHoje
                    ? Icons.today
                    : (estaValido ? Icons.calendar_today : Icons.event_busy),
                color: isHoje
                    ? Colors.green.shade400
                    : (estaValido ? Colors.amber : Colors.grey),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Entrada: $dataEntradaFormatada',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: estaValido ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                        if (isHoje) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'HOJE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ] else if (!estaValido) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'EXPIRADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Validade: até $dataValidadeFormatada',
                      style: TextStyle(
                        fontSize: 12,
                        color: isHoje
                            ? Colors.green.shade300
                            : (estaValido ? Colors.amber.shade300 : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isHoje
                      ? Colors.green.shade400
                      : (estaValido ? Colors.amber.shade700 : Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalKills kills',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: estaValido ? Colors.black : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          if (killsPorTipo.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: killsPorTipo.entries.map((tipo) {
                final tipoEnum = Tipo.values.firstWhere(
                  (t) => t.name == tipo.key,
                  orElse: () => Tipo.normal,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tipoEnum.cor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tipoEnum.cor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/tipagens/icon_tipo_${tipoEnum.name}.png',
                        width: 16,
                        height: 16,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.catching_pokemon,
                            size: 16,
                            color: tipoEnum.cor,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${tipo.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBonusStat(String nome, int valor) {
    // Se houver tipo selecionado, mostra o bônus daquele tipo
    String displayText;
    Color corTexto = Colors.amber.shade300;

    if (_tipoSelecionado != null) {
      final bonusTipo = _calcularBonusTipo(_tipoSelecionado!);
      final valorTipo = bonusTipo[nome] ?? 0;
      displayText = valorTipo > 0 ? '+$valorTipo' : '-';

      // Para cores muito escuras (como Trevas), usa a mesma cor da borda
      final isCorEscura = _tipoSelecionado!.cor.computeLuminance() < 0.1;
      corTexto = isCorEscura ? Colors.purple.shade400 : _tipoSelecionado!.cor;
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
            color: corTexto,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildKillsView() {
    final tipos = Tipo.values;
    final killsTotal = progressoAtual!.killsPorTipoComHistorico;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: tipos.map((tipo) {
          final kills = killsTotal[tipo.name] ?? 0;
          return _buildTipoCard(tipo, kills);
        }).toList(),
      ),
    );
  }

  Widget _buildTipoCard(Tipo tipo, int kills) {
    final isSelected = _tipoSelecionado == tipo;

    // Para tipos muito escuros (como Trevas), usa uma cor de borda mais clara
    final isCorEscura = tipo.cor.computeLuminance() < 0.1;
    final corBorda = isCorEscura
        ? (isSelected ? Colors.purple.shade400 : Colors.purple.shade700)
        : (isSelected ? tipo.cor : tipo.cor.withOpacity(0.5));

    final corFundo = isSelected
        ? (isCorEscura ? Colors.purple.shade900.withOpacity(0.3) : tipo.cor.withOpacity(0.2))
        : Colors.black.withOpacity(0.3);

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
          color: corFundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: corBorda,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isCorEscura ? Colors.purple.shade400 : tipo.cor).withOpacity(0.5),
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