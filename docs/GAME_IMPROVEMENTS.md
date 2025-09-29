# 🎮 TECHTERRA - IDEIAS DE MELHORIAS DE GAMEPLAY

> **Documento de Design**: Sugestões de melhorias para o sistema de aventura do TechTerra
>
> **Data de Criação**: 2025-09-29
>
> **Status**: Em análise para implementação futura

---

## 📋 ÍNDICE

1. [Progressão & Recompensas](#-progressão--recompensas)
2. [Mecânicas de Combate](#️-mecânicas-de-combate)
3. [Exploração & Mapa](#️-exploração--mapa)
4. [Itens & Equipamentos](#-itens--equipamentos)
5. [Loja & Economia](#-loja--economia)
6. [Social & Multiplayer](#-social--multiplayer)
7. [Visual & Polimento](#-visual--polimento)
8. [Mecânicas Avançadas](#-mecânicas-avançadas)
9. [Audio & Feedback](#-audio--feedback)
10. [Qualidade de Vida](#-qualidade-de-vida)
11. [Eventos & Sazonalidade](#-eventos--sazonalidade)
12. [Endgame & Longevidade](#-endgame--longevidade)
13. [Matriz de Priorização](#-matriz-de-priorização)

---

## 📊 PROGRESSÃO & RECOMPENSAS

### 💡 Ideia #1: Sistema de Missões Diárias/Semanais

**Descrição:**
Sistema de objetivos diários e semanais que incentivam o jogador a retornar ao jogo regularmente.

**Mecânica:**
- **Missões Diárias** (3 por dia):
  - "Derrote 3 monstros elétricos"
  - "Vença uma batalha sem perder HP"
  - "Use apenas habilidades de suporte em 2 batalhas"
  - Reset às 00:00 (horário de Brasília)

- **Missões Semanais** (5 por semana):
  - "Alcance o tier 15"
  - "Derrote 5 monstros elite"
  - "Acumule 100 de score em uma única run"
  - Reset toda segunda-feira

**Recompensas:**
- Missões diárias: 10-20 score, 1 refresh extra, itens comuns
- Missões semanais: 50-100 score, item raro garantido, monstro nostálgico

**UI/UX:**
- Badge de notificação no menu principal
- Tela dedicada de missões com barra de progresso visual
- Animação de recompensa ao completar

**Impacto:**
- ✅ Aumenta retenção de jogadores
- ✅ Diversifica objetivos além de "chegar ao tier X"
- ✅ Incentiva experimentação com diferentes tipos/estratégias

**Complexidade de Implementação:** 🟢 Baixa-Média

---

### 💡 Ideia #2: Sistema de Conquistas (Achievements)

**Descrição:**
Sistema de objetivos de longo prazo que recompensa feitos especiais dos jogadores.

**Categorias:**

**Conquistas de Combate:**
- "Primeira Vitória" - Vença sua primeira batalha
- "Guerreiro Imortal" - Vença 100 batalhas consecutivas
- "Assassino de Elite" - Derrote 50 monstros elite
- "Sobrevivente" - Vença uma batalha com 1 HP restante
- "Dominador" - Vença sem usar itens

**Conquistas de Coleção:**
- "Colecionador Iniciante" - Desbloqueie 5 monstros nostálgicos
- "Mestre Colecionador" - Desbloqueie todos os 30 nostálgicos
- "Caçador de Raros" - Capture 10 monstros raros
- "Lendário" - Obtenha um item lendário

**Conquistas de Progresso:**
- "Explorador" - Chegue ao tier 25
- "Veterano" - Chegue ao tier 50
- "Lenda Viva" - Chegue ao tier 100
- "Milionário" - Acumule 1.000.000 de score total (ao longo de todas as runs)

**Conquistas Especiais:**
- "Speedrunner" - Complete tier 1-10 em menos de 30 minutos
- "Perfeccionista" - Complete um tier inteiro sem perder uma batalha
- "Sortudo" - Obtenha 3 itens lendários em drops seguidos

**Recompensas:**
- Títulos exclusivos ("Mestre dos Dragões", "Guardião da Floresta")
- Badges visuais no perfil
- Bordas especiais para monstros favoritos
- Efeitos visuais exclusivos (auras, partículas)
- Score bônus para conquistas difíceis

**UI/UX:**
- Tela de conquistas com categorias
- Barra de progresso para cada conquista
- Notificação pop-up ao desbloquear
- Showcase de conquistas no perfil

**Impacto:**
- ✅ Objetivos de longo prazo mantêm jogadores engajados
- ✅ Sensação de progressão além do tier
- ✅ Status social (mostrar conquistas raras)

**Complexidade de Implementação:** 🟡 Média

---

### 💡 Ideia #3: Sistema de Streaks (Sequências)

**Descrição:**
Bonificações progressivas por vitórias consecutivas ou dias jogados.

**Mecânicas:**

**Streak de Vitórias:**
- Cada vitória consecutiva aumenta multiplicador de score
- Multiplicadores: +5%, +10%, +15%, +20%, +25% (máximo)
- Quebra ao perder uma batalha ou mudar de run
- Visual: Número flamejante mostrando streak atual

**Streak de Dias:**
- Bônus acumulativo por jogar dias consecutivos
- Dia 1: +0%
- Dia 3: +5% XP
- Dia 7: +10% XP + 1 refresh extra
- Dia 14: +15% XP + chance de drop +5%
- Dia 30: +20% XP + item raro garantido ao logar
- Quebra se pular um dia

**Proteção de Streak:**
- Item especial "Talismã da Continuidade" (comprado na loja)
- Salva streak de 1 derrota/dia perdido
- Custo: 100 score

**UI/UX:**
- Contador visual de streak no header
- Efeito de fogo/chamas ao redor do número em streaks altas
- Notificação de "Streak em risco!" se próximo de quebrar
- Histórico de melhor streak pessoal

**Impacto:**
- ✅ Incentiva hábito diário
- ✅ Tensão dramática em batalhas (não quer perder streak)
- ✅ Recompensa consistência

**Complexidade de Implementação:** 🟢 Baixa

---

### 💡 Ideia #4: Passe de Batalha Sazonal

**Descrição:**
Sistema de progressão paralelo baseado em temporadas, com recompensas exclusivas.

**Estrutura:**
- 50 níveis por temporada
- Duração: 90 dias (3 meses)
- XP do passe: ganho por completar batalhas, missões e desafios
- Duas trilhas: Gratuita e Premium

**Recompensas Gratuitas (Todos os Jogadores):**
- Score bônus (200, 500, 1000 nos níveis 10, 25, 50)
- Itens comuns e raros
- Refreshs extras
- Fragmentos de crafting

**Recompensas Premium (Opcional):**
- Monstros exclusivos temáticos
- Skins especiais
- Efeitos visuais (auras, trails)
- Titles exclusivos
- Double XP tokens

**Desafios Semanais:**
- 10 desafios específicos por semana
- Completar desafios acelera progressão (XP extra)
- Exemplo: "Derrote 20 monstros de fogo", "Alcance tier 30"

**Temas Sazonais:**
| Temporada | Tema | Monstro Exclusivo | Visual |
|-----------|------|-------------------|--------|
| 1 | Dragões Antigos | Dragão Temporal | Efeito de relógio |
| 2 | Espíritos da Floresta | Guardião Verde | Folhas flutuantes |
| 3 | Senhores do Gelo | Fênix Congelada | Cristais de gelo |
| 4 | Profundezas Marinhas | Leviatã | Bolhas aquáticas |

**Impacto:**
- ✅ Monetização opcional (se implementar compras)
- ✅ Conteúdo novo a cada temporada
- ✅ Recompensas exclusivas aumentam FOMO positivo
- ✅ Objetivos claros de progressão

**Complexidade de Implementação:** 🔴 Alta

---

## ⚔️ MECÂNICAS DE COMBATE

### 💡 Ideia #5: Sistema de Combos Elementais

**Descrição:**
Sinergias entre tipos elementais no time para criar estratégias de composição.

**Tipos de Combos:**

**Combo Mono-Tipo (Pureza Elemental):**
- 3 monstros do mesmo tipo no time
- Bônus: +15% dano daquele tipo
- Efeito visual: Aura colorida unificada ao redor do time

**Combo Dual-Type (Harmonia):**
- 2 monstros de um tipo + 1 de outro tipo complementar
- Combinações especiais:
  - Fogo + Elétrico = "Plasma" → +10% crítico
  - Água + Gelo = "Congelamento" → +10% defesa
  - Planta + Terra = "Raízes" → +15% vida
  - Vento + Voador = "Tempestade" → +15% agilidade
  - Luz + Psíquico = "Iluminação" → +10% energia
  - Trevas + Fantasma = "Sombra" → +10% esquiva

**Combo Rainbow (Diversidade):**
- 3 monstros de tipos completamente diferentes
- Bônus: +5% em todos os atributos
- Sem fraquezas óbvias contra nenhum tipo específico

**Combo Anti (Oposição):**
- Tipos naturalmente opostos no mesmo time
- Fogo + Água, Luz + Trevas, etc
- Bônus: +10% resistência contra ambos os tipos
- Penalidade: -5% sinergia entre os monstros (menos efetivo)

**UI/UX:**
- Indicador visual dos combos ativos (ícones na tela de batalha)
- Preview de combos ao montar time
- Tooltip explicando cada combo
- Partículas especiais quando combo está ativo

**Mecânica de Ativação:**
- Combos são calculados no início da batalha
- Permanecem ativos durante toda a batalha
- Não podem ser mudados mid-battle

**Impacto:**
- ✅ Adiciona camada estratégica na montagem de time
- ✅ Incentiva experimentação com diferentes composições
- ✅ Torna escolha de monstros mais significativa
- ✅ Aumenta replay value (testar combos diferentes)

**Complexidade de Implementação:** 🟡 Média

---

### 💡 Ideia #6: Sistema de Críticos e Esquivas

**Descrição:**
Adiciona elementos de RNG estratégico baseado em atributos.

**Mecânica de Crítico:**

**Chance de Crítico:**
- Base: 5%
- Bônus por agilidade: Cada 10 pontos de AGI = +1% chance
- Exemplo: Monstro com 50 AGI = 5% + 5% = 10% chance total
- Máximo: 50% de chance

**Dano Crítico:**
- Multiplicador: 1.5x o dano normal
- Críticos ignoram 25% da defesa do alvo
- Não pode ser esquivado

**Visual:**
- Efeito de raio dourado no impacto
- Número do dano em fonte maior e dourada
- Shake da tela
- Partículas brilhantes
- Som especial

**Mecânica de Esquiva:**

**Chance de Esquiva:**
- Baseado em diferença de agilidade
- Fórmula: `(AGI_defensor - AGI_atacante) / 20`
- Mínimo: 0%, Máximo: 30%
- Exemplo: Defensor 60 AGI vs Atacante 20 AGI = (60-20)/20 = 2% esquiva

**Efeito de Esquiva:**
- Ataque não causa dano algum
- Não consome energia da habilidade (falha completa)
- Contador de esquivas na batalha

**Visual:**
- Efeito de blur/ghost no defensor
- Som de "whoosh"
- Texto "MISS!" em vermelho
- Defensor fica semi-transparente por 0.5s

**Interação Crítico x Esquiva:**
- Críticos NÃO podem ser esquivados (sempre acertam)
- Isso torna agilidade útil tanto ofensiva quanto defensivamente

**Habilidades Especiais:**
- Nova habilidade: "Foco de Batalha" - +15% chance de crítico por 3 turnos
- Nova habilidade: "Reflexos Aprimorados" - +10% esquiva por 3 turnos

**UI/UX:**
- Estatísticas de batalha mostram:
  - Taxa de crítico: X%
  - Taxa de esquiva: Y%
  - Total de críticos: Z
  - Total de esquivas: W
- Tooltip mostrando chances antes de atacar

**Impacto:**
- ✅ Torna agilidade mais valiosa
- ✅ Adiciona excitação (momentos "wow" com críticos)
- ✅ Cria contrajogo (alta AGI vs alta AGI)
- ✅ Permite builds especializadas (crit builds, dodge builds)

**Complexidade de Implementação:** 🟢 Baixa-Média

---

### 💡 Ideia #7: Sistema de Status/Efeitos

**Descrição:**
Efeitos de status que adicionam profundidade tática às batalhas.

**Tipos de Status:**

**1. Queimadura (Status de Fogo)** 🔥
- **Aplicação:** 20% chance em ataques de fogo
- **Efeito:** Dano ao longo do tempo
- **Valor:** 5% da vida máxima por turno
- **Duração:** 3 turnos
- **Visual:** Pequenas chamas ao redor do monstro
- **Cura:** Ataques de água removem (50% chance)

**2. Congelamento (Status de Gelo)** ❄️
- **Aplicação:** 15% chance em ataques de gelo
- **Efeito:** Pula o próximo turno completamente
- **Duração:** 1 turno (perde o turno seguinte)
- **Visual:** Monstro coberto de gelo azul
- **Cura:** Ataques de fogo removem (100% chance)
- **Imunidade:** Monstros de gelo são imunes

**3. Paralisia (Status Elétrico)** ⚡
- **Aplicação:** 25% chance em ataques elétricos
- **Efeito:** 50% chance de não conseguir atacar no turno
- **Duração:** 2 turnos
- **Visual:** Raios amarelos piscando
- **Cura:** Se dissipa sozinho após duração
- **Imunidade:** Monstros elétricos são imunes

**4. Envenenamento (Status Venenoso)** ☠️
- **Aplicação:** 30% chance em ataques venenosos
- **Efeito:** Dano crescente por turno
- **Valor:** 5 HP (turno 1) → 10 HP (turno 2) → 15 HP (turno 3)
- **Duração:** 3 turnos
- **Visual:** Bolhas roxas ao redor, monstro fica esverdeado
- **Cura:** Item especial "Antídoto" (nova adição à loja)

**5. Regeneração (Status de Planta)** 🌿
- **Aplicação:** Habilidades de cura/suporte de planta
- **Efeito:** Cura pequena por turno
- **Valor:** 10 HP por turno
- **Duração:** 5 turnos
- **Visual:** Folhas verdes flutuando, brilho verde
- **Interação:** Queimadura cancela regeneração

**6. Confusão (Status Psíquico)** 🌀
- **Aplicação:** 10% chance em ataques psíquicos
- **Efeito:** Atacante pode se atingir (30% chance por turno)
- **Duração:** 2 turnos
- **Visual:** Estrelas girando ao redor da cabeça
- **Dano auto-infligido:** 50% do dano do ataque

**7. Sangramento (Status de Ataque Físico)** 🩸
- **Aplicação:** Críticos têm 25% chance de causar sangramento
- **Efeito:** Dano fixo por turno
- **Valor:** 8 HP por turno
- **Duração:** 4 turnos
- **Visual:** Gotas vermelhas caindo do monstro

**8. Blindagem (Status Defensivo)** 🛡️
- **Aplicação:** Habilidades de defesa especiais
- **Efeito:** +50% defesa temporária
- **Duração:** 2 turnos
- **Visual:** Escudo brilhante azul ao redor

**Mecânicas Adicionais:**

**Resistência a Status:**
- Cada tipo tem imunidades naturais:
  - Fogo imune a queimadura
  - Gelo imune a congelamento
  - Elétrico imune a paralisia
  - Veneno imune a envenenamento
  - Fantasma imune a confusão

**Combo de Status:**
- Múltiplos status podem estar ativos simultaneamente
- Máximo: 2 status negativos + 1 positivo por vez

**Limpeza de Status:**
- Nova habilidade: "Purificação" - Remove todos os status negativos
- Novo item: "Elixir Restaurador" - Remove 1 status aleatório

**UI/UX:**
- Ícones de status ao lado da barra de vida
- Tooltip ao passar mouse mostrando detalhes
- Contador de turnos restantes
- Animação de aplicação (partículas do tipo)
- Log de batalha registra aplicação/remoção de status

**Impacto:**
- ✅ Adiciona profundidade estratégica enorme
- ✅ Torna tipos específicos mais únicos
- ✅ Cria decision-making (aplicar status vs dano direto)
- ✅ Permite builds de "status stacker"

**Complexidade de Implementação:** 🔴 Alta

---

### 💡 Ideia #8: Sistema de Posicionamento/Formação

**Descrição:**
Posições táticas que afetam comportamento e stats dos monstros em batalha.

**Três Posições:**

**Posição: FRENTE (Tank/Defensor)** 🛡️
- **Modificadores:**
  - +15% defesa
  - -10% agilidade
  - +20% chance de ser alvo de ataques
- **Ideal para:** Monstros com alta vida e defesa
- **Visual:** Monstro aparece maior, mais à frente na tela

**Posição: MEIO (Balanceado)** ⚖️
- **Modificadores:**
  - Sem bônus ou penalidades
  - Chance neutra de ser alvo
- **Ideal para:** Monstros versáteis, suportes
- **Visual:** Monstro aparece no centro

**Posição: TRÁS (DPS/Atacante)** ⚔️
- **Modificadores:**
  - +15% ataque
  - -15% defesa
  - -30% chance de ser alvo de ataques
- **Ideal para:** Monstros com alto ataque, baixa defesa
- **Visual:** Monstro aparece menor, mais ao fundo

**Mecânica de Targeting:**

**Sistema de Prioridade de Alvo:**
1. Inimigos priorizam atacar posição FRENTE (60% chance)
2. Se frente está morto/incapaz: atacam MEIO (70% chance) ou TRÁS (30%)
3. Se meio está morto: atacam TRÁS (100%)
4. Habilidades de área (AOE) ignoram posicionamento

**Habilidades de Reposicionamento:**
- Nova habilidade: "Trocar Posições" - Swap entre dois monstros
- Nova habilidade: "Recuar" - Move um monstro para trás por 2 turnos

**Formações Especiais:**

**Formação "Muro Defensivo":**
- 2 na frente, 1 atrás
- Bônus: +10% defesa para todos

**Formação "Lança Ofensiva":**
- 1 na frente, 2 atrás
- Bônus: +10% ataque para todos

**Formação "Equilibrada":**
- 1 em cada posição
- Bônus: +5% em todos os atributos

**IA Inimiga:**
- Inimigos também usam formações
- Elite sempre na frente (tanque)
- Monstros fracos atrás
- Boss battles: formações especiais

**UI/UX:**
- Tela de seleção de formação antes da batalha
- Drag and drop para posicionar monstros
- Preview dos bônus ao posicionar
- Indicadores visuais claros de posição durante batalha
- Mini-mapa tático mostrando formações

**Impacto:**
- ✅ Adiciona profundidade tática pré-batalha
- ✅ Torna composição de time mais estratégica
- ✅ Cria papel específico para cada monstro (tank, DPS, support)
- ✅ Permite otimização baseada em stats individuais

**Complexidade de Implementação:** 🟡 Média-Alta

---

### 💡 Ideia #9: Sistema de Energia Ativo

**Descrição:**
Ativar o sistema de energia que já existe no código mas está desabilitado.

**Mecânica Atual (Desativada):**
- Energia não é consumida em batalhas
- Restaura para 100% ao final da batalha

**Nova Mecânica Proposta:**

**Consumo de Energia:**
- Habilidades custam energia (já definido: 1-4 pontos)
- Se energia insuficiente: só pode usar ataque básico
- Ataque básico não consome energia

**Regeneração de Energia:**
- +5 energia no início de cada turno próprio
- +3 energia ao receber dano (max 10 por turno)
- +10 energia ao derrotar um inimigo

**Gestão Estratégica:**
- Decisão: usar habilidade poderosa agora ou guardar energia?
- Combos: sequenciar habilidades de forma eficiente
- Suporte: habilidades de energia se tornam mais valiosas

**Novas Habilidades de Energia:**
- "Meditação" - +15 energia instantânea (custo 0, só pode usar 1x por batalha)
- "Drenar Energia" - Causa dano E rouba 50% do custo da habilidade do alvo
- "Sobrecarga" - Causa dano massivo mas consome TODA a energia

**Itens de Energia:**
- Novo tipo de item: "Talismã de Energia" - +20 energia máxima
- Nova compra na loja: "Poção de Energia" - Restaura 30 energia
- Custo: 1.5 × tier efetivo (entre cura e aposta)

**Balanceamento:**
- Energia inicial: baseada no atributo energia (20-40)
- Regeneração: +5 por turno (pode chegar a 10+ turnos de energia completa)
- Habilidades caras (4 de custo) exigem 2-3 turnos de espera

**UI/UX:**
- Barra de energia em cor diferente (azul) abaixo da vida
- Números mostrando energia atual/máxima
- Preview do custo da habilidade ao selecionar
- Aviso visual quando energia insuficiente (habilidades em cinza)
- Animação de pulso ao regenerar energia

**Impacto:**
- ✅ Adiciona resource management às batalhas
- ✅ Torna atributo "energia" significativo
- ✅ Cria momento de decisão (quando gastar energia?)
- ✅ Diferencia monstros (alguns regeneram mais rápido)
- ✅ Batalhas ficam mais dinâmicas

**Complexidade de Implementação:** 🟢 Baixa (código já existe, só ativar)

---

## 🗺️ EXPLORAÇÃO & MAPA

### 💡 Ideia #10: Eventos Aleatórios no Mapa

**Descrição:**
Pontos de interesse especiais que aparecem aleatoriamente no mapa, adicionando variedade.

**Tipos de Eventos:**

**1. Santuário de Cura** ⛩️
- **Frequência:** 15% de chance por andar
- **Posição:** Centro do mapa
- **Efeito:** Restaura 50% da vida de TODOS os monstros
- **Custo:** Gratuito (1 uso por andar)
- **Visual:** Torii japonês brilhante, partículas verdes
- **Lore:** "Um local sagrado onde energias vitais se concentram"

**2. Comerciante Misterioso** 🎭
- **Frequência:** 10% de chance por andar
- **Posição:** Canto superior direito
- **Ofertas:** 2 itens aleatórios de raridade garantida (Épico ou Lendário)
- **Preço:** 25% desconto do preço normal
- **Estoque:** Muda a cada visita
- **Visual:** NPC encapuzado, barraca improvisada
- **Diálogo:** "Psiu... tenho itens raros... preços especiais só hoje..."

**3. Batalha Dupla** ⚔️⚔️
- **Frequência:** 8% de chance por andar
- **Posição:** Substitui 1 dos monstros normais
- **Mecânica:** Enfrenta 2 monstros normais SIMULTANEAMENTE
- **Dificuldade:** Monstros têm -20% stats cada (para balancear)
- **Recompensa:** Score × 2, drop × 2
- **Visual:** Dois ícones de monstro sobrepostos, aura vermelha

**4. Portal de Treinamento** 🌀
- **Frequência:** 12% de chance por andar
- **Posição:** Lateral esquerda
- **Mecânica:** Batalha de treino sem risco
  - Se ganhar: XP normal
  - Se perder: Sem penalidade (monstro inimigo volta à vida)
- **Limitação:** Pode usar 2 vezes por andar
- **Visual:** Portal azul girando, partículas cintilantes
- **Ideal para:** Testar estratégias novas, farmar XP sem risco

**5. Baú do Tesouro** 📦
- **Frequência:** 5% de chance por andar
- **Posição:** Aleatória
- **Conteúdo:**
  - 70%: Item aleatório
  - 20%: Score (10-30)
  - 10%: Refresh extra
- **Custo:** Gratuito (só abrir)
- **Visual:** Baú dourado brilhante, efeito de estrelas
- **Animação:** Baú abre com explosão de confete

**6. Fonte da Fortuna** 🪙
- **Frequência:** 7% de chance por andar
- **Posição:** Centro-inferior
- **Mecânica:** Apostar score para multiplicar
  - Joga uma moeda (50/50)
  - Vitória: Dobra o score apostado
  - Derrota: Perde o score apostado
- **Limite:** Pode apostar até 50% do score atual
- **Visual:** Fonte de pedra, moeda dourada girando

**7. Biblioteca Arcana** 📚
- **Frequência:** 6% de chance por andar (tier 10+)
- **Posição:** Canto superior esquerdo
- **Efeito:** Escolha 1 de 3 buffs temporários:
  - "Conhecimento Proibido": +20% ataque por 3 batalhas
  - "Sabedoria Antiga": +20% defesa por 3 batalhas
  - "Iluminação": +30% XP por 3 batalhas
- **Custo:** 10 score
- **Visual:** Livros flutuantes, símbolos místicos

**8. Altar do Sacrifício** 🗿
- **Frequência:** 4% de chance por andar (tier 15+)
- **Posição:** Centro-superior
- **Mecânica:** Sacrificar 1 item para obter benefício:
  - Item Inferior: +10 score
  - Item Normal: +20 score + fragmento comum
  - Item Raro: +40 score + fragmento raro
  - Item Épico: +80 score + fragmento épico
  - Item Lendário: +150 score + fragmento lendário + escolha 1 buff permanente
- **Visual:** Altar de pedra negro, chamas roxas

**Lógica de Aparição:**
- Máximo 2 eventos por andar
- Eventos não substituem monstros obrigatórios
- Aparições aumentam levemente em tiers altos
- Alguns eventos só aparecem em tiers específicos

**UI/UX:**
- Ícones diferenciados para cada evento
- Animação de "descoberta" ao revelar
- Som especial de "evento raro" ao aparecer
- Descrição do evento ao clicar
- Confirmação antes de interagir

**Impacto:**
- ✅ Aumenta replay value (cada andar é diferente)
- ✅ Adiciona momentos de "sorte" e surpresa
- ✅ Permite recuperação em runs difíceis (santuário)
- ✅ Cria risco/recompensa (fonte da fortuna, altar)

**Complexidade de Implementação:** 🟡 Média

---

### 💡 Ideia #11: Minibosses Especiais

**Descrição:**
Chefes temáticos que aparecem a cada 5 tiers, com mecânicas únicas e recompensas especiais.

**Estrutura:**
- Aparece nos tiers: 5, 10, 15, 20, 25, 30, 35, 40, 45, 50
- Substitui o monstro elite do andar
- Batalha obrigatória para avançar
- Mecânicas únicas por boss

**Galeria de Minibosses:**

**TIER 5: Guardião da Floresta** 🌳
- **Tipo:** Planta/Terra
- **Mecânica Especial:**
  - Regenera 5% da vida máxima por turno
  - A cada 3 turnos, invoca "Espinhos" que causam dano reflexivo (20% do dano recebido volta no atacante)
- **Stats:** 120% dos stats normais de um elite tier 5
- **Visual:** Ent gigante, folhas brilhantes, raízes no chão
- **Recompensa:**
  - Item Épico garantido (tipo planta/terra)
  - 3 fragmentos verdes
  - Título: "Protetor da Floresta"
- **Lore:** "Guardião ancestral que protege as florestas sagradas há milênios"

**TIER 10: Senhor dos Dragões** 🐉
- **Tipo:** Dragão/Fogo
- **Mecânica Especial:**
  - Ataca DUAS vezes por turno
  - A cada 4 turnos, usa "Sopro Flamejante" (ataque em área que atinge todo o time, 150% de dano)
- **Stats:** 130% dos stats de elite tier 10
- **Fases:**
  - Fase 1 (100-50% vida): Ataques normais
  - Fase 2 (<50% vida): Entra em "Fúria" (+30% ataque, +20% velocidade)
- **Visual:** Dragão vermelho com asas, chamas constantes, olhos brilhando
- **Recompensa:**
  - Item Lendário com 50% chance
  - 5 fragmentos de fogo
  - Escama de Dragão (item especial de crafting)
  - Título: "Domador de Dragões"

**TIER 15: Espírito Ancestral** 👻
- **Tipo:** Fantasma/Psíquico
- **Mecânica Especial:**
  - Invoca 2 "Espíritos Menores" (mini-monstros com 30% da vida do boss)
  - Espíritos menores ressuscitam 1x se o boss ainda estiver vivo
  - Boss é IMUNE a dano enquanto espíritos estão vivos
- **Stats:** 110% dos stats de elite tier 15 (compensado pela invocação)
- **Visual:** Espírito translúcido azul, correntes etéreas, aura sombria
- **Recompensa:**
  - Item Épico garantido (tipo fantasma/psíquico)
  - Fragmento Espectral (raro)
  - Habilidade especial: "Invocar Aliado"
  - Título: "Médium Espiritual"

**TIER 20: Colosso de Pedra** 🗿
- **Tipo:** Pedra/Terra
- **Mecânica Especial:**
  - EXTREMA defesa (+100% defesa)
  - Imune a efeitos de status
  - A cada 5 turnos, usa "Terremoto" (stun em todo o time por 1 turno)
- **Stats:** 150% dos stats de elite tier 20
- **Fraqueza:** Ataques críticos causam 2.5x dano (ao invés de 1.5x)
- **Visual:** Golem gigante de pedra, runas brilhando, rachaduras pelo corpo
- **Recompensa:**
  - 2 Itens Épicos
  - Núcleo de Cristal (crafting lendário)
  - 10 fragmentos de pedra
  - Título: "Quebrador de Montanhas"

**TIER 25: Fênix Imortal** 🔥🐦
- **Tipo:** Fogo/Voador
- **Mecânica Especial:**
  - Ao ser derrotado pela primeira vez, REVIVE com 50% vida
  - Após reviver, todos os ataques causam queimadura
  - Pode esquivar ataques (25% chance)
- **Stats:** 135% dos stats de elite tier 25
- **Visual:** Pássaro de fogo majestoso, asas flamejantes, trilha de fogo
- **Recompensa:**
  - Pena de Fênix (item único que revive monstro 1x por run)
  - Item Lendário garantido
  - 8 fragmentos de fogo
  - Título: "Ressurgido das Cinzas"

**TIER 30: Kraken das Profundezas** 🐙
- **Tipo:** Água/Marinho
- **Mecânica Especial:**
  - Começa com 8 "Tentáculos" (HP separados)
  - Cada tentáculo ativo aumenta ataque em 10%
  - Ao destruir um tentáculo, kraken perde 10% ataque mas ganha 5% velocidade
  - Boss principal só pode ser atacado após destruir 4+ tentáculos
- **Stats:** 140% dos stats de elite tier 30
- **Visual:** Polvo gigante azul-escuro, tentáculos animados, bolhas
- **Recompensa:**
  - Tinta do Kraken (crafting)
  - 2 Itens Lendários
  - 12 fragmentos aquáticos
  - Título: "Senhor dos Mares"

**TIER 35: Lich Necromante** 💀
- **Tipo:** Trevas/Magia
- **Mecânica Especial:**
  - Ressuscita monstros derrotados anteriormente no andar (até 3x)
  - Monstros ressuscitados têm 40% vida
  - Drena 5 HP por turno de TODOS os monstros do jogador
  - Dreno cura o Lich
- **Stats:** 125% dos stats de elite tier 35
- **Visual:** Esqueleto com manto roxo, cajado brilhante, aura negra, crânios flutuando
- **Recompensa:**
  - Grimório Proibido (desbloqueia habilidade "Reviver")
  - Item Lendário tipo trevas
  - 15 fragmentos sombrios
  - Título: "Desafiador da Morte"

**TIER 40: Titã de Gelo** ❄️
- **Tipo:** Gelo/Pedra
- **Mecânica Especial:**
  - Começa a batalha com "Armadura de Gelo" (escudo de 500 HP)
  - Enquanto escudo ativo: imune a críticos e efeitos
  - Ao quebrar escudo: boss fica "Vulnerável" por 3 turnos (recebe +50% dano)
  - Escudo regenera após 8 turnos se quebrado
- **Stats:** 160% dos stats de elite tier 40
- **Visual:** Titã de gelo azul cristalino, névoa congelante, solo congelado
- **Recompensa:**
  - Coração de Gelo Eterno (item único)
  - 3 Itens Lendários
  - 20 fragmentos de gelo
  - Título: "Conquistador do Inverno"

**TIER 45: Wyrm Ancião** 🐲
- **Tipo:** Dragão/Trevas
- **Mecânica Especial:**
  - Muda de elemento a cada 3 turnos (fogo → água → elétrico → planta → loop)
  - Elemento atual determina tipo de ataques e fraquezas
  - "Sopro Primordial": Ataque devastador de 300% dano no elemento atual (cooldown 5 turnos)
- **Stats:** 170% dos stats de elite tier 45
- **Visual:** Dragão negro enorme, escamas multicoloridas, múltiplas cabeças
- **Recompensa:**
  - Escama Primordial (crafting ultimate)
  - 2 Itens Lendários escolhidos pelo jogador
  - 25 fragmentos multicoloridos
  - Título: "Lenda Viva"

**TIER 50: Deus Esquecido** ✨
- **Tipo:** Luz/Divino (novo tipo especial)
- **Mecânica Especial:**
  - **FASE 1** (100-66% vida):
    - Ataque padrão + habilidades aleatórias
  - **FASE 2** (66-33% vida):
    - Invoca "Guardiões Divinos" (2 monstros épicos)
    - Imune enquanto guardiões vivos
  - **FASE 3** (<33% vida):
    - "Ira Divina" ativa (ataque dobrado, velocidade +50%)
    - Cada ataque tem 15% chance de ser INSTANTÂNEO (ignora turnos)
- **Stats:** 200% dos stats de elite tier 50
- **Visual:** Entidade humanóide brilhante, auréola, asas de luz, arena transformada
- **Recompensa:**
  - **Essência Divina** (permite criar 1 item Mítico - nova raridade acima de Lendário)
  - **Monstro Exclusivo: "Avatar Divino"** (desbloqueado na coleção)
  - 50 fragmentos divinos
  - **Título: "Matador de Deuses"**
  - **Skin Especial: "Aura Divina"** (efeito visual permanente)

**Mecânicas Gerais de Miniboss:**

**Entrada Épica:**
- Cutscene de 5 segundos ao entrar na batalha
- Nome do boss aparece em letras douradas
- Música muda para tema épico
- Boss dá um rugido/grito característico

**Barra de Vida Especial:**
- Barra dourada ao invés de verde
- Indicadores de fases (marcadores em 75%, 50%, 25%)
- Número mostrando HP restante

**Drops Garantidos:**
- 100% chance de item épico ou superior
- Fragmentos especiais de crafting
- Possibilidade de item único/exclusivo

**Repeat Battles:**
- Após derrotar pela primeira vez: pode rebater o boss
- Custo: 50 score
- Recompensas reduzidas (50% normal)
- Aparece como ícone especial no mapa após limpar o tier

**Achievement por Boss:**
- Conquista por derrotar cada boss pela primeira vez
- Conquista especial: derrotar todos os 10 bosses
- Conquista ultimate: derrotar todos sem morrer

**Impacto:**
- ✅ Marcos memoráveis na progressão
- ✅ Testes de habilidade reais
- ✅ Recompensas premium motivam a derrotar
- ✅ Cria momentos "épicos" compartilháveis
- ✅ Adiciona variedade enorme ao gameplay

**Complexidade de Implementação:** 🔴 Muito Alta (mas alto retorno)

---

### 💡 Ideia #12: Sistema de Zonas/Biomas

**Descrição:**
Rotação de ambientes temáticos que mudam a cada 10 tiers, com mecânicas e bônus únicos.

**Ciclo de Biomas:**

**TIER 1-10: Floresta Verdejante** 🌲
- **Tema:** Floresta exuberante, vegetação densa
- **Monstros Comuns:** Planta, Inseto, Voador
- **Bônus de Bioma:**
  - Monstros tipo Planta: +10% em todos os stats
  - Chance de cura ao vencer batalha: 10 HP
- **Mecânica Especial:** "Raízes Profundas"
  - Monstros tipo Planta no time regeneram 2 HP por turno
- **Clima:** Chuva leve (efeito visual)
- **Evento Exclusivo:** Árvore Sagrada (cura 100% de vida, aparece 1x por bioma)
- **Visual:** Verde vibrante, árvores altas, luz solar filtrada

**TIER 11-20: Deserto Ardente** 🏜️
- **Tema:** Dunas infinitas, calor intenso
- **Monstros Comuns:** Fogo, Pedra, Terrestre
- **Bônus de Bioma:**
  - Monstros tipo Fogo: +15% ataque
  - Ataques de água: +20% efetividade (sede do deserto)
- **Mecânica Especial:** "Tempestade de Areia"
  - A cada 3 batalhas, tempestade reduz agilidade de todos em 15%
  - Pode usar "Tenda do Oásis" para evitar (comprar na loja por 10 score)
- **Clima:** Sol escaldante, ondas de calor visíveis
- **Evento Exclusivo:** Oásis Miragem (chance de item duplo ou ser ilusão)
- **Visual:** Amarelo/laranja, dunas, cactos, esqueletos de animais

**TIER 21-30: Oceano Profundo** 🌊
- **Tema:** Profundezas marinhas, pressão da água
- **Monstros Comuns:** Água, Marinho, Gelo
- **Bônus de Bioma:**
  - Monstros tipo Água: +12% defesa e vida
  - Ataques elétricos: +25% efetividade
- **Mecânica Especial:** "Correntes Marítimas"
  - Agilidade de todos flutua ±10% a cada turno (simula correntes)
  - Navegação requer "Bússola Mágica" para evitar se perder (comprar por 15 score)
- **Clima:** Ambiente subaquático, bolhas, luz azulada
- **Evento Exclusivo:** Naufrágio Antigo (tesouro com 3 itens lendários, raro)
- **Visual:** Azul escuro, corais, peixes no fundo, luz difusa

**TIER 31-40: Cordilheira Celeste** ⛰️
- **Tema:** Montanhas altíssimas, ar rarefeito
- **Monstros Comuns:** Pedra, Voador, Dragão
- **Bônus de Bioma:**
  - Monstros tipo Voador: +20% agilidade
  - Monstros tipo Pedra: +15% defesa
- **Mecânica Especial:** "Ar Rarefeito"
  - Energia regenera -2 por turno (fadiga da altitude)
  - Habilidades de energia custam +1 extra
  - Pode comprar "Máscara de Oxigênio" (nega efeito, 20 score)
- **Clima:** Vento forte, neve ocasional, nuvens baixas
- **Evento Exclusivo:** Pico Místico (meditação dá buff permanente de +5 em atributo escolhido)
- **Visual:** Cinza/branco, rochas, neve, céu azul claro

**TIER 41-50: Reino Celestial** ☁️
- **Tema:** Ilhas flutuantes, reino dos deuses
- **Monstros Comuns:** Luz, Voador, Divino, Dragão
- **Bônus de Bioma:**
  - Todos os monstros: +10% em todos os stats
  - Críticos: +5% chance adicional
- **Mecânica Especial:** "Bênção Celestial"
  - Cada vitória dá 1 "Ponto Divino"
  - 5 Pontos Divinos = 1 ressurreição automática (se morrer, revive com 50% vida)
- **Clima:** Auroras, raios de luz divina, sem gravidade aparente
- **Evento Exclusivo:** Templo dos Deuses (escolher 1 buff lendário permanente)
- **Visual:** Dourado/branco/azul claro, nuvens, construções flutuantes, luz radiante

**TIER 51+: Abismo Sombrio** 🕳️
- **Tema:** Dimensão das trevas, caos puro
- **Monstros Comuns:** Trevas, Fantasma, Dragão, Demônio
- **Bônus de Bioma:**
  - Monstros tipo Trevas: +15% em todos os stats
  - Todos os monstros têm +10% crítico
  - PERIGO: Monstros inimigos também ganham +10% em todos os stats
- **Mecânica Especial:** "Corrupção Sombria"
  - A cada 2 batalhas, 1 monstro aleatório perde 10% stats permanentemente (até sair do bioma)
  - Pode comprar "Amuleto da Pureza" (nega 1 corrupção, 30 score cada)
- **Clima:** Escuridão quase total, sombras animadas, raios roxos
- **Evento Exclusivo:** Portal do Caos (entra em boss rush de 5 bosses aleatórios, recompensa multiplicada ×5)
- **Visual:** Preto/roxo/vermelho escuro, fissuras dimensionais, ruínas corrompidas

**Mecânicas Gerais:**

**Transição de Bioma:**
- Cutscene de 10 segundos mostrando novo ambiente
- Notificação de bônus/mecânicas do bioma
- Música muda para tema do bioma
- Pode revisar info do bioma no menu

**Adaptação Estratégica:**
- Jogador precisa adaptar estratégia a cada bioma
- Diferentes tipos se tornam mais/menos viáveis
- Compras específicas na loja (itens anti-mecânica)

**Coleção de Bioma:**
- Cada bioma tem 5 monstros exclusivos
- Só podem ser encontrados naquele bioma
- Incentiva rejogar tiers antigos

**Conquistas por Bioma:**
- "Mestre da Floresta" - Complete tier 10 sem usar curas
- "Senhor do Deserto" - Sobreviva 10 tempestades de areia
- "Desbravador Oceânico" - Derrote Kraken
- "Escalador Supremo" - Alcance tier 40
- "Divino Ascendido" - Complete tier 50
- "Sobrevivente do Abismo" - Sobreviva 20 corrupções

**UI/UX:**
- Indicador de bioma atual no header
- Mini-mapa com tema do bioma
- Tooltip com bônus/mecânicas ao passar mouse
- Galeria de biomas desbloqueados

**Impacto:**
- ✅ Quebra monotonia visual
- ✅ Força adaptação estratégica
- ✅ Torna certos tipos mais relevantes em diferentes fases
- ✅ Cria senso de progressão (novos ambientes)
- ✅ Aumenta imersão (mundo vivo)

**Complexidade de Implementação:** 🟡 Média-Alta

---

### 💡 Ideia #13: Sistema de Exploração com Fog of War

**Descrição:**
Adiciona elemento de descoberta e incerteza ao mapa, exigindo escolhas estratégicas antes de revelar inimigos.

**Mecânica Principal:**

**Névoa de Guerra:**
- Ao entrar em um novo tier, TODO o mapa está coberto por névoa
- Monstros, eventos e Casa do Vigarista estão ocultos
- Apenas as posições dos pontos são visíveis (círculos cinzas)

**Sistema de Exploração:**

**Pontos de Exploração:**
- Jogador começa com 10 pontos de exploração por tier
- Revelar um ponto custa 1 ponto
- Pontos não utilizados: não carregam para próximo tier

**Revelação Parcial:**
- Ao revelar um ponto, mostra:
  - Tipo de conteúdo (monstro normal/elite/evento)
  - Tipo elemental (só para monstros)
  - Nível de dificuldade aproximada (Fácil/Médio/Difícil/Muito Difícil)
  - Não mostra: stats exatos, habilidades, item equipado

**Indicadores de Dificuldade:**
- ⭐ Fácil: Monstro level 1-2, stats baixos
- ⭐⭐ Médio: Monstro level 3-5, stats médios
- ⭐⭐⭐ Difícil: Monstro level 6-8, stats altos
- ⭐⭐⭐⭐ Muito Difícil: Elite ou monstro level 9+

**Recuperação de Pontos:**
- Cada monstro derrotado devolve 1 ponto
- Cada evento completado devolve 2 pontos
- Casa do Vigarista pode vender "Mapa Parcial" (5 score) que revela 3 pontos

**Torre de Observação:**

**Estrutura Especial:**
- Ponto fixo no centro do mapa
- Sempre visível (não coberto por névoa)
- Custo: 5 score OU 5 pontos de exploração

**Funcionalidade:**
- Revela TODOS os pontos do mapa instantaneamente
- Mostra dificuldade de todos
- Uma vez usada, não pode usar novamente no mesmo tier

**Visual:**
- Torre de pedra alta no centro
- Feixe de luz ao topo que pulsa
- Ao usar: animação de luz se expandindo

**Estratégias de Exploração:**

**Cautela Máxima:**
- Revelar todos os pontos gastando exploração
- Escolher batalhas estrategicamente
- Mais seguro mas gasta todos os recursos

**Risco Controlado:**
- Revelar alguns pontos chave
- Enfrentar alguns no escuro (sorte)
- Balanceamento entre custo e informação

**All-In:**
- Não revelar nada, ir direto nas batalhas
- Máxima incerteza, máxima economia de recursos
- Para jogadores experientes/confiantes

**Pontos Estratégicos:**

**Revelação Inteligente:**
- Revelar primeiro o elite (garantir que pode derrotar)
- Revelar eventos (não quer perder santuário)
- Deixar normais no escuro (menos importantes)

**Marcadores do Jogador:**
- Pode marcar pontos revelados com etiquetas:
  - 🎯 "Prioridade" (atacar primeiro)
  - ⚠️ "Evitar" (muito difícil)
  - 💚 "Farmável" (fácil, bom para XP)
  - ❓ "Incerto" (não revelado)

**Eventos Especiais de Exploração:**

**Scout (Olheiro):**
- Evento raro no mapa
- NPC oferece revelar 3 pontos escolhidos gratuitamente
- Ou vender "Visão Verdadeira" (vê stats exatos por 10 score)

**Mapa do Tesouro:**
- Drop raro de batalhas (2% chance)
- Revela localização de 1 baú do tesouro oculto
- Baú contém item garantido épico+

**Armadilhas:**
- 5% dos pontos revelados são "Armadilhas"
- Ao clicar: batalha surpresa com monstro +20% mais forte
- Visual: Ponto pisca vermelho rapidamente

**Habilidades de Exploração:**

**Nova Habilidade: "Sentido Aguçado"**
- Monstro com essa habilidade revela automaticamente pontos adjacentes
- Alcance: 1 ponto de distância
- Não gasta pontos de exploração

**Nova Habilidade: "Visão Além"**
- Revela tipo elemental de TODOS os pontos ocultos
- Não revela dificuldade
- Cooldown: 1x por tier

**Sistema de Radar:**

**Mini-Mapa com Radar:**
- Canto superior direito
- Mostra pontos revelados em verde
- Pontos ocultos em cinza
- Posição atual do jogador marcada
- Pulsos indicam proximidade de eventos raros

**UI/UX:**

**Névoa Visual:**
- Efeito de fumaça cinza sobre áreas ocultas
- Transparência de 80% (ainda vê o fundo levemente)
- Animação de névoa se dissipando ao revelar

**Botão de Revelação:**
- Ícone de olho sobre cada ponto oculto
- Mostra custo (1 ponto) ao passar mouse
- Clique revela o ponto

**Contador de Pontos:**
- No header: "Exploração: 7/10"
- Muda de cor: Verde (>5), Amarelo (3-5), Vermelho (<3)

**Tutorial:**
- Primeira vez: popup explicando sistema
- Destaca Torre de Observação
- Sugere revelar elite primeiro

**Recompensas por Exploração Eficiente:**

**Conquistas:**
- "Explorador Cauteloso" - Complete tier revelando todos os pontos
- "Aventureiro Ousado" - Complete tier sem revelar nenhum ponto
- "Estrategista" - Complete tier usando exatamente 6 pontos

**Bônus:**
- Se sobrar 5+ pontos ao completar tier: +10 score bônus
- Se completar sem usar Torre: Item raro extra

**Impacto:**
- ✅ Adiciona layer de decisão estratégica PRÉ-batalha
- ✅ Aumenta tensão (não sabe o que vem)
- ✅ Recompensa planejamento
- ✅ Cria momentos de "descoberta"
- ✅ Permite diferentes estilos de jogo (cauteloso vs ousado)

**Complexidade de Implementação:** 🟡 Média

---

## 🎒 ITENS & EQUIPAMENTOS

### 💡 Ideia #14: Sistema de Crafting/Forja

**Descrição:**
Sistema de criação e upgrade de itens usando fragmentos coletados em batalhas.

**Mecânica de Fragmentos:**

**Tipos de Fragmentos:**
- 🔵 **Fragmento Comum** (drop 15%)
- 🟢 **Fragmento Raro** (drop 5%)
- 🟣 **Fragmento Épico** (drop 2%)
- 🟠 **Fragmento Lendário** (drop 0.5%)
- ⚪ **Fragmento Divino** (só de minibosses tier 50)

**Fragmentos Elementais:**
- Cada tipo de monstro dropa fragmento do seu elemento
- Exemplo: Monstro de fogo → Fragmento de Fogo
- Total: 30 tipos de fragmentos elementais

**Drop Rate:**
- Monstro normal: 10% chance de fragmento
- Monstro elite: 30% chance de fragmento
- Miniboss: 100% chance de múltiplos fragmentos

**Armazenamento:**
- Inventário separado para fragmentos (ilimitado)
- Organizados por tipo e raridade
- Contador visual mostrando quantidade

---

**Ferreiro no Mapa:**

**Localização:**
- Aparece como ponto fixo no mapa (tier 3+)
- Posição: Canto inferior esquerdo
- Visual: Bigorna e martelo, fumaça saindo

**Funcionalidades:**

**1. Craftar Novo Item**

**Receitas por Raridade:**
- **Item Normal:**
  - 3 Fragmentos Comuns
  - 1 Fragmento Elemental (define elemento do item)
  - Custo em score: 10

- **Item Raro:**
  - 5 Fragmentos Comuns
  - 3 Fragmentos Raros
  - 2 Fragmentos Elementais
  - Custo em score: 30

- **Item Épico:**
  - 3 Fragmentos Raros
  - 5 Fragmentos Épicos
  - 3 Fragmentos Elementais
  - Custo em score: 80

- **Item Lendário:**
  - 5 Fragmentos Épicos
  - 3 Fragmentos Lendários
  - 5 Fragmentos Elementais
  - Custo em score: 200

- **Item Mítico** (nova raridade):**
  - 10 Fragmentos Lendários
  - 1 Fragmento Divino
  - 10 Fragmentos Elementais (qualquer combinação)
  - Custo em score: 500

**Características de Item Mítico:**
- 6-7 atributos (todos os atributos possíveis)
- Valores: base 15-25 × tier
- Cor: Arco-íris animado
- Efeito especial passivo (escolher 1):
  - "Imortalidade": Revive 1x com 25% vida
  - "Vampirismo": Cura 10% do dano causado
  - "Reflexão": Reflete 30% do dano recebido
  - "Precisão": +15% crítico
  - "Evasão": +15% esquiva

**Escolha de Atributos:**
- Ao craftar, pode escolher QUAIS atributos quer no item
- Número de atributos depende da raridade
- Valores ainda são aleatórios (base × tier)

---

**2. Upgrade de Item Existente**

**Subir Raridade:**
- Transforma item em raridade superior
- Mantém atributos existentes
- Adiciona 1-2 atributos novos
- Aumenta valores base em 20%

**Custos de Upgrade:**
- Inferior → Normal: 2 Fragmentos Comuns + 5 score
- Normal → Raro: 3 Fragmentos Raros + 20 score
- Raro → Épico: 5 Fragmentos Épicos + 50 score
- Épico → Lendário: 3 Fragmentos Lendários + 150 score
- Lendário → Mítico: 5 Fragmentos Lendários + 1 Divino + 400 score

**Upgrade de Tier:**
- Aumenta o multiplicador de tier do item
- Exemplo: Item tier 5 (atk +35) → Item tier 10 (atk +70)
- Custo: 10 Fragmentos do elemento + 50 score por tier aumentado
- Máximo: pode upgradar até tier atual do jogador

---

**3. Reforjar Atributos**

**Mecânica:**
- Mantém raridade e número de atributos
- Sorteia novamente QUAIS atributos tem
- Sorteia novamente valores base
- Útil para tentar conseguir atributos melhores

**Custo:**
- 5 Fragmentos da raridade do item
- Score = 2x tier atual
- Exemplo: Reforjar épico tier 10 = 5 Épicos + 20 score

**Proteção:**
- Pode "travar" 1 atributo para não mudar
- Custo adicional: +3 Fragmentos Lendários

---

**4. Extrair Essência**

**Mecânica:**
- Destruir item para obter fragmentos
- Útil para desfazer itens ruins

**Retorno:**
- Item Inferior: 1 Fragmento Comum
- Item Normal: 2 Fragmentos Comuns
- Item Raro: 1 Fragmento Raro + 2 Comuns
- Item Épico: 2 Fragmentos Épicos + 1 Raro
- Item Lendário: 1 Fragmento Lendário + 3 Épicos
- Item Mítico: 3 Fragmentos Lendários + 1 Divino

**Confirmação:**
- Requer confirmação dupla (evitar destruição acidental)
- Itens favoritos não podem ser extraídos

---

**5. Fundir Itens**

**Mecânica:**
- Combinar 2 itens da mesma raridade
- Cria 1 item da raridade superior
- Atributos são média dos 2 itens + bonus aleatório

**Requisitos:**
- Ambos itens devem ser mesma raridade
- Custo adicional: 5 score × tier médio

**Exemplo:**
- Item A (Normal): ATK +10, DEF +15
- Item B (Normal): ATK +12, VID +20
- Resultado (Raro): ATK +11, DEF +15, VID +20 + 1 atributo aleatório

---

**Animação de Forja:**

**Visual:**
- Tela escurece com partículas de fogo
- Bigorna no centro
- Martelo batendo (3 batidas)
- Item final surge com explosão de luz
- Som metálico CLANG a cada batida

**Tempo:**
- Duração: 3 segundos
- Pode pular pressionando tela (após 1ª batida)

---

**Receitas Especiais:**

**Descoberta de Receitas:**
- Algumas receitas são secretas
- Desbloqueadas ao craftar combinações específicas
- Dão itens únicos com nomes especiais

**Exemplos:**
- **"Espada do Dragão"**
  - 10 Fragmentos de Fogo + 5 Fragmentos de Dragão + Escama de Dragão
  - Item Lendário com bonus contra dragões (+30% dano)

- **"Armadura do Oceano"**
  - 15 Fragmentos de Água + Tinta do Kraken
  - Item Épico com imunidade a afogamento

- **"Cajado do Lich"**
  - Grimório Proibido + 10 Fragmentos de Trevas
  - Item Lendário que permite usar 1 habilidade de necromancia

---

**UI/UX:**

**Tela de Crafting:**
- Grid mostrando todos os fragmentos disponíveis
- Arrastar fragmentos para "Zona de Crafting"
- Preview do item resultante
- Lista de receitas conhecidas (lado esquerdo)
- Botão "Forjar" (só ativo se receita válida)

**Filtros:**
- Por raridade
- Por elemento
- Por tipo de receita (craftar/upgrade/reforjar)

**Galeria de Receitas:**
- Livro de receitas desbloqueadas
- Mostra ingredientes necessários
- Preview do resultado
- Receitas secretas aparecem como "???" até descobrir

---

**Impacto:**
- ✅ Dá uso aos drops ruins (extrair)
- ✅ Permite criar builds específicos (escolher atributos)
- ✅ Adiciona progressão paralela (colecionar receitas)
- ✅ Aumenta sensação de controle (não depende só de RNG de drops)
- ✅ Cria "crafting endgame" (itens míticos)

**Complexidade de Implementação:** 🔴 Alta

---

### 💡 Ideia #15: Sistema de Sets de Equipamento

**Descrição:**
Conjuntos temáticos de itens que dão bônus especiais quando equipados juntos.

**Estrutura de Sets:**

Cada set tem 3-5 peças com nomes relacionados. Equipar múltiplas peças do mesmo set ativa bônus progressivos.

---

**SETS DISPONÍVEIS:**

**🔥 Set do Dragão Flamejante**
- **Peças:**
  1. Escama de Dragão (peito)
  2. Garra Ardente (arma)
  3. Chifre Flamejante (cabeça)
  4. Cauda do Wyrm (acessório)
  5. Coração de Fogo (amuleto)

- **Bônus:**
  - 2 peças: +15% dano de fogo
  - 3 peças: +20% dano de fogo + Imunidade a queimadura
  - 4 peças: +25% dano de fogo + Ataques de fogo causam queimadura (15% chance)
  - 5 peças: +30% dano de fogo + "Fúria do Dragão" (ao ficar <30% vida, +50% ATK por 3 turnos)

**❄️ Set do Titã Gélido**
- **Peças:**
  1. Armadura de Gelo (peito)
  2. Martelo Congelante (arma)
  3. Elmo Glacial (cabeça)
  4. Botas da Neve (pés)
  5. Cristal Eterno (amuleto)

- **Bônus:**
  - 2 peças: +100 vida máxima
  - 3 peças: +200 vida + +15% defesa
  - 4 peças: +300 vida + +20% defesa + Regeneração de 5 HP/turno
  - 5 peças: +400 vida + +25% defesa + Regeneração de 10 HP/turno + "Pele de Gelo" (primeiros 100 de dano recebidos por batalha são absorvidos)

**⚡ Set do Relâmpago**
- **Peças:**
  1. Capa do Trovão (costas)
  2. Lança Elétrica (arma)
  3. Coroa dos Raios (cabeça)
  4. Botas Velozes (pés)
  5. Núcleo de Energia (amuleto)

- **Bônus:**
  - 2 peças: +15 agilidade
  - 3 peças: +25 agilidade + +10% crítico
  - 4 peças: +35 agilidade + +15% crítico + +10% esquiva
  - 5 peças: +50 agilidade + +20% crítico + +15% esquiva + "Velocidade Relâmpago" (sempre ataca primeiro, ignora agilidade do oponente)

**🌿 Set da Floresta Ancestral**
- **Peças:**
  1. Armadura de Casca (peito)
  2. Cajado da Vida (arma)
  3. Coroa de Folhas (cabeça)
  4. Raízes Vivas (pés)
  5. Semente Primordial (amuleto)

- **Bônus:**
  - 2 peças: Regeneração de 3 HP/turno
  - 3 peças: Regeneração de 5 HP/turno + Habilidades de cura +25% efetivas
  - 4 peças: Regeneração de 8 HP/turno + Habilidades de cura +50% efetivas + Começa batalha com buff de +10% vida máxima
  - 5 peças: Regeneração de 12 HP/turno + Habilidades de cura +75% efetivas + "Renascimento" (ao morrer, revive 1x com 40% vida)

**🌊 Set do Abismo Marinho**
- **Peças:**
  1. Escamas do Kraken (peito)
  2. Tridente das Marés (arma)
  3. Máscara Coral (cabeça)
  4. Botas Aquáticas (pés)
  5. Pérola Negra (amuleto)

- **Bônus:**
  - 2 peças: +10% defesa
  - 3 peças: +15% defesa + Ataques de água ganham +20% dano
  - 4 peças: +20% defesa + Ataques de água ganham +30% dano + Imunidade a afogamento
  - 5 peças: +25% defesa + Ataques de água ganham +50% dano + "Maré Alta" (cada turno, chance de 20% de ganhar turno extra)

**💀 Set do Necromante**
- **Peças:**
  1. Manto das Sombras (peito)
  2. Grimório Sombrio (arma)
  3. Capuz da Morte (cabeça)
  4. Botas Espectrais (pés)
  5. Crânio Ancestral (amuleto)

- **Bônus:**
  - 2 peças: Ataques drenam 5% da vida causada
  - 3 peças: Ataques drenam 10% da vida causada + +15% dano de trevas
  - 4 peças: Ataques drenam 15% da vida causada + +20% dano de trevas + Imunidade a veneno
  - 5 peças: Ataques drenam 25% da vida causada + +30% dano de trevas + "Toque da Morte" (ao derrotar inimigo, drena sua essência: +5% de todos stats até fim da run)

**✨ Set Divino (Lendário)**
- **Peças:**
  1. Armadura Celestial (peito)
  2. Espada Sagrada (arma)
  3. Auréola Dourada (cabeça)
  4. Asas de Luz (costas)
  5. Essência Divina (amuleto)

- **Bônus:**
  - 2 peças: +10% em TODOS os atributos
  - 3 peças: +15% em TODOS os atributos + Imunidade a todos os efeitos negativos
  - 4 peças: +20% em TODOS os atributos + Imunidade a todos os efeitos negativos + Ataques têm 10% chance de causar "Julgamento Divino" (dano triplo)
  - 5 peças: +25% em TODOS os atributos + "Transcendência" (se for morrer, sobrevive com 1 HP e ganha invencibilidade por 2 turnos - 1x por batalha)

**🗡️ Set do Gladiador**
- **Peças:**
  1. Couraça de Batalha (peito)
  2. Espada Gêmea (arma)
  3. Elmo de Guerra (cabeça)
  4. Manoplas Pesadas (mãos)
  5. Botas de Combate (pés)

- **Bônus:**
  - 2 peças: +20 ataque
  - 3 peças: +35 ataque + Críticos causam +0.2x dano adicional (1.5x → 1.7x)
  - 4 peças: +50 ataque + Críticos causam +0.4x dano adicional (1.5x → 1.9x) + +10% chance de crítico
  - 5 peças: +75 ataque + Críticos causam +0.8x dano adicional (1.5x → 2.3x) + +15% chance de crítico + "Fúria de Batalha" (cada ataque aumenta o próximo em +10%, até +50%)

**🛡️ Set do Guardião**
- **Peças:**
  1. Armadura Fortaleza (peito)
  2. Escudo Impenetrável (off-hand)
  3. Elmo do Protetor (cabeça)
  4. Grevas Reforçadas (pernas)
  5. Amuleto da Resiliência (amuleto)

- **Bônus:**
  - 2 peças: +30 defesa
  - 3 peças: +50 defesa + Reduz dano crítico recebido em 50%
  - 4 peças: +70 defesa + Reduz dano crítico recebido em 75% + 15% chance de bloquear ataque completamente
  - 5 peças: +100 defesa + Imunidade a críticos recebidos + 25% chance de bloquear ataque + "Fortaleza Inquebrável" (abaixo de 25% vida, ganha +100% defesa)

**🌀 Set Místico**
- **Peças:**
  1. Túnica Arcana (peito)
  2. Orbe do Conhecimento (arma)
  3. Chapéu de Mago (cabeça)
  4. Botas Levitantes (pés)
  5. Tomo dos Segredos (amuleto)

- **Bônus:**
  - 2 peças: Habilidades custam -1 energia
  - 3 peças: Habilidades custam -2 energia + +20 energia máxima
  - 4 peças: Habilidades custam -3 energia + +40 energia máxima + Regenera +2 energia/turno adicional
  - 5 peças: Habilidades custam -4 energia (mínimo 0) + +60 energia máxima + Regenera +5 energia/turno adicional + "Sobrecarga Arcana" (pode usar 2 habilidades no mesmo turno, 1x por batalha)

---

**Obtenção de Peças de Set:**

**Drops Naturais:**
- Peças de set dropam de monstros específicos
- Cada bioma tem 2-3 sets favorecidos
- Taxa de drop: 3% para peça de set (vs item normal)

**Crafting:**
- Pode craftar peças de set usando receitas especiais
- Requer fragmentos + material único do set
- Exemplo: Escama de Dragão = 10 Frag. Fogo + Escama do Boss Dragão

**Loja:**
- Casa do Vigarista vende peças aleatórias de set
- Opção especial: "Peça de Set" - 100 score
- Sorteia peça aleatória de qualquer set

**Boss Drops:**
- Minibosses garantem 1 peça do set temático
- Exemplo: Senhor dos Dragões (tier 10) → peça do Set do Dragão

---

**Identificação Visual:**

**No Inventário:**
- Borda especial dourada com padrão único
- Nome em fonte diferente
- Ícone de "corrente" indicando pertence a um set
- Tooltip mostra qual set + quantas peças tem

**Na Batalha:**
- Quando set está ativo, monstro ganha aura visual
- Cor da aura corresponde ao set:
  - Dragão: Chamas vermelhas
  - Titã: Cristais de gelo azuis
  - Relâmpago: Raios amarelos
  - Floresta: Folhas verdes
  - Abismo: Bolhas azuis escuras
  - Necromante: Sombras roxas
  - Divino: Luz dourada
  - Gladiador: Aura vermelha sangrenta
  - Guardião: Escudo azul brilhante
  - Místico: Runas flutuantes

**Efeitos Sonoros:**
- Som especial ao equipar peça que completa bônus
- Som épico ao completar set inteiro (5 peças)

---

**UI/UX:**

**Tela de Sets:**
- Aba dedicada no menu de inventário
- Mostra todos os sets do jogo
- Indica quais peças tem (acesas) e quais faltam (apagadas)
- Preview do monstro com set completo equipado
- Lista de bônus ativos

**Rastreador de Set:**
- Indicador no HUD mostrando set ativo
- Ícone + número de peças (ex: "🔥 3/5")
- Brilha quando bônus está ativo

**Galeria de Sets:**
- Enciclopédia de todos os sets
- Lore de cada set
- Como obter cada peça
- Preview 3D do monstro com set completo

---

**Estratégia de Build:**

**Trade-offs:**
- Sets forçam usar itens específicos (pode não ser ótimo individualmente)
- Mas bônus de set compensa a perda
- Decision-making: 3 peças de set melhor vs 3 lendários aleatórios?

**Mixing Sets:**
- Pode equipar peças de sets diferentes
- Mas não ativa bônus de nenhum (precisa 2+ do mesmo)
- Ou pode fazer 2 peças de set A + 2 peças de set B = 2 bônus pequenos

**Meta Sets:**
- Sets melhores para cada situação:
  - Dragão: DPS puro
  - Titã: Tank
  - Relâmpago: Crit/AGI build
  - Floresta: Sustain/heal
  - Guardião: Defesa máxima

---

**Impacto:**
- ✅ Objetivos de longo prazo (colecionar set completo)
- ✅ Aumenta engajamento (caçar peça específica)
- ✅ Build diversity (diferentes sets = diferentes estilos)
- ✅ Visual diferenciado (auras de set)
- ✅ Sensação de poder ao completar set

**Complexidade de Implementação:** 🔴 Alta

---

(Continuando com mais ideias nos próximos blocos...)