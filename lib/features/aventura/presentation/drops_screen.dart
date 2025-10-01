import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/drop.dart';

class DropsScreen extends StatefulWidget {
  const DropsScreen({super.key});

  @override
  State<DropsScreen> createState() => _DropsScreenState();
}

class _DropsScreenState extends State<DropsScreen> {
  Map<TipoDrop, int> _drops = {};
  Map<TipoDrop, double> _porcentagens = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDrops();
  }

  Future<void> _carregarDrops() async {
    final prefs = await SharedPreferences.getInstance();

    // Carrega drops do jogador
    final dropsJson = prefs.getString('jogador_drops');
    if (dropsJson != null) {
      final Map<String, dynamic> dropsMap = jsonDecode(dropsJson);
      final Map<TipoDrop, int> loaded = {};

      for (final entry in dropsMap.entries) {
        final tipo = TipoDrop.values.firstWhere((t) => t.id == entry.key);
        loaded[tipo] = entry.value as int;
      }

      _drops = loaded;
    }

    // Carrega configurações de porcentagem
    final configJson = prefs.getString('drops_config');
    if (configJson != null) {
      final Map<String, dynamic> configMap = jsonDecode(configJson);
      final Map<TipoDrop, double> loadedConfig = {};

      for (final entry in configMap.entries) {
        final tipo = TipoDrop.values.firstWhere((t) => t.id == entry.key);
        loadedConfig[tipo] = (entry.value as num).toDouble();
      }

      _porcentagens = loadedConfig;
    } else {
      // Valores padrão
      _porcentagens = {
        TipoDrop.pocaoVidaPequena: 30.0,
        TipoDrop.pocaoVidaGrande: 10.0,
        TipoDrop.pedraReforco: 5.0,
      };
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _mostrarDetalheDrop(TipoDrop tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          tipo.nome,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  tipo.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tipo.descricao,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantidade:',
                    style: TextStyle(
                      color: Colors.amber.shade100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_drops[tipo] ?? 0}',
                    style: TextStyle(
                      color: Colors.amber.shade300,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chance de Drop:',
                    style: TextStyle(
                      color: Colors.blue.shade100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(_porcentagens[tipo] ?? 0).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.blue.shade300,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background/templo.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade900.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.amber, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'DROPS CONQUISTADOS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Grid de Drops
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: TipoDrop.values.map((tipo) {
                  final quantidade = _drops[tipo] ?? 0;
                  final porcentagem = _porcentagens[tipo] ?? 0;

                  return GestureDetector(
                    onTap: () => _mostrarDetalheDrop(tipo),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: quantidade > 0 ? Colors.amber : Colors.grey.shade700,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    tipo.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'x$quantidade',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: quantidade > 0 ? Colors.amber : Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Porcentagem no canto superior direito
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              '${porcentagem.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
