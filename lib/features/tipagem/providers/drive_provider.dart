import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tipagem_repository.dart';
import 'tipagem_provider.dart';

final driveProvider = StateNotifierProvider<DriveNotifier, DriveState>((ref) {
  final repository = ref.read(tipagemRepositoryProvider);
  return DriveNotifier(repository);
});

class DriveNotifier extends StateNotifier<DriveState> {
  final TipagemRepository _repository;

  DriveNotifier(this._repository) : super(const DriveState());

  Future<void> conectarDrive() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final sucesso = await _repository.conectarDrive();
      
      if (sucesso) {
        state = state.copyWith(
          isLoading: false,
          isConectado: true,
          successMessage: '✅ Conectado ao Google Drive!\nPasta "TechConnect_Tipagens" criada.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '❌ Falha ao conectar com Google Drive\nVerifique sua conexão e permissões.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro: $e',
      );
    }
  }

  Future<void> sincronizarTodos() async {
    if (!state.isConectado) {
      await conectarDrive();
      if (!state.isConectado) return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final sucesso = await _repository.sincronizarTodosParaDrive();
      
      if (sucesso) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '☁️ Todos os arquivos sincronizados!\n30 arquivos JSON enviados para o Drive.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '⚠️ Alguns arquivos falharam na sincronização\nTente novamente.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro na sincronização: $e',
      );
    }
  }

  Future<void> desconectar() async {
    await _repository.desconectarDrive();
    state = state.copyWith(
      isConectado: false,
      successMessage: '🔌 Desconectado do Google Drive',
      errorMessage: null,
    );
  }

  void limparMensagens() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  void verificarConexao() {
    state = state.copyWith(
      isConectado: _repository.isDriveConectado,
    );
  }
}

class DriveState {
  final bool isLoading;
  final bool isConectado;
  final String? errorMessage;
  final String? successMessage;

  const DriveState({
    this.isLoading = false,
    this.isConectado = false,
    this.errorMessage,
    this.successMessage,
  });

  DriveState copyWith({
    bool? isLoading,
    bool? isConectado,
    String? errorMessage,
    String? successMessage,
  }) {
    return DriveState(
      isLoading: isLoading ?? this.isLoading,
      isConectado: isConectado ?? this.isConectado,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
