"""Birds paper model (docs/ideation/content/pass3/birds-pass3-model.py, unchanged, imported read-only)
rerun with realistic arrivals. Accounting dials: h=2 s=0.125 k=0.1 f=0.25 g=6 egg=1, lines A (homecoming)
and U (tempo). Pre-start board = the model's snapshot total (sky excluded), as in the accounting check.

Variants per seat (one per real committed seat, survivors at each round):
  paper      the authored line (guaranteed arrivals, paper climb, 3 Suppers)
  climb      paper arrivals, the seat's real tier-up rounds and slice tier costs (5,7,8,11,13)
  shop       arrivals from a shop-luck draw (a2's pool rules, the seat's real tiers and refreshes);
             the line buys a piece the first time it is offered; Supper only when offered
  captured   arrivals = the round the seat first owned the piece (R8 snapshot = the paper round if
             that is by R8, else R8); never owned = never arrives; real climb; Supper as shop
Every variant fills empty slots with vanilla off-tribe bodies (the real boards hold 3-6 Birds of 7),
which take no Bird buffs. 'nofill' runs 'captured' without fillers.
"""
import importlib.util, json, os, random, statistics as st, sys, math

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = "/home/alex/code/Bramble-ideation/docs/ideation/content/pass3/birds-pass3-model.py"
SRC = os.environ.get("BIRDS_MODEL", SRC)
TAG = os.environ.get("TAG", "design")
sys.argv = ["m"] + os.environ.get("BIRDS_ARGS", "h=2 s=0.125 k=0.1 f=0.25 g=6 egg=1").split() + ["n=0", "lines=A"]
spec = importlib.util.spec_from_file_location("bm", SRC)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
sys.path.insert(0, HERE)
import a2_shopluck as sl

D = json.load(open(os.path.join(HERE, "seats.json")))
B, E = D["boards"], D["econ"]
NAME = {"chiffchaff": "Chiffchaff", "one_swallow": "Swallow", "mrs_dunnock": "Dunnock", "mrs_jay": "Jay",
        "mr_redbreast": "Redbreast", "redwing": "Redwing", "jack_daw": "JackDaw", "tom_tit": "TomTit",
        "old_tern": "Tern", "mrs_stork": "Stork", "mag_pye": "MagPye", "cuckoo": "Cuckoo", "great_lump": "Lump",
        "mother_goose": "Goose", "gabble_ratchet": "Ratchet", "seven_whistlers": "Whistlers"}
INV = {v: k for k, v in NAME.items()}
FILL = {1: (1, 3), 2: (2, 4), 3: (3, 5), 4: (4, 6), 5: (5, 8), 6: (6, 9)}
for t, (a, h) in FILL.items():
    m.CARDS["F%d" % t] = (t, a, h, False)
SLICE_COST = {2: 5, 3: 7, 4: 8, 5: 11, 6: 13}

# --- patch the model minimally: fillers take no Bird buffs; fillers make room for Birds
orig_come_home = m.Game.come_home
orig_snapshot = m.Game.snapshot


def is_filler(u):
    return u.card.startswith("F") and u.card[1:].isdigit()


def come_home(self, b, why):
    # Cuckoo's spread is "other Birds": hide fillers from home() during the homecoming
    saved = [u for u in self.units if is_filler(u) and u.loc == "board"]
    for u in saved:
        u.loc = "filler_board"
    try:
        orig_come_home(self, b, why)
    finally:
        for u in saved:
            if u.loc == "filler_board":
                u.loc = "board"
        while len(self.home()) > 7:
            fill = [u for u in self.home() if is_filler(u)]
            if not fill:
                break
            u = min(fill, key=m.Unit.size); u.loc = "gone"; self.gold += 1


def snapshot(self):
    units = orig_snapshot(self)
    for u in units:          # Supper is a Bird aura: take it back off fillers
        if str(u[2].get("card", "")).startswith("F") and u[2]["card"][1:].isdigit():
            u[0] -= self.tribe; u[1] -= self.tribe
            u[2]["bird"] = False
    return units


m.Game.come_home = come_home
m.Game.snapshot = snapshot


def make_room(g):
    fill = [u for u in g.home() + g.hand() if is_filler(u)]
    if len(g.home()) >= 7 and fill:
        u = min(fill, key=m.Unit.size); u.loc = "gone"; g.gold += 1


orig_buy = m.Game.buy


def buy(self, card):
    if not card.startswith("F"):
        make_room(self)
    orig_buy(self, card)


m.Game.buy = buy


def run_line(L, rounds=14, fill=True, cost=None, supper_rounds=None):
    m.Unit._uid = 0
    g = m.Game(L)
    out = {}
    for t in range(1, rounds + 1):
        if cost:
            m.TIER_COST.clear(); m.TIER_COST.update(cost)
            if t == 1:
                g.cost = cost[2]
        g.round(t)
        if fill:   # spend what the line left on vanilla bodies of the shop's tier
            while g.gold - g.reserve() >= 3 and len(g.home()) + len(g.hand()) < 7:
                g.gold -= 3
                u = m.Unit("F%d" % g.tier); u.loc = "board"; g.units.append(u)
            g.stats[t]["snap"] = g.snapshot()
        snap = g.stats[t]["snap"]
        out[t] = sum(u[0] + u[1] for u in snap)
    m.TIER_COST.clear(); m.TIER_COST.update({2: 5, 3: 7, 4: 8, 5: 11, 6: 11})
    return out


def seat_climb(h):
    c = {}
    for t in range(2, 7):
        rr = [int(r) for r, x in h.items() if x["tier"] >= t]
        c[t] = min(rr) if rr else 99
    return c


def shop_arrivals(L, h, rng):
    """First round each Bird is offered, replaying this seat's tiers and refreshes; supper rounds offered."""
    arr, sup = {}, []
    for r in range(1, 17):
        x = h.get(str(r)) or h[max(h, key=int)]
        tier, refills = x["tier"], 1 + x["refresh"]
        for _ in range(refills):
            for cid, card in NAME.items():
                if card in arr:
                    continue
                q = sl.p_card_slot(sl.TIER[cid], tier)
                if any(rng.random() < q for _ in range(sl.SHOP[tier - 1])):
                    arr[card] = r
            if rng.random() < sl.p_spell("harvest_supper", tier):
                sup.append(r)
    return arr, tuple(sorted(set(sup)))


def captured_arrivals(L, rs):
    arr = {}
    for r in sorted(rs, key=int):
        for u in rs[r]["units"]:
            c = NAME.get(u["id"])
            if c and u["loc"] in ("board", "hand", "away") and c not in arr:
                arr[c] = int(r) if int(r) > 8 else min(L["arrive"].get(c, 8), 8)
    return arr


def main():
    rng = random.Random(5)
    res = {}
    for line, key in (("line_birds_homecoming", "A"), ("line_birds_tempo", "U")):
        L0 = m.LINES[key]
        paper = run_line(dict(L0), fill=False)
        paper_fill = run_line(dict(L0), fill=True)
        var = {k: {t: [] for t in (8, 10, 12, 14)} for k in ("climb", "shop", "captured", "nofill")}
        for skey, rs in B[line].items():
            h = E[line][skey]
            climb = seat_climb(h)
            alive = {t for t in (8, 10, 12, 14) if str(t) in rs}
            L = dict(L0, climb=climb)
            o = run_line(L, cost=SLICE_COST)
            for t in alive: var["climb"][t].append(o[t])
            arr, sup = shop_arrivals(L0, h, rng)
            L = dict(L0, climb=climb, arrive=arr, supper=sup)
            o = run_line(L, cost=SLICE_COST)
            for t in alive: var["shop"][t].append(o[t])
            arr = captured_arrivals(L0, rs)
            L = dict(L0, climb=climb, arrive=arr, supper=sup)
            o = run_line(L, cost=SLICE_COST)
            for t in alive: var["captured"][t].append(o[t])
            o = run_line(L, cost=SLICE_COST, fill=False)
            for t in alive: var["nofill"][t].append(o[t])
        real = {t: st.median([rs[str(t)]["stats"] for rs in B[line].values() if str(t) in rs]) for t in (8, 10, 12, 14)}
        print("\n=====", line, "(paper line %s)" % key)
        print("  round   paper  paper+fill |  climb   shop  captured  nofill |  real | real/paper  shop/paper  captured/paper  real/captured")
        rows = {}
        for t in (8, 10, 12, 14):
            md = {k: st.median(v[t]) for k, v in var.items()}
            rows[t] = dict(paper=paper[t], paper_fill=paper_fill[t], real=real[t], **md)
            print("  R%-4d %6d %8d    | %6.0f %6.0f %8.0f %7.0f | %5.0f |   %.2f        %.2f        %.2f          %.2f" % (
                t, paper[t], paper_fill[t], md["climb"], md["shop"], md["captured"], md["nofill"], real[t],
                real[t] / paper[t], md["shop"] / paper[t], md["captured"] / paper[t], real[t] / md["captured"]))
        # distribution at R12
        for k in ("shop", "captured"):
            v = sorted(var[k][12])
            print("  R12 %s p10/p25/p50/p75/p90: %s" % (k, "/".join("%.0f" % v[int(p * (len(v) - 1))] for p in (.1, .25, .5, .75, .9))))
        v = sorted(rs["12"]["stats"] for rs in B[line].values() if "12" in rs)
        print("  R12 real p10/p25/p50/p75/p90: %s" % "/".join("%.0f" % v[int(p * (len(v) - 1))] for p in (.1, .25, .5, .75, .9)))
        res[line] = rows
    json.dump(res, open(os.path.join(HERE, "a3_birds_rerun_%s.json" % TAG), "w"), indent=1)


if __name__ == "__main__":
    main()
