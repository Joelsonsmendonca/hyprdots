# hyprdots

Configurações pessoais de desktop para [Hyprland](https://hyprland.org/), incluindo Waybar, Kitty, Rofi e Wofi.

## O que tem aqui

| App | O que faz | Config |
| --- | --- | --- |
| [Hyprland](https://hyprland.org/) | Compositor Wayland | `common/hypr/hyprland.lua` |
| [Waybar](https://github.com/Alexays/Waybar) | Barra de status | `common/waybar/` |
| [Kitty](https://sw.kovidgoyal.io/kitty/) | Terminal | `common/kitty/kitty.conf` |
| [Rofi](https://github.com/davatorium/rofi) | Launcher | `common/rofi/config.rasi` |
| [Wofi](https://hg.sr.ht/~scoopta/wofi) | Menu/dmenu (drun, energia, atalhos) | `common/wofi/` |

### Destaques

- Config do Hyprland em **Lua** (`hyprland.lua`), usando o suporte nativo do `hyprlang` — binds, monitores, regras de janela e autostart tudo num lugar só.
- Popup de atalhos (`SUPER + tecla` na Waybar) que lê `common/hypr/config/keybinds.conf` e monta a lista dinamicamente via `wofi` — não é uma lista hardcoded.
- Menu de energia (`common/hypr/scripts/power-menu.sh`) e screenshot para a área de transferência (`screenshot_clipboard.sh`, via `grim` + `slurp` + `wl-copy`).
- Tema consistente entre Waybar / Wofi / popup de atalhos, usando `JetBrainsMono Nerd Font Mono`.

> **Nota:** os binds "de verdade" ficam em `hyprland.lua` (seção `KEYBINDINGS`). O arquivo `config/keybinds.conf` é usado só pelo `show-keybinds.sh` para gerar o popup visual — se você mudar um bind no `.lua`, espelhe a mudança nesse arquivo também para o popup continuar correto.

## Pré-requisitos

Testado em Arch Linux. Pacotes necessários:

```bash
sudo pacman -S hyprland waybar kitty wofi grim slurp wl-clipboard \
    brightnessctl wireplumber pavucontrol dolphin btop ttf-jetbrains-mono-nerd

# rofi com suporte a Wayland
sudo pacman -S rofi-wayland
```

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
   for app in hypr kitty rofi waybar wofi; do
       [ -e "$HOME/.config/$app" ] && [ ! -L "$HOME/.config/$app" ] && \
           mv "$HOME/.config/$app" "$HOME/.config/${app}.bak"
   done
   ```

3. Crie os symlinks para `~/.config`:

   ```bash
   mkdir -p ~/.config
   for app in hypr kitty rofi waybar wofi; do
       ln -sfn "$HOME/dotfiles/common/$app" "$HOME/.config/$app"
   done
   ```

4. Reinicie o Hyprland (ou faça logout/login) para carregar as novas configs.

## Estrutura

```
common/
├── hypr/
│   ├── hyprland.lua          # config principal do Hyprland
│   ├── config/keybinds.conf  # fonte para o popup de atalhos
│   └── scripts/              # power-menu, screenshot, popup de atalhos
├── kitty/kitty.conf
├── rofi/config.rasi
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
