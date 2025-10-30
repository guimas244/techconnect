import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/drop.dart';
import '../../../core/config/developer_config.dart';

class AdminDropsScreen extends StatefulWidget {
  const AdminDropsScreen({super.key});

  @override
  State<AdminDropsScreen> createState() => _AdminDropsScreenState();
}

class _AdminDropsScreenState extends State<AdminDropsScreen> {
  Map<TipoDrop, double> _porcentagens = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('drops_config');

    if (configJson != null) {
      final Map<String, dynamic> configMap = jsonDecode(configJson);
      final Map<TipoDrop, double> loaded = {};

      for (final entry in configMap.entries) {
        final tipo = TipoDrop.values.firstWhere((t) => t.id == entry.key);
        loaded[tipo] = (entry.value as num).toDouble();
      }

      setState(() {
        _porcentagens = loaded;
        _isLoading = false;
      });
    } else {
      // Valores padrão
      setState(() {
        _porcentagens = {
          TipoDrop.pocaoVidaPequena: 5.0,
          TipoDrop.pocaoVidaGrande: 2.0,
          TipoDrop.pedraRecriacao: 2.0,
          TipoDrop.joiaReforco: 1.0,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, double> configMap = {};

    for (final entry in _porcentagens.entries) {
      configMap[entry.key.id] = entry.value;
    }

    await prefs.setString('drops_config', jsonEncode(configMap));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações de drops salvas!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text('Configuração de Drops'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configure a porcentagem de chance (1-100%) de cada drop aparecer após vitória em batalha.',
                      style: TextStyle(
                        color: Colors.amber.shade100,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...TipoDrop.values.map((tipo) => _buildDropConfig(tipo)),
            const SizedBox(height: 32),
            if (DeveloperConfig.ENABLE_TYPE_EDITING)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvarConfiguracoes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'SALVAR CONFIGURAÇÕES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange.shade300),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edição desabilitada. Ative ENABLE_TYPE_EDITING para editar.',
                        style: TextStyle(
                          color: Colors.orange.shade100,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropConfig(TipoDrop tipo) {
    final porcentagem = _porcentagens[tipo] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      tipo.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tipo.descricao,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chance de Drop: ${porcentagem.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: porcentagem,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        activeColor: DeveloperConfig.ENABLE_TYPE_EDITING ? Colors.amber : Colors.grey,
                        inactiveColor: Colors.grey.shade700,
                        label: '${porcentagem.toStringAsFixed(0)}%',
                        onChanged: DeveloperConfig.ENABLE_TYPE_EDITING
                            ? (value) {
                                setState(() {
                                  _porcentagens[tipo] = value;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
