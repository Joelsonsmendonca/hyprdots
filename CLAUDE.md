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

**Dispatch em TEXTO clássico está morto (parser Lua).** Qualquer `dispatch workspace 5`,
`dispatch exec ...`, etc. — mandado por `hyprctl` OU direto no socket1 — o servidor
embrulha em `return hl.dispatch(workspace 5)` e quebra com erro de sintaxe Lua. Só funciona
a forma `hl.dsp.*` (ex.: `hyprctl dispatch 'hl.dsp.focus({ workspace = 5 })'`). Consequência
prática: ferramentas do ecossistema que disparam texto clássico não conseguem dirigir o
Hyprland. **Waybar é o caso concreto** — `hyprland/workspaces` troca de workspace mandando
`dispatch workspace N`, então clicar no módulo não faz nada. Solução aplicada:
`common/waybar/config.jsonc` usa **`ext/workspaces`** (protocolo `ext-workspace-v1`, ativa
via Wayland puro, sem dispatch de texto) com `"sort-by": "number"`.

- Testado com cliente Wayland cru: o `activate` do ext-workspace **funciona** pra trocar
  workspace no monitor em foco (1→4, 1→2, etc. OK). Limitação: ativar workspace que vive
  em OUTRO monitor troca lá mas não move o foco do teclado pra esse monitor — clicar o
  número na barra do monitor que você está olhando é o caminho que funciona 100%.
- `hyprctl dispatch` NÃO testa clique de barra. Clique em layer-shell não dá pra simular
  com uinput aqui (só `follow_mouse` responde); confiar no teste do protocolo + pedir
  pro usuário validar na mão.

- Espelhar/estender telas em runtime: `hyprctl keyword monitor ...` também morre ("non-legacy
  parsers") — usar `hyprctl eval 'hl.monitor({...})'` (é o que `scripts/mirror-toggle.sh` faz).

## Monitores: multi-host numa config só

`common/hypr/hyprland.lua` (seção MONITORS) usa **regra genérica `output=""` + regras
`desc:` específicas**. Regra cujo output não está conectado é ignorada sem erro, então o
mesmo arquivo cobre: notebook sozinho, notebook + projetor da facul (genérica liga
estendido; `SUPER+SHIFT+P` → `scripts/mirror-toggle.sh` alterna espelhamento), e o
desktop de casa (LG UltraWide `desc:LG Electronics LG ULTRAWIDE` à esquerda/principal em
`0x0`, AOC `desc:AOC 1970W` à direita em `3440x0`).

- Casar por `desc:` (não por `HDMI-A-1`/`DP-3`) — o nome da porta muda de máquina pra
  máquina, a descrição EDID não.
- `hyprctl keyword monitor ...` responde "keyword can't work with non-legacy parsers"
  (config é Lua). Pra testar ao vivo, editar o `.lua` e `hyprctl reload` — funciona.
- **Não há regra pra tela interna do notebook** — o usuário não sabe o nome dela e a regra
  genérica `output=""` já cobre (preferred/auto/scale 1). Se um dia precisar de scale
  diferente no painel do note, aí sim pegar o nome com `hyprctl monitors` e adicionar linha.
- `mirror-toggle.sh` parseia texto do `hyprctl monitors all` (sem jq — jq não está
  instalado). Usa `monitors all` porque monitor espelhando some do `monitors` normal.
- **`SUPER+SHIFT+M` → `scripts/monitor-toggle.sh`**: liga/desliga o AOC (pra ficar só no
  UltraWide). Desliga com `hl.monitor({ disabled = true })`; religar exige `disabled = false`
  EXPLÍCITO no mesmo `hl.monitor` (só passar mode/position não reativa). Monitor desligado
  aparece em `monitors all` com `disabled: true`.
- **Workspaces fixos por monitor** (só materializam onde o `desc:` existe): 1-5 no LG,
  6-10 no AOC, via `hl.workspace_rule({ persistent = true, monitor = "desc:..." })`. No
  notebook sozinho nenhuma regra casa e os 10 workspaces ficam no eDP como sempre.

## Teclado

Físico é **ANSI/US** (não ABNT2). `hyprland.lua` usa `kb_layout = "us"`,
`kb_variant = "intl"` (US Internacional com dead keys — igual ao ´ do ABNT2): `'`+vogal =
acento agudo, `'`+c = ç, `~`+a/o/n = til, `^`+vogal = circunflexo, `` ` ``+vogal = crase,
`"`+vogal = trema. `'` `"` `~` `^` `` ` `` literais: tecla + espaço. AltGr+, também dá ç.

- **`altgr-intl` foi testado e abandonado**: exige AltGr (Alt direito) pra TODO acento, o
  que é chato, e o Alt direito deixa de ser Alt (vira ISO_Level3_Shift). Com `intl` os dead
  keys não precisam de AltGr — só o Alt esquerdo importa (Alt+Tab etc.).
- **Alt direito NÃO é Alt** em qualquer variante `intl`/`altgr-intl`/`abnt2` (é o AltGr).
  Alt+Tab, Alt+F4 etc. = **Alt ESQUERDO**.
- Dead key é composição do lado do cliente (toolkit). Funciona em apps GTK/Qt/kitty/Firefox
  nativos; **Electron no Wayland (vesktop/Discord, Steam) tem bug conhecido de dead key** —
  se acento não sai só lá, é o app, não a config.
- `hyprctl eval` NÃO retorna valor (só "ok"), então não dá pra checar tecla presa com
  `hl.is_key_down` por ele; usar `hl.notification.create({ text = ..., time = N })` + `grim`.
- **Não testar teclado com uinput sintético neste ambiente** — os testes falharam (foco,
  timeout) e correm risco de deixar modificador preso (quebra Alt+Tab e digitação). Se
  acontecer: soltar os mods sintéticos ou relogar.

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
- **Som "abafado" vs Windows (headset JBL Quantum 360 Wireless)**: NÃO é bug de plumbing —
  já checado: sink em `S16LE 48000 2ch`, sem resample, sem downmix, profile `analog-stereo`,
  formato negociado limpo. É o timbre cru do headset (JBL afina escuro e conta com o EQ do
  QuantumENGINE, que só existe no Windows). **Resolvido** com EasyEffects 8:
  - Autostart: `easyeffects --service-mode` no `hyprland.lua` (`--gapplication-service` é
    deprecado no EE8). No-op se o pacote não existir. Precisa de `lsp-plugins-lv2` pro
    equalizador funcionar (dep OPCIONAL do easyeffects — instalar à mão).
  - Presets em `common/easyeffects/*.json` (formato EE7, o EE8 lê sem reclamar). Symlinkados
    pra `~/.local/share/easyeffects/output/` pelo `bootstrap.sh` (loop `*.json`; NÃO
    symlinkar a pasta `~/.config/easyeffects` inteira — o EE8 escreve o DB de settings em
    `db/` lá dentro). Não existe EQ público pro Quantum 360 Wireless; os prontos são AutoEq
    do 800 (`JBL-Quantum-800-AutoEq`, irmão mais próximo — padrão ativo) e do 400
    (`JBL-Quantum-400-AutoEq`), + um manual mais suave (`JBL-Quantum-360`). Trocar com
    `easyeffects -l <nome>`. AutoEq txt importável direto na GUI (plugin Equalizer → import).
  - EE8 reaplica o último preset de saída sozinho no start; `easyeffects -l <nome>` recarrega
    na mão, `easyeffects -s` mostra o ativo.
  - Não perder tempo procurando problema no PipeWire de novo.
- **Scroll no ícone de volume da Waybar não fazia nada**: `pulseaudio` module chamava
  `pamixer` (não instalado). Trocado pelo scroll nativo do Waybar (libpulse). As teclas de
  volume usam `wpctl` — ambos batem no mesmo sink default agora. `pamixer` continua fora;
  se for adicionar controle de volume em script, usar `wpctl`.
- **Touchpad "travado"**: neste hardware o toggle Fn é 100% EC/firmware
  (`touchpad_ctrl_via_ec=N` por padrão), invisível pro Linux — não tem log, não tem rfkill.
  `common/system/modprobe.d/` tem a opção pra expor isso ao kernel, se ainda não foi aplicada.
- Ver a seção "Confiabilidade" do README pros detalhes completos de cada um.
