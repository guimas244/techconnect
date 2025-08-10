import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tipo_enum.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TipagemDanoScreen extends StatefulWidget {
  final Tipo tipoSelecionado;
  const TipagemDanoScreen({Key? key, required this.tipoSelecionado}) : super(key: key);

  @override
  State<TipagemDanoScreen> createState() => _TipagemDanoScreenState();
}

class _TipagemDanoScreenState extends State<TipagemDanoScreen> {
  late Map<Tipo, double> danoRecebido;

  @override
  void initState() {
    super.initState();
    print('=== INIT STATE ===');
    print('Tipo selecionado: ${widget.tipoSelecionado.name}');
    
    danoRecebido = {
      for (final tipo in Tipo.values)
        if (tipo != widget.tipoSelecionado) tipo: 1.0,
    };
    
    print('Mapa inicial criado com ${danoRecebido.length} tipos');
    print('Chamando _carregarDados...');
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    print('=== INICIANDO CARREGAMENTO ===');
    print('Tipo selecionado: ${widget.tipoSelecionado.name}');
    
    final fileName = 'tb_${widget.tipoSelecionado.name}_defesa.json';
    
    try {
      // 1. Sempre tentar carregar do asset primeiro (arquivo do projeto)
      String jsonContent = '';
      
      try {
        print('📦 Tentando carregar do asset: tipagem_jsons/$fileName');
        jsonContent = await rootBundle.loadString('tipagem_jsons/$fileName');
        print('✅ Carregado do asset com sucesso!');
        
        // Salvar/atualizar a cópia no armazenamento interno
        final appDir = await getApplicationDocumentsDirectory();
        final localFile = File('${appDir.path}/$fileName');
        await localFile.writeAsString(jsonContent);
        print('� Cópia atualizada no armazenamento interno');
        
      } catch (e) {
        print('❌ Erro ao carregar do asset: $e');
        
        // 2. Se não conseguir do asset, tentar do armazenamento interno
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final localFile = File('${appDir.path}/$fileName');
          
          if (await localFile.exists()) {
            print('📁 Carregando do armazenamento interno como fallback');
            jsonContent = await localFile.readAsString();
            print('✅ Carregado do armazenamento interno');
          } else {
            throw Exception('Arquivo não encontrado em nenhum local');
          }
        } catch (e2) {
          print('❌ Erro ao carregar do armazenamento interno: $e2');
          throw e2;
        }
      }
      
      print('Conteúdo lido: ${jsonContent.substring(0, 100)}...');
      
      final json = jsonDecode(jsonContent);
      print('JSON decodificado com sucesso');
      
      if (json['defesa'] != null) {
        final defesaList = json['defesa'] as List;
        print('Lista de defesa tem ${defesaList.length} itens');
        
        for (final item in defesaList) {
          final tipoName = item['tipo'] as String;
          final valor = (item['valor'] as num).toDouble();
          
          print('🔍 Processando: $tipoName = $valor');
          
          // Encontrar o enum correspondente
          Tipo? tipoEnum;
          for (final t in Tipo.values) {
            if (t.name == tipoName) {
              tipoEnum = t;
              break;
            }
          }
          
          if (tipoEnum != null && tipoEnum != widget.tipoSelecionado) {
            if (danoRecebido.containsKey(tipoEnum)) {
              danoRecebido[tipoEnum] = valor;
              print('✅ Carregado: ${tipoEnum.name} = $valor (${tipoEnum.descricao})');
            } else {
              print('❌ Tipo não encontrado no mapa: ${tipoEnum.name}');
            }
          } else if (tipoEnum == widget.tipoSelecionado) {
            print('⚠️ Ignorando próprio tipo: ${tipoEnum?.name}');
          } else {
            print('❌ Tipo não encontrado no enum: $tipoName');
          }
        }
        
        print('=== ATUALIZANDO UI ===');
        print('Estado final do mapa danoRecebido:');
        for (final entry in danoRecebido.entries) {
          if (entry.value != 1.0) {
            print('  ${entry.key.name} (${entry.key.descricao}) = ${entry.value}');
          }
        }
        
        if (mounted) {
          setState(() {});
          print('✅ UI atualizada');
        }
      } else {
        print('❌ Campo "defesa" não encontrado no JSON');
      }
    } catch (e, stackTrace) {
      print('❌ ERRO: $e');
      print('StackTrace: $stackTrace');
    }
    
    print('=== FIM DO CARREGAMENTO ===');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dano Recebido: ${widget.tipoSelecionado.descricao}'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: danoRecebido.keys.map((tipo) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tipo.descricao,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${danoRecebido[tipo]!.toStringAsFixed(1)}x',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.blueGrey.shade700,
                            inactiveTrackColor: Colors.blueGrey.shade300,
                            thumbColor: Colors.blueGrey.shade900,
                            overlayColor: Colors.blueGrey.shade900.withAlpha(32),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: danoRecebido[tipo]!,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20, // 0.1 increments
                            onChanged: (novo) {
                              setState(() {
                                danoRecebido[tipo] = novo;
                              });
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0.0x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '1.0x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '2.0x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    print('=== INICIANDO SALVAMENTO ===');
                    
                    // Criar array de defesa no formato correto
                    List<Map<String, dynamic>> defesaArray = [];
                    
                    // Adicionar todos os tipos (incluindo o próprio tipo)
                    for (final tipo in Tipo.values) {
                      double valor = 1.0;
                      if (tipo != widget.tipoSelecionado && danoRecebido.containsKey(tipo)) {
                        valor = danoRecebido[tipo]!;
                      }
                      defesaArray.add({
                        'tipo': tipo.name,
                        'valor': valor,
                      });
                    }
                    
                    final jsonMap = {
                      'tipo': widget.tipoSelecionado.name,
                      'defesa': defesaArray,
                    };
                    
                    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);
                    
                    // Salvar no armazenamento interno
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'tb_${widget.tipoSelecionado.name}_defesa.json';
                    final file = File('${appDir.path}/$fileName');
                    
                    await file.writeAsString(jsonStr);
                    
                    print('✅ Arquivo salvo em: ${file.path}');
                    print('📄 Conteúdo: ${jsonStr.substring(0, 200)}...');
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alterações salvas!')),
                      );
                    }
                  } catch (e, stackTrace) {
                    print('❌ Erro ao salvar: $e');
                    print('StackTrace: $stackTrace');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao salvar: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
