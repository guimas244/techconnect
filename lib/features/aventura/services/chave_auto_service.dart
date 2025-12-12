import '../models/item_consumivel.dart';

/// Serviço para gerenciar o modo auto da Chave Auto
/// - Dura 2 andares ou até perder os 3 monstros
/// - Não usa consumíveis durante o auto
/// - Coleta drops consumíveis (máximo 3)
class ChaveAutoService {
  // Estado do modo chave auto
  bool _ativo = false;
  int _andaresRestantes = 0;
  List<ItemConsumivel> _dropsColetados = [];

  static const int maxDrops = 3;
  static const int duracaoAndares = 2;

  // Singleton
  static final ChaveAutoService _instance = ChaveAutoService._internal();
  factory ChaveAutoService() => _instance;
  ChaveAutoService._internal();

  // Getters
  bool get ativo => _ativo;
  int get andaresRestantes => _andaresRestantes;
  List<ItemConsumivel> get dropsColetados => List.unmodifiable(_dropsColetados);
  bool get podeColetarMaisDrops => _dropsColetados.length < maxDrops;

  /// Ativa o modo chave auto
  void ativar() {
    _ativo = true;
    _andaresRestantes = duracaoAndares;
    _dropsColetados = [];
    print('🔑 [ChaveAutoService] Modo Chave Auto ATIVADO! Andares: $_andaresRestantes');
  }

  /// Desativa o modo chave auto
  void desativar() {
    _ativo = false;
    _andaresRestantes = 0;
    print('🔑 [ChaveAutoService] Modo Chave Auto DESATIVADO');
  }

  /// Registra que um andar foi completado
  /// Retorna true se ainda há andares restantes, false se acabou
  bool completarAndar() {
    if (!_ativo) return false;

    _andaresRestantes--;
    print('🔑 [ChaveAutoService] Andar completado. Restantes: $_andaresRestantes');

    if (_andaresRestantes <= 0) {
      print('🔑 [ChaveAutoService] Todos os andares completados!');
      return false;
    }

    return true;
  }

  /// Adiciona um drop consumível à lista (máximo 3)
  /// Retorna true se foi adicionado, false se a lista está cheia
  bool adicionarDrop(ItemConsumivel drop) {
    if (!_ativo) return false;

    // Só coleta consumíveis válidos (não moedas/ovos de evento/itens especiais)
    if (drop.tipo == TipoItemConsumivel.moedaEvento ||
        drop.tipo == TipoItemConsumivel.moedaHalloween ||
        drop.tipo == TipoItemConsumivel.ovoEvento ||
        drop.tipo == TipoItemConsumivel.moedaChave ||
        drop.tipo == TipoItemConsumivel.chaveAuto ||
        drop.tipo == TipoItemConsumivel.jaulinha) {
      return false;
    }

    if (_dropsColetados.length >= maxDrops) {
      print('🔑 [ChaveAutoService] Lista de drops cheia (máx $maxDrops)');
      return false;
    }

    _dropsColetados.add(drop);
    print('🔑 [ChaveAutoService] Drop coletado: ${drop.nome} (${_dropsColetados.length}/$maxDrops)');
    return true;
  }

  /// Limpa os drops coletados após o jogador escolher
  void limparDrops() {
    _dropsColetados = [];
    print('🔑 [ChaveAutoService] Drops limpos');
  }

  /// Finaliza o modo chave auto e retorna os drops coletados
  List<ItemConsumivel> finalizar() {
    final drops = List<ItemConsumivel>.from(_dropsColetados);
    desativar();
    _dropsColetados = [];
    print('🔑 [ChaveAutoService] Finalizado com ${drops.length} drops');
    return drops;
  }

  /// Reseta completamente o serviço
  void reset() {
    _ativo = false;
    _andaresRestantes = 0;
    _dropsColetados = [];
    print('🔑 [ChaveAutoService] Reset completo');
  }
}
