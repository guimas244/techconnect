import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/ranking_entry.dart';
import '../services/ranking_service.dart';
import '../../../core/providers/user_provider.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final RankingService _rankingService = RankingService();
  
  DateTime _dataAtual = DateTime.now();
  List<RankingEntry> _topJogadores = [];
  Map<String, dynamic> _estatisticas = {};
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Inicializa com o dia atual
    final agora = _rankingService.agora;
    _dataAtual = DateTime(agora.year, agora.month, agora.day);
    _carregarRanking();
  }

  Future<void> _carregarRanking() async {
    if (!mounted) return;
    
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final topJogadores = await _rankingService.getTopJogadores(_dataAtual, limite: 50);
      final estatisticas = await _rankingService.getEstatisticasDia(_dataAtual);

      if (!mounted) return;
      
      setState(() {
        _topJogadores = topJogadores;
        _estatisticas = estatisticas;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _erro = 'Erro ao carregar ranking: $e';
        _carregando = false;
      });
    }
  }

  void _voltarDia() {
    if (!mounted) return;
    
    setState(() {
      _dataAtual = _dataAtual.subtract(const Duration(days: 1));
    });
    _carregarRanking();
  }

  void _avancarDia() {
    if (!mounted) return;
    
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    
    if (_dataAtual.isBefore(hojeSemHora)) {
      setState(() {
        _dataAtual = _dataAtual.add(const Duration(days: 1));
      });
      _carregarRanking();
    }
  }

  void _irParaHoje() {
    if (!mounted) return;
    
    final agora = _rankingService.agora;
    setState(() {
      _dataAtual = DateTime(agora.year, agora.month, agora.day);
    });
    _carregarRanking();
  }

  String _formatarData(DateTime data) {
    final dias = [
      '',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    final meses = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];

    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final ontemSemHora = hojeSemHora.subtract(const Duration(days: 1));

    if (data == hojeSemHora) {
      return 'Hoje';
    } else if (data == ontemSemHora) {
      return 'Ontem';
    } else {
      return '${dias[data.weekday]}, ${data.day} de ${meses[data.month]}';
    }
  }

  String _obterIniciais(String email) {
    final partes = email.split('@')[0].split('.');
    if (partes.length >= 2) {
      return '${partes[0][0].toUpperCase()}${partes[1][0].toUpperCase()}';
    }
    return email.substring(0, 2).toUpperCase();
  }

  Color _getCorPosicao(int posicao) {
    switch (posicao) {
      case 1:
        return Colors.amber; // Ouro
      case 2:
        return Colors.grey.shade400; // Prata
      case 3:
        return Colors.orange.shade700; // Bronze
      default:
        return Colors.blue.shade600; // Demais posições
    }
  }

  IconData _getIconePosicao(int posicao) {
    switch (posicao) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailUsuario = ref.watch(validUserEmailProvider);
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final podeAvancar = _dataAtual.isBefore(hojeSemHora);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Ranking'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/templo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Header com navegação de data
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _voltarDia,
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _formatarData(_dataAtual),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${_dataAtual.day.toString().padLeft(2, '0')}/${_dataAtual.month.toString().padLeft(2, '0')}/${_dataAtual.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: podeAvancar ? _avancarDia : null,
                          icon: Icon(
                            Icons.chevron_right, 
                            color: podeAvancar ? Colors.white : Colors.white.withOpacity(0.3),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    if (_dataAtual != hojeSemHora) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _irParaHoje,
                        icon: const Icon(Icons.today, color: Colors.amber, size: 16),
                        label: const Text(
                          'Ir para hoje',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Estatísticas
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEstatistica('Jogadores', _estatisticas['totalJogadores']?.toString() ?? '0'),
                    _buildEstatistica('Aventuras', _estatisticas['totalRuns']?.toString() ?? '0'),
                    _buildEstatistica('Top Score', _estatisticas['scoreMaximo']?.toString() ?? '0'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Lista de ranking
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _carregando
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Carregando ranking...'),
                            ],
                          ),
                        )
                      : _erro != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, size: 48, color: Colors.red.shade300),
                                  const SizedBox(height: 16),
                                  Text(_erro!, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _carregarRanking,
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            )
                          : _topJogadores.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.leaderboard, size: 48, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Nenhuma aventura completada\nneste dia ainda',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _topJogadores.length,
                                  itemBuilder: (context, index) {
                                    final jogador = _topJogadores[index];
                                    final posicao = index + 1;
                                    final isUsuarioAtual = jogador.email == emailUsuario;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: isUsuarioAtual 
                                            ? Colors.blue.shade50 
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: isUsuarioAtual
                                            ? Border.all(color: Colors.blue.shade300, width: 2)
                                            : Border.all(color: Colors.grey.shade200),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Posição
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _getCorPosicao(posicao),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Center(
                                                child: posicao <= 3
                                                    ? Icon(
                                                        _getIconePosicao(posicao),
                                                        color: Colors.white,
                                                        size: 20,
                                                      )
                                                    : Text(
                                                        '$posicao',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            
                                            // Avatar com iniciais
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: isUsuarioAtual 
                                                    ? Colors.blue.shade600 
                                                    : Colors.grey.shade600,
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _obterIniciais(jogador.email),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            
                                            // Nome do jogador
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    jogador.email.split('@')[0],
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: isUsuarioAtual 
                                                          ? Colors.blue.shade800 
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  if (isUsuarioAtual)
                                                    Text(
                                                      'Você',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Score
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getCorPosicao(posicao).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getCorPosicao(posicao).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                '${jogador.score}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: _getCorPosicao(posicao),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstatistica(String label, String valor) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}