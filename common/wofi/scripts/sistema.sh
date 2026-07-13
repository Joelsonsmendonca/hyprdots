#!/bin/bash

opcao=$(echo -e "🔄 Atualizar o Arch\n♻️ Reiniciar Hyprland\n🚪 Sair" | wofi --show dmenu --prompt "Sistema:")

case "$opcao" in
    "🔄 Atualizar o Arch")
        kitty -e bash -c "sudo pacman -Syu; echo 'Pressione ENTER para sair'; read" ;;
    "♻️ Reiniciar Hyprland")
        hyprctl dispatch exec "hyprctl reload" ;;
    "🚪 Sair")
        ~/.config/wofi/scripts/menu-principal.sh ;;
esac
