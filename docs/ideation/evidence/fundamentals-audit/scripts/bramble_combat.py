"""A small Python model of Bramble's combat rules (rulebook ch. 9 + BRAMBLE ideation overrides),
for plain units plus a few optional keywords. No Godot. Mirrors src/core/combat/combat.gd:
  - 9.2.1 more units attacks first, tie random              (combat.gd _first_side)
  - 9.4.2/9.4.5 reading order F1-F4 then B1-B3, pointer + flags (combat.gd _choose_attacker)
  - 9.4.6 0-Attack units never attack; 9.4.10 a side with no attacker passes
  - 9.5.1/9.5.5 random target among enemy front row, else back row (combat_lanes.gd normal_targets)
  - 9.6.1 simultaneous exchange; 9.6.3 deaths after each damage step; 9.6.4 damage persists
  - 9.7 dying units leave slots; 9.8.2 reborn-style return into own slot (only if keyword used)
  - 9.9.2 Last Blow: a mutual wipe goes to the side that attacked in the final exchange
  - 9.10.1 200-attack limit -> tie
  - 10.1.4a hero damage = round base + winner's surviving starting units (we report survivors)
Optional keywords (NOT in the pass 2 slice unless noted): cleave, shield, reborn, venom,
windfury, dr (flat damage reduction), hunker (half damage when attacked), bitter (pass2:
attacker loses N Attack at declaration, down to 1), nightshade (defender loses half current
Health when attacked; slice Belladonna), immune_attacking (takes no damage while attacking).
Slots: 0-3 front (F1-F4), 4-6 back (B1-B3).
"""
import random

FRONT = (0, 1, 2, 3)
ADJ = ((1,), (0, 2), (1, 3), (2,), (5,), (4, 6), (5,))


class U:
    __slots__ = ("a", "h", "slot", "flag", "start", "kw", "base_a", "base_h", "reborn_used", "shield")

    def __init__(self, a, h, slot, kw=None, start=True):
        self.a = a
        self.h = h
        self.base_a = a
        self.base_h = h
        self.slot = slot
        self.flag = False
        self.start = start
        self.kw = kw or {}
        self.reborn_used = False
        self.shield = bool(self.kw.get("shield"))


def make_side(board):
    """board: list of 7 entries, None or (a, h) or (a, h, kw_dict)."""
    side = {}
    for slot, spec in enumerate(board):
        if spec is None:
            continue
        kw = spec[2] if len(spec) > 2 else None
        side[slot] = U(spec[0], spec[1], slot, kw)
    return side


def fight(board0, board1, rng, attack_limit=200, first=None):
    sides = [make_side(board0), make_side(board1)]
    if first is None:
        n0, n1 = len(sides[0]), len(sides[1])
        first = 0 if n0 > n1 else 1 if n1 > n0 else rng.randint(0, 1)
    pointer = [-1, -1]
    attacks = 0
    last_blow = -1
    active = first

    def can_attack(u):
        return u.a > 0

    def choose_attacker(s):
        units = [sides[s][k] for k in sorted(sides[s])]
        ready = [u for u in units if can_attack(u)]
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
        enemy = sides[1 - s]
        front = [enemy[k] for k in sorted(enemy) if k in FRONT]
        cands = front if front else [enemy[k] for k in sorted(enemy)]
        return cands[rng.randrange(len(cands))] if cands else None

    def hit(target, amount, attacking=False, attacked=False):
        if amount <= 0:
            return
        kw = target.kw
        if attacking and kw.get("immune_attacking"):
            return
        if attacked and kw.get("hunker"):
            amount = (amount + 1) // 2
        amount -= kw.get("dr", 0)
        if amount <= 0:
            return
        if target.shield:
            target.shield = False
            return
        target.h -= amount

    def resolve_deaths(s_active):
        for s in (s_active, 1 - s_active):
            dead = [u for u in list(sides[s].values()) if u.h <= 0]
            for u in dead:
                del sides[s][u.slot]
            for u in dead:
                if u.kw.get("reborn") and not u.reborn_used and u.slot not in sides[s]:
                    r = U(u.base_a, 1, u.slot, dict(u.kw), start=u.start)
                    r.reborn_used = True
                    r.shield = False
                    r.flag = u.slot < pointer[s]
                    sides[s][u.slot] = r

    def one_attack(s, att):
        nonlocal last_blow
        d = choose_target(s)
        if d is None:
            return
        # Bitter (pass 2 code: at declaration, before damage, down to 1)
        if d.kw.get("bitter"):
            att.a = max(1, att.a - d.kw["bitter"]) if att.a > 1 else att.a
        # Nightshade: defender first loses half its current Health (not damage, never kills)
        if d.kw.get("nightshade"):
            d.h -= d.h // 2
        out_amt = att.a
        back_amt = d.a
        venom_out = att.kw.get("venom")
        venom_back = d.kw.get("venom")
        h_before_d, h_before_a = d.h, att.h
        sh_d, sh_a = d.shield, att.shield
        hit(d, out_amt, attacked=True)
        if att.kw.get("cleave"):
            for k in ADJ[d.slot]:
                v = sides[1 - s].get(k)
                if v is not None:
                    hv, shv = v.h, v.shield
                    hit(v, out_amt)
                    if venom_out and v.h < hv and not shv:
                        v.h = 0
        hit(att, back_amt, attacking=True)
        if venom_out and d.h < h_before_d:
            d.h = 0
        if venom_back and att.h < h_before_a:
            att.h = 0
        last_blow = s
        resolve_deaths(s)

    while True:
        if not sides[0] or not sides[1]:
            break
        if not any(can_attack(u) for u in sides[0].values()) and not any(
            can_attack(u) for u in sides[1].values()
        ):
            return {"winner": -1, "reason": "no_attacks", "survivors": 0, "attacks": attacks}
        if attacks >= attack_limit:
            return {"winner": -1, "reason": "attack_limit", "survivors": 0, "attacks": attacks}
        att = choose_attacker(active)
        if att is not None:
            attacks += 1
            one_attack(active, att)
            if att.kw.get("windfury") and att.slot in sides[active] and sides[active][att.slot] is att:
                if sides[1 - active]:
                    attacks += 1
                    one_attack(active, att)
        active = 1 - active
    if sides[0] and not sides[1]:
        w = 0
    elif sides[1] and not sides[0]:
        w = 1
    else:
        w = last_blow  # Last Blow
        return {"winner": w, "reason": "last_blow", "survivors": 0, "attacks": attacks}
    surv = sum(1 for u in sides[w].values() if u.start)
    return {"winner": w, "reason": "board_empty", "survivors": surv, "attacks": attacks}


def match(b0, b1, n=2000, seed=1):
    """Win/tie rates of b0 vs b1, sides swapped each pair (as the R9 round robin does)."""
    rng = random.Random(seed)
    w = t = l = 0
    surv = 0
    lb = 0
    for i in range(n):
        if i % 2 == 0:
            r = fight(b0, b1, rng)
            me = 0
        else:
            r = fight(b1, b0, rng)
            me = 1
        if r["winner"] == me:
            w += 1
            surv += r["survivors"]
        elif r["winner"] == -1:
            t += 1
        else:
            l += 1
        if r["reason"] == "last_blow":
            lb += 1
    return {"win": w / n, "tie": t / n, "loss": l / n, "surv_when_win": (surv / w if w else 0), "last_blow": lb / n}


def lives(board, enemy_attack):
    """Hits a board can take from a uniform enemy attack value (plain units)."""
    return sum(-(-spec[1] // enemy_attack) for spec in board if spec is not None)
