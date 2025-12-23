import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mapa_explorador.dart';
import './equipe_explorador_provider.dart';

/// Provider dos mapas disponiveis para selecao
/// Os mapas sao gerados uma vez e persistem ate o jogador escolher um
final mapasExploradorProvider =
    StateNotifierProvider<MapasExploradorNotifier, List<MapaExplorador>?>((ref) {
  final equipe = ref.watch(equipeExploradorProvider);
  return MapasExploradorNotifier(equipe?.tierAtual ?? 1);
});

/// Notifier dos mapas disponiveis
class MapasExploradorNotifier extends StateNotifier<List<MapaExplorador>?> {
  final int _tierAtual;

  MapasExploradorNotifier(this._tierAtual) : super(null);

  /// Gera novos mapas (so se ainda nao existirem)
  void gerarMapasSePreciso() {
    if (state == null || state!.isEmpty) {
      state = MapaExplorador.gerarOpcoes(_tierAtual);
    }
  }

  /// Forca geracao de novos mapas
  void gerarNovosMapas() {
    state = MapaExplorador.gerarOpcoes(_tierAtual);
  }

  /// Limpa os mapas (apos jogador escolher um)
  void limparMapas() {
    state = null;
  }

  /// Atualiza tier e regenera mapas se necessario
  void atualizarTier(int novoTier) {
    // Regenera mapas com o novo tier
    state = MapaExplorador.gerarOpcoes(novoTier);
  }
}
