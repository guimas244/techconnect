import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/criadouro_provider.dart';
import '../models/criadouro_models.dart';
import 'widgets/mascote_display_widget.dart';
import 'widgets/status_bar_widget.dart';
import 'widgets/action_button_widget.dart';
import 'criar_mascote_screen.dart';
import 'loja_criadouro_screen.dart';
import 'memorial_screen.dart';
import 'config_criadouro_screen.dart';

class CriadouroScreen extends ConsumerStatefulWidget {
  const CriadouroScreen({super.key});

  @override
  ConsumerState<CriadouroScreen> createState() => _CriadouroScreenState();
}

class _CriadouroScreenState extends ConsumerState<CriadouroScreen> {
  static const String _moedaPath = 'assets/criadouro/comidas/moeda_criador.png';

  late String _monstro1;
  late String _monstro2;

  static const List<String> _monstrosDisponiveis = [
    'assets/monstros_aventura/colecao_inicial/inseto.png',
    'assets/monstros_aventura/colecao_inicial/venenoso.png',
    'assets/monstros_aventura/colecao_inicial/zumbi.png',
    'assets/monstros_aventura/colecao_inicial/marinho.png',
    'assets/monstros_aventura/colecao_inicial/fera.png',
    'assets/monstros_aventura/colecao_inicial/normal.png',
    'assets/monstros_aventura/colecao_inicial/planta.png',
    'assets/monstros_aventura/colecao_inicial/fogo.png',
    'assets/monstros_aventura/colecao_inicial/voador.png',
    'assets/monstros_aventura/colecao_inicial/terrestre.png',
    'assets/monstros_aventura/colecao_inicial/gelo.png',
    'assets/monstros_aventura/colecao_inicial/agua.png',
    'assets/monstros_aventura/colecao_inicial/vento.png',
    'assets/monstros_aventura/colecao_inicial/eletrico.png',
    'assets/monstros_aventura/colecao_inicial/pedra.png',
    'assets/monstros_aventura/colecao_inicial/luz.png',
    'assets/monstros_aventura/colecao_inicial/trevas.png',
    'assets/monstros_aventura/colecao_inicial/nostalgico.png',
    'assets/monstros_aventura/colecao_inicial/mistico.png',
    'assets/monstros_aventura/colecao_inicial/dragao.png',
    'assets/monstros_aventura/colecao_inicial/alien.png',
    'assets/monstros_aventura/colecao_inicial/docrates.png',
    'assets/monstros_aventura/colecao_inicial/psiquico.png',
    'assets/monstros_aventura/colecao_inicial/magico.png',
    'assets/monstros_aventura/colecao_inicial/tecnologia.png',
    'assets/monstros_aventura/colecao_inicial/tempo.png',
    'assets/monstros_aventura/colecao_inicial/deus.png',
    'assets/monstros_aventura/colecao_inicial/desconhecido.png',
    'assets/monstros_aventura/colecao_inicial/subterraneo.png',
    'assets/monstros_aventura/colecao_inicial/fantasma.png',
  ];

  @override
  void initState() {
    super.initState();
    _sortearMonstros();
    // Atualiza degradação ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(criadouroProvider.notifier).atualizarDegradacao();
    });
  }

  void _sortearMonstros() {
    final random = Random();
    final indices = List.generate(_monstrosDisponiveis.length, (i) => i);
    indices.shuffle(random);
    _monstro1 = _monstrosDisponiveis[indices[0]];
    _monstro2 = _monstrosDisponiveis[indices[1]];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(criadouroProvider);
    final mascote = state.mascote;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _monstro1,
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => const Text('🐾', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 8),
            const Text('Criadouro'),
          ],
        ),
        actions: [
          // Saldo de Teks
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(_moedaPath, width: 18, height: 18),
                const SizedBox(width: 4),
                Text(
                  '${state.teks}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: mascote == null ? _buildSemMascote() : _buildComMascote(mascote),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSemMascote() {
    final memorial = ref.watch(memorialProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/eventos/halloween/ovo_halloween.png',
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => const Text('🥚', style: TextStyle(fontSize: 100)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Você não tem um mascote',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um mascote para começar a cuidar dele!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (memorial.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${memorial.length} mascote(s) no memorial',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _irParaCriarMascote,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _monstro2,
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => const Text('🐾', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Criar Mascote'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComMascote(Mascote mascote) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Display do mascote
          MascoteDisplayWidget(mascote: mascote),
          const SizedBox(height: 24),

          // Barras de status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusBarWidget(
                    label: 'Fome',
                    emoji: mascote.emojiPorBarra('fome', mascote.fome),
                    valor: mascote.fome,
                  ),
                  StatusBarWidget(
                    label: 'Sede',
                    emoji: mascote.emojiPorBarra('sede', mascote.sede),
                    valor: mascote.sede,
                  ),
                  StatusBarWidget(
                    label: 'Higiene',
                    emoji: mascote.emojiPorBarra('higiene', mascote.higiene),
                    valor: mascote.higiene,
                  ),
                  StatusBarWidget(
                    label: 'Alegria',
                    emoji: mascote.emojiPorBarra('alegria', mascote.alegria),
                    valor: mascote.alegria,
                  ),
                  StatusBarWidget(
                    label: 'Saúde',
                    emoji: mascote.emojiPorBarra('saude', mascote.saude),
                    valor: mascote.saude,
                    corBarra: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ações rápidas (gratuitas)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ações',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ActionButtonWidget(
                        emoji: '🤲',
                        label: 'Acariciar',
                        enabled: mascote.acariciarDisponiveis > 0,
                        badge: mascote.acariciarDisponiveis > 0
                            ? '${mascote.acariciarDisponiveis}'
                            : null,
                        onPressed: () {
                          ref.read(criadouroProvider.notifier).acariciar();
                          _mostrarFeedback('Você acariciou ${mascote.nome}! 💕');
                        },
                      ),
                      ActionButtonWidget(
                        emoji: '🎾',
                        label: 'Brincar',
                        enabled: mascote.brincarDisponiveis > 0,
                        badge: mascote.brincarDisponiveis > 0
                            ? '${mascote.brincarDisponiveis}'
                            : null,
                        onPressed: () {
                          ref.read(criadouroProvider.notifier).brincar();
                          _mostrarFeedback(
                              'Você brincou com ${mascote.nome}! 🎉');
                        },
                      ),
                      ActionButtonWidget(
                        emoji: '🛁',
                        label: 'Banho',
                        enabled: true,
                        onPressed: () {
                          ref.read(criadouroProvider.notifier).darBanho();
                          _mostrarFeedback(
                              '${mascote.nome} tomou banho! ✨');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ações com itens
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usar Itens',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBotoesItens(mascote),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info de interações
          if (mascote.acariciarDisponiveis == 0 &&
              mascote.brincarDisponiveis == 0)
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete andares no Aventura para desbloquear mais interações!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBotoesItens(Mascote mascote) {
    final inventario = ref.watch(inventarioProvider);
    final temComida = inventario.itens.entries
        .any((e) => e.value > 0 && _isComida(e.key));
    final temBebida = inventario.itens.entries
        .any((e) => e.value > 0 && _isBebida(e.key));
    final temRemedio = inventario.itens.entries
        .any((e) => e.value > 0 && _isRemedio(e.key));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionButtonWidget(
          emoji: '🍖',
          label: 'Alimentar',
          enabled: temComida,
          onPressed: () => _mostrarItensParaUsar(CategoriaItem.alimentacao),
        ),
        ActionButtonWidget(
          emoji: '💧',
          label: 'Dar Água',
          enabled: temBebida,
          onPressed: () => _mostrarItensParaUsar(CategoriaItem.hidratacao),
        ),
        ActionButtonWidget(
          emoji: '💊',
          label: 'Medicar',
          enabled: temRemedio && mascote.estaDoente,
          onPressed: () => _mostrarItensParaUsar(CategoriaItem.medicamento),
        ),
      ],
    );
  }

  bool _isComida(String itemId) {
    final item = ItensCriadouro.porId(itemId);
    return item?.categoria == CategoriaItem.alimentacao;
  }

  bool _isBebida(String itemId) {
    final item = ItensCriadouro.porId(itemId);
    return item?.categoria == CategoriaItem.hidratacao;
  }

  bool _isRemedio(String itemId) {
    final item = ItensCriadouro.porId(itemId);
    return item?.categoria == CategoriaItem.medicamento;
  }

  void _mostrarItensParaUsar(CategoriaItem categoria) {
    final inventario = ref.read(inventarioProvider);
    final itensDisponiveis = inventario.todosItens
        .where((e) => e.item.categoria == categoria)
        .toList();

    if (itensDisponiveis.isEmpty) {
      _mostrarFeedback('Você não tem itens desta categoria!');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usar ${categoria.nomeCompleto}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...itensDisponiveis.map((e) => ListTile(
                  leading: Text(e.item.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(e.item.nome),
                  subtitle: Text(e.item.efeitoDescricao),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x${e.quantidade}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(criadouroProvider.notifier).usarItem(e.item.id);
                    _mostrarFeedback('Usou ${e.item.nome}! ${e.item.emoji}');
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton('🏪', 'Loja', _irParaLoja),
            _buildNavButton('⚙️', 'Config', _irParaConfig),
            _buildNavButton('📜', 'Memorial', _irParaMemorial),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String emoji, String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _mostrarFeedback(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _irParaCriarMascote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CriarMascoteScreen()),
    );
  }

  void _irParaLoja() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LojaCriadouroScreen()),
    );
  }

  void _irParaConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigCriadouroScreen()),
    );
  }

  void _irParaMemorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemorialScreen()),
    );
  }
}
