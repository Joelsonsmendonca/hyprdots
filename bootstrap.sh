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
  case "$app" in system|systemd) continue ;; esac   # tratados abaixo / à mão
  link "$CFG/$app" "$REPO/common/$app"
done

echo "==> Unidades systemd --user"
for u in "$REPO"/common/systemd/user/*; do
  link "$CFG/systemd/user/$(basename "$u")" "$u"
done
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now battery-notify.timer 2>/dev/null || true

echo "==> Wrapper nvidia-offload (~/.local/bin)"
if [[ -e "$REPO/common/hypr/scripts/nvidia-offload.sh" ]]; then
  link "$HOME/.local/bin/nvidia-offload" "$REPO/common/hypr/scripts/nvidia-offload.sh"
fi

cat <<EOF

==> Pronto. Os symlinks apontam pra dentro de: $REPO
    (editar ~/.config/<app> já edita o repo; 'git -C $REPO status' mostra as mudanças)

Configs de SISTEMA (sudo, específicas do notebook híbrido AMD+NVIDIA) — se for o caso:
    sudo cp $REPO/common/system/modprobe.d/*.conf /etc/modprobe.d/
    (regdomain de wifi + toggle do touchpad ideapad — ver README)

Depois: ajuste o endereço PCI da GPU em common/uwsm/env-hyprland e faça logout/login.
EOF
