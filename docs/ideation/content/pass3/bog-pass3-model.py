"""Bog folk pass 3 synthesis (bog-pass3.md): expected-value growth model.

A paper model, not a sim, and no fights are played. It sizes the synthesis
against the brief's shape (today's boards to round 7, then x1.5 a round) and
probes the breaks the critic found. Combat-only effects (Bitter's shrink, Bufo,
Sal, Hopkin, Peatlings, Gideon's hit back) don't show: it counts permanent
stats only.

Run: python3 -I bog-pass3-model.py              (main table and probes)
     python3 -I bog-pass3-model.py verbose      (every round of the main lines)

The engine modelled:
- Bitter takes a share s (default 1/4, rounded up, never below 1 Attack) of
  each biter's current Attack. Every Soak unit has Bitter.
- Soak: after the fight, the unit gains +k/+k per Attack its own Bitter took
  from enemies it Mires (k = 1, golden 2). Gains land at the next Start of
  Turn, never mid-fight.
- The Toll: everything all your Bitter took in your last fight.
- Tiddy Mun (T4): Start of Turn, the units beside her split half the Toll
  (one neighbour gets all of that half). Golden: the whole Toll.
- Warty Nan: Start of Turn, your smallest Bog folk gains a quarter of the
  Toll (golden: half).
- Kisses: one a fight while a frog prince is on the board, shared by all your
  frogs. Every third kiss, each frog doubles the units beside it (base plus
  permanent stats again); a unit is doubled once a turn. His Highness becomes
  the Prince Restored (6/7, Mire, Soak) on the first break.
- Ranocchio: after he attacks a Mired enemy, +1/+1 per 4 of its Attack,
  ~1.6 attacks a fight at the Mired enemy with the most Attack. Not Bitter, so
  not in the Toll.
- Soak counts only what Bitter took from the enemies a unit Mires (bites from
  free enemies still go into the Toll).
- Spitfire Sal, Bufo, Hopkin, Gideon's hit back and the Peat King's Peatlings
  are combat only and don't show.

Assumptions a critic should attack:
- Enemy board = the target median (or the strong Sept 2025 curve with
  field=strong). Biggest unit 45% to round 5, a third after. 47% of stats are
  Attack. The carry bites 1.5 times a fight (the second at 3/4 Attack), each
  support 1.4 times. 85% of patches find an attacker.
- The carry's bites go to the Lantern Man if present, else to the Diva with
  probability p (0.65; 0.85 if she is the Prima Donna or Jenny), else to Jenny
  (0.6). The rest of the field's bites land on your front row; a share equal
  to the Bitter share of your front row is taken.
- Bodies are printed (no scale-build body multiplier). Harvest Supper +1/+1
  for Bog folk at rounds 5, 8 and 11. No gold accounting.
"""
import math
import sys

TODAY = {1: 5, 2: 10, 3: 17, 4: 26, 5: 37, 6: 50, 7: 65}
STRONG = {1: 5, 2: 11, 3: 18, 4: 26, 5: 38, 6: 53, 7: 79, 8: 123, 9: 194, 10: 305,
          11: 482, 12: 759, 13: 1177, 14: 1751, 15: 2600, 16: 3900}


def median(r):
    return TODAY[r] if r <= 7 else 65 * 1.5 ** (r - 7)


# card id: (attack, health, mire patches, bitter, soak)
CARDS = {
    "bridge_toad": (1, 3, 1, True, True),
    "warty_nan": (1, 3, 0, True, False),
    "young_pretender": (3, 2, 0, False, False),
    "madame_bufo": (1, 4, 1, True, False),
    "vaulting_hopkin": (3, 1, 0, False, False),
    "peat_cutter": (2, 4, 1, False, False),
    "gideon": (2, 6, 1, True, True),
    "natterjack_chorus": (3, 4, 0, False, False),
    "spitfire_sal": (1, 3, 0, False, False),
    "tiddy_mun": (3, 5, 0, False, False),
    "his_highness": (3, 5, 0, False, False),
    "signor_ranocchio": (3, 4, 0, True, True),
    "prima_donna": (2, 8, 3, True, True),
    "jenny_greenteeth": (4, 7, 1, True, True),
    "peat_king": (5, 9, 1, True, True),
    "lantern_man": (4, 8, 1, True, True),
}


class Unit:
    def __init__(self, cid, front, golden=False):
        a, h, mire, bitter, soak = CARDS[cid]
        g = 2 if golden else 1
        self.id, self.front, self.golden = cid, front, golden
        self.a, self.h = a * g, h * g
        self.mire, self.bitter, self.soak = mire, bitter, soak
        self.keep = 2 if golden else 1
        self.took = 0.0

    @property
    def size(self):
        return self.a + self.h

    def grow(self, x):
        self.a += x
        self.h += x


def run(line, s=0.25, k=1.0, field="median", nan_share=0.25, repeat=3,
        shared_kisses=True, king_doubles=False, p_diva=0.65, tiddy_share=0.5,
        rounding="up", soak_mired_only=True, verbose=False):
    F = median if field == "median" else (lambda r: STRONG[r])
    board, kisses, broken, out, supper = {}, 0, False, {}, 0
    frog_kisses = {}

    def take(a):
        a = round(a)
        cut = math.ceil(s * a) if rounding == "up" else math.floor(s * a)
        return 0 if a <= 1 else min(a - 1, cut)

    for r in range(1, 17):
        for ev in line.get(r, []):
            op, key = ev[0], ev[1]
            if op == "buy":
                u = Unit(ev[2], ev[3], golden=(len(ev) > 4 and ev[4] == "golden"))
                u.grow(supper)
                board[key] = u
                if ev[2] == "his_highness":
                    frog_kisses[key] = 0
            elif op == "sell":
                board.pop(key, None)
                frog_kisses.pop(key, None)
            elif op == "diva":
                line["_diva"] = key
            elif op == "beside":           # (frog or tiddy key, [neighbour keys])
                line.setdefault("_beside", {})[key] = ev[2]
        if r in (8, 11):
            supper += 1
            for u in board.values():
                u.grow(1)
        total = sum(u.size for u in board.values())
        big = max(board.values(), key=lambda u: u.size)
        diva = board.get(line.get("_diva"))
        E = F(r)
        out[r] = dict(E=E, total=total, med=median(r), ratio=total / median(r),
                      strong=total / STRONG[r], share=big.size / total, big=big.id,
                      diva=(diva.a, diva.h) if diva else None,
                      units={k2: (round(u.a), round(u.h), u.id) for k2, u in board.items()})
        # The fight. Enemy board from the field curve.
        n = min(7, max(1, r))
        cs = 0.45 if r < 6 else 1 / 3
        Ac = 0.47 * cs * E
        As = 0.47 * (1 - cs) * E / (n - 1) if n > 1 else 0
        carry_take = take(Ac) + 0.5 * take(0.75 * Ac)
        sup_take = take(As) + 0.4 * take(0.75 * As)
        for u in board.values():
            u.took = 0.0
        # Who drinks the carry.
        lantern = board.get("lantern")
        jenny = next((u for u in board.values() if u.id == "jenny_greenteeth"), None)
        drinker, p = None, 0.0
        if lantern:
            drinker, p = lantern, 1.0
        elif diva and diva.mire:
            drinker = diva
            p = 0.85 if diva.id in ("prima_donna", "jenny_greenteeth") else p_diva
        if drinker:
            drinker.took += p * carry_take
        free_carry = 1 - p
        if jenny and jenny is not drinker:
            jenny.took += free_carry * 0.6 * carry_take
            free_carry *= 0.4
        # Support patches: every other Mire patch takes a support, 85% filled.
        sups_left = n - 1
        chorus = [k2 for k2, u in board.items() if u.id == "natterjack_chorus"]
        lent = set()
        for c in chorus:
            for nb in line.get("_beside", {}).get(c, []):
                lent.add(nb)
        for key, u in board.items():
            patches = u.mire + (1 if key in lent and u.mire == 0 else 0)
            has_bitter = u.bitter or key in lent
            if key in lent:
                u.soak = True
            if u is drinker:
                patches -= 1
            for _ in range(patches):
                if sups_left <= 0:
                    break
                sups_left -= 1
                if has_bitter:
                    u.took += 0.85 * sup_take
        # Unmired supports bite the front row.
        front = [u for k2, u in board.items() if u.front]
        bitter_front = [u for k2, u in board.items() if u.front and (u.bitter or k2 in lent)]
        loose_toll = 0.0
        if front and (sups_left > 0 or free_carry > 0):
            share = len(bitter_front) / len(front)
            loose = sups_left * sup_take + free_carry * carry_take
            loose_toll = loose * share
            if not soak_mired_only:
                for u in bitter_front:
                    u.took += loose_toll / max(1, len(bitter_front))
                loose_toll = 0.0
        # Ranocchio drains the stuck carry when he attacks.
        for u in board.values():
            if u.id == "signor_ranocchio":
                u.took += take(Ac) + 0.6 * take(0.75 * Ac)
        toll = sum(u.took for u in board.values()
                   if (u.bitter or u.soak) and u.id != "signor_ranocchio") + loose_toll
        out[r]["toll"] = toll
        # After the fight: Soak, the King, Tiddy, Nan.
        kmult = 2 if (king_doubles and any(u.id == "peat_king" for u in board.values())) else 1
        for u in board.values():
            if u.soak:
                u.grow(k * u.keep * kmult * u.took)
        for key, u in board.items():
            if u.id == "tiddy_mun":
                nbs = [board[x] for x in line.get("_beside", {}).get(key, []) if x in board]
                for nb in nbs:
                    nb.grow(k * tiddy_share * (2 if u.golden else 1) * toll / len(nbs))
        for key, u in board.items():
            if u.id == "warty_nan":
                low = min(board.values(), key=lambda x: x.size)
                low.grow((2 if u.golden else 1) * nan_share * toll)
        # Kisses and the curse.
        frogs = [key for key, u in board.items() if u.id in ("his_highness", "prince_restored")]
        doubled = set()
        if frogs:
            kisses += 1
            for f in frogs:
                frog_kisses[f] = frog_kisses.get(f, 0) + 1
            for f in frogs:
                count = kisses if shared_kisses else frog_kisses[f]
                if count % repeat == 0:
                    fu = board[f]
                    mult = 3 if fu.golden else 2
                    for nb in line.get("_beside", {}).get(f, []):
                        if nb in board and (nb not in doubled or not shared_kisses):
                            t = board[nb]
                            t.grow(0)
                            t.a, t.h = t.a * mult, t.h * mult
                            doubled.add(nb)
                    if fu.id == "his_highness":
                        fu.id, fu.mire, fu.soak, fu.bitter = "prince_restored", 1, True, True
                        fu.a, fu.h = fu.a + 3 * (2 if fu.golden else 1), fu.h + 2 * (2 if fu.golden else 1)
        if verbose:
            print(f"  R{r:2d} med {median(r):6.0f} bog {total:6.0f} ({total / median(r):4.2f}x med,"
                  f" {total / STRONG[r]:4.2f}x strong) big {big.id[:12]:12s} {big.size / total:4.2f}"
                  f" toll {toll:6.1f} diva {diva.a if diva else 0:5.0f}/{diva.h if diva else 0:<5.0f}"
                  f" kisses {kisses}")
    return out


def L(events):
    """Copy a line so runs don't share state."""
    return {r: list(v) for r, v in events.items()}


# Lines: round -> events. ('buy', key, card, front?) ('sell', key) ('diva', key)
# ('beside', frog_or_tiddy_key, [neighbour keys]).
# Gold-honest lines: 3 gold a unit, tier-ups on the climb schedule, about one
# unit bought on a climb turn and two otherwise; board full at round 8.
DIVA_STRONG = {  # climb [2, 4, 6, 8, 10]; pieces on time; never more than 7 units
    1: [("buy", "toad", "bridge_toad", True)],
    3: [("buy", "nan", "warty_nan", True), ("buy", "pret", "young_pretender", False)],
    4: [("buy", "bufo", "madame_bufo", True)],
    5: [("buy", "gid", "gideon", True), ("buy", "hop", "vaulting_hopkin", False)],
    6: [("buy", "tiddy", "tiddy_mun", True), ("diva", "gid"), ("beside", "tiddy", ["gid"])],
    7: [("sell", "pret"), ("buy", "hh", "his_highness", True), ("beside", "hh", ["gid", "bufo"])],
    9: [("sell", "hop"), ("buy", "pd", "prima_donna", False)],
    10: [("sell", "nan"), ("buy", "king", "peat_king", False)],
    12: [("sell", "bufo"), ("buy", "lantern", "lantern_man", False)],
}
DIVA_TYPICAL = {  # climb [2, 5, 7, 9, 11]; each piece a round or two late
    1: [("buy", "toad", "bridge_toad", True)],
    3: [("buy", "nan", "warty_nan", True)],
    4: [("buy", "bufo", "madame_bufo", True), ("buy", "pret", "young_pretender", False)],
    6: [("buy", "gid", "gideon", True), ("buy", "hop", "vaulting_hopkin", False)],
    7: [("buy", "sal", "spitfire_sal", False)],
    8: [("sell", "pret"), ("buy", "tiddy", "tiddy_mun", True), ("diva", "gid"),
        ("beside", "tiddy", ["gid"])],
    9: [("sell", "sal"), ("buy", "hh", "his_highness", True), ("beside", "hh", ["gid", "bufo"])],
    10: [("sell", "hop"), ("buy", "pd", "prima_donna", False)],
    12: [("sell", "bufo"), ("buy", "king", "peat_king", False)],
    14: [("sell", "nan"), ("buy", "lantern", "lantern_man", False)],
}
DIVA_SPREAD = {r: [(("beside", "tiddy", ["gid", "toad"]) if e[:2] == ("beside", "tiddy") else
                     ("beside", "hh", ["toad", "bufo"]) if e[:2] == ("beside", "hh") else e)
                    for e in v] for r, v in DIVA_TYPICAL.items()}  # Tiddy and the frog between two units each
DIVA_LOW = {      # Tiddy late, no frog prince
    1: [("buy", "toad", "bridge_toad", True)],
    3: [("buy", "nan", "warty_nan", True)],
    4: [("buy", "bufo", "madame_bufo", True), ("buy", "pret", "young_pretender", False)],
    6: [("buy", "gid", "gideon", True), ("buy", "hop", "vaulting_hopkin", False)],
    7: [("buy", "sal", "spitfire_sal", False)],
    8: [("sell", "pret"), ("buy", "cut", "peat_cutter", False)],
    10: [("sell", "cut"), ("buy", "tiddy", "tiddy_mun", True), ("diva", "gid"),
         ("beside", "tiddy", ["gid"])],
    11: [("sell", "sal"), ("buy", "pd", "prima_donna", False)],
    13: [("sell", "hop"), ("buy", "king", "peat_king", False)],
}
SWAMP = {         # wide: lent Soak, Tiddy in the middle, Nan levels, no frog prince
    1: [("buy", "toad", "bridge_toad", True)],
    3: [("buy", "nan", "warty_nan", True)],
    4: [("buy", "bufo", "madame_bufo", True), ("buy", "cut", "peat_cutter", False)],
    6: [("buy", "gid", "gideon", True), ("buy", "cho", "natterjack_chorus", True),
        ("beside", "cho", ["bufo", "nan"])],
    7: [("buy", "sal", "spitfire_sal", False)],
    8: [("sell", "cut"), ("buy", "ran", "signor_ranocchio", False)],
    9: [("sell", "sal"), ("buy", "tiddy", "tiddy_mun", False), ("beside", "tiddy", ["gid", "ran"])],
    10: [("sell", "toad"), ("buy", "pd", "prima_donna", False), ("beside", "tiddy", ["pd", "ran"])],
    12: [("sell", "bufo"), ("buy", "king", "peat_king", True)],
    14: [("sell", "cho"), ("buy", "lantern", "lantern_man", True)],
}


def golden(line, key, rnd):
    """Make the unit bought under `key` golden from round `rnd`."""
    line = L(line)
    for r, evs in list(line.items()):
        for i, ev in enumerate(evs):
            if ev[0] == "buy" and ev[1] == key:
                if r >= rnd:
                    evs[i] = ev[:4] + ("golden",)
                else:
                    line.setdefault(rnd, []).insert(0, ("buy", key, ev[2], ev[3], "golden"))
    return line


def second_frog(line, rnd, beside):
    line = L(line)
    line.setdefault(rnd, []).extend([("sell", "nan"), ("buy", "hh2", "his_highness", False),
                                     ("beside", "hh2", beside)])
    return line


def geo(out, rs, key="ratio"):
    return math.prod(out[r][key] for r in rs) ** (1 / len(rs))


def row(name, out, rounds=(6, 9, 12, 15)):
    cells = []
    for r in rounds:
        o = out[r]
        cells.append(f"R{r} {o['ratio']:4.2f}x ({o['share']:.2f})")
    cells.append(f"R11-13 {geo(out, (11, 12, 13)):4.2f}x")
    cells.append(f"R14-16 {geo(out, (14, 15, 16)):4.2f}x")
    print(f"  {name:34s} " + " | ".join(cells))


if __name__ == "__main__":
    verbose = len(sys.argv) > 1 and sys.argv[1] == "verbose"
    print("Bog total at the fight, x the brief's median, (biggest unit's share). Median:",
          " ".join(f"R{r} {median(r):.0f}" for r in (6, 9, 12, 15)))
    print("== Main lines, defaults (Bitter 1/4 rounded up, k=1, Soak from its Mired enemy, Tiddy 1/2,"
          " Nan 1/4, every 3rd kiss, shared kisses). R11-13 and R14-16 are geometric means,"
          " which smooth the frog's doubling")
    for name, line in (("Diva, strong (pieces on time)", DIVA_STRONG),
                       ("Diva, typical (a round or two late)", DIVA_TYPICAL),
                       ("Court, spread (Tiddy, frog split)", DIVA_SPREAD),
                       ("Diva, lowroll (Tiddy R10, no frog)", DIVA_LOW),
                       ("Swamp (wide), typical", SWAMP)):
        if verbose:
            print(" ", name)
        row(name, run(L(line), verbose=verbose))
    print("== The same lines against the strong (Sept 2025) field: x strong board")
    for name, line in (("Diva, typical", DIVA_TYPICAL), ("Swamp", SWAMP)):
        o = run(L(line), field="strong")
        print(f"  {name:34s} " + " | ".join(f"R{r} {o[r]['total']:5.0f} {o[r]['strong']:4.2f}x"
                                             for r in (6, 9, 12, 15))
              + f" | R11-13 {geo(o, (11, 12, 13), 'strong'):4.2f}x")
    print("== Rate sweep on Diva, typical (k = keep, s = Bitter share)")
    for k in (0.5, 1.0, 1.5):
        for s in (0.2, 0.25, 1 / 3):
            row(f"k={k} s={s:.2f}", run(L(DIVA_TYPICAL), s=s, k=k))
    print("== Breaker probes on Diva, typical")
    row("as shipped", run(L(DIVA_TYPICAL)))
    row("two frogs, shared kisses (the fix)", run(second_frog(DIVA_TYPICAL, 10, ["gid", "pd"])))
    row("two frogs, own kisses (no fix)", run(second_frog(DIVA_TYPICAL, 10, ["gid", "pd"]),
                                               shared_kisses=False))
    row("golden His Highness R10", run(golden(DIVA_TYPICAL, "hh", 10)))
    row("golden Gideon (Diva) R7", run(golden(DIVA_TYPICAL, "gid", 7)))
    row("golden Bridge Toad R4", run(golden(DIVA_TYPICAL, "toad", 4)))
    row("golden Warty Nan R4", run(golden(DIVA_TYPICAL, "nan", 4)))
    row("golden Tiddy Mun R11", run(golden(DIVA_TYPICAL, "tiddy", 11)))
    row("King doubles Soak (carry design)", run(L(DIVA_TYPICAL), king_doubles=True))
    row("Nan at half", run(L(DIVA_TYPICAL), nan_share=0.5))
    row("Tiddy gives the whole Toll", run(L(DIVA_TYPICAL), tiddy_share=1.0))
    row("Soak from every bite (not only Mired)", run(L(DIVA_TYPICAL), soak_mired_only=False))
    row("Bitter rounds down", run(L(DIVA_TYPICAL), rounding="down"))
    row("Prince every 4th kiss", run(L(DIVA_TYPICAL), repeat=4))
    row("Prince off (one break only)", run(L(DIVA_TYPICAL), repeat=99))
    row("Diva drinks the carry 45%", run(L(DIVA_TYPICAL), p_diva=0.45))
    print("== Boards at the fight (Attack/Health), typical court and Swamp")
    for name, line in (("Diva, typical", DIVA_TYPICAL), ("Swamp", SWAMP)):
        o = run(L(line))
        for r in (9, 12, 15):
            print(f"  {name} R{r} ({o[r]['total']:.0f}): " + ", ".join(
                f"{v[2]} {v[0]}/{v[1]}" for v in sorted(o[r]["units"].values(),
                                                        key=lambda v: -(v[0] + v[1]))))
    print("== Highroll: strong line, golden frog R8, golden Gideon R7")
    row("highroll", run(golden(golden(DIVA_STRONG, "hh", 8), "gid", 7)))


def combos():
    print("== Combos: tiddy share / nan share / prince repeat")
    for ts in (1.0, 0.5):
        for ns in (0.5, 0.25):
            for rep in (3, 4, 99):
                tag = f"tiddy {ts} nan {ns} prince {rep if rep < 99 else 'once'}"
                for name, line in (("strong", DIVA_STRONG), ("typical", DIVA_TYPICAL),
                                   ("low", DIVA_LOW), ("swamp", SWAMP)):
                    row(f"{tag:28s} {name:7s}", run(L(line), tiddy_share=ts, nan_share=ns,
                                                     repeat=rep))
