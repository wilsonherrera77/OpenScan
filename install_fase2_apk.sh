#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════
# SCRIPT DE INSTALACIÓN - Lumara v5.6.1 Fase 2
# ═══════════════════════════════════════════════════════════════════════
# Fecha: 2025-10-31
# Features: Session Tracking + Review Workflow + CSV Export
# ═══════════════════════════════════════════════════════════════════════

set -e  # Exit on error

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  📱 INSTALACIÓN LUMARA v5.6.1 - FASE 2 INTEGRADA"
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar si adb está instalado
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ ERROR: adb no está instalado${NC}"
    echo "Instala con: sudo apt-get install adb"
    exit 1
fi

# Verificar dispositivo conectado
echo -e "${BLUE}🔍 Verificando dispositivo Android...${NC}"
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No se detectó ningún dispositivo Android${NC}"
    echo ""
    echo "Por favor:"
    echo "  1. Conecta tu dispositivo por USB"
    echo "  2. Habilita Depuración USB en Ajustes > Opciones de Desarrollador"
    echo "  3. Acepta la autorización en el dispositivo"
    echo ""
    exit 1
fi

DEVICE_NAME=$(adb devices | grep -v "List" | grep "device$" | head -n1 | awk '{print $1}')
echo -e "${GREEN}✅ Dispositivo detectado: ${DEVICE_NAME}${NC}"
echo ""

# Mostrar opciones
echo "Selecciona la versión a instalar:"
echo ""
echo "  1) DEBUG   (190MB) - Para desarrollo y debugging"
echo "  2) RELEASE (96MB)  - Versión optimizada para producción"
echo ""
read -p "Opción [1-2]: " OPTION

case $OPTION in
    1)
        APK_PATH="$HOME/Descargas/Lumara_v5.6.1_Fase2_DEBUG.apk"
        APK_TYPE="DEBUG"
        ;;
    2)
        APK_PATH="$HOME/Descargas/Lumara_v5.6.1_Fase2_SessionTracking_Reviews_CSVExport.apk"
        APK_TYPE="RELEASE"
        ;;
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

# Verificar que existe el APK
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ ERROR: APK no encontrado en: ${APK_PATH}${NC}"
    exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | awk '{print $1}')
echo ""
echo -e "${BLUE}📦 APK seleccionado: ${APK_TYPE}${NC}"
echo -e "${BLUE}📊 Tamaño: ${APK_SIZE}${NC}"
echo -e "${BLUE}📂 Ruta: ${APK_PATH}${NC}"
echo ""

# Confirmar instalación
read -p "¿Proceder con la instalación? [S/n]: " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "Instalación cancelada."
    exit 0
fi

# Instalar APK
echo ""
echo -e "${YELLOW}⏳ Instalando APK...${NC}"
echo ""

if adb install -r "$APK_PATH" 2>&1 | tee /tmp/adb_install.log; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ INSTALACIÓN EXITOSA${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "📱 Lumara v5.6.1 Fase 2 instalado correctamente"
    echo ""
    echo "🎯 FEATURES NUEVAS INTEGRADAS:"
    echo "   ✅ Session Tracking (Digitizor + Admin Dashboards)"
    echo "   ✅ Review Workflow (Reviewer Dashboard)"
    echo "   ✅ CSV Export (Viewer Dashboard)"
    echo ""
    echo "🧪 TESTING RECOMENDADO:"
    echo ""
    echo "   1️⃣  Session Tracking End-to-End"
    echo "      • Login como DIGITALIZADOR"
    echo "      • Dashboard → Click SessionIndicator → Iniciar Sesión"
    echo "      • Capturar y subir 2-3 documentos"
    echo "      • Verificar badge verde pulsante"
    echo "      • Finalizar sesión"
    echo ""
    echo "   2️⃣  Assignment Review"
    echo "      • Login como REVISOR"
    echo "      • Reviewer Dashboard → Click 'Revisar'"
    echo "      • Probar Aprobar (con quality score 85)"
    echo "      • Probar Rechazar (con feedback)"
    echo ""
    echo "   3️⃣  CSV Export"
    echo "      • Login como VIEWER"
    echo "      • Viewer Dashboard → Click botón Export"
    echo "      • Exportar: Asignaciones, Productividad, Resumen Equipo"
    echo "      • Verificar que se comparten los CSVs"
    echo ""
    echo "📋 BACKEND DEBE ESTAR CORRIENDO:"
    echo "   http://192.168.40.17:8001"
    echo ""
    echo "🔍 MONITOREAR LOGS:"
    echo "   adb logcat | grep -E '(Lumara|Session|CSV|Review)'"
    echo ""

    # Preguntar si iniciar logs
    echo ""
    read -p "¿Iniciar monitoreo de logs ahora? [s/N]: " START_LOGS
    if [[ $START_LOGS =~ ^[Ss]$ ]]; then
        echo ""
        echo -e "${BLUE}📊 Iniciando logs (Ctrl+C para detener)...${NC}"
        echo ""
        adb logcat | grep --color=auto -E "(Lumara|Session|CSV|Review|✅|❌|⏱️)"
    fi

else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ❌ ERROR EN LA INSTALACIÓN${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Detalles del error:"
    cat /tmp/adb_install.log
    echo ""
    exit 1
fi
