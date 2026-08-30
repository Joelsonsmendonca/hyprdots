#!/usr/bin/env bash
# ==============================================================================
# setup-ai.sh - Launcher de instalação do stack de IA via ia.skills
# ==============================================================================
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills/ia-skills"

echo "==> Sincronizando repositório ia.skills..."
mkdir -p "$HOME/.claude/skills"

if [[ -d "$SKILLS_DIR/.git" ]]; then
  (cd "$SKILLS_DIR" && git pull --quiet || true)
else
  git clone git@github.com:Joelsonsmendonca/ia.skills.git "$SKILLS_DIR" 2>/dev/null \
    || git clone https://github.com/Joelsonsmendonca/ia.skills.git "$SKILLS_DIR"
fi

echo "==> Executando instalador do ia.skills..."
exec "$SKILLS_DIR/install.sh" "$@"
