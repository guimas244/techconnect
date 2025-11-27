import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/criadouro_provider.dart';
import '../models/criadouro_models.dart';
import '../../../core/services/storage_service.dart';
import '../services/criadouro_notification_service.dart';
import 'widgets/mascote_display_widget.dart';
import 'widgets/status_bar_widget.dart';
import 'widgets/action_button_widget.dart';
import 'widgets/xp_bar_widget.dart';
import 'criar_mascote_screen.dart';
import 'loja_criadouro_screen.dart';
import 'memorial_screen.dart';
import 'config_criadouro_screen.dart';
import 'mochila_criadouro_screen.dart';

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

  final StorageService _storageService = StorageService();
  final CriadouroNotificationService _notificationService = CriadouroNotificationService();

  @override
  void initState() {
    super.initState();
    _sortearMonstros();
    // Inicializa o criadouro ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarCriadouro();
    });
  }

  Future<void> _inicializarCriadouro() async {
    final email = await _storageService.getLastEmail();
    if (email != null) {
      await ref.read(criadouroProvider.notifier).inicializar(email);
    }

    // Configura e inicia as notificações
    await _notificationService.init();
    await _notificationService.requestPermission();
    _notificationService.configurar(
      getMascotes: () => ref.read(criadouroProvider).mascotes,
      getConfig: () => ref.read(criadouroProvider).config,
    );
    _notificationService.iniciarMonitoramento();
  }

  @override
  void dispose() {
    _notificationService.pararMonitoramento();
    super.dispose();
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
    final mascote = state.mascoteAtivo;
    final mascotes = state.mascotesVivos;

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
            if (mascotes.length > 1) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${mascotes.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
      body: mascotes.isEmpty
          ? _buildSemMascote()
          : mascote == null
              ? _buildSelecionarMascote(mascotes)
              : _buildComMascote(mascote, mascotes),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// Tela para selecionar um mascote quando há múltiplos mas nenhum ativo
  Widget _buildSelecionarMascote(List<Mascote> mascotes) {
    // Se houver apenas 1 mascote, mostra tela otimizada
    if (mascotes.length == 1) {
      return _buildSelecionarUnicoMascote(mascotes.first);
    }

    // Múltiplos mascotes - mostra grid
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Selecione um Mascote',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${mascotes.length} mascotes disponíveis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: mascotes.length,
            itemBuilder: (context, index) => _buildMascoteCardGrande(mascotes[index]),
          ),
        ],
      ),
    );
  }

  /// Tela otimizada quando há apenas 1 mascote
  Widget _buildSelecionarUnicoMascote(Mascote mascote) {
    final nivel = ref.watch(nivelTipoProvider(mascote.tipo));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Imagem do mascote grande
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                mascote.monstroId,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nome e emoji
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mascote.nome,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(mascote.emoji, style: const TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 16),

          // XP em 1 linha (Card compacto)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv ${nivel.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('XP', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${nivel.xpAtual}/${nivel.xpParaProximoLevel}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: nivel.progressoXp,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status em grid 2x3
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Linha 1: Fome e Sede
                  Row(
                    children: [
                      Expanded(child: _buildStatusItem('🍖', 'Fome', mascote.fome)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatusItem('💧', 'Sede', mascote.sede)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Linha 2: Higiene e Alegria
                  Row(
                    children: [
                      Expanded(child: _buildStatusItem('🧼', 'Higiene', mascote.higiene)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatusItem('😊', 'Alegria', mascote.alegria)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Linha 3: Saúde (centralizada ou full width)
                  _buildStatusItem('❤️', 'Saúde', mascote.saude, corBarra: Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botão de selecionar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(criadouroProvider.notifier).selecionarMascote(mascote.tipo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Cuidar deste Mascote',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botão de criar novo
          TextButton.icon(
            onPressed: _irParaCriarMascote,
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Criar Novo Mascote'),
          ),
        ],
      ),
    );
  }

  /// Item de status com barra horizontal
  Widget _buildStatusItem(String emoji, String label, double valor, {Color? corBarra}) {
    Color cor = corBarra ?? (valor >= 70 ? Colors.green : valor >= 40 ? Colors.orange : Colors.red);

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12)),
                  Text('${valor.toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: valor / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Card grande para seleção de mascote (grid de múltiplos)
  Widget _buildMascoteCardGrande(Mascote mascote) {
    final nivel = ref.watch(nivelTipoProvider(mascote.tipo));

    return GestureDetector(
      onTap: () {
        ref.read(criadouroProvider.notifier).selecionarMascote(mascote.tipo);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagem
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                mascote.monstroId,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.pets, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Nome
            Text(
              mascote.nome,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Nível e emoji
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lv${nivel.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(mascote.emoji, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
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

  /// Card de um mascote para seleção
  Widget _buildMascoteCard(Mascote mascote, bool selecionado) {
    return GestureDetector(
      onTap: () {
        ref.read(criadouroProvider.notifier).selecionarMascote(mascote.tipo);
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selecionado ? Colors.green.withValues(alpha: 0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? Colors.green : Colors.grey[300]!,
            width: selecionado ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                mascote.monstroId,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.pets, size: 30),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mascote.nome,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              mascote.emoji,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComMascote(Mascote mascote, List<Mascote> todosMascotes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Seletor de mascotes (se houver mais de um)
          if (todosMascotes.length > 1) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Seus Mascotes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _irParaCriarMascote,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Novo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: todosMascotes
                            .map((m) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildMascoteCard(m, m.tipo == mascote.tipo),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Display do mascote
          MascoteDisplayWidget(mascote: mascote),
          const SizedBox(height: 16),

          // Barra de XP
          Builder(
            builder: (context) {
              final nivel = ref.watch(nivelAtivoProvider);
              if (nivel != null) {
                return XpBarWidget(nivel: nivel);
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),

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
            _buildNavButton('🎒', 'Mochila', _irParaMochila),
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

  void _irParaMochila() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MochilaCriadouroScreen()),
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
