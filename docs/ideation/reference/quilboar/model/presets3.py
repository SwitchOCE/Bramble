"""Final-doc presets on qm3 (review fixes applied). python3 -I presets3.py"""
import importlib.util, copy, math
from pathlib import Path
spec = importlib.util.spec_from_file_location('q', Path(__file__).with_name('qm3.py'))
q = importlib.util.module_from_spec(spec); spec.loader.exec_module(q)
q.BODY['balinda'] = (6, 6, 6); q.QUIL.discard('balinda')
q.LINES['hand'] = {
    'policy': 'hand', 'keep': ('roogug', 'surveyor', 'tunneler', 'geomant', 'refiner'),
    'climb': {2: 2, 3: 4, 4: 6, 5: 9, 6: 11},
    'buys': {1: ['geomancer'], 3: ['roadboar'], 4: ['flex3'], 5: ['crater_miner', 'bandit'], 6: ['trench'],
             7: ['tunneler', 'foodie', 'roogug'], 8: ['sly', 'flex3', 'trapper'], 9: ['surveyor', 'foodie'],
             10: ['tunneler', 'refiner', 'sly'], 11: ['geomant'], 12: [], 13: [], 14: ['tunneler'], 15: []},
    'golden': {14: 'tunneler'}, 'cycle_cap': 4,
}
q.LINES['hand_bal'] = copy.deepcopy(q.LINES['hand']); q.LINES['hand_bal']['buys'][12] = ['balinda']; q.LINES['hand_bal']['balinda_round'] = 12
FIX = dict(hog_after=True, trapper_bg=True, conf_cost=1, tun_once=True)
P = {
 'A': dict(size_step=.5, champion=(2, 1), refiner=(1, 1), hog_gems=.5, hog_others=True, brigand_gems=1, round_up=True, **FIX),
 'B': dict(size_step=.5, champion=(2, 1), refiner=(1, 1), hog_gems=1, hog_others=True, brigand_gems=1, round_up=True, **FIX),
 'C': dict(size_step=1, champion=(2, 1), refiner=(1, 1), hog_gems=1, hog_others=True, brigand_gems=1, **FIX),
 'uncut': dict(hog_after=True, trapper_bg=True, conf_cost=1, tun_once=False, tunneler_cards=1),
}
TGT12 = {'A': 500, 'B': 900, 'C': 1800, 'uncut': 500}
def run(line, kw, **extra):
    return q.run(line, q.Dials(**{**kw, **extra}))
if __name__ == '__main__':
    for nm, kw in P.items():
        for line in ['typical', 'strong', 'low_roll', 'hand', 'hand_bal']:
            o = run(line, kw)
            g = (o[14]['board'] / o[8]['board']) ** (1 / 6)
            print(f"{nm:5s} {line:9s}", ' | '.join(f"{o[r]['board']:>6,}" for r in (6, 9, 12, 15)),
                  f"| R12 x{o[12]['board']/TGT12[nm]:.2f} tgt | R8-14 x{g:.2f} | big12 {o[12]['big_share']} big15 {o[15]['big_share']} | gem {o[9]['S']} {o[12]['S']} {o[15]['S']}")
