import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/tipo_enum.dart';



class TipagemScreen extends StatelessWidget {
  const TipagemScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Tipagem'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Builder(
        builder: (context) {
          // Filtra tipos únicos por descrição
          final tiposUnicos = <String, Tipo>{};
          for (final tipo in Tipo.values) {
            tiposUnicos.putIfAbsent(tipo.descricao, () => tipo);
          }
          final listaTipos = tiposUnicos.values.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: listaTipos.length,
            itemBuilder: (context, index) {
              final tipo = listaTipos[index];
              final assetName = getTipoAsset(tipo);
              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                      color: Colors.grey.shade200,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        assetName,
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/tipagens/icon_tipo_desconhecido.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    tipo.descricao,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String getTipoAsset(Tipo tipo) {
  switch (tipo) {
    case Tipo.normal: return 'assets/tipagens/icon_tipo_normal.png';
    case Tipo.planta: return 'assets/tipagens/icon_tipo_planta.png';
    case Tipo.inseto: return 'assets/tipagens/icon_tipo_inseto.png';
    case Tipo.venenoso: return 'assets/tipagens/icon_tipo_venenoso.png';
    case Tipo.fera: return 'assets/tipagens/icon_tipo_fera.png';
    case Tipo.zumbi: return 'assets/tipagens/icon_tipo_zumbi.png';
    case Tipo.marinho: return 'assets/tipagens/icon_tipo_marinho.png';
    case Tipo.voador: return 'assets/tipagens/icon_tipo_voador.png';
    case Tipo.subterraneo: return 'assets/tipagens/icon_tipo_subterraneo.png';
    case Tipo.terrestre: return 'assets/tipagens/icon_tipo_terrestre.png';
    case Tipo.fogo: return 'assets/tipagens/icon_tipo_fogo.png';
    case Tipo.gelo: return 'assets/tipagens/icon_tipo_gelo.png';
    case Tipo.agua: return 'assets/tipagens/icon_tipo_agua.png';
    case Tipo.vento: return 'assets/tipagens/icon_tipo_vento.png';
    case Tipo.eletrico: return 'assets/tipagens/icon_tipo_eletrico.png';
    case Tipo.pedra: return 'assets/tipagens/icon_tipo_pedra.png';
    case Tipo.luz: return 'assets/tipagens/icon_tipo_luz.png';
    case Tipo.trevas: return 'assets/tipagens/icon_tipo_trevas.png';
    case Tipo.nostalgico: return 'assets/tipagens/icon_tipo_nostalgico.png';
    case Tipo.mistico: return 'assets/tipagens/icon_tipo_mistico.png';
    case Tipo.dragao: return 'assets/tipagens/icon_tipo_dragao.png';
    case Tipo.alien: return 'assets/tipagens/icon_tipo_alien.png';
    case Tipo.docrates: return 'assets/tipagens/icon_tipo_docrates.png';
    case Tipo.fantasma: return 'assets/tipagens/icon_tipo_desconhecido.png';
    case Tipo.psiquico: return 'assets/tipagens/icon_tipo_desconhecido.png';
    case Tipo.magico: return 'assets/tipagens/icon_tipo_magico.png';
    case Tipo.tecnologia: return 'assets/tipagens/icon_tipo_tecnologia.png';
    case Tipo.tempo: return 'assets/tipagens/icon_tipo_tempo.png';
    case Tipo.desconhecido: return 'assets/tipagens/icon_tipo_desconhecido.png';
    case Tipo.deus: return 'assets/tipagens/icon_tipo_deus.png';
  }
}

Color getTipoColor(Tipo tipo) {
  switch (tipo) {
    case Tipo.normal: return Colors.grey;
    case Tipo.planta: return Colors.green;
    case Tipo.inseto: return Colors.lightGreen;
    case Tipo.venenoso: return Colors.purple;
    case Tipo.fera: return Colors.brown;
    case Tipo.zumbi: return Colors.teal;
    case Tipo.marinho: return Colors.blue;
    case Tipo.voador: return Colors.indigo;
    case Tipo.subterraneo: return Colors.brown.shade700;
    case Tipo.terrestre: return Colors.orange;
    case Tipo.fogo: return Colors.red;
    case Tipo.gelo: return Colors.cyan;
    case Tipo.agua: return Colors.blueAccent;
    case Tipo.vento: return Colors.lightBlueAccent;
    case Tipo.eletrico: return Colors.yellow.shade700;
    case Tipo.pedra: return Colors.grey.shade800;
    case Tipo.luz: return Colors.amber;
    case Tipo.trevas: return Colors.deepPurple;
    case Tipo.nostalgico: return Colors.deepOrange;
    case Tipo.mistico: return Colors.pinkAccent;
    case Tipo.dragao: return Colors.deepOrangeAccent;
    case Tipo.alien: return Colors.lightGreenAccent;
    case Tipo.docrates: return Colors.blueGrey;
    case Tipo.fantasma: return Colors.deepPurpleAccent;
    case Tipo.psiquico: return Colors.pink;
    case Tipo.magico: return Colors.indigoAccent;
    case Tipo.tecnologia: return Colors.blueGrey.shade600;
    case Tipo.tempo: return Colors.blueGrey.shade300;
    case Tipo.desconhecido: return Colors.black45;
    case Tipo.deus: return Colors.yellowAccent;
  }
}
