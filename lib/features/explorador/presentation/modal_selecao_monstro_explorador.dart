import 'package:flutter/material.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/monstro_explorador.dart';

/// Modal de selecao de monstro para o Modo Explorador
/// Usa o mesmo padrao da Jaulinha: Tipo expansivel -> Monstro
/// Agora mostra monstros salvos primeiro (com XP/level) e depois novos monstros
class ModalSelecaoMonstroExplorador extends StatefulWidget {
  final Map<String, bool> colecao;
  final Set<Tipo> tiposJaUsados; // Tipos que ja estao na equipe (nao podem repetir)
  final String tituloSlot; // "Ativo 1", "Banco 2", etc
  final Future<void> Function(Tipo tipo, String colecaoEscolhida) onConfirmarNovo;
  final Future<void> Function(MonstroExplorador monstro)? onConfirmarSalvo;
  final List<MonstroExplorador> monstrosSalvos; // Monstros salvos disponiveis

  const ModalSelecaoMonstroExplorador({
    super.key,
    required this.colecao,
    required this.tiposJaUsados,
    required this.tituloSlot,
    required this.onConfirmarNovo,
    this.onConfirmarSalvo,
    this.monstrosSalvos = const [],
  });

  @override
  State<ModalSelecaoMonstroExplorador> createState() => _ModalSelecaoMonstroExploradorState();
}

class _ModalSelecaoMonstroExploradorState extends State<ModalSelecaoMonstroExplorador> {
  Tipo? _tipoSelecionado;
  String? _colecaoSelecionada;
  MonstroExplorador? _monstroSalvoSelecionado;
  Tipo? _tipoExpandido;
  bool _processando = false;

  // Indice atual de imagem para cada tipo (para animacao de alternancia)
  final Map<Tipo, int> _indiceImagemPorTipo = {};

  // Lista de tipos disponiveis (todos os 30 tipos)
  final List<Tipo> _tiposDisponiveis = Tipo.values.toList();

  @override
  void initState() {
    super.initState();
    _iniciarAlternanciaImagens();
  }

  void _iniciarAlternanciaImagens() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
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
              Colors.grey.shade900,
              Colors.black87,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.teal,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.4),
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.catching_pokemon,
                      color: Colors.teal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecionar Monstro',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Para ${widget.tituloSlot}',
                          style: const TextStyle(
                            color: Colors.teal,
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

            // Info tipos bloqueados
            if (widget.tiposJaUsados.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tipos ja usados: ${widget.tiposJaUsados.map((t) => t.displayName).join(", ")}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Corpo - Lista de monstros salvos e novos
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Secao de monstros salvos (com XP/level)
                    if (_getMonstrosSalvosDisponiveis().isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Monstros Salvos',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Monstros com XP e level preservados',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMonstrosSalvos(),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),
                    ],

                    // Secao de novos monstros
                    const Text(
                      'Novos Monstros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Clique em um tipo para ver os monstros disponiveis',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSeletorTiposExpandivel(),
                  ],
                ),
              ),
            ),

            // Botao confirmar
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
                        backgroundColor: Colors.teal,
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
                              _getBotaoTexto(),
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

  Widget _buildSeletorTiposExpandivel() {
    return Column(
      children: _tiposDisponiveis.map((tipo) {
        final expandido = _tipoExpandido == tipo;
        final tipoTemSelecao = _tipoSelecionado == tipo && _colecaoSelecionada != null;
        final monstrosDesbloqueados = _getMonstrosDesbloqueadosPorTipo(tipo);
        final tipoBloqueado = widget.tiposJaUsados.contains(tipo);

        return Opacity(
          opacity: tipoBloqueado ? 0.4 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: tipoTemSelecao
                  ? Colors.teal.withOpacity(0.2)
                  : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tipoBloqueado
                    ? Colors.red.withOpacity(0.5)
                    : tipoTemSelecao
                        ? Colors.teal
                        : Colors.white24,
                width: tipoTemSelecao ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Header do tipo (clicavel para expandir)
                InkWell(
                  onTap: tipoBloqueado
                      ? null
                      : () {
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
                        // Imagem do tipo
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
                                color: tipo.cor.withOpacity(0.3),
                                child: Icon(tipo.icone, color: tipo.cor, size: 24),
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
                              Row(
                                children: [
                                  Text(
                                    tipo.displayName,
                                    style: TextStyle(
                                      color: tipoBloqueado ? Colors.red : Colors.white,
                                      fontSize: 14,
                                      fontWeight: tipoTemSelecao ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (tipoBloqueado) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.lock, color: Colors.red, size: 14),
                                  ],
                                ],
                              ),
                              Text(
                                tipoBloqueado
                                    ? 'Ja na equipe'
                                    : '${monstrosDesbloqueados.length} disponivel${monstrosDesbloqueados.length != 1 ? 'is' : ''}',
                                style: TextStyle(
                                  color: tipoBloqueado ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Icone de expandir/retrair
                        if (!tipoBloqueado)
                          Icon(
                            expandido ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white54,
                          ),
                      ],
                    ),
                  ),
                ),
                // Grid de monstros desbloqueados (quando expandido)
                if (expandido && !tipoBloqueado)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: monstrosDesbloqueados.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            child: const Text(
                              'Nenhum monstro deste tipo desbloqueado na colecao',
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
                                        ? Colors.teal.withOpacity(0.4)
                                        : Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.teal : Colors.white24,
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
                                            color: tipo.cor.withOpacity(0.3),
                                            child: Icon(tipo.icone, color: tipo.cor, size: 24),
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
          ),
        );
      }).toList(),
    );
  }

  /// Retorna lista de monstros desbloqueados para um tipo especifico
  List<Map<String, String>> _getMonstrosDesbloqueadosPorTipo(Tipo tipo) {
    final List<Map<String, String>> monstros = [];

    // Colecao inicial - sempre desbloqueada
    monstros.add({
      'colecao': 'colecao_inicial',
      'arquivo': tipo.name,
    });

    // Colecao nostalgica - verifica no mapa de colecao
    if (widget.colecao[tipo.name] == true) {
      monstros.add({
        'colecao': 'colecao_nostalgicos',
        'arquivo': tipo.name,
      });
    }

    // Colecao Halloween - verifica com prefixo halloween_
    if (widget.colecao['halloween_${tipo.name}'] == true) {
      monstros.add({
        'colecao': 'colecao_halloween',
        'arquivo': tipo.name,
      });
    }

    return monstros;
  }

  /// Retorna a imagem atual a ser exibida para um tipo (alterna entre monstros)
  String _getImagemAtualPorTipo(Tipo tipo, List<Map<String, String>> monstros) {
    if (monstros.isEmpty) {
      return 'assets/monstros_aventura/colecao_inicial/${tipo.name}.png';
    }

    final indice = _indiceImagemPorTipo[tipo] ?? 0;
    final monstro = monstros[indice % monstros.length];
    return 'assets/monstros_aventura/${monstro['colecao']}/${monstro['arquivo']}.png';
  }

  String _getColecaoLabel(String colecao) {
    switch (colecao) {
      case 'colecao_inicial':
        return 'Inicial';
      case 'colecao_nostalgicos':
        return 'Nostalgico';
      case 'colecao_halloween':
        return 'Halloween';
      default:
        return colecao;
    }
  }

  /// Retorna monstros salvos que nao tem tipo bloqueado
  List<MonstroExplorador> _getMonstrosSalvosDisponiveis() {
    return widget.monstrosSalvos
        .where((m) => !widget.tiposJaUsados.contains(m.tipo))
        .toList();
  }

  /// Widget para exibir monstros salvos
  Widget _buildMonstrosSalvos() {
    final monstrosSalvos = _getMonstrosSalvosDisponiveis();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: monstrosSalvos.map((monstro) {
        final isSelected = _monstroSalvoSelecionado?.id == monstro.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _monstroSalvoSelecionado = monstro;
              // Limpa selecao de novo monstro
              _tipoSelecionado = null;
              _colecaoSelecionada = null;
            });
          },
          child: Container(
            width: 80,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Imagem do monstro
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
                      color: monstro.tipo.cor.withOpacity(0.3),
                      child: Icon(monstro.tipo.icone, color: monstro.tipo.cor, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Nome do tipo
                Text(
                  monstro.tipo.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Level
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Lv.${monstro.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Texto do botao de confirmar
  String _getBotaoTexto() {
    if (_monstroSalvoSelecionado != null) {
      return 'ADICIONAR ${_monstroSalvoSelecionado!.tipo.displayName.toUpperCase()} Lv.${_monstroSalvoSelecionado!.level}';
    }
    if (_tipoSelecionado != null && _colecaoSelecionada != null) {
      return 'ADICIONAR ${_tipoSelecionado!.displayName.toUpperCase()}';
    }
    return 'SELECIONE UM MONSTRO';
  }

  bool _podeConfirmar() {
    if (_processando) return false;

    // Pode confirmar monstro salvo
    if (_monstroSalvoSelecionado != null &&
        !widget.tiposJaUsados.contains(_monstroSalvoSelecionado!.tipo)) {
      return true;
    }

    // Pode confirmar novo monstro
    return _tipoSelecionado != null &&
        _colecaoSelecionada != null &&
        !widget.tiposJaUsados.contains(_tipoSelecionado);
  }

  Future<void> _confirmar() async {
    if (!_podeConfirmar()) return;

    setState(() => _processando = true);

    try {
      if (_monstroSalvoSelecionado != null && widget.onConfirmarSalvo != null) {
        // Adicionar monstro salvo
        await widget.onConfirmarSalvo!(_monstroSalvoSelecionado!);
      } else if (_tipoSelecionado != null && _colecaoSelecionada != null) {
        // Adicionar novo monstro
        await widget.onConfirmarNovo(_tipoSelecionado!, _colecaoSelecionada!);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar: $e')),
        );
        setState(() => _processando = false);
      }
    }
  }
}
