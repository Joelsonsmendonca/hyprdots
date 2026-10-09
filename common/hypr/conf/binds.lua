---------------------
---- KEYBINDINGS ----
---------------------

-- Fonte única dos atalhos: scripts/show-keybinds.sh lê ESTE arquivo pra montar o
-- popup da Waybar. Bind feito com função anônima precisa de rótulo em KEY_LABELS lá.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "dolphin"
local scripts     = os.getenv("HOME") .. "/.config/hypr/scripts/"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + greater", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(scripts .. "power-menu.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))   -- hypridle chama o hyprlock
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

-------------------------
---- JANELAS / FLOAT ----
-------------------------

hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + CTRL + P",  hl.dsp.window.pin())   -- fixa flutuante em todos os workspaces

-- Modo PIP: flutua + encolhe pro canto + fixa (pin) em todos os workspaces — chamada de
-- vídeo enquanto usa outras janelas. SUPER+V só flutua e mantém o tamanho do tile.
-- Aperta de novo pra voltar a tiled.
hl.bind(mainMod .. " + F", function()
    local win = hl.get_active_window()
    if not win then return end

    if win.floating then
        hl.dispatch(hl.dsp.window.pin({ action = "off" }))
        hl.dispatch(hl.dsp.window.float({ action = "off" }))
    else
        hl.dispatch(hl.dsp.window.float({ action = "on" }))
        hl.dispatch(hl.dsp.window.resize({ x = 420, y = 260 }))

        local mon = hl.get_active_monitor()
        if mon then
            -- move() é em coordenadas GLOBAIS lógicas: soma a origem do monitor (senão no
            -- AOC, em 3440x0, a janela ia parar no LG) e divide o tamanho físico pelo scale.
            local scale = mon.scale or 1
            hl.dispatch(hl.dsp.window.move({
                x = mon.x + mon.width / scale - 440,
                y = mon.y + mon.height / scale - 280,
            }))
        end
        hl.dispatch(hl.dsp.window.pin({ action = "on" }))
    end
end)

-- Alt+Tab: sem bring_to_top, o foco ia pra uma flutuante escondida atrás de outra
-- e ela continuava invisível.
hl.bind("ALT + TAB", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- SUPER+SHIFT+setas: flutuante anda 50px; tiled troca de lugar com a vizinha.
-- (move({direction}) numa flutuante joga ela inteira pra borda do monitor.)
local function moveOrSwap(dir, dx, dy)
    return function()
        local win = hl.get_active_window()
        if win and win.floating then
            hl.dispatch(hl.dsp.window.move({ x = dx, y = dy, relative = true }))
        else
            hl.dispatch(hl.dsp.window.move({ direction = dir }))
        end
    end
end
hl.bind(mainMod .. " + SHIFT + left",  moveOrSwap("left",  -50,   0), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", moveOrSwap("right",  50,   0), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    moveOrSwap("up",      0, -50), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  moveOrSwap("down",    0,  50), { repeating = true })

-- SUPER+CTRL+setas: redimensiona pelo teclado (tiled ou flutuante)
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Binds customizados (portados do setup anterior)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("vesktop"))
hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("kitty -e btop"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(scripts .. "wifi-recover.sh"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(scripts .. "mirror-toggle.sh"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(scripts .. "monitor-toggle.sh"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(scripts .. "clipboard-history.sh"))
hl.bind(mainMod .. " + space",  hl.dsp.exec_cmd("fuzzel"))
hl.bind("PRINT", hl.dsp.exec_cmd(scripts .. "screenshot_clipboard.sh"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(scripts .. "screenshot_area_clipboard.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
