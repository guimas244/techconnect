import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drive_provider.dart';

class DriveConfigScreen extends ConsumerWidget {
  const DriveConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driveState = ref.watch(driveProvider);
    final driveNotifier = ref.read(driveProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud,
                          color: driveState.isConectado 
                            ? Colors.green 
                            : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Drive',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              driveState.isConectado 
                                ? 'Conectado' 
                                : 'Desconectado',
                              style: TextStyle(
                                color: driveState.isConectado 
                                  ? Colors.green 
                                  : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (driveState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
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
                                driveState.errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            if (driveState.isConectado) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: driveState.isLoading 
                    ? null 
                    : () => driveNotifier.sincronizarTodos(),
                  icon: driveState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                  label: Text(
                    driveState.isLoading 
                      ? 'Sincronizando...' 
                      : 'Sincronizar Todos os JSONs',
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: driveState.isLoading 
                    ? null 
                    : () => driveNotifier.desconectar(),
                  icon: const Icon(Icons.cloud_off),
                  label: const Text('Desconectar'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: driveState.isLoading 
                    ? null 
                    : () => driveNotifier.conectarDrive(),
                  icon: driveState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud),
                  label: Text(
                    driveState.isLoading 
                      ? 'Conectando...' 
                      : 'Conectar ao Google Drive',
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Informações sobre o Google Drive
            const Text(
              'Sobre o Google Drive',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Centralização de Dados',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ao conectar com o Google Drive, todos os seus JSONs de configuração de tipagem serão salvos na nuvem, permitindo sincronização entre dispositivos.',
                    ),
                    
                    SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Icon(Icons.folder_outlined, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Pasta: TechConnect_Tipagens',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Uma pasta será criada automaticamente no seu Google Drive para organizar todos os arquivos do aplicativo.',
                    ),
                  ],
                ),
              ),
            ),
            
            // Modo de desenvolvimento
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.code, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modo de Desenvolvimento: O Google Drive está simulado para testes. As funcionalidades estão funcionando localmente.',
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
}
