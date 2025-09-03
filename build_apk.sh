#!/bin/bash

# Script para build e renomeação automática do APK TechTerra
# Uso: ./build_apk.sh

echo "🚀 Iniciando build do APK TechTerra..."

# Lê a versão do pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

echo "📦 Versão detectada: $VERSION"

# Executa o build do APK
echo "🔨 Executando flutter build apk --release..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ Build concluído com sucesso!"
    
    # Renomeia o APK para o padrão TechTerra
    APK_NAME="techterra-v${VERSION}-release.apk"
    
    echo "📝 Renomeando APK para: $APK_NAME"
    cp "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/$APK_NAME"
    
    echo "🎉 APK pronto: build/app/outputs/flutter-apk/$APK_NAME"
    echo "📊 Tamanho: $(du -h build/app/outputs/flutter-apk/$APK_NAME | cut -f1)"
    
else
    echo "❌ Erro no build do APK"
    exit 1
fi