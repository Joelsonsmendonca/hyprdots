#!/bin/bash

opcao=$(echo -e "📺 YouTube\n💬 WhatsApp\n📬 Gmail\n⬅️ Voltar" | wofi --show dmenu --prompt "Web Apps:")

case "$opcao" in
    "📺 YouTube")
        firefox https://youtube.com ;;
    "💬 WhatsApp")
        firefox https://web.whatsapp.com ;;
    "📬 Gmail")
        firefox https://mail.google.com ;;
    "⬅️ Voltar")
        ~/.config/wofi/scripts/menu-principal.sh ;;
esac
