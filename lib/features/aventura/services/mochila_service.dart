import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/mochila.dart';
import '../../../core/services/google_drive_service.dart';

class MochilaService {
  static final GoogleDriveService _driveService = GoogleDriveService();

  // Verifica se o Drive está disponível
  static Future<bool> verificarDriveDisponivel(BuildContext context) async {
    try {
      final conectado = await _driveService.inicializarConexao();
      if (!conectado) {
        _mostrarErroModal(
          context,
          'Google Drive não autenticado',
          'Faça login no Google Drive para usar a mochila.',
        );
        return false;
      }
      return true;
    } catch (e) {
      _mostrarErroModal(
        context,
        'Erro ao conectar com Drive',
        'Não foi possível conectar ao Google Drive. Verifique sua conexão.',
      );
      return false;
    }
  }

  // Carrega a mochila do Drive
  static Future<Mochila?> carregarMochila(BuildContext context, String email) async {
    try {
      // Verifica disponibilidade do Drive
      if (!await verificarDriveDisponivel(context)) {
        return null;
      }

      final emailLimpo = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final nomeArquivo = 'mochila_$emailLimpo';

      // Busca o arquivo no Drive (pasta mochila dentro de TECHTERRA)
      final conteudo = await _driveService.baixarArquivoDaPasta(
        nomeArquivo,
        'mochila',
      );

      if (conteudo.isEmpty) {
        print('⚠️ Mochila não encontrada, criando nova');
        return Mochila();
      }

      final json = jsonDecode(conteudo) as Map<String, dynamic>;
      return Mochila.fromJson(json);
    } catch (e) {
      print('⚠️ Erro ao carregar mochila (criando nova): $e');
      // Se não encontrou, retorna mochila vazia
      return Mochila();
    }
  }

  // Salva a mochila no Drive
  static Future<bool> salvarMochila(
    BuildContext context,
    String email,
    Mochila mochila,
  ) async {
    try {
      // Verifica disponibilidade do Drive
      if (!await verificarDriveDisponivel(context)) {
        return false;
      }

      final emailLimpo = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final nomeArquivo = 'mochila_$emailLimpo';

      // Converte para JSON
      final conteudo = jsonEncode(mochila.toJson());

      // Salva no Drive (pasta mochila dentro de TECHTERRA)
      final sucesso = await _driveService.salvarArquivoEmPasta(
        nomeArquivo,
        conteudo,
        'mochila',
      );

      if (sucesso) {
        print('✅ Mochila salva com sucesso no Drive');
      } else {
        print('❌ Falha ao salvar mochila no Drive');
      }

      return sucesso;
    } catch (e) {
      print('❌ Erro ao salvar mochila no Drive: $e');
      if (context.mounted) {
        _mostrarErroModal(
          context,
          'Erro ao salvar',
          'Não foi possível salvar a mochila no Drive.',
        );
      }
      return false;
    }
  }

  static void _mostrarErroModal(
    BuildContext context,
    String titulo,
    String mensagem,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: Text(mensagem),
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