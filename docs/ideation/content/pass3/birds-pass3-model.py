#!/usr/bin/env python3
"""Birds pass 3 synthesis (birds-pass3.md): growth and combat paper model.

Not Godot and not a lobby. It plays scripted lines (arrival rounds stand in for the shop),
charges gold, and then fights each line's combat-start board against target-shape field
boards. The combat code is adapted from build/orchestrator/fundamentals/bramble_combat.py
(reading order, pointer and flags, back-row protection, simultaneous exchange, Last Blow)
with the pass 3 Bird pieces added: half damage (Tom Tit), Cleave (the Lump), drop-ins
(the Gabble Ratchet), the Whistlers' halving and omen, and Jack Daw's steal.

Usage: python3 -I birds-pass3-model.py [key=value ...]
  h=2      homecoming multiplier: Fly South "comes home with double stats"
  s=0.125  Mr Redbreast: share of each homecoming Bird's stats
  k=0.1    the Cuckoo: after a Bird comes home, your other Birds in play gain k of its stats
  cuckoo=spread   (default) as above; cuckoo=keeper is the rejected Engine version, where the
                  unit standing on the Bird's Nest gains k of its stats (try it with k=0.5)
  f=0.25   Jack Daw: permanent steal of the enemy across
  egg=1    Golden Egg multiplier is x2 when egg=1; egg=0 switches Golden Eggs off
  g=6      Mrs Stork: gold spent per homecoming (her count carries over between turns)
  n=600    fights per matchup (0 skips the fights)
  lines=A,B,C,D,T,U,X   which lines to run (U is the birds_tempo harness line in birds-pass3.md)
  ablate=1 also runs the holder ablations and the omen test on line A's R12 and R15 boards
"""
import math
import random
import sys

P = {"h": 2.0, "s": 0.125, "k": 0.1, "f": 0.25, "egg": 1, "g": 6, "cuckoo": "spread", "n": 600,
     "lines": "A,B,C,D,T,U,X", "ablate": 0}
for arg in sys.argv[1:]:
    key, val = arg.split("=")
    P[key] = val if key in ("lines", "cuckoo") else float(val)
P["n"] = int(P["n"])
P["ablate"] = int(P["ablate"])


def up(x):
    return int(math.ceil(x - 1e-9))


# card: (tier, attack, health, flier)
CARDS = {
    "Swallow": (1, 1, 2, True), "Chiffchaff": (1, 1, 2, True), "Dunnock": (1, 2, 3, False),
    "Redbreast": (2, 2, 4, False), "Jay": (2, 3, 3, True), "Redwing": (2, 2, 4, False),
    "JackDaw": (3, 3, 4, False), "Tern": (3, 3, 4, True), "TomTit": (3, 3, 4, False),
    "Stork": (4, 4, 7, False), "Cuckoo": (4, 4, 7, False), "MagPye": (4, 4, 7, False),
    "Lump": (5, 5, 8, False), "Goose": (5, 6, 8, True),
    "Ratchet": (6, 6, 10, False), "Whistlers": (6, 7, 9, False),
}
TIER_COST = {2: 5, 3: 7, 4: 8, 5: 11, 6: 11}

# Target shape: today's level to R7, then about x1.5 a round (the breaker's yardstick).
TARGET = {1: 6, 2: 12, 3: 20, 4: 30, 5: 42, 6: 55, 7: 70, 8: 100, 9: 145, 10: 220,
          11: 330, 12: 490, 13: 735, 14: 1100, 15: 1650, 16: 2480}
CARRY_SHARE = 0.34  # Battlegrounds keeps about a third of the board in one unit


class Unit:
    _uid = 0

    def __init__(self, card, golden=False):
        Unit._uid += 1
        self.uid = Unit._uid
        t, a, h, fl = CARDS[card]
        m = 2 if golden else 1
        self.card, self.tier, self.flier, self.golden = card, t, fl, golden
        self.ba, self.bh = a * m, h * m
        self.a, self.h = self.ba, self.bh
        self.loc = "board"
        self.due = None
        self.flew = None
        self.missed = False
        self.ready = None
        self.egged = False

    def size(self):
        return self.a + self.h


class Game:
    def __init__(self, line):
        self.L = line
        self.t = 0
        self.gold = 0
        self.tier = 1
        self.cost = TIER_COST[2]
        self.stork_count = 0
        self.tribe = 0
        self.units = []
        self.keeper = {}  # away Bird uid -> unit standing on its Nest
        self.lump_on = None
        self.log = []
        self.homecomings = 0
        self.stats = {}

    # ---- helpers
    def home(self):
        return [u for u in self.units if u.loc == "board"]

    def hand(self):
        return [u for u in self.units if u.loc == "hand"]

    def away(self):
        return [u for u in self.units if u.loc == "away"]

    def has(self, card):
        return [u for u in self.home() if u.card == card]

    def owned(self, card):
        return [u for u in self.units if u.card == card and u.loc in ("board", "hand", "away")]

    def copies_owned(self, card):
        return sum(3 if u.golden else 1 for u in self.owned(card))

    def spend(self, n, why=""):
        assert self.gold >= n, (self.t, why, self.gold, n)
        self.gold -= n
        storks = self.has("Stork")
        if storks:
            self.stork_count += n
            while self.stork_count >= P["g"]:
                self.stork_count -= P["g"]
                per = sum(2 if s.golden else 1 for s in storks)
                for _ in range(per):
                    self.recall("Stork")

    def recall(self, why):
        elig = [b for b in self.away() if b.missed]
        if not elig:
            return False
        b = min(elig, key=lambda u: (u.flew, -u.size()))
        self.come_home(b, why)
        return True

    def come_home(self, b, why):
        b.loc = "hand"
        b.due = None
        b.missed = False
        self.homecomings += 1
        b.a += up((P["h"] - 1) * b.a)
        b.h += up((P["h"] - 1) * b.h)
        for rb in self.has("Redbreast"):
            m = 2 if rb.golden else 1
            rb.a += up(P["s"] * m * b.a)
            rb.h += up(P["s"] * m * b.h)
        cks = self.has("Cuckoo")
        kp = self.keeper.pop(b.uid, None)
        if P["cuckoo"] == "keeper":
            if cks and kp is not None and kp.loc == "board":
                m = 2 if any(c.golden for c in cks) else 1
                kp.a += up(P["k"] * m * b.a)
                kp.h += up(P["k"] * m * b.h)
        else:  # spread: after a Bird comes home, your other Birds gain k of its stats
            for c in cks:
                m = 2 if c.golden else 1
                for o in self.home():
                    if o is not b:
                        o.a += up(P["k"] * m * b.a)
                        o.h += up(P["k"] * m * b.h)
        if self.lump_on is b:
            self.lump_on = None
        self.log.append(f"home {b.card} {b.a}/{b.h} ({why})")
        self.play_hand()
        self.use_eggs()
        if b.card == "Tern":
            for o in [u for u in self.away() if u.missed]:
                self.come_home(o, "Tern")
        self.play_hand()

    def play(self, u):
        u.loc = "board"
        u.ready = self.t + 1
        self.on_play(u)

    def play_hand(self):
        for u in sorted(self.hand(), key=lambda x: (not x.flier, -x.size())):
            if len(self.home()) < 7:
                self.play(u)

    def on_play(self, u):
        m = 2 if u.golden else 1
        if u.card == "Swallow":
            self.gold += m
        elif u.card == "Chiffchaff":
            u.a += m
            u.h += m
        elif u.card == "Goose" and P["egg"]:
            for _ in range(m):
                self.golden_egg()

    def golden_egg(self):
        self.eggs_held = getattr(self, "eggs_held", 0) + 1
        self.use_eggs()

    def use_eggs(self, force=False):
        while getattr(self, "eggs_held", 0) > 0:
            home = [u for u in self.home() if not u.egged]
            allb = home + [u for u in self.away() if not u.egged]
            if not home:
                return
            best = max(allb, key=Unit.size)
            if best.loc != "board" and not force:
                return  # hold the Egg until the carry lands
            b = max(home, key=Unit.size)
            b.a *= 2
            b.h *= 2
            b.egged = True
            self.eggs_held -= 1
            self.log.append(f"Golden Egg on {b.card} -> {b.a}/{b.h}")

    def buy(self, card):
        self.spend(3, "buy " + card)
        same = [u for u in self.units if u.card == card and not u.golden and u.loc in ("board", "hand")]
        u = Unit(card)
        u.loc = "hand"
        self.units.append(u)
        if len(same) >= 2:  # triple: keep every buff, double the base (7.3.4)
            g = Unit(card, golden=True)
            parts = same[:2] + [u]
            g.a = g.ba + sum(p.a - p.ba for p in parts)
            g.h = g.bh + sum(p.h - p.bh for p in parts)
            g.egged = any(p.egged for p in parts)
            for p in parts:
                p.loc = "gone"
            g.loc = "hand"
            self.units.append(g)
            self.log.append(f"triple {card} -> golden {g.a}/{g.h}")
        self.play_hand()

    def fly(self, b):
        b.loc = "away"
        b.flew = self.t
        b.missed = False
        b.due = self.t + (1 if (b.card == "Tern" and b.golden) else 2)
        self.log.append(f"fly {b.card} {b.a}/{b.h} due R{b.due}")

    # ---- the round
    def round(self, t):
        L = self.L
        self.t = t
        self.log = []
        hc0 = self.homecomings
        if t >= 2:
            self.cost = max(0, self.cost - 1)
        self.gold += min(t + 2, 10)
        for b in sorted([u for u in self.away() if u.due == t], key=lambda u: u.flew):
            if b.loc == "away":
                self.come_home(b, "trip")
        self.play_hand()
        self.fly_phase()
        self.play_hand()
        nxt = self.tier + 1
        if nxt <= 6 and t >= L["climb"].get(nxt, 99) and self.gold >= self.cost:
            self.spend(self.cost, "tier")
            self.tier = nxt
            self.cost = TIER_COST.get(nxt + 1, 99)
        bought = True
        while bought:
            bought = False
            for card in L["prio"]:
                if self.gold < 3 + self.reserve():
                    break
                if L["arrive"].get(card, 99) > t or CARDS[card][0] > self.tier:
                    continue
                if self.copies_owned(card) >= L["copies"].get(card, 1):
                    continue
                if not CARDS[card][3]:
                    ok = True
                    while len([u for u in self.home() + self.hand() if not u.flier]) >= self.max_stay():
                        worst = self.worst_stayer(card)
                        if worst is None:
                            ok = False
                            break
                        worst.loc = "gone"
                        self.gold += 1
                    if not ok:
                        continue
                self.buy(card)
                bought = True
                break
        if self.tier >= 3 and t in L.get("supper", ()) and self.tribe < 3 and self.gold >= 3 + self.reserve():
            self.spend(3, "supper")
            self.tribe += 1
        spare = self.gold - self.reserve()
        if spare > 0 and self.has("Stork"):
            self.spend(spare, "refresh")
        self.play_hand()
        if getattr(self, "eggs_held", 0) and not any(u.due == t + 1 for u in self.away() if not u.egged):
            self.use_eggs(force=True)
        for d in self.has("Dunnock"):
            n = 2 if d.golden else 1
            cands = sorted([b for b in self.away() if b.due and b.due >= t + 2], key=Unit.size, reverse=True)
            for b in cands[:n]:
                b.due -= 1
        self.place_standers()
        snap = self.snapshot()
        for jd in self.has("JackDaw"):
            m = 2 if jd.golden else 1
            M = TARGET[t]
            pc = L.get("jd_carry", 0.5)
            across = pc * CARRY_SHARE * M + (1 - pc) * (1 - CARRY_SHARE) / 6 * M
            big = max(self.home(), key=Unit.size)
            g = int(P["f"] * m * across / 2)
            big.a += g
            big.h += g
        for b in self.away():
            b.missed = True
        self.stats[t] = dict(snap=snap, gold=self.gold, tier=self.tier, tribe=self.tribe,
                             away=[(b.card, b.a, b.h) for b in self.away()],
                             hand=[(b.card, b.a, b.h) for b in self.hand()],
                             homecomings=self.homecomings - hc0, log=self.log)

    def reserve(self):
        L = self.L
        nxt = self.tier + 1
        if nxt <= 6 and L["climb"].get(nxt, 99) == self.t + 1:
            return max(0, self.cost - 1 - min(self.t + 3, 10))
        return 0

    def max_stay(self):
        plan = self.L.get("stay_plan", {1: 7, 7: 5, 10: 4})
        return plan[max(k for k in plan if k <= self.t)]

    def worst_stayer(self, incoming):
        """Swap out the lowest-ranked stayer if the incoming stayer ranks higher on the line's keep list."""
        rank = self.L["keep"]
        if incoming not in rank:
            return None
        stay = [u for u in self.home() if not u.flier]
        cands = [u for u in stay if u.card not in rank or rank.index(u.card) > rank.index(incoming)]
        if not cands:
            return None
        return max(cands, key=lambda u: (rank.index(u.card) if u.card in rank else 99, -u.size()))

    def fly_phase(self):
        L = self.L
        t = self.t
        if L.get("switch") and t >= L["switch"]:
            L = dict(L, never_fly=(), fly_cap=None, keep_home=3)
        if t < L["fly_from"]:
            return
        fliers = [u for u in self.home() if u.flier and u.ready is not None and u.ready <= t]
        fliers.sort(key=lambda u: (u.card != "Goose", -u.size()))
        for b in fliers:
            if b.card in L.get("never_fly", ()):
                continue
            if self.has("Stork") and L.get("stork_top"):
                allf = sorted([u for u in self.units if u.flier and u.loc in ("board", "away", "hand")], key=Unit.size, reverse=True)
                if b not in allf[:L["stork_top"]]:
                    continue
            if L.get("carry_home") and t >= L["carry_home"] and not self.has("Lump"):
                birds = self.home() + self.away()
                if b is max(birds, key=Unit.size):
                    continue
            if b.card == "Tern" and len(self.away()) < L.get("tern_min", 2):
                continue
            others = [u for u in self.home() if u is not b]
            if len(others) < L["keep_home"]:
                continue
            if L.get("fly_cap") is not None and len(self.away()) >= L["fly_cap"]:
                continue
            self.fly(b)

    def place_standers(self):
        """Lump on the biggest away Bird's Nest. With the Cuckoo, other home units keep Nests."""
        self.keeper = {}
        self.lump_on = None
        aw = sorted(self.away(), key=Unit.size, reverse=True)
        lumps = self.has("Lump")
        nests = list(aw)
        if lumps and nests:
            self.lump_on = nests[0]
            self.keeper[nests[0].uid] = lumps[0]
            nests = nests[1:]
        if self.has("Cuckoo") and P["cuckoo"] == "keeper":
            standers = [u for u in self.home() if u.card != "Lump"]
            standers.sort(key=lambda u: (u.card != "Redbreast", u.flier, -u.size()))
            for b, kp in zip(nests, standers):
                self.keeper[b.uid] = kp

    def snapshot(self):
        """Combat-start board, after auras, before Start of Combat effects."""
        tb = self.tribe
        units = []
        for u in self.home():
            a, h = u.a + tb, u.h + tb
            tags = {"card": u.card, "bird": True, "golden": u.golden}
            if u.card == "Lump":
                tags["cleave"] = True
                if self.lump_on is not None:
                    m = 2 if u.golden else 1
                    a += m * (self.lump_on.a + tb)
                    h += m * (self.lump_on.h + tb)
                    tags["nest"] = (self.lump_on.a + tb, self.lump_on.h + tb)
            else:
                for b_uid, kp in self.keeper.items():
                    if kp is u:
                        bb = next(x for x in self.units if x.uid == b_uid)
                        tags["nest"] = (bb.a + tb, bb.h + tb)
            units.append([a, h, tags])
        kept = set(self.keeper)
        free = 7 - len(units)
        eggs = sorted([b for b in self.away() if b.uid not in kept], key=Unit.size, reverse=True)[:max(0, free)]
        rw = self.has("Redwing")
        rw_n = sum(4 if r.golden else 2 for r in rw)
        for i, b in enumerate(eggs):
            ba, bh = b.a + tb, b.h + tb
            if i < rw_n:
                ea, eh = up(ba / 2), up(bh / 2)
            else:
                ea, eh = 0, 1
            units.append([ea, eh, {"card": "Egg", "egg": True, "nest": (ba, bh)}])
        return units


# ---------------------------------------------------------------- combat
FRONT = (0, 1, 2, 3)
ADJ = ((1,), (0, 2), (1, 3), (2,), (5,), (4, 6), (5,))
SLOTN = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]


class CU:
    __slots__ = ("a", "h", "slot", "flag", "start", "kw", "half", "shield", "dropped")

    def __init__(self, a, h, slot, kw):
        self.a, self.h, self.slot, self.kw = a, h, slot, kw
        self.flag = False
        self.start = True
        self.half = False
        self.shield = bool(kw.get("shield"))
        self.dropped = False


def field_board(kind, t, rng):
    M = TARGET[t]
    if kind == "even":
        each = M / 7
        specs = [(up(each / 2), up(each / 2), {})] * 7
        return {i: s for i, s in enumerate(specs)}
    mult = 1.4 if kind.startswith("strong") else 1.0
    M *= mult
    c = CARRY_SHARE * M
    o = (1 - CARRY_SHARE) * M / 6
    carry_slot = 5 if rng.random() < 0.5 else 1
    kw = {"shield": True} if kind.endswith("shield") else {}
    b = {}
    others = [s for s in range(7) if s != carry_slot]
    b[carry_slot] = (up(c / 2), up(c / 2), dict(kw, carry=True))
    for s in others:
        b[s] = (up(o / 2), up(o / 2), {})
    return b


def place_birds(units, enemy):
    """Hand placement against the scouted board (the line policy's placement rule)."""
    board = {}
    ens = sorted(enemy.items(), key=lambda kv: kv[1][0] + kv[1][1], reverse=True)
    e_big = ens[0][0]
    e_second = ens[1][0] if len(ens) > 1 else ens[0][0]
    rest = list(units)

    def take(card):
        for u in rest:
            if u[2]["card"] == card:
                rest.remove(u)
                return u
        return None

    w = take("Whistlers")
    if w:
        board[e_big] = w
    jd = take("JackDaw")
    if jd:
        board[e_second if e_big in board else e_big] = jd
    birds = [u for u in rest if not u[2].get("egg")]
    carry = max(birds, key=lambda u: u[0] + u[1]) if birds else None
    order_back = []
    if carry:
        rest.remove(carry)
        order_back.append(carry)
    for card in ("TomTit", "Ratchet", "Redbreast", "Stork"):
        u = take(card)
        if u:
            order_back.append(u)
    back_free = [s for s in (5, 4, 6) if s not in board]
    front_free = [s for s in FRONT if s not in board]
    eggs = [u for u in rest if u[2].get("egg")]
    others = [u for u in rest if not u[2].get("egg")]
    for u in order_back:
        if back_free:
            board[back_free.pop(0)] = u
        else:
            others.insert(0, u)
    for u in eggs + others:
        if front_free:
            board[front_free.pop(0)] = u
        elif back_free:
            board[back_free.pop(0)] = u
    return board


def fight(my_units, enemy, rng):
    mine = place_birds(my_units, enemy)
    sides = [{s: CU(u[0], u[1], s, dict(u[2])) for s, u in mine.items()},
             {s: CU(e[0], e[1], s, dict(e[2])) for s, e in enemy.items()}]
    n0, n1 = len(sides[0]), len(sides[1])
    first = 0 if n0 > n1 else 1 if n1 > n0 else rng.randint(0, 1)
    # Start of Combat (side 0 only: the field is plain)
    me, en = sides[0], sides[1]
    birds = [u for u in me.values() if u.kw.get("bird")]
    distinct = {u.kw["card"] for u in birds}
    omen = len(birds) == 7 and len(distinct) == 7
    for s, u in sorted(me.items()):
        if u.kw.get("card") == "Whistlers":
            reps = 2 if u.kw.get("golden") else 1
            targets = list(en.values()) if omen else ([en[s]] if s in en else [])
            for v in targets:
                for _ in range(reps):
                    v.a, v.h = up(v.a / 2), up(v.h / 2)
            omen = False  # one Whistlers' omen per fight
        if u.kw.get("card") == "JackDaw" and s in en:
            v = en[s]
            m = 2 if u.kw.get("golden") else 1
            fa, fh = int(P["f"] * m * v.a), int(P["f"] * m * v.h)
            v.a -= fa
            v.h -= fh
            if birds:
                big = max(birds, key=lambda x: x.a + x.h)
                big.a += fa
                big.h += fh
    tomtits = [u for u in me.values() if u.kw.get("card") == "TomTit"]
    if tomtits and birds:
        n = 2 if any(t.kw.get("golden") for t in tomtits) else 1
        for u in sorted([b for b in birds if b.kw.get("card") != "TomTit"], key=lambda x: x.a + x.h, reverse=True)[:n]:
            u.half = True
    pointer = [-1, -1]
    attacks = 0
    last_blow = -1
    active = first

    def choose_attacker(s):
        units = [sides[s][k] for k in sorted(sides[s])]
        ready = [u for u in units if u.a > 0]
        if not ready:
            return None
        att = next((u for u in ready if not u.flag), None)
        if att is None:
            for u in units:
                u.flag = False
            att = ready[0]
        pointer[s] = att.slot
        for u in units:
            if u.slot <= att.slot:
                u.flag = True
        return att

    def choose_target(s):
        enemy_side = sides[1 - s]
        front = [enemy_side[k] for k in sorted(enemy_side) if k in FRONT]
        cands = front if front else [enemy_side[k] for k in sorted(enemy_side)]
        return cands[rng.randrange(len(cands))] if cands else None

    def tomtit_alive():
        return any(u.kw.get("card") == "TomTit" for u in sides[0].values())

    def hit(target, amount):
        if amount <= 0:
            return
        if target.half and tomtit_alive():
            amount = up(amount / 2)
        if target.shield:
            target.shield = False
            return
        target.h -= amount

    def resolve_deaths(s_active):
        for s in (s_active, 1 - s_active):
            dead = [u for u in list(sides[s].values()) if u.h <= 0]
            for u in dead:
                del sides[s][u.slot]
            ratchets = [u for u in sides[s].values() if u.kw.get("card") == "Ratchet"]
            for u in dead:
                if s == 0 and ratchets and u.kw.get("nest") and not u.kw.get("dropped"):
                    m = 2 if any(r.kw.get("golden") for r in ratchets) else 1
                    na, nh = u.kw["nest"]
                    d = CU(na * m, nh * m, u.slot, {"card": "Dropin", "bird": True, "dropped": True})
                    d.start = False
                    d.flag = u.slot < pointer[s]
                    sides[s][u.slot] = d

    def one_attack(s, att):
        nonlocal last_blow
        d = choose_target(s)
        if d is None:
            return
        out_amt, back_amt = att.a, d.a
        hit(d, out_amt)
        if att.kw.get("cleave"):
            for k in ADJ[d.slot]:
                v = sides[1 - s].get(k)
                if v is not None:
                    hit(v, out_amt)
        hit(att, back_amt)
        last_blow = s
        resolve_deaths(s)

    while True:
        if not sides[0] or not sides[1]:
            break
        if not any(u.a > 0 for u in sides[0].values()) and not any(u.a > 0 for u in sides[1].values()):
            return -1
        if attacks >= 200:
            return -1
        att = choose_attacker(active)
        if att is not None:
            attacks += 1
            one_attack(active, att)
        active = 1 - active
    if sides[0] and not sides[1]:
        return 0
    if sides[1] and not sides[0]:
        return 1
    return last_blow


def win_rate(units, kind, t, n, seed=7):
    rng = random.Random(seed)
    w = tie = 0
    for _ in range(n):
        r = fight(units, field_board(kind, t, rng), rng)
        if r == 0:
            w += 1
        elif r == -1:
            tie += 1
    return w / n, tie / n


# ---------------------------------------------------------------- lines
BASE_PRIO = ["Redbreast", "Chiffchaff", "Jay", "Swallow", "Dunnock", "TomTit", "Stork", "JackDaw", "Tern",
             "Goose", "Cuckoo", "Lump", "Ratchet", "Whistlers", "Redwing", "MagPye"]
KEEP = ["Stork", "Redbreast", "Lump", "Ratchet", "TomTit", "Whistlers", "Cuckoo", "JackDaw", "Dunnock", "Redwing", "MagPye"]
SELL = KEEP
LINES = {
    "A": dict(name="birds_homecoming, typical roll", prio=BASE_PRIO, keep=KEEP,
              arrive={"Chiffchaff": 1, "Swallow": 2, "Jay": 3, "Redbreast": 3, "Dunnock": 4, "TomTit": 5,
                      "JackDaw": 6, "Tern": 6, "Stork": 7, "Cuckoo": 9, "Goose": 10, "Lump": 11, "Ratchet": 12,
                      "Whistlers": 13},
              copies={"Jay": 2}, climb={2: 3, 3: 5, 4: 7, 5: 10, 6: 12}, supper=(6, 8, 10),
              fly_from=3, keep_home=3, jd_carry=0.5),
    "B": dict(name="birds_homecoming, strong roll (the typical line with Stork R6, Goose R9, Lump R10)",
              prio=BASE_PRIO, keep=KEEP,
              arrive={"Chiffchaff": 1, "Swallow": 2, "Jay": 3, "Redbreast": 3, "Dunnock": 4, "TomTit": 5,
                      "JackDaw": 6, "Tern": 5, "Stork": 6, "Cuckoo": 8, "Goose": 9, "Lump": 10, "Ratchet": 12,
                      "Whistlers": 12},
              copies={"Jay": 2, "Chiffchaff": 2}, climb={2: 3, 3: 5, 4: 6, 5: 9, 6: 12},
              supper=(6, 8, 10), fly_from=3, keep_home=3, jd_carry=1.0),
    "C": dict(name="birds_homecoming, low roll (no Stork until R12, no Goose, no Cuckoo)", prio=BASE_PRIO, keep=KEEP,
              arrive={"Chiffchaff": 1, "Swallow": 2, "Jay": 3, "Redbreast": 4, "Dunnock": 4, "TomTit": 6,
                      "JackDaw": 7, "Tern": 8, "Stork": 12, "Lump": 12, "Ratchet": 14, "Whistlers": 15,
                      "Redwing": 5},
              copies={}, climb={2: 3, 3: 5, 4: 8, 5: 11, 6: 14}, supper=(7, 9, 11),
              fly_from=3, keep_home=3, jd_carry=0.3),
    "D": dict(name="birds_homecoming, flock knob (Redwing, the Cuckoo, Ratchet, two Chiffchaffs)",
              prio=["Redbreast", "Jay", "Chiffchaff", "Redwing", "Swallow", "Tern", "TomTit", "Cuckoo", "Stork",
                    "Ratchet", "Goose", "Whistlers", "Dunnock", "JackDaw", "Lump", "MagPye"],
              keep=["Stork", "Redbreast", "Cuckoo", "Ratchet", "Redwing", "TomTit", "Whistlers", "Lump", "JackDaw", "Dunnock", "MagPye"],
              arrive={"Chiffchaff": 1, "Swallow": 2, "Redwing": 3, "Jay": 3, "Redbreast": 4, "Tern": 5,
                      "TomTit": 6, "Cuckoo": 7, "Stork": 9, "Goose": 11, "Ratchet": 12, "Whistlers": 13},
              copies={"Jay": 2, "Chiffchaff": 2}, climb={2: 3, 3: 5, 4: 7, 5: 10, 6: 12}, supper=(6, 8, 10),
              fly_from=3, keep_home=3, jd_carry=0.5),
    "T": dict(name="birds_tempo, typical roll (fly only Swallow and Chiffchaff to R8, then the engine)",
              prio=["Jay", "Redbreast", "Dunnock", "Chiffchaff", "Swallow", "TomTit", "JackDaw", "Stork", "MagPye",
                    "Goose", "Lump", "Tern", "Cuckoo", "Whistlers", "Ratchet", "Redwing"],
              keep=["Redbreast", "Stork", "Lump", "TomTit", "JackDaw", "Whistlers", "Ratchet", "MagPye", "Dunnock",
                    "Cuckoo", "Redwing"],
              arrive={"Chiffchaff": 1, "Dunnock": 1, "Jay": 2, "Redbreast": 2, "Swallow": 2, "TomTit": 4,
                      "JackDaw": 4, "MagPye": 6, "Stork": 6, "Cuckoo": 7, "Lump": 8, "Goose": 8, "Tern": 8,
                      "Ratchet": 10, "Whistlers": 10, "Redwing": 3},
              copies={"Jay": 2}, climb={2: 2, 3: 4, 4: 6, 5: 8, 6: 10}, supper=(4, 6, 8),
              stay_plan={1: 7, 9: 5, 11: 4}, fly_from=4, keep_home=5, fly_cap=2, never_fly=("Jay",),
              switch=9, jd_carry=0.5),
    "U": dict(name="birds_tempo harness line (hold four home, small fliers only, fold into the engine at R7)",
              prio=["Jay", "Redbreast", "Dunnock", "Chiffchaff", "Swallow", "TomTit", "JackDaw", "Stork", "MagPye",
                    "Goose", "Lump", "Tern", "Cuckoo", "Whistlers", "Ratchet", "Redwing"],
              keep=["Redbreast", "Stork", "Lump", "TomTit", "JackDaw", "Whistlers", "Ratchet", "MagPye", "Dunnock",
                    "Cuckoo", "Redwing"],
              arrive={"Chiffchaff": 1, "Dunnock": 1, "Jay": 2, "Redbreast": 2, "Swallow": 2, "TomTit": 4,
                      "JackDaw": 4, "MagPye": 6, "Stork": 6, "Cuckoo": 7, "Lump": 8, "Goose": 8, "Tern": 8,
                      "Ratchet": 10, "Whistlers": 10, "Redwing": 3},
              copies={"Jay": 2}, climb={2: 3, 3: 5, 4: 7, 5: 10, 6: 12}, supper=(4, 6, 8),
              stay_plan={1: 7, 7: 5, 10: 4}, fly_from=4, keep_home=4, fly_cap=3, never_fly=("Jay",),
              switch=7, jd_carry=0.5),
    "X": dict(name="breaker probe: every engine piece early, two Geese, golden Jay, golden Stork",
              prio=["Jay", "Stork"] + [c for c in BASE_PRIO if c not in ("Jay", "Stork")], keep=KEEP,
              arrive={"Chiffchaff": 1, "Jay": 2, "Swallow": 2, "Redbreast": 2, "Dunnock": 2, "TomTit": 4,
                      "Tern": 4, "JackDaw": 4, "Stork": 6, "Cuckoo": 6, "Goose": 8, "Lump": 9, "Ratchet": 11,
                      "Whistlers": 11},
              copies={"Jay": 3, "Goose": 2, "Stork": 3}, climb={2: 2, 3: 4, 4: 6, 5: 8, 6: 11}, supper=(4, 6, 8),
              fly_from=2, keep_home=2, jd_carry=1.0),
}


def run(key):
    L = LINES[key]
    Unit._uid = 0
    g = Game(L)
    out = {}
    for t in range(1, 17):
        g.round(t)
        snap = g.stats[t]["snap"]
        tot = sum(u[0] + u[1] for u in snap)
        big = max(snap, key=lambda u: u[0] + u[1])
        sky = sum(a + h for _, a, h in g.stats[t]["away"])
        out[t] = (tot, big, sky, snap)
    return g, out


def main():
    rounds_show = (6, 9, 12, 15)
    print(f"params: h={P['h']} s={P['s']} k={P['k']} f={P['f']} egg={P['egg']} n={P['n']}")
    print("target median:", {t: TARGET[t] for t in (6, 9, 12, 15)})
    for key in P["lines"].split(","):
        g, out = run(key)
        print(f"\n=== Line {key}: {LINES[key]['name']}")
        row = []
        for t in range(5, 17):
            tot = out[t][0]
            row.append(f"R{t} {tot} ({tot / TARGET[t]:.2f}x)")
        print("  board:", "; ".join(row))
        hc = [g.stats[t]["homecomings"] for t in range(1, 17)]
        print("  homecomings a turn R1-16:", hc)
        for t in rounds_show:
            tot, big, sky, snap = out[t]
            st = g.stats[t]
            cards = ", ".join(f"{u[2]['card']}{'*' if u[2].get('golden') else ''} {u[0]}/{u[1]}" for u in sorted(snap, key=lambda u: -(u[0] + u[1])))
            print(f"  R{t}: board {tot} vs target {TARGET[t]} ({tot / TARGET[t]:.2f}x); biggest {big[2]['card']} "
                  f"{big[0]}/{big[1]} = {100 * (big[0] + big[1]) / max(1, tot):.0f}%; sky {sky}; tier {st['tier']}; gold left {st['gold']}")
            print(f"       {cards}")
            if st["away"]:
                print("       away:", ", ".join(f"{c} {a}/{h}" for c, a, h in st["away"]))
            if st["hand"]:
                print("       hand:", ", ".join(f"{c} {a}/{h}" for c, a, h in st["hand"]))
            if P["n"]:
                res = []
                for kind in ("median", "median_shield", "even", "strong"):
                    w, tie = win_rate(snap, kind, t, P["n"])
                    res.append(f"{kind} {100 * w:.0f}%")
                print("       wins vs field:", "; ".join(res))


def ablate():
    """Holder ablations and the omen test on line A's R12 and R15 boards."""
    import copy
    g, out = run("A")
    n = max(P["n"], 200)

    def wr(snap, t):
        return " / ".join(f"{100 * win_rate(snap, k, t, n)[0]:.0f}%" for k in ("median", "median_shield", "even", "strong"))

    print("\n=== Ablations on line A (median / median_shield / even / strong)")
    for t in (12, 15):
        snap = out[t][3]
        print(f"  R{t} board {sum(u[0] + u[1] for u in snap)}: as is {wr(snap, t)}")
        for card in ("TomTit", "Ratchet", "JackDaw"):
            if any(u[2]["card"] == card for u in snap):
                s2 = [u for u in snap if u[2]["card"] != card] + [[0, 1, {"card": "Egg", "egg": True, "nest": (0, 1)}]]
                print(f"    without {card} (a 0/1 Egg in its place): {wr(s2, t)}")
        s3 = copy.deepcopy(snap)
        for u in s3:
            if u[2]["card"] == "Lump" and "nest" in u[2]:
                na, nh = u[2]["nest"]
                u[0] -= na
                u[1] -= nh
        print(f"    the Lump without its Nest's stats: {wr(s3, t)}")
        s4 = copy.deepcopy(snap)
        swap = "Tern" if t == 12 else "Stork"
        for u in s4:
            if u[2]["card"] == swap:
                u[0], u[1], u[2] = 7 + 3, 9 + 3, {"card": "Whistlers", "bird": True}
                break
        names = [u[2]["card"] for u in s4]
        omen = len(set(names)) == 7 and not any(u[2].get("egg") for u in s4)
        print(f"    {swap} swapped for the Whistlers ({len(set(names))} different Birds, omen {omen}): {wr(s4, t)}")


if __name__ == "__main__":
    main()
    if P["ablate"]:
        ablate()
