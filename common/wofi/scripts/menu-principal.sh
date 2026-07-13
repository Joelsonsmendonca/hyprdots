#!/bin/bash

opcao=$(echo -e "🧭 Aplicativos\n🌐 Web Apps\n🛠️ Sistema" | wofi --show dmenu --prompt "Menu Principal:")

case "$opcao" in
    "🧭 Aplicativos")
        wofi --show drun ;;
    "🌐 Web Apps")
        ~/.config/wofi/scripts/webapps.sh ;;
    "🛠️ Sistema")
        ~/.config/wofi/scripts/sistema.sh ;;
esac
