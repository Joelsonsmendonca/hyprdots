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

# Atalho inteligente para ativar venvs python (digite apenas: activate)
function activate
    if test -f .venv/bin/activate.fish
        builtin source .venv/bin/activate.fish
    else if test -f venv/bin/activate.fish
        builtin source venv/bin/activate.fish
    else
        echo "Nenhum ambiente virtual (.venv ou venv) encontrado no diretório atual."
    end
end

# Se digitar 'source .venv/bin/activate' por força do hábito do bash, redireciona para o .fish
function source
    if string match -r '(.*)/bin/activate$' -- "$argv[1]" >/dev/null; and test -f "$argv[1].fish"
        builtin source "$argv[1].fish"
    else
        builtin source $argv
    end
end

# Configuração e inicialização do Starship Prompt
set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
if type -q starship
    starship init fish | source
end
