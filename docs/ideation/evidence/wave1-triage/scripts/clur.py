# Cluricaun ("After you Tier up: if every slot has a Ring, your Rings grow +1/+1"): at each tier-up with
# Cluricaun on board before and after, how many slots had a Ring, and did Ring size grow?
import pickle, os, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
def onboard(v, card): return any(u[0] == card and u[5] == "board" for u in v["units"])
def ringed(v): return sum(1 for c in v["rings"] if c > 0)
def shy_left(a, b):
    ids = lambda v: {x[3] for x in v["rec"] if x[0] in ("lob_lie_by_the_fire", "silky", "hob_in_the_hearth") and x[1] == "board"}
    return bool(ids(a) - ids(b))
for line in ["line_fairies_ring", "line_fairies_court"]:
    ev = collections.Counter(); pre = collections.Counter(); seats_with = set(); seats_grew = set(); t6 = collections.Counter()
    for (sd, se, r), v in S.items():
        if v["line"] != line: continue
        p = S.get((sd, se, r - 1))
        if not p or v["tier"] <= p["tier"]: continue
        if not (onboard(p, "cluricaun") and onboard(v, "cluricaun")): continue
        seats_with.add((sd, se))
        before = ringed(p); after = ringed(v)
        grew = (v["ring_size"] or 1) > (p["ring_size"] or 1)
        clean = not shy_left(p, v) and not onboard(p, "fairy_monarch")
        key = ("prev7" if before == 7 else f"prev{before}") 
        pre[key] += 1
        ev[("grew" if grew else "flat", "rainbow_after" if after == 7 else "no_rainbow_after", "clean" if clean else "other_source_possible")] += 1
        if grew and clean: seats_grew.add((sd, se))
    print("==", line, "tier-ups with Cluricaun on board:", sum(pre.values()), "in", len(seats_with), "seats")
    print("  ringed slots at previous combat:", sorted(pre.items()))
    for k, n in sorted(ev.items(), key=lambda kv: -kv[1]): print("  ", k, n)
    # Cluricaun ever on board: how many tier-ups did he see at all?
    seats = collections.defaultdict(list)
    for (sd, se, r), v in S.items():
        if v["line"] == line and onboard(v, "cluricaun"): seats[(sd, se)].append(r)
    firsts = collections.Counter(); tierat = collections.Counter()
    for (sd, se), rs in seats.items():
        f = min(rs); firsts[f] += 1; tierat[S[(sd, se, f)]["tier"]] += 1
    print("  seats with Cluricaun ever:", len(seats), " tier when he first stood:", sorted(tierat.items()))
