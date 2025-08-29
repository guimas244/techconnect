import '../../../core/services/google_drive_service.dart';
import '../models/drop_jogador.dart';

class DropsService {
  final GoogleDriveService _driveService = GoogleDriveService();

  /// Nome do arquivo de drops para um jogador específico
  String _getDropsFileName(String email) {
    return 'drops_$email.json';
  }

  /// Verifica se o jogador tem arquivo de drops
  Future<bool> jogadorTemDrops(String email) async {
    try {
      final fileName = _getDropsFileName(email);
      final arquivos = await _driveService.listarArquivosDrive();
      final fileExists = arquivos.contains(fileName);
      print('🎁 [DropsService] Jogador $email tem drops: $fileExists');
      return fileExists;
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

      final jsonData = await _driveService.baixarJson(fileName);
      if (jsonData == null) {
        print('📁 [DropsService] Erro ao baixar arquivo de drops para $email, criando novo...');
        return _criarDropsVazio(email);
      }
      
      final drops = DropJogador.fromJson(jsonData);
      print('✅ [DropsService] Drops carregados para $email: ${drops.itens.length} itens');
      
      return drops;
    } catch (e) {
      print('❌ [DropsService] Erro ao carregar drops de $email: $e');
      return _criarDropsVazio(email);
    }
  }

  /// Salva os drops de um jogador
  Future<void> salvarDrops(DropJogador drops) async {
    try {
      final fileName = _getDropsFileName(drops.email);
      final fileNameWithoutJson = fileName.replaceAll('.json', '');
      
      final sucesso = await _driveService.salvarJson(fileNameWithoutJson, drops.toJson());
      if (!sucesso) {
        throw Exception('Falha ao salvar no Drive');
      }
      
      print('✅ [DropsService] Drops salvos para ${drops.email}');
      
    } catch (e) {
      print('❌ [DropsService] Erro ao salvar drops de ${drops.email}: $e');
      throw Exception('Falha ao salvar drops: $e');
    }
  }

  /// Adiciona itens mockados de recompensa
  Future<void> adicionarRecompensasMockadas(String email) async {
    try {
      final dropsAtual = await carregarDrops(email) ?? _criarDropsVazio(email);
      
      // Cria itens mockados
      final novoItens = [
        DropItem(
          nome: 'Poção de Vida Suprema',
          descricao: 'Restaura toda a vida do monstro instantaneamente',
          tipo: 'consumivel',
          quantidade: 3,
          dataObtencao: DateTime.now(),
        ),
        DropItem(
          nome: 'Cristal de Poder',
          descricao: 'Aumenta permanentemente +2 em todos os atributos',
          tipo: 'upgrade',
          quantidade: 1,
          dataObtencao: DateTime.now(),
        ),
        DropItem(
          nome: 'Moedas de Ouro',
          descricao: 'Moedas preciosas obtidas na aventura',
          tipo: 'moeda',
          quantidade: 250,
          dataObtencao: DateTime.now(),
        ),
      ];
      
      final dropsAtualizados = dropsAtual.copyWith(
        itens: [...dropsAtual.itens, ...novoItens],
        ultimaAtualizacao: DateTime.now(),
      );
      
      await salvarDrops(dropsAtualizados);
      print('🎁 [DropsService] Recompensas mockadas adicionadas para $email');
      
    } catch (e) {
      print('❌ [DropsService] Erro ao adicionar recompensas mockadas: $e');
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