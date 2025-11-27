import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../aventura/models/mochila.dart';
import '../../aventura/models/item_consumivel.dart';
import '../../aventura/services/mochila_service.dart';
import '../../../core/services/storage_service.dart';
import '../providers/criadouro_provider.dart';

/// Tela de Mochila do Criadouro
/// Mostra itens do Aventura que podem ser usados para dar XP ao mascote
class MochilaCriadouroScreen extends ConsumerStatefulWidget {
  const MochilaCriadouroScreen({super.key});

  @override
  ConsumerState<MochilaCriadouroScreen> createState() =>
      _MochilaCriadouroScreenState();
}

class _MochilaCriadouroScreenState
    extends ConsumerState<MochilaCriadouroScreen> {
  final StorageService _storageService = StorageService();
  Mochila? _mochila;
  bool _carregando = true;
  String? _email;

  @override
  void initState() {
    super.initState();
    _carregarMochila();
  }

  Future<void> _carregarMochila() async {
    setState(() => _carregando = true);

    final email = await _storageService.getLastEmail();
    if (email != null && mounted) {
      final mochila = await MochilaService.carregarMochila(context, email);
      setState(() {
        _email = email;
        _mochila = mochila;
        _carregando = false;
      });
    } else {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascote = ref.watch(mascoteProvider);
    final nivel = ref.watch(nivelAtivoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎒 ', style: TextStyle(fontSize: 24)),
            Text('Mochila'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _mochila == null
              ? _buildSemMochila()
              : _buildConteudo(mascote, nivel),
    );
  }

  Widget _buildSemMochila() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎒', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text(
            'Mochila não encontrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Jogue o Aventura para ganhar itens!'),
        ],
      ),
    );
  }

  Widget _buildConteudo(mascote, nivel) {
    // Filtra apenas itens do tipo fruta (Nutys)
    final nutys = <({ItemConsumivel item, int index})>[];

    for (int i = 0; i < _mochila!.itens.length; i++) {
      final item = _mochila!.itens[i];
      if (item != null && item.tipo == TipoItemConsumivel.fruta) {
        nutys.add((item: item, index: i));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info do mascote ativo
          if (mascote != null && nivel != null) ...[
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mascote.nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Lv ${nivel.level}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${nivel.xpAtual}/${nivel.xpParaProximoLevel} XP',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Seção de Nutys
          const Text(
            'Frutas Nuty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use Nutys para dar XP ao seu mascote!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          if (nutys.isEmpty)
            Card(
              color: Colors.grey[100],
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Text('🍎', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text(
                        'Nenhuma Nuty encontrada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Jogue o Aventura para dropar Nutys!',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...nutys.map((entry) => _buildNutyCard(entry.item, entry.index)),

          const SizedBox(height: 24),

          // Info adicional
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
                      'Cada Nuty dá entre 5-10 XP ao mascote ativo. O XP é permanente para o TIPO do monstro!',
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

  Widget _buildNutyCard(ItemConsumivel item, int index) {
    final mascote = ref.read(mascoteProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            item.iconPath,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              color: Colors.orange[100],
              child: const Center(
                child: Text('🍎', style: TextStyle(fontSize: 24)),
              ),
            ),
          ),
        ),
        title: Text(
          item.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.descricao,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.raridade.cor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: item.raridade.cor),
              ),
              child: Text(
                item.raridade.nome,
                style: TextStyle(
                  fontSize: 10,
                  color: item.raridade.cor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: item.quantidade > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x${item.quantidade}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (mascote != null)
                    GestureDetector(
                      onTap: () => _usarNuty(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Usar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : const Text(
                'x0',
                style: TextStyle(color: Colors.grey),
              ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _usarNuty(int index) async {
    if (_mochila == null || _email == null) return;

    final item = _mochila!.itens[index];
    if (item == null || item.quantidade <= 0) {
      _mostrarMensagem('Você não tem esse item!', erro: true);
      return;
    }

    final mascote = ref.read(mascoteProvider);
    if (mascote == null) {
      _mostrarMensagem('Selecione um mascote primeiro!', erro: true);
      return;
    }

    // Usa o Nuty para dar XP
    final resultado = await ref.read(criadouroProvider.notifier).usarNuty();

    if (resultado != null) {
      // Remove 1 unidade do item
      final novoItem = item.copyWith(quantidade: item.quantidade - 1);
      final mochilaNova = _mochila!.atualizarItem(index, novoItem);

      // Salva a mochila atualizada
      if (mounted) {
        await MochilaService.salvarMochila(context, _email!, mochilaNova);
      }

      setState(() {
        _mochila = mochilaNova;
      });

      // Mostra mensagem de XP ganho
      String mensagem = '${mascote.nome} ganhou +${resultado.xpGanho} XP!';
      if (resultado.subiuNivel) {
        mensagem += ' 🎉 Subiu de nível!';
      }
      _mostrarMensagem(mensagem);
    }
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
