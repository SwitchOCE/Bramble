#!/usr/bin/env python3
"""Main tribe and placement of one label's runs in a ghost field, plus counts per label.

Usage: tribe_picks.py FIELD LABEL
Main tribe: the tribe with the most units on the final board, if it has 4 or more; units in
hand are not counted. Shared (tribeless) units don't count toward a tribe.
"""
import collections
import json
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parents[2]
field, label = pathlib.Path(sys.argv[1]), sys.argv[2]
names = {"thorn": "briar"}
tribe = {}
for f in root.glob("src/content/*/units.json"):
    for card in json.loads(f.read_text())["cards"]:
        tribe[card["id"] if isinstance(card, dict) else card] = f.parent.name
rows = [json.loads(line) for line in open(field / "index.jsonl")]
print("field:", dict(collections.Counter(r["label"] for r in rows)))
share, place, hand = collections.Counter(), collections.defaultdict(list), []
for r in rows:
    if r["label"] != label:
        continue
    run = json.loads((field / "runs" / r["id"][:2] / f"{r['id']}.json").read_text())
    payload = run["turns"][-1]["payload"]
    count = collections.Counter(tribe.get(u["def"], "?") for u in payload["board"] if u)
    count.pop("shared", None)
    top = count.most_common(1)
    main = top[0][0] if top and top[0][1] >= 4 else "none"
    share[main] += 1
    place[main].append(run["placement"])
    hand.append(sum(1 for u in payload["hand"] if u))
n = sum(share.values())
print(f"{label}: {n} runs, mean place {sum(map(sum, place.values())) / n:.3f}, units in hand at the end {sum(hand) / n:.1f}")
for t, k in share.most_common():
    print(f"  {names.get(t, t):8} {k / n:6.1%}  mean place {sum(place[t]) / len(place[t]):.2f}")
