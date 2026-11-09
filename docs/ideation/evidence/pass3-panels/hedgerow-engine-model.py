"""Paper model for the Hedgerow pass 3 engine design (the Long Sleep).

Run: python3 -I hedgerow-engine-model.py [wake=1.0] [period=3] [food=0.5]
     [share=0.10] [pym=3] [beadle=2] [committee=0.5] [hayward=1] [spells=4]
     [line=supper|parish|both] [units=1] [late=0] [curve=1] [beadle_line=1]

Defaults are the pass 3 card texts: Dozey doubles every 3 turns and eats at
+1/+1 per 2 gold; Pym Passes +3/+3; Beadle Passes +2/+2 per Acorn; the
Committee gives Attack only (counted as half its stats); Lollop shares 10%.

No fights are simulated. Stats are Attack + Health totals; "+X/+X" adds 2X.
Two scripted lines (SUPPER and PARISH below), round by round:
- Start of Turn: Old Mother Mast's interest (an Acorn per Stash held, a Great
  Hoard counts as three); Acorns won by Mrs Sorrel last fight arrive.
- Recruit: scripted buys, sells and moves; then the Acorn policy. The Supper
  line holds everything and feeds it all to Dozey on his wake turn; the Parish
  line cashes it all at once (gold only; the model doesn't buy with it).
- End of Turn, in this order: Passes land; Dozey wakes (every `period` turns
  in his slot he gains `wake` x his stats); Mrs Mallow doubles the smallest
  Hedgerow unit; the Committee; Squire Lollop's share; the Sleeping Partner.
- Goodman Hayward is a standing tribe bonus: every Hedgerow unit, now and
  later, has +H/+H per gold of Acorns played (cashed or fed) after he lands.
It prints board totals at rounds 6, 9, 12 and 15 and the biggest unit's
share, next to the target (typical = the lobby median shape used by the
Hunters model; strong = 1.35x, about Battlegrounds' September 2025 means).
`late=1` delays every buy from round 4 by one round (a slow game).
"""
import sys

ARGS = dict(a.split("=", 1) for a in sys.argv[1:] if "=" in a)
WAKE = float(ARGS.get("wake", "1.0"))
PERIOD = int(ARGS.get("period", "3"))
FOOD = float(ARGS.get("food", "0.5"))   # current text: +1/+1 per 2 gold
SHARE = float(ARGS.get("share", "0.10"))
PYM = float(ARGS.get("pym", "3"))
BEADLE = float(ARGS.get("beadle", "2"))
COMMITTEE = float(ARGS.get("committee", "0.5"))  # Attack only: half the stats
HAYWARD = float(ARGS.get("hayward", "1"))
LINE = ARGS.get("line", "both")
LATE = int(ARGS.get("late", "0"))
SPELLS = float(ARGS.get("spells", "4"))   # generic spell/neutral stats a turn, R3+

TARGET = {6: 52, 9: 158, 12: 531, 15: 1793}
BASE = {  # Attack + Health of the pass 3 bodies
    "mrs_burdock": 3, "kit": 2, "mr_crumb": 3, "sleeping_partner": 3,
    "mrs_clover": 6, "mr_pym": 6, "mrs_sorrel": 5, "alderman_dozey": 7,
    "dr_urchin": 7, "sergeant_at_conkers": 6, "beadle_warrenby": 8,
    "mrs_mallow": 8, "honorary_treasurer": 8, "goodman_hayward": 11,
    "standing_committee": 12, "squire_lollop": 14, "old_mother_mast": 14,
}
ZIGZAG = ["F1", "B1", "F2", "B2", "F3", "B3", "F4"]

# round -> actions. ("buy", id, slot) ("sell", slot) ("move", from, to)
SUPPER = {
    1: [("buy", "sleeping_partner", "B1")],
    3: [("buy", "mr_pym", "F1")],
    4: [("buy", "alderman_dozey", "B3")],      # last while F4 is empty
    5: [("buy", "mrs_sorrel", "B2")],          # back row: every summon Spills
    6: [("buy", "dr_urchin", "F2")],
    7: [("buy", "mrs_mallow", "F3")],
    10: [("move", "B3", "F4"), ("buy", "goodman_hayward", "B3")],  # just after a wake
    11: [("sell", "F1"), ("buy", "standing_committee", "F1")],
    12: [("sell", "B2"), ("buy", "squire_lollop", "B2")],
    13: [("sell", "B1"), ("buy", "old_mother_mast", "B1")],
}
PARISH = {
    1: [("buy", "mrs_burdock", "F2")],          # Kit behind
    2: [("buy", "mr_crumb", "F1")],
    3: [("buy", "mrs_clover", "F3")],
    4: [("buy", "mrs_sorrel", "F4")],
    5: [("buy", "mrs_burdock", "B3")],          # Kit has no room: Acorn
    6: [("buy", "mrs_mallow", "B2")],
    8: [("sell", "F1"), ("buy", "standing_committee", "F1")],   # Crumb Passes
    9: [("sell", "B3"), ("buy", "goodman_hayward", "B3")],
    10: [("sell", "F2"), ("buy", "mrs_mallow", "F2")],          # second Mallow
    11: [("sell", "B1"), ("buy", "squire_lollop", "B1")],
}


if ARGS.get("beadle_line") == "1":
    # Beadle replaces Pym at round 8 and gives way to the Committee at 11
    SUPPER[8] = [("sell", "F1"), ("buy", "beadle_warrenby", "F1")]


def delay(script):
    if not LATE:
        return script
    return {(r + 1 if r >= 4 else r): a for r, a in script.items()}


class Unit:
    def __init__(self, cid, r, own=None):
        self.cid, self.since = cid, r
        self.own = BASE[cid] if own is None else own


def run(script, line):
    board = {s: None for s in ZIGZAG}
    hand = {"acorn": 0, "stash": 0, "hoard": 0}
    tribe = 0.0
    sorrel_due = 0.0
    out = {}

    units = lambda: [u for u in board.values() if u]
    has = lambda cid: any(u.cid == cid for u in units())
    stats = lambda u: u.own + tribe
    larder = lambda: hand["acorn"] + 5 * hand["stash"] + 16 * hand["hoard"]

    def last_unit():
        for s in reversed(ZIGZAG):
            if board[s]:
                return board[s]
        return None

    def touching(of):
        i = [k for k, s in enumerate(ZIGZAG) if board[s] is of][0]
        lo = hi = i
        while lo > 0 and board[ZIGZAG[lo - 1]]:
            lo -= 1
        while hi < 6 and board[ZIGZAG[hi + 1]]:
            hi += 1
        return [board[ZIGZAG[k]] for k in range(lo, hi + 1)]

    gains = [0]

    def gain(kind, n=1):
        """Gain Acorn items; return the number of Stashes formed or gained."""
        gains[0] += n
        hand[kind] += n
        got = n if kind == "stash" else 0
        while hand["acorn"] >= 3:
            hand["acorn"] -= 3
            hand["stash"] += 1
            got += 1
        while hand["stash"] >= 3:
            hand["stash"] -= 3
            hand["hoard"] += 1
        return got

    for r in range(1, 17):
        passes = []
        played = 0
        gains[0] = 0
        # Start of Turn
        stash_events = 0
        if has("old_mother_mast"):
            stash_events += gain("acorn", hand["stash"] + 3 * hand["hoard"])
        whole = int(sorrel_due)
        sorrel_due -= whole
        stash_events += gain("acorn", whole)
        # Recruit
        for act in script.get(r, []):
            if act[0] == "move":
                u = board[act[1]]
                board[act[1]], board[act[2]] = None, u
                u.since = r
            elif act[0] == "sell":
                u = board[act[1]]
                if u.cid == "mr_crumb":
                    passes.append(stats(u))          # When sold: Pass its stats
                board[act[1]] = None
            else:
                _, cid, slot = act
                board[slot] = Unit(cid, r)
                if cid == "mr_crumb":
                    passes.append(2)                 # When played: Pass +1/+1
                if cid == "mrs_burdock":
                    behind = {"F1": ["B1"], "F2": ["B1", "B2"], "F3": ["B2", "B3"],
                              "F4": ["B3"]}.get(slot, [])
                    free = [s for s in behind if not board[s]]
                    if free:
                        kit = 2 + (stats(next(u for u in units() if u.cid == "mrs_clover")) // 2 * 1
                                   if has("mrs_clover") else 0)
                        board[free[0]] = Unit("kit", r, kit)
                    else:
                        stash_events += gain("acorn")   # Spill
        if has("mr_pym"):
            passes += [2 * PYM] * stash_events
        dozey = next((u for u in units() if u.cid == "alderman_dozey"), None)
        wake_turn = bool(dozey) and (r - dozey.since + 1) % PERIOD == 0
        # Acorn policy
        if line == "parish":
            played += larder()
            hand.update(acorn=0, stash=0, hoard=0)
        elif wake_turn:
            dozey.own += 2 * FOOD * larder()
            played += larder()
            hand.update(acorn=0, stash=0, hoard=0)
        if has("goodman_hayward"):
            tribe += 2 * HAYWARD * played
        # Generic spells and neutral buffs (not Hedgerow text): onto the Pass
        # target on the Supper line (fed before a wake), else the smallest.
        if r >= 3 and units():
            (last_unit() if line == "supper" else min(units(), key=stats)).own += SPELLS
        # End of Turn
        if has("beadle_warrenby"):
            passes += [2 * BEADLE] * gains[0]
        tgt = last_unit()
        for p in passes:
            tgt.own += p
        if wake_turn:
            dozey.own += WAKE * stats(dozey)
        for _ in [u for u in units() if u.cid == "mrs_mallow"]:
            small = min(units(), key=stats)
            small.own += stats(small)
        for u in [u for u in units() if u.cid == "standing_committee"]:
            t = touching(u)
            for v in t:
                v.own += 2 * COMMITTEE * len(t)
        for u in [u for u in units() if u.cid == "squire_lollop"]:
            amt = SHARE * stats(max(units(), key=stats))
            for v in touching(u):
                v.own += amt
        for u in [u for u in units() if u.cid == "honorary_treasurer"]:
            u.own += 2 * larder()
        for u in [u for u in units() if u.cid == "sleeping_partner"]:
            if (r - u.since + 1) % 3 == 0:
                got = gain("stash")
                if has("mr_pym"):
                    last_unit().own += 2 * PYM * got
        # Fight: Sorrel makes Acorns when nothing fits behind her
        for s, u in board.items():
            if u and u.cid == "mrs_sorrel":
                behind = {"F1": ["B1"], "F2": ["B1", "B2"], "F3": ["B2", "B3"],
                          "F4": ["B3"]}.get(s, [])
                if all(board[b] for b in behind):
                    sorrel_due += 1.0 if r < 9 else 1.5
        out[r] = (sorted(((stats(u), u.cid) for u in units()), reverse=True), larder())
    return out


TYPICAL = {1: 3, 2: 8, 3: 15, 4: 24, 5: 34, 6: 52, 7: 70}
for _r in range(8, 17):
    TYPICAL[_r] = TYPICAL[_r - 1] * 1.5
TYPICAL.update(TARGET)


def curve(res):
    return {r: sum(v for v, _ in res[r][0]) for r in res}


for line, script in (("supper", SUPPER), ("parish", PARISH)):
    if LINE not in ("both", line):
        continue
    res = run(delay(script), line)
    if ARGS.get("curve") == "1":
        on = curve(run(script, line))
        globals()["LATE"] = 1
        late = curve(run(delay(script), line))
        globals()["LATE"] = int(ARGS.get("late", "0"))
        print(f"== {line} curve: board / typical, on time | one round late | mean")
        for r in range(4, 17):
            m = (on[r] + late[r]) / 2
            print(f"  R{r:2d} typical {TYPICAL[r]:6.0f}: {on[r]:6.0f} ({on[r]/TYPICAL[r]:.2f}x) | "
                  f"{late[r]:6.0f} ({late[r]/TYPICAL[r]:.2f}x) | {m:6.0f} ({m/TYPICAL[r]:.2f}x)")
        continue
    print(f"== {line} line: wake +{WAKE:g}x every {PERIOD}, food {FOOD:g}, "
          f"share {SHARE:g}, pym {PYM:g}, committee {COMMITTEE:g}, hayward {HAYWARD:g}")
    for r in (6, 9, 12, 15):
        board, lard = res[r]
        tot = sum(v for v, _ in board)
        big = board[0]
        print(f"R{r}: board {tot:7.0f}  typical {TARGET[r]:5d} ({tot / TARGET[r]:.2f}x)"
              f"  strong ~{TARGET[r] * 1.35:6.0f} ({tot / (TARGET[r] * 1.35):.2f}x)"
              f"  biggest {big[1]} {big[0]:.0f} ({big[0] / tot:.0%})  larder {lard}")
    if ARGS.get("units") == "1":
        for r in (6, 9, 12, 15):
            print(f"  R{r} units:", ", ".join(f"{n} {v:.0f}" for v, n in res[r][0]))
