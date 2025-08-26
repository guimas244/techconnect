import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/monstro_aventura.dart';
import '../services/item_service.dart';
import '../utils/gerador_nomes_itens.dart';
import '../../../shared/models/tipo_enum.dart';

class TesteItemScreen extends StatelessWidget {
  const TesteItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Sistema de Itens'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _testarGeradorItens(context),
              child: const Text('Gerar Item Aleatório'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _testarGeradorNomes(context),
              child: const Text('Gerar 10 Nomes de Itens'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _mostrarEstatisticas(context),
              child: const Text('Estatísticas de Raridade'),
            ),
          ],
        ),
      ),
    );
  }

  void _testarGeradorItens(BuildContext context) {
    final itemService = ItemService();
    final item = itemService.gerarItemAleatorio();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Item Gerado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${item.nome}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Raridade: ${item.raridade.nome}'),
            Text('Atributos:'),
            ...item.atributos.entries.map((e) => 
              Text('  ${e.key}: +${e.value}')
            ),
            Text('Total: ${item.totalAtributos} pontos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _testarGeradorNomes(BuildContext context) {
    List<String> nomes = [];
    for (int i = 0; i < 10; i++) {
      nomes.add(GeradorNomesItens.gerarNomeItem());
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('10 Nomes Gerados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: nomes.map((nome) => Text('• $nome')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarEstatisticas(BuildContext context) {
    final itemService = ItemService();
    Map<RaridadeItem, int> contadores = {};
    
    // Gera 1000 itens para ver a distribuição
    for (int i = 0; i < 1000; i++) {
      final item = itemService.gerarItemAleatorio();
      contadores[item.raridade] = (contadores[item.raridade] ?? 0) + 1;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estatísticas (1000 itens)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: RaridadeItem.values.map((raridade) {
            final count = contadores[raridade] ?? 0;
            final percentage = (count / 10.0).toStringAsFixed(1);
            return Text('${raridade.nome}: $count ($percentage%)');
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
