#!/usr/bin/env python3
# Le os hl.bind(...) direto do hyprland.lua e mostra num popup do wofi.
# hyprland.lua e a unica fonte de verdade para os binds (nao ha .conf duplicado).
import os
import re

HYPR_LUA = os.path.expanduser("~/.config/hypr/hyprland.lua")
STYLE = os.path.expanduser("~/.config/hypr/scripts/keybinds-style.css")

SECTION_START = "KEYBINDINGS ----"
SECTION_END = "WINDOWS AND WORKSPACES ----"

ACTION_LABELS = {
    "window.close": "fechar janela",
    "window.pseudo": "pseudo-tiling",
    "window.cycle_next": "alternar janelas",
    "window.drag": "mover janela (mouse)",
    "window.resize": "redimensionar janela (mouse)",
    "window.float": "alternar flutuante",
}


def split_top_level(s, sep=","):
    parts, depth, cur, in_str = [], 0, "", None
    for i, c in enumerate(s):
        if in_str:
            cur += c
            if c == in_str and s[i - 1] != "\\":
                in_str = None
        elif c in "\"'":
            in_str = c
            cur += c
        elif c in "([{":
            depth += 1
            cur += c
        elif c in ")]}":
            depth -= 1
            cur += c
        elif c == sep and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += c
    if cur.strip():
        parts.append(cur)
    return [p.strip() for p in parts]


def extract_calls(text, funcname):
    """Find funcname(...) calls at any nesting depth, return their raw argument strings."""
    calls, marker, idx = [], funcname + "(", 0
    while True:
        idx = text.find(marker, idx)
        if idx == -1:
            break
        depth, in_str, i = 0, None, idx + len(marker) - 1
        while i < len(text):
            c = text[i]
            if in_str:
                if c == in_str and text[i - 1] != "\\":
                    in_str = None
            elif c in "\"'":
                in_str = c
            elif c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        calls.append(text[idx + len(marker):i])
        idx = i + 1
    return calls


def strip_comment(line):
    """Remove a trailing Lua `--` comment, ignoring `--` that appears inside a string literal."""
    in_str = None
    for i, c in enumerate(line[:-1]):
        if in_str:
            if c == in_str and line[i - 1] != "\\":
                in_str = None
        elif c in "\"'":
            in_str = c
        elif c == "-" and line[i + 1] == "-":
            return line[:i]
    return line


def humanize_key(expr):
    expr = expr.strip().replace("mainMod", "SUPER")
    parts = []
    for p in expr.split(".."):
        p = p.strip()
        if p.startswith('"') and p.endswith('"'):
            parts.append(p[1:-1])
        else:
            parts.append(p)
    return "".join(parts).strip()


def humanize_action(expr, var_defs=None):
    var_defs = var_defs or {}
    expr = expr.strip()
    m = re.match(r"hl\.dsp\.([\w.]+)\((.*)\)$", expr, re.S)
    if not m:
        return expr
    fn, arg = m.group(1), m.group(2).strip()

    if fn == "exec_cmd":
        arg = arg.replace('os.getenv("HOME")', "~")
        parts = []
        for p in arg.split(".."):
            p = p.strip()
            if p.startswith('"') and p.endswith('"'):
                parts.append(p[1:-1])
            elif p in var_defs:
                parts.append(var_defs[p])
            else:
                parts.append(p)
        return f"exec: {''.join(parts)}"

    if fn == "layout":
        return f"layout: {arg.strip(chr(34))}"

    if fn == "workspace.toggle_special":
        return f"workspace especial: {arg.strip(chr(34))}"

    if fn == "focus":
        d = re.search(r'direction\s*=\s*"(\w+)"', arg)
        w = re.search(r"workspace\s*=\s*([^\s,}]+)", arg)
        if d:
            return f"focar janela: {d.group(1)}"
        if w:
            return f"ir para workspace {w.group(1).strip(chr(34))}"

    if fn == "window.move":
        w = re.search(r"workspace\s*=\s*([^\s,}]+)", arg)
        if w:
            return f"mover janela para workspace {w.group(1).strip(chr(34))}"

    return ACTION_LABELS.get(fn, expr)


def main():
    text = open(HYPR_LUA, encoding="utf-8").read()

    var_defs = {
        name: value
        for name, value in re.findall(r'local\s+(\w+)\s*=\s*"([^"]*)"', text)
    }

    start = text.index(SECTION_START)
    end = text.index(SECTION_END, start)
    section = text[start:end]

    # A workspace loop (mainMod/SHIFT + 1..0) is generated dynamically and has
    # no literal key names to parse, so it's summarized separately below.
    loop_match = re.search(r"for i = 1, 10 do.*?\bend\b", section, re.S)
    if loop_match:
        section = section[: loop_match.start()] + section[loop_match.end():]

    entries = []
    for line in section.splitlines():
        line = strip_comment(line)
        if "hl.bind(" not in line:
            continue
        inner = extract_calls(line, "hl.bind")
        if not inner:
            continue
        args = split_top_level(inner[0])
        if len(args) < 2:
            continue
        entries.append((humanize_key(args[0]), humanize_action(args[1], var_defs)))

    if loop_match:
        entries.append(("SUPER + [0-9]", "ir para workspace 1-10"))
        entries.append(("SUPER + SHIFT + [0-9]", "mover janela para workspace 1-10"))

    lines = []
    for key, action in entries:
        key = key.replace("&", "&amp;").replace("<", "&lt;")
        action = action.replace("&", "&amp;").replace("<", "&lt;")
        lines.append(
            f"<b><span foreground='#e0af68'>{key:<26}</span></b>  "
            f"<span foreground='#7dcfff'>{action}</span>"
        )

    import subprocess

    subprocess.run(
        ["wofi", "--dmenu", "--allow-markup", "--style", STYLE,
         "--prompt", "  Atalhos", "--width", "780", "--height", "640", "--insensitive"],
        input="\n".join(lines),
        text=True,
    )


if __name__ == "__main__":
    main()
