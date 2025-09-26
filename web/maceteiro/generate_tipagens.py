#!/usr/bin/env python3
import json
import os

# Muda para o diretório do script
script_dir = os.path.dirname(os.path.abspath(__file__))
tipagens_dir = os.path.join(script_dir, 'tipagens')

# Dicionário para armazenar todos os dados
all_tipagens = {}

# Lista todos os arquivos JSON na pasta tipagens
json_files = [f for f in os.listdir(tipagens_dir) if f.endswith('.json')]

print(f"Processando {len(json_files)} arquivos JSON...")

for json_file in json_files:
    file_path = os.path.join(tipagens_dir, json_file)
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            tipo = data.get('tipo', '')
            if tipo:
                all_tipagens[tipo] = data
                print(f"OK {json_file} -> {tipo}")
            else:
                print(f"ERRO {json_file} -> sem tipo")
    except Exception as e:
        print(f"ERRO ao ler {json_file}: {e}")

# Gera o arquivo JavaScript
js_content = f"""// Dados de tipagens gerados automaticamente
// Total: {len(all_tipagens)} tipos

const TIPAGENS_DATA = {json.dumps(all_tipagens, indent=2, ensure_ascii=False)};

// Função para carregar dados embarcados
function carregarTipagensEmbarcadas() {{
  console.log('Carregando tipagens embarcadas...');
  let sucessos = 0;

  for (const [tipo, data] of Object.entries(TIPAGENS_DATA)) {{
    try {{
      applyDefenseJSON(data);
      sucessos++;
    }} catch (error) {{
      console.warn(`Erro ao processar tipo ${{tipo}}:`, error);
    }}
  }}

  renderStatus();
  document.getElementById('resultBox').textContent = `${{sucessos}} tipagens carregadas (dados embarcados).`;
  console.log(`${{sucessos}} tipagens carregadas com sucesso.`);
}}
"""

output_file = os.path.join(script_dir, 'tipagens_data.js')
with open(output_file, 'w', encoding='utf-8') as f:
    f.write(js_content)

print(f"\nArquivo gerado: {output_file}")
print(f"Total de tipos processados: {len(all_tipagens)}")
print(f"Adicione <script src=\"tipagens_data.js\"></script> no HTML")