"""Paper model for the Hunters pass 3 engine design (the Feast).

Run: python3 -I hunters-engine-model.py [s=0.1667] [round=up|down]
     [line=engine|tempo|both] [glutton=1] [laird_t=1] [units=1] [per_feast=1]

No fights are simulated. The model assumes:
- The lobby follows the target shape: per-unit stats level with today's
  bots to round 7, then x1.5 a round (U below).
- A quarry that falls is a typical front unit: 0.8 U, split 47% Attack, 53% Health.
- Each Take feeds every Feast point on the board: round(s*N*A) + round(s*N*H),
  rounded up by default.
- Takes per fight T(r) is a scripted schedule per line (see TAKES); the
  Laird adds laird_t Takes a fight from round 13 on the engine line.
- Feast gains land after each round's fight; flat growth is per fight.
It prints board totals at rounds 6, 9, 12, 15 and the biggest unit's share,
next to the target (typical = lobby median shape, strong = about 1.35x,
close to Battlegrounds' September 2025 means).
"""
import math
import sys

ARGS = dict(a.split("=", 1) for a in sys.argv[1:] if "=" in a)
S = float(ARGS.get("s", "0.1667"))
LINE = ARGS.get("line", "both")
ROUND = ARGS.get("round", "up")          # up | down: how a meal rounds
GLUTTON = int(ARGS.get("glutton", "1"))  # the Glutton's own Feast
LAIRD_T = float(ARGS.get("laird_t", "1"))  # extra Takes a fight from the Laird

U = {1: 3, 2: 4, 3: 5, 4: 6, 5: 6.8, 6: 7.5, 7: 10}
for r in range(8, 17):
    U[r] = U[r - 1] * 1.5

TAKES = {
    "engine": {1: 1, 2: 1, 3: 1.5, 4: 1.5, 5: 2, 6: 2, 7: 2.5, 8: 2.5, 9: 3, 10: 3,
               11: 3.5, 12: 3.5, 13: 3.5, 14: 3.5, 15: 3.5, 16: 3.5},
    "tempo": {1: 1, 2: 1, 3: 1.5, 4: 1.5, 5: 2, 6: 2, 7: 2.5, 8: 2.5, 9: 3, 10: 3,
              11: 3.5, 12: 3.5, 13: 4, 14: 4, 15: 4.5, 16: 4.5},
}


def meal(r, n):
    """Stats one Take gives a unit with Feast n in round r."""
    q = 0.8 * U[r]
    a, h = 0.47 * q, 0.53 * q
    f = math.ceil if ROUND == "up" else math.floor
    return f(S * n * a) + f(S * n * h)


# Each unit: name, base stats, buy round, sell round, feast schedule
# [(from_round, feast_points)], flat growth per fight [(from_round, stats)].
ENGINE = [
    ("Little Nip", 5, 1, 12, [], [(2, 1.2)]),
    ("Sable", 5, 3, 99, [(8, 1)], []),
    ("Mistress Russet", 6, 2, 99, [(8, 1)], []),
    ("The Toll-Bard", 6, 3, 11, [], []),
    ("The Lodger", 7, 5, 99, [(6, 1), (8, 2)], []),
    ("Old Brock", 8, 7, 99, [(8, 1)], []),
    ("Old Lutra", 7, 6, 99, [(8, 1), (11, 0)], []),
    ("The Mountain Glutton", 10, 10, 99, [(11, GLUTTON + 1)], []),
    ("The Laird of the Sett", 12, 12, 99, [(13, 1)], []),
]

TEMPO = [
    ("Sable", 5, 2, 10, [], []),
    ("Young Brock", 5, 1, 99, [], []),
    ("Little Nip", 5, 1, 99, [], [(2, 1.2)]),
    ("Wick", 5, 1, 99, [(8, 1)], [(2, 1.5)]),
    ("Brother Wolf", 7, 4, 99, [(8, 1)], []),
    ("The Lodger", 7, 5, 99, [(6, 1)], []),
    ("Grey Agnes", 9, 6, 10, [], []),
    ("Grizel", 11, 8, 99, [(8, 1)], []),
    ("Old Isegrim", 14, 11, 99, [(11, 1)], []),
    ("Old Lutra", 7, 9, 99, [], []),
]

# Isegrim's hunt: the biggest enemy (about 2.4 U) falls in about half the
# fights from round 12; every Feast point eats a share of it.
ISEGRIM_FROM = 12


def feast_at(sched, r):
    n = 0
    for start, pts in sched:
        if r >= start:
            n = pts
    return n


def run(units, line):
    stats = {}
    out = {}
    for r in range(1, 17):
        on = [u for u in units if u[2] <= r < u[3]]
        for u in on:
            stats.setdefault(u[0], u[1])
        # fight
        t = TAKES[line][r]
        if line == "engine" and r >= 13:
            t += LAIRD_T
        for name, base, buy, sell, sched, flat in on:
            n = feast_at(sched, r)
            gain = t * meal(r, n) if n else 0
            if line == "tempo" and r >= ISEGRIM_FROM and n:
                big = 2.4 * U[r]
                f = math.ceil if ROUND == "up" else math.floor
                gain += 0.5 * (f(S * n * 0.47 * big) + f(S * n * 0.53 * big))
            for start, g in flat:
                if r >= start:
                    gain += g
            stats[name] += gain
        # keep the seven biggest on board
        board = sorted(((stats[u[0]], u[0]) for u in on), reverse=True)[:7]
        out[r] = board
    return out


TARGET = {6: 52, 9: 158, 12: 531, 15: 1793}

# One Feast point held from a given round, on the engine line's Take schedule.
if ARGS.get("per_feast") == "1":
    for start in (6, 8, 9, 11, 13):
        tot, row = 0, []
        for r in range(1, 16):
            t = TAKES["engine"][r] + (LAIRD_T if r >= 13 else 0)
            if r >= start:
                tot += t * meal(r, 1)
            if r in (9, 12, 15):
                row.append(f"R{r} {tot:.0f}")
        print(f"one Feast from R{start}:", ", ".join(row))
    for r in (6, 8, 9, 10, 11, 12, 13, 14, 15):
        t = TAKES["engine"][r] + (LAIRD_T if r >= 13 else 0)
        print(f"  R{r}: U {U[r]:.0f}, meal {meal(r, 1)}, Takes {t}, per Feast a fight {t * meal(r, 1):.0f}")

for line, units in (("engine", ENGINE), ("tempo", TEMPO)):
    if LINE not in ("both", line):
        continue
    res = run(units, line)
    print(f"== {line} line, s = {S}")
    for r in (6, 9, 12, 15):
        board = res[r]
        tot = sum(v for v, _ in board)
        big = board[0]
        print(f"R{r}: board {tot:7.0f}  typical {TARGET[r]:5d} ({tot / TARGET[r]:.2f}x)"
              f"  strong ~{TARGET[r] * 1.35:6.0f} ({tot / (TARGET[r] * 1.35):.2f}x)"
              f"  biggest {big[1]} {big[0]:.0f} ({big[0] / tot:.0%})")
    if ARGS.get("units") == "1":
        for r in (9, 12, 15):
            print(f"  R{r} units:", ", ".join(f"{n} {v:.0f}" for v, n in res[r]))
    print("  meal per Take per Feast point:",
          ", ".join(f"R{r} {meal(r, 1)}" for r in (6, 8, 9, 12, 15)))
