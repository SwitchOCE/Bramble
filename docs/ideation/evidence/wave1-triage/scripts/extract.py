# Extract per-seat, per-round combat-start state from the wave-1 accounting fight logs.
import gzip, json, glob, pickle, sys, os
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run/"
OUT = os.path.join(os.path.dirname(__file__), "states.pkl")
states = {}
ghost = 0
for path in sorted(glob.glob(RUN + "chunk-*.fights.jsonl.gz")):
    with gzip.open(path, "rt") as f:
        for line in f:
            x = json.loads(line)
            rnd = x["round"]; seed = x["seed"]
            for i, seat in enumerate(x["players"]):
                cs = x["combat_start"][i]
                key = (seed, seat, rnd)
                if key in states:
                    ghost += 1
                    continue
                slots = x["input"]["slots"][i]
                rings = [0]*7; rsize = None
                for s, effs in enumerate(slots):
                    for e in effs:
                        if e.get("name") == "Ring":
                            rings[s] += int(e.get("count", 1)); rsize = e.get("ring_size")
                units = [(u["def_id"], u.get("slot"), u["attack"], u["health"], u.get("golden", False), u.get("location"), u.get("tier"), tuple(u.get("tribes", []))) for u in cs["units"]]
                rec = [(u["def_id"], u.get("location"), u.get("origin"), u.get("iid")) for u in cs.get("recruit_units", [])]
                states[key] = dict(line=cs.get("assigned_line"), policy=cs.get("policy"), sline=cs.get("line"),
                                   tier=x["input"]["tiers"][i], health=cs.get("health"),
                                   spent_turn=cs.get("gold_spent_turn"), spent_game=cs.get("gold_spent_game"),
                                   stats=cs.get("active_stats"), rings=rings, ring_size=rsize, units=units, rec=rec)
    print(path, len(states), file=sys.stderr)
pickle.dump(states, open(OUT, "wb"))
print("states", len(states), "dup", ghost)
