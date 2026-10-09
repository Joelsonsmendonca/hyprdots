---------------
---- INPUT ----
---------------

hl.config({
    input = {
        -- Teclado físico ANSI/US. "intl" (US Internacional c/ dead keys) — igual
        -- ao ´ do ABNT2:
        --   '  então vogal  -> á é í ó ú       |  '  então c  -> ç
        --   ~  então a/o/n  -> ã õ ñ           |  ^  então vogal -> â ê ô
        --   `  então vogal  -> à              |  "  então vogal -> ä ë ü
        --   AltGr + ,       -> ç  (também funciona)
        -- Pra digitar ' " ~ ^ ` literais: a tecla + espaço.
        kb_layout  = "us",
        kb_variant = "intl",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        -- Num Lock ligado ao iniciar a sessão. A tela de login (SDDM) é outro processo:
        -- ver common/system/sddm.conf.d/numlock.conf.
        numlock_by_default = true,

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Config por dispositivo: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
-- (nome do dispositivo em `hyprctl devices`)
-- hl.device({ name = "<nome>", sensitivity = -0.5 })
