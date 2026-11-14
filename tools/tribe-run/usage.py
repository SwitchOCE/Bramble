#!/usr/bin/env python3
"""Tokens and API-equivalent cost by model, from Claude Code transcripts.

Usage: usage.py --session-dir DIR [--since ISO_TIME] [--allow MODEL ...]
DIR is the orchestrator's own transcript folder, ~/.claude/projects/<project>/<session-id>/
(its subagents and workflow agents live under it), plus the <session-id>.jsonl next to it.
Counts each API message once (by message id). Prices per million tokens, list price.
Exits 1 if it finds no calls at all, or any model not in --allow
(default: claude-opus-5-5 and claude-fable-5-2), and names the files where they appear.
"""
import argparse, glob, json, os
from collections import defaultdict

PRICE = {  # input, 5m cache write, 1h cache write, cache read, output
    "claude-opus-5-5": (4, 5, 8, 0.20, 20),
    "claude-fable-5-2": (8, 10, 16, 0.20, 40),
    "claude-sonnet-5-5": (2, 2.5, 4, 0.10, 10),
}
ap = argparse.ArgumentParser()
ap.add_argument("--since", default="")
ap.add_argument("--session-dir", required=True)
ap.add_argument("--allow", nargs="*", default=["claude-opus-5-5", "claude-fable-5-2"])
a = ap.parse_args()
sd = os.path.abspath(os.path.expanduser(a.session_dir)).rstrip("/")
files = glob.glob(sd + "/**/*.jsonl", recursive=True) + glob.glob(sd + ".jsonl")
where = defaultdict(set)
tot = defaultdict(lambda: [0, 0, 0, 0, 0, 0])  # in, w5, w1, read, out, calls
seen = set()
for f in files:
    for line in open(f, errors="ignore"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        m = d.get("message")
        if not isinstance(m, dict) or not m.get("usage") or (d.get("timestamp", "") < a.since):
            continue
        key = m.get("id") or (f, d.get("uuid"))
        if key in seen:
            continue
        seen.add(key)
        if m.get("model") == "<synthetic>":
            continue
        u, t = m["usage"], tot[m.get("model", "?")]
        where[m.get("model", "?")].add(f)
        cc = u.get("cache_creation") or {}
        w1 = cc.get("ephemeral_1h_input_tokens", 0)
        t[0] += u.get("input_tokens", 0); t[1] += u.get("cache_creation_input_tokens", 0) - w1; t[2] += w1
        t[3] += u.get("cache_read_input_tokens", 0); t[4] += u.get("output_tokens", 0); t[5] += 1
grand = 0
for model, t in sorted(tot.items()):
    p = PRICE.get(model)
    usd = sum(x * y for x, y in zip(t[:5], p)) / 1e6 if p else float("nan")
    grand += usd if p else 0
    print(f"{model:22} calls {t[5]:6}  out {t[4]:>11,}  in {t[0]+t[1]+t[2]+t[3]:>13,}  ${usd:,.2f}")
print(f"{'total':22} ${grand:,.2f}")
bad = [m for m in tot if m not in a.allow]
for m in bad:
    print(f"NOT ALLOWED: {m} in", *sorted(where[m]), sep="\n  ")
if not tot:
    print("No calls found: check --session-dir.")
raise SystemExit(1 if bad or not tot else 0)
