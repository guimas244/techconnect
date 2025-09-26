#!/usr/bin/env python3
import http.server
import socketserver
import os

# Muda para o diretório do maceteiro
os.chdir(os.path.dirname(os.path.abspath(__file__)))

PORT = 8080

Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Servindo na porta {PORT}")
    print(f"Acesse: http://localhost:{PORT}")
    print("Pressione Ctrl+C para parar")
    httpd.serve_forever()