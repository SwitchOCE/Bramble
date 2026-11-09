"""Critic lens: Ring stats on occupied vs empty slots, pre vs post start, Nan/Sally presence."""
import glob, gzip, json, statistics, collections, sys
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LAB = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LAB))}
agg = collections.defaultdict(lambda: collections.defaultdict(list))
for f in sorted(glob.glob(RUN + "/chunk-*.boards.json.gz")):
    for r in json.load(gzip.open(f)):
        line = labels.get((r["seed"], r["seat"]), r["line"])
        if not line or "fairies" not in line and "birds" not in line: continue
        rd = r["round"]
        occ = {u["slot"] for u in r["units"] if u["location"] == "board"}
        size = r["ring_size"]
        on_occ = on_empty = 0; cnt_occ = cnt_empty = 0
        for i, s in enumerate(r.get("slots") or []):
            for m in s:
                if m.get("name") == "Ring":
                    c = m.get("count", 0)
                    if i in occ: cnt_occ += c; on_occ += 2*m.get("attack", 0)
                    else: cnt_empty += c; on_empty += 2*m.get("attack", 0)
        a = agg[(line, rd)]
        a["stats"].append(r["stats"]); a["post"].append(r["post_start_stats"])
        a["ringstat_occ"].append(on_occ); a["ringstat_empty"].append(on_empty)
        a["cnt_occ"].append(cnt_occ); a["cnt_empty"].append(cnt_empty)
        a["empty_slots"].append(7 - len(occ)); a["size"].append(size)
        a["bodies"].append(r["stats"] - on_occ)
        own = collections.Counter(u["def_id"] for u in r["units"] if u["location"] == "board")
        for k in ("nan_toadstool", "sally_spore", "old_moth_annis", "will_o_the_wisp", "changeling", "cluricaun"):
            a["has_" + k].append(1 if own[k] else 0)
med = statistics.median
for (line, rd), a in sorted(agg.items()):
    if "fairies" not in line or rd not in (8, 10, 12, 14): continue
    n = len(a["stats"])
    print(f"{line} R{rd} n={n} stats={med(a['stats'])} post={med(a['post'])} post/pre={med([p/max(1,s) for p,s in zip(a['post'],a['stats'])]):.2f} "
          f"bodies={med(a['bodies'])} ringstat_occ={med(a['ringstat_occ'])} mean_share={statistics.mean(o/max(1,s) for o,s in zip(a['ringstat_occ'],a['stats'])):.2f} "
          f"cnt_occ={med(a['cnt_occ'])} cnt_empty={med(a['cnt_empty'])} wasted_share={sum(a['cnt_empty'])/max(1,sum(a['cnt_empty'])+sum(a['cnt_occ'])):.2f} "
          f"empty={statistics.mean(a['empty_slots']):.2f} size={med(a['size'])} "
          + " ".join(f"{k[4:8]}={statistics.mean(v):.2f}" for k, v in a.items() if k.startswith('has_')))
for (line, rd), a in sorted(agg.items()):
    if "birds" in line and rd in (12,):
        print(line, rd, "stats", med(a["stats"]), "post", med(a["post"]))
