#!/bin/bash
# Force Build Script - Bypass git issues
# OpenScan Indigenous Communities

set -e

echo "🔧 OpenScan Force Build Script"
echo "================================"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para ejecutar comandos ignorando git warnings
run_command() {
    local cmd="$1"
    local desc="$2"

    echo -e "${YELLOW}➤${NC} $desc"

    # Redirigir stderr de git a /dev/null pero mantener otros errores
    eval "$cmd" 2> >(grep -v "fatal: no es un repositorio git" >&2) || {
        echo -e "${RED}✗ Error ejecutando: $desc${NC}"
        return 1
    }

    echo -e "${GREEN}✓ Completado${NC}"
    echo ""
}

# Configurar variable de entorno para deshabilitar git
export FLUTTER_GIT_URL=""
export GIT_TRACE=0

echo "📍 Directorio actual: $(pwd)"
echo ""

# Verificar Flutter
echo "🔍 Verificando Flutter..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter no encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter encontrado${NC}"
echo ""

# Verificar archivos críticos
echo "📋 Verificando archivos críticos..."
FILES=(
    "lib/main.dart"
    "lib/data/local/database/app_database.dart"
    "lib/data/local/database/app_database.g.dart"
    "assets/census/persons.csv"
    "pubspec.yaml"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file ${RED}FALTANTE${NC}"
        exit 1
    fi
done
echo ""

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
rm -rf build/
rm -rf .dart_tool/
rm -f pubspec.lock
echo -e "${GREEN}✓ Build limpiado${NC}"
echo ""

# Flutter pub get (con timeout)
echo "📦 Instalando dependencias..."
echo "⚠️  Esto puede tomar varios minutos..."
echo ""

# Usar timeout y capturar exit code
timeout 300 flutter pub get 2>&1 | grep -v "fatal: no es un repositorio git" || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo -e "${RED}✗ Timeout esperando pub get${NC}"
        exit 1
    elif [ $EXIT_CODE -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Pub get completó con warnings${NC}"
    fi
}

# Verificar que se crearon los archivos necesarios
if [ -d ".dart_tool" ]; then
    echo -e "${GREEN}✓ Dependencias instaladas${NC}"
else
    echo -e "${YELLOW}⚠️  .dart_tool no creado, pero continuando...${NC}"
fi
echo ""

# Build APK
echo "🔨 Construyendo APK..."
echo "⚠️  Esto tomará 5-10 minutos en la primera ejecución..."
echo ""

# Build con verbose para ver progreso
timeout 600 flutter build apk --release --verbose 2>&1 | \
    grep -v "fatal: no es un repositorio git" | \
    grep --line-buffered -E "(Building|Running|Assembling|Built|Error|Exception)" || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo -e "${RED}✗ Timeout esperando build${NC}"
        exit 1
    fi
}

echo ""

# Verificar APK generado
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✓ APK generado exitosamente${NC}"
    echo ""
    echo "📦 APK Details:"
    echo "   Path: $APK_PATH"
    echo "   Size: $APK_SIZE"
    echo ""
    echo "📱 Para instalar en dispositivo:"
    echo "   adb install $APK_PATH"
    echo ""
    echo -e "${GREEN}🎉 BUILD EXITOSO${NC}"
else
    echo -e "${RED}✗ APK no generado${NC}"
    echo ""
    echo "🔍 Archivos en build/app/outputs:"
    ls -lh build/app/outputs/ 2>/dev/null || echo "Directorio no existe"
    exit 1
fi
