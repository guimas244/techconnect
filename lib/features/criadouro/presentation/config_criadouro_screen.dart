import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/criadouro_provider.dart';
import '../models/config_criadouro.dart';

class ConfigCriadouroScreen extends ConsumerStatefulWidget {
  const ConfigCriadouroScreen({super.key});

  @override
  ConsumerState<ConfigCriadouroScreen> createState() =>
      _ConfigCriadouroScreenState();
}

class _ConfigCriadouroScreenState extends ConsumerState<ConfigCriadouroScreen> {
  late ConfigCriadouro _config;

  @override
  void initState() {
    super.initState();
    _config = ref.read(criadouroProvider).config;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚙️ ', style: TextStyle(fontSize: 24)),
            Text('Configurações'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle geral
            Card(
              child: SwitchListTile(
                title: const Row(
                  children: [
                    Text('🔔 ', style: TextStyle(fontSize: 20)),
                    Text('Notificações'),
                  ],
                ),
                subtitle: const Text('Ativar/desativar todas as notificações'),
                value: _config.notificacoesAtivas,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(notificacoesAtivas: value);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Configurações por barra
            if (_config.notificacoesAtivas) ...[
              const Text(
                'Notificar quando:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Arraste o slider para definir o limite de cada barra',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              _buildSliderCard(
                emoji: '🍖',
                label: 'Fome',
                valor: _config.limiteFome,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(limiteFome: value.toInt());
                  });
                },
              ),
              _buildSliderCard(
                emoji: '💧',
                label: 'Sede',
                valor: _config.limiteSede,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(limiteSede: value.toInt());
                  });
                },
              ),
              _buildSliderCard(
                emoji: '🧼',
                label: 'Higiene',
                valor: _config.limiteHigiene,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(limiteHigiene: value.toInt());
                  });
                },
              ),
              _buildSliderCard(
                emoji: '😄',
                label: 'Alegria',
                valor: _config.limiteAlegria,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(limiteAlegria: value.toInt());
                  });
                },
              ),
              _buildSliderCard(
                emoji: '❤️',
                label: 'Saúde',
                valor: _config.limiteSaude,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(limiteSaude: value.toInt());
                  });
                },
              ),
              const SizedBox(height: 8),

              // Notificar doença
              Card(
                child: SwitchListTile(
                  title: const Row(
                    children: [
                      Text('🤒 ', style: TextStyle(fontSize: 20)),
                      Text('Notificar Doença'),
                    ],
                  ),
                  subtitle: const Text('Avisar quando o mascote ficar doente'),
                  value: _config.notificarDoenca,
                  onChanged: (value) {
                    setState(() {
                      _config = _config.copyWith(notificarDoenca: value);
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarConfiguracoes,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Configurações'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String emoji,
    required String label,
    required int valor,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCorPorValor(valor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '< $valor%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: valor.toDouble(),
              min: 10,
              max: 80,
              divisions: 14,
              label: '$valor%',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCorPorValor(int valor) {
    if (valor <= 20) return Colors.red;
    if (valor <= 40) return Colors.orange;
    if (valor <= 60) return Colors.yellow[700]!;
    return Colors.green;
  }

  void _salvarConfiguracoes() {
    ref.read(criadouroProvider.notifier).atualizarConfig(_config);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas! ✅'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }
}
