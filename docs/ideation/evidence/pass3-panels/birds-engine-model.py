"""Paper model v2 of the Birds pass 3 engine.
Tailwind W: Birds coming home gain +W/+W, then W rises by r. Listeners: Redbreast (+W per homecoming),
Cuckoo (keeper of the Nest +W), Goose homecoming (all Birds +W). Lump on a Nest has its Bird's stats.
Board stats are combat-start sums (A+H) of the 7 slots: units, keepers, Eggs. Combat-only effects
(Jack Daw, Whistlers, Ratchet, Mag Pye) are not in the totals.
"""
import sys

FLIERS = {"swallow", "chiffchaff", "jay", "redwing", "jackdaw", "tern", "goose"}
BASE = {
    "swallow": (1, 1, 2), "chiffchaff": (1, 2, 2), "dunnock": (1, 2, 3),
    "redbreast": (2, 2, 4), "redwing": (2, 2, 4), "jay": (2, 3, 3),
    "tomtit": (3, 3, 4), "jackdaw": (3, 3, 3), "tern": (3, 3, 4),
    "cuckoo": (4, 3, 6), "magpye": (4, 3, 6), "stork": (4, 3, 6),
    "lump": (5, 3, 5), "goose": (5, 4, 7),
    "ratchet": (6, 4, 8), "whistlers": (6, 6, 8),
    "fill1": (1, 2, 3), "fill2": (2, 3, 4), "fill3": (3, 4, 5), "fill4": (4, 5, 6),
}
KEEPER_PREF = ["lump", "dunnock", "tomtit", "stork", "magpye", "cuckoo", "whistlers", "ratchet", "fill1", "fill2", "fill3", "fill4", "redbreast"]


class U:
    def __init__(self, name, golden=False):
        t, a, h = BASE[name]
        self.name, self.golden = name, golden
        m = 2 if golden else 1
        self.a, self.h = a * m, h * m
        self.state = "hand"; self.due = None; self.played = None; self.left = None
        self.keeper_of = None

    def flier(self):
        return self.name in FLIERS

    def bird(self):
        return not self.name.startswith("fill")

    def s(self):
        return self.a + self.h

    def __repr__(self):
        return f"{self.name}{'*' if self.golden else ''} {self.a}/{self.h}"


def run(schedule, P, verbose=False, keep_home=(), label=""):
    st = dict(W=P["W0"], homes=0)
    units = []
    snaps = {}

    def board():
        return [u for u in units if u.state == "board"]

    def come_home(u, t):
        u.state = "hand"; u.due = None
        W = st["W"]
        k = 2 if (u.golden and P["golden_bird_x2"]) else 1
        u.a += W * k; u.h += W * k
        st["homes"] += 1
        for r in board():
            if r.name == "redbreast":
                m = (2 if r.golden else 1) * P["rb"]
                r.a += int(W * m); r.h += int(W * m)
        cuck = [c for c in board() if c.name == "cuckoo"]
        if cuck and getattr(u, "keeper", None) is not None:
            m = sum(2 if c.golden else 1 for c in cuck[:1])
            u.keeper.a += W * m; u.keeper.h += W * m
        u.keeper = None
        if u.name == "goose" and P["goose_mode"] == "wide":
            m = 2 if u.golden else 1
            for b in units:
                if b.bird() and b.state in ("board", "hand", "away") and b is not u:
                    b.a += W * m; b.h += W * m
        if P["r"]:
            st["W"] += P["r"]
        elif not st.get("rose"):
            st["W"] += P["k"]; st["rose"] = True
        if u.name == "goose" and P["goose_mode"] == "double":
            st["W"] = int(st["W"] * (P["gmult"] ** (2 if u.golden else 1)))
        if u.name == "tern":
            for o in sorted([x for x in units if x.state == "away"], key=lambda x: x.left):
                if o.state == "away":
                    come_home(o, t)

    for t in range(1, P["rounds"] + 1):
        h0 = st["homes"]; st["rose"] = False
        for u in sorted([x for x in units if x.state == "away" and x.due <= t], key=lambda x: x.left):
            if u.state == "away":
                come_home(u, t)
        for item in schedule.get(t, []):
            name, g = (item if isinstance(item, tuple) else (item, False))
            if name.startswith("sell:"):
                for u in units:
                    if u.name == name[5:] and u.state in ("board", "hand"):
                        u.state = "gone"; break
                continue
            if name.startswith("gold:"):
                for u in units:
                    if u.name == name[5:] and u.state in ("board", "hand") and not u.golden:
                        u.golden = True; bt, ba, bh = BASE[u.name]; u.a += ba; u.h += bh  # triple: extra base copy (gains of the 3 kept, approx)
                        break
                continue
            if name == "supper":
                for u in units:
                    if u.bird() and u.state != "gone":
                        u.a += P["supper"]; u.h += P["supper"]
                continue
            nu = U(name, g); nu.keeper = None; units.append(nu)
        # fly eligible fliers first (frees slots)
        if t >= P["fly_from"]:
            elig = [u for u in board() if u.flier() and u.played is not None and u.played < t and u.name not in keep_home]
            elig.sort(key=lambda u: -u.s())
            nb = len(board())
            for u in elig:
                if nb - 1 < P["min_home"]:
                    break
                nb -= 1
                trip = 3 if u.name == "tern" else 2
                if u.name == "tern" and u.golden:
                    trip = 1
                u.state = "away"; u.due = t + trip; u.left = t; u.keeper = None

        def play_hand():
            for u in sorted([x for x in units if x.state == "hand"], key=lambda x: (x.flier(), -x.s())):
                if not u.flier() and len([x for x in board() if not x.flier()]) >= P["max_stay"]:
                    ws = sorted([x for x in board() if not x.flier() and x.name not in ("redbreast",)], key=lambda x: x.s())
                    weak = [x for x in ws if x.name.startswith("fill") or x.name in P["drop_order"]]
                    if weak:
                        weak[0].state = "gone"
                    else:
                        continue
                if len(board()) >= 7:
                    fills = sorted([x for x in board() if not x.bird()], key=lambda x: x.s())
                    if fills:
                        fills[0].state = "gone"
                    elif not u.flier():
                        continue
                    else:
                        continue
                u.state = "board"; u.played = t
                if u.name == "chiffchaff":
                    if P["chiff_mode"] == "raise":
                        st["W"] += P["chiff"] * (2 if u.golden else 1)
                    else:
                        m = 2 if u.golden else 1
                        u.a += st["W"] * m; u.h += st["W"] * m
        play_hand()
        storks = [u for u in board() if u.name == "stork"]
        if storks:
            n = (P["spend"] // 6) * sum(2 if s.golden else 1 for s in storks)
            for _ in range(n):
                c = sorted([x for x in units if x.state == "away" and x.left < t], key=lambda x: x.left)
                if not c:
                    break
                come_home(c[0], t)
            play_hand()
        # end of turn: dunnock
        for d in [u for u in board() if u.name == "dunnock"]:
            k = 2 if d.golden else 1
            for x in sorted([x for x in units if x.state == "away" and x.due > t + 1], key=lambda x: x.due)[:k]:
                x.due -= 1
        # place keepers on nests: away birds with nests, sorted by size; stayers stand on them
        b = board()
        away = sorted([x for x in units if x.state == "away"], key=lambda x: -x.s())
        stay = [u for u in b if not u.flier()]
        stay.sort(key=lambda u: KEEPER_PREF.index(u.name) if u.name in KEEPER_PREF else 99)
        nests = away[:7]  # at most 7 nests
        lump_bonus = 0
        used = set()
        for x in nests:
            for s in stay:
                if id(s) in used:
                    continue
                if s.name == "redbreast":
                    continue
                if s.name in ("ratchet",):  # wants back row, fine anywhere; skip as keeper
                    pass
                x.keeper = s; used.add(id(s))
                if s.name == "lump":
                    lump_bonus += x.s() * (2 if s.golden else 1)
                break
        free = 7 - len(b)
        eggs = []
        rw = 2 * len([u for u in b if u.name == "redwing"])
        tomtit = False
        for x in [x for x in nests if x.keeper is None][:max(free, 0)]:
            if rw > 0:
                e = x.s(); rw -= 1
            else:
                e = (x.a + 1) // 2 + (x.h + 1) // 2
            eggs.append(e)
        stats = sum(u.s() for u in b) + sum(eggs) + lump_bonus
        units_stats = sorted([u.s() for u in b] + eggs, reverse=True)
        if lump_bonus:
            pass
        big = max([u.s() + (lump_bonus if u.name == "lump" else 0) for u in b] + [0])
        snaps[t] = dict(stats=stats, W=st["W"], homes=st["homes"] - h0, big=big, share=big / max(stats, 1),
                        board=[repr(u) for u in b], eggs=eggs, lump=lump_bonus,
                        away=[repr(x) for x in away])
        if verbose:
            print(f"{label}R{t:2} W={st['W']:3} H={st['homes']-h0} stats={stats:5} big={big:4} share={big/max(stats,1):.2f} | {', '.join(repr(u) for u in b)} | eggs {eggs} lump+{lump_bonus} | away {[repr(x) for x in away]}")
    return snaps


P0 = dict(W0=1, r=0, k=1, chiff=1, rb=1, golden_bird_x2=0, spend=10, fly_from=3, rounds=16, supper=1,
          goose_mode="double", chiff_mode="gain", gmult=2, max_stay=5, min_home=0, drop_order=("dunnock", "tomtit", "fill1", "fill2", "fill3"))

# Engine line, strong-typical: T2 R3, T3 R5, T4 R7, T5 R9, T6 R12
STRONG = {
    1: ["chiffchaff"], 2: ["swallow"], 3: ["redbreast"], 4: ["jay", "fill2"],
    5: ["dunnock", "chiffchaff"], 6: ["tern", "tomtit"], 7: ["stork", "supper"],
    8: ["cuckoo", "redwing"], 9: ["goose", "sell:dunnock"], 10: ["lump", "supper"],
    11: ["jackdaw", "chiffchaff", "gold:chiffchaff"], 12: ["ratchet"], 13: ["supper"], 14: ["whistlers", "sell:tomtit"],
}
# Typical: one tier later, fewer pieces, no golden
TYPICAL = {
    1: ["swallow"], 2: [], 3: ["chiffchaff", "fill2"], 4: ["redbreast"], 5: ["jay", "fill2"],
    6: ["tern"], 7: ["fill3", "dunnock"], 8: ["stork", "supper"], 9: ["tomtit"], 10: ["cuckoo"],
    11: ["goose", "supper", "sell:dunnock"], 12: ["lump"], 13: ["ratchet"], 14: ["supper"], 15: ["jackdaw"],
}
# Highroll: golden Redbreast R6, T4 R6, T5 R8, T6 R10
HIGH = {
    1: ["chiffchaff"], 2: ["swallow"], 3: ["redbreast", "redbreast"], 4: ["jay", "dunnock"],
    5: ["redbreast", "gold:redbreast", "sell:redbreast", "sell:redbreast"], 6: ["stork", "tern"], 7: ["cuckoo", "supper"],
    8: ["goose", "chiffchaff"], 9: ["lump", "redwing"], 10: ["ratchet", "supper"], 11: ["stork", "gold:stork", "sell:stork"],
    12: ["whistlers", "sell:dunnock"], 13: ["supper"], 14: ["goose", "goose", "gold:goose", "sell:goose", "sell:goose"],
}

if __name__ == "__main__":
    P = dict(P0)
    for a in sys.argv[1:]:
        k, v = a.split("=")
        P[k] = v if not v.replace('.','').isdigit() else (float(v) if "." in v else int(v))
    for nm, sc in [("STRONG ", STRONG), ("TYPICAL", TYPICAL), ("HIGH   ", HIGH)]:
        print(nm, P)
        s = run(sc, P, verbose=True, label="")
        print(nm, "summary:", {r: (s[r]["stats"], round(s[r]["share"], 2), s[r]["W"]) for r in (6, 9, 12, 15) if r in s})
