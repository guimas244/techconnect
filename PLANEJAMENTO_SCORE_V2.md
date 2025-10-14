# 📊 Planejamento: Sistema de Score V2

## 📋 Visão Geral
Implementação de novo sistema de score com limite de 50 pontos até tier 10, reset no tier 11, e pontuação extra até 150 pontos. Inclui sistema de configuração via painel admin.

---

## 🎯 Passo 1: Criar/Atualizar Parâmetros Configuráveis

### Objetivo
Adicionar novos parâmetros ao sistema de configuração existente para controlar limites de score.

### Tarefas
- [ ] Localizar o enum de parâmetros existente
- [ ] Adicionar os seguintes parâmetros:
  - `SCORE_LIMITE_PRE_TIER_11` (valor padrão: **50**)
  - `SCORE_PONTOS_GARANTIDOS_TIER_11` (valor padrão: **50**)
  - `SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS` (valor padrão: **2**)
  - `SCORE_LIMITE_MAXIMO_TOTAL` (valor padrão: **150**)
  - `SCORE_TIER_TRANSICAO` (valor padrão: **11**)
- [ ] Garantir que os valores sejam editáveis via admin (se `ENABLE_TYPE_EDITING = true`)

### Arquivos Envolvidos
- Procurar por enum de parâmetros/configuração (provavelmente em `lib/core/config/` ou similar)

---

## 🎯 Passo 2: Implementar Limite de Score Pré-Tier 11

### Objetivo
Garantir que scores salvos no ranking nunca ultrapassem 50 pontos antes do andar 11.

### Regras
- **Andar 1-10:** Score salvo no ranking = `min(scoreAtual, 50)`
- **Andar 11+:** Score salvo = 50 garantidos + score extra (até 150 total)

### Tarefas
- [ ] Localizar onde o score é salvo no ranking (`ranking_service.dart`)
- [ ] Adicionar lógica de verificação de tier:
  ```dart
  int scoreSalvar;
  if (tier < 11) {
    // Pré-tier 11: limite de 50
    scoreSalvar = min(scoreAtual, SCORE_LIMITE_PRE_TIER_11);
  } else {
    // Tier 11+: 50 garantidos + score extra (máx 150 total)
    scoreSalvar = min(SCORE_PONTOS_GARANTIDOS_TIER_11 + scoreAtual, SCORE_LIMITE_MAXIMO_TOTAL);
  }
  ```
- [ ] Testar cenários:
  - Tier 5 com 45 pontos → Salva **45**
  - Tier 6 com 67 pontos → Salva **50**
  - Tier 7 com 44 pontos → Salva **44**
  - Tier 11 com 0 pontos → Salva **50**
  - Tier 12 com 10 pontos → Salva **60** (50 + 10)
  - Tier 12 com 4 pontos → Salva **54** (50 + 4)

### Arquivos Envolvidos
- `lib/features/aventura/services/ranking_service.dart`
- `lib/features/aventura/data/aventura_repository.dart`

---

## 🎯 Passo 3: Adicionar Mensagem de Alerta ao Atingir 50 Pontos

### Objetivo
Mostrar mensagem informativa quando o jogador atinge 50 pontos pela primeira vez em uma aventura (antes do tier 11).

### Regras
- **Condição:** `tier < 11` E `scoreAtual >= 50` E mensagem não foi mostrada nesta aventura
- **Frequência:** Apenas 1 vez por aventura
- **Mensagem sugerida:**
  ```
  ⚠️ LIMITE DE SCORE ATINGIDO

  Você atingiu 50 pontos! Este é o limite máximo
  que será salvo no ranking até o andar 11.

  Qualquer score acima de 50 não será contabilizado
  no ranking até você avançar para o andar 11.
  ```

### Tarefas
- [ ] Adicionar flag `bool mensagemLimite50Mostrada` no modelo `HistoriaJogador`
- [ ] Resetar flag ao iniciar nova aventura
- [ ] Verificar após cada batalha vencida:
  ```dart
  if (tier < 11 && scoreAtual >= 50 && !mensagemLimite50Mostrada) {
    _mostrarModalLimiteScore();
    historiaAtualizada = historia.copyWith(mensagemLimite50Mostrada: true);
  }
  ```
- [ ] Criar modal `_mostrarModalLimiteScore()` com design informativo

### Arquivos Envolvidos
- `lib/features/aventura/models/historia_jogador.dart` (adicionar flag)
- `lib/features/aventura/presentation/batalha_screen.dart` (lógica de exibição)
- `lib/features/aventura/presentation/modal_limite_score.dart` (novo arquivo - modal)

---

## 🎯 Passo 4: Melhorar Mensagem de Transição Tier 10 → 11

### Objetivo
Atualizar modal que aparece ao avançar do andar 10 para o 11 com informações claras sobre reset de score.

### Mensagem Proposta
```
🎊 PARABÉNS! VOCÊ ALCANÇOU O ANDAR 11! 🎊

🏆 PONTUAÇÃO FINAL SALVA
Seu score será registrado no ranking como:
• 50 PONTOS GARANTIDOS

⚠️ RESET DE SCORE
Ao entrar no andar 11, seu score voltará para 0.
Porém, os 50 pontos já estão salvos no ranking!

✨ NOVO SISTEMA DE PONTUAÇÃO
A partir do andar 11:
• Cada vitória = +2 pontos extras
• Esses pontos extras podem ultrapassar os 50
• Limite total: 150 pontos (50 garantidos + 100 extras)

Boa sorte no endgame! 🚀
```

### Tarefas
- [ ] Localizar modal de avanço de tier (`mapa_aventura_screen.dart` linha ~1075)
- [ ] Verificar se modal existe ou criar novo
- [ ] Substituir/criar modal com nova mensagem
- [ ] Adicionar animação/destaque visual para os 50 pontos garantidos
- [ ] Confirmar que score é resetado para 0 após fechar modal
- [ ] Confirmar que 50 pontos são salvos no ranking antes do reset

### Arquivos Envolvidos
- `lib/features/aventura/presentation/mapa_aventura_screen.dart`
- `lib/features/aventura/presentation/modal_tier_11_transicao.dart` (novo arquivo - se necessário)

---

## 🎯 Passo 5: Implementar Sistema de Score Tier 11+

### Objetivo
Implementar mecânica de 50 pontos garantidos + score extra com limite de 150.

### Regras
- **Score base:** 50 pontos garantidos (não aparece na UI do jogo)
- **Score visível:** Pontos extras ganhos (0 a 100)
- **Score total salvo:** 50 + scoreExtra (máximo 150)
- **Ganho por vitória:** +2 pontos (conforme já implementado)

### Tarefas
- [ ] **Atualizar UI para mostrar score corretamente:**
  - Tier 1-10: Mostrar score normal (0-50+)
  - Tier 11+: Mostrar "50 + X" ou apenas "X extras"
  - Exemplo: "Score: 50 + 10" ou "Score Extra: 10/100"

- [ ] **Garantir cálculo correto ao salvar ranking:**
  ```dart
  if (tier >= 11) {
    int scoreFinal = SCORE_PONTOS_GARANTIDOS_TIER_11 + scoreExtra;
    scoreFinal = min(scoreFinal, SCORE_LIMITE_MAXIMO_TOTAL);
    salvarNoRanking(scoreFinal);
  }
  ```

- [ ] **Validar limite de 150:**
  - Score extra máximo = 100
  - Bloquear ganho de pontos se `50 + scoreExtra >= 150`
  - Mostrar mensagem ao atingir limite máximo

### Arquivos Envolvidos
- `lib/features/aventura/presentation/aventura_screen.dart` (UI do score)
- `lib/features/aventura/services/ranking_service.dart` (salvar score)
- `lib/features/aventura/presentation/mapa_aventura_screen.dart` (exibição do score)

---

## 🎯 Passo 6: Criar Painel de Configuração Admin

### Objetivo
Adicionar sexta opção no menu admin da home para editar parâmetros de score.

### Requisitos
- **Visibilidade:** Apenas se `DeveloperConfig.ENABLE_TYPE_EDITING == true`
- **Funcionalidade:** Editar valores dos parâmetros criados no Passo 1
- **Persistência:** Salvar alterações em arquivo de configuração ou Hive

### Tarefas
- [ ] Localizar menu admin da home (onde está Drops, Monstros, etc.)
- [ ] Adicionar botão "⚙️ Configurações" ou "📊 Parâmetros Score"
- [ ] Criar tela de edição com:
  - Campo numérico para `SCORE_LIMITE_PRE_TIER_11` (padrão: 50)
  - Campo numérico para `SCORE_PONTOS_GARANTIDOS_TIER_11` (padrão: 50)
  - Campo numérico para `SCORE_PONTOS_POR_VITORIA_TIER_11_PLUS` (padrão: 2)
  - Campo numérico para `SCORE_LIMITE_MAXIMO_TOTAL` (padrão: 150)
  - Campo numérico para `SCORE_TIER_TRANSICAO` (padrão: 11)
- [ ] Adicionar validações:
  - Valores devem ser > 0
  - `SCORE_LIMITE_MAXIMO_TOTAL` > `SCORE_PONTOS_GARANTIDOS_TIER_11`
- [ ] Implementar botão "Salvar" com ícone de check
- [ ] Implementar botão "Restaurar Padrões"
- [ ] Mostrar valores atuais ao abrir a tela

### Arquivos Envolvidos
- `lib/features/home/presentation/home_screen.dart` (adicionar botão no menu admin)
- `lib/features/admin/presentation/config_score_screen.dart` (nova tela de configuração)
- `lib/core/config/developer_config.dart` (ler/escrever configurações)

---

## 🎯 Passo 7: Atualizar Documentação de Regras

### Objetivo
Atualizar o documento `REGRAS_SCORE.md` com as novas mecânicas implementadas.

### Tarefas
- [ ] Atualizar seção "GANHO DE SCORE EM BATALHAS"
- [ ] Adicionar seção "LIMITE DE SCORE PRÉ-TIER 11"
  - Explicar limite de 50 pontos
  - Explicar que score pode ultrapassar 50, mas só salva 50
- [ ] Adicionar seção "TRANSIÇÃO TIER 10 → 11"
  - Explicar reset de score para 0
  - Explicar 50 pontos garantidos salvos no ranking
- [ ] Adicionar seção "SISTEMA DE SCORE TIER 11+"
  - Explicar 50 pontos garantidos (invisíveis)
  - Explicar score extra visível (0-100)
  - Explicar limite total de 150 pontos
- [ ] Atualizar seção "RESUMO VISUAL DAS REGRAS"
- [ ] Adicionar exemplos práticos de cada cenário
- [ ] Adicionar diagramas/flowcharts se necessário

### Arquivos Envolvidos
- `REGRAS_SCORE.md` (documento criado anteriormente)
- Pode criar novo arquivo `REGRAS_SCORE_V2.md` se preferir manter histórico

---

## 🎯 Passo 8: Testes e Validação

### Objetivo
Testar todos os cenários possíveis para garantir funcionamento correto.

### Cenários de Teste

#### 🧪 **Teste 1: Limite 50 Pré-Tier 11**
- [ ] Iniciar aventura no tier 1
- [ ] Vencer batalhas até atingir 45 pontos (tier 5)
- [ ] Verificar ranking: deve mostrar **45 pontos**
- [ ] Vencer mais batalhas até atingir 67 pontos (tier 6)
- [ ] Verificar ranking: deve mostrar **50 pontos** (limite)
- [ ] Gastar pontos na loja até ficar com 44 pontos
- [ ] Verificar ranking: deve mostrar **44 pontos**

#### 🧪 **Teste 2: Mensagem de Alerta 50 Pontos**
- [ ] Iniciar nova aventura
- [ ] Atingir 50 pontos antes do tier 11
- [ ] Verificar se modal aparece **1 vez apenas**
- [ ] Continuar jogando e verificar que modal **não aparece novamente**
- [ ] Iniciar outra aventura nova
- [ ] Atingir 50 pontos novamente
- [ ] Verificar se modal aparece novamente na **nova aventura**

#### 🧪 **Teste 3: Transição Tier 10 → 11**
- [ ] Chegar ao tier 10 com 30 pontos
- [ ] Clicar em "Avançar para Tier 11"
- [ ] Verificar modal com nova mensagem detalhada
- [ ] Verificar ranking: deve mostrar **50 pontos garantidos**
- [ ] Entrar no tier 11
- [ ] Verificar que score voltou para **0**

#### 🧪 **Teste 4: Score Tier 11+ (Garantido + Extra)**
- [ ] Estar no tier 11 com score 0
- [ ] Verificar ranking: deve mostrar **50 pontos**
- [ ] Vencer batalha: ganhar +2 pontos → score vira 2
- [ ] Verificar ranking: deve mostrar **52 pontos** (50 + 2)
- [ ] Vencer mais 4 batalhas → score vira 10
- [ ] Verificar ranking: deve mostrar **60 pontos** (50 + 10)
- [ ] Gastar 6 pontos na loja → score vira 4
- [ ] Verificar ranking: deve mostrar **54 pontos** (50 + 4)

#### 🧪 **Teste 5: Limite Máximo 150 Pontos**
- [ ] Estar no tier 11+ com score extra 95
- [ ] Vencer batalha: ganhar +2 pontos → score extra vira 97
- [ ] Verificar ranking: **147 pontos** (50 + 97)
- [ ] Vencer batalha: ganhar +2 pontos → score extra vira 99
- [ ] Verificar ranking: **149 pontos** (50 + 99)
- [ ] Vencer batalha: tentar ganhar +2 pontos
- [ ] Score deve ficar em **100 extras (150 total)** - não ultrapassar
- [ ] Verificar se aparece mensagem de limite máximo atingido

#### 🧪 **Teste 6: Painel Admin**
- [ ] Ativar `ENABLE_TYPE_EDITING = true`
- [ ] Abrir home → Menu admin
- [ ] Verificar se aparece opção "Configurações Score"
- [ ] Abrir tela de configuração
- [ ] Editar valores:
  - Limite pré-tier 11: 50 → 30
  - Pontos garantidos tier 11: 50 → 40
  - Pontos por vitória tier 11+: 2 → 3
  - Limite máximo: 150 → 120
  - Tier transição: 11 → 10
- [ ] Salvar alterações
- [ ] Jogar e verificar se novos valores estão sendo usados
- [ ] Usar botão "Restaurar Padrões"
- [ ] Verificar se valores voltam ao padrão
- [ ] Desativar `ENABLE_TYPE_EDITING = false`
- [ ] Verificar que opção **não aparece** no menu admin

---

## 🎯 Passo 9: Ajustes Finais e Polimento

### Objetivo
Revisar e polir implementação antes de considerar concluído.

### Tarefas
- [ ] Revisar todos os textos/mensagens para consistência
- [ ] Garantir que logs estão adequados (não muito verboso, mas informativo)
- [ ] Verificar se há código duplicado que pode ser refatorado
- [ ] Validar se todos os parâmetros estão sendo usados corretamente
- [ ] Testar em diferentes tiers e situações edge cases
- [ ] Verificar performance (não deve haver lentidão)
- [ ] Validar que alterações não quebraram funcionalidades existentes

---

## 📦 Passo 10: Documentação e Entrega

### Objetivo
Finalizar documentação e preparar para deploy.

### Tarefas
- [ ] Atualizar `REGRAS_SCORE_V2.md` com versão final
- [ ] Criar/atualizar `CHANGELOG.md` com mudanças:
  ```markdown
  ## [v2.1.1] - Score System V2

  ### Added
  - Limite de 50 pontos no ranking até tier 10
  - Sistema de 50 pontos garantidos + extras no tier 11+
  - Mensagem de alerta ao atingir 50 pontos
  - Modal melhorado na transição tier 10 → 11
  - Painel admin para configurar parâmetros de score
  - Limite máximo de 150 pontos

  ### Changed
  - Score salvo no ranking agora respeita limites por tier
  - Score reseta para 0 ao entrar no tier 11
  - UI de score atualizada para mostrar pontos extras

  ### Fixed
  - Score não ultrapassando limites configurados
  ```
- [ ] Criar guia rápido para testadores
- [ ] Fazer commit final com mensagem descritiva
- [ ] Preparar build de teste

---

## 📊 Checklist Geral de Conclusão

### Funcionalidades Principais
- [ ] ✅ Limite de 50 pontos até tier 10 implementado
- [ ] ✅ Reset de score no tier 11 funcionando
- [ ] ✅ 50 pontos garantidos + extras no tier 11+ funcionando
- [ ] ✅ Limite de 150 pontos implementado
- [ ] ✅ Mensagem de alerta aos 50 pontos funcionando
- [ ] ✅ Modal de transição tier 10→11 atualizado
- [ ] ✅ Painel admin funcionando (com flag de dev)

### Testes
- [ ] ✅ Todos os cenários de teste passaram
- [ ] ✅ Edge cases validados
- [ ] ✅ Não há regressões em funcionalidades existentes

### Documentação
- [ ] ✅ Regras de score atualizadas
- [ ] ✅ Código comentado adequadamente
- [ ] ✅ Changelog atualizado

### Código
- [ ] ✅ Sem warnings ou erros no `flutter analyze`
- [ ] ✅ Código refatorado e limpo
- [ ] ✅ Performance validada

---

## 🚀 Ordem Sugerida de Implementação

1. **Passo 1** (Parâmetros) - Base para tudo
2. **Passo 2** (Limite 50 pré-tier 11) - Lógica core
3. **Passo 5** (Score tier 11+) - Lógica core
4. **Passo 4** (Modal tier 10→11) - UX importante
5. **Passo 3** (Mensagem 50 pontos) - UX complementar
6. **Passo 6** (Painel admin) - Ferramenta de configuração
7. **Passo 7** (Documentação) - Durante implementação
8. **Passo 8** (Testes) - Validação completa
9. **Passo 9** (Ajustes) - Polimento
10. **Passo 10** (Entrega) - Finalização

---

## 📝 Notas Importantes

- **Compatibilidade:** Garantir que aventuras antigas não quebrem com novo sistema
- **Migração:** Se necessário, criar script de migração para dados existentes
- **Rollback:** Manter código anterior comentado caso precise reverter
- **Versionamento:** Considerar incrementar versão major (v2.1.1) pelas mudanças significativas

---

**Documento criado em:** 2025-10-10
**Versão:** 1.0
**Status:** 📋 Planejamento
