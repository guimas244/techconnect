@echo off
REM Script para build e renomeação automática do APK TechTerra
REM Uso: build_apk.bat

echo 🚀 Iniciando build do APK TechTerra...

REM Lê a versão do pubspec.yaml
for /f "tokens=2 delims: " %%i in ('findstr "version:" pubspec.yaml') do set VERSION_FULL=%%i
for /f "tokens=1 delims=+" %%i in ("%VERSION_FULL%") do set VERSION=%%i

echo 📦 Versão detectada: %VERSION%

REM Executa o build do APK
echo 🔨 Executando flutter build apk --release...
flutter build apk --release

if %errorlevel% equ 0 (
    echo ✅ Build concluído com sucesso!
    
    REM Renomeia o APK para o padrão TechTerra
    set APK_NAME=techterra-v%VERSION%-release.apk
    
    echo 📝 Renomeando APK para: %APK_NAME%
    copy "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\%APK_NAME%"
    
    echo 🎉 APK pronto: build\app\outputs\flutter-apk\%APK_NAME%
    
    REM Mostra o tamanho do arquivo
    for %%A in ("build\app\outputs\flutter-apk\%APK_NAME%") do echo 📊 Tamanho: %%~zA bytes
    
) else (
    echo ❌ Erro no build do APK
    exit /b 1
)

pause