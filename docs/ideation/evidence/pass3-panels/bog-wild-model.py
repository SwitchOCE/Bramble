"""Bog folk pass 3, wild angle (bog-wild.md): expected-value model of the Swell engine.

Paper model, not a sim; the harness replaces it. It sizes the engine rate f
(the share of a sunk enemy's starting stats a Swell unit keeps) against the
target shape: level with today's boards to round 7, then about x1.5 a round.

Design modelled (bog-wild.md):
- Swell f on Gideon, Jenny, Prima Donna (three patches), Peat King, Lantern Man;
  Bridge Toad Swells f/2. Rounded down per stat.
- Warty Nan (Sink): each Mired enemy that dies also feeds your smallest Bog
  folk f/2 of its stats. Not a Swell, so Tiddy doesn't double it.
- Tiddy Mun: your Swells trigger twice.
- His Highness, Sink (5): the two units beside him double, then he becomes
  The Prince Restored, who doubles them again at Sink (REPEAT=15).
- The Peat King's Peatlings are combat only: modelled as +0.1 on answer.

Assumptions (stated so a critic can attack them):
- Enemy board B(t) is the target median. From round 6 its biggest unit holds a
  third of it; before that, 45%.
- Bog mirers sit across the biggest enemies, the carry first.
- Win chance w = 1 / (1 + (B_enemy / (B_bog * answer))^4). answer stands for
  the lock, Bitter 25%, Bufo, Sal and Jenny shrinking their carry: 1.15 by
  default, 1.3 tested. No penalty for overkill or over-concentration, so
  very tall carries are flattered.
- Bog wins: every Mired enemy dies. Bog loses: the Mired carry dies 20% of
  the time, other Mired enemies 60%.
- Bodies: tier 1-3 at today's printed stats; tier 4-6 arrive at the median
  enemy unit (the scale build's progression bar), the same for every tribe.
- Harvest Supper: +1/+1 at R5, R8 and R11. No gold accounting: lines are
  hand-written and somewhat generous before round 7.
Run: python3 -I bog-wild-model.py
"""
import math

ROUNDS = range(1, 17)
TIER = {"bridge_toad": 1, "young_pretender": 1, "warty_nan": 1, "madame_bufo": 2,
        "peat_cutter": 2, "vaulting_hopkin": 2, "gideon": 3, "natterjack_chorus": 3,
        "spitfire_sal": 3, "jenny_greenteeth": 4, "his_highness": 4,
        "signor_ranocchio": 4, "tiddy_mun": 5, "prima_donna": 5, "peat_king": 6,
        "lantern_man": 6}
PRINTED = {"bridge_toad": 4, "young_pretender": 5, "warty_nan": 4, "madame_bufo": 5,
           "peat_cutter": 6, "vaulting_hopkin": 4, "gideon": 8, "natterjack_chorus": 7,
           "spitfire_sal": 4, "jenny_greenteeth": 8, "his_highness": 8,
           "signor_ranocchio": 7, "tiddy_mun": 9, "prima_donna": 10, "peat_king": 14,
           "lantern_man": 12}

# (round placed, card id, role, round sold or None)
# carry/lantern: Swell, takes the biggest enemy; sink: Swell, next enemy;
# sink3: Swell on three; mire: Mire, no Swell; mire2: lends two Mires;
# nan; tiddy; king (Swell + Peatlings); highness; body (no Mire).
LINES = {
    "carry_strong": [
        (1, "bridge_toad", "sink", None), (2, "warty_nan", "nan", None),
        (3, "madame_bufo", "mire", 11), (4, "young_pretender", "body", 7),
        (5, "gideon", "carry", None), (6, "vaulting_hopkin", "body", 10),
        (7, "his_highness", "highness", None), (8, "jenny_greenteeth", "sink", None),
        (9, "tiddy_mun", "tiddy", None), (11, "lantern_man", "lantern", None)],
    "carry_typical": [
        (1, "bridge_toad", "sink", None), (2, "warty_nan", "nan", None),
        (3, "madame_bufo", "mire", 13), (4, "young_pretender", "body", 8),
        (6, "gideon", "carry", None), (7, "vaulting_hopkin", "body", 12),
        (9, "his_highness", "highness", None), (10, "jenny_greenteeth", "sink", None),
        (11, "tiddy_mun", "tiddy", None), (14, "lantern_man", "lantern", None)],
    "tempo_strong": [
        (1, "bridge_toad", "sink", None), (2, "warty_nan", "nan", None),
        (2, "young_pretender", "body", 6), (3, "madame_bufo", "mire", None),
        (4, "peat_cutter", "mire", 9), (5, "gideon", "carry", None),
        (6, "spitfire_sal", "body", 12), (6, "natterjack_chorus", "mire2", 10),
        (7, "jenny_greenteeth", "sink", None), (9, "prima_donna", "sink3", None),
        (10, "tiddy_mun", "tiddy", None), (12, "peat_king", "king", None)],
    "tempo_typical": [
        (1, "bridge_toad", "sink", None), (2, "warty_nan", "nan", None),
        (2, "young_pretender", "body", 7), (3, "madame_bufo", "mire", None),
        (4, "peat_cutter", "mire", 11), (6, "gideon", "carry", None),
        (6, "spitfire_sal", "body", 13), (7, "natterjack_chorus", "mire2", 12),
        (8, "jenny_greenteeth", "sink", None), (11, "prima_donna", "sink3", None),
        (12, "tiddy_mun", "tiddy", None), (14, "peat_king", "king", None)],
}


def target(t):
    today = {1: 5, 2: 10, 3: 17, 4: 26, 5: 37, 6: 50, 7: 65}
    return today[t] if t <= 7 else 65 * 1.5 ** (t - 7)


def enemy_units(t):
    n = min(7, max(1, t))
    b = target(t)
    if n == 1:
        return [b]
    big = b * (1 / 3 if t >= 6 else 0.45)
    return [big] + [(b - big) / (n - 1)] * (n - 1)


def win_prob(b_bog, b_enemy, answer):
    return 1 / (1 + (b_enemy / (b_bog * answer)) ** 4)


def body(card, t):
    med = target(t) / min(7, max(1, t))
    return max(PRINTED[card], round(med)) if TIER[card] >= 4 else PRINTED[card]


def supper(t):
    return 2 * sum(t >= r for r in (5, 8, 11))


def keep(stats, share):
    return 2 * math.floor(stats / 2 * share)


def run(line, f=0.5, answer=1.15, repeat=15, tiddy_mult=2):
    grown, base, sinks, breaks, rows, snaps = {}, {}, 0.0, 0, [], {}
    for t in ROUNDS:
        board = [c for c in line if c[0] <= t and (c[3] is None or c[3] > t)]
        while len(board) > 7:
            board.remove(next((c for c in board if c[2] == "body"), board[0]))
        for c in board:
            base.setdefault(c[1], body(c[1], c[0]))
        roles = {c[1]: c[2] for c in board}

        def stats():
            return {c[1]: base[c[1]] + supper(t) + grown.get(c[1], 0) for c in board}

        s = stats()
        b_bog, enemies = sum(s.values()), enemy_units(t)
        b_enemy = sum(enemies)
        w = win_prob(b_bog, b_enemy, answer + (0.1 if "king" in roles.values() else 0))
        mult = tiddy_mult if "tiddy" in roles.values() else 1
        order = sorted(range(len(enemies)), key=lambda i: -enemies[i])
        claim, slots = list(order), []
        for n, r in roles.items():
            if r in ("carry", "lantern") and claim:
                slots.append((claim.pop(0), n, True))
        for n, r in roles.items():
            k = {"sink": (1, True), "sink3": (3, True), "mire": (1, False),
                 "king": (1, True), "mire2": (2, False)}.get(r)
            for _ in range(k[0] if k else 0):
                if claim:
                    slots.append((claim.pop(0), n, k[1]))
        deaths = 0.0
        for idx, maker, swells in slots:
            p = w + (1 - w) * (0.2 if idx == order[0] else 0.6)
            deaths += p
            share = f / 2 if maker == "bridge_toad" else f
            if swells:
                grown[maker] = grown.get(maker, 0) + keep(enemies[idx], share) * p * mult
            if "nan" in roles.values():
                cur = stats()
                low = min(cur, key=cur.get)
                grown[low] = grown.get(low, 0) + keep(enemies[idx], f / 2) * p
        if "his_highness" in roles:
            sinks += deaths
            need = 5 if breaks == 0 else (repeat or 1e9)
            while sinks >= need:
                sinks -= need
                breaks += 1
                cur = stats()
                for v, k in sorted(((v, k) for k, v in cur.items() if k != "his_highness"),
                                   reverse=True)[:2]:
                    grown[k] = grown.get(k, 0) + v
                need = repeat or 1e9
        s = stats()
        after = sum(s.values())
        rows.append((t, round(b_enemy), round(b_bog), round(b_bog / b_enemy, 2),
                     round(w, 2), round(max(s.values()) / after, 2), round(deaths, 1)))
        if t in (9, 12, 15):
            snaps[t] = {k: round(v) for k, v in s.items()}
    return rows, snaps


if __name__ == "__main__":
    print("Board at fight / target median (biggest unit's share), Tiddy x2, Prince every 15")
    for f in (0.25, 0.35, 0.5):
        for ans in (1.15, 1.3):
            print("== Swell f = %.2f, answer %.2f" % (f, ans))
            for name, line in LINES.items():
                rows, _ = run(line, f, ans)
                print("  %-14s" % name + " ".join(
                    "R%d %.2f/%.2f" % (r[0], r[3], r[5]) for r in rows
                    if r[0] in (6, 8, 9, 10, 11, 12, 13, 15)))
    print()
    for name in LINES:
        rows, snaps = run(LINES[name], 0.5)
        print("== %s, f = 0.50: unit stats (Attack + Health) after the fight" % name)
        for t, s in snaps.items():
            print("  R%d (median unit %d, win %.2f):" % (t, target(t) / 7, rows[t - 1][4]),
                  ", ".join("%s %d" % kv for kv in sorted(s.items(), key=lambda kv: -kv[1])))
