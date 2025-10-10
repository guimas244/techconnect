import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mochila.dart';

class MochilaService {
  static const String _boxName = 'mochila_box';

  /// Carrega a mochila do Hive
  static Future<Mochila?> carregarMochila(BuildContext context, String email) async {
    try {
      print('📦 [MochilaService] Carregando mochila do Hive para: $email');

      final box = await Hive.openBox(_boxName);
      final emailLimpo = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final chave = 'mochila_$emailLimpo';

      final conteudo = box.get(chave);

      if (conteudo == null) {
        print('📭 [MochilaService] Mochila não encontrada, criando nova');
        final mochilaNova = Mochila();
        // Salva a mochila vazia
        await _salvarNoHive(emailLimpo, mochilaNova);
        return mochilaNova;
      }

      // Se for String, converte de JSON
      if (conteudo is String) {
        final json = jsonDecode(conteudo) as Map<String, dynamic>;
        print('✅ [MochilaService] Mochila carregada do Hive (JSON)');
        return Mochila.fromJson(json);
      }

      // Se for Map, usa direto
      if (conteudo is Map) {
        print('✅ [MochilaService] Mochila carregada do Hive (Map)');
        return Mochila.fromJson(Map<String, dynamic>.from(conteudo));
      }

      print('⚠️ [MochilaService] Formato desconhecido, criando nova mochila');
      return Mochila();
    } catch (e, stack) {
      print('❌ [MochilaService] Erro ao carregar mochila: $e');
      print(stack);
      return Mochila();
    }
  }

  /// Salva a mochila no Hive
  static Future<bool> salvarMochila(
    BuildContext context,
    String email,
    Mochila mochila,
  ) async {
    try {
      print('💾 [MochilaService] Salvando mochila no Hive para: $email');

      final emailLimpo = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      await _salvarNoHive(emailLimpo, mochila);

      print('✅ [MochilaService] Mochila salva com sucesso no Hive');
      return true;
    } catch (e, stack) {
      print('❌ [MochilaService] Erro ao salvar mochila: $e');
      print(stack);

      if (context.mounted) {
        _mostrarErroModal(
          context,
          'Erro ao salvar',
          'Não foi possível salvar a mochila.',
        );
      }
      return false;
    }
  }

  /// Salva diretamente no Hive (método auxiliar privado)
  static Future<void> _salvarNoHive(String emailLimpo, Mochila mochila) async {
    final box = await Hive.openBox(_boxName);
    final chave = 'mochila_$emailLimpo';

    // Salva como JSON string para garantir consistência
    final json = jsonEncode(mochila.toJson());
    await box.put(chave, json);

    print('💾 [MochilaService] Dados salvos no Hive com chave: $chave');
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
