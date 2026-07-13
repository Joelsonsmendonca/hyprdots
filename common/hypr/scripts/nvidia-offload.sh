#!/bin/bash
# Roda um comando específico na dGPU NVIDIA via PRIME render offload,
# enquanto o resto do desktop continua na iGPU AMD (padrão em env-hyprland).
# Uso: nvidia-offload glxgears
#      nvidia-offload steam
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "uso: $(basename "$0") <comando> [args...]" >&2
    exit 1
fi

prev_profile=""
if command -v powerprofilesctl >/dev/null 2>&1; then
    prev_profile="$(powerprofilesctl get 2>/dev/null || true)"
    [ -n "$prev_profile" ] && powerprofilesctl set performance >/dev/null 2>&1 || true
fi

restore_profile() {
    [ -n "$prev_profile" ] && powerprofilesctl set "$prev_profile" >/dev/null 2>&1 || true
}
trap restore_profile EXIT

__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
    "$@"
