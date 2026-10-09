#!/bin/bash
# Histórico da área de transferência (cliphist) no fuzzel. Bind: SUPER+SHIFT+V.
# O histórico é gravado pelo cliphist.service (common/systemd/user/), que roda
# `wl-paste --watch cliphist store` desde o login.
# --with-nth 2 esconde o ID numérico da lista; o cliphist decode precisa da linha inteira.
cliphist list \
    | fuzzel --dmenu --with-nth 2 --prompt 'Clipboard > ' \
    | cliphist decode \
    | wl-copy
