import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/atributo_jogo_enum.dart';
import '../../aventura/presentation/card_monstro_aventura.dart';
import '../../aventura/presentation/modal_monstro_aventura.dart';
import '../../aventura/models/monstro_aventura.dart';
import '../../../shared/models/tipo_enum.dart';

class RegrasScreen extends StatelessWidget {
  const RegrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Regras do Jogo'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atributos dos Monstros',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Todo monstro sorteado possui 5 atributos principais, cada um com seu intervalo de valores:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildAtributoRegra('Vida', AtributoJogo.vida),
            _buildAtributoRegra('Energia', AtributoJogo.energia),
            _buildAtributoRegra('Agilidade', AtributoJogo.agilidade),
            _buildAtributoRegra('Ataque', AtributoJogo.ataque),
            _buildAtributoRegra('Defesa', AtributoJogo.defesa),
            const SizedBox(height: 24),
            const Text(
              'Exemplo de Monstro Sorteado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ModalMonstroAventura(
              monstro: MonstroAventura(
                tipo: Tipo.vento,
                tipoExtra: Tipo.voador,
                imagem: 'assets/monstros_aventura/vento.png',
                vida: 87,
                energia: 32,
                agilidade: 15,
                ataque: 18,
                defesa: 52,
                habilidades: const [],
                item: '',
              ),
              onClose: null,
              showCloseButton: false,
            ),
            const SizedBox(height: 24),
            Text(
              'Os valores dos atributos são sorteados dentro dos intervalos definidos para garantir equilíbrio entre os monstros.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtributoRegra(String nome, AtributoJogo atributo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$nome:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            atributo.rangeTexto,
            style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}
