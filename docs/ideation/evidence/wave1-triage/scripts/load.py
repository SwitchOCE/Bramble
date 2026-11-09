"""Load wave-1 accounting captures into a compact per-board table (pickle).

Reads only: build/sim/wave1-accounting/run/chunk-*.boards.json.gz and chunk-*.players.csv
and the seat-labels file. Writes boards.pkl next to this script.
"""
import csv, glob, gzip, json, os, pickle, sys

RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LABELS = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "boards.pkl")

labels = {(r["seed"], r["seat"]): r for r in json.load(gzip.open(LABELS))}

players = {}
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.players.csv"))):
    for r in csv.DictReader(open(f)):
        key = (int(r["seed"]), int(r["seat"]))
        players[key] = {
            "place": int(r["place"]),
            "rounds": int(r["rounds"]),
            "hero": r["hero"],
            "tier6_turn": int(r["tier6_turn"]) if r["tier6_turn"] not in ("", None) else None,
            "final_tribe": r["final_tribe"],
            "strategy": r["strategy"],
            "lobby_tribes": r["lobby_tribes"],
        }

rows = []
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.boards.json.gz"))):
    for r in json.load(gzip.open(f)):
        key = (r["seed"], r["seat"])
        lab = labels.get(key)
        units = r["units"]
        owned = {}
        onboard = {}
        golden_board = 0
        top_unit = 0
        board_unit_stats = []
        for u in units:
            d = u["def_id"]
            owned[d] = owned.get(d, 0) + 1
            if u["location"] == "board":
                onboard[d] = onboard.get(d, 0) + 1
                board_unit_stats.append(u["attack"] + u["health"])
                if u.get("golden"):
                    golden_board += 1
        rings = 0
        slot_ring_max = 0
        for s in r.get("slots") or []:
            for m in s:
                if m.get("name") == "Ring":
                    rings += m.get("count", 0)
                    slot_ring_max = max(slot_ring_max, m.get("count", 0))
        rows.append({
            "seed": r["seed"], "seat": r["seat"], "round": r["round"],
            "line": r["line"], "start_line": lab["starting_line"] if lab else None,
            "policy": r["actual_policy"],
            "stats": r["stats"], "post": r["post_start_stats"],
            "tier": r["tier"], "largest_share": r["largest_share"],
            "gold_spent": r["gold_spent"],
            "ring_size": r.get("ring_size"), "rings": rings, "ring_max_slot": slot_ring_max,
            "homecomings": r.get("homecomings"),
            "owned": owned, "onboard": onboard, "golden_board": golden_board,
            "board_units": len(board_unit_stats),
            "max_unit": max(board_unit_stats) if board_unit_stats else 0,
            **{("p_" + k): v for k, v in players.get(key, {}).items()},
        })

mismatch = sum(1 for x in rows if x["start_line"] is not None and x["line"] != x["start_line"]
               and not (x["line"] == "hard_field" and x["start_line"] == "hard_field"))
print("records", len(rows), "line/start_line mismatches", mismatch, "players", len(players))
pickle.dump({"rows": rows, "players": players, "labels": labels}, open(OUT, "wb"))
print("wrote", OUT)
