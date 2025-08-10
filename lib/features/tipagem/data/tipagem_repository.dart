import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../core/services/google_drive_service.dart';

class TipagemRepository {
  final GoogleDriveService _driveService = GoogleDriveService();

  Future<Map<Tipo, double>> carregarDadosTipo(Tipo tipo) async {
    try {
      // 1. Google Drive está em desenvolvimento, pulando por enquanto
      
      // 2. Primeiro tenta carregar do armazenamento local
      final localData = await _carregarDadosLocal(tipo);
      if (localData != null) return localData;
      
      // 3. Se não encontrar localmente, carrega dos assets
      return await _carregarDadosAssets(tipo);
    } catch (e) {
      // Em caso de erro, retorna valores padrão
      return _obterValoresPadrao();
    }
  }

  Future<Map<Tipo, double>?> _carregarDadosLocal(Tipo tipo) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tb_${tipo.name}_defesa.json');
      
      if (!await file.exists()) return null;
      
      final contents = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(contents);
      
      return _converterJsonParaTipos(jsonData);
    } catch (e) {
      return null;
    }
  }

  Future<Map<Tipo, double>> _carregarDadosAssets(Tipo tipo) async {
    try {
      print('Tentando carregar: tipagem_jsons/tb_${tipo.name}_defesa.json');
      final String data = await rootBundle.loadString('tipagem_jsons/tb_${tipo.name}_defesa.json');
      final Map<String, dynamic> jsonData = json.decode(data);
      final resultado = _converterJsonParaTipos(jsonData);
      
      print('Dados carregados para ${tipo.name}:');
      resultado.forEach((key, value) {
        print('  ${key.name}: $value');
      });
      
      // Tenta salvar localmente, mas não falha se não conseguir (ex: na web)
      try {
        await salvarDadosTipo(tipo, resultado);
      } catch (e) {
        print('Aviso: Não foi possível salvar localmente (normal na web): $e');
      }
      
      return resultado;
    } catch (e) {
      print('Erro ao carregar dados dos assets para ${tipo.name}: $e');
      return _obterValoresPadrao();
    }
  }

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
          final num? valor = defesa['valor'];
          
          if (tipoNome != null && valor != null) {
            // Procura o tipo correspondente
            try {
              final tipo = Tipo.values.firstWhere((t) => t.name == tipoNome);
              resultado[tipo] = valor.toDouble();
            } catch (e) {
              // Se não encontrar o tipo, ignora
              continue;
            }
          }
        }
      }
    } else {
      // Fallback para formato simples (caso existam arquivos neste formato)
      for (final tipo in Tipo.values) {
        final valor = jsonData[tipo.name];
        if (valor != null) {
          resultado[tipo] = (valor as num).toDouble();
        }
      }
    }
    
    return resultado;
  }

  Map<Tipo, double> _obterValoresPadrao() {
    return Map.fromEntries(
      Tipo.values.map((tipo) => MapEntry(tipo, 1.0)),
    );
  }

  Future<void> salvarDadosTipo(Tipo tipo, Map<Tipo, double> dados) async {
    final jsonData = {
      "tipo": tipo.name,
      "defesa": dados.entries.map((entry) => {
        "tipo": entry.key.name,
        "valor": entry.value,
      }).toList(),
    };

    try {
      // 1. Salva localmente sempre (backup)
      await _salvarDadosLocal(tipo, dados);

      // 2. Salva no Google Drive se conectado
      if (_driveService.isConectado) {
        print('☁️ Salvando no Google Drive...');
        final sucesso = await _driveService.salvarJson(tipo.name, jsonData);
        if (sucesso) {
          print('✅ Salvo no Drive com sucesso!');
        } else {
          print('⚠️ Falha ao salvar no Drive, mantido backup local');
        }
      } else {
        print('⚠️ Drive não conectado, salvando apenas localmente');
      }
      
    } catch (e) {
      throw Exception('Erro ao salvar dados: $e');
    }
  }

  Future<void> _salvarNoProjetoLocal(Tipo tipo, Map<Tipo, double> dados) async {
    // Caminho para a pasta tipagem_jsons do projeto
    final projectPath = Directory.current.path;
    final tipagemPath = '$projectPath/tipagem_jsons';
    final nomeArquivo = 'tb_${tipo.name}_defesa.json';
    final file = File('$tipagemPath/$nomeArquivo');
    
    print('🔍 Tentando salvar no projeto: ${file.path}');
    
    // Cria o formato correto do JSON
    final Map<String, dynamic> jsonStructure = {
      'tipo': tipo.name,
      'defesa': [],
    };
    
    final List<Map<String, dynamic>> defesaList = [];
    for (final tipoEntry in Tipo.values) {
      defesaList.add({
        'tipo': tipoEntry.name,
        'valor': dados[tipoEntry] ?? 1.0,
      });
    }
    
    jsonStructure['defesa'] = defesaList;
    
    // Salva com formatação bonita
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonStructure));
    
    print('✅ Arquivo salvo no projeto: tipagem_jsons/$nomeArquivo');
  }

  Future<void> _salvarNoArmazenamentoDispositivo(Tipo tipo, Map<Tipo, double> dados) async {
    try {
      if (kIsWeb) return; // Não funciona na web
      
      // Salva no armazenamento interno
      await _salvarDadosLocal(tipo, dados);
      
      // Exporta para Downloads para facilitar acesso
      await _exportarParaDownloads(tipo, dados);
      
    } catch (e) {
      print('❌ Erro ao salvar no dispositivo: $e');
      throw Exception('Erro ao salvar dados: $e');
    }
  }

  Future<void> _salvarDadosLocal(Tipo tipo, Map<Tipo, double> dados) async {
    if (kIsWeb) return; // Não funciona na web
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tb_${tipo.name}_defesa.json');
    
    final Map<String, double> jsonData = {};
    for (final entry in dados.entries) {
      jsonData[entry.key.name] = entry.value;
    }
    
    await file.writeAsString(json.encode(jsonData));
    print('✅ Dados salvos localmente: ${file.path}');
  }

  Future<void> _exportarParaDownloads(Tipo tipo, Map<Tipo, double> dados) async {
    try {
      if (kIsWeb) return; // Não funciona na web
      
      // Tenta usar Downloads primeiro, depois fallback para Documents
      Directory? directory;
      try {
        directory = await getDownloadsDirectory();
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        // Cria pasta TechConnect se não existir
        final techConnectDir = Directory('${directory.path}/TechConnect');
        if (!await techConnectDir.exists()) {
          await techConnectDir.create(recursive: true);
        }
        
        final filename = 'tb_${tipo.name}_defesa.json';
        final file = File('${techConnectDir.path}/$filename');
        
        // Cria o formato correto do JSON
        final Map<String, dynamic> jsonStructure = {
          'tipo': tipo.name,
          'defesa': [],
        };
        
        final List<Map<String, dynamic>> defesaList = [];
        for (final tipoEntry in Tipo.values) {
          defesaList.add({
            'tipo': tipoEntry.name,
            'valor': dados[tipoEntry] ?? 1.0,
          });
        }
        
        jsonStructure['defesa'] = defesaList;
        
        // Salva com formatação bonita
        const encoder = JsonEncoder.withIndent('  ');
        await file.writeAsString(encoder.convert(jsonStructure));
        
        print('📁 JSON exportado para: ${file.path}');
      }
    } catch (e) {
      print('⚠️ Erro ao exportar para Downloads: $e');
      // Não falha se não conseguir exportar
    }
  }

  Future<List<Tipo>> obterTodosTipos() async {
    return Tipo.values;
  }

  Future<bool> existeArquivoLocal(Tipo tipo) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tb_${tipo.name}_defesa.json');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> resetarParaPadrao(Tipo tipo) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tb_${tipo.name}_defesa.json');
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Erro ao resetar dados: $e');
    }
  }

  String gerarJsonFormatado(Tipo tipo, Map<Tipo, double> dados) {
    final Map<String, dynamic> jsonStructure = {
      'tipo': tipo.name,
      'defesa': [],
    };
    
    // Adiciona todos os tipos na ordem correta
    final List<Map<String, dynamic>> defesaList = [];
    for (final tipoEntry in Tipo.values) {
      defesaList.add({
        'tipo': tipoEntry.name,
        'valor': dados[tipoEntry] ?? 1.0,
      });
    }
    
    jsonStructure['defesa'] = defesaList;
    
    // Retorna com formatação bonita
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonStructure);
  }

  Future<String> obterCaminhoExportacao() async {
    try {
      // Primeiro tenta o caminho do projeto
      final projectPath = Directory.current.path;
      final tipagemPath = '$projectPath/tipagem_jsons/';
      final testFile = File('${tipagemPath}test.tmp');
      
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
        return '💾 Projeto: tipagem_jsons/\n📁 Backup: Downloads/TechConnect/';
      } catch (e) {
        // Se não conseguir escrever no projeto, usa o caminho de fallback
        if (kIsWeb) return 'Download via navegador';
        
        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          return '📁 Downloads/TechConnect/\n⚠️ (Copie para tipagem_jsons/)';
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
          return '📁 ${directory.path}/TechConnect/\n⚠️ (Copie para tipagem_jsons/)';
        }
      }
    } catch (e) {
      return 'Erro ao obter caminho';
    }
  }

  Future<void> exportarTodosOsJsons() async {
    try {
      int sucessos = 0;
      int falhas = 0;
      
      for (final tipo in Tipo.values) {
        try {
          final dados = await carregarDadosTipo(tipo);
          await _salvarNoProjetoLocal(tipo, dados);
          sucessos++;
        } catch (e) {
          print('❌ Erro ao exportar ${tipo.name}: $e');
          try {
            final dados = await carregarDadosTipo(tipo);
            await _salvarNoArmazenamentoDispositivo(tipo, dados);
            falhas++;
          } catch (e2) {
            print('❌ Falha total para ${tipo.name}: $e2');
            falhas++;
          }
        }
      }
      
      if (sucessos > 0) {
        print('✅ $sucessos JSONs salvos no projeto');
      }
      if (falhas > 0) {
        print('⚠️ $falhas JSONs salvos apenas no dispositivo');
      }
      
    } catch (e) {
      throw Exception('Erro ao exportar todos os JSONs: $e');
    }
  }

  // Métodos do Google Drive
  Future<bool> conectarDrive() async {
    return await _driveService.inicializarConexao();
  }

  Future<bool> sincronizarTodosParaDrive() async {
    // Criar um mapa com todos os dados de todos os tipos
    Map<String, Map<String, dynamic>> todosJsons = {};

    for (Tipo tipo in Tipo.values) {
      try {
        // Carregar dados do tipo atual
        final dados = await carregarDadosTipo(tipo);
        
        // Converter para formato JSON
        Map<String, dynamic> jsonData = {};
        dados.forEach((tipoDefensor, multiplicador) {
          jsonData[tipoDefensor.name] = multiplicador;
        });
        
        todosJsons[tipo.name] = jsonData;
      } catch (e) {
        print('⚠️ Erro ao processar tipo ${tipo.name}: $e');
      }
    }

    // Sincronizar todos para o Drive
    return await _driveService.sincronizarTodosJsons(todosJsons);
  }

  Future<void> desconectarDrive() async {
    await _driveService.desconectar();
  }

  bool get isDriveConectado => _driveService.isConectado;

  Future<List<String>> listarArquivosDrive() async {
    return await _driveService.listarArquivosDrive();
  }
}
