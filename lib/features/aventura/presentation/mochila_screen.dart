import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_consumivel.dart';
import '../models/mochila.dart';
import '../models/historia_jogador.dart';
import 'modal_cura_obtida.dart';
import '../providers/aventura_provider.dart';
import '../services/mochila_service.dart';
import 'modal_item_consumivel.dart';
import 'modal_selecao_monstro_reforco.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/item_service.dart';

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
    // Verifica se é item permanente de evento (não pode ser descartado)
    final podeDescartar = item.tipo != TipoItemConsumivel.ovoEvento &&
                          item.tipo != TipoItemConsumivel.moedaEvento;
    // Verifica se pode usar (apenas se quantidade > 0)
    final podeUsar = item.quantidade > 0;

    showDialog(
      context: context,
      builder: (context) => ModalItemConsumivel(
        item: item,
        onUsar: podeUsar ? () {
          _usarItem(index);
        } : null,
        onDescartar: podeDescartar ? () {
          _descartarItem(index);
        } : null,
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

    if (item.tipo == TipoItemConsumivel.joia) {
      await _usarPedraReforco(index, item);
      return;
    }

    if (item.tipo == TipoItemConsumivel.ovoEvento) {
      await _usarOvoEvento();
      return;
    }

    await _consumirItem(index, item, mensagem: '${item.nome} usado!');
  }

  Future<void> _usarOvoEvento() async {
    if (mochila == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    // Remove 1 ovo
    final mochilaAtualizada = mochila!.removerOvoEvento(1);
    if (mochilaAtualizada == null) {
      _mostrarSnack('Você não tem ovos suficientes!', erro: true);
      return;
    }

    // Salva mochila
    setState(() {
      mochila = mochilaAtualizada;
    });

    await MochilaService.salvarMochila(context, user.email!, mochilaAtualizada);

    // TODO: Adicionar aqui a lógica de usar o ovo (abrir surpresa, etc)
    _mostrarSnack('Ovo do Evento usado! (Em breve: surpresa)');
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

          // Fecha o modal
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _usarPedraReforco(int index, ItemConsumivel item) async {
    final carregado = await _garantirHistoriaCarregada();
    if (!carregado || historiaAtual == null) {
      _mostrarSnack('Não foi possível carregar o time para usar a pedra.', erro: true);
      return;
    }

    if (historiaAtual!.monstros.isEmpty) {
      _mostrarSnack('Nenhum monstro disponível no time.', erro: true);
      return;
    }

    // Filtra apenas monstros que têm item equipado
    final monstrosComItem = historiaAtual!.monstros.where((m) => m.itemEquipado != null).toList();

    if (monstrosComItem.isEmpty) {
      _mostrarSnack('Nenhum monstro tem equipamento para reforçar!', erro: true);
      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalSelecaoMonstroReforco(
        monstrosDisponiveis: monstrosComItem,
        tierAtual: historiaAtual!.tier,
        onReforcarItem: (monstro) async {
          final itemAtual = monstro.itemEquipado!;
          final itemService = ItemService();

          // Gera novo item com o tier atual mantendo a raridade
          final itemReforcado = itemService.gerarItemComRaridade(
            itemAtual.raridade,
            tierAtual: historiaAtual!.tier,
          );

          // Atualiza o monstro com o item reforcado
          final monstrosAtualizados = historiaAtual!.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
              return m.copyWith(itemEquipado: itemReforcado);
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
            mensagem: '${monstro.nome}: ${itemAtual.nome} (Tier ${itemAtual.tier}) -> ${itemReforcado.nome} (Tier ${itemReforcado.tier})!',
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
    // Slot de ovo de evento (index 4) - sempre visível, clicável para detalhes
    if (index == Mochila.slotOvoEvento) {
      final ovo = item;
      final quantidade = ovo?.quantidade ?? 0;

      // Cria item temporário se não existir (para permitir clique mesmo com quantidade 0)
      final ovoParaMostrar = ovo ?? ItemConsumivel(
        id: 'ovo_evento',
        nome: 'Ovo do Evento',
        descricao: 'Ovo especial de evento que pode ser usado para surpresas!',
        tipo: TipoItemConsumivel.ovoEvento,
        iconPath: 'assets/eventos/halloween/ovo_halloween.png',
        quantidade: 0,
        raridade: RaridadeConsumivel.lendario,
      );

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDetalhesItem(ovoParaMostrar, index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF9800), // Laranja lendário
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Imagem do ovo
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/eventos/halloween/ovo_halloween.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.egg,
                          size: 30,
                          color: Color(0xFF9C27B0),
                        );
                      },
                    ),
                  ),
                ),

                // Badge de quantidade estilo estrela de level
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF9800),
                          const Color(0xFFFFB74D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFFE0B2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '$quantidade',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Ícone de permanente (canto superior esquerdo)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 12,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Slot de moeda de evento (index 3) - sempre visível, clicável para detalhes
    if (index == Mochila.slotMoedaEvento) {
      final moeda = item;
      final quantidade = moeda?.quantidade ?? 0;

      // Cria item temporário se não existir (para permitir clique mesmo com quantidade 0)
      final moedaParaMostrar = moeda ?? ItemConsumivel(
        id: 'moeda_evento',
        nome: 'Moeda de Evento',
        descricao: 'Moeda especial de evento usada na roleta de sorteio!',
        tipo: TipoItemConsumivel.moedaEvento,
        iconPath: 'assets/eventos/halloween/moeda_halloween.png',
        quantidade: 0,
        raridade: RaridadeConsumivel.lendario,
      );

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDetalhesItem(moedaParaMostrar, index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF9800), // Laranja lendário
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
          children: [
            // Imagem da moeda
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/eventos/halloween/moeda_halloween.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.stars,
                      size: 30,
                      color: Color(0xFFFF9800),
                    );
                  },
                ),
              ),
            ),

            // Badge de quantidade estilo estrela de level
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800),
                      const Color(0xFFFFB74D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFFE0B2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Text(
                  '$quantidade',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Ícone de permanente (canto superior esquerdo)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 12,
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      );
    }

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
      case TipoItemConsumivel.moedaEvento:
        return Icons.stars;
      case TipoItemConsumivel.ovoEvento:
        return Icons.egg;
    }
  }
}