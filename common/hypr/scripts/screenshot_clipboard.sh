#!/bin/bash
# Sem slurp de propósito: slurp é seleção interativa (a tela "se move" enquanto você arrasta).
# Isso aqui captura o frame exato de quando a tecla foi apertada, sem interação nenhuma.
grim - | wl-copy
notify-send -a "screenshot" "Print capturado" "Copiado pra área de transferência"
