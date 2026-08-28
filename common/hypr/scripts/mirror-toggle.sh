#!/bin/bash
# Espelha TODAS as telas na tela em foco (modo "projetar na facul"). Rodar de
# novo desfaz e volta pro layout estendido do hyprland.lua. Bind: SUPER+SHIFT+P.
#
# Genérico de propósito: serve tanto pro notebook + projetor quanto pro desktop.
# Config do Hyprland é Lua, então `hyprctl keyword` não funciona ("non-legacy
# parsers") — usa-se `hyprctl eval 'hl.monitor{...}'` pra espelhar e `hyprctl
# reload` pra restaurar. Sem jq (não instalado): parseia texto do `hyprctl monitors`.
#
# Nota: monitor espelhando some do `hyprctl monitors` normal, por isso usamos
# `hyprctl monitors all` (e filtramos os `disabled: true`).
set -uo pipefail
app="espelhar"

mons=$(hyprctl monitors all)

# nome da tela em foco
focused=$(awk '/^Monitor /{n=$2} /^[[:space:]]*focused: yes/{print n; exit}' <<<"$mons")
if [ -z "$focused" ]; then
    notify-send -a "$app" "Erro" "Não achei a tela em foco"
    exit 1
fi

# "<nome>\t<disabled>\t<mirrorOf>" por monitor
info=$(awk '
    /^Monitor /                     { if (n != "") print n"\t"dis"\t"mir; n=$2; dis=""; mir="" }
    /^[[:space:]]*disabled:/         { dis=$2 }
    /^[[:space:]]*mirrorOf:/         { mir=$2 }
    END                             { if (n != "") print n"\t"dis"\t"mir }
' <<<"$mons")

mapfile -t others < <(awk -F'\t' -v f="$focused" '$1 != f && $2 == "false"' <<<"$info")

if [ "${#others[@]}" -eq 0 ]; then
    notify-send -a "$app" "Uma tela só" "Nada pra espelhar"
    exit 0
fi

mirroring=0
while IFS=$'\t' read -r _ _ mir; do
    [ -n "$mir" ] && [ "$mir" != "none" ] && mirroring=1
done <<<"$info"

if [ "$mirroring" -eq 1 ]; then
    hyprctl reload
    notify-send -a "$app" "Espelhamento desligado" "Telas estendidas de novo"
else
    while IFS=$'\t' read -r name _ _; do
        hyprctl eval "hl.monitor({ output = \"$name\", mode = \"preferred\", position = \"auto\", scale = 1, mirror = \"$focused\" })" >/dev/null
    done < <(printf '%s\n' "${others[@]}")
    notify-send -a "$app" "Espelhando" "Todas as telas replicando $focused"
fi
