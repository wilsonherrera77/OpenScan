#!/bin/bash
echo "Verificando dispositivo Android..."
adb devices -l
echo ""
DEVICE=$(adb devices | grep -w "device" | awk '{print $1}')
if [ -n "$DEVICE" ]; then
    echo "✅ Dispositivo detectado: $DEVICE"
    adb shell getprop ro.product.model
else
    echo "❌ No hay dispositivo conectado"
    echo ""
    echo "En el dispositivo Android:"
    echo "  1. Settings → About phone → Tap 'Build number' 7 veces"
    echo "  2. Settings → Developer options → Enable 'USB debugging'"
    echo "  3. Acepta el prompt 'Allow USB debugging?'"
    echo "  4. Cambia modo USB a 'File Transfer'"
fi
