# 🎃 Progresso - Implementação Coleção Halloween

## ✅ Concluído

### 1. Backend - Estrutura Base
- ✅ **TipoColecao enum** (`tipo_colecao.dart`)
  - Nostálgico e Halloween
  - Properties: nome, descrição, assetsPath, corTematica, ícone
  - `apareceNoMapa` = false para Halloween (NÃO aparece no mapa)
  - `estaAtiva` = true só em outubro para Halloween

- ✅ **ColecaoHiveService atualizado**
  - 30 monstros Halloween adicionados com prefixo `halloween_`
  - Listas estáticas: `monstrosNostalgicos` e `monstrosHalloween`
  - `criarColecaoInicial()` inclui ambas coleções (60 monstros total)

- ✅ **ColecaoService atualizado**
  - `obterMonstrosHalloweenDesbloqueados()`
  - `contarMonstrosHalloweenDesbloqueados()`

- ✅ **BonusColecaoService criado** (`bonus_colecao_service.dart`)
  - Sistema centralizado de bônus
  - Nostálgicos: +1 HP por monstro (máx +30 HP)
  - Halloween: +1 ATK a cada 5 monstros (máx +6 ATK aos 30)
  - Classe `BonusColecao` com todas as informações

- ✅ **UI - Tela "Minha Coleção" implementada** (`colecao_screen.dart`)
  - TabBar com 2 abas: "Nostálgicos" e **"Eventos"**
  - Aba Eventos mostra 30 monstros específicos da pasta `colecao_halloween`
  - Mapa estático `_monstrosEventos` com nomes específicos de cada monstro
  - GridView 3 colunas com cards
  - Badge de progresso: "X/30 desbloqueados"
  - **Efeito sombra (grayscale)** quando bloqueado, colorido quando desbloqueado
  - Verifica HIVE com prefixo `halloween_` para status de desbloqueio
  - Usa imagens de `assets/monstros_aventura/colecao_halloween/`

- ✅ **UI - Tela "Vantagens" implementada** (`vantagens_screen.dart`)
  - Adicionada coleção Halloween em `VantagensService`
  - Card com emoji 🎃 para identificação
  - Bônus de ataque: +1 ATK a cada 5 monstros (máx +6 aos 30)
  - Cálculo especial no modelo `VantagemColecao` (campo `ehHalloween`)
  - Lógica para contar com prefixo `halloween_`
  - Progresso exibido: "X/30 monstros"
  - Método `obterBonusAtaque()` disponível no service

**✅ CORRIGIDO**: A aba agora se chama "Eventos" e usa as imagens específicas da pasta `colecao_halloween` (não reutiliza da coleção nostálgica).

---

## 📋 Próximos Passos

### 2. Integração - Aplicar Bônus nos Monstros (PRÓXIMO)
**Objetivo**: Fazer os bônus afetarem os stats reais dos monstros na aventura

**Arquivos a modificar**:
- Localizar onde os stats dos monstros são calculados/aplicados
- Adicionar chamada ao `VantagensService.obterBonusAtaque()`

**Exemplo de integração**:
```dart
// Onde calcular ataque do monstro:
final vantagensService = VantagensService();
final bonusAtk = await vantagensService.obterBonusAtaque(email);
final atkFinal = atkBase + bonusAtk;
```

---

### 3. Garantir que Halloween NÃO Apareça no Mapa
**Arquivo**: `lib/features/aventura/presentation/aventura_screen.dart`

**Verificar método `_gerarNovosMonstrosLocal()`**:
- Confirmar que só usa `obterMonstrosNostalgicosDesbloqueados()`
- Adicionar comentário explícito sobre Halloween não aparecer

```dart
// ⚠️ IMPORTANTE: Monstros Halloween NUNCA aparecem no mapa
// Eles são desbloqueados por outros meios (a definir)
final monstrosNostalgicos = await colecaoService.obterMonstrosNostalgicosDesbloqueados(email);
```

---

### 4. Método de Aquisição (FUTURO)
**Aguardando definição**: Como os jogadores desbloquearão monstros Halloween?

Opções:
- Evento especial em outubro
- Missões/quests temáticas
- Compra com moeda especial
- Drop de baús especiais

---

## 🎯 Ordem de Implementação Sugerida

### ✅ Sprint 1 - UI Básico (CONCLUÍDO)
1. ✅ Atualizar tela "Minha Coleção" com abas
2. ✅ Criar grid de 30 cards para Halloween
3. ✅ Mostrar cards bloqueados (placeholder)
4. ✅ Corrigir path de imagens (usar colecao_nostalgicos)

### ~~Sprint 2 - Assets (NÃO NECESSÁRIO)~~
~~Adicionar 30 imagens de monstros Halloween~~

**Motivo**: Monstros Halloween reutilizam imagens dos tipos originais

### ✅ Sprint 3 - Bônus (CONCLUÍDO)
5. ✅ Adicionar coleção Halloween em VantagensService
6. ✅ Atualizar modelo VantagemColecao (campo ehHalloween)
7. ✅ Implementar cálculo especial (+1 ATK a cada 5)
8. ✅ Atualizar UI com emoji 🎃

### Sprint 4 - Integração (PRÓXIMO - 1-2 horas)
9. Aplicar bônus de ataque nos stats dos monstros
10. Testar cálculo de bônus em batalha
11. Adicionar comentários sobre Halloween no código do mapa

### Sprint 5 - Método de Aquisição (Futuro)
12. Implementar forma de desbloquear monstros Halloween
13. (Aguardando definição de como será)

---

## 🔍 Como Testar

### Desbloquear Monstros Halloween Manualmente
```dart
// No ColecaoService, pode adicionar método temporário:
Future<bool> desbloquearHalloweenParaTeste(String email, String nomeMonstro) async {
  return await desbloquearMonstro(email, 'halloween_$nomeMonstro');
}

// Usar no código:
final colecaoService = ColecaoService();
await colecaoService.desbloquearHalloweenParaTeste(email, 'agua');
await colecaoService.desbloquearHalloweenParaTeste(email, 'fogo');
// ... desbloquear vários para testar (5, 10, 15, 20, 25, 30)
```

### Testar Bônus nas Vantagens
1. Desbloquear 5 monstros → verificar "+1 ATK"
2. Desbloquear 10 monstros → verificar "+2 ATK"
3. Desbloquear 30 monstros → verificar "+6 ATK"

### Testar Cálculo de Bônus Programático
```dart
final vantagensService = VantagensService();
final bonusAtk = await vantagensService.obterBonusAtaque(email);
print('Bônus de Ataque Total: +$bonusAtk'); // Deve incluir Halloween
```

---

## 📊 Estrutura de Dados

### No Hive/Drive
```json
{
  "email": "player@example.com",
  "monstros": {
    "agua": true,
    "fogo": false,
    // ... 30 nostálgicos
    "halloween_agua": true,
    "halloween_fogo": false,
    // ... 30 Halloween
  },
  "ultima_atualizacao": "2025-01-11T10:30:00Z"
}
```

### Bônus Calculados
```dart
// Via VantagensService
final bonusAtk = await vantagensService.obterBonusAtaque(email);
// Se 15 Halloween desbloqueados: bonusAtk = 3 (15/5 = 3)

// Nostálgicos continuam dando HP via:
final bonusHp = await vantagensService.obterCuraPosBatalha(email);
// 12 nostálgicos = +12 HP
```

---

## 🎃 Lista de Monstros Halloween (Mesmo Tipos da Coleção Original)

Os 30 monstros Halloween são os mesmos tipos da coleção nostálgica, mas com nomes modificados:

**Exemplos**:
- `agua` → "Água Halloween"
- `fogo` → "Fogo Halloween"
- `dragao` → "Dragão Halloween"
- `fantasma` → "Fantasma Halloween"
- etc.

**Lista completa dos tipos** (30):
```
agua, alien, desconhecido, deus, docrates, dragao,
eletrico, fantasma, fera, fogo, gelo, inseto,
luz, magico, marinho, mistico, normal, nostalgico,
pedra, planta, psiquico, subterraneo, tecnologia, tempo,
terrestre, trevas, venenoso, vento, voador, zumbi
```

**No HIVE, são salvos com prefixo `halloween_`**:
- `halloween_agua` = true/false
- `halloween_fogo` = true/false
- etc.

---

## 🚀 Próxima Ação

**Integrar bônus de ataque nos stats dos monstros**

Localizar onde os atributos dos monstros são calculados e aplicar:
```dart
final vantagensService = VantagensService();
final bonusAtk = await vantagensService.obterBonusAtaque(email);
final atkFinal = atkBase + bonusAtk;
```

**Arquivos prováveis**:
- `lib/features/aventura/models/monstro_aventura.dart`
- `lib/features/aventura/presentation/batalha_screen.dart`
- Qualquer lugar que calcule stats finais dos monstros
