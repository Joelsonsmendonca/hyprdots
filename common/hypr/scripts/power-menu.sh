#!/bin/bash
# Menu de energia (desligar / reiniciar / suspender / hibernar)
# Usa fuzzel --index: retorna o NÚMERO da opção escolhida, sem depender de
# casar o texto (o wofi --dmenu estava sempre devolvendo a 1ª linha).

idx=$(printf '%s\n' \
    $'  Desligar' \
    $'  Reiniciar' \
    $'  Suspender' \
    $'  Hibernar' \
    $'  Cancelar' \
    | fuzzel --dmenu --index --prompt 'Energia > ' --lines 5)

case "$idx" in
    0) systemctl poweroff ;;
    1) systemctl reboot ;;
    2) systemctl suspend ;;
    3) systemctl hibernate ;;
    *) exit 0 ;;
esac
