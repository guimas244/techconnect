import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/vantagem_colecao.dart';
import '../services/vantagens_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/vantagem_colecao_enum.dart';
import '../widgets/icone_colecao_nostalgica.dart';
import 'package:remixicon/remixicon.dart';

class VantagensScreen extends ConsumerStatefulWidget {
  const VantagensScreen({super.key});

  @override
  ConsumerState<VantagensScreen> createState() => _VantagensScreenState();
}

class _VantagensScreenState extends ConsumerState<VantagensScreen>
    with TickerProviderStateMixin {
  final VantagensService _vantagensService = VantagensService();
  final StorageService _storageService = StorageService();

  List<VantagemColecao> _vantagens = [];
  bool _carregando = true;
  String? _erro;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _carregarVantagens();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarVantagens() async {
    try {
      setState(() {
        _carregando = true;
        _erro = null;
      });

      final email = await _storageService.getLastEmail();
      if (email == null) {
        throw Exception('Email do jogador não encontrado');
      }

      final vantagens = await _vantagensService.carregarVantagensJogador(email);

      if (mounted) {
        setState(() {
          _vantagens = vantagens;
          _carregando = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vantagens de Coleção'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/jogador'),
        ),
        actions: [
          IconButton(
            icon: _carregando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _carregando ? null : _carregarVantagens,
            tooltip: _carregando ? 'Carregando...' : 'Atualizar',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.indigo.shade50,
                  Colors.purple.shade50,
                  Colors.pink.shade50,
                ],
              ),
            ),
          ),
          // Content
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_carregando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Carregando vantagens...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar vantagens',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _erro!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregarVantagens,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Header com resumo
          SliverToBoxAdapter(
            child: _buildResumoVantagens(),
          ),
          // Lista de coleções
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCardColecao(_vantagens[index]),
                  );
                },
                childCount: _vantagens.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoVantagens() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Remix.award_fill,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vantagens de Coleção',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCardColecao(VantagemColecao vantagem) {
    final cor = vantagem.status.cor;
    final progresso = vantagem.progresso;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              cor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primeira linha: Nome da coleção e status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      vantagem.nomeColecao,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vantagem.status.icone,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vantagem.status.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segunda linha: Imagem e descrição
              Row(
                children: [
                  // Widget especial para coleção nostálgica ou ícone padrão
                  vantagem.ehNostalgica
                      ? const IconeColecaoNostalgica(size: 48)
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: vantagem.tipoVantagem.cor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            vantagem.tipoVantagem.icone,
                            color: vantagem.tipoVantagem.cor,
                            size: 28,
                          ),
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      vantagem.descricaoColecao,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Vantagem oferecida
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: vantagem.tipoVantagem.cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: vantagem.tipoVantagem.cor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      vantagem.tipoVantagem.icone,
                      color: vantagem.tipoVantagem.cor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vantagem.tipoVantagem.nome,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: vantagem.tipoVantagem.cor,
                            ),
                          ),
                          Text(
                            vantagem.tipoVantagem.descricao,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      vantagem.valorFormatado,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: vantagem.tipoVantagem.cor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progresso da coleção
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progresso da Coleção',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        vantagem.progressoTexto,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progresso,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(cor),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progresso * 100).toStringAsFixed(1)}% completo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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
}