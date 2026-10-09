#!/bin/bash
# Espera o Hyprland ter pelo menos um monitor configurado e dá um respiro pro
# modeset (ex.: LG indo de "preferred" pra 3440x1440@160) terminar.
# Usado como ExecStartPre de apps de autostart que dependem da tela existir.
#
# Caso real: o Linux Wallpaper Engine sobe ~0,02-0,3s depois do Hyprland e já
# restaura o wallpaper pedindo `--screen-root DP-3`. Se a saída ainda não existe,
# o renderizador encerra com "Cannot continue" (exit 1) e a interface NÃO tenta
# de novo -> "às vezes o wallpaper aparece, às vezes não".
# Sempre sai 0: no pior caso (10s sem monitor) o app sobe do mesmo jeito.
for _ in $(seq 1 50); do
    if hyprctl monitors 2>/dev/null | grep -q '^Monitor '; then
        sleep "${1:-2}"
        exit 0
    fi
    sleep 0.2
done
exit 0
