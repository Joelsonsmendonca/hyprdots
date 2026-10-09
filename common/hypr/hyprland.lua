-- Config do Hyprland (Lua, 0.55+). Referência da API: /usr/share/hypr/stubs/hl.meta.lua
-- https://wiki.hypr.land/Configuring/Start/
--
-- Dividida em módulos em conf/. Cada `require` roda num escopo Lua separado: erro num
-- arquivo NÃO derruba os outros (antes, um erro no meio do arquivo único matava tudo
-- que vinha depois). `local` de um arquivo não é visível nos outros.

require("conf.monitors")
require("conf.autostart")
require("conf.look")
require("conf.input")
require("conf.binds")
require("conf.rules")
