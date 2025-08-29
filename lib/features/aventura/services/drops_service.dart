import 'dart:convert';
import '../../../core/services/google_drive_service.dart';
import '../models/drop_jogador.dart';
import 'drops_config_service.dart';

class DropsService {
  final GoogleDriveService _driveService = GoogleDriveService();
  final DropsConfigService _configService = DropsConfigService();

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

  /// Adiciona recompensas baseadas na configuração do Excel
  Future<void> adicionarRecompensasMockadas(String email) async {
    try {
      final dropsAtual = await carregarDrops(email) ?? _criarDropsVazio(email);
      
      // Carrega configuração e sorteia itens (sempre do Drive)
      final itensSorteados = await _configService.sortearDrops(quantidadeItens: 3);
      
      // Converte configuração para DropItem
      final novosItens = itensSorteados.map((config) => DropItem(
        nome: config.nome,
        descricao: config.descricao,
        tipo: config.tipo,
        quantidade: config.quantidade,
        dataObtencao: DateTime.now(),
      )).toList();
      
      final dropsAtualizados = dropsAtual.copyWith(
        itens: [...dropsAtual.itens, ...novosItens],
        ultimaAtualizacao: DateTime.now(),
      );
      
      await salvarDrops(dropsAtualizados);
      print('🎁 [DropsService] ${novosItens.length} recompensas adicionadas para $email baseadas na configuração');
      
    } catch (e) {
      print('❌ [DropsService] Erro ao adicionar recompensas: $e');
      
      // Fallback para itens padrão em caso de erro
      await _adicionarRecompensasPadrao(email);
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
        ),
        DropItem(
          nome: 'Poção de Vida Menor',
          descricao: 'Restaura 50 pontos de vida',
          tipo: 'consumivel',
          quantidade: 1,
          dataObtencao: DateTime.now(),
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
      ultimaAtualizacao: DateTime.now(),
    );
  }
}