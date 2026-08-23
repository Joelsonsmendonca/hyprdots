# Contexto pra IA trabalhando neste repo

Dotfiles de Hyprland (Lenovo Legion, AMD Ryzen iGPU + NVIDIA dGPU, Arch Linux + UWSM).
O README é pra humano instalar; isto aqui é pra não repetir a arqueologia que já foi feita.

## Convenção de symlink

`~/.config/<app>` é sempre um symlink pra `common/<app>/` dentro deste repo (ver README →
Instalação). Editar direto em `~/.config/<app>` já edita o repo. Depois de mexer, `git status`
aqui mostra o que mudou de verdade.

## Hyprland config é Lua, não `.conf`

`common/hypr/hyprland.lua` usa a API `hl.*` (hyprlang com binding Lua), não a sintaxe clássica
`bind = ...`. Referência completa da API (todos os namespaces `hl.dsp.*`, tipos de retorno,
campos de `HL.Window`/`HL.Monitor`) fica em `/usr/share/hypr/stubs/hl.meta.lua` no sistema —
lê esse arquivo antes de adivinhar assinatura de função.

**Testar um dispatch sem editar o arquivo e recarregar:**
```bash
hyprctl dispatch 'hl.dsp.window.resize({x = 420, y = 260})'
```
O texto depois de `dispatch` é colado dentro de `hl.dispatch(<texto>)` e avaliado como Lua de
verdade — então precisa ser uma expressão Lua válida (prefixo `hl.dsp.` completo, não só
`window.resize(...)`). Erros de argumento vêm com o nome certo do parâmetro esperado (ex.:
"Expected positions (x & y)"), então o primeiro erro geralmente já ensina a assinatura certa.

**Gotcha de coordenadas:** `hyprctl monitors` e `hl.get_active_monitor()` retornam
`width`/`height` em pixels **físicos**. `hl.dsp.window.move`/`resize` trabalham em coordenadas
**lógicas** (físico / `scale`). Em qualquer monitor com scale ≠ 1, dividir por `mon.scale` antes
de calcular posição — já mordemos essa (janela ia parar fora da tela, ver histórico do PIP em
`hyprland.lua`).

**Antes de confiar em qualquer teste feito por `hyprctl dispatch` neste ambiente**, tirar um
`grim` e checar visualmente — já aconteceu do estado reportado por `hyprctl activewindow -j`
não bater com o que renderizava na tela.

## Autostart é systemd de verdade (via UWSM)

Cada `.desktop` em `/etc/xdg/autostart/` ou `~/.config/autostart/` vira uma unidade
`app-<nome>@autostart.service` (não é só `exec-once` solto). Pra depurar um app que não
aparece/crasha:
```bash
systemctl --user status 'app-nm\x2dapplet@autostart.service'   # escapar o @ e caracteres especiais
journalctl --user -u 'app-nm\x2dapplet@autostart.service'
```
Se crashou de verdade (coredump), o motivo real está em `journalctl`, não em "esqueceu do
autostart" — checar antes de mexer em `hyprland.lua`.

**Drop-in compartilhado entre todos os apps de autostart:** `app-@autostart.service.d/*.conf`
(literal, com o `@` logo depois de `app-`) aplica em QUALQUER unidade `app-<x>@autostart.service`
via prefix-matching do systemd — é assim que o UWSM injeta `slice-tweak.conf` em todo mundo, e
é onde `common/systemd/user/app-@autostart.service.d/99-crash-notify.conf` vive.

**Dentro desse drop-in compartilhado, `%i` colide** (resolve sempre pra `"autostart"`, igual
pra todo app — não dá pra distinguir quem falhou). Usar `%p` (prefixo, ex. `app-blueman`) pra
qualquer coisa que precise saber QUAL app disparou o `OnFailure=`/gatilho.

## Achados de troubleshooting (não redescobrir)

- **Wifi "sem sinal" mesmo com roteador saudável perto**: iwd guarda um BSS obsoleto/morto em
  cache depois de várias falhas de conexão seguidas. `nmcli radio wifi off && sleep 3 &&
  nmcli radio wifi on` limpa. Script pronto: `common/hypr/scripts/wifi-recover.sh`
  (`SUPER+SHIFT+W`).
- **Wifi rejeita associação (`status: 1` no log do iwd) mesmo com sinal bom**: causa diferente
  do item acima — `wireless-regdb` estava ausente (`dmesg` mostra "regulatory.db failed"),
  cfg80211 ficava em `00: DFS-UNSET`. Driver é `rtw89` (Realtek RTL8852AE), conhecido por ter
  problema de negociação HE/802.11ax com regdomain indefinido. Fix real, não workaround:
  `sudo pacman -S wireless-regdb iw && sudo iw reg set BR`, persistido em
  `common/system/modprobe.d/wifi-regdomain.conf`. Antes de cogitar trocar o backend
  iwd→wpa_supplicant, checar se isso já foi aplicado.
- **Áudio USB cortando ("Broken pipe" no log do PipeWire)**: não é economia de energia, é
  quantum de buffer pequeno pro dongle. Ver `common/pipewire/pipewire.conf.d/99-quantum.conf`.
- **Touchpad "travado"**: neste hardware o toggle Fn é 100% EC/firmware
  (`touchpad_ctrl_via_ec=N` por padrão), invisível pro Linux — não tem log, não tem rfkill.
  `common/system/modprobe.d/` tem a opção pra expor isso ao kernel, se ainda não foi aplicada.
- Ver a seção "Confiabilidade" do README pros detalhes completos de cada um.
