import 'dart:math';
import '../models/item.dart';

enum TipoItem {
  armadura('Armadura'),
  capacete('Capacete'),
  luvas('Luvas'),
  botas('Botas'),
  colar('Colar'),
  anel('Anel'),
  orb('Orb'),
  amuleto('Amuleto'),
  bracelete('Bracelete'),
  cinto('Cinto');

  const TipoItem(this.nome);
  final String nome;
}

class GeradorNomesItens {
  static final Random _random = Random();

  // Distribuição de raridade baseada nos percentuais fornecidos
  static final Map<RaridadeItem, int> _pesoRaridade = {
    RaridadeItem.inferior: 35, // 35%
    RaridadeItem.normal: 30,   // 30%
    RaridadeItem.raro: 20,     // 20%
    RaridadeItem.epico: 10,    // 10%
    RaridadeItem.lendario: 5,  // 5%
  };

  // Prefixos por raridade
  static final Map<RaridadeItem, List<String>> _prefixosPorRaridade = {
    RaridadeItem.inferior: [
      'Velho', 'Quebrado', 'Gasto', 'Simples', 'Comum', 'Básico', 'Tosco', 'Rudimentar',
      'Desgastado', 'Rachado', 'Enferrujado', 'Surrado', 'Ordinário', 'Vulgar', 'Trivial'
    ],
    RaridadeItem.normal: [
      'Resistente', 'Sólido', 'Confiável', 'Duradouro', 'Funcional', 'Estável', 'Firme',
      'Bem Feito', 'Polido', 'Limpo', 'Íntegro', 'Útil', 'Prático', 'Eficiente', 'Decente'
    ],
    RaridadeItem.raro: [
      'Mágico', 'Encantado', 'Brilhante', 'Radiante', 'Cristalino', 'Élfico', 'Arcano',
      'Místico', 'Etéreo', 'Luminoso', 'Cintilante', 'Energizado', 'Abençoado', 'Sagrado'
    ],
    RaridadeItem.epico: [
      'Supremo', 'Majestoso', 'Imperial', 'Real', 'Glorioso', 'Magnifico', 'Épico',
      'Heroico', 'Titânico', 'Colossal', 'Poderoso', 'Devastador', 'Invencível', 'Imortal'
    ],
    RaridadeItem.lendario: [
      'Lendário', 'Ancestral', 'Primordial', 'Celestial', 'Divino', 'Eterno', 'Infinito',
      'Cósmico', 'Absoluto', 'Transcendente', 'Supremo', 'Omnipotente', 'Mítico', 'Dracônico'
    ],
  };

  // Sufixos elementais e temáticos
  static final List<String> _sufixosElementais = [
    'do Fogo', 'da Água', 'do Vento', 'da Terra', 'do Gelo', 'do Trovão', 'da Luz', 'das Trevas',
    'da Natureza', 'do Veneno', 'da Pedra', 'do Dragão', 'do Fantasma', 'da Magia', 'da Tecnologia',
    'do Oceano', 'do Céu', 'da Floresta', 'do Deserto', 'da Montanha', 'do Vulcão', 'do Abismo'
  ];

  // Sufixos de poder
  static final List<String> _sufixosPoder = [
    'da Força', 'da Velocidade', 'da Resistência', 'da Vitalidade', 'da Energia', 'do Poder',
    'da Proteção', 'da Regeneração', 'da Destruição', 'da Sabedoria', 'da Coragem', 'da Fúria',
    'da Serenidade', 'do Equilíbrio', 'da Harmonia', 'da Concentração', 'da Precisão', 'da Agilidade'
  ];

  // Nomes base para cada tipo de item
  static final Map<TipoItem, List<String>> _nomesBaseItens = {
    TipoItem.armadura: [
      'Couraça', 'Peitoral', 'Armadura', 'Proteção', 'Courante', 'Gibão', 'Cota', 'Loriga',
      'Couro', 'Placas', 'Malha', 'Vestimenta', 'Traje', 'Protetor', 'Blindagem', 'Defesa',
      'Escama', 'Casco', 'Carapuça', 'Manto', 'Túnica', 'Veste', 'Jaleco', 'Sobretudo'
    ],
    TipoItem.capacete: [
      'Elmo', 'Capacete', 'Yelmo', 'Tiara', 'Coroa', 'Diadema', 'Capuz', 'Barrete',
      'Píleo', 'Gorro', 'Boné', 'Chapéu', 'Helm', 'Morião', 'Celada', 'Barbute',
      'Cabeça', 'Protetor', 'Crista', 'Casco', 'Cobertura', 'Faixa', 'Bandana', 'Turbante'
    ],
    TipoItem.luvas: [
      'Luvas', 'Manoplas', 'Gauntlets', 'Punhos', 'Protetor de Mãos', 'Dedeiras', 'Garras',
      'Mitenes', 'Guantes', 'Proteções', 'Braçadeiras', 'Punheiras', 'Algemas', 'Abraçadeiras',
      'Talheres', 'Ganchos', 'Lâminas', 'Espinhos', 'Anéis', 'Dedais', 'Presilhas', 'Fivelas'
    ],
    TipoItem.botas: [
      'Botas', 'Sapatos', 'Sandálias', 'Chinelos', 'Coturnos', 'Botinas', 'Tênis', 'Alpargatas',
      'Pés', 'Protetor de Pés', 'Solado', 'Pisantes', 'Patins', 'Esporas', 'Ferraduras', 'Palmilhas',
      'Grevas', 'Polainas', 'Cano', 'Salto', 'Sola', 'Cadarço', 'Velcro', 'Fivela'
    ],
    TipoItem.colar: [
      'Colar', 'Gargantilha', 'Corrente', 'Cordão', 'Coleira', 'Medalha', 'Pendente', 'Amuleto',
      'Torque', 'Choker', 'Rosário', 'Escapulário', 'Relicário', 'Talismã', 'Berloque', 'Pingente',
      'Cordel', 'Fio', 'Cabo', 'Tira', 'Faixa', 'Banda', 'Laço', 'Nó'
    ],
    TipoItem.anel: [
      'Anel', 'Aliança', 'Argola', 'Aro', 'Círculo', 'Banda', 'Sinete', 'Selo', 'Marca',
      'Dedeira', 'Falange', 'Junta', 'Nó', 'Laço', 'Presilha', 'Grampo', 'Clip',
      'Fivela', 'Broche', 'Pino', 'Trava', 'Gancho', 'Abraçadeira', 'Cinta', 'Fita'
    ],
    TipoItem.orb: [
      'Orb', 'Esfera', 'Globo', 'Cristal', 'Pedra', 'Gema', 'Joia', 'Perla', 'Mármore',
      'Núcleo', 'Centro', 'Coração', 'Alma', 'Essência', 'Fonte', 'Origem', 'Base',
      'Fragmento', 'Shard', 'Estilhaço', 'Pedaço', 'Parte', 'Porção', 'Seção', 'Fatia'
    ],
    TipoItem.amuleto: [
      'Amuleto', 'Talismã', 'Charme', 'Fetiche', 'Berloque', 'Mascote', 'Símbolo', 'Emblema',
      'Insígnia', 'Brasão', 'Marca', 'Selo', 'Signo', 'Sinal', 'Token', 'Ficha',
      'Relíquia', 'Lembrança', 'Memória', 'Recordação', 'Souvenir', 'Troféu', 'Prêmio', 'Conquista'
    ],
    TipoItem.bracelete: [
      'Bracelete', 'Pulseira', 'Brazalete', 'Munhequeira', 'Algema', 'Abraçadeira', 'Faixa', 'Banda',
      'Tira', 'Correia', 'Cinta', 'Laço', 'Nó', 'Presilha', 'Grampo', 'Clip',
      'Fivela', 'Broche', 'Pino', 'Trava', 'Gancho', 'Suporte', 'Apoio', 'Base'
    ],
    TipoItem.cinto: [
      'Cinto', 'Cintura', 'Faixa', 'Banda', 'Tira', 'Correia', 'Cinta', 'Abraçadeira',
      'Laço', 'Nó', 'Presilha', 'Fivela', 'Broche', 'Pino', 'Trava', 'Gancho',
      'Suporte', 'Apoio', 'Base', 'Alicerce', 'Fundação', 'Estrutura', 'Esqueleto', 'Ossatura'
    ],
  };

  // Nomes únicos para itens lendários
  static final Map<TipoItem, List<String>> _nomesLendarios = {
    TipoItem.armadura: [
      'Aegis Eterna', 'Couraça do Cosmos', 'Proteção Primordial', 'Armadura dos Deuses',
      'Vestimenta do Infinito', 'Defesa Celestial', 'Blindagem Divina', 'Escudo do Universo'
    ],
    TipoItem.capacete: [
      'Coroa dos Titãs', 'Diadema Cósmico', 'Elmo do Destino', 'Capacete da Eternidade',
      'Tiara Celestial', 'Helm Primordial', 'Yelmo dos Deuses', 'Proteção Divina'
    ],
    TipoItem.luvas: [
      'Punhos do Infinito', 'Garras Cósmicas', 'Luvas da Criação', 'Manoplas Eternas',
      'Gauntlets Divinos', 'Mãos do Destino', 'Dedos da Fortuna', 'Poder Supremo'
    ],
    TipoItem.botas: [
      'Passos da Eternidade', 'Botas Cósmicas', 'Pés do Destino', 'Sandálias Divinas',
      'Coturnos Celestiais', 'Sapatos do Infinito', 'Grevas Primordiais', 'Marcha Eterna'
    ],
    TipoItem.colar: [
      'Colar das Estrelas', 'Gargantilha Cósmica', 'Corrente do Destino', 'Cordão Eterno',
      'Medalha Divina', 'Pendente Celestial', 'Amuleto Primordial', 'Talismã Supremo'
    ],
    TipoItem.anel: [
      'Anel do Poder Absoluto', 'Aliança Cósmica', 'Argola do Destino', 'Círculo Eterno',
      'Banda Celestial', 'Sinete Divino', 'Selo Primordial', 'Marca Suprema'
    ],
    TipoItem.orb: [
      'Orb da Criação', 'Esfera Cósmica', 'Cristal do Infinito', 'Núcleo Primordial',
      'Gema do Universo', 'Pedra da Eternidade', 'Coração Celestial', 'Alma Divina'
    ],
    TipoItem.amuleto: [
      'Talismã Supremo', 'Amuleto Cósmico', 'Charme do Destino', 'Fetiche Eterno',
      'Símbolo Celestial', 'Emblema Divino', 'Relíquia Primordial', 'Mascote Supremo'
    ],
    TipoItem.bracelete: [
      'Pulseira do Infinito', 'Bracelete Cósmico', 'Munhequeira Eterna', 'Banda Celestial',
      'Abraçadeira Divina', 'Faixa Primordial', 'Tira Suprema', 'Correia do Destino'
    ],
    TipoItem.cinto: [
      'Cinto do Cosmos', 'Cintura Eterna', 'Faixa Celestial', 'Banda Divina',
      'Abraçadeira Primordial', 'Correia Suprema', 'Cinta do Infinito', 'Laço do Destino'
    ],
  };

  /// Sorteia uma raridade baseada nos pesos definidos
  static RaridadeItem sortearRaridade() {
    final totalPeso = _pesoRaridade.values.reduce((a, b) => a + b);
    final sorteio = _random.nextInt(totalPeso);
    
    int pesoAcumulado = 0;
    for (final entry in _pesoRaridade.entries) {
      pesoAcumulado += entry.value;
      if (sorteio < pesoAcumulado) {
        return entry.key;
      }
    }
    
    return RaridadeItem.inferior; // Fallback
  }

  /// Sorteia um tipo de item aleatório
  static TipoItem sortearTipoItem() {
    final tipos = TipoItem.values;
    return tipos[_random.nextInt(tipos.length)];
  }

  /// Gera um nome completo para um item
  static String gerarNomeItem({
    TipoItem? tipo,
    RaridadeItem? raridade,
  }) {
    tipo ??= sortearTipoItem();
    raridade ??= sortearRaridade();
    
    // Para itens lendários, usa nomes únicos
    if (raridade == RaridadeItem.lendario) {
      final nomesLendarios = _nomesLendarios[tipo] ?? ['Item Lendário'];
      return nomesLendarios[_random.nextInt(nomesLendarios.length)];
    }
    
    // Para outros itens, constrói o nome
    final prefixos = _prefixosPorRaridade[raridade]!;
    final nomesBase = _nomesBaseItens[tipo]!;
    
    final prefixo = prefixos[_random.nextInt(prefixos.length)];
    final nomeBase = nomesBase[_random.nextInt(nomesBase.length)];
    
    // 50% de chance de adicionar sufixo elemental ou de poder
    String sufixo = '';
    if (_random.nextBool()) {
      if (_random.nextBool()) {
        sufixo = _sufixosElementais[_random.nextInt(_sufixosElementais.length)];
      } else {
        sufixo = _sufixosPoder[_random.nextInt(_sufixosPoder.length)];
      }
    }
    
    return sufixo.isNotEmpty 
        ? '$prefixo $nomeBase $sufixo'
        : '$prefixo $nomeBase';
  }

  /// Sorteia a quantidade de atributos que o item terá
  static int sortearQuantidadeAtributos() {
    final sorteio = _random.nextInt(100);
    
    if (sorteio < 2) return 5;      // 2% chance de 5 atributos
    if (sorteio < 5) return 4;      // 3% chance de 4 atributos  
    if (sorteio < 15) return 3;     // 10% chance de 3 atributos
    if (sorteio < 35) return 2;     // 20% chance de 2 atributos
    return 1;                       // 65% chance de 1 atributo
  }

  /// Lista dos atributos disponíveis
  static const List<String> atributos = [
    'Vida', 'Energia', 'Agilidade', 'Ataque', 'Defesa'
  ];

  /// Sorteia quais atributos o item irá aumentar
  static List<String> sortearAtributos(int quantidade) {
    final atributosDisponiveis = List<String>.from(atributos);
    final atributosSorteados = <String>[];
    
    for (int i = 0; i < quantidade && atributosDisponiveis.isNotEmpty; i++) {
      final index = _random.nextInt(atributosDisponiveis.length);
      atributosSorteados.add(atributosDisponiveis.removeAt(index));
    }
    
    return atributosSorteados;
  }

  /// Gera uma descrição para o item baseada nos atributos
  static String gerarDescricao(List<String> atributosBeneficiados) {
    if (atributosBeneficiados.isEmpty) {
      return 'Um item misterioso sem efeitos aparentes.';
    }
    
    final String atributosTexto = atributosBeneficiados.length == 1
        ? atributosBeneficiados.first.toLowerCase()
        : atributosBeneficiados.length == 2
            ? '${atributosBeneficiados.first.toLowerCase()} e ${atributosBeneficiados.last.toLowerCase()}'
            : '${atributosBeneficiados.take(atributosBeneficiados.length - 1).map((a) => a.toLowerCase()).join(', ')} e ${atributosBeneficiados.last.toLowerCase()}';
    
    final List<String> descricoesPossibles = [
      'Este item aumenta permanentemente $atributosTexto em 1 ponto quando equipado.',
      'Fortalece $atributosTexto do portador em 1 ponto.',
      'Concede +1 de bônus em $atributosTexto.',
      'Melhora $atributosTexto do usuário em 1 ponto.',
      'Aumenta $atributosTexto em 1 ponto enquanto estiver equipado.',
    ];
    
    return descricoesPossibles[_random.nextInt(descricoesPossibles.length)];
  }

  /// Gera um item completo com todas as propriedades
  static Map<String, dynamic> gerarItemCompleto({
    TipoItem? tipo,
    RaridadeItem? raridade,
  }) {
    tipo ??= sortearTipoItem();
    raridade ??= sortearRaridade();
    
    final quantidadeAtributos = sortearQuantidadeAtributos();
    final atributosBeneficiados = sortearAtributos(quantidadeAtributos);
    final nome = gerarNomeItem(tipo: tipo, raridade: raridade);
    final descricao = gerarDescricao(atributosBeneficiados);
    
    return {
      'nome': nome,
      'tipo': tipo.nome,
      'raridade': raridade.nome,
      'nivel': raridade.nivel,
      'cor': raridade.cor,
      'atributos': atributosBeneficiados,
      'quantidadeAtributos': quantidadeAtributos,
      'descricao': descricao,
    };
  }
}
