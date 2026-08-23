#!/bin/bash
# Versão com seleção de área (slurp) — pra quando você quer escolher o que capturar,
# diferente do PRTSC sozinho que pega a tela inteira na hora.
grim -g "$(slurp)" - | wl-copy
notify-send -a "screenshot" "Print capturado" "Área selecionada copiada pra área de transferência"
