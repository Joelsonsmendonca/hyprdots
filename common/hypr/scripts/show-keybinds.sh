#!/bin/bash
# Le o keybinds.conf atual e mostra num popup do wofi (sempre atualizado, nao hardcoded)
KEYBINDS_FILE="$HOME/.config/hypr/config/keybinds.conf"
STYLE="$HOME/.config/hypr/scripts/keybinds-style.css"

grep -E '^bind[a-z]* = ' "$KEYBINDS_FILE" | sed -E 's/^bind[a-z]* = //' | \
awk -F', *' '{
    mod = $1
    key = $2
    action = $3
    for (i = 4; i <= NF; i++) action = action ", " $i

    gsub(/\$mainMod/, "SUPER", mod)
    gsub(/ /, " + ", mod)

    combo = (mod == "") ? key : mod " + " key
    gsub(/&/, "&amp;", combo); gsub(/&/, "&amp;", action)
    gsub(/</, "&lt;", combo);  gsub(/</, "&lt;", action)

    printf "<b><span foreground=\x27#e0af68\x27>%-26s</span></b>  <span foreground=\x27#7dcfff\x27>%s</span>\n", combo, action
}' | wofi --dmenu --allow-markup --style "$STYLE" --prompt "  Atalhos" --width 780 --height 640 --insensitive
