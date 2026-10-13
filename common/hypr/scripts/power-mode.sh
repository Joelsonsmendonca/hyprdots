#!/bin/bash
# Modo de energia do notebook (Fn+Q da Lenovo = platform_profile, espelhado pelo
# power-profiles-daemon como power-saver / balanced / performance).
#
#   power-mode.sh status   JSON pro módulo custom/power-mode da waybar
#   power-mode.sh cycle    próximo modo (clique na waybar; mesma ordem do Fn+Q)
#   power-mode.sh watch    serviço (power-mode.service): reage a troca de modo e à tomada
#
# No desktop não existe platform_profile: status sai vazio (módulo some) e o watch
# não troca nada.
set -u

PROFILE=/sys/firmware/acpi/platform_profile
WAYBAR_SIGNAL=14

current() { powerprofilesctl get 2>/dev/null; }

label() {  # label <perfil ppd> -> "ícone|cor|curto|nome"
    case "$1" in
        power-saver) echo "󰌪|#7aa2f7|eco|Economia" ;;
        performance) echo "󰓅|#f7768e|turbo|Desempenho" ;;
        *)           echo "󰾆|#73daca|equil|Equilibrado" ;;
    esac
}

status() {
    [ -r "$PROFILE" ] || { echo '{"text": ""}'; return; }
    local p icon color short name
    p=$(current); IFS='|' read -r icon color short name <<< "$(label "$p")"
    # mesmo formato dos vizinhos na ilha (cpu, memória...): ícone colorido + texto
    printf '{"text": "<span foreground='"'"'%s'"'"'>%s</span> %s", "tooltip": "Modo: %s\\nClique ou Fn+Q pra trocar", "class": "%s"}\n' \
        "$color" "$icon" "$short" "$name" "$p"
}

cycle() {
    case "$(current)" in
        power-saver) powerprofilesctl set balanced ;;
        balanced)    powerprofilesctl set performance ;;
        *)           powerprofilesctl set power-saver ;;
    esac
}

on_profile() {  # on_profile <perfil novo> <perfil anterior>
    local icon color short name
    IFS='|' read -r icon color short name <<< "$(label "$1")"
    pkill -RTMIN+$WAYBAR_SIGNAL waybar
    # look.lua lê o modo ao carregar: só recarrega se entrou/saiu da economia
    if [ "$1" = power-saver ] || [ "$2" = power-saver ]; then
        hyprctl reload >/dev/null
    fi
    notify-send -a "Energia" -t 2500 -h string:x-canonical-private-synchronous:power-mode \
        "$icon  Modo $name"
}

on_battery() {  # on_battery true|false  (tirou/ligou a tomada)
    if [ "$1" = true ]; then powerprofilesctl set power-saver
    else powerprofilesctl set balanced; fi
}

watch() {
    [ -r "$PROFILE" ] || exec sleep infinity   # desktop: nada a fazer
    # Um monitor pro PPD (modo) e outro pro UPower (tomada). O PPD publica o mesmo evento
    # também em /net/hadess/... (nome antigo) — filtrado pelo caminho no case lá embaixo.
    # Se um dos dois morrer, sai e o systemd (Restart=always) sobe tudo de novo.
    gdbus monitor --system --dest org.freedesktop.UPower.PowerProfiles &
    gdbus monitor --system --dest org.freedesktop.UPower --object-path /org/freedesktop/UPower &
    wait -n
} 2>/dev/null

case "${1:-}" in
    status) status ;;
    cycle)  cycle ;;
    watch)
        prev=$(current)
        watch | while read -r line; do
            case "$line" in
                "/org/freedesktop/UPower/PowerProfiles: "*"'ActiveProfile': <'"*)
                    new=${line#*\'ActiveProfile\': <\'}; new=${new%%\'*}
                    [ "$new" != "$prev" ] && on_profile "$new" "$prev"
                    prev=$new ;;
                "/org/freedesktop/UPower: "*"'OnBattery': <"*)
                    b=${line#*\'OnBattery\': <}; on_battery "${b%%>*}" ;;
            esac
        done ;;
    *) echo "uso: $0 {status|cycle|watch}" >&2; exit 1 ;;
esac
