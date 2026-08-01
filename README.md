# hyprdots

Configurações pessoais de desktop para [Hyprland](https://hyprland.org/), incluindo Waybar, Kitty, Rofi e Wofi.

## O que tem aqui

| App | O que faz | Config |
| --- | --- | --- |
| [Hyprland](https://hyprland.org/) | Compositor Wayland | `common/hypr/hyprland.lua` |
| [Waybar](https://github.com/Alexays/Waybar) | Barra de status | `common/waybar/` |
| [Kitty](https://sw.kovidgoyal.io/kitty/) | Terminal | `common/kitty/kitty.conf` |
| [Rofi](https://github.com/davatorium/rofi) | Launcher | `common/rofi/config.rasi` |
| [Fuzzel](https://codeberg.org/dnkl/fuzzel) | Launcher de apps (`SUPER + Space`) | `common/fuzzel/fuzzel.ini` |
| [Wofi](https://hg.sr.ht/~scoopta/wofi) | Menu/dmenu (energia, popup de atalhos) | `common/wofi/` |
| [UWSM](https://github.com/Vladimir-csp/uwsm) | Environment do Hyprland (variáveis pré-login) | `common/uwsm/env-hyprland` |

### Destaques

- Config do Hyprland em **Lua** (`hyprland.lua`), usando o suporte nativo do `hyprlang` — binds, monitores, regras de janela e autostart tudo num lugar só.
- Popup de atalhos (`SUPER + tecla` na Waybar) que lê os `hl.bind(...)` direto do `hyprland.lua` e monta a lista dinamicamente via `wofi` — **fonte única de verdade**, sem lista duplicada para manter sincronizada.
- Menu de energia (`common/hypr/scripts/power-menu.sh`) e screenshot para a área de transferência (`screenshot_clipboard.sh`, via `grim` + `slurp` + `wl-copy`).
- Tema consistente entre Waybar / Wofi / popup de atalhos, usando `JetBrainsMono Nerd Font Mono`.

## Economia de energia (notebook híbrido AMD + NVIDIA)

> Específico para hardware com iGPU AMD + dGPU NVIDIA Optimus (ex.: Lenovo Legion com Ryzen + RTX mobile). Se sua máquina não tem duas GPUs, ignore esta seção.

**O problema:** por padrão o Hyprland (via Aquamarine) escolhe sozinho qual GPU usa para compor a tela, e nesse hardware ele escolhia a dGPU NVIDIA. Isso mantém `/dev/nvidia*` aberto o tempo todo, o que impede a GPU de entrar em runtime suspend — mesmo 100% ociosa (0% de uso), ela fica presa em D0/P5 consumindo energia.

**Como medir o impacto antes de mexer em qualquer coisa:**

```bash
# consumo total do sistema, em watts, agora
upower -i "$(upower -e | grep BAT)" | grep energy-rate

# quanto disso é só a GPU dedicada, parada
nvidia-smi --query-gpu=power.draw,utilization.gpu --format=csv
```

Neste notebook, isso mostrou **9.6 W de consumo total, dos quais 9.2 W eram só a dGPU parada** — ou seja, quase 100% do gasto de energia em repouso vinha de uma GPU que não estava fazendo nada. Rode os dois comandos acima na sua máquina antes de decidir se vale a pena: se a dGPU já aparece com poucos watts (ou o `nvidia-smi` falha porque ela já está suspensa), o problema não é esse e essa mudança não vai ajudar muito.

**A correção:** `common/uwsm/env-hyprland` define `AQ_DRM_DEVICES` apontando só para a iGPU, então o Hyprland nunca abre a dGPU — ela fica livre para suspender de verdade. Isso é lido pelo UWSM *antes* do Hyprland iniciar, então **precisa de logout/login (ou reboot) para valer** — não tem como trocar a GPU do compositor em tempo real, isso é uma limitação de qualquer compositor Wayland (não só do Hyprland), já que trocar a GPU primária significa recriar o contexto gráfico de todo mundo que está na tela.

**Para apps que precisam da dGPU** (jogos, Blender, etc.), sem precisar togglar nada nem fazer logout:

```bash
nvidia-offload glxgears      # roda só esse processo na NVIDIA via PRIME
nvidia-offload steam
```

O wrapper (`common/hypr/scripts/nvidia-offload.sh`, symlinkado em `~/.local/bin/nvidia-offload`) seta as variáveis de PRIME render offload, sobe o `power-profiles-daemon` pra `performance` enquanto o comando roda, e restaura o profile anterior quando ele termina. A dGPU acorda só pra esse processo e volta a dormir depois — isso sim é dinâmico, não precisa de logout.

**Validando o resultado** (depois do logout/login): rode os mesmos dois comandos de novo. `nvidia-smi` deve falhar com algo como "couldn't communicate" (GPU suspensa) e o `energy-rate` do `upower` deve cair bem perto do valor que sobrar sem a GPU.

## Pré-requisitos

Testado em Arch Linux. Pacotes necessários:

```bash
sudo pacman -S hyprland uwsm waybar kitty wofi fuzzel grim slurp wl-clipboard \
    brightnessctl wireplumber pavucontrol dolphin btop ttf-jetbrains-mono-nerd \
    python playerctl power-profiles-daemon

# rofi com suporte a Wayland
sudo pacman -S rofi-wayland
```

`python` é usado pelo `show-keybinds.sh` (o popup de atalhos lê os binds direto do `hyprland.lua`).

Apps referenciados nos binds que não vêm do repositório oficial (instale via AUR com `yay`/`paru` se quiser tudo funcionando, ou ajuste os binds em `hyprland.lua`):

```bash
yay -S visual-studio-code-bin vesktop-bin brave-bin
```

## Instalação

1. Clone o repositório em `~/dotfiles`:

   ```bash
   git clone https://github.com/Joelsonsmendonca/hyprdots.git ~/dotfiles
   ```

2. Faça backup de configs existentes (se já tiver algo em `~/.config`):

   ```bash
   for app in hypr kitty rofi waybar wofi fuzzel uwsm; do
       [ -e "$HOME/.config/$app" ] && [ ! -L "$HOME/.config/$app" ] && \
           mv "$HOME/.config/$app" "$HOME/.config/${app}.bak"
   done
   ```

3. Crie os symlinks para `~/.config`:

   ```bash
   mkdir -p ~/.config
   for app in hypr kitty rofi waybar wofi fuzzel uwsm; do
       ln -sfn "$HOME/dotfiles/common/$app" "$HOME/.config/$app"
   done
   ```

4. (Só em notebook híbrido AMD+NVIDIA) crie o atalho do wrapper de offload:

   ```bash
   mkdir -p ~/.local/bin
   ln -sfn "$HOME/.config/hypr/scripts/nvidia-offload.sh" ~/.local/bin/nvidia-offload
   ```

   Ajuste o caminho PCI em `common/uwsm/env-hyprland` para o da sua GPU (`lspci | grep VGA` mostra os endereços) antes disso — o valor atual é específico deste notebook.

5. Reinicie o Hyprland (ou faça logout/login) para carregar as novas configs.

## Estrutura

```
common/
├── hypr/
│   ├── hyprland.lua          # config principal do Hyprland (única fonte dos binds)
│   └── scripts/              # power-menu, screenshot, popup de atalhos, nvidia-offload
├── kitty/kitty.conf
├── rofi/config.rasi
├── fuzzel/fuzzel.ini          # launcher de apps (SUPER + Space)
├── uwsm/
│   └── env-hyprland          # variáveis pré-login (ex.: qual GPU o Hyprland usa)
├── waybar/
│   ├── config.jsonc
│   └── style.css
└── wofi/
    ├── style.css
    └── scripts/               # menus custom (sistema, webapps, menu principal)
```

## Atualizando

Como `~/.config/<app>` é um symlink para dentro deste repositório, qualquer edição feita direto nos arquivos já reflete no repo. Basta:

```bash
cd ~/dotfiles
git add -A
git commit -m "descreva a mudança"
git push
```
