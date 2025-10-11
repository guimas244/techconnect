# 🛒 Reestruturação da Casa do Vigarista - Documento Técnico

**Data:** 2025-10-11
**Status:** 🔴 Loja quebrada - Necessita reestruturação completa
**Problema Principal:** Modais empilhados + context inválido + race conditions

---

## 📋 Índice

1. [Regras de Negócio da Loja](#regras-de-negócio-da-loja)
2. [Estrutura Atual (Problemática)](#estrutura-atual-problemática)
3. [Produtos Disponíveis](#produtos-disponíveis)
4. [Fluxos de Compra](#fluxos-de-compra)
5. [Problemas Identificados](#problemas-identificados)
6. [Arquitetura Proposta para Nova Loja](#arquitetura-proposta-para-nova-loja)
7. [Detalhes de Implementação](#detalhes-de-implementação)

---

## 🎯 Regras de Negócio da Loja

### **Custos Dinâmicos por Tier**

```dart
// Tier 1-10: multiplicador normal
// Tier 11+: multiplicador x2

custoAposta = 2 * (tier >= 11 ? 2 : tier)
custoCura = 1 * (tier >= 11 ? 2 : tier)
custoFeirao = (tier >= 11 ? 2 : tier) * 1.5 (arredondado para cima)
```

**Exemplos:**
- Tier 1: Aposta=2, Cura=1, Feirão=2
- Tier 5: Aposta=10, Cura=5, Feirão=8
- Tier 11: Aposta=4, Cura=2, Feirão=3
- Tier 15: Aposta=4, Cura=2, Feirão=3

### **Moeda**
- **Score:** Obtido através de batalhas e derrotas de monstros
- Score é debitado **ANTES** de gerar o item/magia
- Se a transação falhar, score **não deve ser devolvido** (jogador assume o risco)

### **Restrições**
- ✅ Jogador precisa ter aventura iniciada
- ✅ Jogador precisa ter score suficiente
- ❌ Não pode comprar enquanto outra compra está em andamento (`_comprando` flag)
- ✅ Todos os 3 monstros devem estar disponíveis para equipar

---

## 📦 Produtos Disponíveis

### **1. Item Misterioso** (Aposta Básica)
- **Custo:** `custoAposta`
- **Resultado:** 1 item aleatório baseado no tier atual
- **Ação:** Jogador pode equipar em 1 dos 3 monstros ou descartar

### **2. Magia Ancestral** (Aposta Básica)
- **Custo:** `custoAposta`
- **Resultado:** 1 habilidade aleatória baseada no tier atual
- **Ação:** Jogador escolhe monstro + habilidade a substituir

### **3. Cura da Vida** (Aposta de Cura)
- **Custo:** `custoCura`
- **Resultado:** Porcentagem de cura aleatória (1-100%)
- **Ação:** Jogador escolhe 1 monstro para curar

### **4. Feirão** (3 Itens)
- **Custo:** `custoFeirao` (pago na abertura)
- **Resultado:** 3 itens aleatórios exibidos
- **Ação:** Jogador pode comprar 1 ou mais itens (custo adicional: `custoAposta` por item)
- **Observação:** Feirão fecha após comprar ou clicar em "SAIR"

### **5. Biblioteca** (3 Magias)
- **Custo:** `custoFeirao` (pago na abertura)
- **Resultado:** 3 habilidades aleatórias exibidas
- **Ação:** Jogador pode comprar 1 ou mais magias (custo adicional: `custoAposta` por magia)
- **Observação:** Biblioteca fecha após comprar ou clicar em "SAIR"

---

## 🔄 Fluxos de Compra

### **Fluxo 1: Compra Unitária (Item/Magia/Cura)**

```
[Casa do Vigarista]
       ↓
   Usuário clica em produto
       ↓
   Modal de Confirmação (opcional)
       ↓
   ✅ Confirma
       ↓
   1. Debita score
   2. Gera item/magia/cura aleatório
   3. Salva história no repositório (HIVE + Drive)
   4. ❌ FECHA Casa do Vigarista
   5. ✅ ABRE Modal de Resultado (ModalItemObtido/ModalMagiaObtida/ModalCuraObtida)
       ↓
   Usuário equipar/curar
       ↓
   Modal de Resultado fecha
       ↓
   [Volta para Mapa de Aventura]
```

### **Fluxo 2: Feirão**

```
[Casa do Vigarista]
       ↓
   Usuário clica em "Feirão"
       ↓
   Modal de Confirmação
       ↓
   ✅ Confirma
       ↓
   1. Debita custoFeirao
   2. Gera 3 itens aleatórios
   3. Salva história no repositório
   4. ❌ FECHA Casa do Vigarista
   5. ✅ ABRE Modal do Feirão (3 itens + botões comprar)
       ↓
   Usuário clica em "Comprar" em 1 item
       ↓
   1. Debita custoAposta
   2. Salva história no repositório
   3. ❌ FECHA Modal do Feirão
   4. ✅ ABRE Modal de Resultado (ModalItemObtido)
       ↓
   Usuário equipar item
       ↓
   [Volta para Mapa de Aventura]
```

### **Fluxo 3: Biblioteca**

```
[Casa do Vigarista]
       ↓
   Usuário clica em "Biblioteca"
       ↓
   1. Debita custoFeirao
   2. Gera 3 magias aleatórias
   3. Salva história no repositório
   4. ✅ ABRE Modal da Biblioteca (3 magias + botões comprar)
   5. ⚠️ Casa do Vigarista permanece aberta (problema!)
       ↓
   Usuário clica em "Comprar" em 1 magia
       ↓
   1. Debita custoAposta
   2. Salva história no repositório
   3. ❌ FECHA Modal da Biblioteca
   4. ✅ ABRE Modal de Resultado (ModalMagiaObtida)
       ↓
   Usuário equipar magia
       ↓
   [Volta para Mapa de Aventura]
```

---

## ❌ Problemas Identificados

### **1. Arquitetura de Modais Empilhados**

**Problema:**
```
[MapaAventura Screen]
  └─ [Casa do Vigarista Modal] (context A)
      └─ [Modal do Feirão] (context B)
          └─ [Modal de Item Obtido] (context C) ❌ context A já morreu!
```

**Causa:**
- Fechar `context A` invalida todos os contexts derivados
- Tentar abrir modal com context morto = tela preta ou erro

### **2. Race Condition no Navigator**

**Problema:**
```dart
widget.onHistoriaAtualizada(historia); // Async - não aguarda
Navigator.pop(); // Fecha imediatamente
// Race condition: setState do pai + Navigator lock
```

**Causa:**
- `onHistoriaAtualizada()` chama `setState()` no `MapaAventuraScreen`
- Se Navigator está fechando ao mesmo tempo = `!_debugLocked` assertion

### **3. setState após dispose()**

**Problema:**
```dart
Navigator.pop(); // Widget desmontado
SchedulerBinding.addPostFrameCallback(() {
  setState(...); // ❌ Widget já não existe!
});
```

**Causa:**
- Callbacks tentam modificar widget que já foi destruído

### **4. Erro de Geometria (glassmorphism)**

**Problema:**
```
RRect._raw(): Failed assertion: line 1252 pos 15
```

**Causa:**
- Durante destruição da Casa do Vigarista, o `glassmorphism` tenta renderizar com dimensões inválidas
- Isso trava o ciclo de renderização

### **5. Context Inválido**

**Problema:**
```dart
final navigatorContext = Navigator.of(context, rootNavigator: true).context;
Navigator.pop(); // Destrói context
await Future.delayed(...); // Delay
showDialog(context: navigatorContext); // ❌ Context pode estar inválido
```

**Causa:**
- Mesmo capturando `rootNavigator`, o context pode ser invalidado durante operações assíncronas

---

## 🏗️ Arquitetura Proposta para Nova Loja

### **Princípios de Design**

1. ✅ **Sem Empilhamento de Modais:** Apenas 1 modal ativo por vez
2. ✅ **Navegação Limpa:** Sempre fechar antes de abrir novo
3. ✅ **Await em Callbacks:** Sempre aguardar `onHistoriaAtualizada()`
4. ✅ **Context Seguro:** Usar context da tela pai ou GlobalKey
5. ✅ **Sem SchedulerBinding:** Usar `await Future.delayed()` ou callbacks diretos

### **Nova Estrutura de Navegação**

```
[MapaAventura Screen] (context root - sempre válido)
       ↓
   Abre: Casa do Vigarista
       ↓
   Fecha: Casa do Vigarista
       ↓
   Abre: Modal de Resultado (usando context root)
       ↓
   Fecha: Modal de Resultado
       ↓
   [Volta para MapaAventura]
```

### **Opções de Implementação**

#### **Opção A: Callback de Navegação**
```dart
class CasaVigaristaModal extends StatefulWidget {
  final Function(Item item, HistoriaJogador historia) onItemObtido;
  final Function(Habilidade habilidade, HistoriaJogador historia) onMagiaObtida;
  // ...
}

// No MapaAventura:
showDialog(
  context: context,
  builder: (context) => CasaVigaristaModal(
    onItemObtido: (item, historia) {
      Navigator.pop(context); // Fecha loja
      _mostrarModalItem(item, historia); // Abre modal item
    },
  ),
);
```

**Vantagens:**
- ✅ Context sempre válido (do MapaAventura)
- ✅ Controle total no pai
- ✅ Fácil de testar

**Desvantagens:**
- ❌ Muitos callbacks

#### **Opção B: Navigator Return Value**
```dart
// Na loja:
Navigator.pop(context, {
  'tipo': 'item',
  'item': item,
  'historia': historia,
});

// No MapaAventura:
final resultado = await showDialog(...);
if (resultado != null) {
  if (resultado['tipo'] == 'item') {
    _mostrarModalItem(resultado['item'], resultado['historia']);
  }
}
```

**Vantagens:**
- ✅ Menos código
- ✅ Pattern nativo do Flutter

**Desvantagens:**
- ❌ Menos type-safe

#### **Opção C: State Management (Provider/Riverpod)**
```dart
// Provider para gerenciar estado da loja
class LojaProvider extends ChangeNotifier {
  Item? itemPendente;
  HistoriaJogador? historiaPendente;

  void setItemObtido(Item item, HistoriaJogador historia) {
    itemPendente = item;
    historiaPendente = historia;
    notifyListeners();
  }
}

// No MapaAventura:
final lojaProvider = Provider.of<LojaProvider>(context);
if (lojaProvider.itemPendente != null) {
  SchedulerBinding.addPostFrameCallback(() {
    _mostrarModalItem(lojaProvider.itemPendente!, lojaProvider.historiaPendente!);
    lojaProvider.clear();
  });
}
```

**Vantagens:**
- ✅ Desacoplado
- ✅ Escalável

**Desvantagens:**
- ❌ Mais complexo
- ❌ Overhead desnecessário para caso simples

---

## **✅ SOLUÇÃO RECOMENDADA: Opção B (Navigator Return Value)**

Mais simples, idiomático e resolve todos os problemas.

---

## 🔧 Detalhes de Implementação

### **1. Estrutura de Retorno da Loja**

```dart
class ResultadoLoja {
  final TipoResultado tipo; // item, magia, cura, nenhum
  final Item? item;
  final Habilidade? habilidade;
  final int? porcentagemCura;
  final HistoriaJogador historiaAtualizada;

  ResultadoLoja({
    required this.tipo,
    this.item,
    this.habilidade,
    this.porcentagemCura,
    required this.historiaAtualizada,
  });
}

enum TipoResultado { item, magia, cura, nenhum }
```

### **2. Casa do Vigarista - Retorno**

```dart
class CasaVigaristaModalV3 extends StatefulWidget {
  // Remove callbacks onHistoriaAtualizada
  // Remove modals aninhados
}

// Ao comprar item:
void _apostarItem() async {
  // 1. Debita score
  final historiaAtualizada = _historiaAtual.copyWith(...);

  // 2. Gera item
  final item = _itemService.gerarItemAleatorio(...);

  // 3. Retorna via Navigator
  Navigator.of(context).pop(ResultadoLoja(
    tipo: TipoResultado.item,
    item: item,
    historiaAtualizada: historiaAtualizada,
  ));
}
```

### **3. MapaAventura - Processamento do Resultado**

```dart
void _abrirLoja() async {
  final resultado = await showDialog<ResultadoLoja>(
    context: context,
    builder: (context) => CasaVigaristaModalV3(historia: historiaAtual!),
  );

  if (resultado == null) return; // Usuário fechou sem comprar

  // Salva história
  await _salvarHistoria(resultado.historiaAtualizada);

  // Atualiza estado local
  setState(() {
    historiaAtual = resultado.historiaAtualizada;
  });

  // Aguarda frame
  await Future.delayed(const Duration(milliseconds: 100));

  // Abre modal apropriado baseado no tipo
  switch (resultado.tipo) {
    case TipoResultado.item:
      _mostrarModalItem(resultado.item!, resultado.historiaAtualizada);
      break;
    case TipoResultado.magia:
      _mostrarModalMagia(resultado.habilidade!, resultado.historiaAtualizada);
      break;
    case TipoResultado.cura:
      _mostrarModalCura(resultado.porcentagemCura!, resultado.historiaAtualizada);
      break;
    case TipoResultado.nenhum:
      break;
  }
}
```

### **4. Feirão/Biblioteca - Retorno em Cadeia**

```dart
// Ao abrir Feirão:
void _abrirFeirao() async {
  // Gera itens
  final itens = [...];

  // Retorna para abrir modal do Feirão
  Navigator.of(context).pop(ResultadoLoja(
    tipo: TipoResultado.abrirFeirao,
    itensFeirao: itens,
    historiaAtualizada: historiaAtualizada,
  ));
}

// No MapaAventura:
if (resultado.tipo == TipoResultado.abrirFeirao) {
  await _salvarHistoria(resultado.historiaAtualizada);

  final itemComprado = await showDialog<ResultadoItemFeirao>(
    context: context,
    builder: (context) => ModalFeirao(itens: resultado.itensFeirao),
  );

  if (itemComprado != null) {
    _mostrarModalItem(itemComprado.item, itemComprado.historia);
  }
}
```

---

## 📝 Checklist de Implementação

### **Fase 1: Estrutura Base**
- [ ] Criar `ResultadoLoja` class
- [ ] Criar `TipoResultado` enum
- [ ] Criar `CasaVigaristaModalV3` (cópia limpa da V2)
- [ ] Remover todos callbacks `onHistoriaAtualizada` do modal
- [ ] Remover todos `showDialog` dentro do modal

### **Fase 2: Compras Unitárias**
- [ ] Implementar `_apostarItem()` com Navigator.pop + ResultadoLoja
- [ ] Implementar `_apostarMagia()` com Navigator.pop + ResultadoLoja
- [ ] Implementar `_apostarCura()` com Navigator.pop + ResultadoLoja
- [ ] Testar cada compra isoladamente

### **Fase 3: Feirão**
- [ ] Implementar `_abrirFeirao()` com retorno
- [ ] Criar `ModalFeiraoV2` que também retorna via Navigator
- [ ] Integrar fluxo completo no MapaAventura
- [ ] Testar Feirão end-to-end

### **Fase 4: Biblioteca**
- [ ] Implementar `_abrirBiblioteca()` com retorno
- [ ] Criar `ModalBibliotecaV2` que também retorna via Navigator
- [ ] Integrar fluxo completo no MapaAventura
- [ ] Testar Biblioteca end-to-end

### **Fase 5: Polimento**
- [ ] Remover `CasaVigaristaModalV2` antiga
- [ ] Remover métodos `_mostrarResultado*()` obsoletos
- [ ] Adicionar logs de debug
- [ ] Adicionar tratamento de erros robusto
- [ ] Testar todos os fluxos múltiplas vezes

---

## 🎨 Notas de UI

### **Animações Mantidas**
- Partículas de fundo (`_particleController`)
- Background animado (`_backgroundController`)
- Glassmorphism (verificar se causa problemas)

### **Componentes Reutilizáveis**
- `GerenciadorEquipamentosMonstros` - Grid de 3 monstros (já implementado)
- `ModalItemObtido` - Modal de equipar item (já implementado)
- `ModalMagiaObtida` - Modal de equipar magia (já implementado)
- `ModalCuraObtida` - Modal de curar monstro (já implementado)

### **Melhorias Futuras**
- Feedback visual de loading durante saves
- Animação de transição entre modais
- Confirmação visual de "score debitado"
- Preview do item antes de comprar (no Feirão)

---

## 📚 Referências Importantes

### **Arquivos Principais**
- `casa_vigarista_modal_v2.dart` - Loja atual (quebrada)
- `mapa_aventura_screen.dart` - Tela pai (onde loja é aberta)
- `modal_item_obtido.dart` - Modal de equipar item
- `modal_magia_obtida.dart` - Modal de equipar magia
- `modal_cura_obtida.dart` - Modal de curar
- `item_service.dart` - Gerador de itens
- `gerador_habilidades.dart` - Gerador de habilidades

### **Modelos**
- `HistoriaJogador` - Estado do jogador
- `Item` - Equipamento
- `Habilidade` - Magia/habilidade
- `MonstroAventura` - Monstro do jogador

---

**FIM DO DOCUMENTO**

_Este documento será atualizado conforme a implementação progride._
