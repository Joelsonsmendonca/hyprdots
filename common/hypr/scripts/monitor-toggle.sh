#!/bin/bash
# Liga/desliga um monitor (pra ficar só com uma tela). Bind: SUPER+SHIFT+M.
# Sem argumento: alterna o AOC (tela secundária). Com argumento: alterna o
# monitor cujo `desc:` casa com o texto passado.
#
# Config do Hyprland é Lua, então `hyprctl keyword` não funciona — usa-se
# `hyprctl eval 'hl.monitor{...}'`. `disabled = false` tem que ser explícito
# pra religar (só passar mode/position não basta).
set -uo pipefail

# alvo padrão: AOC. mode/position batem com o hyprland.lua.
DESC="${1:-AOC 1970W}"
MODE="1366x768@59.79"
POS="3440x0"
if [ $# -ge 1 ]; then          # monitor custom -> deixa o Hyprland decidir
    MODE="preferred"; POS="auto"
fi

# Está desabilitado agora? (procura o bloco no `monitors all` e lê o disabled:)
disabled=$(hyprctl monitors all | awk -v d="$DESC" '
    /^Monitor /            { inblk=0 }
    /description:/         { if (index($0, d)) inblk=1 }
    inblk && /disabled:/   { print $2; exit }
')

if [ "$disabled" = "true" ]; then
    hyprctl eval "hl.monitor({ output = \"desc:$DESC\", disabled = false, mode = \"$MODE\", position = \"$POS\", scale = 1.0 })" >/dev/null
    notify-send -a "monitor" "Tela ligada" "$DESC"
else
    hyprctl eval "hl.monitor({ output = \"desc:$DESC\", disabled = true })" >/dev/null
    notify-send -a "monitor" "Tela desligada" "$DESC — só uma tela agora"
fi
