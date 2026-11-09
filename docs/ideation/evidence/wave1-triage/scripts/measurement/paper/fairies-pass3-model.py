"""Fairies pass 3 synthesis: paper model of Rings x Ring size, with a gold ledger.

Design: fairies-pass3.md in this folder. Not a game sim: no shops, fights or opponents.
Each line is a hand-written list of actions per round (buy, sell, spells, moves, tier-ups),
checked against income and tier-up costs (rulebook 4.1, 4.6). End of Turn effects run from
the cards on the board. It reports board stats (Attack + Health over every unit):
  recruit: what the board shows while recruiting (Rings included; Shy units get none);
  combat:  combat-start: adds Cradle Fetch's copy and Wisps on empty Rings.
Shield, Nightshade, the curse, the Changeling and Reel-Mistress's dance have no Start of
Combat stats and are not counted. Fights are not played: a board's ratio to the target row
(BG September 2025 mean, T below) is shape, not win rate.

Rules modelled (fairies-pass3.md):
  A slot gives (Rings on it) x S to both stats. S, the Ring size, starts at 1.
  Nan Toadstool: when played or sold, Ring this slot (golden twice).
  Old Moth Annis: End of Turn and after you sell a unit: Ring the slots behind this
    (golden twice). 'churn' buys and sells cheap units for this: 2 gold net a sale.
  Sally Spore: End of Turn, Ring your empty slot nearest this (golden twice).
  Cluricaun: every (1/g)-th End of Turn (default every 3rd), if every slot has a Ring,
    S += 1. The model counts only turns with the rainbow complete, a slight undercount.
    Copies share one count (guards=1); golden +2.
  Lob: when it leaves (thanked), S += floor(turns stayed / lob). Golden x2.
  Silky: after a Shy unit leaves (Silky too), S += 1. Copies don't add up; golden +2.
  Fairy Monarch: every p-th End of Turn from play, S x2 (monring=1 adds "When played: Ring
    every slot"). One clock however many Monarchs (guards=1); golden x3.
  Queen of Elfland: End of Turn (every qp-th, default every one), destroy the units behind;
    Ring every slot qk times for each unit destroyed (default once). Golden x2.
  Spells: spore (2 gold, Ring a slot twice), stone (2 gold, three times), pinch (1 gold;
    thanks a Shy unit: it leaves, 2 gold next turn), supper (3 gold, Fairies +1/+1, max 3).
Shop supply (supply=N): the plans are written as if every card and spell shows up. With
  supply=N, Ring spells (Spore Cloud, Boundary Stone) are limited to one a turn through tier 4
  and one every N turns from tier 5, and Nan cycles stop after tier 4. Rule 6.1.3a's odds give
  a Stone about 17% a refill at tier 4, 8% at tier 5 and 5% at tier 6; a given tier 1 unit is
  about 1% a refill at tier 6. Dropped actions leave their gold unspent, and 'churn' then
  spends it. supply=0 runs the plans as written.
Usage: python3 -I fairies-pass3-model.py [g=0.3333] [lob=3] [p=3] [qk=1] [qp=1] [supply=2] [churn=9] [monring=0] [fetch=1] [guards=1] [line=ring|court] [debug=1]
"""
import sys, math

P = {"g": 1 / 3, "lob": 3, "p": 3, "guards": 1, "line": "all", "fetch": 1.0, "debug": 0, "qk": 1, "qp": 1, "monring": 0,
     "supply": 2}
for a in sys.argv[1:]:
    k, v = a.split("=")
    P[k] = v if k == "line" else float(v)

T = {4: 24, 6: 53, 7: 79, 8: 123, 9: 194, 10: 305, 11: 482, 12: 759, 13: 1177, 14: 1751, 15: 2600, 16: 3900}
SLOTS = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
BEHIND = {"F1": ["B1"], "F2": ["B1", "B2"], "F3": ["B2", "B3"], "F4": ["B3"]}
NEAREST = {"F1": "F2 F3 F4 B1 B2 B3", "F2": "F3 F1 F4 B2 B1 B3", "F3": "F4 F2 F1 B3 B2 B1",
           "F4": "F3 F2 F1 B3 B2 B1", "B1": "B2 B3 F2 F1 F3 F4", "B2": "B3 B1 F3 F2 F4 F1",
           "B3": "B2 B1 F4 F3 F2 F1"}
INCOME = {1: 3, 2: 4, 3: 5, 4: 6, 5: 7, 6: 8, 7: 9}
TIER_BASE = {2: 5, 3: 7, 4: 8, 5: 11, 6: 11}
U = {  # attack, health, fairy, shy, tier
    "nan": (2, 1, 1, 0, 1), "chaser": (2, 2, 1, 0, 1), "witch": (1, 3, 1, 0, 1),
    "annis": (2, 4, 1, 0, 2), "sally": (2, 4, 1, 0, 2), "hob": (2, 5, 1, 1, 2),
    "clur": (3, 5, 1, 0, 3), "lob": (3, 6, 1, 1, 3), "silky": (3, 7, 1, 1, 3),
    "changeling": (3, 3, 1, 0, 4), "will": (3, 6, 1, 0, 4), "fetch": (2, 4, 1, 0, 4),
    "reel": (4, 7, 1, 0, 5), "bella": (4, 8, 1, 0, 5), "monarch": (6, 8, 1, 0, 6), "queen": (8, 8, 1, 0, 6),
    "n2": (3, 4, 0, 0, 2), "n3": (4, 4, 0, 0, 3), "n4": (5, 5, 0, 0, 4), "n5": (6, 7, 0, 0, 5), "n6": (7, 8, 0, 0, 6),
}


class Unit:
    def __init__(self, name, golden=False, r=0):
        a, h, f, shy, tier = U[name]
        k = 2 if golden else 1
        self.name, self.golden, self.a, self.h = name, golden, a * k, h * k
        self.fairy, self.shy, self.perm, self.since = f, shy, 0.0, r

    def __repr__(self):
        return self.name + ("*" if self.golden else "")


class Game:
    def __init__(self, p):
        self.p = p
        self.gold = 0; self.pending = 0; self.tier = 1; self.cost = TIER_BASE[2]
        self.b = {}; self.ring = {s: 0 for s in SLOTS}; self.S = 1
        self.clur_tick = 0; self.mon_from = None; self.mon_gold = False
        self.queen_from = None; self.supper = 0; self.log = []; self.round = 0
        self.extra_clocks = []; self.churns = 0

    # ---- helpers
    def pay(self, n, what):
        self.gold -= n
        if self.gold < 0:
            raise SystemExit("R%d: not enough gold for %s (short %d)" % (self.round, what, -self.gold))

    def place(self, u, s):
        if s in self.b:
            raise SystemExit("R%d: slot %s is taken by %s" % (self.round, s, self.b[s]))
        self.b[s] = u

    def leave(self, s):
        """A Shy unit leaves (thanked)."""
        u = self.b.pop(s)
        self.pending += 4 if u.golden else 2
        if u.name == "lob":
            turns = self.round - u.since
            self.S += (2 if u.golden else 1) * math.floor(turns / self.p["lob"])
        silkies = [x for x in list(self.b.values()) + [u] if x.name == "silky"]
        if silkies:
            n = 1 if self.p["guards"] else len(silkies)
            self.S += n * (2 if any(x.golden for x in silkies) else 1)

    def annis(self, n=1):
        """After you sell a unit: each Annis Rings the slots behind it."""
        for s, u in self.b.items():
            if u.name == "annis":
                for x in BEHIND.get(s, []):
                    self.ring[x] += n * (2 if u.golden else 1)

    # ---- actions
    def act(self, a):
        op = a[0]
        if op == "tier":
            self.pay(self.cost, "tier"); self.tier += 1
            self.cost = TIER_BASE.get(self.tier + 1, 99)
        elif op == "buy":
            name, s = a[1], a[2]; golden = len(a) > 3 and a[3]
            if not golden:
                self.pay(3, name)
            if U[name][4] > self.tier:
                raise SystemExit("R%d: %s is tier %d, shop is %d" % (self.round, name, U[name][4], self.tier))
            u = Unit(name, golden, self.round); self.place(u, s)
            if name == "nan":
                self.ring[s] += 2 if golden else 1
            if name == "monarch" and self.p["monring"]:   # variant: "When played: Ring every slot."
                for x in SLOTS:
                    self.ring[x] += 2 if golden else 1
            if name == "monarch":
                if self.mon_from is None:
                    self.mon_from = self.round
                elif not self.p["guards"]:
                    self.extra_clocks.append(self.round)
                self.mon_gold = self.mon_gold or golden
        elif op == "sell":
            s = a[1]; u = self.b.pop(s)
            if u.name == "chaser":
                self.gold += sum(1 for x in SLOTS if self.ring[x] > 0) * (2 if u.golden else 1)
            else:
                self.gold += 1
            if u.name == "nan":
                self.ring[s] += 2 if u.golden else 1
            self.annis()
        elif op == "churn":   # buy a cheap unit, play it in the flex slot, sell it; keep a[1] gold
            keep = a[1] if len(a) > 1 else 0
            n = max(0, (self.gold - keep) // 2)
            self.pay(2 * n, "churn"); self.annis(n); self.churns += n
        elif op == "move":
            self.b[a[2]] = self.b.pop(a[1])
        elif op == "swap":
            x, y = self.b.get(a[1]), self.b.get(a[2])
            self.b.pop(a[1], None); self.b.pop(a[2], None)
            if x: self.b[a[2]] = x
            if y: self.b[a[1]] = y
        elif op == "nan":   # buy a Nan, play it into an empty slot, sell it from another slot
            play, sell = a[1], a[2]
            self.act(("buy", "nan", play))
            if sell != play:
                self.act(("swap", play, sell))     # Nan to the sell slot, its unit to the play slot
            self.act(("sell", sell))
            if sell != play and play in self.b:
                self.act(("move", play, sell))     # the unit goes back
        elif op == "nancycle":   # a Nan bought, played and sold: one Ring on each of two slots, 2 gold net
            self.pay(2, "nan cycle")
            for x in a[1:]:
                self.ring[x] += 1
            self.annis()
        elif op == "spell":
            kind, s = a[1], a[2] if len(a) > 2 else None
            if kind == "spore":
                self.pay(2, "spore"); self.ring[s] += 2
            elif kind == "stone":
                self.pay(2, "stone"); self.ring[s] += 3
            elif kind == "pinch":
                self.pay(1, "pinch"); self.leave(s)
            elif kind == "supper":
                self.pay(3, "supper"); self.supper = min(3, self.supper + 1)
        else:
            raise SystemExit("unknown action %r" % (a,))

    def end_of_turn(self, tithe=False):
        for s in SLOTS:
            u = self.b.get(s)
            if not u: continue
            k = 2 if u.golden else 1
            if u.name == "annis":
                for x in BEHIND.get(s, []):
                    self.ring[x] += k
            if u.name == "sally":
                for x in NEAREST[s].split():
                    if x not in self.b:
                        self.ring[x] += k; break
        clurs = [u for u in self.b.values() if u.name == "clur"]
        if clurs and all(self.ring[x] > 0 for x in SLOTS):
            self.clur_tick += 1
            every = round(1 / self.p["g"])
            if self.clur_tick % every == 0:
                n = 1 if self.p["guards"] else len(clurs)
                self.S += n * (2 if any(c.golden for c in clurs) else 1)
        per = int(self.p["p"])
        clocks = ([self.mon_from] if self.mon_from is not None else []) + self.extra_clocks
        for c in clocks:
            if (self.round - c) % per == per - 1:
                self.S *= 3 if self.mon_gold else 2
        if self.queen_from is None:
            q = [s for s, u in self.b.items() if u.name == "queen"]
            if q: self.queen_from = self.round
        if self.queen_from is not None and (self.round - self.queen_from) % int(self.p["qp"]) == int(self.p["qp"]) - 1:
            q = [s for s, u in self.b.items() if u.name == "queen"]
            if q:
                behind = [x for x in BEHIND.get(q[0], []) if x in self.b]
                k = int(self.p["qk"]) * (2 if self.b[q[0]].golden else 1)
                for x in behind:
                    self.b.pop(x)
                for x in SLOTS:
                    self.ring[x] += k * len(behind)
                self.log.append("R%d Teind: %d destroyed, every slot +%d Rings" % (self.round, len(behind), k * len(behind)))

    def stats(self, s):
        u = self.b[s]
        sup = self.supper if u.fairy else 0
        ring = 0 if u.shy else self.ring[s] * self.S
        return u.a + u.h + 2 * sup + 2 * u.perm + 2 * ring

    def snapshot(self):
        rec = {s: self.stats(s) for s in self.b}
        comb = dict(rec)
        for s, u in self.b.items():
            if u.name == "fetch":
                behind = [x for x in BEHIND[s] if x in self.b and self.b[x].name != "fetch"]
                if behind:
                    tgt = max(behind, key=lambda x: rec[x])
                    comb[s] = self.p["fetch"] * rec[tgt] + 2 * self.ring[s] * self.S
        if any(u.name == "will" for u in self.b.values()):
            for x in SLOTS:
                if x not in self.b and self.ring[x] > 0:
                    comb["W" + x] = 2 + 2 * self.ring[x] * self.S
        return rec, comb


def play(name, plan, rounds=16, show=True, **over):
    p = dict(P); p.update(over)
    g = Game(p); out = {}
    for r in range(1, rounds + 1):
        g.round = r
        g.gold += INCOME.get(r, 10) + g.pending; g.pending = 0
        if r >= 2:
            g.cost = max(0, g.cost - 1)
        spells = 0
        for a in plan.get(r, []):
            if p["supply"]:
                ring_spell = a[0] == "spell" and a[1] in ("spore", "stone")
                if ring_spell and (spells >= 1 or (g.tier >= 5 and r % int(p["supply"]) != 0)):
                    continue
                if a[0] == "nancycle" and g.tier >= 5:
                    continue
                spells += ring_spell
            g.act(a)
        g.end_of_turn()
        rec, comb = g.snapshot()
        big = max(comb.items(), key=lambda kv: kv[1]) if comb else ("", 0)
        out[r] = dict(rec=sum(rec.values()), comb=sum(comb.values()), S=g.S, rings=sum(g.ring.values()),
                      big=big, gold=g.gold, tier=g.tier, board=dict(g.b), ringmap=dict(g.ring))
    if show:
        print(name)
        for r in (4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16):
            o = out[r]
            bn = o["big"][0]
            bname = ("Wisp" if bn.startswith("W") else o["board"][bn].name) if bn else ""
            print("  R%2d T%d gold %2d  S %3d  Rings %3d  recruit %6.0f  combat %6.0f = %4.2fx  biggest %s@%s %5.0f (%2.0f%%)"
                  % (r, o["tier"], o["gold"], o["S"], o["rings"], o["rec"], o["comb"], o["comb"] / T.get(r, 1) if r in T else 0,
                     bname, bn.replace("W", ""), o["big"][1], 100 * o["big"][1] / o["comb"] if o["comb"] else 0))
        for l in g.log:
            print("   ", l)
        if p.get("debug"):
            for r in range(1, rounds + 1):
                o = out[r]
                print("   R%d gold %d S %d | " % (r, o["gold"], o["S"]) + " ".join(
                    "%s:%s/%d" % (x, o["board"][x].name if x in o["board"] else "-", o["ringmap"][x]) for x in SLOTS))
        print()
    return out


# ---------------------------------------------------------------- lines
CHURN_FROM = int(P.get("churn", 9))


def churn(p, start, keep=None):
    """Spend what is left each turn from round `start` on buy-and-sell churn (Annis's sell trigger)."""
    keep = keep or {}
    for r in range(start, 17):
        p[r] = list(p.get(r, [])) + [("churn", keep.get(r, 0))]
    return p

def ring_plan(v="typ"):
    """fairies_ring. The big Ring is B1, lit by Annis from F1; Fetch in F2 copies it.
    Climb T2 R2, T3 R4, T4 R6, T5 R9, T6 R11. 'nancycle' = buy Nan, play it, swap, sell it."""
    p = {}
    p[1] = [("buy", "nan", "B1")]
    p[2] = [("tier",)]
    p[3] = [("buy", "annis", "F1")]
    p[4] = [("tier",), ("buy", "sally", "B2")]                              # Sally grows the B3 gap
    p[5] = [("buy", "clur", "F2"), ("buy", "lob", "F3")]
    p[6] = [("tier",), ("nancycle", "F4", "F2")]
    p[7] = [("buy", "n4", "F4"), ("nancycle", "F1", "F3"), ("spell", "spore", "B2")]   # rainbow
    p[8] = [("sell", "B1"), ("buy", "n4", "B1"), ("spell", "spore", "B1"), ("buy", "hob", "B3")]
    p[9] = [("tier",), ("sell", "B2"), ("buy", "silky", "B2")]
    p[10] = [("spell", "pinch", "F3"), ("move", "F2", "F3"), ("buy", "fetch", "F2"), ("sell", "B1"),
             ("buy", "bella", "B1"), ("spell", "stone", "B1")]
    p[11] = [("tier",), ("spell", "pinch", "B2"), ("spell", "stone", "B1"), ("nancycle", "B2", "B1")]
    p[12] = [("buy", "monarch", "B2"), ("sell", "F4"), ("buy", "will", "F4"), ("spell", "stone", "B1")]
    p[13] = [("spell", "pinch", "B3"), ("buy", "reel", "B3"), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
    for r in (14, 15, 16):
        p[r] = [("spell", "stone", "B1"), ("spell", "stone", "B1"), ("spell", "stone", "B1"), ("nancycle", "B1", "B1")]
    if v == "slow":   # T5 R10, T6 R12, Monarch R13, a Stone fewer each late turn
        p[9] = [("sell", "B2"), ("buy", "silky", "B2"), ("spell", "spore", "B1")]
        p[10] = [("tier",), ("spell", "pinch", "F3"), ("move", "F2", "F3"), ("buy", "fetch", "F2")]
        p[11] = [("sell", "B1"), ("buy", "bella", "B1"), ("spell", "pinch", "B2"), ("spell", "stone", "B1"),
                 ("nancycle", "B2", "B1")]
        p[12] = [("tier",), ("spell", "stone", "B1")]
        p[13] = [("buy", "monarch", "B2"), ("sell", "F4"), ("buy", "will", "F4"), ("spell", "stone", "B1")]
        p[14] = [("spell", "pinch", "B3"), ("buy", "reel", "B3"), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
        for r in (15, 16):
            p[r] = [("spell", "stone", "B1"), ("spell", "stone", "B1"), ("nancycle", "B1", "B1")]
    if v == "high":   # golden Cluricaun on R8 (two more copies found), Monarch R11
        p[8] = p[8][:-1] + [("sell", "F2"), ("buy", "clur", "F2", True)]
        p[9] = [("tier",), ("sell", "B2"), ("buy", "silky", "B2"), ("buy", "hob", "B3")]
        p[11] = [("tier",), ("spell", "pinch", "B2"), ("buy", "monarch", "B2"), ("spell", "stone", "B1")]
        p[12] = [("sell", "F4"), ("buy", "will", "F4"), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
    if v == "low":    # no Lob or Silky; rainbow on R9; Monarch R13
        p[5] = [("buy", "clur", "F2"), ("buy", "n3", "F3")]
        p[7] = [("buy", "n4", "F4"), ("nancycle", "F1", "F3")]
        p[8] = [("sell", "B1"), ("buy", "n4", "B1"), ("spell", "spore", "B2"), ("buy", "hob", "B3")]
        p[9] = [("tier",)]
        p[10] = [("sell", "F3"), ("move", "F2", "F3"), ("buy", "fetch", "F2"), ("sell", "B1"), ("buy", "bella", "B1"),
                 ("spell", "stone", "B1")]
        p[11] = [("tier",), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
        p[12] = [("sell", "F4"), ("buy", "will", "F4"), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
        p[13] = [("sell", "B2"), ("buy", "monarch", "B2"), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
    if v == "top":    # golden Cluricaun R8 and golden Monarch R11
        p[8] = p[8][:-1] + [("sell", "F2"), ("buy", "clur", "F2", True)]
        p[9] = [("tier",), ("sell", "B2"), ("buy", "silky", "B2"), ("buy", "hob", "B3")]
        p[11] = [("tier",), ("spell", "pinch", "B2"), ("buy", "monarch", "B2", True), ("spell", "stone", "B1")]
        p[12] = [("sell", "F4"), ("buy", "will", "F4"), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
    if v == "copies":  # the breaker's stack: a 2nd Cluricaun on R8, a 2nd Silky on R9, a 2nd Monarch on R14
        p[8] = [("sell", "B1"), ("buy", "n4", "B1"), ("sell", "F4"), ("buy", "clur", "F4"), ("buy", "hob", "B3")]
        p[9] = [("tier",), ("sell", "B2"), ("buy", "silky", "B2")]
        p[10] = [("spell", "pinch", "F3"), ("buy", "silky", "F3"), ("spell", "spore", "B1"),
                 ("sell", "F1"), ("move", "F2", "F1"), ("buy", "fetch", "F2")]
        p[11] = [("tier",), ("spell", "pinch", "B2"), ("spell", "pinch", "F3"), ("sell", "B1"), ("buy", "bella", "B1"),
                 ("spell", "stone", "B1")]
        p[12] = [("buy", "monarch", "B2"), ("buy", "will", "F3"), ("spell", "stone", "B1")]
        p[14] = [("sell", "F4"), ("buy", "monarch", "F4"), ("spell", "stone", "B1"), ("spell", "stone", "B1")]
    return churn(p, CHURN_FROM, {9: 2, 10: 1})


def court_plan(v="typ"):
    """fairies_court (tempo). Every slot Ringed by R7, the Chaser cashed then; Annis F2 lights B1
    and B2. Lob banks from R5 and is thanked R10. Queen in F4 tithes the cheap unit in B3 every
    3rd turn. Climb T2 R2, T3 R4, T4 R6, T5 R8, T6 R10."""
    p = {}
    p[1] = [("buy", "nan", "F1")]
    p[2] = [("tier",)]
    p[3] = [("buy", "annis", "F2")]
    p[4] = [("tier",), ("buy", "chaser", "B2")]                       # stand on Annis's Rings
    p[5] = [("buy", "sally", "F4"), ("buy", "n2", "B1")]
    p[6] = [("tier",), ("nancycle", "F2", "F3")]
    p[7] = [("nancycle", "F4", "B3"), ("move", "B2", "F3"), ("sell", "F3"), ("buy", "clur", "F3"), ("buy", "witch", "B2"),
            ("buy", "lob", "B3"), ("sell", "B1"), ("buy", "changeling", "B1")]   # rainbow; Chaser pays 7
    p[8] = [("tier",), ("sell", "F1"), ("buy", "silky", "F1"), ("spell", "spore", "F4")]
    p[9] = [("sell", "F4"), ("buy", "bella", "F4")]
    p[10] = [("tier",), ("spell", "pinch", "B3"), ("buy", "n2", "B3")]
    # Queen in F4 tithes B3 every End of Turn; Will in B2 lights a Wisp in the tithed B3
    p[11] = [("spell", "pinch", "F1"), ("move", "F4", "F1"), ("buy", "queen", "F4"), ("sell", "B2"),
             ("buy", "will", "B2"), ("spell", "stone", "B1")]
    p[12] = [("buy", "n2", "B3"), ("spell", "supper",)]
    p[13] = [("sell", "B1"), ("buy", "monarch", "B1"), ("buy", "n2", "B3")]
    for r in (14, 15, 16):
        p[r] = [("buy", "n2", "B3"), ("spell", "stone", "F3")]
    if v == "noT6":   # no Queen or Monarch: a neutral 6 in F4, Reel-Mistress in B1 from R14
        p[11] = [("spell", "pinch", "F1"), ("move", "F4", "F1"), ("sell", "B3"), ("buy", "n6", "F4"),
                 ("sell", "B2"), ("buy", "will", "B2"), ("spell", "stone", "B1")]
        p[12] = [("spell", "supper",)]
        p[13] = [("spell", "stone", "F3")]
        p[14] = [("sell", "B1"), ("buy", "reel", "B1"), ("spell", "stone", "F3")]
        p[15] = [("spell", "stone", "F3")]
        p[16] = [("spell", "stone", "F3")]
    return churn(p, CHURN_FROM, {9: 2, 10: 1})


if __name__ == "__main__":
    L = P["line"]
    if L in ("all", "ring"):
        play("fairies_ring, full line (every piece on time)", ring_plan("typ"))
        play("fairies_ring, slow shops (T5 R10, T6 R12, Monarch R13)", ring_plan("slow"))
        play("fairies_ring, highroll (golden Cluricaun R8)", ring_plan("high"))
        play("fairies_ring, lowroll (no Lob or Silky, rainbow R8, Monarch R13)", ring_plan("low"))
        play("fairies_ring, top 1% (golden Cluricaun R8, golden Monarch R11)", ring_plan("top"))
        play("fairies_ring, breaker's copies with guards (2nd Cluricaun, 2nd Silky, 2nd Monarch)", ring_plan("copies"))
        play("fairies_ring, the same copies without guards", ring_plan("copies"), guards=0)
    if L in ("all", "supply"):
        for n in (2, 3):
            play("fairies_ring, typical, shop supply %d" % n, ring_plan("typ"), supply=n)
            play("fairies_court, typical, shop supply %d" % n, court_plan("typ"), supply=n)
    if L in ("all", "court"):
        play("fairies_court, full line", court_plan("typ"))
        play("fairies_court, no tier 6 Fairy", court_plan("noT6"))
