# 📋 Tasks de Implementação - Criadouro

> **Referência**: [planejamento_criadouro.md](planejamento_criadouro.md)

---

## 📊 Visão Geral

| Total de Tasks | Prioridade Alta | Prioridade Média | Prioridade Baixa |
|----------------|-----------------|------------------|------------------|
| 11 | 5 | 4 | 2 |

---

## 🔴 Prioridade Alta (MVP)

### Task 1: Criar Models do Criadouro
**Status**: ⬜ Pendente
**Referência**: [Considerações Técnicas](planejamento_criadouro.md#considerações-técnicas)

#### Subtarefas:
- [ ] Criar `Mascote` model
  - `id`, `nome`, `monstroId`, `dataCriacao`, `ultimoAcesso`
  - Barras: `fome`, `sede`, `higiene`, `alegria`, `saude` (0-100)
  - Doença: `estaDoente`, `proximaDoenca`, `fimImunidade`
  - Morte: `inicioCritico`, `barraZerada`
- [ ] Criar `MascoteMorto` model
  - `nome`, `monstroId`, `diasVivido`, `causaMorte`, `dataMorte`, `estatisticasFinais`
- [ ] Criar `ConfigCriadouro` model
  - `limiteNotificacao` (Map por barra)
  - `notificarDoenca`
- [ ] Criar `ItemCriadouro` model (itens da loja)
  - `id`, `nome`, `categoria`, `preco`, `efeito`, `valorEfeito`
- [ ] Criar enums: `CategoriaItem`, `TipoEfeito`, `CausaMorte`

#### Arquivos a criar:
```
lib/features/criadouro/
├── domain/
│   ├── models/
│   │   ├── mascote.dart
│   │   ├── mascote_morto.dart
│   │   ├── config_criadouro.dart
│   │   ├── item_criadouro.dart
│   │   └── enums/
│   │       ├── categoria_item.dart
│   │       ├── tipo_efeito.dart
│   │       └── causa_morte.dart
```

---

### Task 2: Criar Serviço/Provider do Criadouro
**Status**: ⬜ Pendente
**Referência**: [Sistema de Necessidades](planejamento_criadouro.md#sistema-de-necessidades), [Sistema de Doença](planejamento_criadouro.md#sistema-de-doença), [Sistema de Morte](planejamento_criadouro.md#sistema-de-morte)

#### Subtarefas:
- [ ] Criar `CriadouroProvider` (ChangeNotifier)
- [ ] Implementar cálculo de degradação por minuto
  - Fome: `0.083%/min` (~5%/hora)
  - Sede: `0.133%/min` (~8%/hora)
  - Higiene: `0.05%/min` (~3%/hora)
  - Alegria: Especial (5h+ offline → -10%, depois -1%/hora)
- [ ] Implementar multiplicadores de degradação
  - Doente: `2x` mais rápido
  - Fome/Sede = 0%: Alegria `3x` mais rápido
- [ ] Implementar sistema de doença
  - Imunidade inicial: 24h
  - Sorteio: `random(1, 30)` horas
  - Modificadores por alegria/higiene
- [ ] Implementar sistema de morte
  - Contador de 3h quando barra = 0%
  - Cascata de dano entre barras
  - Saúde = 0% → morte imediata
- [ ] Implementar interações
  - Acariciar/Brincar: +1% alegria (1x por andar)
  - Dar banho: +10% higiene (ilimitado)
  - Usar itens: efeito variável
- [ ] Implementar criação de novo mascote
- [ ] Implementar registro de morte no Memorial

#### Arquivos a criar:
```
lib/features/criadouro/
├── application/
│   ├── criadouro_provider.dart
│   ├── criadouro_calculator.dart  (cálculos de degradação)
│   └── criadouro_disease_service.dart  (sistema de doença)
```

---

### Task 3: Criar Tela Principal do Criadouro
**Status**: ⬜ Pendente
**Referência**: [Interface do Usuário](planejamento_criadouro.md#interface-do-usuário), [Emojis de Status](planejamento_criadouro.md#emojis-de-status)

#### Subtarefas:
- [ ] Criar `CriadouroScreen` (tela principal)
- [ ] Implementar exibição do mascote
  - Imagem do monstro (do catálogo)
  - Emoji de humor baseado no estado
  - Nome e dias vivo
- [ ] Implementar barras de status visuais
  - 🍖 Fome, 💧 Sede, 🧼 Higiene, 😄 Alegria, ❤️ Saúde
  - Cores por nível (verde > amarelo > vermelho)
  - Emojis dinâmicos por estado
- [ ] Implementar botões de ações rápidas
  - 🤲 Acariciar, 🎾 Brincar, 🛁 Banho
- [ ] Implementar botões de ações com itens
  - 🍖 Alimentar, 💧 Dar Água, 💊 Medicar
- [ ] Implementar navegação
  - 🏪 Loja, ⚙️ Config, 📜 Memorial
- [ ] Exibir saldo de Teks
- [ ] Implementar estados visuais especiais
  - Doente: visual diferenciado 🤢
  - Crítico: alertas visuais ☠️

#### Arquivos a criar:
```
lib/features/criadouro/
├── presentation/
│   ├── criadouro_screen.dart
│   ├── widgets/
│   │   ├── mascote_display.dart
│   │   ├── status_bar.dart
│   │   ├── status_bars_panel.dart
│   │   ├── action_buttons.dart
│   │   └── criadouro_bottom_nav.dart
```

---

### Task 4: Criar Tela de Criação do Mascote
**Status**: ⬜ Pendente
**Referência**: [O Mascote](planejamento_criadouro.md#o-mascote)

#### Subtarefas:
- [ ] Criar `CriarMascoteScreen`
- [ ] Implementar grid de seleção de monstros
  - Mostrar apenas monstros desbloqueados do catálogo
  - Destacar monstro selecionado
- [ ] Implementar campo de nome
  - Validação (mínimo 2 caracteres, máximo 15)
- [ ] Implementar preview do mascote
- [ ] Implementar botão de confirmação
- [ ] Mostrar atributos iniciais (todos em 75%, saúde 100%)

#### Arquivos a criar:
```
lib/features/criadouro/
├── presentation/
│   ├── criar_mascote_screen.dart
│   ├── widgets/
│   │   ├── monstro_grid_selector.dart
│   │   └── mascote_preview.dart
```

---

### Task 5: Criar Tela da Loja do Criador
**Status**: ⬜ Pendente
**Referência**: [Loja do Criador](planejamento_criadouro.md#loja-do-criador)

#### Subtarefas:
- [ ] Criar `LojaCriadouroScreen`
- [ ] Implementar abas por categoria
  - 🍖 Alimentação
  - 💧 Hidratação
  - 💊 Medicamentos
  - 🧼 Higiene
  - 🎾 Brinquedos
- [ ] Implementar lista de itens por categoria
  - Nome, preço, efeito
  - Botão de compra
- [ ] Implementar lógica de compra
  - Verificar saldo de Teks
  - Adicionar item ao inventário
  - Deduzir Teks
- [ ] Exibir saldo de Teks no header
- [ ] Implementar feedback de compra (sucesso/erro)

#### Itens da loja (conforme planejamento):
| Categoria | Itens |
|-----------|-------|
| 🍖 Alimentação | Ração Básica, Ração Premium, Banquete, Nutys |
| 💧 Hidratação | Água, Suco Natural, Bebida Energética |
| 💊 Medicamentos | Remédio Básico, Kit Primeiros Socorros, Vitaminas |
| 🧼 Higiene | Sabonete, Kit Banho Completo, Perfume |
| 🎾 Brinquedos | Bolinha, Osso, Brinquedo Squeaky, Brinquedo Premium |

#### Arquivos a criar:
```
lib/features/criadouro/
├── presentation/
│   ├── loja_criadouro_screen.dart
│   ├── widgets/
│   │   ├── categoria_tab.dart
│   │   ├── item_loja_card.dart
│   │   └── saldo_teks_header.dart
```

---

## 🟡 Prioridade Média

### Task 6: Criar Tela do Memorial
**Status**: ⬜ Pendente
**Referência**: [Memorial dos Mascotes](planejamento_criadouro.md#memorial-dos-mascotes)

#### Subtarefas:
- [ ] Criar `MemorialScreen`
- [ ] Implementar lista de mascotes mortos
  - 🪦 Nome
  - Dias vivido
  - Causa da morte
  - Data da morte
  - Imagem do monstro
- [ ] Implementar card expandível com estatísticas finais
- [ ] Implementar estado vazio (nenhum mascote morreu ainda)

#### Arquivos a criar:
```
lib/features/criadouro/
├── presentation/
│   ├── memorial_screen.dart
│   ├── widgets/
│   │   └── mascote_morto_card.dart
```

---

### Task 7: Criar Tela de Configurações do Criadouro
**Status**: ⬜ Pendente
**Referência**: [Notificações](planejamento_criadouro.md#notificações)

#### Subtarefas:
- [ ] Criar `ConfigCriadouroScreen`
- [ ] Implementar sliders para cada barra
  - "Notificar quando Fome < X%"
  - "Notificar quando Sede < X%"
  - "Notificar quando Higiene < X%"
  - "Notificar quando Alegria < X%"
  - "Notificar quando Saúde < X%"
- [ ] Implementar toggle para notificação de doença
- [ ] Salvar configurações no provider

#### Arquivos a criar:
```
lib/features/criadouro/
├── presentation/
│   ├── config_criadouro_screen.dart
│   ├── widgets/
│   │   └── notificacao_slider.dart
```

---

### Task 8: Integrar Drop de Teks no Aventura
**Status**: ⬜ Pendente
**Referência**: [Economia - Teks](planejamento_criadouro.md#economia---teks), [Integração com Aventura](planejamento_criadouro.md#integração-com-aventura)

#### Subtarefas:
- [ ] Adicionar `teks` ao modelo de recompensas de batalha
- [ ] Implementar lógica de drop
  - Andares 1-49: chance = `chave * 2`
  - Andares 50+: chance = `chave * 3`
- [ ] Implementar quantidade de drop
  - Andares 1-49: 1-3 Teks
  - Andares 50+: 2-5 Teks
- [ ] Exibir Teks ganhos na tela de vitória
- [ ] Atualizar saldo no CriadouroProvider

#### Arquivos a modificar:
```
lib/features/aventura/
├── domain/models/batalha_reward.dart  (adicionar teks)
├── application/batalha_provider.dart  (lógica de drop)
├── presentation/vitoria_screen.dart   (exibir teks)
```

---

### Task 9: Adicionar Botão Criadouro na Home
**Status**: ⬜ Pendente
**Referência**: [Visão Geral](planejamento_criadouro.md#visão-geral)

#### Subtarefas:
- [ ] Adicionar botão/card "🐣 Criadouro" na Home
- [ ] Implementar navegação para CriadouroScreen
- [ ] Mostrar indicador se mascote precisa de atenção
  - Badge vermelho se alguma barra < 30%
  - Badge amarelo se doente

#### Arquivos a modificar:
```
lib/features/home/
├── presentation/home_screen.dart  (adicionar botão)
```

---

## 🟢 Prioridade Baixa

### Task 10: Implementar Persistência de Dados
**Status**: ⬜ Pendente
**Referência**: [Considerações Técnicas](planejamento_criadouro.md#considerações-técnicas)

#### Subtarefas:
- [ ] Criar `CriadouroRepository`
- [ ] Implementar salvamento local (SharedPreferences ou Hive)
- [ ] Implementar sincronização com Google Drive
  - Salvar: mascote atual, memorial, config, inventário, teks
- [ ] Implementar carregamento ao iniciar app
- [ ] Implementar cálculo de degradação offline
  - Usar horário da internet (NTP)
  - Calcular todas as barras desde último acesso
  - Verificar se morreu enquanto offline

#### Arquivos a criar:
```
lib/features/criadouro/
├── data/
│   ├── criadouro_repository.dart
│   └── criadouro_local_storage.dart
```

---

### Task 11: Implementar Sistema de Notificações
**Status**: ⬜ Pendente
**Referência**: [Notificações](planejamento_criadouro.md#notificações)

#### Subtarefas:
- [ ] Configurar flutter_local_notifications
- [ ] Implementar agendamento de notificações
  - Calcular quando cada barra atingirá o limite configurado
  - Agendar notificação para esse momento
- [ ] Implementar mensagens personalizadas
  - "🍖 [Nome] está com fome! Alimente-o!"
  - "💧 [Nome] está com sede! Dê água!"
  - "🧼 [Nome] precisa de um banho!"
  - "😢 [Nome] está triste! Brinque com ele!"
  - "🤒 [Nome] ficou doente! Medique-o!"
  - "☠️ URGENTE: [Nome] está morrendo!"
- [ ] Reagendar notificações ao:
  - Abrir o app
  - Alimentar/cuidar do mascote
  - Alterar configurações

#### Arquivos a criar:
```
lib/features/criadouro/
├── application/
│   └── criadouro_notification_service.dart
```

---

## 📁 Estrutura Final de Pastas

```
lib/features/criadouro/
├── domain/
│   ├── models/
│   │   ├── mascote.dart
│   │   ├── mascote_morto.dart
│   │   ├── config_criadouro.dart
│   │   ├── item_criadouro.dart
│   │   └── enums/
│   │       ├── categoria_item.dart
│   │       ├── tipo_efeito.dart
│   │       └── causa_morte.dart
│   │
├── application/
│   ├── criadouro_provider.dart
│   ├── criadouro_calculator.dart
│   ├── criadouro_disease_service.dart
│   └── criadouro_notification_service.dart
│   │
├── data/
│   ├── criadouro_repository.dart
│   └── criadouro_local_storage.dart
│   │
├── presentation/
│   ├── criadouro_screen.dart
│   ├── criar_mascote_screen.dart
│   ├── loja_criadouro_screen.dart
│   ├── memorial_screen.dart
│   ├── config_criadouro_screen.dart
│   └── widgets/
│       ├── mascote_display.dart
│       ├── status_bar.dart
│       ├── status_bars_panel.dart
│       ├── action_buttons.dart
│       ├── criadouro_bottom_nav.dart
│       ├── monstro_grid_selector.dart
│       ├── mascote_preview.dart
│       ├── categoria_tab.dart
│       ├── item_loja_card.dart
│       ├── saldo_teks_header.dart
│       ├── mascote_morto_card.dart
│       └── notificacao_slider.dart
```

---

## 🔄 Ordem de Implementação Sugerida

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO DE IMPLEMENTAÇÃO                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  FASE 1 - Base                                              │
│  ─────────────                                              │
│  Task 1 (Models) ──► Task 2 (Provider) ──► Task 10 (Persist)│
│                                                              │
│  FASE 2 - UI Principal                                      │
│  ────────────────────                                       │
│  Task 4 (Criar) ──► Task 3 (Tela Principal) ──► Task 9 (Home)│
│                                                              │
│  FASE 3 - Features Secundárias                              │
│  ────────────────────────────                               │
│  Task 5 (Loja) ──► Task 8 (Teks Aventura)                   │
│                                                              │
│  FASE 4 - Complementos                                      │
│  ─────────────────────                                      │
│  Task 6 (Memorial) ──► Task 7 (Config) ──► Task 11 (Notif)  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Changelog

| Versão | Data | Alterações |
|--------|------|------------|
| 1.0 | 25/11/2025 | Documento inicial com 11 tasks |

---

> **Próximo passo**: Iniciar Task 1 (Models)
