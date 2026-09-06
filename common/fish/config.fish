# Remove mensagem padrão de boas-vindas do fish
set -g fish_greeting ""

# Garante ~/.local/bin no PATH
fish_add_path $HOME/.local/bin

# Aliases modernos
if type -q eza
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -la --icons --group-directories-first"
    alias lt="eza --tree --level=2 --icons"
end

if type -q bat
    alias cat="bat --paging=never --style=plain"
end

# Inicialização do Starship Prompt
if type -q starship
    starship init fish | source
end

# Configuração do Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
