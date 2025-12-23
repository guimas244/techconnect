import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kills_permanentes.dart';
import '../services/kills_hive_service.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/providers/user_provider.dart';

/// Provider do serviço Hive para kills permanentes
final killsHiveServiceProvider = Provider<KillsHiveService>((ref) {
  return KillsHiveService();
});

/// Provider que carrega as kills permanentes do usuário atual
final killsPermanentesProvider =
    StateNotifierProvider<KillsPermanentesNotifier, KillsPermanentes?>((ref) {
  final hiveService = ref.watch(killsHiveServiceProvider);
  final email = ref.watch(currentUserEmailProvider);
  return KillsPermanentesNotifier(hiveService, email);
});

/// Provider para obter kills de um tipo específico
final killsDoTipoProvider = Provider.family<int, Tipo>((ref, tipo) {
  final kills = ref.watch(killsPermanentesProvider);
  return kills?.getKills(tipo) ?? 0;
});

/// Provider para obter total de kills
final totalKillsPermanentesProvider = Provider<int>((ref) {
  final kills = ref.watch(killsPermanentesProvider);
  return kills?.totalKills ?? 0;
});

/// Notifier para gerenciar estado das kills permanentes
class KillsPermanentesNotifier extends StateNotifier<KillsPermanentes?> {
  final KillsHiveService _hiveService;
  final String? _email;

  KillsPermanentesNotifier(this._hiveService, this._email) : super(null) {
    _loadKills();
  }

  /// Carrega kills do storage
  Future<void> _loadKills() async {
    final email = _email;
    if (email == null || email.isEmpty) {
      print('[KillsPermanentesNotifier] Email nao disponivel, nao carregou kills');
      state = KillsPermanentes();
      return;
    }

    try {
      await _hiveService.init();
      final kills = await _hiveService.carregarKills(email);
      state = kills ?? KillsPermanentes();
      print('[KillsPermanentesNotifier] Kills carregadas: ${state?.totalKills ?? 0}');
    } catch (e) {
      print('[KillsPermanentesNotifier] Erro ao carregar kills: $e');
      state = KillsPermanentes();
    }
  }

  /// Adiciona kills de um tipo
  Future<bool> adicionarKills(Tipo tipo, int quantidade) async {
    final email = _email;
    if (email == null || email.isEmpty) {
      print('[KillsPermanentesNotifier] Email nao disponivel, nao adicionou kills');
      return false;
    }

    try {
      final novasKills = (state ?? KillsPermanentes()).adicionarKills(tipo, quantidade);
      state = novasKills;

      final sucesso = await _hiveService.salvarKills(email, novasKills);
      if (sucesso) {
        print('[KillsPermanentesNotifier] Adicionadas $quantidade kills de ${tipo.displayName}');
      }
      return sucesso;
    } catch (e) {
      print('[KillsPermanentesNotifier] Erro ao adicionar kills: $e');
      return false;
    }
  }

  /// Adiciona uma única kill
  Future<bool> adicionarKill(Tipo tipo) async {
    return adicionarKills(tipo, 1);
  }

  /// Gasta kills de um tipo (para compras na loja)
  Future<bool> gastarKills(Tipo tipo, int quantidade) async {
    final email = _email;
    if (email == null || email.isEmpty) {
      print('[KillsPermanentesNotifier] Email nao disponivel, nao gastou kills');
      return false;
    }

    final currentState = state;
    if (currentState == null) {
      return false;
    }

    final novasKills = currentState.gastarKills(tipo, quantidade);
    if (novasKills == null) {
      print('[KillsPermanentesNotifier] Kills insuficientes de ${tipo.displayName}');
      return false;
    }

    try {
      state = novasKills;
      final sucesso = await _hiveService.salvarKills(email, novasKills);
      if (sucesso) {
        print('[KillsPermanentesNotifier] Gastas $quantidade kills de ${tipo.displayName}');
      }
      return sucesso;
    } catch (e) {
      print('[KillsPermanentesNotifier] Erro ao gastar kills: $e');
      return false;
    }
  }

  /// Verifica se tem kills suficientes
  bool temKillsSuficientes(Tipo tipo, int quantidade) {
    return state?.temKillsSuficientes(tipo, quantidade) ?? false;
  }

  /// Obtém kills de um tipo
  int getKills(Tipo tipo) {
    return state?.getKills(tipo) ?? 0;
  }

  /// Recarrega kills do storage
  Future<void> reload() async {
    await _loadKills();
  }

  /// Limpa todas as kills (para debug/reset)
  Future<bool> limparKills() async {
    final email = _email;
    if (email == null || email.isEmpty) {
      return false;
    }

    try {
      final novoState = KillsPermanentes();
      state = novoState;
      final sucesso = await _hiveService.salvarKills(email, novoState);
      print('[KillsPermanentesNotifier] Kills limpas');
      return sucesso;
    } catch (e) {
      print('[KillsPermanentesNotifier] Erro ao limpar kills: $e');
      return false;
    }
  }
}
