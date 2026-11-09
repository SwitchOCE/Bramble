"""Paper model of the Fairies pass 3 engine (carry and answers angle), v3.
Design: fairies-carry.md in this folder.

Not a game sim: no shops, no fights, no opponents. It plays scripted lines on one board and
reports combat-start stats (Attack + Health summed over the 7 slots) after each round's End of
Turn. Combat-only effects (Changeling, Nightshade, Hex, Cleave, Shield, the Wisp refill,
Reel-Mistress's dance) are not in the totals; Cradle Fetch's half Ring is.

Engine:
  Glamour G starts at g0 (1). "Ring a slot" adds +G/+G to it. No cap.
  Old Moth Annis (T4): End of Turn, Glamour +r (golden 2r).
  Silky (T3): after a Shy unit leaves (Silky counts too), Ring its slot and Glamour +r.
  Fairy Monarch (T6): after you Ring a slot, Glamour +mr (golden 2mr).
  Sally Spore (T2): End of Turn, Ring this slot (golden twice).
  Lob-Lie-by-the-Fire (T3, Shy): End of Turn, Ring the slots beside this (golden twice).
  Nan Toadstool (T1): when played, Ring a slot next to this (golden twice).
  Spore Cloud (neutral spell, 2 gold): Ring a slot sp times (proposed sp = 2).
  Queen of Elfland (T6): every qp-th End of Turn, destroy the units behind her, double your
    biggest Ring (golden x4).
  Cradle Fetch (T2, front row): Start of Combat, gains half the biggest Ring behind it.
  Shy units get nothing from Rings.
Defaults: r=1 mr=1 sp=2 qp=3 g0=1 cap=50 (the carry line's share rule for Ring spells).
Usage: python3 -I fairies-carry-model.py [r=1] [mr=1] [sp=2] [qp=3] [g0=1] [cap=50] [line=all|<name>]
"""
import sys

INFRONT = {"B1": ["F1", "F2"], "B2": ["F2", "F3"], "B3": ["F3", "F4"]}
BEHIND = {"F1": ["B1"], "F2": ["B1", "B2"], "F3": ["B2", "B3"], "F4": ["B3"]}
BESIDE = {"F1": ["F2"], "F2": ["F1", "F3"], "F3": ["F2", "F4"], "F4": ["F3"],
          "B1": ["B2"], "B2": ["B1", "B3"], "B3": ["B2"]}
ORDER = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]

# name: (attack, health, fairy, shy). Pass 3 printed stats; neutral fillers by tier.
BASE = {
    "nan": (2, 1, 1, 0), "chaser": (1, 3, 1, 0), "witch": (1, 3, 1, 0),
    "sally": (1, 3, 1, 0), "hob": (1, 4, 1, 1), "fetch": (2, 3, 1, 0),
    "lob": (2, 3, 1, 1), "silky": (3, 4, 1, 1), "clur": (3, 4, 1, 0),
    "annis": (3, 6, 1, 0), "will": (3, 6, 1, 0), "changeling": (2, 4, 1, 0),
    "bella": (4, 8, 1, 0), "reel": (4, 7, 1, 0), "monarch": (5, 7, 1, 0), "queen": (8, 8, 1, 0),
    "n2": (3, 4, 0, 0), "n3": (4, 5, 0, 0), "n4": (5, 6, 0, 0), "n5": (5, 8, 0, 0),
    "token": (1, 1, 1, 0),
}


class Unit:
    def __init__(self, name, golden=False):
        a, h, f, s = BASE[name]
        k = 2 if golden else 1
        self.name, self.golden = name, golden
        self.a, self.h, self.fairy, self.shy = a * k, h * k, f, s
        self.played = None

    def __repr__(self):
        return self.name + ("*" if self.golden else "")


def run(line, P, label, verbose=False):
    st = {"G": P["g0"]}
    ring = {s: 0 for s in ORDER}
    board = {s: None for s in ORDER}
    supper = 0
    out = {}

    def ring_mult():
        if P.get("mode", 0) != 1:
            return 1
        best = 1
        for u in board.values():
            if u and u.name == "monarch":
                best = max(best, (P["mon"] + 1) if u.golden else P["mon"])
        return best

    def do_ring(slot, times=1):
        for _ in range(times * ring_mult()):
            ring[slot] += st["G"]
            if P.get("mode", 0) == 0:
                for u in board.values():
                    if u and u.name == "monarch":
                        st["G"] += P.get("mr", 1) * (2 if u.golden else 1)

    def biggest_ring():
        return max(ORDER, key=lambda s: (ring[s], -ORDER.index(s)))

    for rnd in range(1, 17):
        for act in line.get(rnd, []):
            op = act[0]
            if op == "play":
                _, name, slot, *rest = act
                golden = "golden" in rest
                u = Unit(name, golden)
                u.played = rnd
                board[slot] = u
                if name == "nan":
                    target = next((x for x in rest if x in ORDER), slot)
                    do_ring(target, 2 if golden else 1)
            elif op == "sell":
                board[act[1]] = None
            elif op == "move":
                _, a, b = act
                board[a], board[b] = board[b], board[a]
            elif op == "spell_ring":
                do_ring(act[1], P.get("sp", 1))
            elif op == "spell_smart":
                _, cs, alt = act
                tot = sum((u.a + u.h + (0 if u.shy else 2 * ring[x])) for x, u in board.items() if u)
                cu = board[cs]
                cshare = ((cu.a + cu.h + 2 * ring[cs]) / tot) if (cu and tot) else 0
                do_ring(cs if cshare < P.get("cap", 50) / 100 else alt, P.get("sp", 1))
            elif op == "thank":  # an aimed spell on a Shy unit: it leaves
                slot = act[1]
                leaving = board[slot]
                silkies = [u for u in board.values() if u and u.name == "silky"]
                board[slot] = None
                for u in silkies:  # Silky counts herself too
                    do_ring(slot, 2 if u.golden else 1)
                    st["G"] += P["r"] * (2 if u.golden else 1)
            elif op == "supper":
                supper = min(3, supper + 1)
        # End of Turn, reading order
        for s in ORDER:
            u = board[s]
            if not u:
                continue
            k = 2 if u.golden else 1
            if u.name == "annis":
                st["G"] += P["r"] * k
            elif u.name == "sally":
                do_ring(s, k)
            elif u.name == "lob":
                for t in BESIDE[s]:
                    do_ring(t, k)
            elif u.name == "queen" and (rnd - u.played) % P.get("qp", 3) == P.get("qp", 3) - 1:
                behind = [b for b in BEHIND.get(s, []) if board[b]]
                if behind:
                    for b in behind:
                        board[b] = None
                    bslot = biggest_ring()
                    ring[bslot] *= 4 if u.golden else 2
                else:
                    board[s] = None
        # combat-start snapshot
        total, units = 0, []
        for s in ORDER:
            u = board[s]
            if not u:
                continue
            ra = rh = 0 if u.shy else ring[s]
            if u.name == "fetch" and s in BEHIND:
                bigb = max((ring[b] for b in BEHIND[s]), default=0)
                add = bigb if u.golden else bigb // 2
                ra += add
                rh += add
            sup = supper if u.fairy else 0
            a, h = u.a + ra + sup, u.h + rh + sup
            units.append((s, repr(u), a, h))
            total += a + h
        big = max((a + h for _, n, a, h in units), default=0)
        out[rnd] = dict(total=total, G=st["G"], big=big, share=big / total if total else 0, units=units,
                        idle=sum(2 * ring[s] for s in ORDER if not board[s] and ring[s]))
        if verbose and rnd in (6, 9, 12, 15):
            print(f"  {label} R{rnd}: total {total}, Glamour {st['G']}, biggest {big} ({big/total:.0%})")
            print("      " + ", ".join(f"{s} {n} {a}/{h}" for s, n, a, h in units))
    return out


# ---------------------------------------------------------------- lines
# Tiers: T1 Nan, Chaser, Witch. T2 Sally, Hob, Fetch. T3 Lob, Silky, Cluricaun.
# T4 Annis, Will, Changeling. T5 Belladonna, Reel-Mistress. T6 Monarch, Queen.
# Sally rings her own slot each End of Turn. Lob (Shy) rings the slots beside it.
# Carry slot B2 (the throne). Lob in B1 rings B2 only. Hob in B3 shields F3 and F4.

# Back-row carry, typical: T2 R3, T3 R5, T4 R7, T5 R10, T6 R12 (Queen), R13 (Monarch).
# Ring spells go to the carry while it holds under half the board, else to Sally's slot.
CARRY_TYP = {
    1: [("play", "nan", "F2", "B2")],
    2: [("play", "n2", "F1")],
    3: [("play", "sally", "B2")],
    4: [("play", "hob", "B3"), ("play", "n2", "F3")],
    5: [("play", "lob", "B1"), ("spell_smart", "B2", "F3")],
    6: [("play", "silky", "F4"), ("supper",)],
    7: [("thank", "F4"), ("play", "annis", "F4"), ("spell_smart", "B2", "F3")],
    8: [("sell", "F1"), ("play", "will", "F1"), ("spell_smart", "B2", "F3")],
    9: [("sell", "F2"), ("play", "clur", "F2"), ("supper",), ("spell_smart", "B2", "F3")],
    10: [("sell", "F3"), ("move", "B2", "F3"), ("play", "bella", "B2"), ("spell_smart", "B2", "F3")],
    11: [("spell_smart", "B2", "F3"), ("spell_smart", "B2", "F3")],
    12: [("sell", "B3"), ("play", "token", "B3"), ("sell", "F1"), ("play", "queen", "F4"),
         ("move", "F4", "F1"), ("spell_smart", "B2", "F3"), ("supper",)],
    13: [("play", "monarch", "F4"), ("spell_smart", "B2", "F3")],
    14: [("play", "token", "B3"), ("spell_smart", "B2", "F3"), ("spell_smart", "B2", "F3")],
    15: [("play", "token", "B3"), ("spell_smart", "B2", "F3"), ("spell_smart", "B2", "F3")],
    16: [("play", "token", "B3"), ("spell_smart", "B2", "F3")],
}
# R12: Annis (F4) and the Queen trade places: the Queen goes to F1? F1 has only B1 (Lob) behind.
# Line choice: Will out, Queen in F4 tithes B3 (a token); Annis moves to F1.
CARRY_TYP[12] = [("sell", "B3"), ("play", "token", "B3"), ("move", "F4", "F1"), ("play", "queen", "F4"),
                 ("spell_smart", "B2", "F3"), ("supper",)]
CARRY_TYP[13] = [("sell", "F1"), ("play", "monarch", "F1"), ("spell_smart", "B2", "F3")]   # Annis out

# Back-row carry without the Queen: keep Will and add Cradle Fetch in front of the throne.
CARRY_NOQ = dict(CARRY_TYP)
CARRY_NOQ[11] = [("sell", "F2"), ("play", "fetch", "F2"), ("move", "F1", "F1"),
                 ("spell_smart", "B2", "F3"), ("spell_smart", "B2", "F3")]   # Cluricaun moves to F4? see 12
CARRY_NOQ[12] = [("sell", "F4"), ("play", "clur", "F4"), ("spell_smart", "B2", "F3"), ("supper",)]  # Annis out
CARRY_NOQ[13] = [("sell", "B3"), ("play", "monarch", "B3"), ("spell_smart", "B2", "F3")]           # Hob out
CARRY_NOQ[14] = [("spell_smart", "B2", "F3"), ("spell_smart", "B2", "F3")]
CARRY_NOQ[15] = [("spell_smart", "B2", "F3"), ("spell_smart", "B2", "F3")]
CARRY_NOQ[16] = [("spell_smart", "B2", "F3")]

# Back-row carry, highroll: T2 R2, T3 R4, T4 R6, T5 R8, T6 R10; golden Sally R7; Monarch R10; Queen R11.
CARRY_HIGH = {
    1: [("play", "nan", "F2", "B2")],
    2: [("play", "sally", "B2")],
    3: [("play", "hob", "B3"), ("play", "n2", "F3")],
    4: [("play", "lob", "B1"), ("play", "silky", "F4")],
    5: [("thank", "F4"), ("play", "n3", "F4"), ("spell_smart", "B2", "F2"), ("supper",)],
    6: [("sell", "F4"), ("play", "annis", "F4"), ("play", "will", "F1")],
    7: [("sell", "B2"), ("play", "sally", "B2", "golden"), ("spell_smart", "B2", "F2")],
    8: [("sell", "F3"), ("play", "clur", "F3"), ("supper",), ("spell_smart", "B2", "F2")],
    9: [("move", "B2", "F2"), ("sell", "B2"), ("play", "bella", "B2"), ("spell_smart", "B2", "F2")],
    10: [("sell", "F3"), ("play", "monarch", "F3"), ("spell_smart", "B2", "F2"), ("spell_smart", "B2", "F2")],
    11: [("sell", "F1"), ("play", "queen", "F1"), ("sell", "B1"), ("play", "token", "B1"),
         ("spell_smart", "B2", "F2"), ("supper",)],
    12: [("play", "will", "B1"), ("spell_smart", "B2", "F2"), ("spell_ring", "F2")],
    13: [("play", "token", "B1"), ("spell_smart", "B2", "F2"), ("spell_ring", "F4")],
    14: [("play", "token", "B1"), ("spell_smart", "B2", "F2"), ("spell_ring", "F2")],
    15: [("play", "token", "B1"), ("spell_smart", "B2", "F2"), ("spell_ring", "F4")],
    16: [("play", "token", "B1"), ("spell_smart", "B2", "F2")],
}

# Fast climb without luck: the highroll's tiers, no golden Sally, Monarch one turn later.
CARRY_FAST = {k: list(v) for k, v in CARRY_HIGH.items()}
CARRY_FAST[7] = [("sell", "F3"), ("play", "clur", "F3"), ("spell_smart", "B2", "F2")]
CARRY_FAST[8] = [("supper",), ("spell_smart", "B2", "F2")]
CARRY_FAST[9] = [("move", "B2", "F2"), ("play", "bella", "B2"), ("spell_smart", "B2", "F2")]
CARRY_FAST[10] = [("spell_smart", "B2", "F2"), ("spell_smart", "B2", "F2")]
CARRY_FAST[11] = [("sell", "F3"), ("play", "monarch", "F3"), ("spell_smart", "B2", "F2"), ("supper",)]
CARRY_FAST[12] = [("sell", "F1"), ("play", "queen", "F1"), ("sell", "B1"), ("play", "token", "B1"),
                  ("spell_smart", "B2", "F2")]
CARRY_FAST[13] = [("play", "will", "B1"), ("spell_smart", "B2", "F2")]

# Wide line (the Long Dance), typical: two Sallies growing walls, Lob in a row's middle.
WIDE_TYP = {
    1: [("play", "nan", "F2", "F2")],
    2: [("play", "n2", "F1")],
    3: [("play", "sally", "F3")],
    4: [("play", "hob", "B1"), ("play", "n2", "F4")],
    5: [("play", "lob", "B2"), ("spell_ring", "F1")],           # Lob B2 rings B1 (Hob: wasted), B3
    6: [("play", "sally", "B3"), ("supper",)],
    7: [("sell", "F4"), ("play", "annis", "F4"), ("spell_ring", "F2")],
    8: [("sell", "F1"), ("play", "will", "F1"), ("spell_ring", "F4")],
    9: [("sell", "B1"), ("play", "silky", "B1"), ("supper",)],
    10: [("thank", "B1"), ("play", "reel", "B1"), ("spell_ring", "F3")],
    11: [("sell", "F2"), ("play", "bella", "F2"), ("spell_ring", "F4")],
    12: [("sell", "F4"), ("play", "monarch", "F4"), ("spell_ring", "B1"), ("supper",)],
    13: [("spell_ring", "F2"), ("spell_ring", "F1")],
    14: [("sell", "B2"), ("play", "lob", "B2", "golden"), ("spell_ring", "B1")],
    15: [("spell_ring", "F3"), ("spell_ring", "F2")],
    16: [("spell_ring", "F1")],
}

# Tempo line: early bodies, Rings where they land, answers; Glamour clock late.
TEMPO = {
    1: [("play", "nan", "F1", "F1")],
    2: [("play", "n2", "F2")],
    3: [("play", "hob", "B1"), ("play", "n2", "F3")],
    4: [("play", "sally", "F4")],
    5: [("play", "fetch", "B2"), ("spell_ring", "F1")],
    6: [("sell", "F3"), ("play", "changeling", "F3"), ("supper",)],
    7: [("play", "will", "B3")],
    8: [("sell", "F2"), ("play", "n4", "F2"), ("spell_ring", "F1")],
    9: [("sell", "B2"), ("play", "bella", "B2"), ("supper",)],
    10: [("sell", "B1"), ("play", "annis", "B1"), ("spell_ring", "F2")],
    11: [("sell", "F1"), ("play", "n5", "F1"), ("spell_ring", "F1")],
    12: [("sell", "F2"), ("play", "queen", "F2"), ("play", "token", "B2"), ("spell_ring", "F1"), ("supper",)],
    13: [("spell_ring", "F1"), ("spell_ring", "F4")],
    14: [("spell_ring", "F1"), ("spell_ring", "F4")],
    15: [("spell_ring", "F1"), ("spell_ring", "F3")],
    16: [("spell_ring", "F1")],
}


def main():
    P = dict(r=1, g0=1, mon=2, mode=0, mr=1, sp=2, qp=3, cap=50)
    line = "none"
    for arg in sys.argv[1:]:
        k, v = arg.split("=")
        if k == "line":
            line = v
        else:
            P[k] = int(v)
    lines = {"carry_typ": CARRY_TYP, "carry_noq": CARRY_NOQ, "carry_high": CARRY_HIGH, "carry_fast": CARRY_FAST, "wide_typ": WIDE_TYP, "tempo": TEMPO}
    target = {6: "52/60", 9: "150/200", 12: "500/700", 15: "1700/2400"}
    print(f"params {P}")
    print("round | " + " | ".join(f"{k:<22}" for k in lines) + " | target median/strong")
    res = {k: run(v, P, k) for k, v in lines.items()}
    for rnd in range(3, 17):
        row = [f"{res[k][rnd]['total']:>5} G{res[k][rnd]['G']:>3} top{res[k][rnd]['share']:>4.0%}{'':>4}"
               for k in lines]
        print(f"R{rnd:>2}   | " + " | ".join(row) + f" | {target.get(rnd, '')}")
    if line != "none":
        for k, v in lines.items():
            if line in ("all", k):
                run(v, P, k, verbose=True)


if __name__ == "__main__":
    main()
