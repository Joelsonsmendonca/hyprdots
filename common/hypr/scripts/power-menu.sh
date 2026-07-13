#!/bin/bash
# Menu de energia (desligar / reiniciar / suspender / hibernar)
STYLE="$HOME/.config/wofi/style.css"

opcao=$(printf "%s\n%s\n%s\n%s\n%s\n" \
    "  Desligar" \
    "  Reiniciar" \
    "  Suspender" \
    "  Hibernar" \
    "  Cancelar" \
    | wofi --dmenu --prompt "Energia" --width 320 --height 280 --insensitive)

case "$opcao" in
    *Desligar)   systemctl poweroff ;;
    *Reiniciar)  systemctl reboot ;;
    *Suspender)  systemctl suspend ;;
    *Hibernar)   systemctl hibernate ;;
    *) exit 0 ;;
esac
