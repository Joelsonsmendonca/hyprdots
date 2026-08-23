#!/bin/bash
# iwd/NetworkManager às vezes prendem um BSSID morto em cache depois de várias falhas de
# conexão seguidas, fazendo o wifi reportar sinal fantasma mesmo com o roteador saudável
# por perto. Isso limpa o rádio e força um scan novo.
notify-send -a "wifi" "Recuperando wifi..." "Desligando e religando o rádio"
nmcli radio wifi off
sleep 3
nmcli radio wifi on
sleep 2
nmcli device wifi rescan
notify-send -a "wifi" "Wifi recuperado" "Rádio reiniciado, escolha a rede no nm-applet"
