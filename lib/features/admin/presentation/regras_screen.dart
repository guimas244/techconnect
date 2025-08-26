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
                    itemEquipado: null,
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
            ExpansionTile(
              title: const Text(
                'Sistema de Energia',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'O sistema de energia controla o uso de habilidades durante as batalhas:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildEnergiaRegras(),
                const SizedBox(height: 16),
                _buildAtaqueBasico(),
                const SizedBox(height: 16),
                Text(
                  'A energia adiciona estratégia às batalhas, forçando o uso inteligente das habilidades mais poderosas.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text(
                'Sistema de Batalha',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'As batalhas seguem regras específicas para garantir equilíbrio e estratégia:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBatalhaRegras(),
                const SizedBox(height: 16),
                _buildBuffsTemporarios(),
                const SizedBox(height: 16),
                Text(
                  'O sistema de batalha foi otimizado para proporcionar experiências táticas e dinâmicas.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text(
                'Interface e Experiência',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Melhorias implementadas para uma melhor experiência do usuário:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInterfaceRegras(),
                const SizedBox(height: 16),
                Text(
                  'Todas essas melhorias foram implementadas com base no feedback e testes de usabilidade.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text(
                'Sistema de Itens e Equipamentos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Sistema completo de itens que podem ser equipados pelos monstros para aumentar seus atributos:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTiposItens(),
                const SizedBox(height: 16),
                _buildRaridadeItens(),
                const SizedBox(height: 16),
                _buildAtributosItens(),
                const SizedBox(height: 16),
                Text(
                  'O sistema de itens adiciona customização e progressão aos monstros, permitindo builds estratégicos.',
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

  Widget _buildEnergiaRegras() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custo de Energia:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Cada habilidade tem um custo de energia de 1 a 5 pontos'),
          Text('• O custo é gerado aleatoriamente quando a habilidade é criada'),
          Text('• Habilidades mais poderosas tendem a custar mais energia'),
          const SizedBox(height: 12),
          Text(
            'Gerenciamento de Energia:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• A energia é deduzida automaticamente ao usar habilidades'),
          Text('• O sistema verifica se há energia suficiente antes de executar'),
          Text('• Barras visuais mostram a energia atual/máxima em tempo real'),
        ],
      ),
    );
  }

  Widget _buildAtaqueBasico() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ataque Básico:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Quando não há energia para habilidades, o sistema usa ataque básico'),
          Text('• Ataque básico não consome energia e causa dano baseado no atributo ataque'),
          Text('• Garantia de que a batalha sempre pode continuar'),
        ],
      ),
    );
  }

  Widget _buildBatalhaRegras() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mecânicas de Batalha:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Turnos alternados baseados na agilidade (maior agilidade começa)'),
          Text('• Rodadas completas: cada clique executa uma ação de cada lado'),
          Text('• Cálculo de dano: (Habilidade + Ataque) - Defesa = Dano Final'),
          Text('• Dano mínimo garantido de 1 ponto mesmo com alta defesa'),
          const SizedBox(height: 12),
          Text(
            'Habilidades de Suporte:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Habilidades de suporte podem ser usadas apenas uma vez por batalha'),
          Text('• Habilidades ofensivas podem ser reutilizadas'),
          Text('• Velocidade (agilidade) não pode ser aumentada por habilidades'),
        ],
      ),
    );
  }

  Widget _buildBuffsTemporarios() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistema de Buffs:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Buffs temporários são aplicados durante a batalha'),
          Text('• Indicadores visuais mostram atributos aumentados: "Vida (+10)"'),
          Text('• Vida máxima pode ser aumentada temporariamente'),
          Text('• Todos os buffs são resetados após a batalha'),
          const SizedBox(height: 12),
          Text(
            'Visualização:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Cards de batalha mostram valores atuais com buffs'),
          Text('• Modal de detalhes exibe incrementos em verde'),
          Text('• Histórico de batalha mostra alterações em tempo real'),
        ],
      ),
    );
  }

  Widget _buildInterfaceRegras() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Melhorias de Interface:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Remoção do botão "Voltar" durante batalhas'),
          Text('• Reposicionamento de botões para melhor acessibilidade'),
          Text('• Histórico de batalha em ordem cronológica inversa'),
          Text('• Modal de detalhes ao clicar na imagem do monstro'),
          const SizedBox(height: 12),
          Text(
            'Informações Visuais:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Barras de energia com indicadores visuais precisos'),
          Text('• Textos melhorados para habilidades de suporte'),
          Text('• Feedback detalhado sobre mudanças de atributos'),
          Text('• Correção na exibição de energia do monstro inimigo'),
        ],
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
            itemEquipado: null,
          ),
          onClose: null,
          showCloseButton: false,
        ),
      ],
    );
  }

  Widget _buildTiposItens() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipos de Itens:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Armaduras: Proteção corporal completa'),
          Text('• Capacetes: Proteção para a cabeça'),
          Text('• Luvas: Proteção e poder para as mãos'),
          Text('• Botas: Calçados especiais'),
          Text('• Colares: Joias com poderes mágicos'),
          Text('• Anéis: Pequenos mas poderosos acessórios'),
          Text('• Orbs: Esferas de energia pura'),
          Text('• Amuletos: Talismãs protetores'),
          Text('• Braceletes: Pulseiras encantadas'),
          Text('• Cintos: Acessórios de suporte'),
        ],
      ),
    );
  }

  Widget _buildRaridadeItens() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistema de Raridade:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Inferior (35%): Itens básicos e gastos'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Normal (30%): Itens confiáveis e duráveis'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Raro (20%): Itens mágicos e encantados'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Épico (10%): Itens supremos e heroicos'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Lendário (5%): Itens únicos e divinos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAtributosItens() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistema de Atributos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Cada item aumenta de 1 a 5 atributos diferentes'),
          Text('• Todos os aumentos são de +1 ponto por atributo'),
          Text('• Atributos disponíveis: Vida, Energia, Agilidade, Ataque, Defesa'),
          const SizedBox(height: 12),
          Text(
            'Probabilidade de Atributos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• 1 atributo: 65% (mais comum)'),
          Text('• 2 atributos: 20%'),
          Text('• 3 atributos: 10%'),
          Text('• 4 atributos: 3%'),
          Text('• 5 atributos: 2% (muito raro)'),
          const SizedBox(height: 12),
          Text(
            'Exemplos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• "Luvas Mágicas do Trovão": +1 Ataque'),
          Text('• "Orb Supremo do Fogo": +1 Vida, +1 Energia, +1 Ataque'),
          Text('• "Armadura Lendária dos Deuses": +1 em todos os atributos'),
        ],
      ),
    );
  }
}
