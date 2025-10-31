# 🔥 TIER 100+ HARDCORE MODE

## Visão Geral
A partir do **Tier 100**, o jogo entra no **Modo Hardcore**, com mudanças significativas que aumentam drasticamente a dificuldade e as recompensas.

---

## 📋 Mudanças Implementadas

### 1. 🌟 Monstros Nostálgicos (Coleção)
**Localização**: `lib/core/models/atributo_jogo_enum.dart`

**Chances de Spawn**:
- Tier 3-10: **2%**
- Tier 11-99: **4%**
- **Tier 100+: 20%** ✨ NOVO

**Tratamento Especial**:
- Monstros de Halloween **NÃO devem aparecer** quando um Nostálgico for gerado na aventura
- Isso se aplica **APENAS** ao slot de monstro extra (Nostálgico)
- Em outros contextos (roleta, eventos, etc.), Halloween continua aparecendo normalmente

**Código Afetado**:
- `lib/core/models/atributo_jogo_enum.dart` - Adicionar nova faixa de chance para tier 100+
- `lib/features/aventura/data/aventura_repository.dart` - Filtrar monstros de Halloween ao gerar Nostálgico

---

### 2. ⚠️ Aviso de Entrada no Hardcore (Tier 99 → 100)
**Localização**: Sistema de avisos ao subir de andar

**Trigger**: Ao passar do tier 99 para o tier 100

**Mensagem**:
```
🔥 BEM-VINDO AO HARDCORE! 🔥

Você entrou no modo mais difícil do jogo!

⚔️ MUDANÇAS:
• Não ganha mais SCORE dos monstros
• TODOS os inimigos têm passivas de batalha
• 20% de chance de monstros terem item IMPOSSÍVEL
• Elites SEMPRE dropam item IMPOSSÍVEL
• Loja: Cura desabilitada
• 20% de chance de encontrar Nostálgicos

Boa sorte, você vai precisar! 💀
```

**Código Afetado**:
- Arquivo que controla avisos ao subir de tier (precisa localizar)

---

### 3. 📊 Sistema de Score
**Mudança**: A partir do Tier 100, **não ganha mais score** ao derrotar monstros

**Impacto**:
- Score fica congelado no valor alcançado no tier 99
- Jogador não pode mais subir no ranking através de batalhas
- Foco passa a ser coleção e itens raros

**Código Afetado**:
- `lib/features/aventura/presentation/batalha_screen.dart` - Lógica de ganho de score
- Verificar se `tier >= 100` antes de adicionar score

---

### 4. 💀 Passivas Obrigatórias nos Inimigos
**Mudança**: A partir do Tier 100, **TODOS** os monstros inimigos têm passivas

**Antes (Tier < 100)**:
- Tier 11+: 5% de chance de passiva

**Depois (Tier 100+)**:
- 100% de chance de passiva de batalha
- Passivas possíveis: Todas as passivas de batalha disponíveis

**Código Afetado**:
- `lib/features/aventura/data/aventura_repository.dart` - Geração de inimigos
- Método que sorteia passivas para inimigos

---

### 5. 🌟 Itens Impossíveis nos Inimigos
**Mudança**: Chances massivamente aumentadas de itens IMPOSSÍVEL

**Tier 100+ - Monstros Normais**:
- **20% de chance** de ter item IMPOSSÍVEL equipado
- 80% segue tabela normal de raridades

**Tier 100+ - Monstros Elite**:
- **100% de chance** de ter item IMPOSSÍVEL equipado
- Sempre dropa item impossível ao ser derrotado

**Código Afetado**:
- `lib/features/aventura/data/aventura_repository.dart` - Geração de equipamento dos inimigos
- `lib/features/aventura/services/item_service.dart` - Pode precisar de método específico

---

### 6. 🛒 Loja - Cura Desabilitada
**Mudança**: Botão "Comprar Cura" fica **bloqueado** (cinza/desabilitado) a partir do Tier 100

**Visual**:
- Mesmo estilo de quando não tem score suficiente
- Tooltip: "Cura desabilitada no Modo Hardcore (Tier 100+)"

**Código Afetado**:
- Arquivo da loja que exibe o botão de comprar cura
- Adicionar verificação `tier >= 100`

---

## 🔍 Arquivos a Serem Modificados

### 1. **atributo_jogo_enum.dart**
```dart
// Adicionar nova constante
chanceMonstroColecoRaroTier100Plus(min: 20, max: 20), // 20% de chance (tier 100+)
tierBoostMonstroColecoRaroHardcore(min: 100, max: 100), // Segundo boost no tier 100

// Modificar método chanceMonstroColecoRaroPercent
static int chanceMonstroColecoRaroPercent(int tier) {
  if (tier >= AtributoJogo.tierBoostMonstroColecoRaroHardcore.min) {
    return AtributoJogo.chanceMonstroColecoRaroTier100Plus.min; // 20% tier 100+
  }
  if (tier >= AtributoJogo.tierBoostMonstroColecoRaro.min) {
    return AtributoJogo.chanceMonstroColecoRaroTier11Plus.min; // 4% tier 11-99
  }
  return AtributoJogo.chanceMonstroColecoRaro.min; // 2% tier 3-10
}
```

### 2. **aventura_repository.dart**
- Filtrar Halloween ao gerar Nostálgico
- Garantir passivas em todos os inimigos (tier 100+)
- Adicionar chance de 20% de item impossível em inimigos normais (tier 100+)
- Garantir item impossível em elites (tier 100+)

### 3. **batalha_screen.dart**
- Bloquear ganho de score se `tier >= 100`

### 4. **Sistema de Avisos** (arquivo a localizar)
- Adicionar aviso especial ao passar de tier 99 para 100

### 5. **Loja** (arquivo a localizar)
- Desabilitar botão de cura se `tier >= 100`

---

## ✅ Checklist de Implementação

- [x] 1. Localizar todos os arquivos necessários
- [x] 2. Aumentar chance de Nostálgico para 20% (tier 100+)
- [x] 3. Filtrar monstros de Halloween APENAS no spawn de Nostálgico
- [x] 4. Criar aviso de Hardcore (tier 99→100)
- [x] 5. Bloquear ganho de score (tier 100+)
- [x] 6. Garantir passivas em TODOS os inimigos (tier 100+)
- [x] 7. Adicionar 20% chance item impossível em inimigos normais (tier 100+)
- [x] 8. Garantir 100% item impossível em elites (tier 100+)
- [x] 9. Desabilitar cura na loja (tier 100+)
- [ ] 10. Testar todas as mudanças
- [ ] 11. Verificar que Halloween continua aparecendo em outros contextos

---

## ⚠️ Pontos de Atenção

1. **NÃO remover Halloween de outros lugares**, apenas do spawn de Nostálgico
2. **NÃO quebrar sistema de passivas existente** (tier < 100)
3. **NÃO quebrar sistema de score** para tiers < 100
4. **Garantir retrocompatibilidade** com salvamentos existentes
5. **Testar edge cases**: exatamente no tier 100, transição 99→100→101

---

## 🎮 Impacto na Gameplay

**Positivo**:
- Endgame mais desafiador e recompensador
- Maior chance de completar coleção de Nostálgicos
- Itens impossíveis mais acessíveis
- Define um "marco" claro de dificuldade

**Negativo**:
- Impossível subir no ranking após tier 100
- Batalhas muito mais difíceis (todos com passivas)
- Não pode mais curar na loja

**Resultado Esperado**:
- Tier 100+ é para jogadores veteranos que querem desafio máximo
- Foco em coleção e items, não em score
- Estratégia de batalha muito mais importante

---

## 📝 Resumo das Implementações Realizadas

### Arquivos Modificados

#### 1. **lib/core/models/atributo_jogo_enum.dart**
- ✅ Adicionadas novas constantes para tier 100+
  - `chanceMonstroColecoRaroTier100Plus(min: 20, max: 20)` - 20% chance
  - `tierBoostMonstroColecoRaroHardcore(min: 100, max: 100)` - Threshold do hardcore
- ✅ Modificado método `chanceMonstroColecoRaroPercent()` para suportar 3 tiers
  - Tier 3-10: 2%
  - Tier 11-99: 4%
  - Tier 100+: 20% (HARDCORE)

#### 2. **lib/features/aventura/data/aventura_repository.dart**
- ✅ **Linhas 897-904**: Filtro de Halloween no método `_gerarMonstroRaro()`
  - Remove monstros com `colecao == 'halloween'` do pool
  - Apenas para geração de nostálgicos, não afeta outras partes do código
  - Fallback para pool completo se filtro resultar em lista vazia

- ✅ **Linhas 974-1010**: Passivas obrigatórias no método `_sortearPassivaInimigo()`
  - Adicionada verificação `tierAtual >= 100` para modo hardcore
  - Se hardcore: 100% de chance de passiva (pula verificação de 5%)
  - Se tier < 100: Mantém comportamento original (5% de chance)
  - Logging diferenciado para hardcore

- ✅ **Linhas 724-765**: Itens impossíveis para monstros normais
  - Verificação `tierAtual >= 100` no bloco de geração de itens
  - 20% chance de gerar item impossível usando `gerarItemComRaridade()`
  - 80% chance segue fluxo normal com restrições

- ✅ **Linhas 864-874**: Itens impossíveis para elites
  - Verificação `tierAtual >= 100` antes de gerar item elite
  - Se hardcore: 100% item impossível via `gerarItemComRaridade()`
  - Se tier < 100: Usa `gerarItemEliteComRestricoes()` (comportamento original)

#### 3. **lib/features/aventura/presentation/batalha_screen.dart**
- ✅ **Linhas 1006-1026**: Bloqueio de ganho de score
  - Adicionada verificação `historia.tier >= 100`
  - Se hardcore: `scoreGanho = 0` (sem incremento)
  - Se tier < 100: Mantém lógica original (tier ou pontos fixos)
  - Logging específico para hardcore mode

#### 4. **lib/features/aventura/presentation/mapa_aventura_screen.dart**
- ✅ **Linhas 445-528**: Aviso de entrada no Hardcore Mode
  - Detecta transição tier 99 → 100 via `isAndar99`
  - Container vermelho com borda destacada
  - Lista completa de mudanças do hardcore mode
  - Título do modal: "🔥 HARDCORE MODE - Andar 99"
  - Botão de confirmação: "🔥 ENTRAR NO HARDCORE"
  - Mensagem final: "💀 Boa sorte, você vai precisar!"

#### 5. **lib/features/aventura/presentation/casa_vigarista_screen.dart**
- ✅ **Linhas 249-384**: Modificado método `_buildOptionCard()`
  - Adicionado parâmetro `forceDisabled` (default: false)
  - Nova variável `isEnabled` que combina `!forceDisabled && canAfford`
  - Substituídas todas as referências de `canAfford` por `isEnabled`
  - Controla visual (cores, opacidade) e interatividade (onTap)

- ✅ **Linhas 186-194**: Botão de Comprar Cura desabilitado
  - Adicionado parâmetro `forceDisabled: _historiaAtual.tier >= 100`
  - Botão fica cinza e não clicável no tier 100+
  - Mesmo visual de quando não tem score suficiente

### Comportamento Implementado

✅ **Sistema de Nostálgicos**: Chance aumenta progressivamente (2% → 4% → 20%)
✅ **Filtro de Halloween**: Apenas para nostálgicos em aventura, não afeta roleta/eventos
✅ **Aviso Visual**: Modal dramático ao entrar no tier 100 com todas as informações
✅ **Score Congelado**: Jogador para de ganhar score, foco muda para coleção
✅ **Passivas Garantidas**: Todos os inimigos (normais, elite, raros) têm passivas
✅ **Itens Impossíveis**: 20% chance normais, 100% elites - farm de endgame
✅ **Loja Limitada**: Sem cura, jogador precisa gerenciar recursos melhor

### Compilação

✅ Todos os arquivos compilam sem erros
⚠️ 534 avisos informativos (avoid_print, deprecated_member_use)
✅ Nenhum warning crítico ou erro de tipo

---

## 🧪 Testes Necessários

Para validar a implementação, é necessário testar:

1. **Transição Tier 99 → 100**
   - [ ] Modal de aviso aparece corretamente
   - [ ] Todas as informações estão corretas no modal
   - [ ] Botão de confirmação funciona

2. **Sistema de Score**
   - [ ] Score para de incrementar no tier 100
   - [ ] Score continua funcionando no tier 99
   - [ ] Ranking não é atualizado após tier 100

3. **Passivas dos Inimigos**
   - [ ] Todos os inimigos têm passivas no tier 100+
   - [ ] 5% de chance funciona no tier 11-99
   - [ ] Sem passivas no tier 1-10

4. **Itens Impossíveis**
   - [ ] ~20% dos monstros normais têm item impossível
   - [ ] 100% dos elites têm item impossível
   - [ ] Itens normais continuam dropando no tier < 100

5. **Nostálgicos**
   - [ ] Chance de ~20% no tier 100+
   - [ ] Monstros de Halloween NÃO aparecem como nostálgicos
   - [ ] Halloween continua na roleta/eventos

6. **Loja**
   - [ ] Botão de cura fica desabilitado (cinza) no tier 100+
   - [ ] Botão funciona normalmente no tier < 100
   - [ ] Outros botões continuam funcionando

7. **Retrocompatibilidade**
   - [ ] Jogadores em tier < 100 não são afetados
   - [ ] Salvamentos antigos continuam funcionando
   - [ ] Transição suave entre tiers
