#!/usr/bin/env python3
"""Chip de uso de IA pra Waybar: um módulo por provedor (CLD, AG...).

Uso: ai-usage.py <vendor-id>     (ex.: anthropic, antigravity)

Lê `ai-usagebar usage --json` (todos os provedores habilitados em
~/.config/ai-usagebar/config.toml) com cache curto em $XDG_RUNTIME_DIR, pra que
os N módulos da barra não façam N chamadas de rede. Saída: JSON da Waybar
{text, tooltip, class}.

- text: sigla + o percentual do limite MAIS apertado do provedor (o maior entre
  sessão/semana/etc.), colorido pela severidade.
- tooltip: detalhe do provedor do chip (barra, renovação, ritmo) + resumo de uma
  linha dos outros. Monoespaçado: a fonte vem do `tooltip label` no style.css.
"""
import fcntl
import html
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime

CACHE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "ai-usage.json")
CACHE_TTL = 240  # o módulo roda a cada 300s; sinal 13 força refresh (cache expira antes)

SHORT = {"anthropic": "CLD", "antigravity": "AG"}
VENDOR_COLOR = {"anthropic": "#e0af68", "antigravity": "#7dcfff"}
SEV_COLOR = {"low": "#9ece6a", "mid": "#e0af68", "high": "#ff9e64", "critical": "#f7768e"}
NUM_COLOR = {"low": "#c0caf5", "mid": "#e0af68", "high": "#ff9e64", "critical": "#f7768e"}
MUTED, DIM, TRACK, FG = "#565f89", "#a9b1d6", "#2a2e45", "#c0caf5"

WIDTH = 40      # largura do tooltip em colunas
BAR = WIDTH     # largura da barra de progresso


def load():
    with open(CACHE + ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)  # o 2º módulo espera o 1º terminar e reusa
        try:
            if time.time() - os.path.getmtime(CACHE) < CACHE_TTL:
                with open(CACHE) as f:
                    return json.load(f)
        except (OSError, ValueError):
            pass
        out = subprocess.run(["ai-usagebar", "usage", "--json"],
                             capture_output=True, text=True, timeout=60).stdout
        data = json.loads(out)
        tmp = CACHE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(data, f)
        os.replace(tmp, CACHE)
        return data


def window_name(m):
    secs = m.get("window_secs") or 0
    return "5h" if secs <= 86400 else "7d"


def label_pt(m):
    lab = m["label"].replace("Session", "Sessão").replace("Weekly", "Semana")
    if "(" not in lab:
        lab = f"{lab} ({window_name(m)})"
    return lab


def detail_pt(detail):
    """'Resets in 2h 10m · 56% elapsed · 27pts under' -> (texto, elapsed%)"""
    parts, elapsed = [], None
    for chunk in (detail or "").split("·"):
        chunk = chunk.strip()
        if m := re.match(r"Resets in (.+)", chunk):
            parts.append(f"renova em {m.group(1)}")
        elif m := re.match(r"(\d+)% elapsed", chunk):
            elapsed = int(m.group(1))
        elif m := re.match(r"(\d+)pts (under|over)", chunk):
            lado = "abaixo" if m.group(2) == "under" else "acima"
            parts.append(f"{m.group(1)} pts {lado} do ritmo")
        elif chunk:
            parts.append(chunk)
    return " · ".join(parts), elapsed


def span(text, color, bold=False):
    w = " font_weight='bold'" if bold else ""
    return f"<span foreground='{color}'{w}>{html.escape(text)}</span>"


def justify(left_plain, left_markup, right_plain, right_markup):
    pad = max(1, WIDTH - len(left_plain) - len(right_plain))
    return left_markup + " " * pad + right_markup


def bar(pct, elapsed, color):
    filled = round(BAR * min(max(pct, 0), 100) / 100)
    cells = [span("━", color)] * filled + [span("━", TRACK)] * (BAR - filled)
    if elapsed is not None:
        pos = min(BAR - 1, round(BAR * elapsed / 100))
        cells[pos] = span("┃", DIM)
    return "".join(cells)


def worst(entry):
    ms = entry.get("metrics") or []
    return max(ms, key=lambda m: m.get("percent") or 0) if ms else None


def detail_block(entry):
    lines = []
    plan = entry.get("plan") or entry.get("display_name") or entry["id"]
    upd = ""
    if entry.get("fetched_at"):
        t = datetime.fromisoformat(entry["fetched_at"].replace("Z", "+00:00")).astimezone()
        upd = f"atualizado {t:%H:%M}"
    lines.append(justify(plan, span(plan, FG, bold=True), upd, span(upd, MUTED)))
    for m in entry.get("metrics") or []:
        pct = m.get("percent") or 0
        sev = m.get("severity", "low")
        color = SEV_COLOR.get(sev, FG) if pct > 0 else DIM
        lab, val = label_pt(m), f"{pct}%"
        text, elapsed = detail_pt(m.get("detail"))
        lines.append("")
        lines.append(justify(lab, html.escape(lab), val, span(val, color, bold=True)))
        lines.append(bar(pct, elapsed, color))
        if text:
            lines.append(span(text, MUTED))
    return lines


def summary_line(entry):
    name = entry.get("display_name") or entry["id"]
    m = worst(entry)
    if entry.get("error") or not m:
        right = "erro"
        return justify(name, span(name, VENDOR_COLOR.get(entry["id"], DIM)), right, span(right, "#f7768e"))
    right = f"{m.get('percent') or 0}% {('semana' if window_name(m) == '7d' else '5h')}"
    color = NUM_COLOR.get(m.get("severity", "low"), FG)
    return justify(name, span(name, VENDOR_COLOR.get(entry["id"], DIM)), right, span(right, color, bold=True))


def main():
    vendor = sys.argv[1] if len(sys.argv) > 1 else "anthropic"
    short = SHORT.get(vendor, vendor[:3].upper())
    try:
        data = load()
    except Exception as e:  # sem rede, binário ausente, JSON quebrado
        print(json.dumps({"text": f"{short} !", "tooltip": html.escape(str(e)), "class": ["error", vendor]}))
        return

    entries = data.get("entries", [])
    me = next((e for e in entries if e.get("id") == vendor), None)
    if me is None:
        print(json.dumps({"text": "", "class": "hidden"}))  # provedor desligado: some da barra
        return
    m = worst(me)
    if me.get("error") or m is None:
        print(json.dumps({"text": f"{short} !", "tooltip": html.escape(str(me.get("error") or "sem dados")),
                          "class": ["error", vendor]}))
        return

    pct, sev = m.get("percent") or 0, m.get("severity", "low")
    text = f"{short} {span(str(pct), NUM_COLOR.get(sev, FG), bold=True)}"

    tip = detail_block(me)
    others = [e for e in entries if e is not me]
    if others:
        tip += ["", span("─" * WIDTH, TRACK)] + [summary_line(e) for e in others]

    print(json.dumps({"text": text, "tooltip": "\n".join(tip), "class": [sev, vendor]}))


if __name__ == "__main__":
    main()
