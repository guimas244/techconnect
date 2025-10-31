import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mochila.dart';
import '../models/item_consumivel.dart';

class MochilaService {
  static const String _boxName = 'mochila_box';
  static const String _migrationBoxName = 'app_migration';
  static const String _currentVersion = '2.2.1';

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
        final mochilaNova = Mochila().inicializarMoedaEvento().inicializarOvoEvento();
        // Salva a mochila vazia
        await _salvarNoHive(emailLimpo, mochilaNova);
        return mochilaNova;
      }

      Mochila mochila;

      // Se for String, converte de JSON
      if (conteudo is String) {
        final json = jsonDecode(conteudo) as Map<String, dynamic>;
        print('✅ [MochilaService] Mochila carregada do Hive (JSON)');
        mochila = Mochila.fromJson(json).inicializarMoedaEvento().inicializarOvoEvento();
      }
      // Se for Map, usa direto
      else if (conteudo is Map) {
        print('✅ [MochilaService] Mochila carregada do Hive (Map)');
        mochila = Mochila.fromJson(Map<String, dynamic>.from(conteudo)).inicializarMoedaEvento().inicializarOvoEvento();
      } else {
        print('⚠️ [MochilaService] Formato desconhecido, criando nova mochila');
        return Mochila().inicializarMoedaEvento().inicializarOvoEvento();
      }

      // Aplica migração se necessário (2.0.0 -> 2.1.1)
      final mochilaLimpa = await _aplicarMigracaoSeNecessario(emailLimpo, mochila);
      return mochilaLimpa;
    } catch (e, stack) {
      print('❌ [MochilaService] Erro ao carregar mochila: $e');
      print(stack);
      return Mochila().inicializarMoedaEvento().inicializarOvoEvento();
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

  /// Aplica migração 2.0.0 -> 2.1.1 se necessário
  /// Remove poções e pedras de reforço da mochila
  static Future<Mochila> _aplicarMigracaoSeNecessario(String emailLimpo, Mochila mochila) async {
    try {
      final migrationBox = await Hive.openBox(_migrationBoxName);
      final chave = 'migrated_2_1_0_$emailLimpo';

      // Verifica se já foi migrado
      final jaMigrado = migrationBox.get(chave, defaultValue: false) as bool;

      if (jaMigrado) {
        print('✅ [MochilaService] Migração 2.1.1 já foi aplicada anteriormente');
        return mochila;
      }

      print('🔄 [MochilaService] Aplicando migração 2.0.0 -> 2.1.1: Limpando poções e pedras de reforço');

      // Remove todos os itens que são poções ou joias (pedra de reforço)
      final itensLimpos = mochila.itens.map((item) {
        if (item == null) return null;

        // Mantém moeda de evento e ovo de evento (slots fixos)
        if (item.tipo == TipoItemConsumivel.moedaEvento ||
            item.tipo == TipoItemConsumivel.ovoEvento) {
          return item;
        }

        // Remove poções e joias (pedra de reforço)
        if (item.tipo == TipoItemConsumivel.pocao ||
            item.tipo == TipoItemConsumivel.joia) {
          print('🗑️ [MochilaService] Removendo: ${item.nome} (${item.tipo.name})');
          return null;
        }

        // Mantém outros tipos
        return item;
      }).toList();

      final mochilaLimpa = mochila.copyWith(itens: itensLimpos);

      // Salva a mochila limpa
      await _salvarNoHive(emailLimpo, mochilaLimpa);

      // Marca como migrado
      await migrationBox.put(chave, true);

      print('✅ [MochilaService] Migração 2.1.1 concluída com sucesso');
      return mochilaLimpa;

    } catch (e, stack) {
      print('❌ [MochilaService] Erro na migração 2.1.1: $e');
      print(stack);
      // Em caso de erro, retorna a mochila original
      return mochila;
    }
  }
}
