import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/services/google_drive_service.dart';

class TipagemRepository {
  final GoogleDriveService _driveService = GoogleDriveService();
  
  // ✅ CACHE CENTRALIZADO - único ponto de verdade
  static final Map<Tipo, Map<Tipo, double>> _cache = {};
  static final Map<Tipo, Map<Tipo, double>> _originalAssets = {};

  // ========================================
  // ✅ MÉTODOS PÚBLICOS - INTERFACE ÚNICA
  // ========================================

  /// ÚNICO PONTO DE LEITURA - sempre retorna dados originais dos assets
  Future<Map<Tipo, double>> carregarDadosTipo(Tipo tipo) async {
    try {
      // 1. Se está no cache de assets, retorna
      if (_originalAssets.containsKey(tipo)) {
        return Map.from(_originalAssets[tipo]!);
      }
      
      // 2. Carrega dos assets e salva no cache
      final assetData = await _carregarDosAssets(tipo);
      _originalAssets[tipo] = Map.from(assetData);
      
      return Map.from(assetData);
    } catch (e) {
      print('❌ Erro ao carregar dados do tipo ${tipo.name}: $e');
      return _obterValoresPadrao();
    }
  }

  /// ÚNICO PONTO DE ESCRITA - salva dados do usuário
  Future<void> salvarDadosTipo(Tipo tipo, Map<Tipo, double> dados) async {
    try {
      // 1. Atualiza cache imediatamente
      _cache[tipo] = Map.from(dados);
      
      // 2. Salva localmente no dispositivo
      await _salvarDadosLocalmente(tipo, dados);
      
      // 3. Tenta salvar no Google Drive (não bloqueia se falhar)
      try {
        await _salvarNoGoogleDrive(tipo, dados);
        print('✅ Dados salvos: Local + Google Drive');
      } catch (e) {
        print('⚠️ Dados salvos localmente, mas erro no Google Drive: $e');
      }
      
    } catch (e) {
      throw Exception('Erro ao salvar dados: $e');
    }
  }

  /// CARREGA DADOS SALVOS PELO USUÁRIO (quando clicar em "Carregar")
  Future<Map<Tipo, double>?> carregarDadosUsuarioSalvos(Tipo tipo) async {
    try {
      // 1. Verifica se há dados no cache primeiro
      if (_cache.containsKey(tipo)) {
        print('✅ Dados carregados do cache');
        return Map.from(_cache[tipo]!);
      }
      
      // 2. Tenta Google Drive se conectado
      if (_driveService.isConectado) {
        try {
          final driveData = await _carregarDoGoogleDrive(tipo);
          if (driveData != null) {
            _cache[tipo] = Map.from(driveData);
            print('✅ Dados carregados do Google Drive');
            return Map.from(driveData);
          }
        } catch (e) {
          print('⚠️ Erro ao carregar do Google Drive: $e');
        }
      }
      
      // 3. Tenta dados locais do usuário
      final dadosLocais = await _carregarDadosLocalmente(tipo);
      if (dadosLocais != null) {
        _cache[tipo] = Map.from(dadosLocais);
        print('✅ Dados carregados do armazenamento local');
        return Map.from(dadosLocais);
      }
      
      print('ℹ️ Nenhum dado salvo encontrado');
      return null;
    } catch (e) {
      print('❌ Erro ao carregar dados salvos: $e');
      return null;
    }
  }

  /// RESETA PARA VALORES ORIGINAIS
  Future<void> resetarParaPadrao(Tipo tipo) async {
    try {
      // Remove do cache
      _cache.remove(tipo);
      
      // Remove arquivos locais do usuário
      await _removerDadosLocais(tipo);
      
      print('✅ Dados resetados para valores padrão para ${tipo.name}');
    } catch (e) {
      print('❌ Erro ao resetar dados: $e');
      throw Exception('Erro ao resetar dados: $e');
    }
  }

  /// VERIFICA SE EXISTE ARQUIVO LOCAL
  Future<bool> existeArquivoLocal(Tipo tipo) async {
    try {
      if (kIsWeb) return false;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_${tipo.name}_defesa.json');
      
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// VERIFICA SE EXISTE ARQUIVO NO DRIVE
  Future<bool> existeArquivoDrive(Tipo tipo) async {
    try {
      final arquivos = await listarArquivosDrive();
      return arquivos.contains('tb_${tipo.name}_defesa.json');
    } catch (e) {
      return false;
    }
  }

  /// LISTA ARQUIVOS DO DRIVE
  Future<List<String>> listarArquivosDrive() async {
    try {
      return await _driveService.listarArquivosDrive();
    } catch (e) {
      print('Erro ao listar arquivos do Drive: $e');
      return [];
    }
  }

  // ========================================
  // 🔧 MÉTODOS INTERNOS DE COMPATIBILIDADE
  // ========================================

  /// Para compatibilidade com o provider existente
  Future<String> obterCaminhoExportacao() async {
    try {
      if (kIsWeb) return "Navegador (Downloads)";
      
      final directory = await getApplicationDocumentsDirectory();
      return "${directory.path}/TechConnect/";
    } catch (e) {
      return "Erro ao obter caminho";
    }
  }

  /// Para compatibilidade com o provider existente
  String gerarJsonFormatado(Tipo tipo, Map<Tipo, double> dados) {
    final List<Map<String, dynamic>> defesas = [];
    for (final entry in dados.entries) {
      defesas.add({
        'tipo': entry.key.name,
        'valor': entry.value,
      });
    }
    
    final jsonData = {
      'defesa': defesas,
    };
    
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }

  // ========================================
  // 🔒 MÉTODOS PRIVADOS INTERNOS
  // ========================================

  /// Carrega dados dos assets (arquivos originais)
  Future<Map<Tipo, double>> _carregarDosAssets(Tipo tipo) async {
    try {
      print('📁 Carregando dados originais: tipagem_jsons/tb_${tipo.name}_defesa.json');
      final String data = await rootBundle.loadString('tipagem_jsons/tb_${tipo.name}_defesa.json');
      final Map<String, dynamic> jsonData = json.decode(data);
      final resultado = _converterJsonParaTipos(jsonData);
      
      print('✅ Dados originais carregados para ${tipo.name}');
      return resultado;
    } catch (e) {
      print('❌ Erro ao carregar dados dos assets para ${tipo.name}: $e');
      return _obterValoresPadrao();
    }
  }

  /// Salva dados localmente no dispositivo
  Future<void> _salvarDadosLocalmente(Tipo tipo, Map<Tipo, double> dados) async {
    if (kIsWeb) return; // Não funciona na web
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_${tipo.name}_defesa.json');
      
      final Map<String, double> jsonData = {};
      for (final entry in dados.entries) {
        jsonData[entry.key.name] = entry.value;
      }
      
      await file.writeAsString(json.encode(jsonData));
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
      final file = File('${directory.path}/user_${tipo.name}_defesa.json');
      
      if (!await file.exists()) return null;
      
      final contents = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(contents);
      
      return _converterJsonParaTipos(jsonData);
    } catch (e) {
      print('❌ Erro ao carregar dados localmente: $e');
      return null;
    }
  }

  /// Salva dados no Google Drive
  Future<void> _salvarNoGoogleDrive(Tipo tipo, Map<Tipo, double> dados) async {
    final List<Map<String, dynamic>> defesas = [];
    for (final entry in dados.entries) {
      defesas.add({
        'tipo': entry.key.name,
        'valor': entry.value,
      });
    }
    
    final jsonData = {
      'defesa': defesas,
    };
    
    await _driveService.salvarJson(tipo.name, jsonData);
  }

  /// Carrega dados do Google Drive
  Future<Map<Tipo, double>?> _carregarDoGoogleDrive(Tipo tipo) async {
    try {
      if (!_driveService.isConectado) return null;
      
      final jsonData = await _driveService.baixarJson('tb_${tipo.name}_defesa.json');
      if (jsonData != null) {
        return _converterJsonParaTipos(jsonData);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao carregar do Google Drive: $e');
      return null;
    }
  }

  /// Remove dados locais do usuário
  Future<void> _removerDadosLocais(Tipo tipo) async {
    try {
      if (kIsWeb) return;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_${tipo.name}_defesa.json');
      
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Arquivo local removido: ${file.path}');
      }
    } catch (e) {
      print('❌ Erro ao remover dados locais: $e');
    }
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
          // Aceita tanto 'valor' quanto 'multiplicador' para compatibilidade
          final dynamic valorDefesa = defesa['valor'] ?? defesa['multiplicador'];
          
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

  /// Valores padrão (todos 1.0)
  Map<Tipo, double> _obterValoresPadrao() {
    final Map<Tipo, double> padrao = {};
    for (final tipo in Tipo.values) {
      padrao[tipo] = 1.0;
    }
    return padrao;
  }
}
