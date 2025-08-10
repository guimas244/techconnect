import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../core/google_drive_client.dart';
import 'drive_service.dart';

class DriveDebugScreen extends StatefulWidget {
  const DriveDebugScreen({super.key});
  @override
  State<DriveDebugScreen> createState() => _DriveDebugScreenState();
}

class _DriveDebugScreenState extends State<DriveDebugScreen> {
  List<drive.File> files = [];
  bool loading = false;
  String log = "";

  Future<void> _withService(Future<void> Function(DriveService) fn) async {
    setState(() { loading = true; log = ""; });
    try {
      print('🔍 [DEBUG] DriveDebugScreen: Chamando DriveClientFactory.create()...');
      final api = await DriveClientFactory.create();
      print('✅ [DEBUG] DriveDebugScreen: API criada, criando DriveService...');
      final service = DriveService(api);
      print('✅ [DEBUG] DriveDebugScreen: DriveService criado, executando função...');
      await fn(service);
      print('✅ [DEBUG] DriveDebugScreen: Função executada com sucesso');
    } catch (e) {
      print('❌ [DEBUG] DriveDebugScreen: Erro detalhado:');
      print('❌ [DEBUG] Tipo: ${e.runtimeType}');
      print('❌ [DEBUG] Mensagem: $e');
      setState(() { log = "Erro detalhado:\nTipo: ${e.runtimeType}\nMensagem: $e"; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TECH CONNECT Drive Test"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : () async {
                      await _withService((svc) async {
                        final res = await svc.listInRootFolder();
                        setState(() { files = res; log = "Listou ${res.length} arquivos"; });
                      });
                    },
                    child: const Text("Listar arquivos"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : () async {
                      await _withService((svc) async {
                        final created = await svc.createTextFile(
                          "hello-tech-connect.txt",
                          "Olá TECH CONNECT - ${DateTime.now()}",
                        );
                        setState(() { log = "Criado: ${created.name} (${created.id})"; });
                        // Atualizar lista após criar
                        final res = await svc.listInRootFolder();
                        setState(() { files = res; });
                      });
                    },
                    child: const Text("Criar texto"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : () async {
                      await _withService((svc) async {
                        final jsonData = {
                          "app": "TECH CONNECT",
                          "timestamp": DateTime.now().toIso8601String(),
                          "test_data": {
                            "normal": 1.0,
                            "fogo": 2.0,
                            "agua": 0.5
                          }
                        };
                        final created = await svc.createJsonFile(
                          "test-tipagem.json",
                          jsonData,
                        );
                        setState(() { log = "JSON criado: ${created.name} (${created.id})"; });
                        // Atualizar lista após criar
                        final res = await svc.listInRootFolder();
                        setState(() { files = res; });
                      });
                    },
                    child: const Text("Criar JSON"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : () async {
                      await _withService((svc) async {
                        final created = await svc.createSubfolder("Tipagens");
                        setState(() { log = "Pasta criada: ${created.name} (${created.id})"; });
                        // Atualizar lista após criar
                        final res = await svc.listInRootFolder();
                        setState(() { files = res; });
                      });
                    },
                    child: const Text("Criar pasta"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading) const LinearProgressIndicator(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                log.isEmpty ? "Clique nos botões para testar..." : log,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: log.startsWith('Erro:') ? Colors.red : Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Arquivos na pasta TECH CONNECT:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Expanded(
              child: files.isEmpty
                  ? const Center(
                      child: Text(
                        "Nenhum arquivo encontrado.\nClique em 'Listar arquivos' para carregar.",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (_, i) {
                        final f = files[i];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              f.mimeType == 'application/vnd.google-apps.folder'
                                  ? Icons.folder
                                  : f.mimeType == 'application/json'
                                      ? Icons.code
                                      : Icons.description,
                              color: f.mimeType == 'application/vnd.google-apps.folder'
                                  ? Colors.amber
                                  : f.mimeType == 'application/json'
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            title: Text(f.name ?? ""),
                            subtitle: Text("${f.mimeType}  •  ${f.modifiedTime}"),
                            trailing: f.size != null 
                                ? Text("${f.size} bytes", style: const TextStyle(fontSize: 12))
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
