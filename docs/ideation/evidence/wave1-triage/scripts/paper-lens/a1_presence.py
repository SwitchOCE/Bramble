"""Real-game audit of the paper models' assumptions, from the captures (seats.json from load.py).

Per committed line and round (survivors only): median board, tier, gold spent, piece presence
(anywhere the seat owns it: board, hand, away), first-seen round, Fairy Rings and Ring size,
Bird homecomings, tribe bodies on board.
"""
import json, os, statistics as st, collections

HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "seats.json")))
B, E = D["boards"], D["econ"]
PIECES = {
    "birds": ["chiffchaff", "one_swallow", "mrs_dunnock", "mrs_jay", "mr_redbreast", "redwing", "jack_daw", "tom_tit",
              "old_tern", "mrs_stork", "mag_pye", "cuckoo", "great_lump", "mother_goose", "gabble_ratchet",
              "seven_whistlers"],
    "fairies": ["nan_toadstool", "rainbow_chaser", "hedge_witch", "old_moth_annis", "sally_spore", "hob_in_the_hearth",
                "cluricaun", "lob_lie_by_the_fire", "silky", "changeling", "will_o_the_wisp", "cradle_fetch",
                "belladonna", "reel_mistress", "fairy_monarch", "queen_of_elfland"],
}
OWN = ("board", "hand", "away", "egg", "belly")


def med(x):
    return st.median(x) if x else float("nan")


def q(x, p):
    if not x:
        return float("nan")
    x = sorted(x)
    return x[min(len(x) - 1, int(p * len(x)))]


out = {}
for line, seats in B.items():
    tribe = "birds" if "birds" in line else "fairies"
    T = "Birds" if tribe == "birds" else "Fairies"
    print("\n=====", line)
    rows = {}
    first = {p: [] for p in PIECES[tribe]}
    for key, rs in seats.items():
        seen = {}
        for r in sorted(rs, key=int):
            for u in rs[r]["units"]:
                if u["loc"] in OWN and u["id"] in first and u["id"] not in seen:
                    seen[u["id"]] = int(r)
        for p in PIECES[tribe]:
            first[p].append(seen.get(p, 99))
    for r in range(8, 15):
        R = str(r)
        live = [rs[R] for rs in seats.values() if R in rs]
        if not live:
            continue
        row = dict(n=len(live), stats=med([x["stats"] for x in live]), tier=med([x["tier"] for x in live]),
                   spent=med([x["spent"] for x in live]))
        row["tier6"] = sum(x["tier"] >= 6 for x in live) / len(live)
        row["tribe_board"] = med([sum(1 for u in x["units"] if u["loc"] == "board" and u["tr"] == T) for x in live])
        row["board_bodies"] = med([sum(1 for u in x["units"] if u["loc"] == "board") for x in live])
        row["golden"] = med([sum(1 for u in x["units"] if u["loc"] in OWN and u["g"]) for x in live])
        pres = {}
        for p in PIECES[tribe]:
            pres[p] = sum(1 for x in live if any(u["id"] == p and u["loc"] in OWN for u in x["units"])) / len(live)
        row["presence"] = pres
        if tribe == "fairies":
            row["S"] = med([x["S"] or 1 for x in live])
            row["S_q"] = (q([x["S"] or 1 for x in live], .25), q([x["S"] or 1 for x in live], .75), q([x["S"] or 1 for x in live], .9))
            row["rings"] = med([sum(x["rings"] or []) for x in live])
            row["rings_q"] = (q([sum(x["rings"] or []) for x in live], .25), q([sum(x["rings"] or []) for x in live], .75))
            row["ringed_slots"] = med([sum(1 for c in (x["rings"] or []) if c > 0) for x in live])
            # Ring stats on board = 2 * count * S on occupied, non-Shy slots (approximation from captured rings)
            row["rings_x_S"] = med([2 * sum(x["rings"] or []) * (x["S"] or 1) for x in live])
        else:
            row["hc"] = med([x["hc"] or 0 for x in live])
            row["away"] = med([sum(1 for u in x["units"] if u["loc"] == "away") for x in live])
            row["jays"] = med([sum(3 if u["g"] else 1 for u in x["units"] if u["id"] == "mrs_jay" and u["loc"] in OWN) for x in live])
        rows[r] = row
        extra = ("S %.1f [%s] rings %.0f %s slotsRinged %.0f" % (row["S"], row["S_q"], row["rings"], row["rings_q"], row["ringed_slots"])
                 if tribe == "fairies" else "hc %.0f away %.0f jays %.0f" % (row["hc"], row["away"], row["jays"]))
        print("R%d n=%d stats %.0f tier %.0f (T6 %.0f%%) spent %.0f tribeOnBoard %.0f/%.0f golden %.0f | %s" % (
            r, row["n"], row["stats"], row["tier"], 100 * row["tier6"], row["spent"], row["tribe_board"], row["board_bodies"],
            row["golden"], extra))
        print("    presence: " + " ".join("%s %.0f%%" % (p[:8], 100 * v) for p, v in pres.items() if v >= 0.02))
    print("  first seen (owned) median / share by R8 / R10 / R12 / ever R8-14:")
    fs = {}
    for p, v in first.items():
        fs[p] = dict(by8=sum(x <= 8 for x in v) / len(v), by10=sum(x <= 10 for x in v) / len(v),
                     by12=sum(x <= 12 for x in v) / len(v), ever=sum(x < 99 for x in v) / len(v))
        print("    %-22s %3.0f%% %3.0f%% %3.0f%% %3.0f%%" % (p, 100 * fs[p]["by8"], 100 * fs[p]["by10"], 100 * fs[p]["by12"], 100 * fs[p]["ever"]))
    # economy R1-R14 from rounds.csv
    print("  economy (median over seats alive): round: tier, bank, spent, paid refreshes, gold left")
    eco = {}
    for r in range(1, 15):
        live = [rs[str(r)] for rs in E[line].values() if str(r) in rs]
        if not live:
            continue
        eco[r] = dict(n=len(live), tier=med([x["tier"] for x in live]), bank=med([x["bank"] for x in live]),
                      spent=med([x["spent"] for x in live]), refresh=st.mean([x["refresh"] for x in live]),
                      left=st.mean([x["left"] for x in live]), units=med([x["units"] for x in live]))
        print("    R%2d n=%3d tier %.0f bank %.0f spent %.0f refresh %.2f left %.2f units %.0f" % (
            r, eco[r]["n"], eco[r]["tier"], eco[r]["bank"], eco[r]["spent"], eco[r]["refresh"], eco[r]["left"], eco[r]["units"]))
    # tier-up rounds
    tu = {t: [] for t in range(2, 7)}
    for key, rs in E[line].items():
        for t in range(2, 7):
            rr = [int(r) for r, x in rs.items() if x["tier"] >= t]
            tu[t].append(min(rr) if rr else 99)
    print("  tier reached round, median [p25,p75]: " + " ".join("T%d %s [%s,%s]" % (t, med(v), q(v, .25), q(v, .75)) for t, v in tu.items()))
    out[line] = dict(rows=rows, first=fs, econ=eco, tierup={t: med(v) for t, v in tu.items()})
json.dump(out, open(os.path.join(HERE, "a1_presence.json"), "w"), indent=1)
