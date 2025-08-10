import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/tipo_enum.dart';

class TipagemRepository {
  Future<Map<Tipo, double>> carregarDadosTipo(Tipo tipo) async {
    try {
      // Primeiro tenta carregar do armazenamento local
      final localData = await _carregarDadosLocal(tipo);
      if (localData != null) return localData;
      
      // Se não encontrar localmente, carrega dos assets e salva localmente
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
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tb_${tipo.name}_defesa.json');
      
      final Map<String, double> jsonData = {};
      for (final entry in dados.entries) {
        jsonData[entry.key.name] = entry.value;
      }
      
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      throw Exception('Erro ao salvar dados: $e');
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
}
