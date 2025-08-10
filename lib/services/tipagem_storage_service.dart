import 'dart:io';
import 'dart:convert';
import '../models/tipo_enum.dart';

class TipagemStorageService {
  static Future<Map<Tipo, double>?> loadDanoRecebido(Tipo tipoSelecionado) async {
    final file = File('tipagem_jsons/${tipoSelecionado.name}.json');
    if (!await file.exists()) return null;
    final jsonStr = await file.readAsString();
    final jsonMap = jsonDecode(jsonStr);
    final danoMap = <Tipo, double>{};
    if (jsonMap['danoRecebido'] is Map) {
      (jsonMap['danoRecebido'] as Map).forEach((key, value) {
        final tipo = Tipo.values.firstWhere(
          (t) => t.name == key,
          orElse: () => Tipo.desconhecido,
        );
        if (tipo != tipoSelecionado) {
          danoMap[tipo] = (value is num) ? value.toDouble() : 1.0;
        }
      });
    }
    return danoMap;
  }
}
