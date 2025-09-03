import 'dart:math';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';

class GeradorNomesHabilidades {
  static final Random _random = Random();

  // Estruturas de nomes por tipo e efeito
  static final Map<Tipo, Map<String, List<String>>> _nomesHabilidades = {
    Tipo.fogo: {
      'ofensiva': [
        'Sopro Flamejante', 'Erupção Ardente', 'Punho de Magma', 'Chamas da Ira',
        'Tempestade de Fogo', 'Lança de Brasa', 'Meteoro Ardente', 'Explosão Solar',
        'Rajada Incandescente', 'Devastação Ígnea', 'Golpe Infernal', 'Tsunami de Lava'
      ],
      'suporte': [
        'Aura Flamejante', 'Benção do Vulcão', 'Calor Protetor', 'Energia Ígnea',
        'Espírito do Fogo', 'Força Ardente', 'Regeneração Térmica', 'Vigor Flamejante',
        'Chama Curativa', 'Renascimento das Cinzas', 'Poder do Magma', 'Essência Solar'
      ]
    },
    Tipo.agua: {
      'ofensiva': [
        'Tsunami Devastador', 'Jato Perfurante', 'Maremoto Sombrio', 'Pressão Abissal',
        'Tempestade Aquática', 'Lâmina Líquida', 'Vórtice Destruidor', 'Tromba d\'Água',
        'Corrente Mortal', 'Gêiser Explosivo', 'Onda Cortante', 'Dilúvio Caótico'
      ],
      'suporte': [
        'Chuva Curativa', 'Aura Oceânica', 'Benção das Marés', 'Vitalidade Aquática',
        'Essência Marinha', 'Proteção Fluida', 'Renovação Hídrica', 'Fonte da Vida',
        'Escudo de Bolhas', 'Corrente Restauradora', 'Névoa Regenerativa', 'Poder das Profundezas'
      ]
    },
    Tipo.vento: {
      'ofensiva': [
        'Rajada Cortante', 'Furacão Destruidor', 'Lâmina do Vento', 'Ciclone Feroz',
        'Tempestade Sombria', 'Tornado Mortal', 'Ventania Dilacerante', 'Sopro Glacial',
        'Redemoinho Fatal', 'Pressão Atmosférica', 'Corrente Aérea', 'Tufão Devastador'
      ],
      'suporte': [
        'Aura dos Ventos', 'Brisa Curativa', 'Velocidade do Ar', 'Proteção Etérea',
        'Espírito Ventoso', 'Levitação Mágica', 'Corrente Vital', 'Sussurro do Céu',
        'Carícia do Vento', 'Dança Aérea', 'Liberdade Alada', 'Benção Celestial'
      ]
    },
    Tipo.planta: {
      'ofensiva': [
        'Chicote de Espinhos', 'Raízes Estrangulantes', 'Chuva de Sementes', 'Perfuração Vegetal',
        'Explosão de Pólen', 'Lança Natural', 'Garras de Madeira', 'Veneno Botânico',
        'Prisão Vegetal', 'Devastação Selvagem', 'Fúria da Natureza', 'Armadilha Floral'
      ],
      'suporte': [
        'Fotossíntese', 'Aura da Floresta', 'Regeneração Natural', 'Vitalidade Verde',
        'Benção da Terra', 'Seiva Curativa', 'Proteção Selvagem', 'Força da Natureza',
        'Renovação Botânica', 'Essência Vegetal', 'Harmonia Natural', 'Crescimento Vital'
      ]
    },
    Tipo.eletrico: {
      'ofensiva': [
        'Descarga Elétrica', 'Raio Fulminante', 'Tempestade de Raios', 'Choque Devastador',
        'Relâmpago Mortal', 'Pulso Elétrico', 'Trovão Destruidor', 'Corrente Letal',
        'Faísca Explosiva', 'Plasma Destrutivo', 'Sobrecarga Neural', 'Arco Voltaico'
      ],
      'suporte': [
        'Campo Elétrico', 'Energia Revitalizante', 'Choque Curativo', 'Aura Magnética',
        'Proteção Iônica', 'Estimulação Neural', 'Força Elétrica', 'Vigor Eletrônico',
        'Regeneração Elétrica', 'Pulso Vital', 'Corrente Restauradora', 'Poder do Trovão'
      ]
    },
    Tipo.gelo: {
      'ofensiva': [
        'Ventisca Mortal', 'Lança de Gelo', 'Explosão Glacial', 'Prisão Congelante',
        'Tempestade de Neve', 'Punhal Gelado', 'Avalanche Destruidora', 'Sopro Ártico',
        'Cristal Perfurante', 'Nevasca Sombria', 'Frio Mortal', 'Geada Cortante'
      ],
      'suporte': [
        'Aura Glacial', 'Proteção Cristalina', 'Regeneração Gélida', 'Frieza Curativa',
        'Essência do Inverno', 'Vigor Ártico', 'Benção do Gelo', 'Força Glacial',
        'Renovação Cristalina', 'Escudo de Neve', 'Poder Congelante', 'Calma Polar'
      ]
    },
    Tipo.pedra: {
      'ofensiva': [
        'Avalanche Rochosa', 'Punho de Pedra', 'Terremoto Devastador', 'Meteoro Pétreo',
        'Bombardeio Mineral', 'Lâmina Rochosa', 'Esmagamento Brutal', 'Fragmentação',
        'Impacto Sísmico', 'Chuva de Pedras', 'Pressão Telúrica', 'Erupção Terrestre'
      ],
      'suporte': [
        'Pele de Pedra', 'Fortaleza Rochosa', 'Resistência Mineral', 'Escudo Pétreo',
        'Força da Terra', 'Dureza Diamantina', 'Proteção Telúrica', 'Vigor Rochoso',
        'Essência Mineral', 'Solidez Eterna', 'Poder Geológico', 'Estabilidade Térrea'
      ]
    },
    Tipo.luz: {
      'ofensiva': [
        'Raio Solar', 'Explosão Luminosa', 'Lâmina de Luz', 'Cegueira Radiante',
        'Pulso Fotônico', 'Devastação Solar', 'Clarão Destruidor', 'Rajada Luminosa',
        'Perfuração Radiante', 'Tempestade de Fótons', 'Laser Celestial', 'Fulgor Mortal'
      ],
      'suporte': [
        'Aura Sagrada', 'Benção Luminosa', 'Cura Radiante', 'Proteção Celestial',
        'Luz Curativa', 'Vigor Solar', 'Essência Divina', 'Iluminação Vital',
        'Claridade Restauradora', 'Poder Angelical', 'Graça Luminosa', 'Energia Pura'
      ]
    },
    Tipo.trevas: {
      'ofensiva': [
        'Sombra Cortante', 'Vazio Devorador', 'Escuridão Mortal', 'Pesadelo Sombrio',
        'Lâmina das Trevas', 'Absorção Vital', 'Maldição Negra', 'Terror Noturno',
        'Perfuração Sombria', 'Caos Umbral', 'Aniquilação Sombria', 'Fúria das Trevas'
      ],
      'suporte': [
        'Aura Sombria', 'Proteção Umbral', 'Regeneração Negra', 'Vigor das Trevas',
        'Essência Noturna', 'Manto de Sombras', 'Força Obscura', 'Poder Sombrio',
        'Benção Noturna', 'Invisibilidade', 'Camuflagem Sombria', 'Mistério Umbral'
      ]
    },
    Tipo.dragao: {
      'ofensiva': [
        'Rugido Dracônico', 'Garra do Dragão', 'Sopro Ancestral', 'Fúria Imperial',
        'Chama Dracônica', 'Devastação Real', 'Poder Primordial', 'Ira do Dragão',
        'Tempestade Dracônica', 'Golpe Imperial', 'Majestade Destrutiva', 'Cólera Ancestral'
      ],
      'suporte': [
        'Majestade Dracônica', 'Benção Imperial', 'Vigor Ancestral', 'Proteção Real',
        'Essência Primordial', 'Poder do Dragão', 'Aura Imperial', 'Força Dracônica',
        'Resistência Ancestral', 'Domínio Dracônico', 'Presença Real', 'Legado do Dragão'
      ]
    },
    Tipo.inseto: {
      'ofensiva': [
        'Picada Venenosa', 'Enxame Destruidor', 'Mandíbula Cortante', 'Ferrão Mortal',
        'Acidez Digestiva', 'Perfuração Quitinosa', 'Invasão do Enxame', 'Veneno Paralisante',
        'Mordida Tóxica', 'Vibração Ultrassônica', 'Chuva de Larvas', 'Ataque Coordenado'
      ],
      'suporte': [
        'Carapaça Protetora', 'Regeneração Larvária', 'Agilidade do Enxame', 'Resistência Quitinosa',
        'Coordenação Coletiva', 'Vibração Curativa', 'Metamorfose', 'Força do Enxame',
        'Proteção Coletiva', 'Evolução Adaptativa', 'Instinto Primitivo', 'União do Enxame'
      ]
    },
    Tipo.venenoso: {
      'ofensiva': [
        'Toxina Letal', 'Veneno Corrosivo', 'Nuvem Tóxica', 'Picada Mortal',
        'Acidez Destrutiva', 'Paralisia Venenosa', 'Corrosão Fatal', 'Miasma Tóxico',
        'Peçonha Mortal', 'Dissolução Ácida', 'Contaminação', 'Necrose Tóxica'
      ],
      'suporte': [
        'Imunidade Tóxica', 'Resistência Venenosa', 'Antídoto Natural', 'Purificação',
        'Neutralização', 'Adaptação Tóxica', 'Proteção Química', 'Desintoxicação',
        'Regeneração Ácida', 'Imunidade Adaptativa', 'Resistência Química', 'Vigor Tóxico'
      ]
    },
    Tipo.fera: {
      'ofensiva': [
        'Garra Selvagem', 'Mordida Predadora', 'Investida Brutal', 'Rugido Intimidador',
        'Caçada Feroz', 'Instinto Assassino', 'Fúria Primitiva', 'Ataque Bestial',
        'Devastação Selvagem', 'Predação Mortal', 'Ferocidade', 'Ímpeto Selvagem'
      ],
      'suporte': [
        'Instinto de Sobrevivência', 'Resistência Selvagem', 'Vigor Animal', 'Faro Aguçado',
        'Agilidade Bestial', 'Força Primitiva', 'Adaptação Natural', 'Território Selvagem',
        'Proteção do Bando', 'Regeneração Bestial', 'Instinto Maternal', 'Harmonia Animal'
      ]
    },
    Tipo.zumbi: {
      'ofensiva': [
        'Mordida Infectante', 'Garra Putrefata', 'Miasma da Morte', 'Praga Zumbi',
        'Decomposição', 'Infecção Viral', 'Necrose Ativa', 'Putrefação',
        'Contágio Mortal', 'Deterioração', 'Apodrecimento', 'Corrupção Corporal'
      ],
      'suporte': [
        'Regeneração Morta-Viva', 'Resistência Necrótica', 'Imunidade à Dor', 'Vigor Zumbi',
        'Persistência Morta-Viva', 'Resistência Viral', 'Adaptação Necrótica', 'Força dos Mortos',
        'Insensibilidade', 'Durabilidade Zumbi', 'Resistência Total', 'Vitalidade Morta-Viva'
      ]
    },
    Tipo.marinho: {
      'ofensiva': [
        'Tsunami Abissal', 'Pressão das Profundezas', 'Tentáculo Esmagador', 'Corrente Mortal',
        'Vórtice Oceânico', 'Arpão Aquático', 'Tempestade Marinha', 'Implosão Abissal',
        'Maremoto Devastador', 'Perfuração Oceânica', 'Esmagamento Abissal', 'Fúria do Oceano'
      ],
      'suporte': [
        'Aura Oceânica', 'Proteção Marinha', 'Regeneração Aquática', 'Força das Marés',
        'Benção do Oceano', 'Vitalidade Abissal', 'Corrente Curativa', 'Vigor Marinho',
        'Essência Oceânica', 'Poder das Profundezas', 'Harmonia Aquática', 'Resistência Abissal'
      ]
    },
    Tipo.voador: {
      'ofensiva': [
        'Mergulho Devastador', 'Rajada Aérea', 'Garra do Céu', 'Voo Rasante',
        'Pressão Atmosférica', 'Bombardeio Aéreo', 'Velocidade Sônica', 'Queda Livre',
        'Ataque Planado', 'Corrente Ascendente', 'Turbulência', 'Investida Celestial'
      ],
      'suporte': [
        'Voo Sustentado', 'Agilidade Aérea', 'Proteção Celestial', 'Velocidade do Vento',
        'Visão Aguçada', 'Liberdade de Movimento', 'Corrente Elevadora', 'Graça Aérea',
        'Leveza Celestial', 'Perspectiva Superior', 'Mobilidade Aérea', 'Benção dos Céus'
      ]
    },
    Tipo.subterraneo: {
      'ofensiva': [
        'Escavação Mortal', 'Ataque Subterrâneo', 'Perfuração Telúrica', 'Emboscada Submersa',
        'Colapso do Solo', 'Tremor Sísmico', 'Tunelamento Explosivo', 'Erupção Terrestre',
        'Armadilha Subterrânea', 'Devastação Submersa', 'Implosão Telúrica', 'Fenda Abissal'
      ],
      'suporte': [
        'Proteção Subterrânea', 'Resistência Telúrica', 'Camuflagem Terrestre', 'Vigor Submerso',
        'Adaptação Subterrânea', 'Força da Terra', 'Estabilidade Rochosa', 'Percepção Sísmica',
        'Resistência à Pressão', 'Navegação Subterrânea', 'Proteção Geológica', 'Harmonia Telúrica'
      ]
    },
    Tipo.terrestre: {
      'ofensiva': [
        'Pisoteamento', 'Carga Terrestre', 'Impacto Sísmico', 'Devastação Telúrica',
        'Esmagamento Brutal', 'Rachadura Terrestre', 'Força Gravitacional', 'Tremor Destruidor',
        'Avalanche Controlada', 'Pressão Telúrica', 'Estrondo Terrestre', 'Colapso Estrutural'
      ],
      'suporte': [
        'Estabilidade Terrestre', 'Resistência Geológica', 'Vigor da Terra', 'Proteção Sólida',
        'Força Gravitacional', 'Firmeza Rochosa', 'Resistência Sísmica', 'Enraizamento',
        'Solidez Terrestre', 'Equilibrio Natural', 'Base Sólida', 'Fundação Inabalável'
      ]
    },
    Tipo.nostalgico: {
      'ofensiva': [
        'Melancolia Destrutiva', 'Lágrima Corrosiva', 'Saudade Paralisante', 'Lembrança Dolorosa',
        'Nostalgia Devastadora', 'Eco do Passado', 'Memória Fragmentada', 'Tempo Perdido',
        'Remorso Mortal', 'Vazio Emocional', 'Tristeza Profunda', 'Dor da Separação'
      ],
      'suporte': [
        'Memória Reconfortante', 'Nostalgia Curativa', 'Lembrança Feliz', 'Vigor do Passado',
        'Proteção Sentimental', 'Força da Tradição', 'Sabedoria Ancestral', 'Conforto Familiar',
        'Renovação Emocional', 'Paz Interior', 'Harmonia Temporal', 'Benção das Lembranças'
      ]
    },
    Tipo.mistico: {
      'ofensiva': [
        'Explosão Mística', 'Lâmina Etérea', 'Distorção Reality', 'Aniquilação Arcana',
        'Ruptura Dimensional', 'Devastação Mágica', 'Pulso Místico', 'Fragmentação Astral',
        'Implosão Mágica', 'Caos Arcano', 'Desintegração Mística', 'Colapso Dimensional'
      ],
      'suporte': [
        'Aura Mística', 'Proteção Arcana', 'Regeneração Mágica', 'Poder Ancestral',
        'Benção Etérea', 'Força Espiritual', 'Vigor Arcano', 'Escudo Místico',
        'Essência Mágica', 'Harmonia Astral', 'Sabedoria Arcana', 'Transcendência'
      ]
    },
    Tipo.alien: {
      'ofensiva': [
        'Raio Plasma', 'Desintegração Molecular', 'Pulso Gravitacional', 'Onda Psíquica',
        'Devastação Quântica', 'Laser Alienígena', 'Implosão Temporal', 'Radiação Cósmica',
        'Distorção Espacial', 'Aniquilação Atômica', 'Pulverização Neural', 'Colapso Quântico'
      ],
      'suporte': [
        'Tecnologia Avançada', 'Regeneração Quântica', 'Proteção Energética', 'Vigor Cósmico',
        'Adaptação Alienígena', 'Força Gravitacional', 'Escudo de Energia', 'Evolução Acelerada',
        'Resistência Cósmica', 'Transcendência Tecnológica', 'Poder Intergaláctico', 'Harmonia Universal'
      ]
    },
    Tipo.docrates: {
      'ofensiva': [
        'Lógica Destrutiva', 'Argumento Demolidor', 'Paradoxo Mortal', 'Refutação Aniquiladora',
        'Dialética Devastadora', 'Silogismo Mortal', 'Contradição Fatal', 'Ironia Destrutiva',
        'Sarcasmo Cortante', 'Crítica Demolidora', 'Análise Devastadora', 'Ceticismo Mortal'
      ],
      'suporte': [
        'Sabedoria Filosófica', 'Contemplação Curativa', 'Reflexão Protetora', 'Conhecimento Vital',
        'Meditação Restauradora', 'Insight Regenerativo', 'Compreensão Profunda', 'Clareza Mental',
        'Iluminação Intelectual', 'Paz Filosófica', 'Harmonia Racional', 'Transcendência Mental'
      ]
    },
    Tipo.fantasma: {
      'ofensiva': [
        'Toque Espectral', 'Assombração', 'Grito Fantasmagórico', 'Possessão Mortal',
        'Manifestação Sombria', 'Terror Sobrenatural', 'Lamento Fantasmal', 'Aparição Mortal',
        'Ectoplasma Corrosivo', 'Presença Maligna', 'Sussurro Mortal', 'Materialização Sombria'
      ],
      'suporte': [
        'Intangibilidade', 'Proteção Espectral', 'Regeneração Etérea', 'Vigor Fantasmal',
        'Resistência Espiritual', 'Forma Etérea', 'Proteção Sobrenatural', 'Essência Fantasma',
        'Invisibilidade Espectral', 'Transcendência Corporal', 'Imunidade Física', 'Paz Espiritual'
      ]
    },
    Tipo.psiquico: {
      'ofensiva': [
        'Explosão Mental', 'Telecinese Destrutiva', 'Confusão Psíquica', 'Trauma Mental',
        'Sobrecarga Neural', 'Implosão Cerebral', 'Distorção da Realidade', 'Pesadelo Psíquico',
        'Fragmentação Mental', 'Colapso Psicológico', 'Devastação Telepática', 'Aniquilação Mental'
      ],
      'suporte': [
        'Telepatia Curativa', 'Proteção Mental', 'Clarividência', 'Vigor Psíquico',
        'Regeneração Neural', 'Força de Vontade', 'Escudo Telepático', 'Harmonia Mental',
        'Concentração Suprema', 'Intuição Aguçada', 'Percepção Extra-sensorial', 'Equilíbrio Psíquico'
      ]
    },
    Tipo.magico: {
      'ofensiva': [
        'Míssil Mágico', 'Explosão Arcana', 'Lâmina Encantada', 'Devastação Mágica',
        'Ruptura Mística', 'Aniquilação Elemental', 'Pulso Encantado', 'Magia Destrutiva',
        'Encantamento Letal', 'Feitiço Mortal', 'Hexágono Destruidor', 'Conjuração Fatal'
      ],
      'suporte': [
        'Encantamento Protetor', 'Benção Mágica', 'Regeneração Arcana', 'Poder Mágico',
        'Proteção Encantada', 'Vigor Místico', 'Escudo Arcano', 'Força Mágica',
        'Essência Encantada', 'Harmonia Mística', 'Sabedoria Arcana', 'Transcendência Mágica'
      ]
    },
    Tipo.tecnologia: {
      'ofensiva': [
        'Laser Destrutivo', 'Sobrecarga Elétrica', 'Pulso Eletromagnético', 'Míssil Guiado',
        'Explosão Quântica', 'Raio Ionizante', 'Desintegração Digital', 'Vírus Cibernético',
        'Hackeamento Neural', 'Plasma Corrosivo', 'Nano-devastação', 'Colapso Sistêmico'
      ],
      'suporte': [
        'Nanobots Curativos', 'Proteção Cibernética', 'Regeneração Digital', 'Upgrade Sistêmico',
        'Escudo Energético', 'Otimização Neural', 'Força Robótica', 'Vigor Tecnológico',
        'Resistência Digital', 'Evolução Cibernética', 'Harmonia Sistêmica', 'Transcendência Digital'
      ]
    },
    Tipo.normal: {
      'ofensiva': [
        'Ataque Básico', 'Golpe Simples', 'Investida Comum', 'Pancada Direta',
        'Soco Poderoso', 'Chute Devastador', 'Impacto Brutal', 'Força Bruta',
        'Ataque Direto', 'Golpe Certeiro', 'Investida Feroz', 'Pancada Pesada'
      ],
      'suporte': [
        'Resistência Natural', 'Vigor Comum', 'Força Básica', 'Proteção Simples',
        'Regeneração Natural', 'Vitalidade Comum', 'Resistência Básica', 'Força Vital',
        'Energia Natural', 'Equilíbrio Básico', 'Harmonia Natural', 'Essência Pura'
      ]
    },
    Tipo.desconhecido: {
      'ofensiva': [
        'Força Misteriosa', 'Ataque Enigmático', 'Poder Oculto', 'Devastação Inexplicável',
        'Fenômeno Destrutivo', 'Energia Desconhecida', 'Manifestação Estranha', 'Anomalia Letal',
        'Distorção Inexplicável', 'Caos Primordial', 'Poder Ancestral', 'Força Primitiva'
      ],
      'suporte': [
        'Proteção Misteriosa', 'Vigor Desconhecido', 'Força Oculta', 'Regeneração Enigmática',
        'Resistência Inexplicável', 'Energia Primitiva', 'Poder Ancestral', 'Harmonia Primordial',
        'Essência Misteriosa', 'Vitalidade Oculta', 'Transcendência Desconhecida', 'Força Primeva'
      ]
    }
  };

  /// Gera um nome único para uma habilidade baseado no tipo e efeito
  static String gerarNome(Tipo tipoElemental, EfeitoHabilidade efeito) {
    final categoria = efeito.isSuporte ? 'suporte' : 'ofensiva';
    final nomesDisponiveis = _nomesHabilidades[tipoElemental]?[categoria] ?? 
                            _nomesHabilidades[Tipo.normal]![categoria]!;
    
    return nomesDisponiveis[_random.nextInt(nomesDisponiveis.length)];
  }

  /// Gera uma descrição temática para a habilidade
  static String gerarDescricao(String nome, Tipo tipoElemental, EfeitoHabilidade efeito, int valor) {
    final Map<EfeitoHabilidade, List<String>> descricoesPorEfeito = {
      EfeitoHabilidade.danoDirecto: [
        'Causa $valor pontos de dano direto ao oponente com poder $tipoElemental',
        'Desencadeia uma força $tipoElemental que inflige $valor de dano',
        'Libera energia $tipoElemental causando $valor pontos de dano devastador',
        'Invoca o poder $tipoElemental para causar $valor de dano mortal'
      ],
      EfeitoHabilidade.aumentarVida: [
        'Aumenta temporariamente a vida máxima em $valor pontos durante a batalha com energia $tipoElemental',
        'Fortalece o corpo com poder $tipoElemental, aumentando a vida em $valor (apenas na batalha)',
        'Canaliza essência $tipoElemental para aumentar temporariamente a vitalidade em $valor pontos',
        'Absorve energia $tipoElemental para fortalecer a vida em $valor durante o combate'
      ],
      EfeitoHabilidade.aumentarEnergia: [
        'Aumenta temporariamente a energia máxima em $valor pontos durante a batalha através do poder $tipoElemental',
        'Expande as reservas de energia em $valor usando força $tipoElemental (apenas no combate)',
        'Canaliza essência $tipoElemental para aumentar temporariamente energia em $valor pontos',
        'Absorve poder $tipoElemental para fortalecer a energia em $valor durante a batalha'
      ],
      EfeitoHabilidade.aumentarAgilidade: [
        'Aumenta permanentemente a agilidade em $valor pontos com velocidade $tipoElemental',
        'Acelera os movimentos em $valor usando poder $tipoElemental',
        'Canaliza energia $tipoElemental para aumentar agilidade em $valor pontos',
        'Absorve essência $tipoElemental para melhorar velocidade em $valor'
      ],
      EfeitoHabilidade.aumentarAtaque: [
        'Aumenta permanentemente o poder de ataque em $valor com força $tipoElemental',
        'Fortalece os ataques em $valor usando energia $tipoElemental',
        'Canaliza poder $tipoElemental para aumentar ataque em $valor pontos',
        'Absorve força $tipoElemental para fortalecer ataques em $valor'
      ],
      EfeitoHabilidade.aumentarDefesa: [
        'Aumenta permanentemente a defesa em $valor pontos com proteção $tipoElemental',
        'Fortalece as defesas em $valor usando escudo $tipoElemental',
        'Canaliza resistência $tipoElemental para aumentar defesa em $valor pontos',
        'Absorve proteção $tipoElemental para fortalecer defesas em $valor'
      ],
      EfeitoHabilidade.curarVida: [
        'Recupera $valor pontos de vida instantaneamente usando energia curativa $tipoElemental',
        'Regenera $valor de vida através do poder restaurador $tipoElemental',
        'Canaliza essência curativa $tipoElemental para recuperar $valor de vida',
        'Absorve energia vital $tipoElemental para curar $valor pontos de vida'
      ]
    };

    final descricoesPossibles = descricoesPorEfeito[efeito] ?? [
      'Manifesta o poder $tipoElemental com intensidade $valor'
    ];

    String descricao = descricoesPossibles[_random.nextInt(descricoesPossibles.length)];
    
    // Substitui o placeholder do tipo pelo nome adequado
    return descricao.replaceAll('\$tipoElemental', tipoElemental.displayName.toLowerCase());
  }
}
