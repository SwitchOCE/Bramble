"""Hedgerow pass 3 synthesis model (9 Nov 2026). Paper model only; no Godot.

Run: python3 -I hedgerow-pass3-model.py            (everything, about a minute)
     python3 -I hedgerow-pass3-model.py part=curve (curves only, fast)
Dials (key=value), pass 3 defaults: wake=1.0 period=3 food=0.5 (per gold)
     share=0.1 comm=0.2 comm_mode=floor (or attack: the breaker's Committee)
     hayward=1.0 treas=1.0 beadle=1 pym=3 mastcap=5 lollops=1 masts=1
     parish_comms=1 dozey_tier=4 (3 = the engine design's tiers) hunker=aura
     (or pass) fights=500 seed=7

What it does, round by round, for three scripted lines (Supper, Parish, Treasury):
- Gold: income 3..10 with carry-over (rulebook 4.1.2), units 3 gold, sell 1
  (Created 0), tier-up costs with the per-turn discount (4.6), 1 gold of
  refreshes a turn from round 4 and 2 from round 8. If a line can't pay its
  scripted costs from gold, it cashes Larder items, smallest first. Spare gold
  (after the save rule: keep what next turn's script needs beyond its income)
  buys flat spells at +1/+1 per gold on the line's spell target. That is the
  only generic growth; the designer's free +4 a turn is gone.
- Larder: Acorn 1, Stash 5, Great Hoard 16 gold; three combine into the next.
  "Get" counts combining (Pym fires on a Stash formed from three Acorns).
- Start of Turn (reading order): Old Mother Mast (an Acorn per 5 gold in the
  Larder, up to `mastcap`), Squire Lollop (Hedgerow folk touching him, except
  your biggest, gain `share` of the biggest's Attack and Health). Sorrel's
  Acorns from the last fight arrive.
- Recruit: scripted buys, sells, moves; Crumb's Passes; Burdock's Kit or Spill;
  Clover's half stats onto Kits; then the line's Larder policy (Parish cashes
  everything; Supper holds and feeds it all to Dozey on his wake turn; Treasury
  holds and cashes out once, on a set round, with Hayward down). Goodman
  Hayward: every Larder item played (cashed or fed) gives Hedgerow folk
  +1/+1 per gold this game (a standing tribe bonus).
- End of Turn: recruiting Passes land on the last unit (zigzag F1-B1-F2-B2-
  F3-B3-F4), then End of Turn text in reading order (F1-F4, B1-B3): Mrs Mallow (doubles your smallest Hedgerow unit), the Standing
  Committee (Hedgerow folk touching it gain `comm` x the stats of the smallest
  of them; comm_mode=attack is the breaker's version), the Treasurer (+1/+1 per gold in the Larder), the Sleeping
  Partner (every 3 turns: an Acorn per Hedgerow unit touching it, itself
  included). Passes triggered at End of Turn (Beadle, Pym) land at once.
  Last, Dozey wakes: every `period` End of Turns in his slot he gains `wake` x
  his current stats (pass 3 rule: he wakes after your other End of Turn text).
- Fight: Mrs Sorrel in the back row Spills 1 Acorn a fight (1.5 from round 9).
  The Sergeant (Treasury line) spends one loose Acorn a fight when he has one.

Fights: a plain Bramble combat (reading order, pointer and flags, back-row
protection, random targets, simultaneous exchange, Last Blow). Keywords: Hunker
(takes half damage when attacked; Dr Urchin's last unit has it while he lives),
Bristle 2 on Urchin. No summons in fights. Fields at round r (typical median T):
  median: one carry with 34% of T plus six varied supports (Battlegrounds keeps
          about a third of the board in one unit), carry slot random;
  even:   seven equal units of T/7;
  strong: the median shape at 1.35 T;
  answer: strong, and one board in three halves your biggest unit at Start of
          Combat (a Track B "biggest enemy" answer).
Both sides' Attack/Health split is 50/50 with noise on the field.
Typical T: 24, 34, 52, 70 at R4-R7, then x1.5 a round (158 / 531 / 1,793 at
R9 / R12 / R15), the panel's target shape.
"""
import math
import random
import sys

ARGS = dict(a.split("=", 1) for a in sys.argv[1:] if "=" in a)


def P(key, default):
    return type(default)(ARGS.get(key, default))


DEFAULTS = dict(wake=1.0, period=3, food=0.5, share=0.10, comm=0.2, hayward=1.0,
                mastcap=5, lollops=1, masts=1, pym=3, beadle=1, treas=1.0, dozey_tier=4,
                hunker="aura", comm_mode="floor", parish_comms=1)
CFG = {k: P(k, v) for k, v in DEFAULTS.items()}
HUNKER = [CFG["hunker"]]   # "aura": the last unit has Hunker while Urchin lives; "pass": all fight
FIGHTS = P("fights", 500)
SEED = P("seed", 7)
PART = ARGS.get("part", "all")

ZIG = ["F1", "B1", "F2", "B2", "F3", "B3", "F4"]
READ = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
BEHIND = {"F1": ["B1"], "F2": ["B1", "B2"], "F3": ["B2", "B3"], "F4": ["B3"]}
BODY = {  # pass 3 bodies, Attack/Health
    "mrs_burdock": (1, 2), "kit": (1, 1), "mr_crumb": (1, 2), "sleeping_partner": (1, 2),
    "mrs_clover": (2, 4), "mr_pym": (2, 4), "mrs_sorrel": (2, 3),
    "alderman_dozey": (3, 6), "mrs_mallow": (2, 5), "sergeant_at_conkers": (3, 3),
    "dr_urchin": (2, 5), "beadle_warrenby": (3, 5), "honorary_treasurer": (3, 5),
    "goodman_hayward": (4, 7), "standing_committee": (5, 7),
    "squire_lollop": (6, 8), "old_mother_mast": (6, 8),
}
TIER_BASE = {2: 5, 3: 7, 4: 8, 5: 11, 6: 11}
TYPICAL = {1: 3, 2: 8, 3: 15, 4: 24, 5: 34, 6: 52, 7: 70}
for _r in range(8, 18):
    TYPICAL[_r] = TYPICAL[_r - 1] * 1.5


def income(r):
    return min(10, r + 2)


def refresh_budget(r):
    return 0 if r < 4 else (1 if r < 8 else 2)


class Unit:
    def __init__(self, cid, r, golden=False, created=False):
        self.cid, self.since, self.golden, self.created = cid, r, golden, created
        a, h = BODY[cid]
        m = 2 if golden else 1
        self.a, self.h = a * m, h * m


# ---------------------------------------------------------------- scripts
# Each script: round -> list of actions.
#   ("tier",)                      tier up
#   ("buy", cid, slot)             buy and play into slot
#   ("buy", cid, slot, "sell:B2")  sell what's in the slot first (or another slot)
#   ("move", from, to)             move (restarts "in this slot" counts)
#   ("golden", cid)                that unit becomes golden (tail runs only)
def supper_script(cfg):
    if cfg["dozey_tier"] == 3:   # the engine design's tiers (Dozey T3, Urchin T4 after the breaker's swap)
        s = {
            1: [("buy", "sleeping_partner", "B1")],
            2: [("tier",)],
            3: [("buy", "mr_pym", "F1")],
            4: [("tier",), ("buy", "alderman_dozey", "B3")],
            5: [("buy", "mrs_mallow", "F3"), ("buy", "mrs_sorrel", "B2")],
            6: [("buy", "mrs_burdock", "F2")],
            7: [("tier",), ("buy", "dr_urchin", "F2", "sell:F2")],
            8: [("buy", "beadle_warrenby", "F1", "sell:F1")],
            10: [("tier",), ("move", "B3", "F4"), ("buy", "goodman_hayward", "B3")],
            11: [("buy", "standing_committee", "B2", "sell:B2")],
            12: [("tier",), ("buy", "squire_lollop", "F3", "sell:F3")],
            13: [("buy", "old_mother_mast", "F1", "sell:F1")],
            14: [("buy", "honorary_treasurer", "B1", "sell:B1")],
        }
    else:                        # pass 3: Dozey T4, Mallow and Urchin T3
        s = {
            1: [("buy", "sleeping_partner", "B1")],
            2: [("tier",)],
            3: [("buy", "mr_pym", "F1")],
            4: [("tier",), ("buy", "mrs_mallow", "F3")],
            5: [("buy", "mrs_sorrel", "B2"), ("buy", "dr_urchin", "F2")],
            6: [("buy", "mr_crumb", "B3")],                          # sold into Dozey on R7
            7: [("tier",), ("buy", "alderman_dozey", "B3", "sell:B3")],   # F4 stays empty
            8: [("buy", "beadle_warrenby", "F1", "sell:F1")],
            10: [("tier",), ("move", "B3", "F4"), ("buy", "goodman_hayward", "B3")],
            11: [("buy", "standing_committee", "B2", "sell:B2")],
            12: [("tier",), ("buy", "squire_lollop", "F3", "sell:F3")],
            13: [("buy", "old_mother_mast", "F1", "sell:F1")],
            14: [("buy", "honorary_treasurer", "B1", "sell:B1")],
        }
    if cfg["lollops"] == 0:
        s[12] = [("tier",), ("buy", "old_mother_mast", "F3", "sell:F3")]
        s[13] = [("buy", "honorary_treasurer", "F1", "sell:F1")]
        s[14] = []
    if cfg["lollops"] >= 2:
        s[13] = [("buy", "squire_lollop", "F1", "sell:F1")]
        s[14] = [("buy", "old_mother_mast", "B1", "sell:B1")]
    return s


def parish_script(cfg):
    return {
        1: [("buy", "mrs_burdock", "F2")],                       # Kit into B1
        2: [("tier",)],
        3: [("buy", "mrs_clover", "F3")],
        4: [("tier",), ("buy", "mrs_mallow", "B2")],
        5: [("buy", "mrs_sorrel", "F4"), ("buy", "mrs_burdock", "B3")],   # Spill
        6: [("tier",), ("buy", "mr_crumb", "F1")],
        7: [("buy", "mrs_mallow", "B1", "sell:B1"), ("buy", "dr_urchin", "B3", "sell:B3")],
        8: [("tier",), ("buy", "standing_committee", "F1", "sell:F1")],  # Crumb Passes
        9: [("buy", "goodman_hayward", "F2", "sell:F2")],
        10: [("tier",)],
        11: [("buy", "squire_lollop", "F3", "sell:F3")],
        12: ([("buy", "standing_committee", "F4", "sell:F4")] if cfg["parish_comms"] >= 2
             else [("buy", "mrs_mallow", "F4", "sell:F4")]),             # a third Mallow
        14: [("buy", "squire_lollop", "B2", "sell:B2")] if cfg["lollops"] >= 2 else [],
    }


def treasury_script(cfg):
    s = {
        1: [("buy", "sleeping_partner", "B1")],
        2: [("tier",)],
        3: [("buy", "mr_pym", "F1")],
        4: [("tier",), ("buy", "mrs_mallow", "F3")],
        5: [("buy", "mrs_sorrel", "B2"), ("buy", "mrs_burdock", "F2")],    # Spill
        6: [("buy", "dr_urchin", "F2", "sell:F2")],
        7: [("tier",), ("buy", "honorary_treasurer", "F4")],              # Pass target
        8: [("buy", "beadle_warrenby", "F1", "sell:F1")],
        9: [("buy", "sergeant_at_conkers", "B3")],
        10: [("tier",), ("buy", "goodman_hayward", "F3", "sell:F3")],
        12: [("tier",), ("buy", "old_mother_mast", "B2", "sell:B2")],
        13: [("buy", "squire_lollop", "F1", "sell:F1")],
    }
    if cfg["masts"] >= 2:
        s[14] = [("buy", "old_mother_mast", "B3", "sell:B3")]
    return s


LINES = {
    "supper": dict(script=supper_script, policy="feast", spell="dozey"),
    "parish": dict(script=parish_script, policy="cash", spell="smallest"),
    "treasury": dict(script=treasury_script, policy="hold", spell="last", cashout=14),
}


def delay(script, late):
    if not late:
        return script
    out = {}
    for r, acts in script.items():
        out.setdefault(r + 1 if r >= 4 else r, []).extend(acts)
    return out


# ---------------------------------------------------------------- the run
def run(line, cfg=None, late=0, goldens=None, trace=False):
    cfg = dict(CFG if cfg is None else cfg)
    spec = LINES[line]
    script = delay(spec["script"](cfg), late)
    goldens = goldens or {}
    board = {s: None for s in ZIG}
    lard = {"acorn": 0, "stash": 0, "hoard": 0}
    st = dict(gold=0, tier=1, tier_cost=TIER_BASE[2], ta=0, th=0, sorrel_due=0.0,
              short=0, cashed_for_costs=0, fed=0, spells=0)
    out = {}

    units = lambda: [board[s] for s in ZIG if board[s]]
    has = lambda cid: [u for u in units() if u.cid == cid]
    A = lambda u: u.a + st["ta"]
    H = lambda u: u.h + st["th"]
    tot = lambda u: A(u) + H(u)
    value = lambda: lard["acorn"] + 5 * lard["stash"] + 16 * lard["hoard"]
    slot_of = lambda u: next(s for s in ZIG if board[s] is u)

    def last_unit(exclude=None):
        for s in reversed(ZIG):
            if board[s] and board[s] is not exclude:
                return board[s]
        return None

    def touching(u):
        i = ZIG.index(slot_of(u))
        lo = hi = i
        while lo > 0 and board[ZIG[lo - 1]]:
            lo -= 1
        while hi < 6 and board[ZIG[hi + 1]]:
            hi += 1
        return [board[ZIG[k]] for k in range(lo, hi + 1)]

    def biggest():
        return max(units(), key=lambda u: (tot(u), -ZIG.index(slot_of(u))))

    def smallest(pool):
        return min(pool, key=lambda u: (tot(u), ZIG.index(slot_of(u))))

    queued = []  # recruiting Passes: (a, h, source)

    def pass_now(a, h, source):
        t = last_unit(exclude=source)
        if t:
            t.a += a
            t.h += h

    def on_gain(kind, n, now):
        """Gain Larder items; fire Beadle (Acorns) and Pym (Stashes, formed counts)."""
        stashes = 0
        if kind == "acorn":
            for b in has("beadle_warrenby"):
                k = cfg["beadle"] * (2 if b.golden else 1)
                for _ in range(n):
                    (pass_now(k, k, b) if now else queued.append((k, k, b)))
        lard[kind] += n
        if kind == "stash":
            stashes += n
        while lard["acorn"] >= 3:
            lard["acorn"] -= 3
            lard["stash"] += 1
            stashes += 1
        while lard["stash"] >= 3:
            lard["stash"] -= 3
            lard["hoard"] += 1
        for p in has("mr_pym"):
            k = cfg["pym"] * (2 if p.golden else 1)
            for _ in range(stashes):
                (pass_now(k, k, p) if now else queued.append((k, k, p)))

    def hayward(gold):
        for hw in has("goodman_hayward"):
            k = cfg["hayward"] * (2 if hw.golden else 1)
            st["ta"] += k * gold
            st["th"] += k * gold

    def cash(amount_needed=None):
        """Cash Larder items, smallest first, until amount_needed gold (None = all)."""
        got = 0
        for kind, v in (("acorn", 1), ("stash", 5), ("hoard", 16)):
            while lard[kind] and (amount_needed is None or got < amount_needed):
                lard[kind] -= 1
                got += v
                hayward(v)
        st["gold"] += got
        return got

    def script_cost(r):
        c = refresh_budget(r)
        for act in script.get(r, []):
            if act[0] == "buy":
                c += 3
            elif act[0] == "tier":
                c += st["tier_cost"] if r == cur_round[0] else TIER_BASE.get(st["tier"] + 1, 99)
        return c

    cur_round = [0]
    for r in range(1, 17):
        cur_round[0] = r
        queued.clear()
        st["gold"] += income(r)
        if r >= 2:
            st["tier_cost"] = max(0, st["tier_cost"] - 1)
        # --- Start of Turn
        due = int(st["sorrel_due"])
        st["sorrel_due"] -= due
        if due:
            on_gain("acorn", due, now=False)
        for s in READ:
            u = board[s]
            if not u:
                continue
            if u.cid == "old_mother_mast":
                m = 2 if u.golden else 1
                n = min(cfg["mastcap"] * m, m * (value() // 5))
                if n:
                    on_gain("acorn", n, now=False)
            elif u.cid == "squire_lollop":
                big = biggest()
                f = cfg["share"] * (2 if u.golden else 1)
                ga, gh = math.floor(f * A(big)), math.floor(f * H(big))
                for v in touching(u):
                    if v is not big:
                        v.a += ga
                        v.h += gh
        # --- Recruit: pay for the script
        need = script_cost(r)
        if st["gold"] < need:
            got = cash(need - st["gold"])
            st["cashed_for_costs"] += got
            if st["gold"] < need:
                st["short"] += need - st["gold"]
        st["gold"] -= refresh_budget(r)
        for act in script.get(r, []):
            if act[0] == "tier":
                st["gold"] -= st["tier_cost"]
                st["tier"] += 1
                st["tier_cost"] = TIER_BASE.get(st["tier"] + 1, 99)
            elif act[0] == "move":
                u = board[act[1]]
                board[act[1]], board[act[2]] = None, u
                u.since = r
            elif act[0] == "buy":
                cid, slot = act[1], act[2]
                if len(act) > 3 and act[3].startswith("sell:"):
                    ss = act[3][5:]
                    old = board[ss]
                    if old:
                        if old.cid == "mr_crumb":
                            m = 2 if old.golden else 1
                            queued.append((m * old.a, m * old.h, old))   # tribe bonus stays
                        st["gold"] += 0 if old.created else 1
                        board[ss] = None
                st["gold"] -= 3
                u = Unit(cid, r)
                board[slot] = u
                if cid == "mr_crumb":
                    queued.append((1, 1, u))
                if cid == "mrs_burdock":
                    free = [b for b in BEHIND.get(slot, []) if not board[b]]
                    if free:
                        kit = Unit("kit", r, created=True)
                        board[free[0]] = kit
                        for c in has("mrs_clover"):
                            f = 1.0 if c.golden else 0.5
                            kit.a += math.floor(f * A(c))
                            kit.h += math.floor(f * H(c))
                    else:
                        on_gain("acorn", 1, now=False)
            elif act[0] == "golden":
                for u in has(act[1]):
                    if not u.golden:
                        u.golden = True
                        b = BODY[u.cid]
                        u.a += b[0] * 2   # two more copies' bodies
                        u.h += b[1] * 2
                        if u.cid == "alderman_dozey":
                            u.since = r
                        break
        for cid, rr in goldens.items():
            if rr == r:
                for u in has(cid):
                    if not u.golden:
                        u.golden = True
                        b = BODY[u.cid]
                        u.a += 2 * b[0]
                        u.h += 2 * b[1]
                        if u.cid == "alderman_dozey":
                            u.since = r
                        break
        # --- Larder policy
        dz = has("alderman_dozey")
        dz = dz[0] if dz else None
        wake_turn = bool(dz) and (r - dz.since + 1) % cfg["period"] == 0
        if spec["policy"] == "cash":
            cash()
        elif spec["policy"] == "feast" and wake_turn:
            v = value()
            m = 2 if dz.golden else 1
            dz.a += math.ceil(cfg["food"] * m * v)
            dz.h += math.ceil(cfg["food"] * m * v)
            st["fed"] += v
            hayward(v)
            lard.update(acorn=0, stash=0, hoard=0)
        elif spec["policy"] == "hold" and has("goodman_hayward") and r == spec.get("cashout"):
            cash()
        # --- spare gold: save rule, then flat spells at +1/+1 per gold
        nxt = 0
        if r < 16:
            for act in script.get(r + 1, []):
                nxt += 3 if act[0] == "buy" else 0
                nxt += max(0, st["tier_cost"] - 1) if act[0] == "tier" else 0
            nxt += refresh_budget(r + 1)
        keep = max(0, nxt - income(r + 1))
        spare = max(0, st["gold"] - keep)
        if spare and units():
            if spec["spell"] == "dozey" and dz:
                t = dz
            elif spec["spell"] == "last":
                tr = has("honorary_treasurer")
                t = tr[0] if tr else last_unit()
            else:
                t = smallest(units())
            t.a += spare
            t.h += spare
            st["gold"] -= spare
            st["spells"] += spare
        # --- End of Turn
        for a, h, src in queued:
            pass_now(a, h, src)
        queued.clear()
        for s in READ:
            u = board[s]
            if not u:
                continue
            if u.cid == "mrs_mallow":
                pool = sorted(units(), key=lambda x: (tot(x), ZIG.index(slot_of(x))))
                for v in pool[: (2 if u.golden else 1)]:
                    ga, gh = A(v), H(v)
                    v.a += ga
                    v.h += gh
            elif u.cid == "standing_committee" and cfg["comm_mode"] == "floor":
                run_ = [v for v in touching(u)]
                small = smallest(run_)
                f = cfg["comm"] * (2 if u.golden else 1)
                ga, gh = math.floor(f * A(small)), math.floor(f * H(small))
                for v in run_:
                    v.a += ga
                    v.h += gh
            elif u.cid == "standing_committee":
                big = biggest()
                pool = [v for v in touching(u) if v is not big]
                k = 2 if u.golden else 1
                for v in sorted(pool, key=lambda x: (tot(x), ZIG.index(slot_of(x))))[:k]:
                    v.a += math.floor(cfg["comm"] * A(big))
            elif u.cid == "honorary_treasurer":
                k = (2 if u.golden else 1) * cfg["treas"]
                u.a += math.floor(k * value())
                u.h += math.floor(k * value())
            elif u.cid == "sleeping_partner" and (r - u.since + 1) % 3 == 0:
                n = len(touching(u)) * (2 if u.golden else 1)
                on_gain("acorn", n, now=True)
        # Dozey wakes after your other End of Turn effects (pass 3 rule)
        for u in has("alderman_dozey"):
            if (r - u.since + 1) % cfg["period"] == 0:
                u.a += math.floor(cfg["wake"] * A(u))
                u.h += math.floor(cfg["wake"] * H(u))
        # --- fight
        for s, u in board.items():
            if u and u.cid == "mrs_sorrel" and all(board[b] for b in BEHIND.get(s, [])):
                st["sorrel_due"] += 1.0 if r < 9 else 1.5
        snap = {s: (A(board[s]), H(board[s]), board[s].cid) for s in ZIG if board[s]}
        if has("sergeant_at_conkers") and lard["acorn"]:
            lard["acorn"] -= 1
        out[r] = dict(board=snap, larder=value(), tribe=st["ta"], gold=st["gold"],
                      short=st["short"], fed=st["fed"], spells=st["spells"],
                      cashed=st["cashed_for_costs"])
    return out


def total(snap):
    return sum(a + h for a, h, _ in snap.values())


# ---------------------------------------------------------------- fights
def fight(X, Y, rng):
    """X, Y: slot -> dict(a, h, hunker, bristle). Returns 0 if X wins, 1 if Y, -1 tie."""
    sides = [{s: dict(u) for s, u in X.items()}, {s: dict(u) for s, u in Y.items()}]
    n0, n1 = len(sides[0]), len(sides[1])
    turn = 0 if n0 > n1 else 1 if n1 > n0 else rng.randrange(2)
    flags = [set(), set()]
    for _ in range(200):
        me, op = sides[turn], sides[1 - turn]
        if not me:
            return 1 - turn
        if not op:
            return turn
        can = [s for s in READ if s in me and me[s]["a"] > 0]
        if not can:
            if not any(op[s]["a"] > 0 for s in op):
                return -1
            turn = 1 - turn
            continue
        cand = [s for s in can if s not in flags[turn]]
        if not cand:
            flags[turn] = set()
            cand = can
        s = cand[0]
        flags[turn] |= set(READ[: READ.index(s) + 1])
        front = [t for t in READ[:4] if t in op]
        t = rng.choice(front if front else [t for t in READ[4:] if t in op])
        att, dfn = me[s], op[t]
        d = att["a"]
        if dfn.get("hunker"):
            d -= d // 2
        dfn["h"] -= d + 0
        att["h"] -= dfn["a"] + dfn.get("bristle", 0)
        if att.get("bristle"):
            dfn["h"] -= att["bristle"]
        if att["h"] <= 0:
            del me[s]
        if dfn["h"] <= 0:
            del op[t]
        for side in (me, op):
            if any(u.get("urchin") for u in side.values()):
                continue
            for u in side.values():
                if u.get("hunker") == "aura":
                    u["hunker"] = False
        if not me and not op:
            return turn
        turn = 1 - turn
    return -1


def hedgerow_board(snap):
    b = {s: dict(a=a, h=h) for s, (a, h, cid) in snap.items()}
    for s, (a, h, cid) in snap.items():
        if cid == "dr_urchin":
            b[s]["bristle"] = 2
            b[s]["urchin"] = True
    if any(cid == "dr_urchin" for _, _, cid in snap.values()):
        urch = [s for s, v in snap.items() if v[2] == "dr_urchin"]
        for s in reversed(ZIG):
            if s in b and s not in urch:
                b[s]["hunker"] = "aura" if HUNKER[0] == "aura" else True
                break
    return b


def field_board(T, kind, rng):
    def unit(t):
        sp = rng.uniform(0.4, 0.6)
        a = max(1, round(t * sp))
        return dict(a=a, h=max(1, round(t) - a))
    slots = READ[:]
    if kind == "even":
        return {s: unit(T / 7) for s in slots}
    carry = 0.34 * T
    w = [rng.uniform(0.7, 1.3) for _ in range(6)]
    rest = [(T - carry) * x / sum(w) for x in w]
    rng.shuffle(slots)
    b = {slots[0]: unit(carry)}
    for s, t in zip(slots[1:], rest):
        b[s] = unit(t)
    return b


def halve_biggest(H, F):
    s = max(H, key=lambda k: H[k]["a"] + H[k]["h"])
    H[s]["a"] //= 2
    H[s]["h"] = max(1, H[s]["h"] // 2)


def winrate(snap, T, kind, rng, n=None, mod=None):
    n = n or FIGHTS
    w = 0
    for _ in range(n):
        H = hedgerow_board(snap)
        F = field_board(T, "median" if kind == "answer" else kind, rng)
        if kind == "answer" and rng.random() < 1 / 3:
            halve_biggest(H, F)
        if mod:
            mod(H, F)
        res = fight(H, F, rng)
        w += 1 if res == 0 else 0.5 if res == -1 else 0
    return w / n


# ---------------------------------------------------------------- reports
def curve_rows(line, cfg=None, goldens=None):
    on = run(line, cfg, 0, goldens)
    lt = run(line, cfg, 1, goldens)
    rows = {}
    for r in range(4, 17):
        a, b = total(on[r]["board"]), total(lt[r]["board"])
        rows[r] = (a, b, (a + b) / 2)
    return on, lt, rows


def avg3(rows, r, k=2):
    vals = [rows[x][k] / TYPICAL[x] for x in (r - 1, r, r + 1) if x in rows]
    return sum(vals) / len(vals)


def print_curve(line, cfg=None, goldens=None, label=""):
    on, lt, rows = curve_rows(line, cfg, goldens)
    print(f"== {line} {label}: board / typical. on time | one round late | mean | 3-round mean")
    for r in range(4, 17):
        a, b, m = rows[r]
        big = max(v[0] + v[1] for v in on[r]["board"].values())
        print(f"  R{r:2d} T{TYPICAL[r]:6.0f}: {a:6.0f} ({a/TYPICAL[r]:.2f}) | {b:6.0f} ({b/TYPICAL[r]:.2f}) |"
              f" {m:6.0f} ({m/TYPICAL[r]:.2f}) | {avg3(rows, r):.2f}   biggest {big/a:.0%}"
              f"  larder {on[r]['larder']}  tribe +{on[r]['tribe']:.0f}")
    print(f"  gold short (on time): {on[16]['short']}, cashed for costs {on[16]['cashed']},"
          f" fed {on[16]['fed']}, spells {on[16]['spells']}")
    return on, lt, rows


def print_units(on, rounds=(6, 9, 12, 15)):
    for r in rounds:
        snap = on[r]["board"]
        items = sorted(snap.items(), key=lambda kv: -(kv[1][0] + kv[1][1]))
        print(f"  R{r} ({total(snap):.0f}):", ", ".join(f"{s} {cid} {a}/{h}" for s, (a, h, cid) in items))


def summary(line, cfg):
    _, _, rows = curve_rows(line, cfg)
    return " ".join(f"R{r} {rows[r][2]/TYPICAL[r]:.2f}" for r in (6, 9, 12, 15)) + \
        f" | 3-avg R12 {avg3(rows, 12):.2f} R15 {avg3(rows, 15):.2f}"


def main():
    rng = random.Random(SEED)
    lines = ["supper", "parish", "treasury"]
    res = {}
    for ln in lines:
        res[ln] = print_curve(ln)
        print_units(res[ln][0])
        print("  late:")
        print_units(res[ln][1])
    if PART == "curve":
        return
    print("\n== Fights at every round, mean of the on-time and late lines (fights per cell: %d)" % FIGHTS)
    print("   round:      " + " ".join(f"R{r:<4d}" for r in range(6, 17)))
    for ln in lines:
        for kind, mult, tag in (("median", 1.0, "median"), ("median", 1.35, "strong"), ("answer", 1.35, "strong+ans")):
            vals = []
            for r in range(6, 17):
                T = TYPICAL[r] * mult
                vals.append((winrate(res[ln][0][r]["board"], T, kind, rng) + winrate(res[ln][1][r]["board"], T, kind, rng)) / 2)
            band = lambda a, b: sum(vals[a - 6:b - 5]) / (b - a + 1)
            print(f"  {ln:8s} {tag:10s} " + " ".join(f"{v:4.0%} " for v in vals) +
                  f"| R6-8 {band(6, 8):.0%} R9-11 {band(9, 11):.0%} R12-16 {band(12, 16):.0%}")
    print("\n== Concentration window: on-time Supper against even boards of lower or equal total")
    on = res["supper"][0]
    for r in range(6, 13):
        snap = on[r]["board"]
        t = total(snap)
        big = max(v[0] + v[1] for v in snap.values())
        cells = []
        for f in (0.6, 0.8, 1.0):
            cells.append(f"{f:.1f}x {winrate(snap, f * t, 'even', rng, n=300):.0%}")
        nohunk = {s: v for s, v in snap.items()}
        print(f"  R{r} total {t:5.0f} biggest {big/t:.0%}: " + "  ".join(cells))
    print("\n== Answers: a Stash from an enemy Sergeant (halve) across the Supper's carry")
    for r in (9, 12, 15):
        snap = on[r]["board"]
        carry = max(snap, key=lambda s: snap[s][0] + snap[s][1])

        def halve(H, F, s=carry):
            H[s]["a"] //= 2
            H[s]["h"] = max(1, H[s]["h"] // 2)

        def zero(H, F, s=carry):
            H[s]["a"] = 0
            H[s]["h"] = 1
        T = TYPICAL[r]
        print(f"  R{r}: as is {winrate(snap, T, 'median', rng):.0%}/{winrate(snap, 1.35*T, 'median', rng):.0%},"
              f" carry halved {winrate(snap, T, 'median', rng, mod=halve):.0%}/"
              f"{winrate(snap, 1.35*T, 'median', rng, mod=halve):.0%},"
              f" carry 0/1 {winrate(snap, T, 'median', rng, mod=zero):.0%}/"
              f"{winrate(snap, 1.35*T, 'median', rng, mod=zero):.0%}   (median / strong)")
    print("\n== Dial sweeps (mean of on time and late, board / typical)")
    sweeps = [
        ("default", {}),
        ("engine design's tiers (Dozey T3)", dict(dozey_tier=3)),
        ("wake +75%", dict(wake=0.75)), ("wake +150%", dict(wake=1.5)),
        ("wake x2 every 4", dict(period=4)),
        ("food per gold", dict(food=1.0)), ("Beadle +2/+2", dict(beadle=2)),
        ("no Lollop", dict(lollops=0)), ("two Lollops", dict(lollops=2)),
        ("share 1/20", dict(share=0.05)), ("share 1/8", dict(share=0.125)),
        ("two Lollops, share 1/20", dict(lollops=2, share=0.05)),
        ("breaker's Committee (half)", dict(comm_mode="attack", comm=0.5)),
        ("breaker's Committee (full)", dict(comm_mode="attack", comm=1.0)),
        ("Committee a quarter", dict(comm=0.25)), ("Committee off", dict(comm=0.0)),
        ("no Lollop, Committee off", dict(lollops=0, comm=0.0)),
        ("Hayward per 2 gold", dict(hayward=0.5)),
        ("Hunker all fight (Pass)", dict(hunker="pass")),
    ]
    for name, d in sweeps:
        cfg = dict(CFG, **d)
        print(f"  supper   {name:34s} {summary('supper', cfg)}")
    for name, d in [("default", {}), ("two Lollops", dict(lollops=2)), ("two Committees", dict(parish_comms=2)),
                    ("Committee a quarter", dict(comm=0.25)), ("Committee a tenth", dict(comm=0.1)),
                    ("breaker's Committee (half)", dict(comm_mode="attack", comm=0.5)),
                    ("breaker's Committee (full)", dict(comm_mode="attack", comm=1.0)),
                    ("share 1/20", dict(share=0.05))]:
        cfg = dict(CFG, **d)
        print(f"  parish   {name:34s} {summary('parish', cfg)}")
    for name, d in [("default", {}), ("Treasurer per 2 gold", dict(treas=0.5)), ("two Masts", dict(masts=2)),
                    ("Mast uncapped", dict(mastcap=99)), ("two Masts uncapped", dict(masts=2, mastcap=99))]:
        cfg = dict(CFG, **d)
        on = run("treasury", cfg)
        print(f"  treasury {name:34s} {summary('treasury', cfg)} | larder R12/R14/R16 "
              f"{on[12]['larder']}/{on[13]['larder']}->{on[14]['larder']}/{on[16]['larder']}")
    print("\n== Tail: goldens on the on-time Supper (board / typical)")
    tails = [
        ("golden Dozey R10", {"alderman_dozey": 10}),
        ("golden Lollop R14", {"squire_lollop": 14}),
        ("golden Dozey R10 + Hayward R12 + Lollop R14", {"alderman_dozey": 10, "goodman_hayward": 12,
                                                         "squire_lollop": 14}),
    ]
    for name, g in tails:
        on = run("supper", None, 0, g)
        print(f"  {name:46s} " + " ".join(f"R{r} {total(on[r]['board'])/TYPICAL[r]:.2f}" for r in (12, 13, 14, 15, 16)))
    on = run("parish", None, 0, {"mrs_mallow": 9, "standing_committee": 12})
    print(f"  {'Parish: golden Mallow R9 + golden Committee R12':46s} " +
          " ".join(f"R{r} {total(on[r]['board'])/TYPICAL[r]:.2f}" for r in (12, 13, 14, 15, 16)))
    on = run("treasury", None, 0, {"honorary_treasurer": 10, "old_mother_mast": 14})
    print(f"  {'Treasury: golden Treasurer R10 + golden Mast R14':46s} " +
          " ".join(f"R{r} {total(on[r]['board'])/TYPICAL[r]:.2f}" for r in (12, 13, 14, 15, 16)))
    cfg2 = dict(CFG, lollops=2)
    on = run("supper", cfg2, 0, {"alderman_dozey": 10, "goodman_hayward": 12, "squire_lollop": 15})
    print(f"  {'two Lollops + all three goldens':46s} " +
          " ".join(f"R{r} {total(on[r]['board'])/TYPICAL[r]:.2f}" for r in (12, 13, 14, 15, 16)))


if __name__ == "__main__":
    main()
