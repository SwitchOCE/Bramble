# Per-seat, per-round Bird state from fight logs: away specs (iid, stats), nests, homecomings this turn.
import gzip, json, glob, pickle, os
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run/"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "birds.pkl")
out = {}
for path in sorted(glob.glob(RUN + "chunk-*.fights.jsonl.gz")):
    with gzip.open(path, "rt") as f:
        for line in f:
            x = json.loads(line)
            for i, seat in enumerate(x["players"]):
                cs = x["combat_start"][i]
                if "birds" not in str(cs.get("assigned_line")): continue
                key = (x["seed"], seat, x["round"])
                if key in out: continue
                fr = x["input"]["fight_rules"][i]
                out[key] = dict(away=[(a["def_id"], a["iid"], a["attack"], a["health"], a.get("golden", False), a.get("slot")) for a in fr["away_specs"]],
                                nests=[(n["slot"], n["def_id"], n["attack"], n["health"]) for n in fr["nests"]],
                                home=fr["homecomings"], goose=fr["goose"],
                                board_iids=[(u["def_id"], u.get("iid"), u.get("location")) for u in cs.get("recruit_units", [])])
pickle.dump(out, open(OUT, "wb")); print(len(out))
