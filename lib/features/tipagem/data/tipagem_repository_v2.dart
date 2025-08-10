import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/services/google_drive_service.dart';

class TipagemRepository {
  final GoogleDriveService _driveService = GoogleDriveService();
  
  // ✅ NOVO CICLO DE VIDA - DEPENDENTE DO DRIVE
  static final Map<Tipo, Map<Tipo, double>> _dadosLocais = {};
  static bool _foiBaixadoDoDrive = false;
  static bool _isInicializado = false;

  // ========================================
  // ✅ VERIFICAÇÃO DE ESTADO PRINCIPAL
  // ========================================
  
  /// Verifica se o app já foi inicializado com dados do Drive
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
    if (isBloqueado) {
      print('🚫 App bloqueado! Chame inicializarComDrive() primeiro');
      return null;
    }
    
    try {
      // 1. Verifica se tem nos dados locais em memória
      if (_dadosLocais.containsKey(tipo)) {
        return Map.from(_dadosLocais[tipo]!);
      }
      
      // 2. Tenta carregar dos dados salvos localmente
      final dadosLocais = await _carregarDadosLocalmente(tipo);
      if (dadosLocais != null) {
        _dadosLocais[tipo] = dadosLocais;
        return Map.from(dadosLocais);
      }
      
      // 3. Se não tem nada, gera valores padrão
      final valoresPadrao = _gerarValoresPadrao();
      _dadosLocais[tipo] = valoresPadrao;
      return Map.from(valoresPadrao);
      
    } catch (e) {
      print('❌ Erro ao carregar dados do tipo ${tipo.name}: $e');
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
      
      final jsonData = await _driveService.baixarJson('tb_${tipo.name}_defesa.json');
      if (jsonData != null) {
        return _converterJsonParaTipos(jsonData);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao baixar do Google Drive: $e');
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
    
    await _driveService.salvarJson(tipo.name, jsonData);
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
}
