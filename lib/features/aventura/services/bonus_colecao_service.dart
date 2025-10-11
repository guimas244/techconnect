import 'colecao_service.dart';

/// Sistema centralizado de bônus de coleções
/// Gerencia todos os bônus aplicados por ter monstros desbloqueados
class BonusColecaoService {
  final ColecaoService _colecaoService = ColecaoService();

  /// Retorna todos os bônus ativos para um jogador
  Future<BonusColecao> obterBonusAtivos(String email) async {
    try {
      print('🎁 [BonusColecaoService] Calculando bônus para: $email');

      // Conta monstros nostálgicos desbloqueados
      final monstrosNostalgicos = await _colecaoService.obterMonstrosNostalgicosDesbloqueados(email);
      final totalNostalgicos = monstrosNostalgicos.length;

      // Conta monstros Halloween desbloqueados
      final totalHalloween = await _colecaoService.contarMonstrosHalloweenDesbloqueados(email);

      // Calcula bônus
      final bonusVida = totalNostalgicos; // +1 HP por monstro nostálgico
      final bonusAtaque = (totalHalloween / 5).floor(); // +1 ATK a cada 5 monstros Halloween

      final bonus = BonusColecao(
        bonusVida: bonusVida,
        bonusAtaque: bonusAtaque,
        monstrosNostalgicos: totalNostalgicos,
        monstrosHalloween: totalHalloween,
      );

      print('✅ [BonusColecaoService] Bônus calculados:');
      print('   - Vida: +$bonusVida (de $totalNostalgicos monstros nostálgicos)');
      print('   - Ataque: +$bonusAtaque (de $totalHalloween monstros Halloween)');

      return bonus;
    } catch (e) {
      print('❌ [BonusColecaoService] Erro ao calcular bônus: $e');
      return BonusColecao.zero();
    }
  }

  /// Retorna apenas o bônus de vida (nostálgicos)
  Future<int> obterBonusVida(String email) async {
    final bonus = await obterBonusAtivos(email);
    return bonus.bonusVida;
  }

  /// Retorna apenas o bônus de ataque (Halloween)
  Future<int> obterBonusAtaque(String email) async {
    final bonus = await obterBonusAtivos(email);
    return bonus.bonusAtaque;
  }

  /// Retorna o total de monstros nostálgicos desbloqueados
  Future<int> obterTotalNostalgicos(String email) async {
    final monstros = await _colecaoService.obterMonstrosNostalgicosDesbloqueados(email);
    return monstros.length;
  }

  /// Retorna o total de monstros Halloween desbloqueados
  Future<int> obterTotalHalloween(String email) async {
    return await _colecaoService.contarMonstrosHalloweenDesbloqueados(email);
  }

  /// Retorna progresso para o próximo bônus de ataque Halloween
  /// Retorna (atual, necessário para próximo)
  Future<(int, int)> progressoProximoBonusAtaque(String email) async {
    final totalHalloween = await obterTotalHalloween(email);
    final bonusAtual = (totalHalloween / 5).floor();
    final proximoBonus = bonusAtual + 1;
    final necessarioParaProximo = (proximoBonus * 5);
    final faltam = necessarioParaProximo - totalHalloween;

    return (faltam, 5);
  }
}

/// Classe que representa os bônus ativos de coleção
class BonusColecao {
  final int bonusVida; // +1 por monstro nostálgico
  final int bonusAtaque; // +1 a cada 5 monstros Halloween
  final int monstrosNostalgicos; // Total desbloqueados
  final int monstrosHalloween; // Total desbloqueados

  const BonusColecao({
    required this.bonusVida,
    required this.bonusAtaque,
    required this.monstrosNostalgicos,
    required this.monstrosHalloween,
  });

  /// Bônus zerado (quando jogador não tem coleção)
  factory BonusColecao.zero() {
    return const BonusColecao(
      bonusVida: 0,
      bonusAtaque: 0,
      monstrosNostalgicos: 0,
      monstrosHalloween: 0,
    );
  }

  /// Verifica se tem algum bônus ativo
  bool get temBonus => bonusVida > 0 || bonusAtaque > 0;

  /// Descrição do bônus de vida
  String get descricaoVida => '+$bonusVida HP';

  /// Descrição do bônus de ataque
  String get descricaoAtaque => '+$bonusAtaque ATK';

  /// Descrição completa
  String get descricaoCompleta {
    if (!temBonus) return 'Nenhum bônus ativo';

    final parts = <String>[];
    if (bonusVida > 0) parts.add(descricaoVida);
    if (bonusAtaque > 0) parts.add(descricaoAtaque);

    return parts.join(' | ');
  }

  @override
  String toString() {
    return 'BonusColecao(vida: +$bonusVida, ataque: +$bonusAtaque, '
           'nostálgicos: $monstrosNostalgicos/30, halloween: $monstrosHalloween/30)';
  }
}
