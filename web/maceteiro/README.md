# Meu Maceteiro - TechTerra

Uma ferramenta de análise de matchups para o TechTerra com integração ao Google Drive.

## Como usar

### Opção 1: Abrir Diretamente (Recomendado)
```
Abra: D:\workspace\techterra\techterra\web\maceteiro\index.html
```

### Opção 2: Servidor Python
```bash
cd "D:\workspace\techterra\techterra\web\maceteiro"
python server.py
```
Depois acesse: http://localhost:8080

### Opção 3: Live Server (VS Code)
1. Instale a extensão Live Server no VS Code
2. Abra a pasta maceteiro no VS Code
3. Clique com botão direito no index.html → "Open with Live Server"

## Funcionalidades

### Tipagens
- **Carregar Tipagens**: Carrega automaticamente todos os 30 tipos embarcados no JavaScript
- **Carregar do Drive (CORS)**: Carrega tipagens da pasta `tipagens/` (requer servidor HTTP)
- **Upload Manual**: Arraste e solte arquivos JSON ou use o seletor de arquivos
- **Demo**: Carrega dados de demonstração

### Aventuras do Google Drive
- **Login Google**: Autentica com Google usando as credenciais do TechTerra
- **Buscar Aventuras**: Busca automaticamente aventuras na pasta HISTORIAS do dia atual
- **Carregamento Automático**: Acessa `TECH CONNECT > HISTORIAS > YYYY-MM-DD`
- **Suporte a Usuários**: Carrega aventuras de qualquer jogador da data atual

### Análise
- **Análise de Matchups**: Clique nos cards para ver vantagens/desvantagens
- **Suporte a Tiers**: Seleciona diferentes tiers de inimigos
- **Mix Ofensivo**: Ajusta proporção entre tipos de ataque

## Estrutura

```
maceteiro/
├── index.html              # Aplicação principal
├── tipagens_data.js         # 30 tipos embarcados (gerado)
├── tipagens/               # 30 arquivos JSON originais
├── server.py               # Servidor HTTP simples
├── generate_tipagens.py    # Script para regenerar dados
└── README.md               # Este arquivo
```

## Configuração Google Drive

O maceteiro usa as mesmas credenciais do TechTerra:

- **Client ID**: `163239542287-3c3rq1k6j9k1s5fmfauvo2p6q157nbpq.apps.googleusercontent.com`
- **Pasta TECH CONNECT**: `1R_WQTo21NNQyZIj3rMPaaUKj1-eGJPfV`
- **Escopo**: `https://www.googleapis.com/auth/drive.readonly`

### Fluxo de Aventuras

1. **Login**: Clique em "Login Google"
2. **Buscar**: Clique em "Buscar Aventuras"
3. **Auto-detecção**: Busca `TECH CONNECT > HISTORIAS > [data-hoje]`
4. **Seleção**: Se múltiplas aventuras, mostra seletor
5. **Carregamento**: Processa e preenche times automaticamente

## Regenerar Tipagens

Para atualizar os dados embarcados:

```bash
cd "D:\workspace\techterra\techterra\web\maceteiro"
python generate_tipagens.py
```

Isso regenera `tipagens_data.js` com base nos arquivos da pasta `tipagens/`.