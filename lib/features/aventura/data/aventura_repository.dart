import 'dart:convert';
import 'dart:math';
import '../../../core/services/google_drive_service.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/historia_jogador.dart';
import '../models/monstro_aventura.dart';
import '../../tipagem/data/tipagem_repository.dart';

class AventuraRepository {
  final GoogleDriveService _driveService = GoogleDriveService();
  final TipagemRepository _tipagemRepository = TipagemRepository();

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
      final nomeArquivo = 'historico_${historia.email}.json';
      final json = jsonEncode(historia.toJson());
      print('💾 [Repository] JSON gerado: ${json.length} caracteres');
      
      final sucesso = await _driveService.salvarArquivoEmPasta(nomeArquivo, json, 'historias');
      print('💾 [Repository] Salvamento ${sucesso ? "bem-sucedido" : "falhou"}');
      return sucesso;
    } catch (e) {
      print('❌ [Repository] Erro ao salvar histórico: $e');
      return false;
    }
  }

  /// Sorteia 3 monstros únicos para o jogador
  Future<HistoriaJogador> sortearMonstrosParaJogador(String email) async {
    final random = Random();
    final tiposDisponiveis = List<Tipo>.from(Tipo.values);
    tiposDisponiveis.shuffle(random);

    final monstrosSorteados = <MonstroAventura>[];

    // Sorteia 3 tipos únicos
    for (int i = 0; i < 3 && i < tiposDisponiveis.length; i++) {
      final tipo = tiposDisponiveis[i];
      // Sorteia tipo extra diferente do principal
      final outrosTipos = Tipo.values.where((t) => t != tipo).toList();
      outrosTipos.shuffle(random);
      final tipoExtra = outrosTipos.first;
      final monstro = MonstroAventura(
        tipo: tipo,
        tipoExtra: tipoExtra,
        imagem: 'assets/monstros_aventura/${tipo.name}.png',
        vida: 50,
        energia: 50,
        habilidades: ['TODO', 'TODO', 'TODO', 'TODO'],
        item: 'TODO',
      );
      monstrosSorteados.add(monstro);
    }
    
    final historia = HistoriaJogador(
      email: email,
      monstros: monstrosSorteados,
    );
    
    // Salva automaticamente no Drive
    await salvarHistoricoJogador(historia);
    
    return historia;
  }

  /// Verifica se todos os tipos de monstros foram baixados e estão disponíveis localmente
  Future<bool> verificarTiposBaixados() async {
    try {
      // Verifica se os dados de tipagem estão disponíveis localmente
      final isInicializado = await _tipagemRepository.isInicializadoAsync;
      print('🔍 [Aventura] Verificação de tipos baixados: $isInicializado');
      return isInicializado;
    } catch (e) {
      print('❌ [Aventura] Erro ao verificar tipos baixados: $e');
      return false;
    }
  }
}
