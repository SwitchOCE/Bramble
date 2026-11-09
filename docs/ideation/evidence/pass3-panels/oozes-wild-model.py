"""Oozes pass 3 (identity and delight): a growth calculator, not a combat sim.

Run:  python3 -I oozes-wild-model.py            (default parameters, both lines)
      python3 -I oozes-wild-model.py sweep      (Rise rate r and Soup amount)

It plays two scripted lines turn by turn with average shops (named cards
arrive on the turns written in each plan; an unaffordable step waits a turn)
and reports board stats at the combat-start snapshot: units on the board plus
everything inside Bellies. Granny's Start of Combat gain is reported
separately, because it counts the family twice. Nothing here fights; the
numbers size effects against the target shape (BG September 2025 means).
"""
import sys

TARGET = {4: 24, 5: 36, 6: 53, 7: 79, 8: 123, 9: 194, 10: 305, 11: 482,
          12: 759, 13: 1177, 14: 1751, 15: 2600, 16: 3900}
BOTS_TODAY = {4: 30, 6: 52, 8: 80, 10: 107, 12: 133, 14: 155}
INCOME = {1: 3, 2: 4, 3: 5, 4: 6, 5: 7, 6: 8, 7: 9}
TIER_BASE = {2: 5, 3: 7, 4: 8, 5: 11, 6: 11}
# average plain unit bought at each tier (Attack, Health), before Soup
PLAIN = {1: (2, 3), 2: (3, 4), 3: (4, 5), 4: (5, 6), 5: (6, 8), 6: (8, 9)}

# Rates. r: Rise. elder: share on coming out. hasty: digest. slice: Cut-and-
# Come-Again copy. granny: share of the family. soup: +X/+X per belly buy.
# aspic: +k/+k a turn. nell: share of the eaten unit.
P = dict(r=(1, 2), elder=1, hasty=(1, 4), slice=(1, 2), granny=(1, 2),
         soup=1, aspic=1, nell=(1, 2), nell_buff=True, nell_sides=0)


def frac(x, f):
    return x * f[0] // f[1]


class U:
    def __init__(self, name, a, h, ooze=False, belly=0, rise=False, tier=1, created=False):
        self.name, self.a, self.h = name, a, h
        self.ooze, self.belly, self.rise, self.tier = ooze, belly, rise, tier
        self.inside = []
        self.created = created

    def stats(self):
        return self.a + self.h

    def total(self):
        return self.stats() + sum(u.total() for u in self.inside)

    def __repr__(self):
        s = f"{self.name} {self.a}/{self.h}"
        if self.inside:
            s += " [" + ", ".join(repr(u) for u in self.inside) + "]"
        return s


SLOTS = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
BESIDE = {"B1": ["B2"], "B2": ["B1", "B3"], "B3": ["B2"],
          "F1": ["F2"], "F2": ["F1", "F3"], "F3": ["F2", "F4"], "F4": ["F3"]}
NEXT_TO = {"F1": ["F2", "B1"], "F2": ["F1", "F3", "B1", "B2"], "F3": ["F2", "F4", "B2", "B3"],
           "F4": ["F3", "B3"], "B1": ["B2", "F1", "F2"], "B2": ["B1", "B3", "F2", "F3"],
           "B3": ["B2", "F3", "F4"]}


class State:
    def __init__(self):
        self.gold = 0
        self.tier = 1
        self.up_cost = TIER_BASE[2]
        self.board = {s: None for s in SLOTS}
        self.hand = []
        self.shop_buff = 0      # Stone Soup: +X/+X this game on shop units
        self.soups = 0          # Soup triggers per belly buy
        self.pending = []       # plan steps waiting for gold
        self.hasty_gain = 0
        self.ooze_buff = 0      # Elder Ooze: your Oozes have +X/+X this game
        self.soup_fired = 0     # Soup: twice a turn

    def plain(self, tier=None, name="unit"):
        t = tier or self.tier
        a, h = PLAIN[t]
        return U(name, a + self.shop_buff, h + self.shop_buff, tier=t)

    def card(self, name, a, h, **kw):
        return U(name, a + self.shop_buff, h + self.shop_buff, ooze=True, **kw)

    def can(self, n):
        return self.gold >= n

    def pay(self, n):
        assert self.gold >= n, (self.gold, n)
        self.gold -= n

    def place(self, unit, slot):
        old = self.board[slot]
        if old is not None:
            if not old.created:
                self.gold += 1
            self.hand.extend(old.inside)
        self.board[slot] = unit

    def buy_into(self, unit, slot, cost=3):
        self.pay(cost)
        host = self.board[slot]
        assert host and len(host.inside) < host.belly, (slot, host)
        host.inside.append(unit)
        if self.soup_fired < 2:
            self.shop_buff += P["soup"] * self.soups
            self.soup_fired += 1

    def tier_up(self):
        self.pay(self.up_cost)
        self.tier += 1
        self.up_cost = TIER_BASE.get(self.tier + 1, 99)

    def contents(self, rows=("F", "B")):
        for s in SLOTS:
            u = self.board[s]
            if u and s[0] in rows:
                for c in u.inside:
                    yield s, u, c

    def snapshot(self):
        n = sum(1 for u in self.board.values() if u and u.ooze) + sum(
            1 for _, _, c in self.contents() if c.ooze)
        return sum(u.total() for u in self.board.values() if u) + 2 * self.ooze_buff * n

    def biggest(self):
        best = None
        for s in SLOTS:
            u = self.board[s]
            if not u:
                continue
            for x in [u] + u.inside:
                if best is None or x.stats() > best.stats():
                    best = x
        return best

    def named(self, name):
        return [s for s in SLOTS if self.board[s] and self.board[s].name == name]


def start_of_turn(st):
    r = P["r"]
    for s in ["B1", "B2", "B3"]:
        u = st.board[s]
        if u and u.rise:
            for c in u.inside:
                c.a += max(1, frac(c.a, r))
                c.h += max(1, frac(c.h, r))
            if u.name == "Cut-and-Come-Again":
                for c in u.inside:
                    if not c.ooze:
                        st.hand.append(U("slice of " + c.name, frac(c.a, P["slice"]),
                                         frac(c.h, P["slice"]), tier=c.tier, created=True))


def end_of_turn(st):
    for s in st.named("Aunt Aspic"):
        k = P["aspic"]
        for _, _, c in st.contents():
            c.a += k
            c.h += k
    for s in st.named("Dishwater Nell"):
        low = max(1, st.tier - 3)
        a, h = PLAIN[low]
        b = st.shop_buff if P["nell_buff"] else 0
        a, h = frac(a + b, P["nell"]), frac(h + b, P["nell"])
        if P["nell_sides"] == 0:     # the biggest unit inside your Oozes
            cs = [c for _, _, c in st.contents()]
            if cs:
                c = max(cs, key=lambda c: c.stats())
                c.a += a
                c.h += h
            continue
        for n in BESIDE[s][: P["nell_sides"]]:
            v = st.board[n]
            if v and v.ooze:
                for c in v.inside:
                    c.a += a
                    c.h += h
    for s in st.named("Bubble and Squeak"):
        u = st.board[s]
        if len(u.inside) >= 2:
            last = u.inside[-1]
            for other in u.inside[:-1]:
                last.a += other.a
                last.h += other.h
            u.inside = [last]


def fight_effects(st, rnd):
    """Permanent gains made in the fight: Elder on front-row openings (each
    front Ooze assumed to open once a fight), and Hasty's digest of the
    field's biggest unit (34% of the target board)."""
    if st.named("Elder Ooze"):
        # openings a fight: each front Ooze holding a unit, plus Elder's own when it dies
        opens = sum(1 for s in ["F1", "F2", "F3", "F4"] if st.board[s] and st.board[s].inside)
        opens += sum(1 for s in ["B1", "B2", "B3"] if st.board[s] and st.board[s].inside) // 2
        st.ooze_buff += P["elder"] * opens
    for s in st.named("Hasty Pudding"):
        u = st.board[s]
        if not u.inside:
            prey = 0.34 * TARGET.get(rnd, 3900)
            g = int(prey * P["hasty"][0] / P["hasty"][1])
            u.a += g // 2
            u.h += g - g // 2
            st.hasty_gain += g


ZIGZAG = ["F1", "B1", "F2", "B2", "F3", "B3", "F4"]


def granny_gain(st):
    """Touching = the unbroken zigzag run of Oozes through Granny's slot.
    Hasty is kept out of the run (the line leaves a gap before it)."""
    for s in st.named("Granny Stir-Up"):
        i = ZIGZAG.index(s)
        run = []
        for step in (-1, 1):
            j = i + step
            while 0 <= j < len(ZIGZAG):
                v = st.board[ZIGZAG[j]]
                if not v or not v.ooze or v.name == "Hasty Pudding":
                    break
                run.append(v)
                j += step
        fam = sum(v.total() + 2 * st.ooze_buff for v in run)
        return frac(fam, P["granny"])
    return 0


def spend_rest(st, line):
    """Leftover gold: buy plain units into Bellies with room, then fill empty
    slots, then replace the weakest plain unit if the new one is bigger."""
    while st.gold >= 2:
        placed = False
        for s in line["belly_order"]:
            u = st.board[s]
            if u and u.belly and len(u.inside) < u.belly and u.name != "Hasty Pudding":
                cost = 2 if u.name == "Little Dollop" else 3
                if st.can(cost):
                    st.buy_into(st.plain(), s, cost)
                    placed = True
                    break
        if placed:
            continue
        if st.gold < 3:
            break
        empty = [s for s in SLOTS if st.board[s] is None]
        if empty:
            st.pay(3)
            st.place(st.plain(), empty[0])
            continue
        plains = [s for s in SLOTS if st.board[s] and st.board[s].name not in line["keep"]
                  and not st.board[s].inside]
        weak = min(plains, key=lambda s: st.board[s].stats(), default=None)
        new = st.plain()
        if weak and new.stats() > st.board[weak].stats() + 2:
            st.pay(3)
            st.place(new, weak)
            continue
        churn = [(c.stats(), s, c) for s, u, c in st.contents()
                 if not u.rise and u.name != "Cut-and-Come-Again"]
        if churn:
            sm, s, c = min(churn, key=lambda t: t[0])
            if new.stats() > sm + 2:
                st.board[s].inside.remove(c)
                st.gold += 1
                st.buy_into(new, s)
                continue
        break
    if line.get("pinch") and st.named("Moss Ooze"):
        ovens = [st.board[s] for s in ["B1", "B2", "B3"] if st.board[s] and st.board[s].rise]
        oven = max(ovens, key=lambda u: len(u.inside), default=None)
        while st.gold >= 1 and oven:
            st.pay(1)
            oven.a += 1
            oven.h += 1
            for c in oven.inside:
                c.a += 1
                c.h += 1


# ---------------------------------------------------------------------------
# Plan steps: (round, action). An action returns False if it can't afford it.

ABLATE = set()


def buy_card(name, a, h, slot, cost=3, soup=False, **kw):
    def act(st):
        if not st.can(cost):
            return False
        st.pay(cost)
        if name in ABLATE:     # a plain unit of the same tier takes its place
            u = st.plain(kw.get("tier", 1), "plain " + name)
            u.ooze = True
            st.place(u, slot)
            return True
        st.place(st.card(name, a, h, **kw), slot)
        if soup:
            st.soups += 1
        return True
    return act


def cut_and_come(slot, pie):
    """Buy Cut-and-Come-Again over the oven in `slot`, move the Pie's biggest
    riser into it, and put the old oven's unit into the Pie's freed place."""
    def act(st):
        if not st.can(3):
            return False
        old = st.board[slot]
        held = list(old.inside) if old else []
        st.pay(3)
        if "Cut-and-Come-Again" in ABLATE:
            return True
        st.board[slot] = st.card("Cut-and-Come-Again", 6, 8, belly=1, rise=True, tier=6)
        st.gold += 1
        p = st.board[pie]
        if p and p.inside:
            big = max(p.inside, key=lambda c: c.stats())
            p.inside.remove(big)
            st.board[slot].inside.append(big)
            for c in held[: p.belly - len(p.inside)]:
                p.inside.append(c)
        return True
    return act


def play_slices(st):
    st.hand.sort(key=lambda u: -u.stats())
    played = 0
    for sl in [u for u in st.hand if u.created]:
        if played >= 2:
            break
        front = [s for s in ["F1", "F2", "F3", "F4"] if st.board[s]
                 and st.board[s].name not in ("Hasty Pudding", "Stone Soup")]
        weak = min(front, key=lambda s: st.board[s].total(), default=None)
        if weak and sl.stats() > st.board[weak].total():
            st.place(sl, weak)
            st.hand.remove(sl)
            played += 1
    st.hand = [u for u in st.hand if not u.created]
    return True


CARRY_PLAN = {
    1: [buy_card("Wee Wobbly", 1, 4, "F1", belly=1)],
    2: [buy_card("Little Dollop", 1, 3, "F2", belly=1)],
    3: [buy_card("Stone Soup", 2, 3, "F3", belly=1, tier=2, soup=True)],
    4: [buy_card("Dishwater Nell", 2, 3, "B2", tier=2)],
    5: [buy_card("The Sixpenny Pie", 2, 5, "B3", belly=2, rise=True, tier=3)],
    6: [buy_card("Moss Ooze", 2, 4, "F4", tier=2)],
    7: [buy_card("Figgy Duff", 4, 6, "B1", belly=1, rise=True, tier=4)],
    9: [buy_card("Hasty Pudding", 3, 10, "F2", belly=1, tier=5)],
    11: [cut_and_come("B1", "B3")],
    12: [play_slices], 13: [play_slices], 14: [play_slices], 15: [play_slices], 16: [play_slices],
}

WIDE_PLAN = {
    1: [buy_card("Wee Wobbly", 1, 4, "F1", belly=1)],
    2: [buy_card("Mrs Posset", 2, 2, "F2", belly=1)],
    3: [buy_card("Stone Soup", 2, 3, "F3", belly=1, tier=2, soup=True)],
    4: [buy_card("Little Dollop", 1, 3, "F4", belly=1)],
    5: [buy_card("Aunt Aspic", 2, 5, "B2", tier=3)],
    6: [buy_card("The Sixpenny Pie", 2, 5, "B1", belly=2, rise=True, tier=3)],
    7: [buy_card("Stone Soup", 2, 3, "B3", belly=1, tier=2, soup=True)],
    9: [buy_card("Elder Ooze", 5, 9, "F4", belly=1, tier=5)],
    10: [buy_card("Hasty Pudding", 3, 10, "F3", belly=1, tier=5)],
    11: [buy_card("Granny Stir-Up", 6, 10, "F2", tier=6)],
}

LINES = {
    "carry": dict(plan=CARRY_PLAN, climb=[3, 5, 7, 9, 11],
                  belly_order=["B3", "B1", "F2", "F1", "F3", "F4"], pinch=True,
                  keep={"Dishwater Nell", "The Sixpenny Pie", "Figgy Duff", "Cut-and-Come-Again",
                        "Hasty Pudding", "Moss Ooze", "Stone Soup", "Wee Wobbly"}),
    "wide": dict(plan=WIDE_PLAN, climb=[3, 5, 7, 9, 11],
                 belly_order=["F4", "F1", "F2", "F3", "B1", "B3"], pinch=False,
                 keep={"Stone Soup", "Aunt Aspic", "The Sixpenny Pie", "Elder Ooze", "Hasty Pudding",
                       "Granny Stir-Up", "Wee Wobbly", "Mrs Posset", "Little Dollop"}),
}


def late(plan, by=1):
    """A typical roll: every named card from round 3 on arrives `by` turns later."""
    out = {}
    for k, v in plan.items():
        nk = k + by if k >= 3 else k
        out.setdefault(nk, []).extend(v)
    return out


def run(line, rounds=16, show=False):
    st = State()
    out = {}
    for rnd in range(1, rounds + 1):
        st.gold += INCOME.get(rnd, 10)
        if rnd >= 2 and st.tier < 6:
            st.up_cost = max(0, st.up_cost - 1)
        start_of_turn(st)
        st.soup_fired = 0
        steps = st.pending + line["plan"].get(rnd, [])
        st.pending = []
        while st.tier < 6 and rnd >= line["climb"][st.tier - 1] and st.can(st.up_cost):
            st.tier_up()
        for act in steps:
            if not act(st):
                st.pending.append(act)
        if not st.pending:
            spend_rest(st, line)
        end_of_turn(st)
        snap = st.snapshot()
        g = granny_gain(st)
        b = st.biggest()
        out[rnd] = (snap, g, U(b.name, b.a, b.h), st.tier, st.shop_buff)
        if show and rnd in (6, 9, 12, 15):
            big = st.biggest()
            ins = sum(c.total() for _, _, c in st.contents())
            print(f"  R{rnd}: board {snap} (inside {ins}; +Granny {g})  target {TARGET.get(rnd)}"
                  f"  tier {st.tier}  shop +{st.shop_buff}  Oozes +{st.ooze_buff}"
                  f"  biggest {big.name} {big.a}/{big.h}"
                  f" ({100 * big.stats() // snap}%)  gold left {st.gold}")
            for s in SLOTS:
                print(f"      {s}: {st.board[s]}")
        fight_effects(st, rnd)
    return out


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "nell":
        print("carry line, r=1/2, by Nell version: R6/R9/R12/R15; target 53/194/759/2600")
        P["r"] = (1, 2)
        for label, n, buff, sides in [("half incl. Soup, both sides", (1, 2), True, 2),
                                      ("full base stats, both sides", (1, 1), False, 2),
                                      ("half incl. Soup, one side", (1, 2), True, 1),
                                      ("full incl. Soup, one side", (1, 1), True, 1),
                                      ("half incl. Soup, the biggest", (1, 2), True, 0),
                                      ("full incl. Soup, the biggest", (1, 1), True, 0),
                                      ("no Nell", (0, 1), False, 2)]:
            P["nell"], P["nell_buff"], P["nell_sides"] = n, buff, sides
            o = run(LINES["carry"])
            t = run(dict(LINES["carry"], plan=late(LINES["carry"]["plan"])))
            print(f"  {label:30s} good " + " / ".join(str(o[k][0]) for k in (6, 9, 12, 15))
                  + "   typ " + " / ".join(str(t[k][0]) for k in (6, 9, 12, 15))
                  + "   carry " + " / ".join(f"{o[k][2].a}/{o[k][2].h}" for k in (9, 12, 15)))
        return
    if len(sys.argv) > 1 and sys.argv[1] == "rolls":
        print("good roll (plan as written) vs typical roll (named cards a turn late), R6/R9/R12/R15")
        for r in [(1, 3), (1, 2)]:
            P["r"] = r
            for name, line in LINES.items():
                good = run(line)
                typ = run(dict(line, plan=late(line["plan"])))
                f = lambda o: " / ".join(f"{o[k][0]}" + (f"(+{o[k][1]})" if o[k][1] else "")
                                         for k in (6, 9, 12, 15))
                big = lambda o: " / ".join(f"{o[k][2].a}/{o[k][2].h}" for k in (9, 12, 15))
                print(f"r={r[0]}/{r[1]} {name:5s} good {f(good)}   biggest {big(good)}")
                print(f"r={r[0]}/{r[1]} {name:5s} typ  {f(typ)}   biggest {big(typ)}")
        return
    if len(sys.argv) > 1 and sys.argv[1] == "sweep":
        print("board snapshot (Granny extra in brackets) at R6 / R9 / R12 / R15")
        print("target          " + " / ".join(str(TARGET[k]) for k in (6, 9, 12, 15)))
        for r in [(1, 4), (1, 3), (1, 2)]:
            for nell in [(1, 2), (1, 1)]:
                for soup in [1, 2]:
                    P["r"], P["soup"], P["nell"] = r, soup, nell
                    cells = []
                    for name, line in LINES.items():
                        o = run(line)
                        cells.append(name + " " + " / ".join(
                            f"{o[k][0]}" + (f"(+{o[k][1]})" if o[k][1] else "") for k in (6, 9, 12, 15)))
                    print(f"r={r[0]}/{r[1]} nell={nell[0]}/{nell[1]} soup=+{soup}:  " + "   ".join(cells))
        return
    if len(sys.argv) > 1 and sys.argv[1] == "ablate":
        for name, line in LINES.items():
            base = run(line)
            names = []
            for acts in line["plan"].values():
                for act in acts:
                    fv = dict(zip(act.__code__.co_freevars, [c.cell_contents for c in (act.__closure__ or [])]))
                    if "name" in fv:
                        names.append(fv["name"])
            print(f"{name}: base " + " / ".join(str(base[k][0] + base[k][1]) for k in (9, 12, 15)))
            for n in names:
                ABLATE.clear()
                ABLATE.add(n)
                o = run(line)
                ABLATE.clear()
                print(f"   without {n:22s}" + " / ".join(
                    f"{(base[k][0] + base[k][1]) - (o[k][0] + o[k][1]):+d}" for k in (9, 12, 15)))
        return
    for name, line in LINES.items():
        print(name)
        run(line, show=True)
        print()


if __name__ == "__main__":
    main()
