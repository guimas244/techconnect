import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/criadouro_provider.dart';

class CriarMascoteScreen extends ConsumerStatefulWidget {
  const CriarMascoteScreen({super.key});

  @override
  ConsumerState<CriarMascoteScreen> createState() => _CriarMascoteScreenState();
}

class _CriarMascoteScreenState extends ConsumerState<CriarMascoteScreen> {
  final _nomeController = TextEditingController();
  String? _monstroSelecionado;
  final _formKey = GlobalKey<FormState>();

  // Lista de monstros disponíveis (imagens do catálogo)
  // TODO: Integrar com catálogo real de monstros desbloqueados
  final List<String> _monstrosDisponiveis = [
    'assets/monstros/monstro_fogo.png',
    'assets/monstros/monstro_agua.png',
    'assets/monstros/monstro_terra.png',
    'assets/monstros/monstro_ar.png',
    'assets/monstros/monstro_luz.png',
    'assets/monstros/monstro_sombra.png',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐣 ', style: TextStyle(fontSize: 24)),
            Text('Criar Mascote'),
          ],
        ),
      ),
      body: Form(
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
              Card(
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
              ),
              const SizedBox(height: 16),

              // Seleção de monstro
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escolha a Aparência',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione um monstro do seu catálogo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGridMonstros(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Atributos iniciais
              Card(
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
                          Expanded(child: _AtributoInicial(emoji: '🍖', label: 'Fome', valor: '75%')),
                          Expanded(child: _AtributoInicial(emoji: '💧', label: 'Sede', valor: '75%')),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _AtributoInicial(emoji: '🧼', label: 'Higiene', valor: '75%')),
                          Expanded(child: _AtributoInicial(emoji: '😄', label: 'Alegria', valor: '75%')),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _AtributoInicial(emoji: '❤️', label: 'Saúde', valor: '100%')),
                          Expanded(child: _AtributoInicial(emoji: '🛡️', label: 'Imunidade', valor: '24h')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão de criar
              ElevatedButton(
                onPressed: _podecriar() ? _criarMascote : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🐣 ', style: TextStyle(fontSize: 20)),
                    Text(
                      'Criar Mascote',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
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
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _monstroSelecionado != null ? Colors.green : Colors.grey,
            width: 3,
          ),
        ),
        child: _monstroSelecionado != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.asset(
                  _monstroSelecionado!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('🐣', style: TextStyle(fontSize: 60)),
                    );
                  },
                ),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🥚', style: TextStyle(fontSize: 50)),
                    SizedBox(height: 8),
                    Text(
                      'Selecione\num monstro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildGridMonstros() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _monstrosDisponiveis.length,
      itemBuilder: (context, index) {
        final monstro = _monstrosDisponiveis[index];
        final selecionado = _monstroSelecionado == monstro;

        return GestureDetector(
          onTap: () {
            setState(() {
              _monstroSelecionado = monstro;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: selecionado ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selecionado ? Colors.green : Colors.grey[300]!,
                width: selecionado ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(selecionado ? 9 : 11),
              child: Image.asset(
                monstro,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      '🐾',
                      style: TextStyle(
                        fontSize: 30,
                        color: selecionado ? Colors.green : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  bool _podecriar() {
    return _nomeController.text.trim().length >= 2 &&
        _monstroSelecionado != null;
  }

  void _criarMascote() {
    if (!_formKey.currentState!.validate()) return;
    if (_monstroSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um monstro!')),
      );
      return;
    }

    ref.read(criadouroProvider.notifier).criarMascote(
          nome: _nomeController.text.trim(),
          monstroId: _monstroSelecionado!,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_nomeController.text.trim()} nasceu! 🎉'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
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
