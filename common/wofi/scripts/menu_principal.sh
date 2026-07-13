#!/bin/bash

# =============================
# 🧭 MENU PRINCIPAL - ARCH LINUX
# =============================

TERMINAL="kitty"
BROWSER="brave"

# === FUNÇÕES ===

# 🧩 SUBMENUS ==================================

menu_apps() {
cat <<EOF
📦 Abrir Terminal
🖋 Editor de Texto (nano)
🌐 Navegador Web ($BROWSER)
🎵 Spotify
📸 Flameshot (captura de tela)
↩️ Voltar
EOF
}

menu_webapps() {
cat <<EOF
💬 ChatGPT
📺 YouTube
📧 Gmail
🐙 GitHub
↩️ Voltar
EOF
}

menu_sistema() {
cat <<EOF
🧱 Atualizar Sistema (pacman)
🌍 Atualizar AUR (yay)
🧹 Limpar Cache do Pacman
🔄 Reiniciar
⏻ Desligar
↩️ Voltar
EOF
}

# 🧠 FUNÇÕES DE AÇÃO ===========================

abrir_terminal() { $TERMINAL & }
abrir_editor() { $TERMINAL -e nano & }
abrir_browser() { $BROWSER & }
abrir_spotify() { spotify & }
abrir_flameshot() { flameshot gui & }

# Web apps
abrir_chatgpt() { $BROWSER "https://chat.openai.com" & }
abrir_youtube() { $BROWSER "https://youtube.com" & }
abrir_gmail() { $BROWSER "https://mail.google.com" & }
abrir_github() { $BROWSER "https://github.com" & }

# Sistema
atualizar_pacman() { $TERMINAL -e sudo pacman -Syu }
atualizar_aur() { $TERMINAL -e yay -Syu --noconfirm }
limpar_cache() { $TERMINAL -e sudo paccache -r }
reiniciar() { systemctl reboot }
desligar() { systemctl poweroff }

# === MENUS WOFi ===============================

main_menu() {
cat <<EOF
💻 Aplicativos
🌐 Web Apps
⚙️ Sistema
❌ Sair
EOF
}

# === EXECUÇÃO DO MENU =========================

mostrar_menu() {
    local op
    op=$(main_menu | wofi --dmenu --prompt "Menu Principal" --width 300 --height 250)

    case "$op" in
        "💻 Aplicativos") submenu_apps ;;
        "🌐 Web Apps") submenu_webapps ;;
        "⚙️ Sistema") submenu_sistema ;;
        "❌ Sair") exit 0 ;;
        *) exit 0 ;;
    esac
}

submenu_apps() {
    local op
    op=$(menu_apps | wofi --dmenu --prompt "Aplicativos" --width 300 --height 250)
    case "$op" in
        "📦 Abrir Terminal") abrir_terminal ;;
        "🖋 Editor de Texto (nano)") abrir_editor ;;
        "🌐 Navegador Web ($BROWSER)") abrir_browser ;;
        "🎵 Spotify") abrir_spotify ;;
        "📸 Flameshot (captura de tela)") abrir_flameshot ;;
        "↩️ Voltar") mostrar_menu ;;
    esac
}

submenu_webapps() {
    local op
    op=$(menu_webapps | wofi --dmenu --prompt "Web Apps" --width 300 --height 250)
    case "$op" in
        "💬 ChatGPT") abrir_chatgpt ;;
        "📺 YouTube") abrir_youtube ;;
        "📧 Gmail") abrir_gmail ;;
        "🐙 GitHub") abrir_github ;;
        "↩️ Voltar") mostrar_menu ;;
    esac
}

submenu_sistema() {
    local op
    op=$(menu_sistema | wofi --dmenu --prompt "Sistema" --width 300 --height 250)
    case "$op" in
        "🧱 Atualizar Sistema (pacman)") atualizar_pacman ;;
        "🌍 Atualizar AUR (yay)") atualizar_aur ;;
        "🧹 Limpar Cache do Pacman") limpar_cache ;;
        "🔄 Reiniciar") reiniciar ;;
        "⏻ Desligar") desligar ;;
        "↩️ Voltar") mostrar_menu ;;
    esac
}

# Início
mostrar_menu
