import 'dart:convert';
import '../../../core/services/google_drive_service.dart';
import '../models/drop_jogador.dart';
import 'excel_reader_service.dart';
import 'recompensa_service.dart';

class DropsService {
  final GoogleDriveService _driveService = GoogleDriveService();
  final ExcelReaderService _excelReader = ExcelReaderService();

  /// Nome do arquivo de drops para um jogador específico
  String _getDropsFileName(String email) {
    return 'drops_$email.json';
  }

  /// Verifica se o jogador tem arquivo de drops
  Future<bool> jogadorTemDrops(String email) async {
    try {
      final fileName = _getDropsFileName(email);
      // Tenta baixar o arquivo da pasta 'drops'
      final jsonString = await _driveService.baixarArquivoDaPasta(fileName, 'drops');
      final hasData = jsonString.isNotEmpty;
      print('🎁 [DropsService] Jogador $email tem drops: $hasData');
      return hasData;
    } catch (e) {
      print('❌ [DropsService] Erro ao verificar drops do jogador $email: $e');
      return false;
    }
  }

  /// Carrega os drops de um jogador
  Future<DropJogador?> carregarDrops(String email) async {
    try {
      final fileName = _getDropsFileName(email);
      
      if (!await jogadorTemDrops(email)) {
        print('📁 [DropsService] Arquivo de drops não existe para $email, criando novo...');
        return _criarDropsVazio(email);
      }

      // Baixa da pasta 'drops' específica
      final jsonString = await _driveService.baixarArquivoDaPasta(fileName, 'drops');
      if (jsonString.isEmpty) {
        print('📁 [DropsService] Erro ao baixar arquivo de drops para $email, criando novo...');
        return _criarDropsVazio(email);
      }
      
      final jsonData = jsonDecode(jsonString);
      
      final drops = DropJogador.fromJson(jsonData);
      print('✅ [DropsService] Drops carregados para $email: ${drops.itens.length} itens');
      
      return drops;
    } catch (e) {
      print('❌ [DropsService] Erro ao carregar drops de $email: $e');
      return _criarDropsVazio(email);
    }
  }

  /// Salva os drops de um jogador na pasta 'drops'
  Future<void> salvarDrops(DropJogador drops) async {
    try {
      final fileName = _getDropsFileName(drops.email);
      final jsonString = jsonEncode(drops.toJson());
      
      // Salva na pasta 'drops'
      final sucesso = await _driveService.salvarArquivoEmPasta(fileName, jsonString, 'drops');
      if (!sucesso) {
        throw Exception('Falha ao salvar drops na pasta drops do Drive');
      }
      
      print('✅ [DropsService] Drops salvos para ${drops.email} na pasta drops');
      
    } catch (e) {
      print('❌ [DropsService] Erro ao salvar drops de ${drops.email}: $e');
      throw Exception('Falha ao salvar drops: $e');
    }
  }

  /// Adiciona recompensas mockadas (compatibilidade)
  @Deprecated('Use adicionarRecompensasBaseadasNoScore com score real')
  Future<void> adicionarRecompensasMockadas(String email) async {
    print('⚠️ [DropsService] Método adicionarRecompensasMockadas está deprecated, não gerando itens');
    print('💡 [DropsService] Use adicionarRecompensasBaseadasNoScore(email, scoreReal, tierReal)');
    // Não gera nenhum item para evitar duplicação
  }

  /// Adiciona recompensas usando o sistema baseado no score real
  Future<void> adicionarRecompensasBaseadasNoScore(String email, int scoreReal, int tierReal) async {
    try {
      print('🎁 [DropsService] Iniciando sistema de recompensas baseado no score para $email...');
      
      final dropsAtual = await carregarDrops(email) ?? _criarDropsVazio(email);
      
      print('🎯 [DropsService] Score do jogador: $scoreReal, Tier: $tierReal');
      
      // Gera múltiplos itens baseado no score usando excel/planilha
      final itensGerados = await _gerarItensBaseadosNoScore(scoreReal, tierReal);
      
      if (itensGerados.isNotEmpty) {
        final dropsAtualizados = dropsAtual.copyWith(
          itens: [...dropsAtual.itens, ...itensGerados],
          ultimaAtualizacao: DateTime.now(),
        );
        
        await salvarDrops(dropsAtualizados);
        print('🎁 [DropsService] ${itensGerados.length} recompensas adicionadas para $email');
        
        // Log de cada item
        for (var item in itensGerados) {
          print('   📦 ${item.nome} (${item.tipo})');
        }
      } else {
        print('⚠️ [DropsService] Nenhum item gerado pelo sistema de score, usando fallback...');
        await _adicionarRecompensasPadrao(email);
      }
      
    } catch (e) {
      print('❌ [DropsService] Erro ao adicionar recompensas baseadas no score: $e');
      
      // Fallback para itens padrão em caso de erro
      await _adicionarRecompensasPadrao(email);
    }
  }

  /// Gera múltiplos itens da planilha baseado no score
  Future<List<DropItem>> _gerarItensBaseadosNoScore(int score, int tier) async {
    final List<DropItem> itensGerados = [];
    
    try {
      print('🎲 [DropsService] Aplicando regras de score para recompensas da planilha...');
      
      // Verifica se tem score mínimo
      if (score < 1) {
        print('❌ [DropsService] Score insuficiente ($score < 1)');
        return itensGerados;
      }
      
      // 1. Drop fixo garantido
      final itemFixo = await _lerItemDoExcel();
      if (itemFixo != null) {
        itensGerados.add(itemFixo);
        print('✅ [DropsService] 1º item (fixo garantido): ${itemFixo.nome}');
      }
      
      // 2. Drops adicionais baseados no score (3% por score)
      int dropsAdicionais = _calcularDropsAdicionaisPlanilha(score);
      for (int i = 0; i < dropsAdicionais; i++) {
        final itemAdicional = await _lerItemDoExcel();
        if (itemAdicional != null) {
          itensGerados.add(itemAdicional);
          print('✅ [DropsService] Item adicional ${i + 1}: ${itemAdicional.nome}');
        }
      }
      
      // 3. Super Drop (dobrar quantidade) - 1% por 2 de score
      bool superDrop = _calcularSuperDropPlanilha(score);
      if (superDrop) {
        print('🌟 [DropsService] SUPER DROP ATIVADO! Dobrando itens da planilha!');
        final itensOriginais = List<DropItem>.from(itensGerados);
        for (var _ in itensOriginais) {
          final itemDuplicado = await _lerItemDoExcel();
          if (itemDuplicado != null) {
            itensGerados.add(itemDuplicado);
            print('⭐ [DropsService] Item duplicado: ${itemDuplicado.nome}');
          }
        }
      }
      
      print('🎁 [DropsService] Total de itens gerados da planilha: ${itensGerados.length}');
      
    } catch (e) {
      print('❌ [DropsService] Erro ao gerar itens baseados no score: $e');
    }
    
    return itensGerados;
  }

  /// Calcula drops adicionais para recompensas da planilha
  int _calcularDropsAdicionaisPlanilha(int score) {
    final chanceTotal = score * 3; // 3% por score
    int dropsGarantidos = chanceTotal ~/ 100; // Quantos drops são garantidos
    int chanceRestante = chanceTotal % 100; // Chance restante em %
    
    print('📊 [DropsService] Drops adicionais: Score $score × 3% = ${chanceTotal}% total');
    print('📊 [DropsService] = $dropsGarantidos garantidos + ${chanceRestante}% restante');
    
    // Sorteia para a chance restante
    if (chanceRestante > 0) {
      final numeroSorteado = DateTime.now().millisecondsSinceEpoch % 100; // Random baseado no tempo
      final ganhouExtra = numeroSorteado < chanceRestante;
      print('🎲 [DropsService] Sorteio extra: $numeroSorteado/100 (precisa < $chanceRestante) → ${ganhouExtra ? 'GANHOU' : 'não ganhou'}');
      if (ganhouExtra) {
        dropsGarantidos++;
      }
    }
    
    print('🎯 [DropsService] Total drops adicionais: $dropsGarantidos');
    return dropsGarantidos;
  }

  /// Calcula se ativa Super Drop para recompensas da planilha
  bool _calcularSuperDropPlanilha(int score) {
    final chanceTotal = (score ~/ 2) * 1; // 1% por cada 2 de score
    final chanceReal = chanceTotal.clamp(0, 100); // Máximo 100%
    
    print('📊 [DropsService] Super Drop: Score $score ÷ 2 = ${score ~/ 2} × 1% = ${chanceTotal}% (máx 100%)');
    print('📊 [DropsService] Chance final: ${chanceReal}%');
    
    final numeroSorteado = DateTime.now().millisecondsSinceEpoch % 100; // Random baseado no tempo
    final ativou = numeroSorteado < chanceReal;
    print('🎲 [DropsService] Sorteio Super Drop: $numeroSorteado/100 (precisa < $chanceReal) → ${ativou ? '⭐ ATIVADO!' : 'não ativado'}');
    
    return ativou;
  }
  
  /// Lê um item aleatório diretamente do Excel/Google Sheets
  Future<DropItem?> _lerItemDoExcel() async {
    try {
      print('📊 [DropsService] Lendo item aleatório do Excel...');
      
      // Usa o novo método que retorna um item estruturado
      final item = await _excelReader.lerItemAleatorioDoExcel();
      
      if (item != null) {
        print('✅ [DropsService] Item obtido do Excel: ${item.nome} (${item.tipo})');
      } else {
        print('⚠️ [DropsService] Nenhum item obtido do Excel');
      }
      
      return item;
      
    } catch (e) {
      print('❌ [DropsService] Erro ao ler item do Excel: $e');
      return null;
    }
  }
  
  /// Fallback para recompensas padrão em caso de erro
  Future<void> _adicionarRecompensasPadrao(String email) async {
    try {
      final dropsAtual = await carregarDrops(email) ?? _criarDropsVazio(email);
      
      final itensPadrao = [
        DropItem(
          nome: 'Moedas de Prata',
          descricao: 'Moedas valiosas de aventura',
          tipo: 'moeda',
          quantidade: 100,
          dataObtencao: DateTime.now(),
          raridade: 'comum',
        ),
        DropItem(
          nome: 'Poção de Vida Menor',
          descricao: 'Restaura 50 pontos de vida',
          tipo: 'consumivel',
          quantidade: 1,
          dataObtencao: DateTime.now(),
          raridade: 'comum',
        ),
      ];
      
      final dropsAtualizados = dropsAtual.copyWith(
        itens: [...dropsAtual.itens, ...itensPadrao],
        ultimaAtualizacao: DateTime.now(),
      );
      
      await salvarDrops(dropsAtualizados);
      print('🎁 [DropsService] Recompensas padrão adicionadas para $email');
      
    } catch (e) {
      print('❌ [DropsService] Erro ao adicionar recompensas padrão: $e');
      throw Exception('Falha ao adicionar recompensas: $e');
    }
  }

  /// Cria um registro de drops vazio para novo jogador
  DropJogador _criarDropsVazio(String email) {
    return DropJogador(
      email: email,
      itens: [],
      magias: [],
      ultimaAtualizacao: DateTime.now(),
    );
  }
}