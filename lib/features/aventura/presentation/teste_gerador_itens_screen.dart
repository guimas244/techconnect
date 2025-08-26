import 'package:flutter/material.dart';
import '../utils/gerador_nomes_itens.dart';

/// Tela de demonstração do gerador de itens
class TesteGeradorItensScreen extends StatefulWidget {
  const TesteGeradorItensScreen({super.key});

  @override
  State<TesteGeradorItensScreen> createState() => _TesteGeradorItensScreenState();
}

class _TesteGeradorItensScreenState extends State<TesteGeradorItensScreen> {
  List<Map<String, dynamic>> itensGerados = [];

  void _gerarItens() {
    setState(() {
      itensGerados.clear();
      // Gera 20 itens aleatórios para demonstração
      for (int i = 0; i < 20; i++) {
        itensGerados.add(GeradorNomesItens.gerarItemCompleto());
      }
    });
  }

  Color _getCorRaridade(String cor) {
    switch (cor.toLowerCase()) {
      case 'cinza':
        return Colors.grey;
      case 'branco':
        return Colors.black87;
      case 'verde':
        return Colors.green;
      case 'roxo':
        return Colors.purple;
      case 'dourado':
        return Colors.amber;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Gerador de Itens'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _gerarItens,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Gerar Itens Aleatórios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (itensGerados.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: itensGerados.length,
                itemBuilder: (context, index) {
                  final item = itensGerados[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['nome'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getCorRaridade(item['cor']),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCorRaridade(item['cor']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _getCorRaridade(item['cor']),
                                  ),
                                ),
                                child: Text(
                                  item['raridade'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getCorRaridade(item['cor']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tipo: ${item['tipo']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atributos: ${item['atributos'].join(', ')}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['descricao'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (itensGerados.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Clique no botão acima para gerar itens',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
