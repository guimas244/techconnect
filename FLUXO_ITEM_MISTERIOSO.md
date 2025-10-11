# 🎁 Fluxo de Compra: Item Misterioso

## Status: ✅ IMPLEMENTADO E FUNCIONAL

---

## 📋 Resumo do Fluxo

```
[Mapa Aventura]
    ↓ Usuário clica no ícone da loja
[Casa do Vigarista Screen] (tela cheia)
    ↓ Usuário clica em "Item Misterioso"
    ↓ Valida: tem score suficiente?
    ↓ ✅ SIM → Processa compra
    │
    ├─ 1. Debita score (custoAposta)
    ├─ 2. Gera item aleatório (baseado no tier)
    ├─ 3. Retorna via Navigator.pop(ResultadoLoja)
    │
[Mapa Aventura] _processarResultadoLoja()
    │
    ├─ 1. Salva história (Hive + Drive)
    ├─ 2. Atualiza estado local (setState)
    ├─ 3. Aguarda 150ms (UI estável)
    ├─ 4. Abre ModalItemObtido
    │
[Modal Item Obtido]
    ↓ Usuário escolhe monstro
    ↓ Usuário clica em "Equipar"
    │
    ├─ 1. Atualiza monstro com item
    ├─ 2. Salva história (Hive + Drive)
    ├─ 3. Atualiza estado local
    ├─ 4. Fecha modal
    │
[Volta para Mapa Aventura] ✅
```

---

## 🔧 Implementação Técnica

### 1. Casa do Vigarista (`casa_vigarista_screen.dart`)

**Método: `_apostarItem()`**
```dart
void _apostarItem() async {
  // Validações
  if (_comprando || _historiaAtual.score < custoAposta) return;

  setState(() => _comprando = true);

  try {
    // 1. Debita score
    final historiaAtualizada = _historiaAtual.copyWith(
      score: _historiaAtual.score - custoAposta,
    );

    // 2. Gera item aleatório
    final item = _itemService.gerarItemAleatorio(
      tierAtual: _historiaAtual.tier
    );

    // 3. Retorna resultado via Navigator
    Navigator.of(context).pop(ResultadoLoja(
      tipo: TipoResultado.item,
      item: item,
      historiaAtualizada: historiaAtualizada,
    ));
  } catch (e) {
    print('❌ Erro ao apostar item: $e');
    setState(() => _comprando = false);
  }
}
```

**Custo:**
```dart
int get custoAposta => 2 * (_historiaAtual.tier >= 11 ? 2 : _historiaAtual.tier);
```

---

### 2. Mapa Aventura (`mapa_aventura_screen.dart`)

**Método: `_mostrarCasaDoVigarista()`**
```dart
Future<void> _mostrarCasaDoVigarista() async {
  final resultado = await Navigator.of(context).push<ResultadoLoja>(
    MaterialPageRoute(
      builder: (context) => CasaVigaristaScreen(historia: historiaAtual!),
    ),
  );

  // Se não houve resultado, retorna
  if (resultado == null || !mounted) return;

  // Processa o resultado
  await _processarResultadoLoja(resultado);
}
```

**Método: `_processarResultadoLoja()`**
```dart
Future<void> _processarResultadoLoja(ResultadoLoja resultado) async {
  print('🛒 [Loja] Processando resultado: ${resultado.tipo}');

  // 1. Salva a história atualizada
  try {
    final repository = ref.read(aventuraRepositoryProvider);
    await repository.salvarHistoricoJogadorLocal(resultado.historiaAtualizada);
    await repository.salvarHistoricoEAtualizarRanking(resultado.historiaAtualizada);
    print('✅ [Loja] História salva com sucesso');
  } catch (e) {
    print('❌ [Loja] Erro ao salvar história: $e');
  }

  // 2. Atualiza estado local
  if (mounted) {
    setState(() {
      historiaAtual = resultado.historiaAtualizada;
    });
  }

  // 3. Aguarda um frame para garantir que a UI está estável
  await Future.delayed(const Duration(milliseconds: 150));

  if (!mounted) return;

  // 4. Abre o modal apropriado
  switch (resultado.tipo) {
    case TipoResultado.item:
      if (resultado.item != null) {
        await _mostrarModalEquiparItem(resultado.item!, resultado.historiaAtualizada);
      }
      break;
    // ... outros casos
  }
}
```

**Método: `_mostrarModalEquiparItem()`**
```dart
Future<void> _mostrarModalEquiparItem(
  Item item,
  HistoriaJogador historia,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ModalItemObtido(
      item: item,
      monstrosDisponiveis: historia.monstros,
      onEquiparItem: (monstro, itemObtido) async {
        // Atualiza o monstro com o item equipado
        final monstrosAtualizados = historia.monstros.map((m) {
          if (m.tipo == monstro.tipo && m.level == monstro.level) {
            return m.copyWith(itemEquipado: itemObtido);
          }
          return m;
        }).toList();

        final historiaAtualizada = historia.copyWith(
          monstros: monstrosAtualizados,
        );

        // Salva a história com o item equipado
        try {
          final repository = ref.read(aventuraRepositoryProvider);
          await repository.salvarHistoricoJogadorLocal(historiaAtualizada);
          await repository.salvarHistoricoEAtualizarRanking(historiaAtualizada);

          if (mounted) {
            setState(() {
              historiaAtual = historiaAtualizada;
            });
          }

          print('✅ [Loja] Item equipado e salvo com sucesso');
        } catch (e) {
          print('❌ [Loja] Erro ao salvar item equipado: $e');
        }

        // Fecha o modal
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    ),
  );
}
```

---

### 3. Modelo de Resultado (`resultado_loja.dart`)

```dart
enum TipoResultado {
  item,
  magia,
  cura,
  abrirFeirao,
  abrirBiblioteca,
  nenhum,
}

class ResultadoLoja {
  final TipoResultado tipo;
  final Item? item;
  final MagiaDrop? habilidade;
  final int? porcentagemCura;
  final List<Item>? itensFeirao;
  final List<MagiaDrop>? magiasBiblioteca;
  final HistoriaJogador historiaAtualizada;

  ResultadoLoja({
    required this.tipo,
    this.item,
    this.habilidade,
    this.porcentagemCura,
    this.itensFeirao,
    this.magiasBiblioteca,
    required this.historiaAtualizada,
  });
}
```

---

## ✅ Benefícios da Arquitetura

1. **Sem Empilhamento de Modais**: Cada modal é aberto sequencialmente
2. **Context Sempre Válido**: Usa context do MapaAventura (root)
3. **Navegação Limpa**: Navigator.pop() + return value
4. **Type-Safe**: ResultadoLoja com tipos definidos
5. **Fácil de Testar**: Fluxo linear e previsível
6. **Sem Race Conditions**: Await em todas operações assíncronas
7. **Sem setState após dispose**: Sempre verifica `mounted`

---

## 🎮 Como Testar

1. Abra o app e inicie uma aventura
2. Acumule score derrotando monstros
3. Clique no ícone da Casa do Vigarista no mapa
4. Clique em "Item Misterioso"
5. Confirme que:
   - ✅ Score foi debitado
   - ✅ Loja fechou
   - ✅ Modal de item abriu
   - ✅ Pode escolher monstro
   - ✅ Item é equipado
   - ✅ Modal fecha
   - ✅ Volta para o mapa
   - ✅ Item está visível no monstro

---

## 📊 Logs Esperados

```
🛒 [Loja] Processando resultado: TipoResultado.item
✅ [Loja] História salva com sucesso
✅ [Loja] Item equipado e salvo com sucesso
```

---

## 🐛 Possíveis Problemas

### ❌ "Sem score suficiente"
- **Causa**: Score < custoAposta
- **Solução**: Derrote mais monstros para ganhar score

### ❌ "Erro ao salvar história"
- **Causa**: Problema com Hive ou Drive
- **Solução**: Verificar logs e conexão

### ❌ "Context inválido"
- **Causa**: Widget desmontado
- **Solução**: Já tratado com verificações `mounted`

---

**FIM DO DOCUMENTO**

✅ Fluxo de Item Misterioso está 100% implementado e funcional!
