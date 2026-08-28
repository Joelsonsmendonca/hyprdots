# Problemas conhecidos

Coisas quebradas ou com workaround que ainda não têm solução limpa. Uma entrada
por problema; fechar movendo pro histórico do git / README quando resolver.

---

## 1. Clicar num workspace na waybar não troca de workspace

**Status:** aberto · **Desde:** 2026-08-28 · **Área:** waybar + Hyprland (config Lua)
· **GitHub:** [#1](https://github.com/Joelsonsmendonca/hyprdots/issues/1)

### Sintoma
Clicar num número de workspace na waybar não faz nada. As binds `SUPER+número`
funcionam normal.

### Causa raiz
A config do Hyprland é Lua (`hyprland.lua`, API `hl.*`). Nesse modo o servidor
**rejeita todo dispatch em texto clássico**: qualquer `dispatch workspace 5`,
`dispatch exec …` — mandado por `hyprctl` ou direto no socket1 — é embrulhado em
`return hl.dispatch(workspace 5)` e quebra com erro de sintaxe Lua. Só funciona a
forma `hl.dsp.*` (ex.: `hyprctl dispatch 'hl.dsp.focus({ workspace = 5 })'`).

O módulo `hyprland/workspaces` da waybar troca de workspace mandando exatamente
`dispatch workspace N` → morre no servidor → clique não faz nada.

### O que já foi tentado
- **`ext/workspaces`** (protocolo `ext-workspace-v1`, ativa via Wayland puro, sem
  dispatch de texto). O protocolo em si **funciona** — testado com cliente Wayland
  cru, `activate` troca de workspace no monitor em foco (1→4, 1→2, etc. OK). Mas o
  clique na barra continuou não funcionando pro usuário mesmo com esse módulo.
  (Não deu pra simular clique em layer-shell no ambiente de teste; só `follow_mouse`
  respondia, então a validação final ficou com o usuário — e falhou.)
- `hl.dispatch("workspace 5")` (string) → `hl.dispatch` só aceita objeto dispatcher.
- Shim em Lua → impossível, o erro é de *parse*, antes de qualquer chamada.

### Próximos passos possíveis
- Módulo custom por workspace (`custom/ws1`…`custom/ws10`), cada botão com
  `on-click` = `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'`. Garantido, mas
  perde o comportamento automático (estado ativo, urgente) — precisaria de script
  gerando JSON.
- Converter `hyprland.lua` de volta pra `hyprland.conf` clássico (restaura toda a
  compat com waybar e o ecossistema). Contraria a escolha atual de usar Lua.
- Acompanhar upstream: waybar `ext/workspaces` + Hyprland ext-workspace `activate`
  cross-monitor / foco de teclado.

### Detalhes técnicos
Ver `CLAUDE.md` → seção "Dispatch em TEXTO clássico está morto (parser Lua)".
