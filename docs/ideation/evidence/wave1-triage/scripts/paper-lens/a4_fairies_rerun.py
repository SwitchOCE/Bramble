"""Fairies paper model (docs/ideation/content/pass3/fairies-pass3-model.py, unchanged, imported read-only)
rerun with realistic arrivals. Accounting dials: fetch=0.5, guards on, built Lob/Monarch/Queen values.
Pre-start board = the model's 'recruit' total, as in the accounting check.

The authored plan is replayed action by action, with gates:
  buy a Fairy piece   only once it has arrived; until then a vanilla body of its tier holds the slot,
                      and the piece goes in when it arrives (selling the stand-in)
  Spore / Stone       only when one has been offered (shop luck; offers can be held)
  thank (pinch)       needs an aimed spell offered (any aimed non-Ring spell, else a Ring spell);
                      a failed thank is retried every later turn
  Supper              only when Harvest Supper has been offered
  Nan buy / Nan cycle only when a Nan is offered that turn
  tier-ups            as planned, at slice costs (tier 6 costs 13)
Variants:
  paper      the authored plan (supply=2, as in the accounting denominator)
  units      unit arrivals realistic (captured), spells/thanks/Nans as planned
  shop       unit arrivals AND spells/thanks/Nans from shop luck (perfect buyer)
  captured   unit arrivals from the captures (first owned), spells/thanks/Nans from shop luck
"""
import importlib.util, json, os, random, statistics as st, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = "/home/alex/code/Bramble-ideation/docs/ideation/content/pass3/fairies-pass3-model.py"
SRC = os.environ.get("FAIRY_MODEL", SRC)
TAG = os.environ.get("TAG", "design")
OVER = json.loads(os.environ.get("FAIRY_OVER", "{}"))
sys.argv = ["m", "fetch=0.5", "supply=2"]
spec = importlib.util.spec_from_file_location("fm", SRC)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
sys.path.insert(0, HERE)
import a2_shopluck as sl

D = json.load(open(os.path.join(HERE, "seats.json")))
B, E = D["boards"], D["econ"]
NAME = {"nan_toadstool": "nan", "rainbow_chaser": "chaser", "hedge_witch": "witch", "old_moth_annis": "annis",
        "sally_spore": "sally", "hob_in_the_hearth": "hob", "cluricaun": "clur", "lob_lie_by_the_fire": "lob",
        "silky": "silky", "changeling": "changeling", "will_o_the_wisp": "will", "cradle_fetch": "fetch",
        "belladonna": "bella", "reel_mistress": "reel", "fairy_monarch": "monarch", "queen_of_elfland": "queen"}
INV = {v: k for k, v in NAME.items()}
m.U["n1"] = (2, 2, 0, 0, 1)


class Skip(Exception):
    pass


def safe(g, a):
    """Run one action; any rule/gold failure skips it (the model raises SystemExit)."""
    snap = (g.gold, dict(g.b), dict(g.ring), g.S, g.pending)
    try:
        g.act(a)
        return True
    except (SystemExit, KeyError):
        g.gold, g.b, g.ring, g.S, g.pending = snap[0], snap[1], snap[2], snap[3], snap[4]
        return False


def offers_for(h, rng):
    """Per round: Spore, Stone, aimed (non-Ring), Supper, Nan offers, from this seat's tiers and refreshes."""
    o = {}
    for r in range(1, 17):
        x = h.get(str(r)) or h[max(h, key=int)]
        tier, refills = x["tier"], 1 + x["refresh"]
        c = dict(spore=0, stone=0, aimed=0, supper=0, nan=0)
        pa = sl.p_aimed(tier) - sl.p_spell("spore_cloud", tier) - (sl.p_spell("boundary_stone", tier) or 0)
        for _ in range(refills):
            c["spore"] += rng.random() < sl.p_spell("spore_cloud", tier)
            c["stone"] += rng.random() < (sl.p_spell("boundary_stone", tier) or 0)
            c["supper"] += rng.random() < (sl.p_spell("harvest_supper", tier) or 0)
            c["aimed"] += rng.random() < pa
            q = sl.p_card_slot(1, tier)
            c["nan"] += sum(1 for _ in range(sl.SHOP[tier - 1]) if rng.random() < q)
        o[r] = c
    return o


def shop_arrivals(h, rng):
    arr = {}
    for r in range(1, 17):
        x = h.get(str(r)) or h[max(h, key=int)]
        tier, refills = x["tier"], 1 + x["refresh"]
        for _ in range(refills):
            for cid, nm in NAME.items():
                if nm in arr:
                    continue
                q = sl.p_card_slot(sl.TIER[cid], tier)
                if any(rng.random() < q for _ in range(sl.SHOP[tier - 1])):
                    arr[nm] = r
    return arr


def plan_round_of(plan):
    first = {}
    for r in sorted(plan):
        for a in plan[r]:
            if a[0] == "buy" and a[1] in INV:
                first.setdefault(a[1], r)
    return first


def captured_arrivals(rs, plan):
    pr = plan_round_of(plan)
    arr = {}
    for r in sorted(rs, key=int):
        for u in rs[r]["units"]:
            nm = NAME.get(u["id"])
            if nm and u["loc"] in ("board", "hand") and nm not in arr:
                arr[nm] = int(r) if int(r) > 8 else min(pr.get(nm, 8), 8)
    return arr


def play(plan, arr=None, offers=None, rounds=14, units_only=False, occupied=None):
    """arr None = guaranteed arrivals; offers None = spells/thanks/Nans as planned (paper supply=2 rule)."""
    m.TIER_BASE[6] = 13 if arr is not None else 11
    g = m.Game(m.params(dict(OVER, supply=2))) if hasattr(m, "params") else m.Game(dict(m.P, supply=2))
    pending = {}            # piece -> slot it should go into
    thank_due = []          # slots whose Shy unit the plan wanted thanked
    hand = dict(spore=0, stone=0, aimed=0, supper=0)
    out = {}
    for r in range(1, rounds + 1):
        g.round = r
        g.gold += m.INCOME.get(r, 10) + g.pending; g.pending = 0
        if r >= 2:
            g.cost = max(0, g.cost - 1)
        o = offers[r] if offers is not None else None
        if o is not None:
            for k in hand:
                hand[k] += o[k]
        nan_left = o["nan"] if o is not None else 99
        # pieces that have arrived since the plan wanted them
        for nm, s0 in list(pending.items()):
            if arr.get(nm, 99) <= r and m.U[nm][4] <= g.tier and g.gold >= 3:
                cand = [s0] + [x for x in m.SLOTS if x != s0]
                if nm in ("fetch", "annis", "queen"):
                    cand = [x for x in cand if x.startswith("F")]
                for s in cand:
                    cur = g.b.get(s)
                    if cur is not None and not cur.name.startswith("n"):
                        continue
                    if cur is not None:
                        safe(g, ("sell", s))
                    if safe(g, ("buy", nm, s)):
                        del pending[nm]
                        if m.U[nm][3]:
                            thank_due.append((s, r + (3 if nm == "lob" else 1)))
                    break
        # thanks the plan wanted but could not do yet
        for item in list(thank_due):
            s, nb = item
            if r < nb:
                continue
            u = g.b.get(s)
            if u is None or not u.shy:
                thank_due.remove(item); continue
            ok = (o is None) or (hand["aimed"] or hand["stone"] or hand["spore"])
            if ok and g.gold >= 1:
                k = None if o is None else ("aimed" if hand["aimed"] else ("stone" if hand["stone"] else "spore"))
                if safe(g, ("spell", "pinch", s)):
                    thank_due.remove(item)
                    if k is None:
                        continue
                    hand[k] -= 1
                    if k != "aimed":
                        g.ring[s] += 3 if k == "stone" else 2
        ring_spells = 0
        for a in plan.get(r, []):
            op = a[0]
            if op == "buy" and a[1] in INV and arr is not None and arr.get(a[1], 99) > r:
                pending[a[1]] = a[2]
                if units_only or True:
                    t = min(m.U[a[1]][4], g.tier)
                    safe(g, ("buy", "n%d" % t, a[2]))
                continue
            if op in ("buy", "move"):
                dest = a[2]
                cur = g.b.get(dest)
                if cur is not None and cur.name.startswith("n") and not (op == "buy" and a[1].startswith("n")):
                    safe(g, ("sell", dest))
            if op == "move":
                if a[1] not in g.b or a[2] in g.b:
                    continue
            if op == "sell":
                for nm, ps in list(pending.items()):
                    if ps == a[1]:
                        del pending[nm]
                if a[1] not in g.b:
                    continue
            if op == "spell":
                kind = a[1]
                if o is None:      # authored supply rule (accounting denominator)
                    if kind in ("spore", "stone") and (ring_spells >= 1 or (g.tier >= 5 and r % 2 != 0)):
                        continue
                    ring_spells += kind in ("spore", "stone")
                    safe(g, a)
                    continue
                if kind in ("spore", "stone"):
                    if hand[kind] <= 0:
                        continue
                    if safe(g, a):
                        hand[kind] -= 1
                    continue
                if kind == "supper":
                    if hand["supper"] <= 0:
                        continue
                    if safe(g, a):
                        hand["supper"] -= 1
                    continue
                if kind == "pinch":
                    s = a[2]
                    if s not in g.b or not g.b[s].shy:
                        continue
                    if hand["aimed"] or hand["stone"] or hand["spore"]:
                        k = "aimed" if hand["aimed"] else ("stone" if hand["stone"] else "spore")
                        if safe(g, a):
                            hand[k] -= 1
                            if k != "aimed":
                                g.ring[s] += 3 if k == "stone" else 2
                            continue
                    thank_due.append((s, r))
                    continue
            if op == "nancycle":
                if o is None:
                    if g.tier >= 5:
                        continue
                elif nan_left <= 0:
                    continue
                else:
                    nan_left -= 1
            if op == "nan" or (op == "buy" and a[1] == "nan"):
                if o is not None:
                    if nan_left <= 0:
                        continue
                    nan_left -= 1
            safe(g, a)
        # spend leftovers on vanilla bodies for empty slots (the real boards are full), then churn
        nxt_tier = any(a[0] == "tier" for a in plan.get(r + 1, []))
        reserve = max(0, g.cost - 1 - m.INCOME.get(r + 1, 10)) if nxt_tier else 0
        want = occupied.get(r, set()) if occupied else set()
        while g.gold - reserve >= 3:
            free = [s for s in m.SLOTS if s not in g.b and s in want]
            if not free or not safe(g, ("buy", "n%d" % min(g.tier, 6), free[0])):
                break
        g.end_of_turn()
        rec, comb = g.snapshot()
        out[r] = dict(rec=sum(rec.values()), S=g.S, rings=sum(g.ring.values()), occ=set(g.b))
    m.TIER_BASE[6] = 11
    return out


def main():
    rng = random.Random(3)
    res = {}
    for line, kind in (("line_fairies_ring", "ring"), ("line_fairies_court", "court")):
        plan = m.ring_plan("typ") if kind == "ring" else m.court_plan("typ")
        paper = play(plan)
        occ = {r: paper[r]["occ"] for r in paper}
        var = {k: {t: [] for t in (8, 10, 12, 14)} for k in ("units", "shop", "captured")}
        SR = {k: {t: [] for t in (8, 10, 12, 14)} for k in ("shop", "captured")}
        for skey, rs in B[line].items():
            h = E[line][skey]
            alive = [t for t in (8, 10, 12, 14) if str(t) in rs]
            offers = offers_for(h, rng)
            carr = captured_arrivals(rs, plan)
            o = play(plan, arr=carr, offers=None, units_only=True, occupied=occ)
            for t in alive: var["units"][t].append(o[t]["rec"])
            sarr = shop_arrivals(h, rng)
            o = play(plan, arr=sarr, offers=offers, occupied=occ)
            for t in alive:
                var["shop"][t].append(o[t]["rec"]); SR["shop"][t].append((o[t]["S"], o[t]["rings"]))
            o = play(plan, arr=carr, offers=offers, occupied=occ)
            for t in alive:
                var["captured"][t].append(o[t]["rec"]); SR["captured"][t].append((o[t]["S"], o[t]["rings"]))
        real = {t: st.median([rs[str(t)]["stats"] for rs in B[line].values() if str(t) in rs]) for t in (8, 10, 12, 14)}
        rS = {t: st.median([rs[str(t)]["S"] or 1 for rs in B[line].values() if str(t) in rs]) for t in (8, 10, 12, 14)}
        rR = {t: st.median([sum(rs[str(t)]["rings"] or []) for rs in B[line].values() if str(t) in rs]) for t in (8, 10, 12, 14)}
        print("\n=====", line)
        print("  round  paper (S, Rings) |  units   shop  captured (S, Rings) |  real (S, Rings) | real/paper units/paper shop/paper captured/paper real/captured")
        rows = {}
        for t in (8, 10, 12, 14):
            md = {k: st.median(v[t]) for k, v in var.items()}
            cS = st.median([x[0] for x in SR["captured"][t]]); cR = st.median([x[1] for x in SR["captured"][t]])
            rows[t] = dict(paper=paper[t]["rec"], real=real[t], capS=cS, capRings=cR, realS=rS[t], realRings=rR[t], **md)
            print("  R%-4d %5d (%d, %d)  | %6.0f %6.0f %7.0f (%.0f, %.0f) | %5.0f (%.0f, %.0f) |  %.2f  %.2f  %.2f  %.2f  %.2f" % (
                t, paper[t]["rec"], paper[t]["S"], paper[t]["rings"], md["units"], md["shop"], md["captured"], cS, cR,
                real[t], rS[t], rR[t], real[t] / paper[t]["rec"], md["units"] / paper[t]["rec"], md["shop"] / paper[t]["rec"],
                md["captured"] / paper[t]["rec"], real[t] / md["captured"]))
        for k in ("shop", "captured"):
            v = sorted(var[k][12])
            print("  R12 %s p10/p25/p50/p75/p90: %s" % (k, "/".join("%.0f" % v[int(p * (len(v) - 1))] for p in (.1, .25, .5, .75, .9))))
        v = sorted(rs["12"]["stats"] for rs in B[line].values() if "12" in rs)
        print("  R12 real p10/p25/p50/p75/p90: %s" % "/".join("%.0f" % v[int(p * (len(v) - 1))] for p in (.1, .25, .5, .75, .9)))
        res[line] = rows
    json.dump(res, open(os.path.join(HERE, "a4_fairies_rerun_%s.json" % TAG), "w"), indent=1)


if __name__ == "__main__":
    main()
