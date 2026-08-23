#!/bin/bash
# Roda a cada ~2min via battery-notify.timer. Guarda o último aviso disparado em
# STATE_FILE pra não repetir notificação a cada execução — só avisa de novo quando
# cruza um novo limite (ou quando volta a carregar, que reseta o estado).
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/battery-notify-state"

BAT=$(upower -e | grep -m1 BAT)
[ -z "$BAT" ] && exit 0

INFO=$(upower -i "$BAT")
STATE=$(echo "$INFO" | awk '/state:/ {print $2}')
PERCENT=$(echo "$INFO" | awk -F'[ %]+' '/percentage:/ {print $3}')
[ -z "$PERCENT" ] && exit 0

LAST=$(cat "$STATE_FILE" 2>/dev/null || echo "none")

if [ "$STATE" = "charging" ] || [ "$STATE" = "fully-charged" ]; then
    [ "$LAST" != "none" ] && echo "none" > "$STATE_FILE"
    exit 0
fi

if [ "$PERCENT" -le 10 ] && [ "$LAST" != "critical" ]; then
    notify-send -u critical -a "battery" "Bateria crítica" "${PERCENT}% restante — conecta o carregador"
    echo "critical" > "$STATE_FILE"
elif [ "$PERCENT" -le 20 ] && [ "$LAST" = "none" ]; then
    notify-send -u normal -a "battery" "Bateria baixa" "${PERCENT}% restante"
    echo "warning" > "$STATE_FILE"
fi
