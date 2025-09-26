@echo off
echo ===========================================
echo   Meu Maceteiro - TechTerra
echo ===========================================
echo.
echo Iniciando servidor HTTP local...
echo Aguarde alguns segundos...
echo.

cd /d "%~dp0"

REM Tenta Python 3
python -c "import http.server" 2>nul
if %errorlevel% equ 0 (
    echo Usando Python 3...
    echo.
    echo ✅ Servidor rodando em: http://localhost:8080
    echo.
    echo 🌐 Abra no navegador: http://localhost:8080
    echo.
    echo ⚠️  IMPORTANTE: Use http://localhost:8080 (não file://)
    echo.
    echo 📱 Para parar: Pressione Ctrl+C
    echo ===========================================
    python -m http.server 8080
    goto :end
)

REM Tenta Python 2 (legacy)
python -c "import SimpleHTTPServer" 2>nul
if %errorlevel% equ 0 (
    echo Usando Python 2...
    echo.
    echo ✅ Servidor rodando em: http://localhost:8080
    echo.
    echo 🌐 Abra no navegador: http://localhost:8080
    echo.
    echo ⚠️  IMPORTANTE: Use http://localhost:8080 (não file://)
    echo.
    echo 📱 Para parar: Pressione Ctrl+C
    echo ===========================================
    python -m SimpleHTTPServer 8080
    goto :end
)

REM Se não tem Python
echo ❌ Python não encontrado!
echo.
echo Para instalar Python:
echo 1. Vá em: https://python.org/downloads
echo 2. Baixe e instale Python
echo 3. Marque "Add Python to PATH"
echo 4. Execute este arquivo novamente
echo.
pause

:end
echo.
echo 👋 Servidor encerrado.
pause