# 🐣 Criadouro - Documento de Planejamento

> **Modo de jogo estilo Tamagotchi** - Cuide do seu mascote virtual!

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [O Mascote](#o-mascote)
3. [Sistema de Necessidades](#sistema-de-necessidades)
4. [Sistema de Doença](#sistema-de-doença)
5. [Sistema de Morte](#sistema-de-morte)
6. [Economia - Planis](#economia---planis)
7. [Loja do Criadouro](#loja-do-criadouro)
8. [Interações](#interações)
9. [Interface do Usuário](#interface-do-usuário)
10. [Notificações](#notificações)
11. [Integração com Aventura](#integração-com-aventura)
12. [Memorial dos Mascotes](#memorial-dos-mascotes)
13. [Emojis de Status](#emojis-de-status)
14. [Ideias Futuras](#ideias-futuras)
15. [Considerações Técnicas](#considerações-técnicas)

---

## 🎯 Visão Geral

O **Criadouro** é um novo modo de jogo acessível pelo menu principal (Home). O jogador terá um mascote virtual que precisa de cuidados constantes - alimentação, hidratação, higiene, carinho e atenção médica.

### Conceito Principal
- **1 mascote por vez** (não é de batalha)
- **Tempo real**: necessidades degradam mesmo com app fechado
- **Consequências reais**: negligência leva à morte do mascote
- **Integração**: recursos obtidos no modo Aventura

---

## 🐾 O Mascote

### Criação
- O jogador escolhe a **imagem do mascote** dentre os monstros desbloqueados no catálogo
- Define o **nome** do mascote
- O mascote **NÃO evolui** - mantém a mesma aparência sempre

### Atributos Iniciais
| Atributo | Valor Inicial |
|----------|---------------|
| Fome | 75% |
| Sede | 75% |
| Higiene | 75% |
| Alegria | 75% |
| Saúde | 100% |

### Informações do Mascote
- **Nome**: definido pelo jogador
- **Dias vivo**: contador desde a criação
- **Imagem**: monstro escolhido do catálogo

---

## 📊 Sistema de Necessidades

### Barras de Status (0% a 100%)

| Barra | Emoji Cheio | Emoji Baixo | Degradação Base |
|-------|-------------|-------------|-----------------|
| 🍖 Fome | 😋 | 😫 | ~5% por hora (~0.083% por minuto) |
| 💧 Sede | 😊 | 🥵 | ~8% por hora (~0.133% por minuto) |
| 🧼 Higiene | ✨ | 🦨 | ~3% por hora (~0.05% por minuto) |
| 😄 Alegria | 🥰 | 😢 | Especial (ver abaixo) |
| ❤️ Saúde | 💪 | 🤒 | Não degrada naturalmente |

### Regras de Degradação

#### Fome (🍖)
- **Taxa**: ~0.083% por minuto (5% por hora)
- **Cálculo**: `minutos_passados * 0.083`

#### Sede (💧)
- **Taxa**: ~0.133% por minuto (8% por hora)
- **Cálculo**: `minutos_passados * 0.133`

#### Higiene (🧼)
- **Taxa**: ~0.05% por minuto (3% por hora)
- **Cálculo**: `minutos_passados * 0.05`

#### Alegria (😄)
- **Regra especial**: Só começa a cair após **5+ horas offline**
- Ao passar 5h offline: **-10% imediato**
- Após isso: **-1% por hora** enquanto offline
- Se Fome OU Sede = 0%: alegria cai **3x mais rápido**

#### Saúde (❤️)
- **NÃO degrada naturalmente**
- Só é afetada por:
  - Doença (quando não tratada)
  - Barras zeradas (ver Sistema de Morte)

### Interação Entre Barras

```
┌─────────────────────────────────────────────────────────────┐
│                    CADEIA DE CONSEQUÊNCIAS                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  FOME = 0% ──────┬──► Alegria cai 3x mais rápido            │
│                  └──► Inicia contador de morte (3h)          │
│                                                              │
│  SEDE = 0% ──────┬──► Alegria cai 3x mais rápido            │
│                  └──► Inicia contador de morte (3h)          │
│                                                              │
│  HIGIENE = 0% ───┬──► Aumenta chance de doença (+50%)       │
│                  └──► Alegria cai 2x mais rápido            │
│                                                              │
│  ALEGRIA BAIXA ──┴──► Aumenta chance de doença              │
│  (< 30%)             (reduz intervalo do sorteio)           │
│                                                              │
│  ALEGRIA ALTA ───────► Diminui chance de doença             │
│  (> 70%)              (aumenta intervalo do sorteio)        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🤒 Sistema de Doença

### Mecânica Principal

1. **Imunidade Inicial**: Ao criar o mascote, ele tem **24 horas de imunidade**
2. **Sorteio de Doença**: Após imunidade, sistema sorteia entre **1h e 30h** para próxima doença
3. **Quando Doente**: Todas as barras degradam **2x mais rápido**
4. **Cura**: Automática ao administrar **remédio**
5. **Novo Sorteio**: Após cura, novo sorteio é feito

### Modificadores de Chance

| Condição | Efeito no Sorteio |
|----------|-------------------|
| Alegria > 70% | Intervalo aumenta (+10h no máximo) |
| Alegria < 30% | Intervalo diminui (-10h no máximo) |
| Higiene = 0% | Chance de doença +50% |

### Exemplo de Cálculo

```
Sorteio base: random(1, 30) horas

Se Alegria > 70%:
  Sorteio: random(1, 40) horas  // mais tempo saudável

Se Alegria < 30%:
  Sorteio: random(1, 20) horas  // fica doente mais rápido

Se Higiene = 0%:
  Resultado do sorteio * 0.5    // metade do tempo
```

### Estados Visuais de Doença

| Estado | Emoji | Descrição |
|--------|-------|-----------|
| Saudável | 💚 | Mascote normal |
| Doente | 🤢 | Mascote com aparência doente |
| Crítico | ☠️ | Prestes a morrer |

---

## 💀 Sistema de Morte

### Condições de Morte

O mascote morre quando **qualquer barra chega a 0%** e permanece assim por **3 horas**.

### Processo de Morte

```
┌─────────────────────────────────────────────────────────────┐
│                      PROCESSO DE MORTE                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Barra chega a 0%                                        │
│     └──► Inicia contador de 3 horas                         │
│                                                              │
│  2. Durante as 3 horas:                                     │
│     └──► Outras barras começam a ser afetadas               │
│     └──► Alertas visuais intensos                           │
│     └──► Notificações urgentes (se configurado)             │
│                                                              │
│  3. Se não recuperar em 3h:                                 │
│     └──► Mascote morre                                      │
│     └──► Transforma em imagem do ovo do evento              │
│     └──► Registro salvo no Memorial                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Cascata de Dano (Durante as 3h críticas)

| Barra Zerada | Efeito em Outras Barras |
|--------------|-------------------------|
| Fome = 0% | Saúde -5% por hora, Alegria -3% por hora |
| Sede = 0% | Saúde -8% por hora, Alegria -3% por hora |
| Higiene = 0% | Saúde -2% por hora (infecção) |
| Saúde = 0% | **MORTE IMEDIATA** |

### Ao Morrer

- Mascote vira a **imagem do ovo do evento**
- **Perde todo progresso** (dias vivo, status)
- Registro salvo no **Memorial** com:
  - Nome do mascote
  - Dias que viveu
  - Causa da morte
  - Data da morte

---

## 💰 Economia - Planis

### O que são Planis?

**Planis** é a moeda exclusiva do Criadouro, usada para comprar itens na Loja do Criadouro.

### Como Ganhar

| Fonte | Chance | Quantidade |
|-------|--------|------------|
| Batalha (Andares 1-49) | Mesma chance da chave (x2) | 1-3 Planis |
| Batalha (Andares 50+) | Chance da chave (x3) | 2-5 Planis |

### Características
- **Rara** - não é fácil de conseguir
- **Sem compra com dinheiro real** (por enquanto)
- **Uso exclusivo** no Criadouro

---

## 🏪 Loja do Criadouro

### Categorias de Itens

#### 🍖 Alimentação
| Item | Preço (Planis) | Efeito |
|------|----------------|--------|
| Ração Básica | 5 | +20% Fome |
| Ração Premium | 15 | +50% Fome |
| Banquete | 30 | +100% Fome |
| Nutys (todas) | 3 | +10% Fome |

#### 💧 Hidratação
| Item | Preço (Planis) | Efeito |
|------|----------------|--------|
| Água | 3 | +20% Sede |
| Suco Natural | 8 | +40% Sede |
| Bebida Energética | 20 | +80% Sede |

#### 💊 Medicamentos
| Item | Preço (Planis) | Efeito |
|------|----------------|--------|
| Remédio Básico | 25 | Cura doença |
| Kit Primeiros Socorros | 50 | Cura doença + 30% Saúde |
| Vitaminas | 15 | +20% Saúde |

#### 🧼 Higiene
| Item | Preço (Planis) | Efeito |
|------|----------------|--------|
| Sabonete | 5 | +30% Higiene |
| Kit Banho Completo | 15 | +70% Higiene |
| Perfume | 10 | +20% Higiene + 5% Alegria |

#### 🎾 Brinquedos
| Item | Preço (Planis) | Efeito |
|------|----------------|--------|
| Bolinha | 10 | +15% Alegria |
| Osso | 12 | +15% Alegria |
| Brinquedo Squeaky | 20 | +25% Alegria |
| Brinquedo Premium | 40 | +40% Alegria |

---

## 🎮 Interações

### Interações Gratuitas

| Ação | Efeito | Limite |
|------|--------|--------|
| 🤲 Acariciar | +1% Alegria | 1x por andar do Aventura |
| 🎾 Brincar | +1% Alegria | 1x por andar do Aventura |
| 🛁 Dar Banho | +10% Higiene | Ilimitado |

> **Nota**: Acariciar e Brincar são desbloqueados ao completar andares no Aventura. Isso incentiva o jogador a jogar o modo Aventura para cuidar melhor do mascote.

### Interações com Itens

| Ação | Requer | Efeito |
|------|--------|--------|
| 🍖 Alimentar | Item de comida | Varia por item |
| 💧 Dar Água | Item de bebida | Varia por item |
| 💊 Medicar | Remédio | Cura doença |
| 🎁 Dar Brinquedo | Brinquedo | Varia por item |

---

## 📱 Interface do Usuário

### Tela Principal do Criadouro

```
┌─────────────────────────────────────────────────────────────┐
│                      🐣 CRIADOURO                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│                    ┌───────────────┐                        │
│                    │               │                        │
│                    │   [MASCOTE]   │  ← Imagem do monstro   │
│                    │     😊        │  ← Emoji de humor      │
│                    │               │                        │
│                    └───────────────┘                        │
│                                                              │
│                    "Nome do Mascote"                        │
│                    📅 12 dias vivo                          │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  BARRAS DE STATUS                                           │
│                                                              │
│  🍖 Fome     [████████░░] 80%                               │
│  💧 Sede     [██████░░░░] 60%                               │
│  🧼 Higiene  [█████████░] 90%                               │
│  😄 Alegria  [███████░░░] 70%                               │
│  ❤️ Saúde    [██████████] 100%                              │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  AÇÕES RÁPIDAS                                              │
│                                                              │
│  [🤲 Acariciar]  [🎾 Brincar]  [🛁 Banho]                   │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [🍖 Alimentar]  [💧 Dar Água]  [💊 Medicar]                │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [🏪 Loja]  [⚙️ Config]  [📜 Memorial]                      │
│                                                              │
│                    💰 150 Planis                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Estados Visuais do Mascote

| Condição | Emoji/Visual |
|----------|--------------|
| Tudo OK | 😊 |
| Com fome (< 30%) | 😫 |
| Com sede (< 30%) | 🥵 |
| Sujo (< 30%) | 🦨 |
| Triste (< 30%) | 😢 |
| Doente | 🤢 |
| Crítico (alguma barra = 0%) | ☠️ |
| Feliz (tudo > 70%) | 🥰 |
| Morto | 🥚 (ovo do evento) |

---

## 🔔 Notificações

### Configurações (Tela de Config do Criadouro)

O jogador pode configurar **quando receber notificações** para cada barra:

| Barra | Configuração | Exemplo |
|-------|--------------|---------|
| Fome | Notificar quando < X% | "Notificar quando fome < 30%" |
| Sede | Notificar quando < X% | "Notificar quando sede < 40%" |
| Higiene | Notificar quando < X% | "Notificar quando higiene < 25%" |
| Alegria | Notificar quando < X% | "Notificar quando alegria < 20%" |
| Saúde | Notificar quando < X% | "Notificar quando saúde < 50%" |
| Doença | Ativar/Desativar | "Notificar quando ficar doente" |

### Mensagens de Notificação

| Evento | Mensagem |
|--------|----------|
| Fome baixa | "🍖 [Nome] está com fome! Alimente-o!" |
| Sede baixa | "💧 [Nome] está com sede! Dê água!" |
| Higiene baixa | "🧼 [Nome] precisa de um banho!" |
| Alegria baixa | "😢 [Nome] está triste! Brinque com ele!" |
| Doente | "🤒 [Nome] ficou doente! Medique-o!" |
| Crítico | "☠️ URGENTE: [Nome] está morrendo!" |

---

## 🗡️ Integração com Aventura

### Drops nas Batalhas

| Item | Drop | Andares |
|------|------|---------|
| Planis | Chance x2 da chave | 1-49 |
| Planis | Chance x3 da chave | 50+ |
| Nutys | Drop normal | Todos |

### Fluxo de Integração

```
┌─────────────────────────────────────────────────────────────┐
│                                                              │
│   AVENTURA                          CRIADOURO               │
│   ────────                          ─────────               │
│                                                              │
│   Batalha ──────► Drop Planis ──────► Loja                  │
│      │                                  │                    │
│      │                                  ▼                    │
│      └──────► Drop Nutys ──────► Alimentar Mascote          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📜 Memorial dos Mascotes

### Tela do Memorial

Registro de todos os mascotes que morreram.

```
┌─────────────────────────────────────────────────────────────┐
│                    📜 MEMORIAL                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🪦 "Fluffy"                                         │    │
│  │    Viveu: 45 dias                                   │    │
│  │    Causa: Desidratação (💧 Sede)                    │    │
│  │    Data: 15/03/2025                                 │    │
│  │    [Imagem do monstro]                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 🪦 "Rex"                                            │    │
│  │    Viveu: 12 dias                                   │    │
│  │    Causa: Doença não tratada (🤒)                   │    │
│  │    Data: 02/02/2025                                 │    │
│  │    [Imagem do monstro]                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Dados Salvos por Mascote

- Nome
- Imagem (monstro escolhido)
- Dias viveu
- Causa da morte
- Data da morte
- Estatísticas finais (todas as barras)

---

## 😀 Emojis de Status

### Tabela Completa de Emojis

| Status | > 70% | 30-70% | < 30% | 0% |
|--------|-------|--------|-------|-----|
| Fome | 😋 | 😐 | 😫 | 💀 |
| Sede | 😊 | 😐 | 🥵 | 💀 |
| Higiene | ✨ | 😐 | 🦨 | 🤢 |
| Alegria | 🥰 | 😐 | 😢 | 😭 |
| Saúde | 💪 | 😐 | 🤒 | ☠️ |

### Emojis Especiais

| Situação | Emoji |
|----------|-------|
| Doente | 🤢 |
| Dormindo | 😴 |
| Muito feliz | 🥳 |
| Estado crítico | ☠️ |
| Morto (ovo) | 🥚 |

---

## 💡 Ideias Futuras

### Fase 2 - Ambiente/Habitat
- [ ] Quarto do mascote decorável
- [ ] Móveis e itens de decoração
- [ ] Temas de ambiente (floresta, praia, etc.)

### Fase 3 - Benefícios no Jogo Principal
- [ ] Mascote bem cuidado dá bônus nas batalhas
- [ ] Mascote feliz aumenta chance de drops
- [ ] Habilidades especiais desbloqueáveis

### Fase 4 - Social
- [ ] Visitar mascote de amigos
- [ ] Ranking de dias vivos
- [ ] Conquistas do Criadouro

### Fase 5 - Evolução (Opcional)
- [ ] Mascote pode evoluir baseado em cuidados
- [ ] Formas especiais por longevidade
- [ ] Skins exclusivas

### Outras Ideias
- [ ] Missões diárias do Criadouro
- [ ] Eventos especiais (Natal, Páscoa, etc.)
- [ ] Mini-games com o mascote
- [ ] Sistema de humor mais complexo
- [ ] Mascote pode ter "gostos" (preferências de comida)
- [ ] Álbum de fotos/memórias do mascote

---

## ⚙️ Considerações Técnicas

### Cálculo de Tempo

**IMPORTANTE**: Sempre usar horário da internet (NTP) para evitar trapaças.

```dart
// Exemplo de cálculo de degradação
double calcularDegradacao(DateTime ultimoAcesso, double taxaPorMinuto) {
  final agora = await obterHoraInternet();
  final minutosPassados = agora.difference(ultimoAcesso).inMinutes;
  return minutosPassados * taxaPorMinuto;
}

// Taxas por minuto
const double TAXA_FOME = 0.083;      // ~5% por hora
const double TAXA_SEDE = 0.133;      // ~8% por hora
const double TAXA_HIGIENE = 0.05;    // ~3% por hora
```

### Estrutura de Dados Sugerida

```dart
class Mascote {
  String id;
  String nome;
  String monstroId;  // referência ao catálogo
  DateTime dataCriacao;
  DateTime ultimoAcesso;

  // Barras
  double fome;       // 0-100
  double sede;       // 0-100
  double higiene;    // 0-100
  double alegria;    // 0-100
  double saude;      // 0-100

  // Doença
  bool estaDoente;
  DateTime? proximaDoenca;  // timestamp do sorteio
  DateTime? fimImunidade;   // 24h após criação

  // Morte
  DateTime? inicioCritico;  // quando alguma barra zerou
  String? barraZerada;      // qual barra causou estado crítico
}

class MascoteMorto {
  String nome;
  String monstroId;
  int diasVivido;
  String causaMorte;
  DateTime dataMorte;
  Map<String, double> estatisticasFinais;
}

class ConfigCriadouro {
  Map<String, int> limiteNotificacao;  // ex: {"fome": 30, "sede": 40}
  bool notificarDoenca;
}
```

### Sincronização

- Calcular degradação ao abrir o app
- Salvar timestamp de último acesso
- Verificar doença pendente
- Verificar se morreu enquanto offline

---

## 📝 Changelog do Documento

| Versão | Data | Alterações |
|--------|------|------------|
| 1.0 | 25/11/2025 | Versão inicial do documento |

---

> **Próximos passos**: Revisar documento, priorizar features para MVP, iniciar desenvolvimento da estrutura base.
