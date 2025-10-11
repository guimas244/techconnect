# 🛒 Pendências da Casa do Vigarista - Correções Necessárias

## ✅ Métodos Já Corrigidos e Funcionais

| Método | Status | Correção Aplicada |
|--------|--------|-------------------|
| `_apostarItem()` | ✅ CORRIGIDO | rootNavigator + await callback + inline modal |
| `_apostarMagia()` | ✅ CORRIGIDO | rootNavigator + await callback + inline modal |
| `_apostarCura()` | ✅ CORRIGIDO | rootNavigator + await callback + método auxiliar |

---

## ⚠️ Métodos que AINDA Precisam de Correção

### 1. `_abrirFeirao()` - Linha ~1800
**Problema:** Usa `_mostrarModalFeirao()` com context inválido após `Navigator.pop()`

**Código Atual:**
```dart
Navigator.of(context).pop();
SchedulerBinding.instance.addPostFrameCallback((_) {
  _mostrarModalFeirao(itensFeirao, historiaAtualizada); // ❌ context inválido
});
```

**Solução Necessária:**
- Capturar `rootNavigator` context antes do pop
- Passar context como parâmetro para `_mostrarModalFeirao()`

---

### 2. `_abrirBiblioteca()` - Linha ~1760
**Problema:** Usa `_mostrarModalBiblioteca()` com context inválido após fechar modal

**Código Atual:**
```dart
SchedulerBinding.instance.addPostFrameCallback((_) {
  _mostrarModalBiblioteca(magiasBiblioteca, historiaAtualizada); // ❌ context inválido
});
```

**Solução Necessária:**
- Capturar `rootNavigator` context antes do pop (se aplicável)
- Passar context como parâmetro para `_mostrarModalBiblioteca()`

---

### 3. `_comprarItemFeirao()` - Linha ~2730
**Problema:** Usa `_mostrarResultadoItem()` com context inválido após `Navigator.pop()`

**Código Atual:**
```dart
Navigator.of(context).pop();
SchedulerBinding.instance.addPostFrameCallback((_) {
  _mostrarResultadoItem(item, historiaAtualizada); // ❌ context inválido
});
```

**Solução Necessária:**
- Capturar `rootNavigator` context antes do pop
- Substituir por inline `showDialog()` como feito em `_apostarItem()`

---

### 4. `_comprarMagiaBiblioteca()` - Linha ~2780
**Problema:** Usa `_mostrarResultadoMagia()` com context inválido após `Navigator.pop()`

**Código Atual:**
```dart
Navigator.of(context).pop();
SchedulerBinding.instance.addPostFrameCallback((_) {
  _mostrarResultadoMagia(habilidade, historiaAtualizada); // ❌ context inválido
});
```

**Solução Necessária:**
- Capturar `rootNavigator` context antes do pop
- Substituir por inline `showDialog()` como feito em `_apostarMagia()`

---

## 🎯 Padrão de Correção a Ser Aplicado

### Template de Correção:
```dart
void _metodoCompra() async {
  // 1. Debita e atualiza
  final historiaAtualizada = _historiaAtual.copyWith(...);

  // 2. AWAIT no callback para evitar race condition
  await widget.onHistoriaAtualizada(historiaAtualizada);

  if (!mounted) return;

  // 3. CAPTURA rootNavigator context ANTES de fechar
  final navigatorContext = Navigator.of(context, rootNavigator: true).context;

  // 4. Fecha o modal atual
  Navigator.of(context).pop();

  // 5. Aguarda frame e abre novo modal com context válido
  SchedulerBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: navigatorContext, // ✅ context válido!
      builder: (context) => ModalXYZ(...),
    );
  });
}
```

---

## 🔍 Observações Importantes

### Problemas Identificados:
1. ❌ **Context inválido:** Após `Navigator.pop()`, o `context` do widget é destruído
2. ❌ **Race condition:** Não aguardar `widget.onHistoriaAtualizada()` causa lock no Navigator
3. ❌ **setState após dispose:** Callbacks tentam chamar setState em widgets desmontados

### Soluções Implementadas:
1. ✅ **rootNavigator:** `Navigator.of(context, rootNavigator: true).context`
2. ✅ **await callback:** `await widget.onHistoriaAtualizada()` antes do pop
3. ✅ **mounted check:** Verificar `if (!mounted)` antes de todas as operações

---

## 📊 Status do Projeto

- **Total de métodos:** 7
- **Corrigidos:** 3 (43%)
- **Pendentes:** 4 (57%)
- **Build Status:** ✅ Compila sem erros
- **Análise:** ✅ Apenas warnings de deprecated (withOpacity)

---

## 🚀 Próximos Passos

1. Aplicar correção em `_abrirFeirao()` e `_mostrarModalFeirao()`
2. Aplicar correção em `_abrirBiblioteca()` e `_mostrarModalBiblioteca()`
3. Aplicar correção em `_comprarItemFeirao()`
4. Aplicar correção em `_comprarMagiaBiblioteca()`
5. Testar todos os fluxos end-to-end
6. Remover métodos `_mostrarResultado*()` não utilizados (opcional)

---

**Última atualização:** 2025-10-11
**Arquivo:** `casa_vigarista_modal_v2.dart`
