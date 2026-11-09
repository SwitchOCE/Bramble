"""Paper model of the Quilboar Choose One line on Bramble's economy (no Godot).

Bramble rules used: income 3..10 (R8+), carry-over gold, units 3 gold, Bought sells 1 / Created 0,
upgrade costs 5/7/8/11/11 with -1 a turn, 7 slots. Board = recruit board at combat start
(permanent stats only; combat-only gems from Tusker/Bonker/Camper are not counted, as in
reference-curves column C's snapshot after Start of Combat).

Axes (owner's 'trivariate scaling'):
  count  = gems and Choose One cards gained per turn (gem makers, Gem Rat, Tunneler, shop cycling)
  apps   = recipients/extra casts per gem event (Hogrider: N gems on every Quilboar)
  size   = gem size (Gem Day, Foodie, Refiner per attack, Champion)
  time   = size and count that grow each fight with no gold (Refiner, Champion deaths, Tunneler, Rat)

Usage: python3 -I qmodel.py
"""
import itertools, json, sys, math

TARGET = {6: 52, 9: 150, 12: 500, 15: 1700}
INCOME = {1: 3, 2: 4, 3: 5, 4: 6, 5: 7, 6: 8, 7: 9}
UPCOST = {2: 5, 3: 7, 4: 8, 5: 11, 6: 11}

# BG 37.0.2 bodies (Bramble keeps them)
BODY = {
    'geomancer': (1, 2, 1), 'camper': (1, 2, 3), 'crater_miner': (2, 2, 2), 'tusker': (2, 2, 5),
    'roadboar': (2, 2, 4), 'foodie': (3, 2, 4), 'gem_rat': (3, 4, 4), 'bandit': (3, 3, 3),
    'sly': (3, 4, 5), 'trailblazer': (3, 4, 5), 'trench': (3, 3, 3), 'bonker': (4, 2, 7),
    'tunneler': (4, 3, 6), 'roogug': (4, 4, 6), 'flapper': (4, 5, 3), 'trapper': (4, 4, 4),
    'surveyor': (5, 3, 7), 'felboar': (5, 2, 6), 'vineweaver': (5, 4, 4), 'refiner': (5, 3, 8),
    'champion': (6, 9, 4), 'hogrider': (6, 6, 8), 'brigand': (6, 8, 8), 'geomant': (6, 10, 10),
    'flex1': (1, 2, 3), 'flex2': (2, 3, 4), 'flex3': (3, 4, 4),
}
QUIL = {k for k in BODY if not k.startswith('flex')}
SELL_RANK = ['flex1', 'flex2', 'flex3', 'crater_miner', 'trapper', 'foodie', 'sly', 'camper', 'tusker', 'geomancer', 'roadboar', 'bandit', 'bonker', 'flapper', 'roogug', 'trench', 'trailblazer', 'gem_rat', 'vineweaver', 'surveyor', 'felboar', 'brigand', 'geomant', 'champion', 'refiner', 'tunneler', 'hogrider']
CHOOSE_ONE = {'crater_miner', 'foodie', 'sly', 'trapper', 'brigand'}


class Dials:
    def __init__(self, **kw):
        self.gem0 = (1.0, 1.0)      # base Blood Gem
        self.size_step = 1.0        # multiplier on every 'your Blood Gems give an extra' step
        self.refiner = (1, 1)       # 37.0.2
        self.champion = (2, 1)
        self.hog_gems = 2           # Hogrider gems per Choose One card, per Quilboar
        self.hog_others = False     # 36.4 text: 'your other Quilboar'
        self.brigand_gems = 3       # Veteran Brigand: gems on all your minions
        self.geomancer_gems = 2; self.miner_gems = 2; self.foodie_gems = 4; self.sly_gems = 3; self.roadboar_gems = 1
        self.foodie_size = (1, 1)
        self.supper_rounds = (7, 9, 11)
        self.gem_mult = 1.0         # multiplier on printed gem counts (Geomancer 2, Miner 2, Foodie 4 ...)
        self.tunneler_cards = 1     # cards per Rally
        self.rat_days = 1
        self.confiscation = 3
        self.rally_attacks = {8: 1.5, 99: 2.0}   # Rally attacks per fight by round (back-row unit)
        self.champion_dies = 0.5
        self.cycle_cost = 4.5       # net gold per shop Choose One cycle: buy 3, sell +1, ~2.5 refreshes to find one (about 0.35 Choose One units a shop at T5-6)
        self.cycle_find_cap = None  # most shop Choose One cards found a turn (None: the line's own)
        # ablations
        self.count_off = False      # no card or gem generators beyond printed Battlecry/Choose One on bought units
        self.apps_off = False       # Hogrider's gems go on one unit; no multi-recipient effects
        self.size_off = False       # gem size frozen at gem0
        self.rational_off = False; self.created_sell = 0; self.conf_cost = 0; self.tun_once = False
        self.time_off = False       # no per-fight growth: Refiner, Champion deaths, Tunneler, Roadboar
        # final-doc fixes and options
        self.hog_after = False      # Hogrider fires after the chosen mode resolves (BG: 'After you play')
        self.trapper_bg = False     # Snare Trapper: +1 gold every turn (engine income query), not the 4.1.4 ceiling
        self.round_up = False       # each gem gives the gem size rounded up (halves presets)
        # gems-from-hand line
        self.geomant_gems = 6; self.bandit_gems = 3; self.roogug_n = 1; self.surveyor_extra = 1; self.balinda = False
        self.__dict__.update(kw)


def rally(d, r):
    for cap, v in sorted(d.rally_attacks.items()):
        if r <= cap:
            return v


LINES = {
    # Arrivals stand in for the shop. The typical line follows the guides' Choose One plan and the
    # final-board frequencies (Firestone, 40 boards: Hogrider 40, Tunneler 39, Gem Rat 20, Refiner 15;
    # perfect games: Hogrider 100%, Tunneler 86%, Gem Rat 58%, Refiner 47%).
    'typical': {
        'climb': {2: 2, 3: 4, 4: 6, 5: 9, 6: 11},
        'buys': {1: ['geomancer'], 3: ['roadboar'], 4: ['flex3'], 5: ['crater_miner', 'gem_rat'],
                 6: ['trench'], 7: ['tunneler', 'foodie', 'trailblazer'], 8: ['sly', 'flex3', 'trapper'],
                 9: ['refiner', 'foodie'], 10: ['tunneler', 'foodie', 'sly'],
                 11: ['hogrider'], 12: ['foodie'], 13: ['champion'], 14: ['tunneler'], 15: []},
        'golden': {14: 'tunneler'},
        'cycle_cap': 4,
    },
    # every piece on time, two Rats, golden Tunneler R11, second Hogrider R12 (the example board shape)
    'strong': {
        'climb': {2: 2, 3: 4, 4: 6, 5: 8, 6: 10},
        'buys': {1: ['geomancer'], 3: ['roadboar'], 4: ['gem_rat'], 5: ['crater_miner', 'foodie'],
                 6: ['tunneler'], 7: ['trailblazer', 'trench', 'foodie'], 8: ['refiner'],
                 9: ['tunneler', 'sly', 'gem_rat'], 10: ['hogrider'], 11: ['tunneler', 'champion'],
                 12: ['hogrider'], 13: ['refiner'], 14: [], 15: []},
        'golden': {11: 'tunneler'},
        'cycle_cap': 4,
    },
    # no Refiner, one Tunneler, Hogrider late (R13)
    'low_roll': {
        'climb': {2: 2, 3: 4, 4: 7, 5: 10, 6: 12},
        'buys': {1: ['geomancer'], 3: ['roadboar'], 4: ['flex3'], 5: ['crater_miner', 'foodie'],
                 6: ['flex3'], 7: ['gem_rat', 'trench', 'sly'], 8: ['tunneler', 'foodie'],
                 9: ['trapper', 'foodie'], 10: ['trailblazer'], 11: ['foodie', 'sly'],
                 12: ['champion'], 13: ['hogrider'], 14: [], 15: []},
        'golden': {},
        'cycle_cap': 4,
    },
}


def run(line='typical', d=None, rounds=16, verbose=False):
    d = d or Dials()
    L = LINES[line]
    gold = 0; tier = 1; upcost = UPCOST[2]; extra_income = 0
    S = list(d.gem0)
    board = []          # dicts: name, a, h, quil, gold(en)
    hand_gems = 0; hand_days = 0; hand_conf = 0; hand_cards = []  # Choose One cards from Tunneler
    out = {}
    log = []
    owned = {}

    def add_size(da, dh):
        if d.size_off:
            return
        S[0] += da * d.size_step; S[1] += dh * d.size_step

    def quils():
        return [u for u in board if u['quil']]

    def carry():
        ks = quils() or board
        return max(ks, key=lambda u: u['a'] + u['h']) if ks else None

    def gsize():
        if d.round_up:
            return (math.ceil(S[0] - 1e-9), math.ceil(S[1] - 1e-9))
        return (S[0], S[1])

    def gem_on(u, n, src='hand'):
        ga, gh = gsize()
        u['a'] += n * ga; u['h'] += n * gh
        u.setdefault('src', {})
        u['src'][src] = u['src'].get(src, 0) + n * (ga + gh)

    def spread_gems(n):
        # gems from hand: half on the carry, half spread (guides: early on the best unit, late spread then Confiscate)
        ks = quils() or board
        if not ks:
            return
        if L.get('policy') == 'hand':
            surv = sum((2 if u.get('golden') else 1) for u in board if u['name'] == 'surveyor') * d.surveyor_extra
            bal = 1 if d.balinda and r >= L.get('balinda_round', 99) else 0
            casts = 1 + surv + bal            # additive reading of Surveyor + Balinda (unverified)
            rg = [u for u in board if u['name'] == 'roogug']
            if rg:
                t = rg[0]; echo = d.roogug_n * (2 if t.get('golden') else 1)
                others = [u for u in board if u is not t]
                gem_on(t, n * casts, 'hand')
                for u in others:
                    gem_on(u, n * casts * echo / len(others), 'roogug')
            else:
                gem_on(carry(), n * casts, 'hand')
            stats['landings'] = n * casts * (1 + (d.roogug_n if rg else 0))
            return
        c = carry()
        gem_on(c, n * 0.5)
        for u in ks:
            gem_on(u, n * 0.5 / len(ks))

    hog_count = lambda: sum((2 if u.get('golden') else 1) for u in board if u['name'] == 'hogrider')

    def hog_trigger():
        h = hog_count()
        if not h:
            return
        n = d.hog_gems * h
        if d.apps_off:
            gem_on(carry(), n, 'hog')      # one recipient
        elif d.hog_after:
            for hr in [u for u in board if u['name'] == 'hogrider']:
                m = d.hog_gems * (2 if hr.get('golden') else 1)
                for u in quils():
                    if d.hog_others and u is hr:
                        continue
                    gem_on(u, m, 'hog')
        else:
            for u in quils():
                if d.hog_others and u['name'] == 'hogrider':
                    continue
                gem_on(u, n, 'hog')
            # the cycled Choose One unit also gets them but is sold: lost

    def play_choose_one(card, both=False):
        """card: a Choose One minion or 'gem_day'. Returns gems to hand."""
        nonlocal hand_gems, extra_income, last_co
        g = 0
        if not d.hog_after:
            hog_trigger()
        stats['co'] = stats.get('co', 0) + 1
        if card != 'gem_day':
            last_co = card
        late = ((hog_count() > 0) or r >= 9) and not (d.size_off and d.rational_off)
        if card == 'gem_day':
            if both:
                add_size(1, 1)
            else:
                add_size(*((1, 0) if S[0] <= S[1] else (0, 1)))
        elif card == 'crater_miner':
            if both:
                g += d.miner_gems; add_size(*((1, 0) if S[0] <= S[1] else (0, 1)))
            elif late:
                add_size(*((1, 0) if S[0] <= S[1] else (0, 1)))
            else:
                g += d.miner_gems
        elif card == 'foodie':
            if both:
                add_size(*d.foodie_size); g += d.foodie_gems
            elif late:
                add_size(*d.foodie_size)
            else:
                g += d.foodie_gems
        elif card == 'sly':
            g += d.sly_gems   # free refreshes valued in the cycle budget below
        elif card == 'trapper':
            extra_income += 1
        elif card == 'brigand':
            for u in board:
                gem_on(u, d.brigand_gems, 'brigand') if not d.apps_off else None
            if d.apps_off:
                gem_on(carry(), d.brigand_gems, 'brigand')
        hand_gems += g
        if d.hog_after:
            hog_trigger()

    last_co = None
    late_buys = []
    tun_bank = [0.0]
    supper = [0]
    stats = {}
    for r in range(1, rounds + 1):
        stats = {}
        for u in [u for u in board if u.get('cycled')]:
            board.remove(u)
        last_co = None
        income = (min(r + 2, 10) + extra_income) if d.trapper_bg else min(r + 2, 10 + extra_income)
        gold += income
        if r >= 2:
            upcost = max(0, upcost - 1)
        # tier up
        while tier < 6 and L['climb'].get(tier + 1, 99) <= r and gold >= upcost:
            gold -= upcost; tier += 1
            upcost = UPCOST.get(tier + 1, 0) if tier < 6 else 0
        played_co = 0
        trail = any(u['name'] == 'trailblazer' for u in board)
        trail_left = (2 if any(u['name'] == 'trailblazer' and u.get('golden') for u in board) else 1) if trail else 0

        def do_co(card):
            nonlocal trail_left
            both = trail_left > 0
            if both:
                trail_left -= 1
            play_choose_one(card, both)

        # buys
        queue = late_buys + L['buys'].get(r, [])
        late_buys = []
        for qi, name in enumerate(queue):
            if gold < 3:
                late_buys = queue[qi:]      # a missed scripted arrival waits for next turn
                break
            gold -= 3
            owned[name] = owned.get(name, 0) + 1
            # golden triple
            if L['golden'].get(r) == name:
                ex = [u for u in board if u['name'] == name]
                for u in ex:
                    board.remove(u)
                t, a, h = BODY[name]
                keep_a = sum(u['a'] - BODY[name][1] for u in ex); keep_h = sum(u['h'] - BODY[name][2] for u in ex)
                src = {}
                for u in ex:
                    for k2, v2 in u.get('src', {}).items():
                        src[k2] = src.get(k2, 0) + v2
                unit = {'name': name, 'a': 2 * a + keep_a, 'h': 2 * h + keep_h, 'quil': True, 'golden': True, 'src': src}
            else:
                t, a, h = BODY[name]
                unit = {'name': name, 'a': a, 'h': h, 'quil': name in QUIL}
            cap = 6 if any(u['name'] == 'tunneler' for u in board) or hog_count() else 7
            while len(board) >= cap:
                victim = min(board, key=lambda u: (199 - L['keep'].index(u['name']) if u['name'] in L.get('keep', ()) else (SELL_RANK.index(u['name']) if u['name'] in SELL_RANK else 99), u['a'] + u['h']))
                board.remove(victim); gold += 1
            board.append(unit)
            if len(board) == 7 and r >= 7:
                # keep a cycle slot once the engine is on: sell the weakest non-engine unit
                pass
            # battlecries / choose one when played
            if name == 'geomancer':
                hand_gems += d.geomancer_gems * (2 if unit.get('golden') else 1)
            if name in CHOOSE_ONE:
                do_co(name)
            if name == 'champion':
                add_size(*d.champion)
        # Choose One cards in hand: Gem Days (Rat) and Tunneler cards
        for _ in range(int(hand_days)):
            do_co('gem_day')
        hand_days = 0
        # Tunneler cards need a free slot: play then sell (Created sells for 0)
        cards = hand_cards; hand_cards = []
        for c in cards:
            if c == 'gem_day':
                do_co('gem_day')
            else:
                do_co(c); gold += d.created_sell
        # shop cycling: buy a Choose One unit, play it, sell it (Bought: +1)
        cycles = 0
        if not d.count_off and tier >= 3 and r >= 8:
            spare = gold - (upcost if (tier < 6 and L['climb'].get(tier + 1, 99) == r + 1) else 0)
            cycles = int(min(L.get('cycle_cap', d.cycle_find_cap) if d.cycle_find_cap is None else min(d.cycle_find_cap, L.get('cycle_cap', 9)), max(0, spare) // d.cycle_cost))
            pool = [c for c in ['crater_miner', 'foodie', 'sly', 'trapper', 'brigand'] if BODY[c][0] <= tier]
            for i in range(cycles):
                gold -= d.cycle_cost
                do_co(pool[(r + i) % len(pool)])
        # Activate: Geomant (2 gold, once a turn) and Bandit (0 gold, discard a gem, once a turn)
        for u in list(board):
            gm = 2 if u.get('golden') else 1
            if u['name'] == 'geomant' and gold >= 2:
                gold -= 2; hand_gems += d.geomant_gems * gm
            if u['name'] == 'bandit' and hand_gems >= 1:
                hand_gems += d.bandit_gems * gm - 1
        # gems from hand
        if hand_gems:
            stats['hand_gems'] = hand_gems
            spread_gems(hand_gems); hand_gems = 0
        if hand_conf:
            c = carry()
            n_play = hand_conf if not d.conf_cost else min(hand_conf, int(max(0, gold) // d.conf_cost))
            if c and n_play:
                gem_on(c, d.confiscation * n_play, 'conf'); gold -= d.conf_cost * n_play
            hand_conf = min(5, hand_conf - n_play)   # hold the rest (hand limit: at most 5 held)
        # the last Choose One unit played stays in the cycle slot and fights (sold for 0 next turn)
        if last_co and len(board) < 7:
            t, a, h = BODY[last_co]
            n = d.hog_gems * hog_count() if not d.apps_off else 0
            board.append({'name': last_co, 'a': a + n * S[0], 'h': h + n * S[1], 'quil': True, 'cycled': True})
        # end of turn
        rats = 0
        for u in board:
            if u['name'] == 'gem_rat':
                rats += d.rat_days * (2 if u.get('golden') else 1)
            if u['name'] == 'trench':
                hand_conf += 2 if u.get('golden') else 1
        hand_days += min(rats, 1) if d.count_off else rats
        if r in d.supper_rounds and gold >= 3:
            gold -= 3; supper[0] = min(3, supper[0] + 1)
        tot = sum(u['a'] + u['h'] for u in board) + 2 * supper[0] * len([u for u in board if u['quil']])
        big = max((u['a'] + u['h'] for u in board), default=0)
        srcs = {}
        for u in board:
            for k2, v2 in u.get('src', {}).items():
                srcs[k2] = srcs.get(k2, 0) + v2
        srcs['bodies'] = tot - sum(srcs.values())
        out[r] = {'src': {k2: round(v2) for k2, v2 in srcs.items()}, 'board': round(tot), 'big_share': round(big / tot, 2) if tot else 0,
                  'S': (round(S[0], 1), round(S[1], 1)), 'quil': len(quils()), 'gold_left': round(gold, 1),
                  'tier': tier, 'cycles': cycles, 'co': stats.get('co', 0), 'hand_gems': round(stats.get('hand_gems', 0), 1),
                  'hog': hog_count()}
        if verbose:
            log.append((r, out[r], sorted(((u['name'], round(u['a']), round(u['h'])) for u in board), key=lambda x: -(x[1] + x[2]))))
        # combat
        k = rally(d, r)
        if not d.time_off:
            for u in board:
                mult = 2 if u.get('golden') else 1
                if u['name'] == 'refiner':
                    add_size(d.refiner[0] * k * mult, d.refiner[1] * k * mult)
                if u['name'] == 'champion':
                    add_size(d.champion[0] * d.champion_dies * mult, d.champion[1] * d.champion_dies * mult)
                if u['name'] == 'roadboar' and not d.count_off:
                    hand_gems += k * mult * d.roadboar_gems
                if u['name'] == 'tunneler' and not d.count_off:
                    n = (1 if d.tun_once else k * d.tunneler_cards) * mult
                    pool = [c for c in ['crater_miner', 'foodie', 'sly', 'trapper', 'brigand'] if BODY[c][0] <= tier]
                    tun_bank[0] += n
                    while tun_bank[0] >= 1:
                        tun_bank[0] -= 1
                        hand_cards.append(pool[(r * 3 + len(hand_cards)) % len(pool)])
    return (out, log) if verbose else out


def fmt(out, rounds=(6, 9, 12, 15)):
    return ' | '.join(f"R{r} {out[r]['board']:,} ({out[r]['board'] / TARGET[r]:.2f}x)" for r in rounds)


if __name__ == '__main__':
    for line in LINES:
        print(line, 'BG numbers:', fmt(run(line)))
