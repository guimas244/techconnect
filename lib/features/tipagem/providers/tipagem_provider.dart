import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tipagem_repository.dart';
import '../../../shared/models/tipo_enum.dart';

// Provider para o repositório de tipagem
final tipagemRepositoryProvider = Provider<TipagemRepository>((ref) {
  return TipagemRepository();
});

// Provider para carregar dados de um tipo específico
final tipagemDataProvider = FutureProvider.family<Map<Tipo, double>?, Tipo>((ref, tipo) async {
  final repository = ref.read(tipagemRepositoryProvider);
  return await repository.carregarDadosTipo(tipo);
});

// Provider para a lista de todos os tipos
final todosOsTiposProvider = Provider<List<Tipo>>((ref) {
  return Tipo.values;
});

// Notifier para gerenciar o estado de edição de danos
final tipagemEditProvider = StateNotifierProvider.family<TipagemEditNotifier, TipagemEditState, Tipo>((ref, tipo) {
  final repository = ref.read(tipagemRepositoryProvider);
  return TipagemEditNotifier(repository, tipo);
});

// Estado da edição de tipagem
class TipagemEditState {
  final Map<Tipo, double> danoRecebido;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const TipagemEditState({
    required this.danoRecebido,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  TipagemEditState copyWith({
    Map<Tipo, double>? danoRecebido,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return TipagemEditState(
      danoRecebido: danoRecebido ?? this.danoRecebido,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// Notifier para gerenciar edição de tipagem
class TipagemEditNotifier extends StateNotifier<TipagemEditState> {
  final TipagemRepository _repository;
  final Tipo _tipoSelecionado;

  TipagemEditNotifier(this._repository, this._tipoSelecionado)
      : super(TipagemEditState(
          danoRecebido: {
            for (final tipo in Tipo.values)
              if (tipo != _tipoSelecionado) tipo: 1.0,
          },
        )) {
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final dados = await _repository.carregarDadosTipo(_tipoSelecionado);
      
      if (dados != null) {
        print('Provider - dados recebidos do repositório para ${_tipoSelecionado.name}:');
        dados.forEach((key, value) {
          print('  ${key.name}: $value');
        });
        
        // Remove o próprio tipo selecionado dos dados (não faz sentido editar dano de si mesmo)
        final dadosFiltrados = Map<Tipo, double>.from(dados);
        dadosFiltrados.remove(_tipoSelecionado);
        
        print('Provider - dados filtrados (sem ${_tipoSelecionado.name}):');
        dadosFiltrados.forEach((key, value) {
          print('  ${key.name}: $value');
        });
        
        state = state.copyWith(
          danoRecebido: dadosFiltrados,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          errorMessage: 'App não inicializado. Baixe dados do Drive primeiro.',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados: $e',
      );
    }
  }

  void atualizarDano(Tipo tipo, double valor) {
    if (tipo == _tipoSelecionado) return;
    
    final novoMap = Map<Tipo, double>.from(state.danoRecebido);
    novoMap[tipo] = valor;
    
    state = state.copyWith(danoRecebido: novoMap);
  }

  Future<void> salvarAlteracoes() async {
    state = state.copyWith(
      isSaving: true, 
      errorMessage: null, 
      successMessage: null
    );
    
    try {
      await _repository.salvarDadosTipo(_tipoSelecionado, state.danoRecebido);
      
      // Obter caminho de exportação
      final caminhoExportacao = await _repository.obterCaminhoExportacao();
      
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Dados salvos com sucesso!\n\n$caminhoExportacao'
      );
      
      // Remove a mensagem de sucesso após 6 segundos
      Future.delayed(Duration(seconds: 6), () {
        if (mounted) {
          state = state.copyWith(successMessage: null);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erro ao salvar: $e',
      );
    }
  }

  void limparMensagens() {
    state = state.copyWith(
      errorMessage: null, 
      successMessage: null
    );
  }

  String gerarJsonParaDownload() {
    return _repository.gerarJsonFormatado(_tipoSelecionado, state.danoRecebido);
  }
}
