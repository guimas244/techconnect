import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/monstro_aventura.dart';
import '../data/monstro_aventura_repository.dart';
import '../../../../shared/models/tipo_enum.dart';

// Provider para controle de estado do formulário
final cadastroFormProvider = StateNotifierProvider<CadastroFormNotifier, CadastroFormState>((ref) {
  return CadastroFormNotifier();
});

class CadastroFormState {
  final String nome;
  final Tipo tipo1;
  final Tipo tipo2;
  final Uint8List? imagemBytes;
  final String? imagemNome;
  final bool isLoading;
  final String? erro;

  const CadastroFormState({
    this.nome = '',
    this.tipo1 = Tipo.normal,
    this.tipo2 = Tipo.planta,
    this.imagemBytes,
    this.imagemNome,
    this.isLoading = false,
    this.erro,
  });

  CadastroFormState copyWith({
    String? nome,
    Tipo? tipo1,
    Tipo? tipo2,
    Uint8List? imagemBytes,
    String? imagemNome,
    bool? isLoading,
    String? erro,
    bool clearImagem = false,
    bool clearErro = false,
  }) {
    return CadastroFormState(
      nome: nome ?? this.nome,
      tipo1: tipo1 ?? this.tipo1,
      tipo2: tipo2 ?? this.tipo2,
      imagemBytes: clearImagem ? null : (imagemBytes ?? this.imagemBytes),
      imagemNome: clearImagem ? null : (imagemNome ?? this.imagemNome),
      isLoading: isLoading ?? this.isLoading,
      erro: clearErro ? null : (erro ?? this.erro),
    );
  }

  bool get isValid => nome.trim().isNotEmpty && tipo1 != tipo2;
}

class CadastroFormNotifier extends StateNotifier<CadastroFormState> {
  CadastroFormNotifier() : super(const CadastroFormState());

  void setNome(String nome) {
    state = state.copyWith(nome: nome, clearErro: true);
  }

  void setTipo1(Tipo tipo) {
    // Se o tipo1 ficou igual ao tipo2, muda o tipo2 para outro
    Tipo novoTipo2 = state.tipo2;
    if (tipo == state.tipo2) {
      novoTipo2 = Tipo.values.firstWhere((t) => t != tipo);
    }
    state = state.copyWith(tipo1: tipo, tipo2: novoTipo2, clearErro: true);
  }

  void setTipo2(Tipo tipo) {
    // Se o tipo2 ficou igual ao tipo1, muda o tipo1 para outro
    Tipo novoTipo1 = state.tipo1;
    if (tipo == state.tipo1) {
      novoTipo1 = Tipo.values.firstWhere((t) => t != tipo);
    }
    state = state.copyWith(tipo1: novoTipo1, tipo2: tipo, clearErro: true);
  }

  void setImagem(Uint8List bytes, String nome) {
    state = state.copyWith(imagemBytes: bytes, imagemNome: nome, clearErro: true);
  }

  void removeImagem() {
    state = state.copyWith(clearImagem: true, clearErro: true);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setErro(String? erro) {
    state = state.copyWith(erro: erro, isLoading: false);
  }

  void limparFormulario() {
    state = const CadastroFormState();
  }

  void carregarMonstro(MonstroAventura monstro) {
    state = CadastroFormState(
      nome: monstro.nome,
      tipo1: monstro.tipo1,
      tipo2: monstro.tipo2,
      // imagemBytes serão carregados se necessário
    );
  }
}

class MonstroCadastroScreen extends ConsumerStatefulWidget {
  final MonstroAventura? monstroParaEditar;

  const MonstroCadastroScreen({
    super.key,
    this.monstroParaEditar,
  });

  @override
  ConsumerState<MonstroCadastroScreen> createState() => _MonstroCadastroScreenState();
}

class _MonstroCadastroScreenState extends ConsumerState<MonstroCadastroScreen> {
  final _nomeController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool get _isEdicao => widget.monstroParaEditar != null;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEdicao) {
        final monstro = widget.monstroParaEditar!;
        _nomeController.text = monstro.nome;
        ref.read(cadastroFormProvider.notifier).carregarMonstro(monstro);
      } else {
        ref.read(cadastroFormProvider.notifier).limparFormulario();
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(cadastroFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Monstro' : 'Cadastrar Monstro'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagemSection(formState),
            const SizedBox(height: 24),
            _buildNomeField(formState),
            const SizedBox(height: 24),
            _buildTiposSection(formState),
            const SizedBox(height: 24),
            if (formState.erro != null) ...[
              _buildErroCard(formState.erro!),
              const SizedBox(height: 16),
            ],
            _buildSalvarButton(formState),
          ],
        ),
      ),
    );
  }

  Widget _buildImagemSection(CadastroFormState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imagem do Monstro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: state.isLoading ? null : _selecionarImagem,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: state.imagemBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                state.imagemBytes!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () => ref.read(cadastroFormProvider.notifier).removeImagem(),
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.7),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toque para adicionar imagem',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (state.imagemNome != null) ...[
              const SizedBox(height: 8),
              Text(
                'Arquivo: ${state.imagemNome}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNomeField(CadastroFormState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nome do Monstro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nomeController,
              enabled: !state.isLoading,
              decoration: const InputDecoration(
                hintText: 'Digite o nome do monstro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              onChanged: (value) {
                ref.read(cadastroFormProvider.notifier).setNome(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiposSection(CadastroFormState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipos do Monstro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTipoDropdown(
                    label: 'Tipo 1',
                    valor: state.tipo1,
                    onChanged: state.isLoading
                        ? null
                        : (tipo) => ref.read(cadastroFormProvider.notifier).setTipo1(tipo!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTipoDropdown(
                    label: 'Tipo 2',
                    valor: state.tipo2,
                    onChanged: state.isLoading
                        ? null
                        : (tipo) => ref.read(cadastroFormProvider.notifier).setTipo2(tipo!),
                  ),
                ),
              ],
            ),
            if (state.tipo1 == state.tipo2) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Os dois tipos não podem ser iguais',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipoDropdown({
    required String label,
    required Tipo valor,
    required void Function(Tipo?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Tipo>(
          value: valor,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: Tipo.values.map((tipo) => DropdownMenuItem(
            value: tipo,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: tipo.cor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tipo.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildErroCard(String erro) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                erro,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalvarButton(CadastroFormState state) {
    return ElevatedButton(
      onPressed: state.isLoading || !state.isValid ? null : _salvarMonstro,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      child: state.isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Salvando...'),
              ],
            )
          : Text(_isEdicao ? 'Atualizar Monstro' : 'Cadastrar Monstro'),
    );
  }

  Future<void> _selecionarImagem() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        ref.read(cadastroFormProvider.notifier).setImagem(bytes, pickedFile.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _salvarMonstro() async {
    final state = ref.read(cadastroFormProvider);
    final repository = MonstroAventuraRepository();

    ref.read(cadastroFormProvider.notifier).setLoading(true);

    try {
      final monstro = MonstroAventura(
        id: _isEdicao ? widget.monstroParaEditar!.id : '',
        nome: state.nome.trim(),
        tipo1: state.tipo1,
        tipo2: state.tipo2,
        imagemBytes: state.imagemBytes,
        criadoEm: _isEdicao ? widget.monstroParaEditar!.criadoEm : DateTime.now(),
      );

      await repository.salvarMonstro(monstro);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdicao
                ? 'Monstro atualizado com sucesso!'
                : 'Monstro cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ref.read(cadastroFormProvider.notifier).setErro(e.toString());
    }
  }
}
