#!/bin/bash
# Espera a que el dispositivo Android se conecte

echo "═══════════════════════════════════════════════════════"
echo "⏳ ESPERANDO DISPOSITIVO ANDROID..."
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Por favor en el dispositivo:"
echo "  1. Settings → Developer options → Enable 'USB debugging'"
echo "  2. Acepta el prompt 'Allow USB debugging?'"
echo "  3. Cambia modo USB a 'File Transfer' (no solo 'Charging')"
echo ""
echo "Verificando cada 3 segundos..."
echo ""

# Wait up to 2 minutes for device
for i in {1..40}; do
    DEVICE=$(adb devices | grep -w "device" | awk '{print $1}')
    if [ -n "$DEVICE" ]; then
        echo ""
        echo "✅ ¡DISPOSITIVO DETECTADO!"
        echo "   Device ID: $DEVICE"
        echo ""

        # Get device info
        echo "📱 Información del dispositivo:"
        echo "   Modelo: $(adb shell getprop ro.product.model 2>/dev/null || echo 'N/A')"
        echo "   Android: $(adb shell getprop ro.build.version.release 2>/dev/null || echo 'N/A')"
        echo ""

        # Check if app is installed
        APP_INSTALLED=$(adb shell pm list packages | grep "com.ethereal.lumara" || echo "")
        if [ -n "$APP_INSTALLED" ]; then
            APP_VERSION=$(adb shell dumpsys package com.ethereal.lumara | grep versionName | head -1)
            echo "📦 Lumara instalada: $APP_VERSION"
        else
            echo "⚠️  Lumara NO está instalada"
        fi
        echo ""

        exit 0
    fi

    # Show countdown
    REMAINING=$((120 - i*3))
    echo -ne "\r⏳ Esperando... (${REMAINING}s restantes)    "
    sleep 3
done

echo ""
echo "❌ TIMEOUT: No se detectó dispositivo en 2 minutos"
echo ""
echo "Troubleshooting:"
echo "  1. Verifica que el cable USB transmita datos (no solo carga)"
echo "  2. Prueba otro puerto USB en el servidor"
echo "  3. Reinicia el dispositivo Android"
echo "  4. Ejecuta: adb kill-server && adb start-server"
echo ""
exit 1
