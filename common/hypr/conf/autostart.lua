-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- Waybar, swaync, hypridle e cliphist NÃO sobem daqui: são unidades systemd --user
-- habilitadas (WantedBy=graphical-session.target, que o UWSM ativa). Antes o swaync
-- subia aqui E pela unidade, e a segunda instância morria ("already running") com
-- swaync.service em failed. Habilitar: ver bootstrap.sh.
--
-- O que sobra aqui vai por `uwsm app --`, que põe o processo num scope systemd
-- próprio (igual aos apps de ~/.config/autostart) em vez de filho direto do Hyprland.

hl.on("hyprland.start", function ()
  hl.exec_cmd("uwsm app -- /usr/lib/polkit-kde-authentication-agent-1")
  -- EQ do áudio em background (reaplica o último preset de saída do EasyEffects
  -- — presets do headset JBL em common/easyeffects/). Sem janela, sem efeito se
  -- o easyeffects não estiver instalado. Ver README -> Áudio.
  hl.exec_cmd("uwsm app -- easyeffects --service-mode")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
