import 'dart:convert';
import 'dart:math';
import '../../../core/services/google_drive_service.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/models/atributo_jogo_enum.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../models/monstro_inimigo.dart';
import '../models/item.dart';
import '../models/habilidade.dart';
import '../utils/gerador_habilidades.dart';
import '../services/item_service.dart';
import '../../tipagem/data/tipagem_repository.dart';

class AventuraRepository {
  final GoogleDriveService _driveService = GoogleDriveService();
  final TipagemRepository _tipagemRepository = TipagemRepository();
  final ItemService _itemService = ItemService();

  /// Verifica se o jogador já tem um histórico no Drive
  Future<bool> jogadorTemHistorico(String email) async {
    try {
      print('🔍 [Repository] Verificando histórico para: $email');
      final nomeArquivo = 'historico_$email.json';
      final conteudo = await _driveService.baixarArquivoDaPasta(nomeArquivo, 'historias');
      final temHistorico = conteudo.isNotEmpty;
      print('🔍 [Repository] Tem histórico: $temHistorico');
      return temHistorico;
    } catch (e) {
      print('❌ [Repository] Erro ao verificar histórico: $e');
      return false;
    }
  }

  /// Carrega o histórico do jogador do Drive
  Future<HistoriaJogador?> carregarHistoricoJogador(String email) async {
    try {
      print('📥 [Repository] Carregando histórico para: $email');
      final nomeArquivo = 'historico_$email.json';
      final conteudo = await _driveService.baixarArquivoDaPasta(nomeArquivo, 'historias');
      
      if (conteudo.isEmpty) {
        print('📥 [Repository] Conteúdo vazio');
        return null;
      }
      
      print('📥 [Repository] Conteúdo carregado: ${conteudo.length} caracteres');
      final json = jsonDecode(conteudo);
      final historia = HistoriaJogador.fromJson(json);
      print('📥 [Repository] História processada: ${historia.monstros.length} monstros');
      return historia;
    } catch (e) {
      print('❌ [Repository] Erro ao carregar histórico: $e');
      return null;
    }
  }

  /// Salva o histórico do jogador no Drive
  Future<bool> salvarHistoricoJogador(HistoriaJogador historia) async {
    try {
      print('💾 [Repository] Salvando histórico para: ${historia.email}');
      print('💾 [Repository] Dados da história:');
      print('   - Email: ${historia.email}');
      print('   - Monstros: ${historia.monstros.length}');
      print('   - Aventura iniciada: ${historia.aventuraIniciada}');
      print('   - Mapa: ${historia.mapaAventura}');
      print('   - Inimigos: ${historia.monstrosInimigos.length}');
      
      final nomeArquivo = 'historico_${historia.email}.json';
      print('💾 [Repository] Nome do arquivo: $nomeArquivo');
      
      // Tenta serializar JSON com try-catch específico
      String json;
      try {
        final jsonData = historia.toJson();
        print('💾 [Repository] Dados convertidos para Map com sucesso');
        json = jsonEncode(jsonData);
        print('💾 [Repository] JSON gerado: ${json.length} caracteres');
      } catch (jsonError, jsonStackTrace) {
        print('❌ [Repository] ERRO na serialização JSON: $jsonError');
        print('❌ [Repository] Stack trace JSON: $jsonStackTrace');
        return false;
      }
      
      print('💾 [Repository] Primeiros 300 chars do JSON: ${json.substring(0, json.length > 300 ? 300 : json.length)}...');
      
      print('💾 [Repository] Chamando DriveService.salvarArquivoEmPasta...');
      final sucesso = await _driveService.salvarArquivoEmPasta(nomeArquivo, json, 'historias');
      print('💾 [Repository] Resultado do salvamento: $sucesso');
      
      if (sucesso) {
        print('✅ [Repository] Histórico salvo com sucesso no Drive');
      } else {
        print('❌ [Repository] FALHA ao salvar no Drive');
      }
      
      return sucesso;
    } catch (e, stackTrace) {
      print('❌ [Repository] EXCEÇÃO ao salvar histórico: $e');
      print('❌ [Repository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Sorteia 3 monstros únicos para o jogador e já cria a aventura
  Future<HistoriaJogador> sortearMonstrosParaJogador(String email) async {
    final random = Random();
    final tiposDisponiveis = Tipo.values.where((t) => t != Tipo.desconhecido).toList();
    tiposDisponiveis.shuffle(random);

    final monstrosSorteados = <MonstroAventura>[];

    // Sorteia 3 tipos únicos
    for (int i = 0; i < 3 && i < tiposDisponiveis.length; i++) {
      final tipo = tiposDisponiveis[i];
      // Sorteia tipo extra diferente do principal (excluindo desconhecido)
      final outrosTipos = tiposDisponiveis.where((t) => t != tipo).toList();
      outrosTipos.shuffle(random);
      final tipoExtra = outrosTipos.first;
      
      // Gera 4 habilidades para o monstro
      final habilidades = GeradorHabilidades.gerarHabilidadesMonstro(tipo, tipoExtra);
      
      // Sorteia atributos usando os ranges definidos
      final monstro = MonstroAventura(
        tipo: tipo,
        tipoExtra: tipoExtra,
        imagem: 'assets/monstros_aventura/${tipo.name}.png',
        vida: AtributoJogo.vida.sortear(random),
        energia: AtributoJogo.energia.sortear(random),
        agilidade: AtributoJogo.agilidade.sortear(random),
        ataque: AtributoJogo.ataque.sortear(random),
        defesa: AtributoJogo.defesa.sortear(random),
        habilidades: habilidades,
        itemEquipado: null, // Sem item inicial
      );
      monstrosSorteados.add(monstro);
    }
    
    // Seleciona um mapa aleatório para a aventura
    final mapas = [
      'assets/mapas_aventura/cidade_abandonada.jpg',
      'assets/mapas_aventura/deserto.jpg',
      'assets/mapas_aventura/floresta_verde.jpg',
      'assets/mapas_aventura/praia.jpg',
      'assets/mapas_aventura/vulcao.jpg',
    ];
    final mapaEscolhido = mapas[random.nextInt(mapas.length)];
    print('🗺️ [Repository] Mapa escolhido para nova aventura: $mapaEscolhido');

    // Sorteia 5 monstros inimigos para a aventura (tier 1 - sem itens)
    final monstrosInimigos = await _sortearMonstrosInimigos(tierAtual: 1);
    print('👾 [Repository] Sorteados ${monstrosInimigos.length} monstros inimigos');
    
    final historia = HistoriaJogador(
      email: email,
      monstros: monstrosSorteados,
      aventuraIniciada: true,
      mapaAventura: mapaEscolhido,
      monstrosInimigos: monstrosInimigos,
    );
    
    // Salva automaticamente no Drive
    print('💾 [Repository] Tentando salvar aventura completa no Drive...');
    final sucessoSalvamento = await salvarHistoricoJogador(historia);
    if (sucessoSalvamento) {
      print('✅ [Repository] Aventura completa criada e salva com ${monstrosSorteados.length} monstros do jogador e ${monstrosInimigos.length} inimigos');
    } else {
      print('❌ [Repository] ERRO: Falha ao salvar aventura no Drive!');
      throw Exception('Falha ao salvar aventura no Drive');
    }
    
    return historia;
  }

  /// Verifica se todos os tipos de monstros foram baixados e estão disponíveis localmente
  Future<bool> verificarTiposBaixados() async {
    try {
      print('🔍 [Aventura] === VERIFICAÇÃO DETALHADA DE TIPOS BAIXADOS ===');
      
      // Status atual do TipagemRepository
      print('📊 [Aventura] Drive Conectado: ${_tipagemRepository.isDriveConectado}');
      print('📊 [Aventura] Foi Baixado do Drive: ${_tipagemRepository.foiBaixadoDoDrive}');
      print('📊 [Aventura] Is Inicializado: ${_tipagemRepository.isInicializado}');
      print('📊 [Aventura] Is Bloqueado: ${_tipagemRepository.isBloqueado}');
      
      // Verifica se os dados de tipagem estão disponíveis localmente
      final isInicializado = await _tipagemRepository.isInicializadoAsync;
      print('� [Aventura] Is Inicializado Async: $isInicializado');
      
      if (!isInicializado) {
        print('⚠️ [Aventura] Sistema não inicializado - verificando se pode inicializar...');
        
        // Tenta inicializar se estiver conectado ao Drive
        if (_tipagemRepository.isDriveConectado && _tipagemRepository.isBloqueado) {
          print('🔄 [Aventura] Drive conectado mas bloqueado - tentando inicializar...');
          final inicializou = await _tipagemRepository.inicializarComDrive();
          if (inicializou) {
            print('✅ [Aventura] Sistema inicializado com sucesso durante verificação!');
            return true;
          } else {
            print('❌ [Aventura] Falha na inicialização durante verificação');
            return false;
          }
        }
      }
      
      print('🔍 [Aventura] Resultado final da verificação: $isInicializado');
      return isInicializado;
    } catch (e) {
      print('❌ [Aventura] Erro ao verificar tipos baixados: $e');
      return false;
    }
  }

  /// Inicia uma nova aventura para o jogador
  Future<HistoriaJogador?> iniciarAventura(String email) async {
    try {
      print('🚀 [Repository] Iniciando aventura para: $email');
      
      // Carrega o histórico atual
      HistoriaJogador? historiaAtual = await carregarHistoricoJogador(email);
      
      // Se não há histórico, cria um novo
      if (historiaAtual == null) {
        print('📝 [Repository] Histórico não encontrado, criando novo histórico...');
        historiaAtual = await sortearMonstrosParaJogador(email);
        print('✅ [Repository] Novo histórico criado com aventura já iniciada');
        return historiaAtual;
      }

      // Verifica se já há uma aventura iniciada
      if (historiaAtual.aventuraIniciada) {
        print('🔄 [Repository] Aventura já iniciada! Carregando dados existentes...');
        print('🗺️ [Repository] Mapa existente: ${historiaAtual.mapaAventura}');
        print('👾 [Repository] Monstros existentes: ${historiaAtual.monstrosInimigos.length}');
        return historiaAtual; // Retorna a aventura existente
      }

      print('🆕 [Repository] Atualizando histórico existente para iniciar aventura...');
      
      // Seleciona um mapa aleatório
      final mapas = [
        'assets/mapas_aventura/cidade_abandonada.jpg',
        'assets/mapas_aventura/deserto.jpg',
        'assets/mapas_aventura/floresta_verde.jpg',
        'assets/mapas_aventura/praia.jpg',
        'assets/mapas_aventura/vulcao.jpg',
      ];
      final random = Random();
      final mapaEscolhido = mapas[random.nextInt(mapas.length)];
      print('🗺️ [Repository] Mapa escolhido para nova aventura: $mapaEscolhido');

      // Sorteia 5 monstros inimigos (apenas 1 tipo cada)
      final monstrosInimigos = await _sortearMonstrosInimigos(tierAtual: historiaAtual.tier);
      print('👾 [Repository] Sorteados ${monstrosInimigos.length} monstros inimigos');

      // Atualiza o histórico com a aventura iniciada
      final historiaAtualizada = historiaAtual.copyWith(
        aventuraIniciada: true,
        mapaAventura: mapaEscolhido,
        monstrosInimigos: monstrosInimigos,
      );

      // Salva no Drive
      final sucesso = await salvarHistoricoJogador(historiaAtualizada);
      if (sucesso) {
        print('✅ [Repository] Nova aventura criada e salva com sucesso');
        return historiaAtualizada;
      } else {
        print('❌ [Repository] Erro ao salvar nova aventura');
        return null;
      }
    } catch (e) {
      print('❌ [Repository] Erro ao iniciar aventura: $e');
      return null;
    }
  }

  /// Sorteia 5 monstros inimigos com tipos e habilidades
  Future<List<MonstroInimigo>> _sortearMonstrosInimigos({int tierAtual = 1}) async {
    final random = Random();
    final monstrosInimigos = <MonstroInimigo>[];
    
    for (int i = 0; i < 5; i++) {
      // Escolhe um tipo principal aleatório
      final tiposDisponiveis = Tipo.values.where((t) => t != Tipo.desconhecido).toList();
      final tipo = tiposDisponiveis[random.nextInt(tiposDisponiveis.length)];
      
      // Sorteia tipo extra diferente do principal (todos os monstros têm 2 tipos)
      final outrosTipos = tiposDisponiveis.where((t) => t != tipo).toList();
      outrosTipos.shuffle(random);
      final tipoExtra = outrosTipos.first;
      
      // Gera 4 habilidades para o monstro
      final habilidadesBase = GeradorHabilidades.gerarHabilidadesMonstro(tipo, tipoExtra);
      
      // Aplica evolução aleatória nas habilidades baseado no tier (tier 2+)
      final habilidades = _aplicarEvolucaoHabilidadesInimigo(habilidadesBase, tierAtual, random);
      
      // Gera item equipado baseado nas regras de tier
      Item? itemEquipado;
      if (tierAtual == 2) {
        // Tier 2: monstros sempre usam itens de tier 1
        itemEquipado = _itemService.gerarItemAleatorio(tierAtual: 1);
        print('🎯 [Repository] Monstro tier 2 recebeu item tier 1: ${itemEquipado.nome}');
      } else if (tierAtual >= 3) {
        // Tier 3+: 40% de chance de usar item de 1 tier abaixo, 60% chance de item do mesmo tier
        final chanceItem = random.nextInt(100);
        if (chanceItem < 40) {
          itemEquipado = _itemService.gerarItemAleatorio(tierAtual: tierAtual - 1);
          print('🎯 [Repository] Monstro tier $tierAtual recebeu item tier ${tierAtual - 1}: ${itemEquipado.nome} (40% chance)');
        } else {
          itemEquipado = _itemService.gerarItemAleatorio(tierAtual: tierAtual);
          print('🎯 [Repository] Monstro tier $tierAtual recebeu item tier $tierAtual: ${itemEquipado.nome} (60% chance)');
        }
      } else {
        // Tier 1: sem itens
        print('🎯 [Repository] Monstro tier 1 não recebe itens');
      }

      // Cria monstro inimigo com atributos sorteados
      // Level do inimigo = tier atual do mapa
      final monstro = MonstroInimigo(
        tipo: tipo,
        tipoExtra: tipoExtra,
        imagem: 'assets/monstros_aventura/${tipo.name}.png',
        vida: AtributoJogo.vida.sortear(random),
        energia: AtributoJogo.energia.sortear(random),
        agilidade: AtributoJogo.agilidade.sortear(random),
        ataque: AtributoJogo.ataque.sortear(random),
        defesa: AtributoJogo.defesa.sortear(random),
        habilidades: habilidades,
        itemEquipado: itemEquipado,
        level: tierAtual, // Level = tier do mapa
      );
      
      monstrosInimigos.add(monstro);
    }
    
    return monstrosInimigos;
  }

  /// Aplica evolução aleatória nas habilidades dos monstros inimigos baseado no tier
  /// Tier 2+: Para cada habilidade, 20% chance level = tier, 20% chance level = tier-1
  List<Habilidade> _aplicarEvolucaoHabilidadesInimigo(List<Habilidade> habilidadesBase, int tierAtual, Random random) {
    // Tier 1: habilidades permanecem level 1
    if (tierAtual == 1) {
      return habilidadesBase;
    }
    
    final habilidadesEvoluidas = <Habilidade>[];
    
    for (final habilidade in habilidadesBase) {
      final chance = random.nextInt(100);
      int novoLevel = 1; // Level padrão
      
      if (chance < 20) {
        // 20% chance: level = tier do andar
        novoLevel = tierAtual;
        print('✨ [Repository] Habilidade ${habilidade.nome} evoluiu para level $novoLevel (tier atual - 20% chance)');
      } else if (chance < 40) {
        // 20% chance: level = tier - 1 (nunca abaixo de 1)
        novoLevel = (tierAtual - 1).clamp(1, tierAtual);
        print('✨ [Repository] Habilidade ${habilidade.nome} evoluiu para level $novoLevel (tier-1 - 20% chance)');
      } else {
        // 60% chance: permanece level 1
        print('📝 [Repository] Habilidade ${habilidade.nome} permanece level 1 (60% chance)');
      }
      
      // Cria nova habilidade com o level calculado
      final habilidadeEvoluida = Habilidade(
        nome: habilidade.nome,
        descricao: habilidade.descricao,
        tipo: habilidade.tipo,
        efeito: habilidade.efeito,
        tipoElemental: habilidade.tipoElemental,
        valor: habilidade.valor,
        custoEnergia: habilidade.custoEnergia,
        level: novoLevel,
      );
      
      habilidadesEvoluidas.add(habilidadeEvoluida);
    }
    
    return habilidadesEvoluidas;
  }

  /// Gera novos monstros inimigos para um tier específico (método público)
  Future<List<MonstroInimigo>> gerarMonstrosInimigosPorTier(int tier) async {
    print('🆕 [Repository] Gerando monstros inimigos para tier $tier via método público');
    return await _sortearMonstrosInimigos(tierAtual: tier);
  }
}
