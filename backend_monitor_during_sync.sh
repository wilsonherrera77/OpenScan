#!/bin/bash
# BACKEND MONITOR: Logs de Tejido durante sincronización

echo "═══════════════════════════════════════════════════════"
echo "🔍 MONITOR BACKEND (Tejido/Paperless)"
echo "═══════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "Monitoreando logs del backend en tiempo real..."
echo "Presiona Ctrl+C para detener"
echo ""
echo "--- LOGS BACKEND -------------------------------------------"
echo ""

# Monitor Docker logs in real-time
docker logs -f paperless_webserver_1 2>&1 | while IFS= read -r line; do
    # Highlight POST requests (uploads)
    if echo "$line" | grep -qi "POST.*documents"; then
        echo -e "${GREEN}$line${NC}"
    # Highlight errors
    elif echo "$line" | grep -qi "error\|exception\|traceback"; then
        echo -e "${RED}$line${NC}"
    # Highlight 406 issues
    elif echo "$line" | grep -qi "406\|not acceptable"; then
        echo -e "${YELLOW}$line${NC}"
    # Highlight authentication
    elif echo "$line" | grep -qi "auth\|token\|401\|403"; then
        echo -e "${BLUE}$line${NC}"
    else
        echo "$line"
    fi
done
