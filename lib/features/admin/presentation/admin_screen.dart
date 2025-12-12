import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/developer_config.dart';
import '../../../core/providers/user_provider.dart';
import '../../aventura/services/mochila_service.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  Future<void> _adicionarItensTeste(BuildContext context, WidgetRef ref) async {
    // Verifica se modo desenvolvedor está ativo
    if (!DeveloperConfig.ENABLE_TYPE_EDITING) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Modo dev desativado (ENABLE_TYPE_EDITING = false)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final email = ref.read(validUserEmailProvider);
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não identificado'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Carrega mochila atual
      if (!context.mounted) return;
      var mochila = await MochilaService.carregarMochila(context, email);
      if (mochila == null) return;

      // Adiciona 100 ovos, 100 moedas chave e 1 chave auto (máx 1)
      mochila = mochila.adicionarOvoEvento(100);
      mochila = mochila.adicionarMoedaChave(100);
      mochila = mochila.adicionarChaveAuto(1);

      // Salva a mochila
      if (!context.mounted) return;
      await MochilaService.salvarMochila(context, email, mochila);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Adicionados: 100 Ovos + 100 Moedas Chave + 1 Chave Auto!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Administrador'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background/templo.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.1,
              children: [
                _MenuBlock(
                  icon: Icons.category,
                  label: 'Tipagem',
                  color: Colors.blueGrey.shade700,
                  onTap: () => context.push('/admin/tipagem'),
                ),
                _MenuBlock(
                  icon: Icons.bug_report,
                  label: 'Monstros',
                  color: Colors.blueGrey.shade400,
                  onTap: () => context.push('/admin/monstros'),
                ),
                _MenuBlock(
                  icon: Icons.rule,
                  label: 'Regras',
                  color: Colors.blueGrey.shade600,
                  onTap: () => context.push('/admin/regras'),
                ),
                _MenuBlock(
                  icon: Icons.explore,
                  label: 'Aventura',
                  color: Colors.blueGrey.shade500,
                  onTap: () => context.push('/admin/aventura'),
                ),
                _MenuBlock(
                  icon: Icons.card_giftcard,
                  label: 'Drops',
                  color: Colors.blueGrey.shade600,
                  onTap: () => context.push('/admin/drops'),
                ),
                _MenuBlock(
                  icon: Icons.science,
                  label: 'Testes',
                  color: DeveloperConfig.ENABLE_TYPE_EDITING
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  onTap: () => _adicionarItensTeste(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MenuBlock({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
