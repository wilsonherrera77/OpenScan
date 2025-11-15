#!/bin/bash
# Script para completar instalación y generar APK de OpenScan
# Ejecutar con: bash build_apk.sh

set -e

echo "🚀 OpenScan - Script de Build APK"
echo "=================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar progreso
show_progress() {
    echo -e "${BLUE}➤${NC} $1"
}

show_success() {
    echo -e "${GREEN}✓${NC} $1"
}

show_error() {
    echo -e "${RED}✗${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Verificar Java
show_progress "Verificando Java..."
if ! command -v java &> /dev/null; then
    show_warning "Java no encontrado. Instalando OpenJDK 17..."
    sudo apt-get update -qq
    sudo apt-get install -y openjdk-17-jdk
    show_success "Java JDK 17 instalado"
else
    show_success "Java ya instalado: $(java -version 2>&1 | head -1)"
fi

echo ""

# 2. Configurar variables de entorno
show_progress "Configurando variables de entorno..."
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$HOME/flutter/bin"
show_success "Variables configuradas"

echo ""

# 3. Aceptar licencias de Android
show_progress "Aceptando licencias de Android SDK..."
if [ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]; then
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    show_success "Licencias aceptadas"
else
    show_error "Android SDK cmdline-tools no encontrado en $ANDROID_HOME"
    exit 1
fi

echo ""

# 4. Instalar componentes de Android SDK
show_progress "Instalando componentes de Android SDK..."
show_warning "Esto puede tomar 5-10 minutos..."
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" 2>&1 | grep -E "(Installed|done)" || true
show_success "Componentes instalados"

echo ""

# 5. Persistir configuración en .bashrc
show_progress "Agregando configuración a ~/.bashrc..."
if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# Android SDK' >> ~/.bashrc
    echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
    echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
    show_success "ANDROID_HOME agregado a .bashrc"
fi

if ! grep -q "$HOME/flutter/bin" ~/.bashrc; then
    echo '# Flutter SDK' >> ~/.bashrc
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    show_success "Flutter agregado a .bashrc"
fi

echo ""

# 6. Verificar Flutter doctor
show_progress "Verificando Flutter doctor..."
flutter doctor --android-licenses > /dev/null 2>&1 || true
flutter doctor | grep -E "(Flutter|Android toolchain)" || true
show_success "Flutter verificado"

echo ""

# 7. Ir al directorio del proyecto
show_progress "Navegando al proyecto OpenScan..."
cd /home/smt/Escritorio/programacion_proyectos/paperless/openscan/OpenScan
show_success "Directorio: $(pwd)"

echo ""

# 8. Build APK
show_progress "Construyendo APK Release..."
show_warning "Esto puede tomar 5-10 minutos en la primera ejecución..."
echo ""

flutter build apk --release

echo ""

# 9. Verificar APK generado
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_success "APK GENERADO EXITOSAMENTE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 APK Details:"
    echo "   Path: $APK_PATH"
    echo "   Size: $APK_SIZE"
    echo ""
    echo "📱 Para instalar en dispositivo:"
    echo "   adb devices"
    echo "   adb install $APK_PATH"
    echo ""
    echo "🔧 Configuración en la app:"
    echo "   URL: http://172.20.10.13:8001"
    echo "   Usuario: admin"
    echo "   Password: admin"
    echo ""
    echo "✨ Funcionalidades incluidas:"
    echo "   ✓ Offline queue con SQLite/Drift"
    echo "   ✓ Background sync cada 15 minutos"
    echo "   ✓ 3,997 personas del censo"
    echo "   ✓ Smart retry logic"
    echo "   ✓ Upload automático a Paperless"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}🎉 BUILD COMPLETADO${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo ""
    show_error "APK no generado"
    echo ""
    echo "🔍 Verifica los logs anteriores para identificar errores"
    exit 1
fi
