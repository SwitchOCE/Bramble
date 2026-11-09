"""Paper model of the Bog folk pass 3 engine (the Peat). Not a combat sim: it adds up
permanent stats on a scripted line, with guessed hit counts. Treat it as the scale of the
curve, not a measurement.

The Peat P starts at 1. Only Offerings raise it: Tiddy Mun gives one Offering at Start of Turn
(golden: two); casting one costs `offer_cost` gold (the Prince makes the first each turn 1 cheaper)
and raises the Peat by r. Offerings can be kept in hand and cast later.
"Gain the Peat" = +P/+P permanently. It happens when you buy a Bog folk, on each Swell (an enemy
this unit Mires attacks it), and on each of Ranocchio's Snaps. Golden gainers gain twice. The
Natterjack Chorus lends a second Swell to one neighbour (the diva if possible). The Peat King
makes every Swell trigger twice (golden: three times).
The Peat Cutter pays gold for Mired deaths (about `cut_gold` a fight).
Swells per fight = patches x occupancy x hits taken (guess that rises as walls grow).

Usage: python3 -I bog-engine-model.py [r=1] [offer_cost=2] [king_mult=2] [cut_gold=0.8] [verbose=1]
"""
import sys

ARGS = dict(a.split("=") for a in sys.argv[1:])
R = float(ARGS.get("r", 1))
OFFER = int(ARGS.get("offer_cost", 3))
KING = float(ARGS.get("king_mult", 2))
CUTG = float(ARGS.get("cut_gold", 0.3))
TID = float(ARGS.get("tiddy", 1))
ARRIVE = ARGS.get("arrive", "none")  # none | peat | tier: Bog folk you buy gain the Peat (x tier)
HIT = [float(x) for x in ARGS.get("hits", "1.1,1.15,1.2").split(",")]
VERB = int(ARGS.get("verbose", 0))

BASE = {  # tier, attack, health, patches (Swell sources), snaps a fight
    "toad": (1, 1, 3, 1, 0), "nan": (1, 1, 3, 0, 0), "pretender": (1, 3, 2, 0, 0),
    "bufo": (2, 1, 4, 0, 0), "hopkin": (2, 3, 1, 0, 0), "cutter": (2, 2, 4, 0, 0),
    "gideon": (3, 2, 6, 1, 0), "chorus": (3, 3, 4, 0, 0), "sal": (3, 2, 4, 0, 0),
    "tiddy": (5, 3, 6, 0, 0), "ranocchio": (4, 3, 5, 0, 1.4), "highness": (4, 3, 5, 0, 0),
    "prince": (4, 6, 7, 1, 0), "diva": (5, 2, 8, 3, 0), "jenny": (4, 3, 6, 1, 0),
    "king": (6, 5, 9, 1, 0), "lantern": (6, 4, 8, 0, 0),
    "n2": (2, 3, 3, 0, 0), "n3": (3, 4, 5, 0, 0), "n4": (4, 5, 6, 0, 0), "n5": (5, 6, 7, 0, 0),
}
NEUTRAL = {"n2", "n3", "n4", "n5"}


def hits(t, diva=False):
    """Locked hits a sweller takes per occupied patch per fight (guess)."""
    base = 1.0 if t <= 6 else HIT[0] if t <= 9 else HIT[1] if t <= 12 else HIT[2]
    return base * (0.85 if diva else 1.0)


OCC = 0.85


class U:
    def __init__(s, name, P, golden=False):
        s.name, s.golden = name, golden
        t, a, h, s.patches, s.snaps = BASE[name]
        m = 2 if golden else 1
        s.a, s.h = a * m, h * m
        if name not in NEUTRAL and ARRIVE != "none":
            k = t if ARRIVE == "tier" else 1
            s.a += P * k * m; s.h += P * k * m
        s.extra = 0

    def st(s, L=0):
        return s.a + s.h + (0 if s.name in NEUTRAL else 2 * L)


def run(plan, label):
    P, gold, held, L = 1.0, 0.0, 0, 0.0
    board, out = [], {}
    tier, disc = 1, 0
    cost = {2: 5, 3: 7, 4: 8, 5: 11, 6: 11}
    for t in range(1, 17):
        gold += min(2 + t, 10)
        step = plan.get(t, {})
        for _ in range(step.get("up", 0)):
            gold -= max(cost[tier + 1] - disc, 0); tier += 1; disc = 0
        for name in step.get("sell", []):
            for u in board:
                if u.name == name:
                    board.remove(u); gold += 1; break
        for spec in step.get("buy", []):
            g = spec.endswith("*")
            name = spec.rstrip("*")
            gold -= 3  # a golden is modelled as a Discover/triple paid by earlier copies
            board.append(U(name, P, g))
        if step.get("transform"):
            for u in board:
                if u.name == "highness":
                    u.name = "prince"; u.a += 3; u.h += 2; u.patches = 1
        # Start of Turn offerings already given; cast as many as asked and affordable
        held += sum(2 if u.golden else 1 for u in board if u.name == "cutter")
        want = step.get("offer", 0)
        prince = any(u.name == "prince" for u in board)
        cast = 0
        while cast < want and held > 0:
            c = OFFER - (1 if (prince and cast == 0) else 0)
            if gold < c:
                break
            gold -= c; held -= 1; cast += 1; P += R
        for u in board:
            u.extra = 0
        for c in [u for u in board if u.name == "chorus"]:
            tg = sorted([u for u in board if u.patches > 0], key=lambda u: -(u.patches * 1000 + u.st()))
            if tg:
                tg[0].extra += 2 if c.golden else 1
        if gold < 0:
            print("  GOLD SHORT", label, t, gold)
        if len(board) > 7:
            print("  BOARD OVER 7", label, t, [u.name for u in board])
        king = [u for u in board if u.name == "king"]
        km = 1 if not king else (KING if not king[0].golden else KING + 1)
        for u in board:
            if u.patches:
                n = u.patches * OCC * hits(t, u.name == "diva")
                g = n * ((2 if u.golden else 1) + u.extra) * km * P
                u.a += g; u.h += g
            if u.snaps:
                g = u.snaps * (2 if u.golden else 1) * P
                u.a += g; u.h += g
        gold += CUTG * sum(1 for u in board if u.name == "pretender")
        tot = sum(u.st(L) for u in board)
        big = max(board, key=lambda u: u.st(L))
        lb = 0 if big.name in NEUTRAL else L
        out[t] = (tot, (big.name, big.a + lb, big.h + lb), P, gold, tier, len(board), held, L)
        # End of Turn of this round already happened before combat in the game; we apply the
        # layer after combat here, which only shifts it by one fight.
        L += TID * P * sum(2 if u.golden else 1 for u in board if u.name == "tiddy")
        disc += 1
        if VERB:
            print(f"{label} R{t} P={P:.0f} L={L:.0f} gold={gold:.0f} held={held} T{tier} board={tot:.0f} ",
                  " ".join(f"{u.name}{'*' if u.golden else ''}:{u.a:.0f}/{u.h:.0f}" for u in board))
    return out


ENGINE = {  # the Diva line: walls, Cutter R4, Turfs from R5, Jenny R7, Tiddy R9, diva R10, King R12
    1: {"buy": ["toad"]},
    2: {"up": 1},
    3: {"buy": ["nan"]},
    4: {"buy": ["cutter", "bufo"]},
    5: {"up": 1, "buy": ["gideon"], "offer": 1},
    6: {"buy": ["chorus"], "offer": 1},
    7: {"up": 1, "buy": ["jenny"], "offer": 1},       # toad nan cutter bufo gideon chorus jenny
    8: {"buy": ["ranocchio"], "sell": ["nan"], "offer": 2},
    9: {"up": 1, "buy": ["tiddy"], "sell": ["bufo"], "offer": 1},
    10: {"buy": ["diva"], "sell": ["ranocchio"], "offer": 2},
    11: {"up": 1, "buy": ["highness"], "sell": ["chorus"], "offer": 2},
    12: {"buy": ["king"], "sell": ["toad"], "offer": 2, "transform": 1},
    13: {"offer": 2}, 14: {"offer": 2}, 15: {"offer": 2}, 16: {"offer": 2},
}
GREEDY = {k: dict(v) for k, v in ENGINE.items()}  # Cutter R3, second Cutter R6, every Turf it can
GREEDY[3] = {"buy": ["cutter"], "offer": 1}
GREEDY[4] = {"buy": ["bufo"], "offer": 1}
GREEDY[6] = {"buy": ["chorus", "cutter"], "offer": 2}
GREEDY[7] = {"up": 1, "buy": ["jenny"], "offer": 2}
GREEDY[8] = {"buy": ["nan"], "sell": [], "offer": 3}
GREEDY[8] = {"offer": 3}
GREEDY[9] = {"up": 1, "buy": ["tiddy"], "sell": ["bufo"], "offer": 3}
GREEDY[10] = {"buy": ["diva"], "sell": ["cutter"], "offer": 2}
GREEDY[11] = {"up": 1, "buy": ["highness"], "sell": ["chorus"], "offer": 1}
for t in (13, 14, 15, 16):
    GREEDY[t] = {"offer": 3}
TEMPO = {  # the Drowning: climb fast (T3 R4, T4 R6, T5 R8, T6 R10), answers and frogs, Cutter R6, Tiddy R10
    1: {"buy": ["pretender"]},
    2: {"up": 1},
    3: {"buy": ["toad"]},
    4: {"up": 1, "buy": ["bufo"]},
    5: {"buy": ["gideon", "hopkin"]},
    6: {"up": 1, "buy": ["cutter"], "sell": ["pretender"]},
    7: {"buy": ["jenny", "sal"], "offer": 1},
    8: {"up": 1, "buy": ["ranocchio"], "sell": ["sal"]},
    9: {"buy": ["highness"], "sell": ["hopkin"], "offer": 1},
    10: {"up": 1, "buy": ["tiddy"], "sell": ["bufo"], "offer": 1},
    11: {"buy": ["lantern"], "sell": ["toad"], "offer": 2},
    12: {"buy": ["diva"], "sell": ["cutter"], "offer": 2, "transform": 1},
    13: {"buy": ["king"], "sell": ["ranocchio"]},
    14: {}, 15: {}, 16: {},
}
HIGH = {k: dict(v) for k, v in GREEDY.items()}  # greedy, plus golden Cutter R6, golden diva R10, King R11
HIGH[6] = {"buy": ["chorus", "cutter*"], "offer": 3}
HIGH[10] = {"buy": ["diva*"], "sell": ["cutter"], "offer": 2}
HIGH[11] = {"up": 1, "buy": ["king"], "sell": ["chorus"], "offer": 1}
HIGH[12] = {"buy": ["highness"], "sell": ["toad"], "offer": 4}
HIGH[13] = {"offer": 4, "transform": 1}

TARGET = {6: 53, 9: 194, 12: 759, 15: 2600}
if __name__ == "__main__":
    for label, plan in (("engine", ENGINE), ("greedy", GREEDY), ("tempo", TEMPO), ("highroll", HIGH)):
        o = run(plan, label)
        print(f"\n{label}: r={R} offer_cost={OFFER} king=x{KING} arrive={ARRIVE} hits={HIT}")
        for t in (6, 9, 12, 15):
            tot, big, P, gold, tier, n, held, L = o[t]
            print(f"  R{t}: board {tot:6.0f} (BG Sep25 mean {TARGET[t]:5d})  per unit {tot/n:4.0f}  "
                  f"biggest {big[0]} {big[1]:.0f}/{big[2]:.0f} ({(big[1]+big[2])/tot:.0%})  "
                  f"Peat {P:.0f} layer +{L:.0f}  T{tier}  gold {gold:.0f} turfs held {held}")
