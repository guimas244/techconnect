import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/batalha.dart';
import '../services/batalha_service.dart';
import '../providers/aventura_provider.dart';
import '../../../core/providers/user_provider.dart';

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
  final BatalhaService _batalhaService = BatalhaService();
  RegistroBatalha? resultadoBatalha;
  bool batalhaConcluida = false;
  bool salvandoResultado = false;

  @override
  void initState() {
    super.initState();
    _iniciarBatalha();
  }

  Future<void> _iniciarBatalha() async {
    print('🗡️ [BatalhaScreen] Iniciando batalha...');
    
    try {
      // Executa a batalha
      final resultado = await _batalhaService.executarBatalha(
        widget.jogador,
        widget.inimigo,
      );
      
      setState(() {
        resultadoBatalha = resultado;
        batalhaConcluida = true;
      });
      
      // SAVE FIRST: Salva no Drive antes de mostrar o resultado
      await _salvarResultadoNoDrive(resultado);
      
    } catch (e) {
      print('❌ [BatalhaScreen] Erro na batalha: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na batalha: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvarResultadoNoDrive(RegistroBatalha resultado) async {
    if (salvandoResultado) return;
    
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
      
      // Atualiza a vida do monstro se ele perdeu
      if (resultado.vencedor == 'inimigo') {
        // Encontra o monstro do jogador na história e atualiza sua vida
        final monstrosAtualizados = historia.monstros.map((m) {
          if (m.tipo == widget.jogador.tipo && m.tipoExtra == widget.jogador.tipoExtra) {
            // Cria uma nova instância do monstro com vida atualizada
            return MonstroAventura(
              tipo: m.tipo,
              tipoExtra: m.tipoExtra,
              imagem: m.imagem,
              vida: resultado.vidaFinalJogador,
              energia: m.energia,
              agilidade: m.agilidade,
              ataque: m.ataque,
              defesa: m.defesa,
              habilidades: m.habilidades,
              item: m.item,
            );
          }
          return m;
        }).toList();
        
        // Atualiza a história com os monstros modificados
        final historiaAtualizada = historia.copyWith(monstros: monstrosAtualizados);
        
        // Salva a história atualizada
        await repository.salvarHistoricoJogador(historiaAtualizada);
      }
      
      print('✅ [BatalhaScreen] Resultado salvo com sucesso!');
      
    } catch (e) {
      print('❌ [BatalhaScreen] Erro ao salvar resultado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar resultado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        salvandoResultado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Batalha'),
        centerTitle: true,
        elevation: 2,
      ),
      body: !batalhaConcluida
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Batalha em andamento...',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : _buildResultadoBatalha(),
    );
  }

  Widget _buildResultadoBatalha() {
    if (resultadoBatalha == null) {
      return const Center(
        child: Text('Erro: Resultado da batalha não disponível'),
      );
    }

    final resultado = resultadoBatalha!;
    final venceuBatalha = resultado.vencedor == 'jogador';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header do resultado
          Container(
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
                const SizedBox(height: 8),
                Text(
                  '${resultado.jogadorNome} vs ${resultado.inimigoNome}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Resumo da batalha
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo da Batalha',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildResumoMonstro(
                        resultado.jogadorNome,
                        resultado.vidaInicialJogador,
                        resultado.vidaFinalJogador,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildResumoMonstro(
                        resultado.inimigoNome,
                        resultado.vidaInicialInimigo,
                        resultado.vidaFinalInimigo,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Histórico detalhado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                ...resultado.acoes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final acao = entry.value;
                  return _buildAcaoItem(index + 1, acao);
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Indicador de salvamento
          if (salvandoResultado)
            Container(
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
            ),

          const SizedBox(height: 20),

          // Botão de voltar
          SizedBox(
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
          ),
        ],
      ),
    );
  }

  Widget _buildResumoMonstro(String nome, int vidaInicial, int vidaFinal, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            nome,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Vida: $vidaInicial → $vidaFinal',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoItem(int turno, AcaoBatalha acao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  acao.atacante,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            acao.descricao,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
