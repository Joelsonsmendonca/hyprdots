#!/usr/bin/env bash
set -ex

APPS=(hypr kitty rofi waybar wofi fuzzel uwsm pipewire swaync)

echo "Instalando pacotes da interface e ferramentas essenciais..."
sudo pacman -Syu --needed --noconfirm hyprland kitty rofi waybar wofi fuzzel uwsm pipewire pipewire-pulse swaync sddm bluez bluez-utils firewalld qt5-wayland qt6-wayland polkit-kde-agent

echo "Habilitando serviços..."
sudo systemctl enable --now NetworkManager || true
sudo systemctl enable sddm bluetooth firewalld

echo "Configurando dotfiles (hyprdots)..."
[[ -d "$HOME/dotfiles" ]] || git clone "https://github.com/Joelsonsmendonca/hyprdots.git" "$HOME/dotfiles"
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.config/systemd/user"

for app in "${APPS[@]}"; do
  if [[ -e "$HOME/.config/$app" && ! -L "$HOME/.config/$app" ]]; then
    mv "$HOME/.config/$app" "$HOME/.config/$app.bak.$(date +%s)"
  fi
  ln -sfn "$HOME/dotfiles/common/$app" "$HOME/.config/$app"
done

ln -sfn "$HOME/dotfiles/common/systemd/user/app-nm\x2dapplet@autostart.service.d" \
        "$HOME/.config/systemd/user/app-nm\x2dapplet@autostart.service.d" 2>/dev/null || true
systemctl --user daemon-reload 2>/dev/null || true

[[ -e "$HOME/.config/hypr/scripts/nvidia-offload.sh" ]] && \
  ln -sfn "$HOME/.config/hypr/scripts/nvidia-offload.sh" "$HOME/.local/bin/nvidia-offload" || true

echo "Finalizado!"
