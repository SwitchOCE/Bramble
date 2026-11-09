"""Rough hand model for the Bog folk pass 3 carry design (bog-carry.md).

Not a combat sim. It estimates what each card delivers per fight against a field
that follows the target shape (Battlegrounds' September 2025 means from round 6,
level with Bramble before that). Every number is a first guess for the lever sweep.

Run: python3 -I bog-carry-model.py [keep] [bitter] [king] [tiddy_round] [funnel]
  keep        Soak gain per Attack taken (the engine rate, default 1)
  bitter      Bitter's share of the biter's Attack, rounded up (the answer rate, default 0.25)
  king        the Peat King's Soak multiplier (default 2)
  tiddy_round the round Tiddy Mun (tier 4) is found (default 7)
  funnel      pass "funnel" to let the Peat King double Tiddy's funnel too (default: he doubles Soak only)

Typical carry board, average shops (7 slots):
  r1 Bridge Toad; r3 Madame Bufo; r5 Gideon, Warty Nan; r7 Tiddy Mun, Vaulting Hopkin;
  r8 His Highness (Nan sold; the Prince from r11); r9 Prima Donna (tier 5; Bufo kept);
  r11 Peat King (tier 6, replaces Hopkin). Stats are at the start of each round's fight,
  before Harvest Suppers. The opponent is the target field: carry 33% of the board,
  six even supports, 45% of stats in Attack.
"""
import math
import sys

KEEP = float(sys.argv[1]) if len(sys.argv) > 1 else 1.0
B = float(sys.argv[2]) if len(sys.argv) > 2 else 0.25
KING = float(sys.argv[3]) if len(sys.argv) > 3 else 2.0
TIDDY = int(sys.argv[4]) if len(sys.argv) > 4 else 7
KING_FUNNEL = (sys.argv[5] == "funnel") if len(sys.argv) > 5 else False

FIELD = {1: 5, 2: 11, 3: 18, 4: 26, 5: 38, 6: 53, 7: 79, 8: 123, 9: 194, 10: 305,
         11: 482, 12: 759, 13: 1177, 14: 1751, 15: 2600, 16: 3900}


def enemy(r):
    e = FIELD[r]
    n = min(7, r + 1)
    carry = 0.33 * e
    sup = (e - carry) / (n - 1)
    return {"E": e, "n": n, "Ac": 0.45 * carry, "Hc": 0.55 * carry,
            "As": 0.45 * sup, "Hs": 0.55 * sup}


def take(a):
    """Bitter: a quarter of the biter's Attack, rounded up; never below 1 Attack."""
    return 0 if a <= 1 else min(a - 1, math.ceil(B * a))


def all_takes(r):
    """Every Attack Bitter takes in a fight. The carry attacks 1.5 times, each support 1.4;
    repeat bites come at 3/4 Attack; 90% of enemy attacks land on Bitter units."""
    en = enemy(r)
    t = take(en["Ac"]) + 0.5 * take(0.75 * en["Ac"])
    t += (en["n"] - 1) * (take(en["As"]) + 0.4 * take(0.75 * en["As"]))
    return 0.9 * t


def three_patch(r):
    """Prima Donna over their back row: the carry bites ~1.3 times, two supports once."""
    en = enemy(r)
    return take(en["Ac"]) + 0.3 * take(0.75 * en["Ac"]) + 2 * take(en["As"])


def one_patch(r, bites=1.5):
    return bites * take(enemy(r)["As"])


class U:
    def __init__(self, name, a, h, soak=None):
        self.name, self.a, self.h, self.soak = name, a, h, soak

    def grow(self, g):
        self.a += g
        self.h += g

    def __repr__(self):
        return f"{self.a:.0f}/{self.h:.0f}"


def run(verbose=True):
    if verbose:
        print(f"keep={KEEP} bitter={B} (rounded up) king=x{KING} tiddy=r{TIDDY}")
        print("rnd field  carry    support | takes | Diva (who)          Toad     Gideon   Prima Donna"
              "  Prince    Hopkin  Sal each | Bog total  /field  biggest share")
    board = {"toad": U("Bridge Toad", 1, 3, "one")}
    out = {}
    for r in range(1, 17):
        en = enemy(r)
        if r == 3:
            board["bufo"] = U("Madame Bufo", 1, 4)
        if r == 5:
            board["gideon"] = U("Gideon", 2, 6, "two")
            board["nan"] = U("Warty Nan", 1, 3)
        if r == TIDDY:
            board["tiddy"] = U("Tiddy Mun", 3, 6)
        if r == 7:
            board["hopkin"] = U("Vaulting Hopkin", 3, 1)
        if r == 8:
            board.pop("nan", None)
            board["highness"] = U("His Highness", 3, 5)
        if r == 9:
            board["pd"] = U("Prima Donna", 2, 8, "three")
        if r == 11:
            board.pop("hopkin", None)
            board["king"] = U("Peat King", 5, 9, "one")
            board["highness"] = U("Prince Restored", 6, 7)   # third kiss r8-r10
        bog = [u for u in board.values() if u.name not in ("Prince Restored",)]
        diva = max(bog, key=lambda u: u.h)
        h = board.get("highness")
        prince = h if h is not None and h.name == "Prince Restored" else None
        if prince is not None:
            prince_view = U("Prince", 6 + diva.a // 2, 7 + diva.h // 2)
        front_attack = max(diva.a, board["toad"].a, board.get("gideon", U("", 0, 0)).a)
        mired = 4 if "pd" in board else (2 if "gideon" in board else 1)
        total = sum(u.a + u.h for u in board.values() if u.name != "Prince Restored")
        if prince is not None:
            total += prince_view.a + prince_view.h
        big = max(diva.a + diva.h, prince_view.a + prince_view.h if prince is not None else 0)
        out[r] = {"diva": (diva.a, diva.h), "total": total, "E": en["E"]}
        if verbose:
            print(f"{r:3d} {en['E']:5.0f} {en['Ac']:4.0f}/{en['Hc']:<4.0f} {en['As']:3.0f}/{en['Hs']:<4.0f}|"
                  f"{all_takes(r):6.1f} | {str(diva):>9} ({diva.name[:11]:<11})"
                  f" {str(board['toad']):>8} {str(board.get('gideon', '')):>9} {str(board.get('pd', '')):>11}"
                  f" {str(prince_view) if prince is not None else '':>9}"
                  f" {front_attack if 'hopkin' in board else '':>7} {diva.a // mired:>7.0f}"
                  f"  | {total:7.0f}  {total / en['E']:5.2f}  {big / total:5.2f}")
        # Growth from this fight.
        k = KING if "king" in board else 1.0
        tiddy = "tiddy" in board
        if tiddy:
            # Tiddy's funnel is not Soak, so the Peat King does not double it.
            diva.grow(KEEP * (k if KING_FUNNEL else 1.0) * all_takes(r))
        for key, u in board.items():
            if u.soak is None:
                continue
            own = {"one": one_patch(r), "two": one_patch(r, 2), "three": three_patch(r)}[u.soak]
            if tiddy and u is diva:
                # Her own takes are already in the funnel; the King adds his extra on top.
                u.grow(KEEP * (0 if KING_FUNNEL else k - 1) * own)
                continue
            u.grow(KEEP * k * own)
        # His Highness stays 3/5 until the Prince; the Prince's echo is recomputed each round.
    return out


if __name__ == "__main__":
    run()
