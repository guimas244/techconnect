import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/tipo_enum.dart';
import '../providers/tipagem_provider.dart';
import '../../../core/services/google_drive_service.dart';

class TipagemDanoScreen extends ConsumerWidget {
  final Tipo tipoSelecionado;
  
  const TipagemDanoScreen({
    super.key, 
    required this.tipoSelecionado,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editState = ref.watch(tipagemEditProvider(tipoSelecionado));
    final editNotifier = ref.read(tipagemEditProvider(tipoSelecionado).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: Text('Editar Tipo ${tipoSelecionado.displayName}'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (editState.isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else ...[
            // Botão salvar
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: 'Salvar alterações',
              onPressed: () async {
                // Salvar alterações locais
                await editNotifier.salvarAlteracoes();
                
                // Salvar no Google Drive também
                if (!editState.isSaving && editState.errorMessage == null) {
                  await _salvarNoGoogleDrive(context, editNotifier);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alterações salvas localmente e no Google Drive!')),
                  );
                }
              },
            ),
          ]
        ],
      ),
      body: editState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, editState, editNotifier),
    );
  }

  Widget _buildBody(BuildContext context, TipagemEditState state, TipagemEditNotifier notifier) {
    return Column(
      children: [
        // Cabeçalho com informações do tipo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    tipoSelecionado.iconAsset,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipoSelecionado.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Configurar dano recebido',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mensagem de erro
        if (state.errorMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => notifier.limparMensagens(),
                ),
              ],
            ),
          ),

        // Mensagem de sucesso
        if (state.successMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.successMessage!,
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => notifier.limparMensagens(),
                ),
              ],
            ),
          ),

        // Lista de tipos para edição
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.danoRecebido.length,
            itemBuilder: (context, index) {
              final tipos = state.danoRecebido.keys.toList();
              final tipo = tipos[index];
              final valor = state.danoRecebido[tipo]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            tipo.iconAsset,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tipo.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Multiplicador: ${valor.toStringAsFixed(1)}x',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _getColorForValue(valor),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getColorForValue(valor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getEffectText(valor),
                              style: TextStyle(
                                color: _getColorForValue(valor),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: tipo.cor,
                          inactiveTrackColor: tipo.cor.withOpacity(0.3),
                          thumbColor: tipo.cor,
                          overlayColor: tipo.cor.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value: valor,
                          min: 0.0,
                          max: 2.0,
                          divisions: 20,
                          onChanged: (novoValor) {
                            notifier.atualizarDano(tipo, novoValor);
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
            },
          ),
        ),
      ],
    );
  }

  Color _getColorForValue(double value) {
    if (value < 0.5) return Colors.green;
    if (value < 1.0) return Colors.orange;
    if (value == 1.0) return Colors.grey;
    if (value < 1.5) return Colors.red;
    return Colors.red.shade800;
  }

  String _getEffectText(double value) {
    if (value == 0.0) return 'Imune';
    if (value < 0.5) return 'Muito Resistente';
    if (value < 1.0) return 'Resistente';
    if (value == 1.0) return 'Normal';
    if (value < 1.5) return 'Fraco';
    return 'Muito Fraco';
  }

  // Método para salvar no Google Drive
  Future<void> _salvarNoGoogleDrive(BuildContext context, TipagemEditNotifier editNotifier) async {
    try {
      final driveService = GoogleDriveService();
      
      // Gerar JSON do tipo atual usando o método existente
      final jsonString = editNotifier.gerarJsonParaDownload();
      final jsonData = <String, dynamic>{
        'tipo': tipoSelecionado.name,
        'data': jsonString,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final nomeArquivo = 'tb_${tipoSelecionado.name.toLowerCase()}_defesa';
      
      // Salvar no Google Drive
      final sucesso = await driveService.salvarJson(nomeArquivo, jsonData);
      
      if (!sucesso) {
        throw Exception('Falha ao salvar no Google Drive');
      }
      
      print('✅ JSON salvo no Google Drive: $nomeArquivo');
    } catch (e) {
      print('❌ Erro ao salvar no Google Drive: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no Google Drive: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
