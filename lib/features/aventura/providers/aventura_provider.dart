import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/aventura_repository.dart';
import '../models/historia_jogador.dart';

// Provider para o repository
final aventuraRepositoryProvider = Provider<AventuraRepository>((ref) {
  return AventuraRepository();
});

// Provider para verificar se pode acessar aventura (Drive conectado + tipos baixados)
final podeAcessarAventuraProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(aventuraRepositoryProvider);
  
  try {
    print('🔍 [AventuraProvider] Verificando se pode acessar aventura...');
    final tiposBaixados = await repository.verificarTiposBaixados();
    print('🔍 [AventuraProvider] Tipos baixados: $tiposBaixados');
    return tiposBaixados;
  } catch (e) {
    print('❌ [AventuraProvider] Erro ao verificar acesso: $e');
    return false;
  }
});

// Provider para verificar se jogador tem histórico
final jogadorTemHistoricoProvider = FutureProvider.family<bool, String>((ref, email) async {
  final repository = ref.watch(aventuraRepositoryProvider);
  return await repository.jogadorTemHistorico(email);
});

// Provider para carregar histórico do jogador
final historiaJogadorProvider = FutureProvider.family<HistoriaJogador?, String>((ref, email) async {
  final repository = ref.watch(aventuraRepositoryProvider);
  return await repository.carregarHistoricoJogador(email);
});

// StateProvider para controlar o estado da tela (tem histórico, pode sortear, etc.)
enum AventuraEstado {
  carregando,
  semHistorico,
  temHistorico,
  podeIniciar,
  aventuraIniciada,
  erro,
}

final aventuraEstadoProvider = StateProvider<AventuraEstado>((ref) {
  return AventuraEstado.carregando;
});

// Provider para sortear monstros
final sortearMonstrosProvider = FutureProvider.family<HistoriaJogador?, String>((ref, email) async {
  final repository = ref.watch(aventuraRepositoryProvider);
  
  try {
    final historia = await repository.sortearMonstrosParaJogador(email);
    
    // Atualiza o estado para "pode iniciar"
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;
    
    return historia;
  } catch (e) {
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
    return null;
  }
});
