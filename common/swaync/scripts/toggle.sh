#!/bin/bash
# Botões "toggle" da central do swaync (config.json -> buttons-grid).
#   toggle.sh <nome>          aplica o estado que o swaync passa em $SWAYNC_TOGGLE_STATE
#   toggle.sh <nome> status   imprime true/false (update-command, roda ao abrir a central)
# Script em vez de `sh -c '...'` inline: o swaync quebra o comando nos espaços e se
# perde com aspas aninhadas ("EOF inesperado" no journal).
name="$1"; mode="${2:-set}"
CONSERVATION=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
on() { [ "$SWAYNC_TOGGLE_STATE" = true ]; }
bool() { if "$@" >/dev/null 2>&1; then echo true; else echo false; fi; }

case "$name:$mode" in
    # `nmcli radio wifi` diz "enabled" mesmo SEM placa (é só o interruptor de software;
    # o desktop é só cabo). Só acende se o hardware existir e estiver ligado.
    wifi:status)  bool test "$(LC_ALL=C nmcli -t -f WIFI-HW,WIFI radio)" = "enabled:enabled" ;;
    wifi:set)     if on; then nmcli radio wifi on; else nmcli radio wifi off; fi ;;
    # sem controlador (desktop), bluetoothctl espera pra sempre -> timeout
    bt:status)    timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo true || echo false ;;
    bt:set)       if on; then timeout 3 bluetoothctl power on; else timeout 3 bluetoothctl power off; fi ;;
    dnd:status)   swaync-client -D ;;
    dnd:set)      if on; then swaync-client -dn; else swaync-client -df; fi >/dev/null ;;
    # "Não dormir" = hypridle parado (sem bloqueio/desligar tela por inatividade)
    awake:status) systemctl --user is-active -q hypridle && echo false || echo true ;;
    awake:set)    if on; then systemctl --user stop hypridle; else systemctl --user start hypridle; fi ;;
    # "Proteger bateria" = conservation mode da Lenovo (carga para em ~60%). Manual de
    # propósito: em viagem quer bateria cheia. Escrever exige a regra udev em
    # common/system/udev/rules.d/ (senão só root escreve). No desktop: sempre false.
    bat:status)   bool grep -qx 1 "$CONSERVATION" ;;
    bat:set)      if on; then v=1; else v=0; fi
                  echo $v 2>/dev/null > "$CONSERVATION" \
                    || notify-send -a Energia "Proteger bateria" "Sem permissão: instale a regra udev (ver common/system/udev/rules.d)" ;;
    *) echo "uso: $0 {wifi|bt|dnd|awake|bat} [status]" >&2; exit 1 ;;
esac
