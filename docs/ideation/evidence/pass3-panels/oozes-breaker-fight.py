"""Oozes pass 3 breaker: R12 fight probes.

Run:  python3 -I oozes-breaker-fight.py

Uses the carry designer's combat model (oozes-carry-model/ooze_combat3.py, an
extension of the audit's bramble_combat.py), loaded unchanged except that a
Belly may hold a list of units (the Pie's Belly 2): the first comes out into
the dead Ooze's slot, the rest into the nearest empty slots (8.4.1-8.4.2).
Near-deterministic like the audit's model: read for direction, not values.

Question: the engine (Simmer) and wild (Rise) designs put 46-57% of the board
inside back-row ovens behind small shells. Does that board beat a target-shaped
board of the same total, and how much does one stat-holding keyword on the riser
change it?
"""
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, "oozes-carry-model", "ooze_combat3.py")).read()
old = ('                    sp=u.kw["inside"]; nu=U(sp[0],sp[1],src,sp[2] if len(sp)>2 else None,start=False)\n'
       '                    place(s,nu,src,src)\n')
new = ('                    specs=u.kw["inside"] if isinstance(u.kw["inside"],list) else [u.kw["inside"]]\n'
       '                    for sp in specs:\n'
       '                        nu=U(sp[0],sp[1],src,sp[2] if len(sp)>2 else None,start=False)\n'
       '                        place(s,nu,src,src)\n')
assert old in src, "combat model changed; patch point not found"
ns = {}
exec(compile(src.replace(old, new), "ooze_combat3_listbelly", "exec"), ns)
match = ns["match"]


def total(board):
    t = 0
    for spec in board:
        if spec is None:
            continue
        t += spec[0] + spec[1]
        kw = spec[2] if len(spec) > 2 else {}
        ins = kw.get("inside")
        if ins:
            for sp in (ins if isinstance(ins, list) else [ins]):
                t += sp[0] + sp[1]
    return t


def scaled(board, k):
    out = []
    for spec in board:
        if spec is None:
            out.append(None)
            continue
        out.append((max(1, round(spec[0] * k)), max(1, round(spec[1] * k))) + tuple(spec[2:]))
    return out


# Slots: F1 F2 F3 F4 B1 B2 B3
EVEN = [(54, 54)] * 7                                    # 756
BG_FRONT = [(42, 42), (130, 130)] + [(42, 42)] * 5       # 764, carry 34% in F2
BG_BACK = [(42, 42)] * 5 + [(130, 130), (42, 42)]        # 764, carry 34% in B2


def engine_r12(riser_kw=None):
    """The engine designer's typical R12 board (final_model.py, typical_engine), placed:
    Elder in F3 lamping the Pie in F2; three back-row ovens. Supper +4/+4 on Oozes."""
    rk = dict(riser_kw or {})
    return [(6, 6, {"inside": (2, 3)}),                              # F1 Little Dollop [t1]
            (6, 9, {"inside": [(6, 9), (3, 4)]}),                    # F2 Sixpenny Pie [t4, Nell's unit]
            (8, 12, {"inside": (7, 12)}),                            # F3 Elder Ooze [t5]
            (14, 15),                                                # F4 Stone Soup
            (6, 8, {"inside": (28, 63)}),                            # B1 Frumenty [dough2]
            (10, 14, {"inside": (165, 228, rk)}),                    # B2 Granny [dough1, doubled]
            (6, 8, {"inside": (13, 18)})]                            # B3 Aunt Aspic [dough3]


def wild_r12(riser_kw=None, hasty=True):
    """The wild designer's carry line at R12 (oozes-wild-model.py, carry plan)."""
    rk = dict(riser_kw or {})
    return [(1, 4, {"inside": (16, 17)}),                            # F1 Wee Wobbly (Drips not modelled)
            (39, 47, {"swallow": 1}) if hasty else (39, 47),         # F2 Hasty Pudding
            (2, 3, {"inside": (15, 16)}),                            # F3 Stone Soup
            (3, 5),                                                  # F4 Moss Ooze
            (12, 14, {"inside": (168, 186, rk)}),                    # B1 Cut-and-Come-Again [riser]
            (2, 3),                                                  # B2 Dishwater Nell
            (11, 14, {"inside": [(48, 49), (43, 45)]})]              # B3 Sixpenny Pie [two risers]


def carry_r12(granny=True):
    """The carry designer's typical R12 board (oozes-carry.md section 5), as drawn."""
    o = {"ooze": 1}
    g = (20, 25, {"ooze": 1, "gather": 1, "cleave": 1}) if granny else (20, 25, dict(o))
    return [(34, 38, {"ooze": 1, "inside": [(30, 30), (30, 30)]}),   # F1 Sixpenny Pie [two Oozes]
            g,                                                       # F2 Granny Stir-Up
            (30, 34, dict(o)),                                       # F3 Moss Ooze
            (22, 28, dict(o)),                                       # F4 Elder Ooze
            (30, 32, dict(o)),                                       # B1 Dishwater Nell
            (156, 158, {"ooze": 1, "shield": 1, "bubble": 1, "inside": (22, 22)}),  # B2 Bubble and Squeak
            (30, 33, dict(o))]                                       # B3 Stone Soup


def row(label, board, n=2000):
    tb = total(board)
    cells = []
    for opp in (EVEN, BG_FRONT, BG_BACK):
        k = tb / total(opp)
        cells.append(match(board, scaled(opp, k), n)[0])      # equal totals
        cells.append(match(board, opp, n)[0])                 # against the R12 target (~760)
    print(f"  {label:44s} {tb:5d} | " + " | ".join(f"{a:5.1f} {b:5.1f}" for a, b in zip(cells[::2], cells[1::2])))


if __name__ == "__main__":
    print("Win % at R12. Each cell: same total as the Ooze board / against the 760 target board")
    print(f"  {'Ooze board':44s} total |   even 7x54   | BG carry in F2 | BG carry in B2")
    row("engine typical (riser in Granny, B2)", engine_r12())
    row("engine, riser has Shield (Syllabub)", engine_r12({"shield": 1}))
    row("engine, riser has Cleave", engine_r12({"cleave": 1}))
    row("engine, riser has Shield + Cleave", engine_r12({"shield": 1, "cleave": 1}))
    row("wild carry line, Hasty swallowing", wild_r12())
    row("wild carry line, no swallow", wild_r12(hasty=False))
    row("wild, riser has Cleave, no swallow", wild_r12({"cleave": 1}, hasty=False))
    row("carry design board as drawn (Granny gathers)", carry_r12())
    row("carry design board, no Granny gather", carry_r12(granny=False))
