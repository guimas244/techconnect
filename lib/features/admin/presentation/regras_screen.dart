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
                    level: 2, // Exemplo de monstro com level 2
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
            ExpansionTile(
              title: const Text(
                'Sistema de Efetividade de Tipos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'O sistema de efetividade determina o dano causado entre diferentes tipos de monstros:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildEfetividadeMultiplicadores(),
                const SizedBox(height: 16),
                _buildEfetividadeExemplos(),
                const SizedBox(height: 16),
                Text(
                  'A efetividade varia de 0.0x (Imune) até 5.0x (Insignificante), criando estratégias baseadas em tipos.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text(
                'Sistema de Levels e Evolução',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: 8),
                _buildEvolucaoRecuperacaoVida(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Monstros possuem levels que podem aumentar através de batalhas vitoriosas:',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTierELevelRelacao(),
                const SizedBox(height: 16),
                _buildLevelBasico(),
                const SizedBox(height: 16),
                _buildEvolucaoRegras(),
                const SizedBox(height: 16),
                _buildEvolucaoHabilidades(),
                const SizedBox(height: 16),
                _buildHabilidadesInimigos(),
                const SizedBox(height: 16),
                _buildLevelGapRegra(),
                const SizedBox(height: 16),
                Text(
                  'O sistema de levels garante progressão balanceada, onde monstros evoluem apenas contra desafios apropriados.',
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
                level: 1,
              ),
              Habilidade(
                nome: 'Rajada Devastadora',
                descricao: 'Diminui o ataque do oponente com vento cortante',
                tipo: TipoHabilidade.ofensiva,
                efeito: EfeitoHabilidade.danoDirecto,
                tipoElemental: Tipo.voador,
                valor: 18,
                custoEnergia: 2,
                level: 1,
              ),
              Habilidade(
                nome: 'Força Ardente',
                descricao: 'Aumenta o poder de ataque com chamas',
                tipo: TipoHabilidade.suporte,
                efeito: EfeitoHabilidade.aumentarAtaque,
                tipoElemental: Tipo.fogo,
                valor: 12,
                custoEnergia: 4,
                level: 1,
              ),
              Habilidade(
                nome: 'Regeneração',
                descricao: 'Recupera vida usando energia vital',
                tipo: TipoHabilidade.suporte,
                efeito: EfeitoHabilidade.curarVida,
                tipoElemental: Tipo.fogo,
                valor: 20,
                custoEnergia: 5,
                level: 1,
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

  Widget _buildTierELevelRelacao() {
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
          Row(
            children: [
              Icon(Icons.layers, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Relação Tier ↔ Level:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('• Tier 1 = Inimigos Level 1'),
          Text('• Tier 2 = Inimigos Level 2'),  
          Text('• Tier 3 = Inimigos Level 3'),
          Text('• E assim por diante...'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '💡 Conforme você avança de tier, os inimigos ficam automaticamente mais fortes (level mais alto)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBasico() {
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
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Level dos Monstros:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('• Todos os monstros do jogador começam no Level 1'),
          Text('• O level é exibido com um ícone de estrela ⭐ em todas as interfaces'),
          Text('• Monstros inimigos têm level = tier atual do mapa de aventura'),
          Text('• Level 1 vs Level 1 = batalha equilibrada'),
        ],
      ),
    );
  }

  Widget _buildEvolucaoRecuperacaoVida() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, color: Colors.pink.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sistema de Recuperação de Vida na Evolução:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Ao evoluir, o monstro recupera ${AtributoJogo.evolucaoRecuperacaoVida.min}% da sua vida máxima',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '• Recuperação só acontece se a vida atual estiver abaixo de ${AtributoJogo.evolucaoLimiteRecuperacao.min}%',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '• Se a vida já estiver acima de ${AtributoJogo.evolucaoLimiteRecuperacao.min}%, não há recuperação',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '• Vida negativa é tratada como 0 antes do cálculo',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exemplos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Monstro com 30/100 HP → Evolui → 80/105 HP (recuperou 50)',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '• Monstro com 60/100 HP → Evolui → 65/105 HP (sem recuperação)',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '• Monstro com 0/100 HP → Evolui → 55/105 HP (recuperou de 0 para 50)',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolucaoRegras() {
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
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mecânica de Evolução:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('• Ao vencer uma batalha, 1 monstro aleatório pode evoluir'),
          Text('• Evolução NÃO é uma escolha do jogador - é automática e aleatória'),
          Text('• Cada evolução concede: +1 Level'),
          const SizedBox(height: 8),
          Text(
            'Ganhos por Evolução:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('• +5 pontos de Vida (sempre)'),
          Text('• +5 pontos de Energia (sempre)'),
          Text('• +5 pontos em 1 atributo aleatório (Ataque, Defesa ou Agilidade)'),
          Text('• Recuperação de ${AtributoJogo.evolucaoRecuperacaoVida.min}% da vida máxima'),
        ],
      ),
    );
  }

  Widget _buildLevelGapRegra() {
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
          Row(
            children: [
              Icon(Icons.block, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Regra do Level Gap:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('• Se o monstro sorteado for MAIOR que o level do inimigo derrotado, NÃO evolui'),
          Text('• Pode evoluir se for MENOR OU IGUAL ao level do inimigo'),
          Text('• Esta regra evita que monstros muito poderosos "farmen" levels contra inimigos fracos'),
          Text('• Lembre-se: Inimigos têm level = tier do mapa atual'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exemplo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('• Monstro Lv.2 vs Tier 1 (Inimigo Lv.1) = SEM evolução (maior)'),
                Text('• Monstro Lv.1 vs Tier 1 (Inimigo Lv.1) = PODE evoluir (igual)'),
                Text('• Monstro Lv.1 vs Tier 2 (Inimigo Lv.2) = PODE evoluir (menor)'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '💡 Dica: Enfrente inimigos do seu level ou superiores para garantir evolução!',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolucaoHabilidades() {
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
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Evolução das Habilidades:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('• Toda habilidade possui um Level (inicia no Level 1)'),
          Text('• Quando um monstro evolui, 1 habilidade aleatória também pode evoluir'),
          Text('• Valor efetivo da habilidade = Valor base × Level'),
          Text('• Exemplo: Habilidade 20 no Level 3 = 60 de poder efetivo'),
          Text('• Habilidades seguem as mesmas regras de Level Gap dos monstros'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level Gap das Habilidades:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('• Habilidade Level 1 vs Inimigo Level 1 = PODE evoluir'),
                Text('• Habilidade Level 2 vs Inimigo Level 1 = NÃO evolui'),
                Text('• Habilidade Level 1 vs Inimigo Level 2 = PODE evoluir'),
                Text('• Habilidade Level 2 vs Inimigo Level 2 = PODE evoluir'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cenários Especiais:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('• Monstro com Level Gap ainda pode ter habilidades evoluindo'),
                Text('• Modal especial mostra apenas evolução da habilidade'),
                Text('• Todas as habilidades do monstro são consideradas para evolução'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabilidadesInimigos() {
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
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Habilidades dos Monstros Inimigos:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('• Tier 1: Todas as habilidades permanecem Level 1'),
          Text('• Tier 2+: Cada habilidade pode evoluir aleatoriamente'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chances de Evolução (Tier 2+):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('• 20% chance: Level = Tier do andar'),
                Text('• 20% chance: Level = Tier - 1 (mínimo 1)'),
                Text('• 60% chance: Permanece Level 1'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exemplos Práticos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('• Tier 3: 20% Level 3, 20% Level 2, 60% Level 1'),
                Text('• Tier 5: 20% Level 5, 20% Level 4, 60% Level 1'),
                Text('• Cada habilidade roda sua própria chance individualmente'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '💡 Um monstro inimigo pode ter habilidades com níveis variados (ex: Level 1, Level 3, Level 1, Level 2)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfetividadeMultiplicadores() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multiplicadores de Efetividade:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildEfetividadeItem('0.0x', 'Imune', Colors.green.shade700),
          _buildEfetividadeItem('< 0.5x', 'Muito Resistente', Colors.green),
          _buildEfetividadeItem('< 1.0x', 'Resistente', Colors.orange),
          _buildEfetividadeItem('1.0x', 'Normal', Colors.grey),
          _buildEfetividadeItem('< 1.5x', 'Fraco', Colors.red),
          _buildEfetividadeItem('< 2.0x', 'Muito Fraco', Colors.red.shade800),
          _buildEfetividadeItem('< 2.5x', 'Extremamente Fraco', Colors.red.shade800),
          _buildEfetividadeItem('< 3.0x', 'Devastador', Colors.red.shade800),
          _buildEfetividadeItem('< 3.5x', 'Fraqueza Extrema', Colors.purple),
          _buildEfetividadeItem('< 4.0x', 'Vulnerabilidade Total', Colors.purple),
          _buildEfetividadeItem('< 4.5x', 'Resistência Nula', Colors.purple.shade800),
          _buildEfetividadeItem('< 5.0x', 'Defesa de Papel', Colors.purple.shade800),
          _buildEfetividadeItem('≥ 5.0x', 'Insignificante', Colors.black),
        ],
      ),
    );
  }

  Widget _buildEfetividadeItem(String multiplicador, String descricao, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text(
              multiplicador,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: cor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              descricao,
              style: TextStyle(fontSize: 14, color: cor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfetividadeExemplos() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como Funciona:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• O dano base é multiplicado pela efetividade'),
          Text('• Exemplo: 30 de dano × 2.5x = 75 de dano final'),
          Text('• Imunidade (0.0x) bloqueia completamente o dano'),
          Text('• Habilidades ofensivas têm dano mínimo de 5 (exceto imunes)'),
          Text('• Resistência alta pode reduzir drasticamente o dano'),
          const SizedBox(height: 12),
          Text(
            'Estratégia:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• Use tipos vantajosos para maximizar dano'),
          Text('• Evite ataques contra tipos resistentes'),
          Text('• Monstros com duplo tipo têm defesas complexas'),
          Text('• Planeje suas equipes considerando as efetividades'),
        ],
      ),
    );
  }
}
