import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/models/kills_permanentes.dart';
import '../../aventura/providers/kills_permanentes_provider.dart';

/// Tela FORTUNA do Modo Explorador
///
/// Mostra as kills permanentes (moeda do modo explorador)
/// Replica visual da tela de progresso do modo aventura
/// Sem configuracao de distribuicao de atributos
class FortunaScreen extends ConsumerStatefulWidget {
  const FortunaScreen({super.key});

  @override
  ConsumerState<FortunaScreen> createState() => _FortunaScreenState();
}

class _FortunaScreenState extends ConsumerState<FortunaScreen> {
  bool _mostrarHistorico = false;
  Tipo? _tipoSelecionado;

  @override
  Widget build(BuildContext context) {
    final kills = ref.watch(killsPermanentesProvider);
    final totalKills = ref.watch(totalKillsPermanentesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          'FORTUNA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/explorador'),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _mostrarHistorico = !_mostrarHistorico;
              });
            },
            icon: Icon(
              _mostrarHistorico ? Icons.close : Icons.history,
              color: Colors.white,
            ),
            tooltip: 'Ver historico',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a2e2e), // Teal escuro
              Color(0xFF0f0f1e), // Preto
            ],
          ),
        ),
        child: Column(
          children: [
            // Header com total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.teal.shade700.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.teal.shade400,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.stars,
                          size: 32,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalKills',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade300,
                            ),
                          ),
                          Text(
                            'Kills Permanentes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.teal.shade700,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.teal.shade300,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kills nao expiram - use na loja!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.teal.shade200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Conteudo
            Expanded(
              child: kills == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    )
                  : _mostrarHistorico
                      ? _buildHistoricoView(kills)
                      : _buildKillsView(kills),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKillsView(KillsPermanentes kills) {
    final tipos = Tipo.values;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info do tipo selecionado
          if (_tipoSelecionado != null) ...[
            _buildTipoDetalhe(_tipoSelecionado!, kills.getKills(_tipoSelecionado!)),
            const SizedBox(height: 16),
          ],

          // Grid de tipos
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: tipos.map((tipo) {
              final quantidade = kills.getKills(tipo);
              return _buildTipoCard(tipo, quantidade);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoCard(Tipo tipo, int kills) {
    final isSelected = _tipoSelecionado == tipo;

    // Para tipos muito escuros (como Trevas), usa uma cor de borda mais clara
    final isCorEscura = tipo.cor.computeLuminance() < 0.1;
    final corBorda = isCorEscura
        ? (isSelected ? Colors.purple.shade400 : Colors.purple.shade700)
        : (isSelected ? tipo.cor : tipo.cor.withOpacity(0.5));

    final corFundo = isSelected
        ? (isCorEscura
            ? Colors.purple.shade900.withOpacity(0.3)
            : tipo.cor.withOpacity(0.2))
        : Colors.black.withOpacity(0.3);

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoSelecionado = isSelected ? null : tipo;
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: corBorda,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isCorEscura ? Colors.purple.shade400 : tipo.cor)
                        .withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Icone do tipo
            Center(
              child: Image.asset(
                'assets/tipagens/icon_tipo_${tipo.name}.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    tipo.icone,
                    size: 40,
                    color: tipo.cor,
                  );
                },
              ),
            ),

            // Badge de kills
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade800],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 11,
                      color: Colors.white,
                    ),
                    if (kills > 0) ...[
                      const SizedBox(width: 2),
                      Text(
                        '$kills',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0.5, 0.5),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoDetalhe(Tipo tipo, int kills) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tipo.cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tipo.cor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: tipo.cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                'assets/tipagens/icon_tipo_${tipo.name}.png',
                width: 45,
                height: 45,
                errorBuilder: (_, __, ___) => Icon(
                  tipo.icone,
                  size: 35,
                  color: tipo.cor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monstro: ${tipo.monsterName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tipo.cor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$kills',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoView(KillsPermanentes kills) {
    final killsOrdenadas = kills.killsOrdenadas;
    final totalKills = ref.watch(totalKillsPermanentesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info sobre kills permanentes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade600, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'SOBRE KILLS PERMANENTES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Diferente das kills do modo Aventura que expiram em 3 dias, '
                  'estas kills sao permanentes e podem ser usadas para comprar '
                  'equipamentos e itens nas lojas do Modo Explorador.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Resumo total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade700, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.teal, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Total Acumulado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalKills kills',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de kills por tipo
          if (killsOrdenadas.isEmpty) ...[
            const SizedBox(height: 40),
            const Icon(Icons.inbox, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma kill registrada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ganhe kills no modo Aventura e transfira\npara o Modo Explorador',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ] else ...[
            ...killsOrdenadas.map((entry) {
              final tipo = entry.key;
              final quantidade = entry.value;
              return _buildHistoricoCard(tipo, quantidade);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoricoCard(Tipo tipo, int quantidade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tipo.cor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tipo.cor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                'assets/tipagens/icon_tipo_${tipo.name}.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => Icon(
                  tipo.icone,
                  size: 22,
                  color: tipo.cor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  tipo.monsterName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tipo.cor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$quantidade',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
