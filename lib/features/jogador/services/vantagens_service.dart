import '../models/vantagem_colecao.dart';
import '../../../core/models/vantagem_colecao_enum.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/services/colecao_service.dart';

class VantagensService {
  final ColecaoService _colecaoService = ColecaoService();

  /// Define todas as coleções disponíveis e suas vantagens
  static const List<VantagemColecao> _colecoes = [
    // Coleção Nostálgica - Cura pós-batalha
    VantagemColecao(
      id: 'nostalgica',
      nomeColecao: 'Coleção Nostálgica',
      descricaoColecao: 'Monstros clássicos que trazem memórias do passado',
      tipoVantagem: TipoVantagemColecao.curaPosBatalha,
      valor: 1.0, // +1 HP por batalha
      monstrosRequeridos: 30, // Total de monstros nostálgicos
      monstrosDesbloqueados: 0, // Será calculado dinamicamente
      tiposRequeridos: [
        Tipo.agua, Tipo.alien, Tipo.desconhecido, Tipo.deus, Tipo.docrates,
        Tipo.dragao, Tipo.eletrico, Tipo.fantasma, Tipo.fera, Tipo.fogo,
        Tipo.gelo, Tipo.inseto, Tipo.luz, Tipo.magico, Tipo.marinho,
        Tipo.mistico, Tipo.normal, Tipo.nostalgico, Tipo.pedra, Tipo.planta,
        Tipo.psiquico, Tipo.subterraneo, Tipo.tecnologia, Tipo.tempo,
        Tipo.terrestre, Tipo.trevas, Tipo.venenoso, Tipo.vento, Tipo.voador, Tipo.zumbi
      ],
      imagemColecao: 'assets/colecoes/nostalgica.png', // Será exibido ícone se não existir
      ehNostalgica: true,
    ),

    // FUTURAS COLEÇÕES (comentadas temporariamente)

    // VantagemColecao(
    //   id: 'elemental',
    //   nomeColecao: 'Coleção Elemental',
    //   descricaoColecao: 'Dominar os elementos da natureza',
    //   tipoVantagem: TipoVantagemColecao.bonusAtaque,
    //   valor: 5.0, // +5 ATK
    //   monstrosRequeridos: 10,
    //   monstrosDesbloqueados: 0,
    //   tiposRequeridos: [
    //     Tipo.fogo, Tipo.agua, Tipo.eletrico, Tipo.gelo, Tipo.vento,
    //     Tipo.pedra, Tipo.planta, Tipo.luz, Tipo.trevas, Tipo.venenoso
    //   ],
    //   imagemColecao: 'assets/colecoes/elemental.png',
    // ),

    // VantagemColecao(
    //   id: 'lendaria',
    //   nomeColecao: 'Coleção Lendária',
    //   descricaoColecao: 'Criaturas de poder incomensurável',
    //   tipoVantagem: TipoVantagemColecao.bonusExperiencia,
    //   valor: 25.0, // +25% EXP
    //   monstrosRequeridos: 5,
    //   monstrosDesbloqueados: 0,
    //   tiposRequeridos: [
    //     Tipo.deus, Tipo.dragao, Tipo.mistico, Tipo.tempo, Tipo.alien
    //   ],
    //   imagemColecao: 'assets/colecoes/lendaria.png',
    // ),
  ];

  /// Carrega as vantagens atuais do jogador baseado em sua coleção
  Future<List<VantagemColecao>> carregarVantagensJogador(String email) async {
    try {
      print('🎯 [VantagensService] Carregando vantagens para: $email');

      // Carrega a coleção completa do jogador
      final colecaoJogador = await _colecaoService.carregarColecaoJogador(email);

      // Atualiza cada coleção com o progresso atual
      final vantagensAtualizadas = <VantagemColecao>[];

      for (final colecao in _colecoes) {
        // Conta quantos monstros desta coleção o jogador possui
        int monstrosDesbloqueados = 0;

        for (final tipo in colecao.tiposRequeridos) {
          if (colecaoJogador[tipo.name] == true) {
            monstrosDesbloqueados++;
          }
        }

        // Cria uma nova instância com o progresso atualizado
        final colecaoAtualizada = colecao.copyWith(
          monstrosDesbloqueados: monstrosDesbloqueados,
        );

        vantagensAtualizadas.add(colecaoAtualizada);

        print('🎯 [VantagensService] ${colecao.nomeColecao}: $monstrosDesbloqueados/${colecao.monstrosRequeridos} (${colecaoAtualizada.status.nome})');
      }

      print('✅ [VantagensService] ${vantagensAtualizadas.length} coleções carregadas');
      return vantagensAtualizadas;
    } catch (e) {
      print('❌ [VantagensService] Erro ao carregar vantagens: $e');
      return _colecoes; // Retorna coleções vazias em caso de erro
    }
  }

  /// Retorna apenas as vantagens ativas (completas)
  Future<List<VantagemColecao>> obterVantagensAtivas(String email) async {
    final todasVantagens = await carregarVantagensJogador(email);
    return todasVantagens.where((v) => v.status == StatusVantagem.ativa).toList();
  }

  /// Calcula o valor total de uma vantagem específica
  Future<double> calcularBonusTotal(String email, TipoVantagemColecao tipoVantagem) async {
    final vantagensAtivas = await obterVantagensAtivas(email);

    double bonusTotal = 0.0;
    for (final vantagem in vantagensAtivas) {
      if (vantagem.tipoVantagem == tipoVantagem) {
        bonusTotal += vantagem.valor;
      }
    }

    return bonusTotal;
  }

  /// Método específico para obter a cura pós-batalha (para usar no sistema de batalha)
  Future<int> obterCuraPosBatalha(String email) async {
    final bonus = await calcularBonusTotal(email, TipoVantagemColecao.curaPosBatalha);
    return bonus.round();
  }

  /// Método para obter bônus de ataque total
  Future<int> obterBonusAtaque(String email) async {
    final bonus = await calcularBonusTotal(email, TipoVantagemColecao.bonusAtaque);
    return bonus.round();
  }

  /// Método para obter bônus de defesa total
  Future<int> obterBonusDefesa(String email) async {
    final bonus = await calcularBonusTotal(email, TipoVantagemColecao.bonusDefesa);
    return bonus.round();
  }

  /// Método para obter bônus de experiência (em %)
  Future<double> obterBonusExperiencia(String email) async {
    return await calcularBonusTotal(email, TipoVantagemColecao.bonusExperiencia);
  }

  /// Retorna um resumo das vantagens ativas para debug
  Future<String> obterResumoVantagens(String email) async {
    final vantagensAtivas = await obterVantagensAtivas(email);

    if (vantagensAtivas.isEmpty) {
      return 'Nenhuma vantagem ativa';
    }

    final resumos = vantagensAtivas.map((v) =>
      '${v.nomeColecao}: ${v.valorFormatado}'
    ).join(', ');

    return 'Vantagens ativas: $resumos';
  }
}