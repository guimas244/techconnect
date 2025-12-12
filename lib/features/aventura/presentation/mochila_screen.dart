import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
import '../models/monstro_aventura.dart';
import '../models/item.dart';
import '../models/progresso_diario.dart';
import '../../../shared/models/tipo_enum.dart';
import 'modal_nuty_negra_utilizada.dart';
import '../providers/progresso_bonus_provider.dart';
import '../services/colecao_service.dart';

class MochilaScreen extends ConsumerStatefulWidget {
  final HistoriaJogador? historiaInicial;
  final void Function(HistoriaJogador historiaAtualizada)? onHistoriaAtualizada;
  final VoidCallback? onChaveAutoUsada;

  const MochilaScreen({
    super.key,
    this.historiaInicial,
    this.onHistoriaAtualizada,
    this.onChaveAutoUsada,
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
                          item.tipo != TipoItemConsumivel.moedaEvento &&
                          item.tipo != TipoItemConsumivel.chaveAuto &&
                          item.tipo != TipoItemConsumivel.jaulinha;
    // Moeda de evento não pode ser usada, apenas ovos, chaves e chave auto (se quantidade > 0)
    final podeUsar = item.tipo != TipoItemConsumivel.moedaEvento && item.quantidade > 0;

    // Verifica se é item que usa seletor de quantidade
    final usaSeletorQuantidade = item.tipo == TipoItemConsumivel.ovoEvento ||
                                  item.tipo == TipoItemConsumivel.moedaChave;

    showDialog(
      context: context,
      builder: (context) => ModalItemConsumivel(
        item: item,
        onUsar: podeUsar && !usaSeletorQuantidade ? () {
          _usarItem(index);
        } : null,
        onUsarComQuantidade: podeUsar && usaSeletorQuantidade ? (quantidade) {
          if (item.tipo == TipoItemConsumivel.ovoEvento) {
            _usarOvoEvento(quantidade);
          } else if (item.tipo == TipoItemConsumivel.moedaChave) {
            _usarMoedaChave(quantidade);
          }
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

    print('🔍 [MochilaScreen] Usando item: ${item.nome} (ID: ${item.id}, Tipo: ${item.tipo.name}, Raridade: ${item.raridade.name})');

    if (item.tipo == TipoItemConsumivel.pocao) {
      await _usarPocao(index, item);
      return;
    }

    if (item.tipo == TipoItemConsumivel.joia) {
      // Distingue entre Joia da Recriação (lendária) e Joia de Reforço (épica)
      if (item.raridade == RaridadeConsumivel.lendario) {
        await _usarJoiaRecriacao(index, item);
      } else {
        await _usarJoiaReforco(index, item);
      }
      return;
    }

    if (item.tipo == TipoItemConsumivel.fruta) {
      print('🍇 [MochilaScreen] Item é FRUTA, raridade: ${item.raridade.name}, ID: ${item.id}');
      // Distingue entre Fruta Nuty (lendária), Fruta Nuty Cristalizada (épica) e Fruta Nuty Negra (épica)
      if (item.raridade == RaridadeConsumivel.lendario) {
        print('🥥 [MochilaScreen] Chamando _usarFrutaNuty (lendário)');
        await _usarFrutaNuty(index, item);
      } else {
        print('🍇 [MochilaScreen] Fruta épica detectada, verificando ID...');
        // Distingue entre Nuty Cristalizada e Nuty Negra pelo ID
        if (item.id == 'frutaNutyNegra') {
          print('🖤 [MochilaScreen] ID é frutaNutyNegra - Chamando _usarFrutaNutyNegra');
          await _usarFrutaNutyNegra(index, item);
        } else {
          print('💎 [MochilaScreen] ID é ${item.id} - Chamando _usarFrutaNutyCristalizada');
          await _usarFrutaNutyCristalizada(index, item);
        }
      }
      return;
    }

    if (item.tipo == TipoItemConsumivel.ovoEvento) {
      print('🥚 [MochilaScreen] Item é OVO EVENTO');
      await _usarOvoEvento(1);
      return;
    }

    if (item.tipo == TipoItemConsumivel.moedaChave) {
      print('🔑 [MochilaScreen] Item é MOEDA CHAVE');
      await _usarMoedaChave(1);
      return;
    }

    if (item.tipo == TipoItemConsumivel.chaveAuto) {
      print('🔑 [MochilaScreen] Item é CHAVE AUTO');
      await _usarChaveAuto();
      return;
    }

    if (item.tipo == TipoItemConsumivel.jaulinha) {
      print('🐾 [MochilaScreen] Item é JAULINHA');
      await _usarJaulinha();
      return;
    }

    print('❓ [MochilaScreen] Item não reconhecido, usando _consumirItem genérico');
    await _consumirItem(index, item, mensagem: '${item.nome} usado!');
  }

  Future<void> _usarOvoEvento(int quantidade) async {
    if (mochila == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    // Remove a quantidade de ovos
    final mochilaAtualizada = mochila!.removerOvoEvento(quantidade);
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
    final plural = quantidade > 1 ? 'Ovos do Evento usados' : 'Ovo do Evento usado';
    _mostrarSnack('$plural ($quantidade)! (Em breve: surpresa)');
  }

  Future<void> _usarMoedaChave(int quantidade) async {
    if (mochila == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    // Verifica se tem moedas chave suficientes
    final moedaChaveAtual = mochila!.itens[Mochila.slotMoedaChave];
    if (moedaChaveAtual == null || moedaChaveAtual.quantidade < quantidade) {
      _mostrarSnack('Você não tem moedas chave suficientes!', erro: true);
      return;
    }

    // Remove a quantidade de moedas chave
    final novaQuantidade = moedaChaveAtual.quantidade - quantidade;
    final novosItens = List<ItemConsumivel?>.from(mochila!.itens);

    if (novaQuantidade <= 0) {
      novosItens[Mochila.slotMoedaChave] = null;
    } else {
      novosItens[Mochila.slotMoedaChave] = moedaChaveAtual.copyWith(quantidade: novaQuantidade);
    }

    final mochilaAtualizada = mochila!.copyWith(itens: novosItens);

    // Salva mochila
    setState(() {
      mochila = mochilaAtualizada;
    });

    await MochilaService.salvarMochila(context, user.email!, mochilaAtualizada);

    // TODO: Adicionar aqui a lógica de usar a moeda chave
    final plural = quantidade > 1 ? 'Moedas Chave usadas' : 'Moeda Chave usada';
    _mostrarSnack('$plural ($quantidade)! (Em breve: recompensa)');
  }

  Future<void> _usarChaveAuto() async {
    if (mochila == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    // Verifica se tem chave auto
    final chaveAutoAtual = mochila!.itens[Mochila.slotChaveAuto];
    if (chaveAutoAtual == null || chaveAutoAtual.quantidade < 1) {
      _mostrarSnack('Você não tem Chaves Auto!', erro: true);
      return;
    }

    // Remove 1 chave auto
    final mochilaAtualizada = mochila!.removerChaveAuto(1);
    if (mochilaAtualizada == null) {
      _mostrarSnack('Erro ao usar Chave Auto!', erro: true);
      return;
    }

    // Salva mochila
    setState(() {
      mochila = mochilaAtualizada;
    });

    await MochilaService.salvarMochila(context, user.email!, mochilaAtualizada);

    _mostrarSnack('Chave Auto ativada! Modo automático por 2 andares.');

    // Notifica o pai (mapa_aventura_screen) para ativar o modo chave auto
    widget.onChaveAutoUsada?.call();
  }

  Future<void> _usarJaulinha() async {
    if (mochila == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    // Verifica se tem jaulinha
    final jaulinhaAtual = mochila!.itens[Mochila.slotJaulinha];
    if (jaulinhaAtual == null || jaulinhaAtual.quantidade < 1) {
      _mostrarSnack('Você não tem Jaulinhas!', erro: true);
      return;
    }

    // Carrega história para obter os monstros
    final carregado = await _garantirHistoriaCarregada();
    if (!carregado || historiaAtual == null) {
      _mostrarSnack('Erro ao carregar dados do jogador!', erro: true);
      return;
    }

    // Verifica se tem monstros na equipe
    if (historiaAtual!.monstros.isEmpty) {
      _mostrarSnack('Você não tem monstros na equipe!', erro: true);
      return;
    }

    // Carrega a coleção do jogador
    final colecaoService = ColecaoService();
    final colecao = await colecaoService.carregarColecaoJogador(user.email!);

    // Abre o modal de seleção de monstro e tipo
    if (!mounted) return;
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModalJaulinha(
        monstros: historiaAtual!.monstros,
        colecao: colecao,
        onConfirmar: (monstroIndex, novoTipo, colecaoEscolhida) async {
          // Aplica a mudança de tipo com a coleção escolhida
          await _aplicarMudancaTipo(monstroIndex, novoTipo, colecaoEscolhida);
        },
      ),
    );

    if (resultado == true) {
      // Remove 1 jaulinha
      final mochilaAtualizada = mochila!.removerJaulinha(1);
      if (mochilaAtualizada != null) {
        setState(() {
          mochila = mochilaAtualizada;
        });
        await MochilaService.salvarMochila(context, user.email!, mochilaAtualizada);
      }
    }
  }

  Future<void> _aplicarMudancaTipo(int monstroIndex, Tipo novoTipo, String colecaoEscolhida) async {
    if (historiaAtual == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;

    final monstro = historiaAtual!.monstros[monstroIndex];

    // Gera nova imagem baseada no novo tipo e coleção escolhida
    final novaImagem = 'assets/monstros_aventura/$colecaoEscolhida/${novoTipo.name}.png';

    // Cria o monstro com o novo tipo
    final monstroAtualizado = monstro.copyWith(
      tipo: novoTipo,
      imagem: novaImagem,
      // Se tipoExtra for igual ao novo tipo, sorteia outro
      tipoExtra: monstro.tipoExtra == novoTipo ? _sortearTipoDiferente(novoTipo) : monstro.tipoExtra,
    );

    // Atualiza a lista de monstros
    final novosMonstros = List<MonstroAventura>.from(historiaAtual!.monstros);
    novosMonstros[monstroIndex] = monstroAtualizado;

    // Atualiza a história
    final historiaAtualizada = historiaAtual!.copyWith(monstros: novosMonstros);

    // Salva no repositório
    final repository = ref.read(aventuraRepositoryProvider);
    await repository.salvarHistoricoJogadorLocal(historiaAtualizada);

    setState(() {
      historiaAtual = historiaAtualizada;
    });

    // Notifica o pai se tiver callback
    widget.onHistoriaAtualizada?.call(historiaAtualizada);

    _mostrarSnack('Tipo do monstro alterado para ${novoTipo.displayName}!');
  }

  Tipo _sortearTipoDiferente(Tipo tipoExcluir) {
    final tipos = Tipo.values.where((t) => t != tipoExcluir).toList();
    tipos.shuffle();
    return tipos.first;
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

  Future<void> _usarJoiaRecriacao(int index, ItemConsumivel item) async {
    final carregado = await _garantirHistoriaCarregada();
    if (!carregado || historiaAtual == null) {
      _mostrarSnack('Não foi possível carregar o time para usar a pedra.', erro: true);
      return;
    }

    if (historiaAtual!.monstros.isEmpty) {
      _mostrarSnack('Nenhum monstro disponível no time.', erro: true);
      return;
    }

    // Filtra apenas monstros que têm item equipado e que NÃO sejam impossíveis
    final monstrosComItem = historiaAtual!.monstros
        .where((m) => m.itemEquipado != null && m.itemEquipado!.raridade != RaridadeItem.impossivel)
        .toList();

    if (monstrosComItem.isEmpty) {
      _mostrarSnack('Nenhum monstro tem equipamento válido! (Itens Impossíveis são imutáveis)', erro: true);
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

          // Gera novo item mantendo a raridade mas com o tier atual do andar
          final itemRecriado = itemService.gerarItemComRaridade(
            itemAtual.raridade,
            tierAtual: historiaAtual!.tier,
          );

          // Atualiza o monstro com o item recriado
          final monstrosAtualizados = historiaAtual!.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
              return m.copyWith(itemEquipado: itemRecriado);
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
            mensagem: '${monstro.nome}: ${itemAtual.nome} (Tier ${itemAtual.tier}) -> ${itemRecriado.nome} (Tier ${itemRecriado.tier})!',
          );
        },
      ),
    );
  }

  Future<void> _usarJoiaReforco(int index, ItemConsumivel item) async {
    final carregado = await _garantirHistoriaCarregada();
    if (!carregado || historiaAtual == null) {
      _mostrarSnack('Não foi possível carregar o time para usar a joia.', erro: true);
      return;
    }

    if (historiaAtual!.monstros.isEmpty) {
      _mostrarSnack('Nenhum monstro disponível no time.', erro: true);
      return;
    }

    // Filtra apenas monstros que têm item equipado e que NÃO sejam impossíveis
    final monstrosComItem = historiaAtual!.monstros
        .where((m) => m.itemEquipado != null && m.itemEquipado!.raridade != RaridadeItem.impossivel)
        .toList();

    if (monstrosComItem.isEmpty) {
      _mostrarSnack('Nenhum monstro tem equipamento válido! (Itens Impossíveis são imutáveis)', erro: true);
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

          // Calcula o valor base (tier 1) dividindo os atributos pelo tier atual
          final atributosBase = <String, int>{};
          itemAtual.atributos.forEach((atributo, valor) {
            atributosBase[atributo] = (valor / itemAtual.tier).round();
          });

          // Multiplica pelo tier do andar atual para obter os novos atributos
          final novosAtributos = <String, int>{};
          atributosBase.forEach((atributo, valorBase) {
            novosAtributos[atributo] = valorBase * historiaAtual!.tier;
          });

          // Cria um novo item com os atributos ajustados
          final itemReforcado = itemAtual.copyWith(
            atributos: novosAtributos,
            tier: historiaAtual!.tier,
          );

          // Atualiza o monstro com o item reforçado
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
            mensagem: '${monstro.nome}: ${itemAtual.nome} reforçado de Tier ${itemAtual.tier} para Tier ${itemReforcado.tier}!',
          );
        },
      ),
    );
  }

  Future<void> _usarFrutaNuty(int index, ItemConsumivel item) async {
    final carregado = await _garantirHistoriaCarregada();
    if (!carregado || historiaAtual == null) {
      _mostrarSnack('Não foi possível carregar o time para usar a fruta.', erro: true);
      return;
    }

    if (historiaAtual!.monstros.isEmpty) {
      _mostrarSnack('Nenhum monstro disponível no time.', erro: true);
      return;
    }

    // Filtra apenas monstros de level 1
    final monstrosLevel1 = historiaAtual!.monstros.where((m) => m.level == 1).toList();

    if (monstrosLevel1.isEmpty) {
      _mostrarSnack('A Fruta Nuty só pode ser usada em monstros Level 1!', erro: true);
      return;
    }

    // Mostra modal para selecionar o monstro
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalSelecaoMonstroReforco(
        monstrosDisponiveis: monstrosLevel1,
        tierAtual: historiaAtual!.tier,
        onReforcarItem: (monstro) async {
          // Maximiza todos os atributos do monstro
          final monstroMaximizado = monstro.copyWith(
            vida: 150,  // Máximo de vida
            vidaAtual: 150,  // Cura para o máximo também
            energia: 40,  // Máximo de energia
            agilidade: 20,  // Máximo de agilidade
            ataque: 20,  // Máximo de ataque
            defesa: 60,  // Máximo de defesa
          );

          // Atualiza o monstro na lista
          final monstrosAtualizados = historiaAtual!.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
              return monstroMaximizado;
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
            mensagem: '${monstro.nome} teve todos seus atributos maximizados!',
          );
        },
      ),
    );
  }

  Future<void> _usarFrutaNutyCristalizada(int index, ItemConsumivel item) async {
    final carregado = await _garantirHistoriaCarregada();
    if (!carregado || historiaAtual == null) {
      _mostrarSnack('Não foi possível carregar o time para usar a fruta.', erro: true);
      return;
    }

    if (historiaAtual!.monstros.isEmpty) {
      _mostrarSnack('Nenhum monstro disponível no time.', erro: true);
      return;
    }

    // Pode ser usado em qualquer monstro (sem restrição de level)
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalSelecaoMonstroReforco(
        monstrosDisponiveis: historiaAtual!.monstros,
        tierAtual: historiaAtual!.tier,
        onReforcarItem: (monstro) async {
          // Sorteia um atributo aleatório para ganhar +10
          final random = Random();
          final atributos = ['vida', 'energia', 'agilidade', 'ataque', 'defesa'];
          final atributoSorteado = atributos[random.nextInt(atributos.length)];

          // Cria o monstro com o atributo sorteado aumentado
          late final MonstroAventura monstroAprimorado;
          late final String nomeAtributo;

          switch (atributoSorteado) {
            case 'vida':
              monstroAprimorado = monstro.copyWith(
                vida: monstro.vida + 10,
                vidaAtual: monstro.vidaAtual + 10, // Aumenta vida atual também
              );
              nomeAtributo = 'Vida';
              break;
            case 'energia':
              monstroAprimorado = monstro.copyWith(energia: monstro.energia + 10);
              nomeAtributo = 'Energia';
              break;
            case 'agilidade':
              monstroAprimorado = monstro.copyWith(agilidade: monstro.agilidade + 10);
              nomeAtributo = 'Agilidade';
              break;
            case 'ataque':
              monstroAprimorado = monstro.copyWith(ataque: monstro.ataque + 10);
              nomeAtributo = 'Ataque';
              break;
            case 'defesa':
              monstroAprimorado = monstro.copyWith(defesa: monstro.defesa + 10);
              nomeAtributo = 'Defesa';
              break;
          }

          // Atualiza o monstro na lista
          final monstrosAtualizados = historiaAtual!.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level && m.tipoExtra == monstro.tipoExtra) {
              return monstroAprimorado;
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
            mensagem: '${monstro.nome} ganhou +10 de $nomeAtributo!',
          );
        },
      ),
    );
  }

  Future<void> _usarFrutaNutyNegra(int index, ItemConsumivel item) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) {
      _mostrarSnack('Erro ao obter informações do jogador.', erro: true);
      return;
    }

    // Sorteia um tipo aleatório
    final random = Random();
    final tipos = Tipo.values.where((t) => t != Tipo.normal).toList();
    final tipoSorteado = tipos[random.nextInt(tipos.length)];

    print('🖤 [FrutaNutyNegra] Tipo sorteado: ${tipoSorteado.displayName} (${tipoSorteado.name})');

    // Carrega o progresso diário
    final prefs = await SharedPreferences.getInstance();
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final progressoJson = prefs.getString('progresso_diario');

    ProgressoDiario progresso;
    if (progressoJson != null) {
      progresso = ProgressoDiario.fromJson(
        Map<String, dynamic>.from(json.decode(progressoJson) as Map)
      );

      print('🖤 [FrutaNutyNegra] Progresso carregado - Kills antes: ${progresso.killsPorTipo}');

      // Verifica se precisa mudar o dia
      if (progresso.data != hoje) {
        print('🖤 [FrutaNutyNegra] Finalizando dia anterior (${progresso.data}) e iniciando novo dia ($hoje)');
        progresso = progresso.finalizarDia(hoje);
      }
    } else {
      print('🖤 [FrutaNutyNegra] Criando novo progresso diário');
      progresso = ProgressoDiario(data: hoje);
    }

    print('🖤 [FrutaNutyNegra] Kills do tipo ${tipoSorteado.name} ANTES: ${progresso.killsPorTipo[tipoSorteado.name] ?? 0}');

    // Adiciona 10 kills do tipo sorteado
    for (int i = 0; i < 10; i++) {
      progresso = progresso.adicionarKill(tipoSorteado);
    }

    print('🖤 [FrutaNutyNegra] Kills do tipo ${tipoSorteado.name} DEPOIS: ${progresso.killsPorTipo[tipoSorteado.name] ?? 0}');
    print('🖤 [FrutaNutyNegra] Total de kills no dia: ${progresso.totalKills}');
    print('🖤 [FrutaNutyNegra] Todos os kills: ${progresso.killsPorTipo}');

    // Salva o progresso atualizado
    await prefs.setString(
      'progresso_diario',
      json.encode(progresso.toJson()),
    );

    print('🖤 [FrutaNutyNegra] Progresso salvo com sucesso!');

    // Recarrega os bônus para refletir os novos kills
    await ref.read(progressoBonusStateProvider.notifier).reload();

    // Mostra modal informando qual tipo ganhou os kills
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalNutyNegraUtilizada(
        tipoSorteado: tipoSorteado,
        onContinuar: () => Navigator.of(context).pop(),
      ),
    );

    // Consome o item
    await _consumirItem(
      index,
      item,
      mensagem: '+10 kills de ${tipoSorteado.displayName} adicionados!',
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
                const SizedBox(width: 12),
                _buildLegendaRaridade(RaridadeConsumivel.impossivel),
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
                        return Image.asset(
                          'assets/eventos/halloween/ovo_halloween.png',
                          fit: BoxFit.contain,
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

    // Slot de moeda chave (index 27 - 4º da linha 5) - sempre visível, clicável para detalhes
    if (index == Mochila.slotMoedaChave) {
      final moeda = item;
      final quantidade = moeda?.quantidade ?? 0;

      // Cria item temporário se não existir (para permitir clique mesmo com quantidade 0)
      final moedaParaMostrar = moeda ?? ItemConsumivel(
        id: 'moeda_chave',
        nome: 'Moeda Chave',
        descricao: 'Moeda especial em formato de chave. Muito rara!',
        tipo: TipoItemConsumivel.moedaChave,
        iconPath: 'assets/eventos/halloween/moeda_chave.png',
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
                color: const Color(0xFFFFD700), // Dourado para a chave
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Imagem da moeda chave
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/eventos/halloween/moeda_chave.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.key,
                          size: 30,
                          color: Color(0xFFFFD700),
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
                          const Color(0xFFFFD700),
                          const Color(0xFFFFE55C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFFF9C4),
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
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Slot de chave auto (index 28 - 5º da linha 5) - sempre visível, clicável para detalhes
    if (index == Mochila.slotChaveAuto) {
      final chave = item;
      final quantidade = chave?.quantidade ?? 0;

      // Cria item temporário se não existir (para permitir clique mesmo com quantidade 0)
      final chaveParaMostrar = chave ?? ItemConsumivel(
        id: 'chave_auto',
        nome: 'Chave Auto',
        descricao: 'Chave mecânica que ativa o modo automático por 2 andares. Não usa consumíveis durante o auto.',
        tipo: TipoItemConsumivel.chaveAuto,
        iconPath: 'assets/eventos/halloween/chave_auto.png',
        quantidade: 0,
        raridade: RaridadeConsumivel.lendario,
      );

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDetalhesItem(chaveParaMostrar, index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00BCD4), // Ciano para a chave auto
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Imagem da chave auto
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/eventos/halloween/chave_auto.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.vpn_key,
                          size: 30,
                          color: Color(0xFF00BCD4),
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
                          const Color(0xFF00BCD4),
                          const Color(0xFF4DD0E1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFB2EBF2),
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
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Slot de jaulinha (index 29 - 6º da linha 5) - sempre visível, clicável para detalhes
    if (index == Mochila.slotJaulinha) {
      final jaulinha = item;
      final quantidade = jaulinha?.quantidade ?? 0;

      // Cria item temporário se não existir (para permitir clique mesmo com quantidade 0)
      final jaulinhaParaMostrar = jaulinha ?? ItemConsumivel(
        id: 'jaulinha',
        nome: 'Jaulinha',
        descricao: 'Permite mudar o tipo principal de um monstro. Selecione um monstro e escolha seu novo tipo!',
        tipo: TipoItemConsumivel.jaulinha,
        iconPath: 'assets/eventos/halloween/jaulinha.png',
        quantidade: 0,
        raridade: RaridadeConsumivel.impossivel,
      );

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDetalhesItem(jaulinhaParaMostrar, index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFD32F2F), // Vermelho para a jaulinha (impossível)
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Imagem da jaulinha
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/eventos/halloween/jaulinha.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.pets,
                          size: 30,
                          color: Color(0xFFD32F2F),
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
                          const Color(0xFFD32F2F),
                          const Color(0xFFE57373),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFFCDD2),
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
                      color: Color(0xFFD32F2F),
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
                                  // Se for ovo, usa a imagem PNG sempre
                                  if (item.tipo == TipoItemConsumivel.ovoEvento) {
                                    return Image.asset(
                                      'assets/eventos/halloween/ovo_halloween.png',
                                      fit: BoxFit.contain,
                                    );
                                  }
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
                        child: item.tipo == TipoItemConsumivel.ovoEvento
                            ? Image.asset(
                                'assets/eventos/halloween/ovo_halloween.png',
                                width: 12,
                                height: 12,
                              )
                            : Icon(
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
      case TipoItemConsumivel.fruta:
        return Icons.apple;
      case TipoItemConsumivel.vidinha:
        return Icons.favorite;
      case TipoItemConsumivel.pergaminho:
        return Icons.article;
      case TipoItemConsumivel.elixir:
        return Icons.science;
      case TipoItemConsumivel.fragmento:
        return Icons.broken_image;
      case TipoItemConsumivel.moedaEvento:
      case TipoItemConsumivel.moedaHalloween:
        return Icons.stars;
      case TipoItemConsumivel.moedaChave:
        return Icons.key;
      case TipoItemConsumivel.ovoEvento:
        return Icons.egg;
      case TipoItemConsumivel.chaveAuto:
        return Icons.vpn_key;
      case TipoItemConsumivel.jaulinha:
        return Icons.pets;
    }
  }
}

/// Modal para usar a Jaulinha - seleciona monstro e novo tipo
class _ModalJaulinha extends StatefulWidget {
  final List<MonstroAventura> monstros;
  final Future<void> Function(int monstroIndex, Tipo novoTipo, String colecaoEscolhida) onConfirmar;
  final Map<String, bool> colecao;

  const _ModalJaulinha({
    required this.monstros,
    required this.onConfirmar,
    required this.colecao,
  });

  @override
  State<_ModalJaulinha> createState() => _ModalJaulinhaState();
}

class _ModalJaulinhaState extends State<_ModalJaulinha> {
  int? _monstroSelecionado;
  Tipo? _tipoSelecionado;
  String? _colecaoSelecionada; // Qual coleção específica foi selecionada (ex: colecao_inicial, colecao_nostalgicos)
  Tipo? _tipoExpandido; // Tipo atualmente expandido para mostrar monstros
  bool _processando = false;

  // Índice atual de imagem para cada tipo (para animação de alternância)
  final Map<Tipo, int> _indiceImagemPorTipo = {};

  // Lista de tipos disponíveis (exclui alguns tipos especiais)
  final List<Tipo> _tiposDisponiveis = Tipo.values.where((t) =>
    t != Tipo.desconhecido && t != Tipo.deus
  ).toList();

  @override
  void initState() {
    super.initState();
    // Inicia timer para alternar imagens
    _iniciarAlternanciaImagens();
  }

  void _iniciarAlternanciaImagens() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          // Avança o índice de cada tipo
          for (final tipo in _tiposDisponiveis) {
            final monstros = _getMonstrosDesbloqueadosPorTipo(tipo);
            if (monstros.length > 1) {
              final indiceAtual = _indiceImagemPorTipo[tipo] ?? 0;
              _indiceImagemPorTipo[tipo] = (indiceAtual + 1) % monstros.length;
            }
          }
        });
        _iniciarAlternanciaImagens();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade900,
              Colors.brown.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD32F2F),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/eventos/halloween/jaulinha.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pets,
                      color: Color(0xFFD32F2F),
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jaulinha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mude o tipo do seu monstro!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Corpo
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Etapa 1: Selecionar monstro para sacrificar
                    const Text(
                      '1. Selecione o monstro a transformar:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSeletorMonstros(),

                    // Só mostra etapa 2 se selecionou monstro
                    if (_monstroSelecionado != null) ...[
                      const SizedBox(height: 24),

                      // Etapa 2: Selecionar tipo (clique para expandir)
                      const Text(
                        '2. Escolha o novo tipo:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Clique em um tipo para ver os monstros disponíveis',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSeletorTiposExpandivel(),
                    ],
                  ],
                ),
              ),
            ),

            // Botão confirmar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _podeConfirmar() ? _confirmar : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _processando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _tipoSelecionado != null && _colecaoSelecionada != null
                                  ? 'TRANSFORMAR EM ${_tipoSelecionado!.displayName.toUpperCase()} (${_getColecaoLabel(_colecaoSelecionada!)})'
                                  : _monstroSelecionado != null
                                      ? 'SELECIONE UM MONSTRO ACIMA'
                                      : 'SELECIONE O MONSTRO A TRANSFORMAR',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorMonstros() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(widget.monstros.length, (index) {
        final monstro = widget.monstros[index];
        final selecionado = _monstroSelecionado == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _monstroSelecionado = index;
              // Limpa seleção de tipo e coleção ao trocar monstro
              _tipoSelecionado = null;
              _colecaoSelecionada = null;
              _tipoExpandido = null;
            });
          },
          child: Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selecionado
                  ? const Color(0xFFD32F2F).withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selecionado ? const Color(0xFFD32F2F) : Colors.white24,
                width: selecionado ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    monstro.imagem,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey,
                      child: const Icon(Icons.pets, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monstro.tipo.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSeletorTiposExpandivel() {
    return Column(
      children: _tiposDisponiveis.map((tipo) {
        final expandido = _tipoExpandido == tipo;
        // Verifica se algum monstro DESTE tipo está selecionado
        final tipoTemSelecao = _tipoSelecionado == tipo && _colecaoSelecionada != null;
        final monstrosDesbloqueados = _getMonstrosDesbloqueadosPorTipo(tipo);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: tipoTemSelecao
                ? const Color(0xFFD32F2F).withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tipoTemSelecao ? const Color(0xFFD32F2F) : Colors.white24,
              width: tipoTemSelecao ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header do tipo (clicável para expandir)
              InkWell(
                onTap: () {
                  setState(() {
                    if (_tipoExpandido == tipo) {
                      _tipoExpandido = null;
                    } else {
                      _tipoExpandido = tipo;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Imagem do tipo (alterna entre monstros desbloqueados)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Image.asset(
                            _getImagemAtualPorTipo(tipo, monstrosDesbloqueados),
                            key: ValueKey(_getImagemAtualPorTipo(tipo, monstrosDesbloqueados)),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.pets, color: Colors.white54, size: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nome do tipo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tipo.displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: tipoTemSelecao ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${monstrosDesbloqueados.length} monstro${monstrosDesbloqueados.length != 1 ? 's' : ''} disponível${monstrosDesbloqueados.length != 1 ? 'is' : ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ícone de expandir/retrair
                      Icon(
                        expandido ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              // Grid de monstros desbloqueados (quando expandido)
              if (expandido)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: monstrosDesbloqueados.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            'Nenhum monstro deste tipo desbloqueado na coleção',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: monstrosDesbloqueados.map((monstroInfo) {
                            final colecao = monstroInfo['colecao'] as String;
                            final nomeArquivo = monstroInfo['arquivo'] as String;
                            // Verifica se ESTE monstro específico está selecionado
                            final isSelected = _tipoSelecionado == tipo && _colecaoSelecionada == colecao;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tipoSelecionado = tipo;
                                  _colecaoSelecionada = colecao;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFD32F2F).withOpacity(0.4)
                                      : Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFD32F2F)
                                        : Colors.white24,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.asset(
                                        'assets/monstros_aventura/$colecao/$nomeArquivo.png',
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 45,
                                          height: 45,
                                          color: Colors.grey.shade800,
                                          child: const Icon(Icons.pets, color: Colors.white54, size: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getColecaoLabel(colecao),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                        fontSize: 8,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Retorna lista de monstros desbloqueados para um tipo específico
  List<Map<String, String>> _getMonstrosDesbloqueadosPorTipo(Tipo tipo) {
    final List<Map<String, String>> monstros = [];

    // Coleção inicial - sempre desbloqueada
    monstros.add({
      'colecao': 'colecao_inicial',
      'arquivo': tipo.name,
    });

    // Coleção nostálgica - verifica no mapa de coleção
    if (widget.colecao[tipo.name] == true) {
      monstros.add({
        'colecao': 'colecao_nostalgicos',
        'arquivo': tipo.name,
      });
    }

    // Coleção Halloween - verifica com prefixo halloween_
    if (widget.colecao['halloween_${tipo.name}'] == true) {
      monstros.add({
        'colecao': 'colecao_halloween',
        'arquivo': tipo.name,
      });
    }

    return monstros;
  }

  /// Retorna o caminho da imagem atual para um tipo (com alternância)
  String _getImagemAtualPorTipo(Tipo tipo, List<Map<String, String>> monstrosDesbloqueados) {
    if (monstrosDesbloqueados.isEmpty) {
      return 'assets/monstros_aventura/colecao_inicial/${tipo.name}.png';
    }

    final indice = _indiceImagemPorTipo[tipo] ?? 0;
    final monstroAtual = monstrosDesbloqueados[indice % monstrosDesbloqueados.length];
    final colecao = monstroAtual['colecao']!;
    final arquivo = monstroAtual['arquivo']!;

    return 'assets/monstros_aventura/$colecao/$arquivo.png';
  }

  String _getColecaoLabel(String colecao) {
    switch (colecao) {
      case 'colecao_inicial':
        return 'Inicial';
      case 'colecao_nostalgicos':
        return 'Nostálgico';
      case 'colecao_halloween':
        return 'Halloween';
      default:
        return colecao;
    }
  }

  bool _podeConfirmar() {
    return _monstroSelecionado != null &&
           _tipoSelecionado != null &&
           _colecaoSelecionada != null &&
           !_processando;
  }

  Future<void> _confirmar() async {
    if (!_podeConfirmar()) return;

    setState(() {
      _processando = true;
    });

    try {
      await widget.onConfirmar(_monstroSelecionado!, _tipoSelecionado!, _colecaoSelecionada!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }
}