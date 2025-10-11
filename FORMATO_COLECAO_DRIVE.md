# 📦 Formato de Coleção no Google Drive

## Novo Formato (Atual)

O arquivo de coleção no Google Drive agora usa **arrays separados** para cada tipo de coleção.

### Estrutura do Arquivo JSON

**Localização**: `Google Drive/colecao/colecao_{email}.json`

```json
{
  "email": "usuario@exemplo.com",
  "colecoes": {
    "inicial": {
      "agua": false,
      "alien": false,
      "desconhecido": false,
      "deus": false,
      "docrates": false,
      "dragao": false,
      "eletrico": false,
      "fantasma": false,
      "fera": false,
      "fogo": false,
      "gelo": false,
      "inseto": false,
      "luz": false,
      "magico": false,
      "marinho": false,
      "mistico": false,
      "normal": false,
      "nostalgico": false,
      "pedra": false,
      "planta": false,
      "psiquico": false,
      "subterraneo": false,
      "tecnologia": false,
      "tempo": false,
      "terrestre": false,
      "trevas": false,
      "venenoso": false,
      "vento": false,
      "voador": false,
      "zumbi": false
    },
    "nostalgica": {
      "agua": false,
      "alien": false,
      "desconhecido": false,
      "deus": false,
      "docrates": false,
      "dragao": false,
      "eletrico": false,
      "fantasma": false,
      "fera": false,
      "fogo": false,
      "gelo": false,
      "inseto": false,
      "luz": false,
      "magico": false,
      "marinho": false,
      "mistico": false,
      "normal": false,
      "nostalgico": false,
      "pedra": false,
      "planta": false,
      "psiquico": false,
      "subterraneo": false,
      "tecnologia": false,
      "tempo": false,
      "terrestre": false,
      "trevas": false,
      "venenoso": false,
      "vento": false,
      "voador": false,
      "zumbi": false
    },
    "halloween": {
      "agua": false,
      "alien": false,
      "desconhecido": false,
      "deus": false,
      "docrates": false,
      "dragao": false,
      "eletrico": false,
      "fantasma": false,
      "fera": false,
      "fogo": false,
      "gelo": false,
      "inseto": false,
      "luz": false,
      "magico": false,
      "marinho": false,
      "mistico": false,
      "normal": false,
      "nostalgico": false,
      "pedra": false,
      "planta": false,
      "psiquico": false,
      "subterraneo": false,
      "tecnologia": false,
      "tempo": false,
      "terrestre": false,
      "trevas": false,
      "venenoso": false,
      "vento": false,
      "voador": false,
      "zumbi": false
    }
  },
  "ultima_atualizacao": "2025-10-11T20:30:00.000Z"
}
```

---

## Formato Antigo (Compatibilidade)

O sistema ainda suporta o formato antigo para migração automática:

```json
{
  "email": "usuario@exemplo.com",
  "monstros": {
    "agua": false,
    "alien": false,
    "dragao": true,
    "halloween_fantasma": false,
    ...
  },
  "ultima_atualizacao": "2025-10-10T17:32:57.524620"
}
```

Quando um arquivo no formato antigo é carregado, ele é automaticamente convertido para o novo formato no próximo salvamento.

---

## Como Funciona Internamente

### HIVE (Local)

No HIVE, **todas as coleções são armazenadas em um único mapa** com prefixos:

```dart
{
  // Coleção Inicial (sem prefixo)
  "agua": false,
  "fogo": true,

  // Coleção Nostálgica (sem prefixo - mesmos tipos)
  "alien": false,
  "dragao": true,

  // Coleção Halloween (com prefixo 'halloween_')
  "halloween_agua": false,
  "halloween_fantasma": true,
  "halloween_dragao": false,
}
```

### Google Drive (Nuvem)

No Drive, **as coleções são separadas em arrays** para melhor organização:

```json
{
  "colecoes": {
    "inicial": { "agua": false, "fogo": true, ... },
    "nostalgica": { "alien": false, "dragao": true, ... },
    "halloween": { "agua": false, "fantasma": true, ... }
  }
}
```

**Nota**: No Drive, o prefixo `halloween_` é removido. Ele só existe no HIVE.

---

## Fluxo de Salvamento

### ColecaoService.salvarColecaoJogador()

```dart
1. Recebe mapa unificado do HIVE:
   {
     "agua": false,
     "halloween_fantasma": true,
     ...
   }

2. Separa em 3 arrays para o Drive:
   - inicial: monstros sem prefixo que não são nostálgicos
   - nostalgica: monstros da lista estática de nostálgicos
   - halloween: monstros com prefixo 'halloween_' (remove o prefixo)

3. Salva no HIVE (formato unificado)

4. Salva no Drive (formato separado)
```

---

## Fluxo de Carregamento

### ColecaoService.carregarColecaoJogador()

```dart
1. Tenta carregar do HIVE (rápido)
   ✅ Se encontrou → retorna

2. Se não encontrou, carrega do Drive

3. Detecta formato:

   a) Novo formato (com "colecoes"):
      - Carrega array "inicial"
      - Carrega array "nostalgica"
      - Carrega array "halloween" → adiciona prefixo 'halloween_'
      - Unifica tudo em um mapa

   b) Formato antigo (com "monstros"):
      - Carrega como está
      - No próximo save será convertido

4. Salva no HIVE para cache

5. Retorna mapa unificado
```

---

## Listas Estáticas

### ColecaoHiveService

```dart
// 30 monstros nostálgicos
static List<String> get monstrosNostalgicos => [
  'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
  'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
  'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
  'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
  'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi'
];

// 30 monstros Halloween (mesmos tipos)
static List<String> get monstrosHalloween => [
  'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
  'eletrico', 'fantasma', 'fogo', 'gelo', 'inseto', 'luz',
  'magico', 'marinho', 'mistico', 'normal', 'nostalgico', 'pedra',
  'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo', 'terrestre',
  'trevas', 'venenoso', 'vento', 'voador', 'zumbi', 'fera',
];
```

---

## Exemplo de Uso

### Salvar Monstro de Halloween

```dart
// No código (HIVE)
final colecao = await _colecaoService.carregarColecaoJogador(email);
colecao['halloween_dragao'] = true;  // ← Com prefixo
await _colecaoService.salvarColecaoJogador(email, colecao);

// No Drive (resultado)
{
  "colecoes": {
    "halloween": {
      "dragao": true  // ← Sem prefixo
    }
  }
}
```

### Verificar Monstro Desbloqueado

```dart
// Halloween
final temDragao = colecao['halloween_dragao'] == true;

// Nostálgico
final temAlien = colecao['alien'] == true;
```

---

## Migração Automática

Quando um jogador com arquivo antigo joga o jogo:

```
1. Sistema carrega formato antigo do Drive
2. Salva no HIVE (formato unificado)
3. No próximo save, converte automaticamente para novo formato
4. Arquivo no Drive é atualizado com arrays separados
```

**Zero quebras de compatibilidade!** ✅

---

## Assets das Coleções

### Caminhos

```
assets/monstros_aventura/
├── colecao_inicial/       (monstros base)
│   ├── agua.png
│   ├── fogo.png
│   └── ...
├── colecao_nostalgicos/   (monstros nostálgicos)
│   ├── agua.png
│   ├── alien.png
│   └── ...
└── colecao_halloween/     (monstros Halloween)
    ├── agua.png
    ├── fantasma.png
    └── ...
```

### Uso no Código

```dart
// Inicial
'assets/monstros_aventura/colecao_inicial/${tipo.name}.png'

// Nostálgico
'assets/monstros_aventura/colecao_nostalgicos/${tipo.name}.png'

// Halloween
'assets/monstros_aventura/colecao_halloween/${tipo.name}.png'
```

---

## Benefícios do Novo Formato

✅ **Organização**: Arrays separados facilitam visualização no Drive
✅ **Escalabilidade**: Fácil adicionar novas coleções (Natal, Páscoa, etc)
✅ **Compatibilidade**: Suporta formato antigo automaticamente
✅ **Performance**: HIVE usa formato unificado (mais rápido)
✅ **Clareza**: Fica claro quantos monstros de cada coleção estão desbloqueados

---

## Implementado em

- ✅ `colecao_service.dart` - Lógica de salvamento/carregamento
- ✅ `colecao_hive_service.dart` - Listas estáticas e coleção inicial
- ✅ `roleta_halloween_screen.dart` - Sistema de desbloqueio Halloween
- ✅ Compatibilidade total com código existente
