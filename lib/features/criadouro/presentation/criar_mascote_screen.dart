import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/criadouro_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/services/colecao_service.dart';
import '../../../core/services/storage_service.dart';

/// Caminho do ovo para o preview
const String _ovoImagePath = 'assets/eventos/halloween/ovo_halloween.png';

/// Filtro para silhueta preta (bloqueado) - mesmo da tela de coleções
const _grayscaleFilter = ColorFilter.matrix([
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

/// Filtro identidade (normal) - mesmo da tela de coleções
const _identityFilter = ColorFilter.matrix([
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

/// Representa um pet disponível para seleção como mascote
class PetDisponivel {
  final String tipo;
  final String colecao;
  final String nome;
  final String imagePath;
  final bool bloqueado;

  PetDisponivel({
    required this.tipo,
    required this.colecao,
    required this.nome,
    required this.imagePath,
    this.bloqueado = false,
  });
}

class CriarMascoteScreen extends ConsumerStatefulWidget {
  const CriarMascoteScreen({super.key});

  @override
  ConsumerState<CriarMascoteScreen> createState() => _CriarMascoteScreenState();
}

class _CriarMascoteScreenState extends ConsumerState<CriarMascoteScreen> {
  final _nomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Tipo selecionado
  Tipo? _tipoSelecionado;

  // Pet selecionado (imagem completa)
  PetDisponivel? _petSelecionado;

  // Coleção do jogador
  Map<String, bool> _colecaoJogador = {};
  bool _carregandoColecao = true;

  // Monstro aleatório para o ícone (definido uma vez ao abrir a tela)
  late final String _monstroAleatorioPath;

  // Services
  final ColecaoService _colecaoService = ColecaoService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // Seleciona um monstro aleatório da coleção inicial para o ícone
    final tipoAleatorio = Tipo.values[Random().nextInt(Tipo.values.length)];
    _monstroAleatorioPath = 'assets/monstros_aventura/colecao_inicial/${tipoAleatorio.name}.png';
    _carregarColecao();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _carregarColecao() async {
    try {
      final email = await _storageService.getLastEmail();
      if (email != null) {
        final colecao = await _colecaoService.carregarColecaoJogador(email);
        setState(() {
          _colecaoJogador = colecao;
          _carregandoColecao = false;
        });
      } else {
        setState(() => _carregandoColecao = false);
      }
    } catch (e) {
      print('Erro ao carregar coleção: $e');
      setState(() => _carregandoColecao = false);
    }
  }

  /// Retorna a lista de todos os pets para o tipo selecionado (desbloqueados e bloqueados)
  List<PetDisponivel> _getPetsDisponiveis(Tipo tipo) {
    final pets = <PetDisponivel>[];
    final tipoNome = tipo.name;

    // 1. Coleção Inicial - sempre disponível
    pets.add(PetDisponivel(
      tipo: tipoNome,
      colecao: 'colecao_inicial',
      nome: tipo.monsterName,
      imagePath: 'assets/monstros_aventura/colecao_inicial/$tipoNome.png',
      bloqueado: false,
    ));

    // 2. Coleção Nostálgica - mostra sempre, verifica se está desbloqueado
    final nostalgicoBloqueado = _colecaoJogador[tipoNome] != true;
    pets.add(PetDisponivel(
      tipo: tipoNome,
      colecao: 'colecao_nostalgicos',
      nome: tipo.nostalgicMonsterName,
      imagePath: 'assets/monstros_aventura/colecao_nostalgicos/$tipoNome.png',
      bloqueado: nostalgicoBloqueado,
    ));

    // 3. Coleção Halloween - mostra sempre, verifica se está desbloqueado
    final halloweenBloqueado = _colecaoJogador['halloween_$tipoNome'] != true;
    pets.add(PetDisponivel(
      tipo: tipoNome,
      colecao: 'colecao_halloween',
      nome: '${tipo.monsterName} Halloween',
      imagePath: 'assets/monstros_aventura/colecao_halloween/$tipoNome.png',
      bloqueado: halloweenBloqueado,
    ));

    return pets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _monstroAleatorioPath,
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 28),
            ),
            const SizedBox(width: 8),
            const Text('Criar Mascote'),
          ],
        ),
      ),
      body: _carregandoColecao
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview do mascote
                    _buildPreview(),
                    const SizedBox(height: 24),

                    // Campo de nome
                    _buildNomeCard(),
                    const SizedBox(height: 16),

                    // Seleção de tipo
                    _buildTipoSelecao(),
                    const SizedBox(height: 16),

                    // Grid de pets do tipo selecionado
                    if (_tipoSelecionado != null) _buildPetsGrid(),
                    const SizedBox(height: 16),

                    // Atributos iniciais
                    _buildAtributosCard(),
                    const SizedBox(height: 24),

                    // Botão de criar
                    _buildBotaoCriar(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPreview() {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: _tipoSelecionado?.cor.withOpacity(0.1) ?? Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _petSelecionado != null
                ? Colors.green
                : _tipoSelecionado?.cor ?? Colors.grey,
            width: 3,
          ),
        ),
        child: _petSelecionado != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.asset(
                  _petSelecionado!.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        _tipoSelecionado?.icone ?? Icons.pets,
                        size: 60,
                        color: _tipoSelecionado?.cor ?? Colors.grey,
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      _ovoImagePath,
                      width: 70,
                      height: 70,
                      errorBuilder: (_, __, ___) => const Text('🥚', style: TextStyle(fontSize: 50)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tipoSelecionado != null
                          ? 'Selecione\num monstro'
                          : 'Selecione\num tipo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nome do Mascote',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                hintText: 'Digite o nome...',
                prefixIcon: Icon(Icons.pets),
              ),
              maxLength: 15,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite um nome para o mascote';
                }
                if (value.trim().length < 2) {
                  return 'O nome deve ter pelo menos 2 caracteres';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoSelecao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Escolha o Tipo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_tipoSelecionado != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _tipoSelecionado!.cor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tipoSelecionado!.icone,
                          size: 16,
                          color: _tipoSelecionado!.cor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _tipoSelecionado!.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _tipoSelecionado!.cor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione um tipo para ver os monstros de estimação',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Grid de tipos (5 colunas)
            _buildTiposGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTiposGrid() {
    final tipos = Tipo.values;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: tipos.length,
      itemBuilder: (context, index) {
        final tipo = tipos[index];
        final selecionado = _tipoSelecionado == tipo;
        final temPetsLiberados = _temPetsLiberados(tipo);

        return GestureDetector(
          onTap: () {
            setState(() {
              _tipoSelecionado = tipo;
              _petSelecionado = null; // Reset pet ao mudar tipo
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: selecionado
                  ? tipo.cor.withOpacity(0.3)
                  : tipo.cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selecionado ? tipo.cor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Ícone central
                Center(
                  child: Image.asset(
                    tipo.iconAsset,
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) => Icon(
                      tipo.icone,
                      size: 28,
                      color: tipo.cor,
                    ),
                  ),
                ),
                // Badge de quantidade de pets liberados
                if (temPetsLiberados > 1)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$temPetsLiberados',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Retorna quantos pets o jogador tem liberados desse tipo
  int _temPetsLiberados(Tipo tipo) {
    int count = 1; // Coleção inicial sempre disponível
    final tipoNome = tipo.name;

    if (_colecaoJogador[tipoNome] == true) count++; // Nostálgico
    if (_colecaoJogador['halloween_$tipoNome'] == true) count++; // Halloween

    return count;
  }

  Widget _buildPetsGrid() {
    final pets = _getPetsDisponiveis(_tipoSelecionado!);
    final petsDesbloqueados = pets.where((p) => !p.bloqueado).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Monstros de ${_tipoSelecionado!.displayName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$petsDesbloqueados/${pets.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione a aparência do seu monstro de estimação',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Grid de monstros
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                final selecionado = _petSelecionado?.imagePath == pet.imagePath;
                final bloqueado = pet.bloqueado;

                return GestureDetector(
                  onTap: bloqueado
                      ? null
                      : () {
                          setState(() {
                            _petSelecionado = pet;
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bloqueado
                          ? Colors.grey[300]
                          : selecionado
                              ? _tipoSelecionado!.cor.withOpacity(0.2)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: bloqueado
                            ? Colors.grey[400]!
                            : selecionado
                                ? Colors.green
                                : Colors.grey[300]!,
                        width: selecionado ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ColorFiltered(
                              colorFilter: bloqueado
                                  ? _grayscaleFilter
                                  : _identityFilter,
                              child: Image.asset(
                                pet.imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      _tipoSelecionado!.icone,
                                      size: 40,
                                      color: bloqueado
                                          ? Colors.black
                                          : _tipoSelecionado!.cor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bloqueado
                                ? Colors.grey[400]
                                : _getColecaoCor(pet.colecao).withOpacity(0.2),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                bloqueado ? '???' : pet.nome,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: bloqueado
                                      ? Colors.grey[600]
                                      : _getColecaoCor(pet.colecao),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getColecaoLabel(pet.colecao),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: bloqueado
                                      ? Colors.grey[600]
                                      : _getColecaoCor(pet.colecao).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColecaoCor(String colecao) {
    switch (colecao) {
      case 'colecao_inicial':
        return Colors.blue;
      case 'colecao_nostalgicos':
        return Colors.purple;
      case 'colecao_halloween':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
        return '';
    }
  }

  Widget _buildAtributosCard() {
    return Card(
      color: Colors.blue[50],
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Atributos Iniciais',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child:
                        _AtributoInicial(emoji: '🍖', label: 'Fome', valor: '75%')),
                Expanded(
                    child:
                        _AtributoInicial(emoji: '💧', label: 'Sede', valor: '75%')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _AtributoInicial(
                        emoji: '🧼', label: 'Higiene', valor: '75%')),
                Expanded(
                    child: _AtributoInicial(
                        emoji: '😄', label: 'Alegria', valor: '75%')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child:
                        _AtributoInicial(emoji: '❤️', label: 'Saúde', valor: '100%')),
                Expanded(
                    child: _AtributoInicial(
                        emoji: '🛡️', label: 'Imunidade', valor: '24h')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoCriar() {
    return ElevatedButton(
      onPressed: _podeCriar() ? _criarMascote : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: _tipoSelecionado?.cor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            _monstroAleatorioPath,
            width: 28,
            height: 28,
            errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 24),
          ),
          const SizedBox(width: 8),
          Text(
            'Criar Mascote',
            style: TextStyle(
              fontSize: 18,
              color: _podeCriar() ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _podeCriar() {
    if (_nomeController.text.trim().length < 2) return false;
    if (_petSelecionado == null) return false;
    if (_tipoSelecionado == null) return false;

    // Verifica se já existe mascote desse tipo
    final jaTem = ref.read(temMascoteTipoProvider(_tipoSelecionado!.name));
    return !jaTem;
  }

  Future<void> _criarMascote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_petSelecionado == null || _tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um monstro de estimação!')),
      );
      return;
    }

    // Verifica se já existe mascote desse tipo
    final jaTem = ref.read(temMascoteTipoProvider(_tipoSelecionado!.name));
    if (jaTem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você já tem um mascote do tipo ${_tipoSelecionado!.displayName}!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nome = _nomeController.text.trim();
    final sucesso = await ref.read(criadouroProvider.notifier).criarMascote(
          tipo: _tipoSelecionado!.name,
          nome: nome,
          monstroId: _petSelecionado!.imagePath,
        );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nome nasceu! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar mascote!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _AtributoInicial extends StatelessWidget {
  final String emoji;
  final String label;
  final String valor;

  const _AtributoInicial({
    required this.emoji,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
