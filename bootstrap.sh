#!/usr/bin/env bash
# Aplica estes dotfiles: cria os symlinks ~/.config/<app> -> common/<app>.
# Idempotente (pode rodar de novo). Rode como usuário normal, sem sudo.
#
#   git clone https://github.com/Joelsonsmendonca/hyprdots.git ~/dotfiles
#   ~/dotfiles/bootstrap.sh
set -euo pipefail

if [[ -f ${BASH_SOURCE[0]:-} ]]; then
  REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
else
  REPO="${DOTFILES_DIR:-$HOME/dotfiles}"
fi
[[ -d $REPO/common ]] || { echo "não encontrei common/ em $REPO" >&2; exit 1; }

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP=$(date +%Y%m%d-%H%M%S)

link() {  # link <alvo> <origem>
  local target=$1 src=$2
  mkdir -p "$(dirname "$target")"
  if [[ -e $target && ! -L $target ]]; then
    echo "   backup: $target.bak.$STAMP"
    mv "$target" "$target.bak.$STAMP"
  fi
  ln -sfn "$src" "$target"
  echo "   $target -> ${src#$REPO/}"
}

echo "==> Configs (~/.config/<app>)"
for d in "$REPO"/common/*/; do
  app=$(basename "$d")
  case "$app" in system|systemd|easyeffects) continue ;; esac   # tratados abaixo / à mão
  link "$CFG/$app" "$REPO/common/$app"
done

echo "==> Unidades systemd --user"
for u in "$REPO"/common/systemd/user/*; do
  link "$CFG/systemd/user/$(basename "$u")" "$u"
done
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now battery-notify.timer 2>/dev/null || true
# Serviços da sessão gráfica (WantedBy=graphical-session.target, ativado pelo UWSM).
# NÃO subir estes também por exec_cmd no Hyprland — duas instâncias brigam (swaync
# morria com "already running").
systemctl --user enable waybar.service swaync.service hypridle.service cliphist.service 2>/dev/null || true

echo "==> Dolphin como gerenciador de pastas + cache de menus KDE"
# kitty instala kitty-open.desktop e pegava inode/directory ("mostrar na pasta" abria terminal).
xdg-mime default org.kde.dolphin.desktop inode/directory 2>/dev/null || true
# "Abrir com" do Dolphin depende do arch-applications.menu (archlinux-xdg-menu).
XDG_MENU_PREFIX=arch- kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

echo "==> Wrapper nvidia-offload (~/.local/bin)"
if [[ -e "$REPO/common/hypr/scripts/nvidia-offload.sh" ]]; then
  link "$HOME/.local/bin/nvidia-offload" "$REPO/common/hypr/scripts/nvidia-offload.sh"
fi

echo "==> Preset do EasyEffects (~/.local/share/easyeffects/output)"
# EasyEffects 8 guarda os settings dele em ~/.config/easyeffects/db/ (precisa
# escrever lá) e lê presets de ~/.local/share/easyeffects/output/. Por isso o
# preset é symlinkado só como arquivo, não a pasta ~/.config/easyeffects inteira.
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
for p in "$REPO"/common/easyeffects/*.json; do
  [[ -e $p ]] || continue
  link "$DATA/easyeffects/output/$(basename "$p")" "$p"
done

cat <<EOF

==> Pronto. Os symlinks apontam pra dentro de: $REPO
    (editar ~/.config/<app> já edita o repo; 'git -C $REPO status' mostra as mudanças)

Configs de SISTEMA (sudo, específicas do notebook híbrido AMD+NVIDIA) — se for o caso:
    sudo cp $REPO/common/system/modprobe.d/*.conf /etc/modprobe.d/
    (regdomain de wifi + toggle do touchpad ideapad — ver README)
    sudo mkdir -p /etc/sddm.conf.d && sudo cp $REPO/common/system/sddm.conf.d/*.conf /etc/sddm.conf.d/
    (Num Lock ligado na tela de login)

Depois: ajuste o endereço PCI da GPU em common/uwsm/env-hyprland e faça logout/login.
EOF
