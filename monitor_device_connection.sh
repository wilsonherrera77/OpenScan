#!/bin/bash
# Monitor de conexión de dispositivo Android
# Verifica cada 5 segundos si el dispositivo se conectó

echo "════════════════════════════════════════════════════════════════"
echo "🔍 MONITOR DE DISPOSITIVO ANDROID"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Esperando que completes los pasos en el teléfono..."
echo ""
echo "Checklist:"
echo "  [ ] PASO 1: Opciones de desarrollador habilitadas"
echo "  [ ] PASO 2: USB debugging activado"
echo "  [ ] PASO 3: Modo USB = File Transfer (no solo carga)"
echo "  [ ] PASO 4: Popup de autorización → ACEPTAR"
echo ""
echo "Verificando cada 5 segundos..."
echo "Presiona Ctrl+C para detener"
echo ""
echo "────────────────────────────────────────────────────────────────"

COUNTER=1

while true; do
    echo -ne "\r[$COUNTER] Verificando...                              "

    DEVICE=$(adb devices 2>/dev/null | grep -w "device" | awk '{print $1}')

    if [ -n "$DEVICE" ]; then
        echo ""
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "✅✅✅ ¡DISPOSITIVO DETECTADO! ✅✅✅"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "Device ID: $DEVICE"
        echo ""

        # Get device info
        MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
        ANDROID=$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
        BRAND=$(adb shell getprop ro.product.brand 2>/dev/null | tr -d '\r')

        echo "📱 Información del dispositivo:"
        echo "   Marca: $BRAND"
        echo "   Modelo: $MODEL"
        echo "   Android: $ANDROID"
        echo ""

        # Check if Lumara is installed
        LUMARA=$(adb shell pm list packages 2>/dev/null | grep "com.ethereal.openscan")
        if [ -n "$LUMARA" ]; then
            VERSION=$(adb shell dumpsys package com.ethereal.openscan 2>/dev/null | grep "versionName" | head -1 | awk '{print $1}')
            echo "📦 Lumara instalada: $VERSION"
        else
            echo "⚠️  Lumara NO está instalada"
        fi
        echo ""

        echo "════════════════════════════════════════════════════════════════"
        echo "🎉 ¡TODO LISTO! Claude puede ahora controlar el dispositivo"
        echo "════════════════════════════════════════════════════════════════"
        echo ""

        exit 0
    fi

    COUNTER=$((COUNTER + 1))
    sleep 5
done
