------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Estratégia multi-host: uma regra genérica de fallback + regras específicas por
-- monitor (casadas por `desc:`, que independem de qual porta física foi usada).
-- Regra cujo output não está conectado é ignorada em silêncio — então o MESMO
-- arquivo serve pros três cenários:
--   1. notebook sozinho          -> cai na regra genérica (tela nativa, scale 1)
--   2. notebook + projetor facul -> genérica liga o projetor estendido; SUPER+SHIFT+P
--                                   alterna espelhamento (scripts/mirror-toggle.sh)
--   3. desktop de casa           -> regras `desc:` abaixo posicionam os 2 monitores

-- Fallback pra QUALQUER saída (tela interna do notebook, projetor/TV da facul,
-- e qualquer coisa não listada abaixo): liga em modo estendido, resolução
-- preferida, scale 1. Cobre o notebook sozinho sem precisar saber o nome da
-- tela. Se um dia a tela do note precisar de scale diferente, adicionar aqui
-- uma linha `hl.monitor({ output = "<nome do hyprctl monitors>", ... })`.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })

-- Desktop de casa: LG UltraWide à esquerda (principal) + AOC 19" à direita.
-- Pra alinhar as bordas de baixo em vez das de cima, troque a posição do AOC
-- por "3440x672" (1440 - 768).
hl.monitor({ output = "desc:LG Electronics LG ULTRAWIDE", mode = "3440x1440@159.96", position = "0x0",    scale = 1.0 })
hl.monitor({ output = "desc:AOC 1970W",                   mode = "1366x768@59.79",   position = "3440x0", scale = 1.0 })

-- Workspaces fixos por monitor no desktop: 1-5 no LG (principal), 6-10 no AOC.
-- Regra pra monitor não conectado não materializa nada (testado) — no notebook
-- sozinho os 10 workspaces seguem no eDP normalmente.
-- SEM `persistent`: workspace vazio deixa de existir, então a Waybar (ext/workspaces,
-- que não tem classe CSS pra "vazio") mostra só os que têm janela. O vínculo
-- workspace -> monitor continua valendo quando ele é criado.
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "desc:LG Electronics LG ULTRAWIDE" })
end
for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "desc:AOC 1970W" })
end
