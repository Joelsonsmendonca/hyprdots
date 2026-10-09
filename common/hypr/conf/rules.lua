--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- Regras são avaliadas de cima pra baixo e a ÚLTIMA que casa vence em conflito.
--
-- Removidas de propósito (não recolocar sem pensar):
--   * no_initial_focus em `class = ".*"`: NENHUMA janela nova ganhava foco — diálogo de
--     salvar/abrir, seletor de arquivo e até o prompt de senha do polkit abriam com o
--     teclado ainda na janela de trás (senha digitada no Discord, etc.). Se algum app
--     roubar foco ao abrir, criar regra só pra ele (`class = "^steam$"`).
--   * center em `float = true`: centralizava todo diálogo no MONITOR (no UltraWide
--     ficava longe da janela-mãe) e anulava a regra `move` do hyprland-run. O Hyprland
--     já abre flutuante centralizada por padrão.

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Regras portadas do setup anterior (windowrules.conf + hyprland.conf)
hl.window_rule({
    name  = "dolphin-copy-move-float",
    match = { class = "org.kde.dolphin", title = "^(Copying|Moving)$" },
    float = true,
})

hl.window_rule({
    name  = "gnome-calculator-float",
    match = { class = "org.gnome.Calculator" },
    float = true,
    size  = "360 616",
})

hl.window_rule({
    name  = "gnome-text-editor-float",
    match = { class = "org.gnome.TextEditor" },
    float = true,
    size  = "500 600",
})

hl.window_rule({
    name  = "gnome-clocks-float",
    match = { class = "org.gnome.clocks" },
    float = true,
    size  = "600 500",
})

-- Utilitários de sistema (áudio, bluetooth, rede, seletor de arquivo do portal GTK):
-- flutuam com tamanho proporcional ao monitor; persistent_size lembra o tamanho se
-- você redimensionar.
hl.window_rule({
    name  = "system-utils-float",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|xdg-desktop-portal-gtk)$" },
    float = true,
    size  = { "monitor_w*0.4", "monitor_h*0.6" },
    persistent_size = true,
})

-- Picture-in-Picture do navegador (Brave/Chromium/Firefox): flutua, fica em todos os
-- workspaces e vai pro canto inferior direito.
hl.window_rule({
    name  = "browser-pip",
    match = { title = "^(Picture.in.[Pp]icture)$" },
    float = true,
    pin   = true,
    keep_aspect_ratio = true,
    move  = { "monitor_w-window_w-20", "monitor_h-window_h-20" },
})
