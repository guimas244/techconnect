import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/aventura_repository.dart';
import '../models/historia_jogador.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../tipagem/data/tipagem_repository.dart';

// Provider para o repository
final aventuraRepositoryProvider = Provider<AventuraRepository>((ref) {
  return AventuraRepository();
});

// Provider para verificar se pode acessar aventura (Drive conectado + tipos baixados)
final podeAcessarAventuraProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(aventuraRepositoryProvider);
  
  try {
    print('🔍 [AventuraProvider] === VERIFICAÇÃO DE ACESSO À AVENTURA ===');
    print('🔍 [AventuraProvider] Iniciando verificação...');
    
    final tiposBaixados = await repository.verificarTiposBaixados();
    print('🔍 [AventuraProvider] Tipos baixados: $tiposBaixados');
    
    // Diagnóstico detalhado adicional
    final tipagemRepository = TipagemRepository();
    print('📊 [AventuraProvider] === DIAGNÓSTICO DETALHADO DE TIPAGEM ===');
    print('📊 [AventuraProvider] Drive Conectado: ${tipagemRepository.isDriveConectado}');
    print('📊 [AventuraProvider] Foi Baixado do Drive: ${tipagemRepository.foiBaixadoDoDrive}');
    print('📊 [AventuraProvider] Is Inicializado: ${tipagemRepository.isInicializado}');
    print('📊 [AventuraProvider] Is Bloqueado: ${tipagemRepository.isBloqueado}');
    
    final isInicializadoAsync = await tipagemRepository.isInicializadoAsync;
    print('📊 [AventuraProvider] Is Inicializado Async: $isInicializadoAsync');
    
    // Verificação individual de tipos salvos no Hive
    print('🗃️ [AventuraProvider] Verificando tipos individuais salvos no Hive...');
    int tiposEncontradosNoHive = 0;
    for (final tipo in Tipo.values) {
      try {
        final dados = await tipagemRepository.carregarDadosTipo(tipo);
        if (dados != null && dados.isNotEmpty) {
          tiposEncontradosNoHive++;
          print('✅ [AventuraProvider] Tipo ${tipo.name}: ${dados.length} dados no Hive');
        } else {
          print('❌ [AventuraProvider] Tipo ${tipo.name}: NENHUM DADO NO HIVE');
        }
      } catch (e) {
        print('❌ [AventuraProvider] Tipo ${tipo.name}: ERRO no Hive - $e');
      }
    }
    
    print('� [AventuraProvider] RESUMO FINAL: $tiposEncontradosNoHive/${Tipo.values.length} tipos salvos no Hive');
    print('📊 [AventuraProvider] Resultado final: $tiposBaixados');
    
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
