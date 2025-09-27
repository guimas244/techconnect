import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../services/colecao_service.dart';

class ColecaoDebugScreen extends ConsumerStatefulWidget {
  const ColecaoDebugScreen({super.key});

  @override
  ConsumerState<ColecaoDebugScreen> createState() => _ColecaoDebugScreenState();
}

class _ColecaoDebugScreenState extends ConsumerState<ColecaoDebugScreen> {
  final ColecaoService _colecaoService = ColecaoService();

  Map<String, bool>? _colecao;
  bool _carregando = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _carregarEmail();
  }

  Future<void> _carregarEmail() async {
    final email = ref.read(currentUserEmailProvider);
    if (email != null) {
      setState(() {
        _email = email;
      });
      await _carregarColecao();
    }
  }

  Future<void> _carregarColecao() async {
    if (_email == null) return;

    setState(() {
      _carregando = true;
    });

    try {
      final colecao = await _colecaoService.carregarColecaoJogador(_email!);
      setState(() {
        _colecao = colecao;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar coleção: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _desbloquearMonstrosAleatorios(int quantidade) async {
    if (_email == null) return;

    setState(() {
      _carregando = true;
    });

    try {
      final sucesso = await _colecaoService.desbloquearMonstrosAleatorios(_email!, quantidade);
      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$quantidade monstros desbloqueados!')),
        );
        await _carregarColecao(); // Recarrega a coleção
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao desbloquear monstros')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Coleção Nostálgica'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_email != null)
                    Text(
                      'Email: $_email',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 16),

                  // Botões de ação
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _desbloquearMonstrosAleatorios(1),
                        child: const Text('Desbloquear 1'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _desbloquearMonstrosAleatorios(5),
                        child: const Text('Desbloquear 5'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _desbloquearMonstrosAleatorios(10),
                        child: const Text('Desbloquear 10'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _carregarColecao,
                    child: const Text('Recarregar Coleção'),
                  ),
                  const SizedBox(height: 24),

                  // Lista da coleção
                  if (_colecao != null) ...[
                    Text(
                      'Coleção Nostálgica (${_colecao!.values.where((desbloqueado) => desbloqueado).length}/${_colecao!.length} desbloqueados)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _colecao!.length,
                        itemBuilder: (context, index) {
                          final entry = _colecao!.entries.elementAt(index);
                          final nomeMonstro = entry.key;
                          final desbloqueado = entry.value;

                          // Encontra o tipo correspondente para mostrar o nome nostálgico
                          String nomeExibir = nomeMonstro.toUpperCase();
                          try {
                            final tipo = Tipo.values.firstWhere((t) => t.name == nomeMonstro);
                            nomeExibir = desbloqueado
                                ? tipo.nostalgicMonsterName
                                : '??? ${tipo.monsterName}';
                          } catch (e) {
                            // Se não encontrar o tipo, usa o nome original
                            nomeExibir = nomeMonstro.toUpperCase();
                          }

                          return Card(
                            elevation: 2,
                            color: desbloqueado ? Colors.green[100] : Colors.grey[300],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    desbloqueado ? Icons.lock_open : Icons.lock,
                                    color: desbloqueado ? Colors.green : Colors.grey,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nomeExibir,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: desbloqueado ? Colors.green[800] : Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else
                    const Center(
                      child: Text('Carregue a coleção para visualizar'),
                    ),
                ],
              ),
            ),
    );
  }
}