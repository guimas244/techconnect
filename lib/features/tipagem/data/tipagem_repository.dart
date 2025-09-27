import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/services/google_drive_service.dart';
import '../../aventura/services/colecao_hive_service.dart';

class TipagemRepository {
  final GoogleDriveService _driveService = GoogleDriveService();
  final ColecaoHiveService _colecaoHiveService = ColecaoHiveService();
  
  // ✅ NOVO CICLO DE VIDA - DEPENDENTE DO DRIVE
  static final Map<Tipo, Map<Tipo, double>> _dadosLocais = {};
  static bool _foiBaixadoDoDrive = false;
  static bool _isInicializado = false;
  
  // ✅ CACHE LOCAL PERSISTENTE
  static const String _cacheFileName = 'tipagens_cache.json';
  static const String _cacheMetaFileName = 'tipagens_meta.json';

  // ========================================
  // ✅ VERIFICAÇÃO DE ESTADO PRINCIPAL
  // ========================================
  
  /// Verifica se o app já foi inicializado (cache local ou Drive)
  Future<bool> get isInicializadoAsync async {
    // 1º: Verifica se já está carregado em memória
    if (_isInicializado) {
      print('✅ Dados já carregados em memória');
      return true;
    }
    
    // 2º: Verifica se existe cache local válido
    if (await _temCacheLocalValido()) {
      print('✅ Cache local encontrado, carregando...');
      await _carregarCacheLocal();
      return true;
    }
    
    print('❌ Sem cache local válido, necessário download do Drive');
    return false;
  }
  
  /// Verifica se o app já foi inicializado com dados do Drive (legacy)
  bool get isInicializado => _isInicializado;
  
  /// Verifica se já baixou dados do Drive alguma vez
  bool get foiBaixadoDoDrive => _foiBaixadoDoDrive;
  
  /// Verifica se todos os dados estão bloqueados (não baixou do Drive ainda)
  bool get isBloqueado => !_foiBaixadoDoDrive;

  // ========================================
  // ✅ INICIALIZAÇÃO OBRIGATÓRIA
  // ========================================

  /// DEVE SER CHAMADO ANTES DE USAR O APP - Baixa dados do Drive
  Future<bool> inicializarComDrive() async {
    try {
      print('🔄 Inicializando app com dados do Google Drive...');
      
      // 1. Conecta com Google Drive
      if (!_driveService.isConectado) {
        final conectou = await _driveService.inicializarConexao();
        if (!conectou) {
          print('❌ Falha ao conectar com Google Drive');
          return false;
        }
      }
      
      // 2. Baixa TODOS os tipos do Drive
      bool sucessoCompleto = true;
      for (final tipo in Tipo.values) {
        try {
          final dadosDrive = await _baixarTipoDoGoogleDrive(tipo);
          if (dadosDrive != null) {
            _dadosLocais[tipo] = dadosDrive;
            await _salvarDadosLocalmente(tipo, dadosDrive);
          } else {
            // Se não existe no Drive, cria com valores padrão
            final valoresPadrao = _gerarValoresPadrao();
            _dadosLocais[tipo] = valoresPadrao;
            await _salvarDadosLocalmente(tipo, valoresPadrao);
            await _salvarTipoNoGoogleDrive(tipo, valoresPadrao);
          }
        } catch (e) {
          print('⚠️ Erro ao baixar tipo ${tipo.name}: $e');
          sucessoCompleto = false;
        }
      }
      
      if (sucessoCompleto) {
        _foiBaixadoDoDrive = true;
        _isInicializado = true;

        // ✅ SALVA CACHE LOCAL APÓS DOWNLOAD BEM-SUCEDIDO
        await _salvarCacheLocal();

        // ✅ INICIALIZA E SINCRONIZA COLEÇÕES
        await _inicializarColecoes();

        print('✅ App inicializado com sucesso! Dados baixados do Drive.');
        return true;
      } else {
        print('⚠️ Inicialização parcial - alguns tipos falharam');
        return false;
      }
      
    } catch (e) {
      print('❌ Erro na inicialização com Drive: $e');
      return false;
    }
  }

  // ========================================
  // ✅ MÉTODOS PRINCIPAIS - SÓ FUNCIONAM APÓS INICIALIZAR
  // ========================================

  /// CARREGA DADOS DE UM TIPO (só funciona após inicializar)
  Future<Map<Tipo, double>?> carregarDadosTipo(Tipo tipo) async {
    print('🔄 [DEBUG] Iniciando carregamento do tipo: ${tipo.displayName} (${tipo.name})');
    
    if (isBloqueado) {
      print('🚫 [DEBUG] App bloqueado para tipo ${tipo.displayName}! Chame inicializarComDrive() primeiro');
      return null;
    }
    
    try {
      // 1. Verifica se tem nos dados locais em memória
      if (_dadosLocais.containsKey(tipo)) {
        print('💾 [DEBUG] Dados encontrados em memória para tipo ${tipo.displayName}');
        return Map.from(_dadosLocais[tipo]!);
      }
      
      // 2. Tenta carregar dos dados salvos localmente
      print('📁 [DEBUG] Tentando carregar dados locais para tipo ${tipo.displayName}');
      final dadosLocais = await _carregarDadosLocalmente(tipo);
      if (dadosLocais != null) {
        print('✅ [DEBUG] Dados locais encontrados para tipo ${tipo.displayName}');
        _dadosLocais[tipo] = dadosLocais;
        return Map.from(dadosLocais);
      }
      
      // 3. Tenta baixar do Google Drive se não tem dados locais
      if (_driveService.isConectado) {
        print('☁️ [DEBUG] Tentando baixar tipo ${tipo.displayName} (${tipo.name}) do Google Drive...');
        final dadosDrive = await _baixarTipoDoGoogleDrive(tipo);
        if (dadosDrive != null) {
          _dadosLocais[tipo] = dadosDrive;
          await _salvarDadosLocalmente(tipo, dadosDrive);
          print('✅ [DEBUG] Tipo ${tipo.displayName} baixado e salvo do Google Drive');
          return Map.from(dadosDrive);
        } else {
          print('❌ [DEBUG] Não foi possível baixar tipo ${tipo.displayName} do Drive');
        }
      } else {
        print('❌ [DEBUG] Drive não conectado para baixar tipo ${tipo.displayName}');
      }
      
      // 4. Se não tem nada, gera valores padrão
      print('⚠️ [DEBUG] Usando valores padrão para tipo ${tipo.displayName}');
      final valoresPadrao = _gerarValoresPadrao();
      _dadosLocais[tipo] = valoresPadrao;
      return Map.from(valoresPadrao);
      
    } catch (e) {
      print('❌ [DEBUG] Erro ao carregar dados do tipo ${tipo.displayName} (${tipo.name}): $e');
      return null;
    }
  }

  /// SALVA DADOS DE UM TIPO (local + Drive)
  Future<bool> salvarDadosTipo(Tipo tipo, Map<Tipo, double> dados) async {
    if (isBloqueado) {
      print('🚫 App bloqueado! Chame inicializarComDrive() primeiro');
      return false;
    }
    
    try {
      // 1. Atualiza dados locais em memória
      _dadosLocais[tipo] = Map.from(dados);
      
      // 2. Salva localmente no dispositivo
      await _salvarDadosLocalmente(tipo, dados);
      
      // 3. Salva no Google Drive
      await _salvarTipoNoGoogleDrive(tipo, dados);
      
      print('✅ Dados do tipo ${tipo.name} salvos com sucesso');
      return true;
      
    } catch (e) {
      print('❌ Erro ao salvar dados do tipo ${tipo.name}: $e');
      return false;
    }
  }

  /// FORÇA ATUALIZAÇÃO DE TODOS OS TIPOS DO DRIVE
  Future<bool> atualizarTodosDoDrive() async {
    try {
      print('🔄 Atualizando todos os tipos do Google Drive...');
      
      bool sucessoCompleto = true;
      for (final tipo in Tipo.values) {
        try {
          final dadosDrive = await _baixarTipoDoGoogleDrive(tipo);
          if (dadosDrive != null) {
            _dadosLocais[tipo] = dadosDrive;
            await _salvarDadosLocalmente(tipo, dadosDrive);
          }
        } catch (e) {
          print('⚠️ Erro ao atualizar tipo ${tipo.name}: $e');
          sucessoCompleto = false;
        }
      }
      
      return sucessoCompleto;
    } catch (e) {
      print('❌ Erro na atualização geral: $e');
      return false;
    }
  }

  // ========================================
  // ✅ MÉTODOS DE COMPATIBILIDADE
  // ========================================

  /// Para compatibilidade com providers existentes
  Future<Map<Tipo, double>?> carregarDadosUsuarioSalvos(Tipo tipo) async {
    return await carregarDadosTipo(tipo);
  }

  /// Para compatibilidade - reseta usando valores padrão
  Future<void> resetarParaPadrao(Tipo tipo) async {
    if (isBloqueado) {
      print('🚫 App bloqueado! Chame inicializarComDrive() primeiro');
      return;
    }
    
    try {
      final valoresPadrao = _gerarValoresPadrao();
      await salvarDadosTipo(tipo, valoresPadrao);
      print('✅ Tipo ${tipo.name} resetado para valores padrão');
    } catch (e) {
      print('❌ Erro ao resetar tipo ${tipo.name}: $e');
    }
  }

  /// Conecta com Google Drive
  Future<bool> conectarDrive() async {
    try {
      return await _driveService.inicializarConexao();
    } catch (e) {
      print('Erro ao conectar Google Drive: $e');
      return false;
    }
  }

  /// Desconecta do Google Drive
  Future<void> desconectarDrive() async {
    try {
      await _driveService.desconectar();
      print('✅ Desconectado do Google Drive');
    } catch (e) {
      print('Erro ao desconectar Google Drive: $e');
    }
  }

  /// Verifica se está conectado ao Drive
  bool get isDriveConectado => _driveService.isConectado;

  /// Lista arquivos do Drive
  Future<List<String>> listarArquivosDrive() async {
    try {
      return await _driveService.listarArquivosDrive();
    } catch (e) {
      print('Erro ao listar arquivos do Drive: $e');
      return [];
    }
  }

  /// Sincroniza todos os tipos para o Drive
  Future<bool> sincronizarTodosParaDrive() async {
    if (isBloqueado) {
      print('🚫 App bloqueado! Chame inicializarComDrive() primeiro');
      return false;
    }
    
    try {
      for (final tipo in Tipo.values) {
        if (_dadosLocais.containsKey(tipo)) {
          await _salvarTipoNoGoogleDrive(tipo, _dadosLocais[tipo]!);
        }
      }
      print('✅ Sincronização completa realizada');
      return true;
    } catch (e) {
      print('❌ Erro na sincronização: $e');
      return false;
    }
  }

  /// Verifica se existe arquivo local
  Future<bool> existeArquivoLocal(Tipo tipo) async {
    try {
      if (kIsWeb) return false;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tipagem_${tipo.name}.json');
      
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Verifica se existe arquivo no Drive
  Future<bool> existeArquivoDrive(Tipo tipo) async {
    try {
      final arquivos = await listarArquivosDrive();
      return arquivos.contains('tb_${tipo.name}_defesa.json');
    } catch (e) {
      return false;
    }
  }

  /// Para compatibilidade com export
  Future<String> obterCaminhoExportacao() async {
    try {
      if (kIsWeb) return "Navegador (Downloads)";
      
      final directory = await getApplicationDocumentsDirectory();
      return "${directory.path}/TechConnect/";
    } catch (e) {
      return "Erro ao obter caminho";
    }
  }

  /// Gera JSON formatado para export
  String gerarJsonFormatado(Tipo tipo, Map<Tipo, double> dados) {
    final List<Map<String, dynamic>> defesas = [];
    for (final entry in dados.entries) {
      defesas.add({
        'tipo': entry.key.name,
        'valor': entry.value,
      });
    }
    
    final jsonData = {
      'tipo': tipo.name,
      'defesa': defesas,
    };
    
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }

  // ========================================
  // 🔒 MÉTODOS PRIVADOS
  // ========================================

  /// Baixa um tipo específico do Google Drive
  Future<Map<Tipo, double>?> _baixarTipoDoGoogleDrive(Tipo tipo) async {
    try {
      if (!_driveService.isConectado) return null;
      
      final nomeArquivo = 'tb_${tipo.name.toLowerCase()}_defesa.json';
      print('🔍 [DEBUG] Tentando baixar arquivo: $nomeArquivo para tipo: ${tipo.displayName} (${tipo.name})');
      
      final jsonData = await _driveService.baixarJson(nomeArquivo);
      
      if (jsonData != null) {
        print('✅ [DEBUG] Arquivo $nomeArquivo baixado com sucesso');
        return _converterJsonParaTipos(jsonData);
      } else {
        print('❌ [DEBUG] Arquivo $nomeArquivo não encontrado no Drive');
        return null;
      }
    } catch (e) {
      print('❌ [DEBUG] Erro ao baixar tipo ${tipo.displayName} (${tipo.name}) do Google Drive: $e');
      return null;
    }
  }

  /// Salva um tipo no Google Drive
  Future<void> _salvarTipoNoGoogleDrive(Tipo tipo, Map<Tipo, double> dados) async {
    final List<Map<String, dynamic>> defesas = [];
    for (final entry in dados.entries) {
      defesas.add({
        'tipo': entry.key.name,
        'valor': entry.value,
      });
    }
    
    final jsonData = {
      'tipo': tipo.name,
      'defesa': defesas,
    };
    
    await _driveService.salvarJson('tb_${tipo.name.toLowerCase()}_defesa', jsonData);
  }

  /// Salva dados localmente no dispositivo
  Future<void> _salvarDadosLocalmente(Tipo tipo, Map<Tipo, double> dados) async {
    if (kIsWeb) return; // Web não suporta arquivos locais
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tipagem_${tipo.name}.json');
      
      // Cria JSON no formato padronizado
      final List<Map<String, dynamic>> defesas = [];
      for (final entry in dados.entries) {
        defesas.add({
          'tipo': entry.key.name,
          'valor': entry.value,
        });
      }
      
      final jsonData = {
        'tipo': tipo.name,
        'defesa': defesas,
      };
      
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));
      print('💾 Dados salvos localmente: ${file.path}');
    } catch (e) {
      print('❌ Erro ao salvar dados localmente: $e');
      rethrow;
    }
  }

  /// Carrega dados localmente do dispositivo
  Future<Map<Tipo, double>?> _carregarDadosLocalmente(Tipo tipo) async {
    try {
      if (kIsWeb) return null;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tipagem_${tipo.name}.json');
      
      if (!await file.exists()) return null;
      
      final contents = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(contents);
      
      return _converterJsonParaTipos(jsonData);
    } catch (e) {
      print('❌ Erro ao carregar dados localmente: $e');
      return null;
    }
  }

  /// Gera valores padrão usando o arquivo MODELO
  Map<Tipo, double> _gerarValoresPadrao() {
    final Map<Tipo, double> padrao = {};
    
    // Usa o enum para garantir que todos os tipos existam
    for (final tipo in Tipo.values) {
      padrao[tipo] = 1.0; // Todos os valores padrão são 1.0
    }
    
    return padrao;
  }

  /// Converte JSON para Map<Tipo, double>
  Map<Tipo, double> _converterJsonParaTipos(Map<String, dynamic> jsonData) {
    final Map<Tipo, double> resultado = {};
    
    // Inicializa todos os tipos com valor padrão
    for (final tipo in Tipo.values) {
      resultado[tipo] = 1.0;
    }
    
    // Se existe a chave "defesa" (formato do arquivo JSON)
    if (jsonData.containsKey('defesa') && jsonData['defesa'] is List) {
      final List<dynamic> defesas = jsonData['defesa'];
      
      for (final defesa in defesas) {
        if (defesa is Map<String, dynamic>) {
          final String? tipoNome = defesa['tipo'];
          final dynamic valorDefesa = defesa['valor'];
          
          if (tipoNome != null && valorDefesa != null) {
            final Tipo? tipo = _obterTipoPorNome(tipoNome);
            if (tipo != null) {
              // Converte para double independente do formato do JSON
              if (valorDefesa is String) {
                final double? valor = double.tryParse(valorDefesa);
                if (valor != null) {
                  resultado[tipo] = valor;
                }
              } else if (valorDefesa is num) {
                resultado[tipo] = valorDefesa.toDouble();
              }
            }
          }
        }
      }
    }
    
    return resultado;
  }

  /// Obtém enum Tipo pelo nome
  Tipo? _obterTipoPorNome(String nome) {
    try {
      return Tipo.values.firstWhere((tipo) => tipo.name == nome);
    } catch (e) {
      print('⚠️ Tipo não encontrado: $nome');
      return null;
    }
  }

  // ========================================
  // ✅ MÉTODOS DE CACHE LOCAL
  // ========================================

  /// Verifica se existe cache local válido
  Future<bool> _temCacheLocalValido() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/$_cacheFileName');
      final metaFile = File('${dir.path}/$_cacheMetaFileName');
      
      if (!cacheFile.existsSync() || !metaFile.existsSync()) {
        return false;
      }
      
      // Verifica se cache não expirou (7 dias)
      final metaContent = await metaFile.readAsString();
      final meta = jsonDecode(metaContent);
      final timestamp = DateTime.parse(meta['timestamp']);
      final agora = DateTime.now();
      final diferenca = agora.difference(timestamp);
      
      if (diferenca.inDays > 7) {
        print('⏰ Cache local expirado (${diferenca.inDays} dias)');
        return false;
      }
      
      print('✅ Cache local válido (${diferenca.inDays} dias atrás)');
      return true;
    } catch (e) {
      print('❌ Erro ao verificar cache local: $e');
      return false;
    }
  }

  /// Carrega dados do cache local
  Future<void> _carregarCacheLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/$_cacheFileName');
      
      final cacheContent = await cacheFile.readAsString();
      final cacheData = jsonDecode(cacheContent);
      
      // Converte dados do cache para memória
      _dadosLocais.clear();
      for (final entry in cacheData.entries) {
        final tipoNome = entry.key;
        final tipo = _obterTipoPorNome(tipoNome);
        
        if (tipo != null && entry.value is Map<String, dynamic>) {
          final dadosTipo = <Tipo, double>{};
          
          for (final tipoEntry in entry.value.entries) {
            final tipoDefesa = _obterTipoPorNome(tipoEntry.key);
            if (tipoDefesa != null && tipoEntry.value is num) {
              dadosTipo[tipoDefesa] = tipoEntry.value.toDouble();
            }
          }
          
          _dadosLocais[tipo] = dadosTipo;
        }
      }
      
      _foiBaixadoDoDrive = true;
      _isInicializado = true;
      
      print('✅ Cache local carregado: ${_dadosLocais.length} tipos');
    } catch (e) {
      print('❌ Erro ao carregar cache local: $e');
      rethrow;
    }
  }

  /// Salva dados atuais no cache local
  Future<void> _salvarCacheLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/$_cacheFileName');
      final metaFile = File('${dir.path}/$_cacheMetaFileName');
      
      // Prepara dados para cache
      final cacheData = <String, Map<String, double>>{};
      for (final entry in _dadosLocais.entries) {
        final tipoNome = entry.key.name;
        final dadosTipo = <String, double>{};
        
        for (final tipoEntry in entry.value.entries) {
          dadosTipo[tipoEntry.key.name] = tipoEntry.value;
        }
        
        cacheData[tipoNome] = dadosTipo;
      }
      
      // Salva cache
      await cacheFile.writeAsString(jsonEncode(cacheData));
      
      // Salva metadados
      final meta = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'tipos_count': cacheData.length,
      };
      await metaFile.writeAsString(jsonEncode(meta));
      
      print('✅ Cache local salvo: ${cacheData.length} tipos');
    } catch (e) {
      print('❌ Erro ao salvar cache local: $e');
    }
  }

  /// Limpa cache local (opcional, para debug)
  Future<void> limparCacheLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/$_cacheFileName');
      final metaFile = File('${dir.path}/$_cacheMetaFileName');

      if (cacheFile.existsSync()) await cacheFile.delete();
      if (metaFile.existsSync()) await metaFile.delete();

      print('✅ Cache local limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache local: $e');
    }
  }

  // ========================================
  // ✅ MÉTODOS DE COLEÇÕES
  // ========================================

  /// Inicializa e sincroniza coleções durante o download inicial
  Future<void> _inicializarColecoes() async {
    try {
      print('🎯 [TipagemRepository] Inicializando sistema de coleções...');

      // Inicializa o HIVE service das coleções
      await _colecaoHiveService.init();

      // Obtém email do usuário atual (se disponível)
      final email = await _obterEmailUsuarioAtual();
      if (email == null) {
        print('⚠️ [TipagemRepository] Email não disponível, pulando sincronização de coleções');
        return;
      }

      print('👤 [TipagemRepository] Sincronizando coleções para: $email');

      // Tenta baixar coleção do Drive
      await _sincronizarColecaoComDrive(email);

      print('✅ [TipagemRepository] Sistema de coleções inicializado');
    } catch (e) {
      print('❌ [TipagemRepository] Erro ao inicializar coleções: $e');
      // Não falha a inicialização principal por causa das coleções
    }
  }

  /// Obtém o email do usuário atual
  Future<String?> _obterEmailUsuarioAtual() async {
    try {
      // Implementação simplificada - pode ser expandida para usar providers
      // Por enquanto, retorna null para não quebrar o fluxo
      return null;
    } catch (e) {
      print('❌ [TipagemRepository] Erro ao obter email do usuário: $e');
      return null;
    }
  }

  /// Sincroniza coleção de um jogador específico com o Drive
  Future<void> _sincronizarColecaoComDrive(String email) async {
    try {
      print('🔄 [TipagemRepository] Sincronizando coleção para: $email');

      // Verifica se já existe coleção local
      final temColecaoLocal = await _colecaoHiveService.temColecao(email);

      if (temColecaoLocal) {
        print('💾 [TipagemRepository] Coleção local encontrada para $email');
        // Verifica se precisa sincronizar com Drive
        final estaSincronizada = await _colecaoHiveService.estaSincronizada(email);
        if (estaSincronizada) {
          print('✅ [TipagemRepository] Coleção já sincronizada, pulando download');
          return;
        }
      }

      // Tenta baixar coleção do Drive
      final nomeArquivo = 'colecao_$email.json';
      final conteudoDrive = await _driveService.baixarArquivoDaPasta(nomeArquivo, 'colecao');

      if (conteudoDrive.isNotEmpty) {
        print('📥 [TipagemRepository] Coleção encontrada no Drive para $email');

        // Parse do JSON do Drive
        final dados = json.decode(conteudoDrive) as Map<String, dynamic>;
        final colecaoDrive = Map<String, bool>.from(dados['monstros'] ?? {});

        // Salva no HIVE
        await _colecaoHiveService.salvarColecao(email, colecaoDrive);
        await _colecaoHiveService.marcarComoSincronizada(email);

        print('✅ [TipagemRepository] Coleção sincronizada do Drive para HIVE');
      } else {
        print('📭 [TipagemRepository] Nenhuma coleção encontrada no Drive para $email');

        // Cria coleção inicial se não existir local
        if (!temColecaoLocal) {
          final colecaoInicial = _colecaoHiveService.criarColecaoInicial();
          await _colecaoHiveService.salvarColecao(email, colecaoInicial);

          // Salva no Drive também
          await _salvarColecaoNoDrive(email, colecaoInicial);
          await _colecaoHiveService.marcarComoSincronizada(email);

          print('🆕 [TipagemRepository] Coleção inicial criada e sincronizada');
        }
      }
    } catch (e) {
      print('❌ [TipagemRepository] Erro ao sincronizar coleção: $e');
    }
  }

  /// Salva coleção no Drive
  Future<bool> _salvarColecaoNoDrive(String email, Map<String, bool> colecao) async {
    try {
      final dados = {
        'email': email,
        'monstros': colecao,
        'ultima_atualizacao': DateTime.now().toIso8601String(),
      };

      final nomeArquivo = 'colecao_$email.json';
      final json = jsonEncode(dados);

      return await _driveService.salvarArquivoEmPasta(nomeArquivo, json, 'colecao');
    } catch (e) {
      print('❌ [TipagemRepository] Erro ao salvar coleção no Drive: $e');
      return false;
    }
  }

  /// Força refresh das coleções (para botão refresh)
  Future<bool> refreshColecoes(String email) async {
    try {
      print('🔄 [TipagemRepository] Forçando refresh das coleções para: $email');

      // Remove marca de sincronização para forçar download
      await _colecaoHiveService.removerColecao(email);

      // Refaz a sincronização
      await _sincronizarColecaoComDrive(email);

      print('✅ [TipagemRepository] Refresh das coleções concluído');
      return true;
    } catch (e) {
      print('❌ [TipagemRepository] Erro no refresh das coleções: $e');
      return false;
    }
  }
}
