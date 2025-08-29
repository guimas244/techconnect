# Configuração Google Sheets para Drops

## 📊 Como configurar o Google Sheets

### Passo 1: Converter Excel para Google Sheets
1. Acesse [Google Drive](https://drive.google.com)
2. Faça upload do arquivo `drops_techterra.xlsx`
3. Clique com botão direito no arquivo → "Abrir com" → "Google Planilhas"
4. O arquivo será convertido automaticamente para Google Sheets
5. Renomeie para `drops_techterra` (sem extensão)

### Passo 2: Obter o ID da Planilha
1. Com a planilha aberta no Google Sheets
2. Copie o ID da URL (parte entre `/d/` e `/edit`):
   ```
   https://docs.google.com/spreadsheets/d/SEU_ID_AQUI/edit
                                        ↑ 
                                    Copie isso
   ```

### Passo 3: Configurar no Sistema
```dart
// No código, configure o ID da planilha
final dropsConfig = DropsConfigService();
dropsConfig.definirIdPlanilha('SEU_ID_DA_PLANILHA_AQUI');
```

### Passo 4: Estrutura da Planilha
Certifique-se que a planilha tenha:
- **Aba**: `Configuracao_Drops`
- **Colunas**:
  - A: `nome`
  - B: `descricao` 
  - C: `tipo`
  - D: `quantidade`
  - E: `raridade`

### Passo 5: Compartilhamento
1. Clique em "Compartilhar" na planilha
2. Adicione a conta de serviço do Google Drive (se necessário)
3. Ou mantenha como "Qualquer pessoa com o link pode visualizar"

## ✅ Vantagens do Google Sheets

- 📝 **Edição online**: Interface amigável para editar
- 🔄 **Sincronização automática**: Mudanças aparecem na hora
- 👥 **Colaboração**: Várias pessoas podem editar
- 📊 **Validação**: Dropdowns e formatação funcionam
- 🚀 **Performance**: API nativa do Google

## 🔧 Como Usar

1. **Editar itens**: Abra a planilha no Google Sheets e edite normalmente
2. **Adicionar itens**: Insira novas linhas com os dados
3. **Alterar raridades**: Use o dropdown na coluna E
4. **Salvar**: Mudanças são salvas automaticamente
5. **Testar**: Próxima premiação usará configuração atual

## 🎯 Raridades Disponíveis
- `inferior` - 35% de chance
- `normal` - 30% de chance  
- `raro` - 20% de chance
- `epico` - 10% de chance
- `lendario` - 5% de chance

## 🚨 Importante
- **Não altere** os nomes das colunas (header)
- **Não renomeie** a aba `Configuracao_Drops`
- **Configure o ID** da planilha no código antes de usar
- O sistema sempre lê a versão mais atual da planilha