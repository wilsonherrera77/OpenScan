#!/bin/bash
# Simula diferentes condiciones de red con ADB

DEVICE=${1:-$(adb devices | grep -w "device" | awk '{print $1}' | head -1)}
NETWORK_TYPE=${2:-3g}

echo "🌐 Simulando red $NETWORK_TYPE en dispositivo $DEVICE"

case $NETWORK_TYPE in
  "wifi")
    adb -s $DEVICE shell "tc qdisc del dev wlan0 root 2>/dev/null"
    echo "✅ Red WiFi (sin throttling)"
    ;;

  "4g-good")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 30ms rate 10mbit"
    echo "✅ Red 4G buena (10 MB/s, 30ms latency)"
    ;;

  "4g-bad")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 100ms rate 2mbit loss 2%"
    echo "✅ Red 4G mala (2 MB/s, 100ms latency, 2% loss)"
    ;;

  "3g")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 150ms rate 500kbit loss 5%"
    echo "✅ Red 3G (500 KB/s, 150ms latency, 5% loss)"
    ;;

  "edge")
    adb -s $DEVICE shell "tc qdisc replace dev wlan0 root netem delay 300ms rate 100kbit loss 10%"
    echo "✅ Red Edge/2G (100 KB/s, 300ms latency, 10% loss)"
    ;;

  "intermittent")
    echo "✅ Red intermitente (toggle cada 10s)"
    for i in {1..5}; do
      adb -s $DEVICE shell "svc wifi disable"
      echo "  📴 WiFi OFF"
      sleep 10
      adb -s $DEVICE shell "svc wifi enable"
      echo "  📶 WiFi ON"
      sleep 10
    done
    ;;

  "offline")
    adb -s $DEVICE shell "svc wifi disable && svc data disable"
    echo "✅ Modo offline (WiFi y datos desactivados)"
    ;;

  "reset")
    adb -s $DEVICE shell "tc qdisc del dev wlan0 root 2>/dev/null"
    adb -s $DEVICE shell "svc wifi enable && svc data enable"
    echo "✅ Red restaurada"
    ;;

  *)
    echo "❌ Tipo de red desconocido: $NETWORK_TYPE"
    echo "Tipos válidos: wifi, 4g-good, 4g-bad, 3g, edge, intermittent, offline, reset"
    exit 1
    ;;
esac
