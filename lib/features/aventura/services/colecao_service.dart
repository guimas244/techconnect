import 'dart:convert';
import '../../../core/services/google_drive_service.dart';
import 'colecao_hive_service.dart';

class ColecaoService {
  final GoogleDriveService _driveService = GoogleDriveService();
  final ColecaoHiveService _hiveService = ColecaoHiveService();

  /// Carrega a coleção de um jogador (prioriza HIVE sobre Drive)
  /// Retorna um mapa com os monstros desbloqueados
  Future<Map<String, bool>> carregarColecaoJogador(String email) async {
    try {
      print('📥 [ColecaoService] Carregando coleção para: $email');

      // Inicializa HIVE se necessário
      await _hiveService.init();

      // 1º: Tenta carregar do HIVE (local)
      final colecaoHive = await _hiveService.carregarColecao(email);
      if (colecaoHive != null) {
        print('✅ [ColecaoService] Coleção carregada do HIVE: ${colecaoHive.length} monstros');
        return colecaoHive;
      }

      print('📭 [ColecaoService] Nenhuma coleção encontrada no HIVE para $email');

      // 2º: Se não encontrou no HIVE, tenta carregar do Drive
      final nomeArquivo = 'colecao_$email.json';
      final conteudo = await _driveService.baixarArquivoDaPasta(nomeArquivo, 'colecao');

      if (conteudo.isNotEmpty) {
        print('📥 [ColecaoService] Coleção encontrada no Drive, salvando no HIVE');

        final dados = jsonDecode(conteudo) as Map<String, dynamic>;
        final colecao = Map<String, bool>.from(dados['monstros'] ?? {});

        // Salva no HIVE para próximas consultas
        await _hiveService.salvarColecao(email, colecao);
        await _hiveService.marcarComoSincronizada(email);

        print('✅ [ColecaoService] Coleção sincronizada do Drive para HIVE: ${colecao.length} monstros');
        return colecao;
      }

      // 3º: Se não encontrou em lugar nenhum, cria inicial
      print('📭 [ColecaoService] Nenhuma coleção encontrada, criando inicial');
      return await _criarColecaoInicial(email);
    } catch (e) {
      print('❌ [ColecaoService] Erro ao carregar coleção: $e');
      // Se der erro, cria uma coleção inicial
      return await _criarColecaoInicial(email);
    }
  }

  /// Salva a coleção de um jogador (HIVE primeiro, depois Drive)
  Future<bool> salvarColecaoJogador(String email, Map<String, bool> colecao) async {
    try {
      print('💾 [ColecaoService] Salvando coleção para: $email');

      // Inicializa HIVE se necessário
      await _hiveService.init();

      // 1º: Salva no HIVE (local - prioridade)
      final sucessoHive = await _hiveService.salvarColecao(email, colecao);
      if (!sucessoHive) {
        print('❌ [ColecaoService] Falha ao salvar no HIVE');
        return false;
      }

      print('✅ [ColecaoService] Coleção salva no HIVE');

      // 2º: Salva no Drive (sincronização)
      try {
        final dados = {
          'email': email,
          'monstros': colecao,
          'ultima_atualizacao': DateTime.now().toIso8601String(),
        };

        final nomeArquivo = 'colecao_$email.json';
        final json = jsonEncode(dados);

        final sucessoDrive = await _driveService.salvarArquivoEmPasta(nomeArquivo, json, 'colecao');

        if (sucessoDrive) {
          // Marca como sincronizada se salvar no Drive
          await _hiveService.marcarComoSincronizada(email);
          print('✅ [ColecaoService] Coleção salva no Drive e marcada como sincronizada');
        } else {
          print('⚠️ [ColecaoService] Falha ao salvar no Drive, mas dados salvos localmente');
        }

        return true; // Retorna sucesso se salvou no HIVE, mesmo que falhe no Drive
      } catch (e) {
        print('⚠️ [ColecaoService] Erro ao salvar no Drive: $e - dados mantidos no HIVE');
        return true; // Ainda considera sucesso se salvou no HIVE
      }
    } catch (e) {
      print('❌ [ColecaoService] Erro ao salvar coleção: $e');
      return false;
    }
  }

  /// Desbloqueia um monstro específico na coleção do jogador
  Future<bool> desbloquearMonstro(String email, String nomeMonstro) async {
    try {
      print('🔓 [ColecaoService] Desbloqueando monstro $nomeMonstro para $email');

      // Carrega a coleção atual
      final colecao = await carregarColecaoJogador(email);

      // Desbloqueia o monstro
      colecao[nomeMonstro] = true;

      // Salva a coleção atualizada
      return await salvarColecaoJogador(email, colecao);
    } catch (e) {
      print('❌ [ColecaoService] Erro ao desbloquear monstro: $e');
      return false;
    }
  }

  /// Retorna uma lista dos monstros desbloqueados da coleção nostálgica
  Future<List<String>> obterMonstrosNostalgicosDesbloqueados(String email) async {
    try {
      print('🔍 [ColecaoService] Obtendo monstros nostálgicos desbloqueados para: $email');

      final colecao = await carregarColecaoJogador(email);

      // Lista dos 30 monstros nostálgicos (baseado nos assets)
      final monstrosNostalgicos = [
        'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
        'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
        'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
        'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
        'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi'
      ];

      // Filtra apenas os monstros nostálgicos que estão desbloqueados
      final desbloqueados = monstrosNostalgicos.where((monstro) => colecao[monstro] == true).toList();

      print('✅ [ColecaoService] Monstros nostálgicos desbloqueados: ${desbloqueados.length}');
      print('📋 [ColecaoService] Lista: $desbloqueados');

      return desbloqueados;
    } catch (e) {
      print('❌ [ColecaoService] Erro ao obter monstros nostálgicos: $e');
      return [];
    }
  }

  /// Verifica se um monstro está desbloqueado
  Future<bool> monstroEstaDesbloqueado(String email, String nomeMonstro) async {
    try {
      final colecao = await carregarColecaoJogador(email);
      return colecao[nomeMonstro] == true;
    } catch (e) {
      print('❌ [ColecaoService] Erro ao verificar monstro desbloqueado: $e');
      return false;
    }
  }

  /// Cria uma coleção inicial para um novo jogador (todos bloqueados)
  Future<Map<String, bool>> _criarColecaoInicial(String email) async {
    print('🆕 [ColecaoService] Criando coleção inicial para: $email');

    // Inicializa HIVE se necessário
    await _hiveService.init();

    // Usa o método do HIVE service para criar coleção padrão
    final colecaoInicial = _hiveService.criarColecaoInicial();

    // Salva a coleção inicial (HIVE + Drive)
    await salvarColecaoJogador(email, colecaoInicial);

    print('✅ [ColecaoService] Coleção inicial criada com ${colecaoInicial.length} monstros');
    return colecaoInicial;
  }

  /// MÉTODO PARA TESTE - Desbloqueia alguns monstros nostálgicos específicos
  Future<bool> desbloquearMonstrosParaTeste(String email) async {
    try {
      print('🧪 [ColecaoService] Desbloqueando monstros para teste para: $email');

      final colecao = await carregarColecaoJogador(email);

      // Desbloqueia TODOS os 30 monstros nostálgicos para teste
      final monstrosParaTeste = [
        'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
        'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
        'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
        'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
        'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi'
      ];

      for (final monstro in monstrosParaTeste) {
        colecao[monstro] = true;
        print('🔓 [ColecaoService] TESTE: Desbloqueado $monstro');
      }

      // Salva a coleção atualizada
      final sucesso = await salvarColecaoJogador(email, colecao);

      if (sucesso) {
        print('✅ [ColecaoService] TESTE: Monstros desbloqueados com sucesso');
      }

      return sucesso;
    } catch (e) {
      print('❌ [ColecaoService] Erro ao desbloquear monstros para teste: $e');
      return false;
    }
  }

  /// Desbloqueia monstros aleatórios para teste (método de desenvolvimento)
  Future<bool> desbloquearMonstrosAleatorios(String email, int quantidade) async {
    try {
      print('🎲 [ColecaoService] Desbloqueando $quantidade monstros aleatórios para $email');

      final colecao = await carregarColecaoJogador(email);
      final monstrosBloqueados = colecao.entries
          .where((entry) => entry.value == false)
          .map((entry) => entry.key)
          .toList();

      if (monstrosBloqueados.isEmpty) {
        print('⚠️ [ColecaoService] Todos os monstros já estão desbloqueados');
        return true;
      }

      // Embaralha e pega a quantidade solicitada
      monstrosBloqueados.shuffle();
      final parasDesbloquear = monstrosBloqueados.take(quantidade).toList();

      // Desbloqueia os monstros
      for (final monstro in parasDesbloquear) {
        colecao[monstro] = true;
      }

      print('🔓 [ColecaoService] Monstros desbloqueados: $parasDesbloquear');

      // Salva a coleção atualizada
      return await salvarColecaoJogador(email, colecao);
    } catch (e) {
      print('❌ [ColecaoService] Erro ao desbloquear monstros aleatórios: $e');
      return false;
    }
  }

  /// Força refresh da coleção (baixa do Drive novamente)
  Future<bool> refreshColecao(String email) async {
    try {
      print('🔄 [ColecaoService] Forçando refresh da coleção para: $email');

      // Inicializa HIVE se necessário
      await _hiveService.init();

      // Remove a coleção local para forçar re-download
      await _hiveService.removerColecao(email);

      // Carrega novamente (vai buscar do Drive)
      final colecao = await carregarColecaoJogador(email);

      print('✅ [ColecaoService] Refresh concluído: ${colecao.length} monstros');
      return true;
    } catch (e) {
      print('❌ [ColecaoService] Erro no refresh: $e');
      return false;
    }
  }

  /// Verifica status de sincronização
  Future<bool> estaSincronizada(String email) async {
    try {
      await _hiveService.init();
      return await _hiveService.estaSincronizada(email);
    } catch (e) {
      print('❌ [ColecaoService] Erro ao verificar sincronização: $e');
      return false;
    }
  }
}