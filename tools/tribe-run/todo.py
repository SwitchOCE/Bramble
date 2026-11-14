#!/usr/bin/env python3
"""List what each design needs next, as workflow args. Usage: todo.py [--write] ; prints counts and JSON per step."""
import json, subprocess, sys
from pathlib import Path
W = Path("/home/alex/code/Bramble-ideation-tribe-run"); RUN = W / "docs/design/tribe-run/run"
seeds = {p.stem: json.loads(p.read_text()) for p in (RUN / "seeds").glob("*.json") if not p.name.startswith("_")}
for s in seeds.values():
    for r in s["routes"]:
        (RUN / "designs" / f"{s['id']}--{r}").mkdir(parents=True, exist_ok=True)
cmd = ["python3", str(W / "tools/tribe-run/decide.py"), str(RUN)] + (["--write"] if "--write" in sys.argv else [])
out = {}
for line in subprocess.run(cmd, capture_output=True, text=True).stdout.splitlines():
    d = json.loads(line); seed, _, route = d["design"].partition("--")
    out.setdefault(d["next"], []).append({"id": d["design"], "seed": seed, "name": seeds[seed]["name"], "route": route, "v": d["v"], "missing": d["missing"], "need": d["next"]})
print({k: len(v) for k, v in out.items()})
json.dump(out, open(Path(__file__).with_name("todo.json"), "w"))
