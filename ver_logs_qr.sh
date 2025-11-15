#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "  MONITOR DE LOGS - CONFIGURACIÓN QR LUMARA"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📱 Instrucciones:"
echo "1. Conecta el teléfono por USB"
echo "2. Instala el APK: adb install -r ~/Descargas/Lumara_v5.8.3_QR_DEBUG_LOGGING_*.apk"
echo "3. Abre Lumara en el teléfono"
echo "4. Presiona 'Configurar con QR'"
echo "5. Escanea el código QR mostrado en el navegador"
echo "6. Observa los logs aquí en tiempo real"
echo ""
echo "═══════════════════════════════════════════════════════"
echo "Esperando conexión del dispositivo..."
adb wait-for-device
echo "✅ Dispositivo conectado"
echo ""
echo "Iniciando monitoreo de logs (filtrando por 'QR CONFIG'):"
echo "═══════════════════════════════════════════════════════"
echo ""

# Limpiar logs previos
adb logcat -c

# Mostrar logs filtrados por el debug que agregamos
adb logcat | grep -E "QR CONFIG|QR Data|Server URL|Intento|Conectando a|Status code|Error en intento|Resultado Final|flutter"
