import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mapa_explorador.dart';
import './equipe_explorador_provider.dart';

/// Estado dos mapas: lista de mapas + indices dos mapas abandonados
class MapasExploradorState {
  final List<MapaExplorador>? mapas;
  final Set<int> mapasDesistidos;

  const MapasExploradorState({
    this.mapas,
    this.mapasDesistidos = const {},
  });

  MapasExploradorState copyWith({
    List<MapaExplorador>? mapas,
    Set<int>? mapasDesistidos,
  }) {
    return MapasExploradorState(
      mapas: mapas ?? this.mapas,
      mapasDesistidos: mapasDesistidos ?? this.mapasDesistidos,
    );
  }
}

/// Provider dos mapas disponiveis para selecao
/// Os mapas sao gerados uma vez e persistem ate o jogador escolher um
final mapasExploradorProvider =
    StateNotifierProvider<MapasExploradorNotifier, MapasExploradorState>((ref) {
  final equipe = ref.watch(equipeExploradorProvider);
  return MapasExploradorNotifier(equipe?.tierAtual ?? 1);
});

/// Notifier dos mapas disponiveis
class MapasExploradorNotifier extends StateNotifier<MapasExploradorState> {
  final int _tierAtual;

  MapasExploradorNotifier(this._tierAtual) : super(const MapasExploradorState());

  /// Gera novos mapas (so se ainda nao existirem)
  void gerarMapasSePreciso() {
    if (state.mapas == null || state.mapas!.isEmpty) {
      state = MapasExploradorState(
        mapas: MapaExplorador.gerarOpcoes(_tierAtual),
        mapasDesistidos: {},
      );
    }
  }

  /// Forca geracao de novos mapas (limpa desistidos)
  void gerarNovosMapas() {
    state = MapasExploradorState(
      mapas: MapaExplorador.gerarOpcoes(_tierAtual),
      mapasDesistidos: {},
    );
  }

  /// Limpa os mapas (apos jogador escolher um)
  void limparMapas() {
    state = const MapasExploradorState();
  }

  /// Atualiza tier e regenera mapas se necessario
  void atualizarTier(int novoTier) {
    state = MapasExploradorState(
      mapas: MapaExplorador.gerarOpcoes(novoTier),
      mapasDesistidos: {},
    );
  }

  /// Marca um mapa como desistido (pelo indice)
  void marcarDesistido(int index) {
    state = state.copyWith(
      mapasDesistidos: {...state.mapasDesistidos, index},
    );
  }

  /// Verifica se um mapa foi desistido
  bool isDesistido(int index) {
    return state.mapasDesistidos.contains(index);
  }
}
