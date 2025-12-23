import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../auth/providers/auth_provider.dart';
import '../../aventura/services/colecao_service.dart';
import '../models/monstro_explorador.dart';
import '../providers/equipe_explorador_provider.dart';
import 'modal_selecao_monstro_explorador.dart';

/// Tela de selecao de equipe do Modo Explorador
/// Usa o mesmo padrao da Jaulinha para selecao de monstros
class SelecaoEquipeScreen extends ConsumerStatefulWidget {
  const SelecaoEquipeScreen({super.key});

  @override
  ConsumerState<SelecaoEquipeScreen> createState() => _SelecaoEquipeScreenState();
}

class _SelecaoEquipeScreenState extends ConsumerState<SelecaoEquipeScreen> {
  Map<String, bool>? _colecao;
  bool _carregandoColecao = true;

  @override
  void initState() {
    super.initState();
    _carregarColecao();
  }

  Future<void> _carregarColecao() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) {
      setState(() => _carregandoColecao = false);
      return;
    }

    final colecaoService = ColecaoService();
    final colecao = await colecaoService.carregarColecaoJogador(user.email!);

    if (mounted) {
      setState(() {
        _colecao = colecao;
        _carregandoColecao = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipe = ref.watch(equipeExploradorProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Equipe Explorador'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/explorador'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            tooltip: 'Resetar Equipe',
            onPressed: () => _confirmarReset(context, ref),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/mapas_aventura/floresta_verde.jpg'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: SafeArea(
          child: _carregandoColecao
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Secao Ativos
                      _buildSecaoHeader(
                        'Monstros Ativos',
                        Icons.flash_on,
                        Colors.amber,
                        'Participam das batalhas',
                      ),
                      const SizedBox(height: 12),
                      _buildSlotsAtivos(equipe),

                      const SizedBox(height: 24),

                      // Secao Banco
                      _buildSecaoHeader(
                        'Banco',
                        Icons.savings,
                        Colors.teal,
                        '1 ganha +1 XP (sorteio)',
                      ),
                      const SizedBox(height: 12),
                      _buildSlotsBanco(equipe),

                      const SizedBox(height: 24),

                      // Info
                      _buildInfoCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSecaoHeader(String titulo, IconData icone, Color cor, String subtitulo) {
    return Row(
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: cor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitulo,
                style: TextStyle(
                  color: cor.withAlpha(180),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsAtivos(dynamic equipe) {
    final monstros = equipe?.monstrosAtivos ?? [];

    return Row(
      children: [
        Expanded(
          child: _buildSlot(
            index: 0,
            monstro: monstros.isNotEmpty ? monstros[0] : null,
            label: 'Ativo 1',
            isAtivo: true,
            equipe: equipe,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSlot(
            index: 1,
            monstro: monstros.length > 1 ? monstros[1] : null,
            label: 'Ativo 2',
            isAtivo: true,
            equipe: equipe,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsBanco(dynamic equipe) {
    final monstros = equipe?.monstrosBanco ?? [];

    return Row(
      children: [
        Expanded(
          child: _buildSlot(
            index: 0,
            monstro: monstros.isNotEmpty ? monstros[0] : null,
            label: 'Banco 1',
            isAtivo: false,
            equipe: equipe,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSlot(
            index: 1,
            monstro: monstros.length > 1 ? monstros[1] : null,
            label: 'Banco 2',
            isAtivo: false,
            equipe: equipe,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSlot(
            index: 2,
            monstro: monstros.length > 2 ? monstros[2] : null,
            label: 'Banco 3',
            isAtivo: false,
            equipe: equipe,
          ),
        ),
      ],
    );
  }

  Widget _buildSlot({
    required int index,
    required MonstroExplorador? monstro,
    required String label,
    required bool isAtivo,
    required dynamic equipe,
  }) {
    final cor = isAtivo ? Colors.amber : Colors.teal;

    if (monstro != null) {
      // Slot com monstro
      return GestureDetector(
        onTap: () => _mostrarDetalhesMonstro(monstro, isAtivo, equipe),
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withAlpha(150), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagem do monstro
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  monstro.imagem,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 45,
                    height: 45,
                    color: monstro.tipo.cor.withAlpha(50),
                    child: Icon(monstro.tipo.icone, color: monstro.tipo.cor, size: 24),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                monstro.tipo.displayName,
                style: TextStyle(
                  color: monstro.tipo.cor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Lv.${monstro.level}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
              ),
              // Barra de XP
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: monstro.porcentagemXp,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation(Colors.purple),
                    minHeight: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Slot vazio - abre modal de selecao
    return GestureDetector(
      onTap: () => _abrirModalSelecao(label, isAtivo, equipe),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade700, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: cor.withAlpha(150),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: cor.withAlpha(150),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Toque para adicionar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre o modal de selecao estilo Jaulinha
  Future<void> _abrirModalSelecao(String tituloSlot, bool isAtivo, dynamic equipe) async {
    if (_colecao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carregando colecao...'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Coleta tipos ja usados na equipe
    final tiposJaUsados = <Tipo>{};
    if (equipe != null) {
      for (final m in equipe.monstrosAtivos) {
        tiposJaUsados.add(m.tipo);
      }
      for (final m in equipe.monstrosBanco) {
        tiposJaUsados.add(m.tipo);
      }
    }

    // Carrega monstros salvos
    final monstrosSalvos = await ref.read(monstrosSalvosDisponiveisProvider.future);

    if (!mounted) return;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalSelecaoMonstroExplorador(
        colecao: _colecao!,
        tiposJaUsados: tiposJaUsados,
        tituloSlot: tituloSlot,
        monstrosSalvos: monstrosSalvos,
        onConfirmarNovo: (tipo, colecaoEscolhida) async {
          await _adicionarMonstro(tipo, colecaoEscolhida, isAtivo);
        },
        onConfirmarSalvo: (monstro) async {
          await _adicionarMonstroSalvo(monstro, isAtivo);
        },
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monstro adicionado!'), backgroundColor: Colors.teal),
      );
    }
  }

  Future<void> _adicionarMonstro(Tipo tipo, String colecaoEscolhida, bool isAtivo) async {
    final imagem = 'assets/monstros_aventura/$colecaoEscolhida/${tipo.name}.png';

    final monstroDisponivel = MonstroDisponivel(
      tipo: tipo,
      nome: tipo.monsterName,
      imagem: imagem,
      ehNostalgico: colecaoEscolhida == 'colecao_nostalgicos',
    );

    if (isAtivo) {
      await ref.read(equipeExploradorProvider.notifier).adicionarMonstroAtivo(monstroDisponivel);
    } else {
      await ref.read(equipeExploradorProvider.notifier).adicionarMonstroAoBanco(monstroDisponivel);
    }
  }

  /// Adiciona monstro salvo (com XP/level preservados) a equipe
  Future<void> _adicionarMonstroSalvo(MonstroExplorador monstro, bool isAtivo) async {
    if (isAtivo) {
      await ref.read(equipeExploradorProvider.notifier).adicionarMonstroSalvoAtivo(monstro);
    } else {
      await ref.read(equipeExploradorProvider.notifier).adicionarMonstroSalvoBanco(monstro);
    }
  }

  void _mostrarDetalhesMonstro(MonstroExplorador monstro, bool isAtivo, dynamic equipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    monstro.imagem,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: monstro.tipo.cor.withAlpha(50),
                      child: Icon(monstro.tipo.icone, color: monstro.tipo.cor, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monstro.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        monstro.tipo.displayName,
                        style: TextStyle(color: monstro.tipo.cor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.${monstro.level}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de XP
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('XP', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                      Text(
                        '${monstro.xpAtual} / ${monstro.xpParaProximoLevel}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: monstro.porcentagemXp,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation(Colors.purple),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('HP', monstro.vidaTotal, Colors.green),
                  _buildStatItem('ATK', monstro.ataqueTotal, Colors.orange),
                  _buildStatItem('DEF', monstro.defesaTotal, Colors.blue),
                  _buildStatItem('AGI', monstro.agilidadeTotal, Colors.teal),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.grey),

            // Opcoes
            if (isAtivo && (equipe?.monstrosBanco.length ?? 0) < 3)
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.teal),
                title: const Text('Mover para Banco', style: TextStyle(color: Colors.white)),
                subtitle: Text('Chance de +1 XP por vitoria', style: TextStyle(color: Colors.teal.shade300, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(equipeExploradorProvider.notifier).moverParaBanco(monstro.id);
                },
              ),

            if (!isAtivo && (equipe?.monstrosAtivos.length ?? 0) < 2)
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.amber),
                title: const Text('Mover para Ativo', style: TextStyle(color: Colors.white)),
                subtitle: Text('Participa das batalhas', style: TextStyle(color: Colors.amber.shade300, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(equipeExploradorProvider.notifier).moverParaAtivo(monstro.id);
                },
              ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remover da Equipe', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(equipeExploradorProvider.notifier).removerMonstro(monstro.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int valor, Color cor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '$valor',
          style: TextStyle(color: cor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Como funciona',
                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.flash_on, Colors.amber, 'Ativos batalham e ganham XP completo'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.savings, Colors.teal, '1 do banco ganha +1 XP por vitoria (sorteio)'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.block, Colors.red, 'Tipos nao podem repetir na equipe'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icone, Color cor, String texto) {
    return Row(
      children: [
        Icon(icone, color: cor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _confirmarReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Resetar Equipe?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Todos os monstros serao removidos.\nO progresso de XP sera perdido!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(equipeExploradorProvider.notifier).resetarEquipe();
            },
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
  }
}
