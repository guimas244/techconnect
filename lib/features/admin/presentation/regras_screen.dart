import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/atributo_jogo_enum.dart';
import '../../aventura/presentation/modal_monstro_aventura.dart';
import '../../aventura/models/monstro_aventura.dart';
import '../../aventura/models/habilidade.dart';
import '../../../shared/models/habilidade_enum.dart';
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
            ExpansionTile(
              title: const Text(
                'Atributos dos Monstros',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: true,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Todo monstro sorteado possui 5 atributos principais, cada um com seu intervalo de valores:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildAtributoRegra('Vida', AtributoJogo.vida),
                _buildAtributoRegra('Energia', AtributoJogo.energia),
                _buildAtributoRegra('Agilidade', AtributoJogo.agilidade),
                _buildAtributoRegra('Ataque', AtributoJogo.ataque),
                _buildAtributoRegra('Defesa', AtributoJogo.defesa),
                const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text(
                'Habilidades dos Monstros',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Cada monstro possui exatamente 4 habilidades únicas, geradas com base em seu tipo:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildHabilidadeDistribuicao(),
                const SizedBox(height: 16),
                _buildTiposHabilidade(),
                const SizedBox(height: 16),
                _buildExemplosHabilidades(),
                const SizedBox(height: 16),
                Text(
                  'As habilidades são geradas automaticamente seguindo essas regras de distribuição para garantir que cada monstro tenha um conjunto equilibrado de habilidades.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
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

  Widget _buildHabilidadeDistribuicao() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribuição das Habilidades:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text('40% Habilidades de Suporte'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text('60% Habilidades Ofensivas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiposHabilidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipos de Habilidades de Suporte:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• 80% Aumentos de Atributos (Vida, Energia, Ataque, Defesa, Agilidade)'),
              Text('• 20% Cura (Restauração de Vida)'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tipos de Habilidades Ofensivas:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Dano Direto'),
              Text('• Diminuição de Atributos do Oponente'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExemplosHabilidades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exemplos de Habilidades por Tipo:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ModalMonstroAventura(
          monstro: MonstroAventura(
            tipo: Tipo.fogo,
            tipoExtra: Tipo.voador,
            imagem: 'assets/monstros_aventura/fogo.png',
            vida: 75,
            energia: 45,
            agilidade: 20,
            ataque: 30,
            defesa: 35,
            habilidades: [
              Habilidade(
                nome: 'Ataque Flamejante',
                descricao: 'Causa dano direto com poder do fogo',
                tipo: TipoHabilidade.ofensiva,
                efeito: EfeitoHabilidade.danoDirecto,
                tipoElemental: Tipo.fogo,
                valor: 25,
                custoEnergia: 3,
              ),
              Habilidade(
                nome: 'Rajada Devastadora',
                descricao: 'Diminui o ataque do oponente com vento cortante',
                tipo: TipoHabilidade.ofensiva,
                efeito: EfeitoHabilidade.danoDirecto,
                tipoElemental: Tipo.voador,
                valor: 18,
                custoEnergia: 2,
              ),
              Habilidade(
                nome: 'Força Ardente',
                descricao: 'Aumenta o poder de ataque com chamas',
                tipo: TipoHabilidade.suporte,
                efeito: EfeitoHabilidade.aumentarAtaque,
                tipoElemental: Tipo.fogo,
                valor: 12,
                custoEnergia: 4,
              ),
              Habilidade(
                nome: 'Regeneração',
                descricao: 'Recupera vida usando energia vital',
                tipo: TipoHabilidade.suporte,
                efeito: EfeitoHabilidade.curarVida,
                tipoElemental: Tipo.fogo,
                valor: 20,
                custoEnergia: 5,
              ),
            ],
            item: '',
          ),
          onClose: null,
          showCloseButton: false,
        ),
      ],
    );
  }
}
