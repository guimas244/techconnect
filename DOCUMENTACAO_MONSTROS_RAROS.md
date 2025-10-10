# 🌟 Sistema de Monstros Raros (Nostálgicos)

## Descrição Geral

O sistema de monstros raros permite que jogadores encontrem monstros especiais da **Coleção Nostálgicos** durante a aventura. Estes monstros têm visual diferenciado e são mais difíceis de encontrar que os monstros da coleção inicial.

---

## 📊 Configurações de Spawn

### Localização do Código
**Arquivo**: [`lib/core/models/atributo_jogo_enum.dart`](lib/core/models/atributo_jogo_enum.dart) (linhas 27-32)

### Parâmetros Configuráveis

```dart
// Sistema de descoberta de monstros raros da nova coleção (Nostálgicos)
// Tier 3-10: 2% de chance | Tier 11+: 3% de chance
chanceMonstroColecoRaro(min: 2, max: 2),           // 2% de chance base (tier 3-10)
chanceMonstroColecoRaroTier11Plus(min: 3, max: 3), // 3% de chance (tier 11+)
tierMinimoMonstroColecoRaro(min: 3, max: 3),       // A partir do tier 3
tierBoostMonstroColecoRaro(min: 11, max: 11);      // Boost de chance a partir do tier 11
```

---

## 🎯 Regras de Aparição

### Tier Mínimo
- **Tier 3+**: Monstros nostálgicos podem começar a aparecer
- **Tier 1-2**: Impossível encontrar monstros nostálgicos

### Chance de Spawn por Tier

| Tier       | Chance | Descrição                           |
|------------|--------|-------------------------------------|
| 1-2        | 0%     | Não disponível                      |
| 3-10       | **2%** | Chance base (early/mid game)        |
| 11+        | **3%** | Chance aumentada (endgame)          |

### Fórmula de Sorteio

```dart
// Gera número aleatório de 0-99
sorteio = random.nextInt(100);

// Tier 3-10: sucesso se sorteio < 2 (0 ou 1)
// Tier 11+:  sucesso se sorteio < 3 (0, 1 ou 2)
```

**Exemplos**:
- Tier 5 (chance 2%): Sorteio 1 → ✅ Spawn | Sorteio 2 → ❌ Não spawn
- Tier 11 (chance 3%): Sorteio 2 → ✅ Spawn | Sorteio 3 → ❌ Não spawn

---

## 🔧 Métodos Disponíveis

### `podeGerarMonstroRaro(int tier)`
Verifica se o tier permite spawn de monstros raros.

```dart
AtributoJogo.podeGerarMonstroRaro(5);  // true (tier >= 3)
AtributoJogo.podeGerarMonstroRaro(2);  // false (tier < 3)
```

### `chanceMonstroColecoRaroPercent(int tier)`
Retorna a chance em % baseada no tier.

```dart
AtributoJogo.chanceMonstroColecoRaroPercent(5);   // 2
AtributoJogo.chanceMonstroColecoRaroPercent(11);  // 3
AtributoJogo.chanceMonstroColecoRaroPercent(15);  // 3
```

### `deveGerarMonstroRaro(Random random, int tier)`
Sorteia se deve gerar monstro raro baseado na chance do tier.

```dart
// Tier 7: 2% de chance
AtributoJogo.deveGerarMonstroRaro(random, 7);

// Tier 12: 3% de chance
AtributoJogo.deveGerarMonstroRaro(random, 12);
```

---

## 📁 Estrutura de Assets

### Monstros da Coleção Inicial
```
assets/monstros_aventura/colecao_inicial/
  ├── fogo.png
  ├── agua.png
  ├── planta.png
  └── ...
```

### Monstros da Coleção Nostálgicos
```
assets/monstros_aventura/colecao_nostalgicos/
  ├── fogo.png        (visual diferente)
  ├── agua.png        (visual diferente)
  ├── planta.png      (visual diferente)
  ├── nostalgico.png  (tipo exclusivo)
  └── ...
```

---

## 🎮 Fluxo de Jogo

### 1. Geração de Inimigos (Aventura Repository)
```dart
// A cada novo tier, sorteia monstros inimigos
Future<List<MonstroInimigo>> gerarMonstrosInimigos(int tierAtual) {

  // 1. Gera monstros comuns (sempre)
  monstrosInimigos.addAll(_gerarMonstrosComuns(tierAtual));

  // 2. Gera monstro elite (chance separada)
  if (deveGerarElite()) {
    monstrosInimigos.add(_gerarMonstroElite(tierAtual));
  }

  // 3. Gera monstro raro nostálgico (2% ou 3%)
  if (AtributoJogo.deveGerarMonstroRaro(random, tierAtual)) {
    print('🌟 SORTEIO VENCEU! Gerando monstro RARO da nova coleção');
    monstrosInimigos.add(_gerarMonstroRaro(tierAtual));
  }

  return monstrosInimigos;
}
```

### 2. Batalha e Descoberta
- Jogador enfrenta o monstro raro em batalha
- Ao vencer, o monstro é **desbloqueado** na coleção nostálgicos
- Monstro desbloqueado pode aparecer como monstro do **time do jogador** (60% de chance)

### 3. Persistência
- Monstros nostálgicos desbloqueados são salvos em `ColecaoService`
- Lista mantida por email do jogador
- Sincronizada com Google Drive

---

## 🔄 Probabilidades Acumuladas

### Quantos monstros raros esperar?

Assumindo que o jogador joga **100 batalhas**:

**Tier 3-10** (2% por batalha):
- Média esperada: **2 monstros raros** em 100 batalhas
- Aproximadamente **1 a cada 50 batalhas**

**Tier 11+** (3% por batalha):
- Média esperada: **3 monstros raros** em 100 batalhas
- Aproximadamente **1 a cada 33 batalhas**

---

## 🛠️ Como Ajustar as Chances

### Aumentar para 5% no tier 3-10

```dart
chanceMonstroColecoRaro(min: 5, max: 5),  // Muda de 2 para 5
```

### Aumentar para 7% no tier 11+

```dart
chanceMonstroColecoRaroTier11Plus(min: 7, max: 7),  // Muda de 3 para 7
```

### Mudar tier mínimo para 5

```dart
tierMinimoMonstroColecoRaro(min: 5, max: 5),  // Muda de 3 para 5
```

### Mudar tier do boost para 15

```dart
tierBoostMonstroColecoRaro(min: 15, max: 15),  // Muda de 11 para 15
```

---

## 📝 Logs de Debug

O sistema gera logs detalhados para facilitar debug:

```
🌟 [Repository] Verificando spawn de monstro raro no tier 7...
🌟 [Repository] Pode gerar monstro raro? true
🌟 [Repository] Chance configurada: 2%
🌟 [AtributoJogo] Tier 7 - Chance: 2% | Sorteio: 1 < 2 = true
🌟 [Repository] ✅ SORTEIO VENCEU! Gerando monstro RARO da nova coleção
```

---

## 📚 Referências

### Arquivos Relacionados
- **Configuração**: [`lib/core/models/atributo_jogo_enum.dart`](lib/core/models/atributo_jogo_enum.dart)
- **Geração**: [`lib/features/aventura/data/aventura_repository.dart`](lib/features/aventura/data/aventura_repository.dart) (método `gerarMonstrosInimigos`)
- **Tipos**: [`lib/shared/models/tipo_enum.dart`](lib/shared/models/tipo_enum.dart) (enum `Tipo.nostalgico`)
- **Coleção**: [`lib/features/aventura/services/colecao_service.dart`](lib/features/aventura/services/colecao_service.dart)

### Versão do Sistema
- **Implementado em**: v1.6.0
- **Última atualização**: v1.6.3 (2% tier 3-10, 3% tier 11+)

---

**Última atualização**: 2025-10-10
**Autor**: Sistema TechTerra
