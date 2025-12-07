#!/bin/bash
# Filtra y muestra logs relevantes en tiempo real

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
FILTER=${2:-all}

echo "📱 Monitoreando logs de Lumara en dispositivo $DEVICE"
echo "Filtro: $FILTER"
echo ""

case $FILTER in
  "performance")
    adb -s $DEVICE logcat | grep -E "⏱️|🚀|⚡|📊"
    ;;

  "network")
    adb -s $DEVICE logcat | grep -E "🌐|📡|🔌|📶|🔄"
    ;;

  "errors")
    adb -s $DEVICE logcat | grep -E "❌|⚠️|ERROR|Exception"
    ;;

  "optimizations")
    adb -s $DEVICE logcat | grep -E "🖼️|🗜️|💾|✅|⚡ FASE"
    ;;

  "cache")
    adb -s $DEVICE logcat | grep -E "cache|Cache|CACHE|💾"
    ;;

  "retry")
    adb -s $DEVICE logcat | grep -E "retry|Retry|🔄|Circuit|circuit"
    ;;

  "all")
    adb -s $DEVICE logcat | grep -E "Lumara|lumara|lumara"
    ;;

  *)
    echo "❌ Filtro desconocido: $FILTER"
    echo "Filtros válidos: performance, network, errors, optimizations, cache, retry, all"
    exit 1
    ;;
esac
