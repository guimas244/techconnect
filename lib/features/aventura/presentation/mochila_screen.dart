import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_consumivel.dart';
import '../models/mochila.dart';
import '../models/historia_jogador.dart';
import 'modal_cura_obtida.dart';
import '../providers/aventura_provider.dart';
import '../services/mochila_service.dart';
import 'modal_item_consumivel.dart';
import '../../auth/providers/auth_provider.dart';

class MochilaScreen extends ConsumerStatefulWidget {
  final HistoriaJogador? historiaInicial;
  final void Function(HistoriaJogador historiaAtualizada)? onHistoriaAtualizada;

  const MochilaScreen({
    super.key,
    this.historiaInicial,
    this.onHistoriaAtualizada,
  });

  @override
  ConsumerState<MochilaScreen> createState() => _MochilaScreenState();
}

class _MochilaScreenState extends ConsumerState<MochilaScreen> {
  // Tamanho da mochila (6x5 = 30 slots)
  static const int colunas = 6;
  static const int linhas = 5;

  Mochila? mochila;
  bool isLoading = true;

  HistoriaJogador? historiaAtual;

  @override
  void initState() {
    super.initState();
    historiaAtual = widget.historiaInicial;
    _carregarMochila();
    _carregarHistoria();
  }

  @override
  void didUpdateWidget(covariant MochilaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.historiaInicial != null && widget.historiaInicial != oldWidget.historiaInicial) {
      setState(() {
        historiaAtual = widget.historiaInicial;
      });
    }
  }

  Future<void> _carregarMochila() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) {
      setState(() => isLoading = false);
      return;
    }

    final mochilaCarregada = await MochilaService.carregarMochila(
      context,
      user.email!,
    );

    if (mounted) {
      setState(() {
        mochila = mochilaCarregada ?? Mochila();
        isLoading = false;
      });
    }
  }

  Future<void> _salvarMochila() async {
    if (mochila == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    await MochilaService.salvarMochila(
      context,
      user.email!,
      mochila!,
    );
  }

  Future<void> _carregarHistoria() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) {
      return;
    }

    try {
      final repository = ref.read(aventuraRepositoryProvider);
      final historia = await repository.carregarHistoricoJogador(user.email!);
      if (!mounted) return;
      if (historia != null) {
        setState(() {
          historiaAtual = historia;
        });
        // NÃO chama onHistoriaAtualizada aqui - apenas ao USAR um item, não ao CARREGAR
        print('[MochilaScreen] Historia carregada do Hive (sem callback)');
      }
    } catch (e) {
      print('[MochilaScreen] Erro ao carregar historia: $e');
    }
  }

  Future<bool> _garantirHistoriaCarregada() async {
    if (historiaAtual != null) {
      return true;
    }
    await _carregarHistoria();
    return historiaAtual != null;
  }

  void _mostrarDetalhesItem(ItemConsumivel item, int index) {
    showDialog(
      context: context,
      builder: (context) => ModalItemConsumivel(
        item: item,
        onUsar: () {
          _usarItem(index);
        },
        onDescartar: () {
          _descartarItem(index);
        },
      ),
    );
  }

  Future<void> _usarItem(int index) async {
    if (mochila == null) return;

    final item = mochila!.itens[index];
    if (item == null) return;

    if (item.tipo == TipoItemConsumivel.pocao) {
      await _usarPocao(index, item);
      return;
    }

    await _consumirItem(index, item, mensagem: '${item.nome} usado!');
  }

  Future<void> _usarPocao(int index, ItemConsumivel item) async {
    final porcentagem = _obterPorcentagemCura(item);
    if (porcentagem == null) {
      _mostrarSnack('Nao foi possivel identificar o efeito desta pocao.', erro: true);
      return;
    }

    final carregado = await _garantirHistoriaCarregada();
    if (!carregado || historiaAtual == null) {
      _mostrarSnack('Nao foi possivel carregar o time para usar a pocao.', erro: true);
      return;
    }

    if (historiaAtual!.monstros.isEmpty) {
      _mostrarSnack('Nenhum monstro disponivel para receber a cura.', erro: true);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalCuraObtida(
        porcentagem: porcentagem,
        monstrosDisponiveis: historiaAtual!.monstros,
        onCurarMonstro: (monstro, porcentagemCura) async {
          final curaTotal = (monstro.vida * porcentagemCura / 100).round();
          final novaVidaAtual = (monstro.vidaAtual + curaTotal).clamp(0, monstro.vida);

          final monstrosAtualizados = historiaAtual!.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(vidaAtual: novaVidaAtual);
            }
            return m;
          }).toList();

          final historiaAtualizada = historiaAtual!.copyWith(monstros: monstrosAtualizados);

          await _salvarHistoria(historiaAtualizada);

          if (!mounted) return;

          setState(() {
            historiaAtual = historiaAtualizada;
          });

          await _consumirItem(
            index,
            item,
            mensagem: '${monstro.nome} recuperou $curaTotal de vida com ${item.nome}!',
          );
        },
      ),
    );
  }

  int? _obterPorcentagemCura(ItemConsumivel item) {
    switch (item.id) {
      case 'pocaoVidaPequena':
        return 25;
      case 'pocaoVidaGrande':
        return 100;
    }

    final regex = RegExp(r'(\d+)%');
    final match = regex.firstMatch(item.descricao);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  Future<void> _consumirItem(int index, ItemConsumivel item, {String? mensagem}) async {
    if (mochila == null) return;

    final quantidadeRestante = item.quantidade - 1;

    setState(() {
      if (quantidadeRestante > 0) {
        mochila = mochila!.atualizarItem(index, item.copyWith(quantidade: quantidadeRestante));
      } else {
        mochila = mochila!.removerItem(index);
      }
    });

    await _salvarMochila();

    if (mounted && mensagem != null && mensagem.isNotEmpty) {
      _mostrarSnack(mensagem);
    }
  }

  Future<void> _salvarHistoria(HistoriaJogador historia) async {
    final repository = ref.read(aventuraRepositoryProvider);
    try {
      // Salva APENAS no Hive local (sem sincronizar com Drive ao usar item da mochila)
      await repository.salvarHistoricoJogadorLocal(historia);
      widget.onHistoriaAtualizada?.call(historia);
      print('[MochilaScreen] Historia salva localmente (APENAS HIVE)');
    } catch (e) {
      print('[MochilaScreen] Erro ao salvar historia: $e');
      _mostrarSnack('Erro ao atualizar aventura. Tente novamente.', erro: true);
      rethrow;
    }
  }

  void _mostrarSnack(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _descartarItem(int index) async {
    if (mochila == null) return;

    final item = mochila!.itens[index];
    if (item == null) return;

    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Descarte'),
        content: Text('Deseja realmente descartar ${item.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirma == true && mounted) {
      setState(() {
        mochila = mochila!.removerItem(index);
      });

      await _salvarMochila();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item descartado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade900.withOpacity(0.95),
              Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    if (mochila == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade900.withOpacity(0.95),
              Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar mochila',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregarMochila,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.brown.shade900.withOpacity(0.95),
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: Colors.brown.shade700,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                // Ícone da mochila
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade800,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.brown.shade600,
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/icons_gerais/mochila.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.backpack,
                        size: 32,
                        color: Colors.white,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Info da mochila
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MOCHILA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${mochila!.itensOcupados}/${mochila!.slotsDesbloqueados} slots',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber.shade300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botão de organizar (futuro)
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Função de organizar em breve!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sort),
                  color: Colors.white70,
                  tooltip: 'Organizar itens',
                ),
              ],
            ),
          ),

          // Grid de itens
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: colunas,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: Mochila.totalSlots,
                itemBuilder: (context, index) {
                  final item = mochila!.itens[index];
                  final isBloqueado = index >= mochila!.slotsDesbloqueados;
                  return _buildSlot(item, index, isBloqueado);
                },
              ),
            ),
          ),

          // Legenda de raridades
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              border: Border(
                top: BorderSide(
                  color: Colors.brown.shade700,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendaRaridade(RaridadeConsumivel.inferior),
                const SizedBox(width: 12),
                _buildLegendaRaridade(RaridadeConsumivel.comum),
                const SizedBox(width: 12),
                _buildLegendaRaridade(RaridadeConsumivel.raro),
                const SizedBox(width: 12),
                _buildLegendaRaridade(RaridadeConsumivel.epico),
                const SizedBox(width: 12),
                _buildLegendaRaridade(RaridadeConsumivel.lendario),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(ItemConsumivel? item, int index, bool isBloqueado) {
    // Slot bloqueado
    if (isBloqueado) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.brown.shade900,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.lock,
            color: Colors.brown.shade800,
            size: 32,
          ),
        ),
      );
    }

    final isEmpty = item == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty ? null : () => _mostrarDetalhesItem(item, index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isEmpty
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEmpty
                  ? Colors.brown.shade800.withOpacity(0.5)
                  : item.raridade.cor,
              width: isEmpty ? 1 : 2,
            ),
            boxShadow: isEmpty
                ? null
                : [
                    BoxShadow(
                      color: item.raridade.cor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: isEmpty
              ? Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.brown.shade800.withOpacity(0.3),
                    size: 20,
                  ),
                )
              : Stack(
                  children: [
                    // Ícone do item
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: item.iconPath.isEmpty
                            ? Icon(
                                _getIconForType(item.tipo),
                                size: 30,
                                color: item.raridade.cor,
                              )
                            : Image.asset(
                                item.iconPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getIconForType(item.tipo),
                                    size: 30,
                                    color: item.raridade.cor,
                                  );
                                },
                              ),
                      ),
                    ),

                    // Badge de quantidade
                    if (item.quantidade > 1)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.raridade.cor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${item.quantidade}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.raridade.cor,
                            ),
                          ),
                        ),
                      ),

                    // Ícone de tipo (canto superior esquerdo)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(item.tipo),
                          size: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLegendaRaridade(RaridadeConsumivel raridade) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: raridade.cor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: raridade.cor.withOpacity(0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(TipoItemConsumivel tipo) {
    switch (tipo) {
      case TipoItemConsumivel.pocao:
        return Icons.local_drink;
      case TipoItemConsumivel.joia:
        return Icons.diamond;
      case TipoItemConsumivel.pergaminho:
        return Icons.article;
      case TipoItemConsumivel.elixir:
        return Icons.science;
      case TipoItemConsumivel.fragmento:
        return Icons.broken_image;
    }
  }
}