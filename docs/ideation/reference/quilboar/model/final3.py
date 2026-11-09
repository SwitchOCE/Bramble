"""All numbers for the final reference-tribe doc. python3 -I final3.py"""
import importlib.util, copy, math
spec = importlib.util.spec_from_file_location('p', '/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/qfinal/presets3.py')
p = importlib.util.module_from_spec(spec); spec.loader.exec_module(p)
q = p.q
CYC = 6.0
P = {k: {**v, 'cycle_cost': CYC} for k, v in p.P.items()}
T12 = {'A': 500, 'B': 900, 'C': 1800, 'uncut': 500}
R4 = (6, 9, 12, 15)
def run(line, kw, **x): return q.run(line, q.Dials(**{**kw, **x}))
def b(o): return [o[r]['board'] for r in R4]
print('== presets, cycle cost', CYC)
for nm, kw in P.items():
    for line in ['typical', 'strong', 'low_roll', 'hand', 'hand_bal']:
        o = run(line, kw); g = (o[14]['board'] / o[8]['board']) ** (1 / 6)
        print(f"{nm:5s} {line:9s} {b(o)} R12/tgt {o[12]['board']/T12[nm]:.2f} R8-14 x{g:.2f} big12 {o[12]['big_share']} big15 {o[15]['big_share']}")
for nm in ['A', 'B', 'C', 'uncut']:
    t = run('typical', P[nm]); s = run('strong', P[nm]); l = run('low_roll', P[nm]); h = run('hand', P[nm])
    print(f"  {nm}: strong/low R12 {s[12]['board']/l[12]['board']:.1f}x R15 {s[15]['board']/l[15]['board']:.1f}x | hand/typical R12 {h[12]['board']/t[12]['board']:.2f} R15 {h[15]['board']/t[15]['board']:.2f}")
print('== hand line, count cut fallback (Geomant 3, Bandit 2)')
for nm in ['B', 'C']:
    t = run('typical', P[nm]); h = run('hand', P[nm], geomant_gems=3, bandit_gems=2)
    print(nm, b(h), f"hand/typ R12 {h[12]['board']/t[12]['board']:.2f} R15 {h[15]['board']/t[15]['board']:.2f}")
print('== typical every round R5-16')
for nm in ['A', 'B', 'C', 'uncut']:
    o = run('typical', P[nm]); bs = [o[r]['board'] for r in range(5, 17)]
    print(nm, bs); print('   growth', [f"{bs[i+1]/bs[i]:.2f}" for i in range(len(bs) - 1)])
    print('   gem size', [o[r]['S'] for r in (6, 9, 12, 15)], 'co/turn R9-16', [o[r]['co'] for r in range(9, 17)], 'cycles', [o[r]['cycles'] for r in range(8, 17)])
print('== boards at B and C')
for nm in ['B', 'C']:
    o, log = q.run('typical', q.Dials(**P[nm]), verbose=True)
    for r, oo, bb in log:
        if r in R4: print(nm, r, oo['board'], bb)
print('== ablations (typical); rational: Foodie/Miner take gems when size is off')
for nm in ['B', 'C', 'uncut']:
    full = run('typical', P[nm])
    for tag, x in [('count flat', dict(count_off=True)), ('apps off', dict(apps_off=True)), ('size off', dict(size_off=True, rational_off=True)),
                   ('time off', dict(time_off=True)), ('all three', dict(count_off=True, apps_off=True, size_off=True, rational_off=True))]:
        o = run('typical', P[nm], **x)
        print(f"{nm:5s} {tag:10s} {b(o)} /full R12 {full[12]['board']/o[12]['board']:.1f} R15 {full[15]['board']/o[15]['board']:.1f}")
print('== levers restored to BG text, one at a time, from B (typical R12 / R15)')
B = P['B']
for tag, x in [('size steps full (= C)', dict(size_step=1, round_up=False)), ('Hogrider 37.0.2 text (2 gems, all)', dict(hog_gems=2, hog_others=False)),
               ('Tunneler every attack', dict(tun_once=False, tunneler_cards=1)), ('Brigand 3 gems', dict(brigand_gems=3)),
               ('Hogrider every 2nd card (= A)', dict(hog_gems=.5)), ('Refiner once a fight (old spec)', dict(refiner=(.5, .5))),
               ('halves exact, no rounding', dict(round_up=False)), ('Created cards sell for 1', dict(created_sell=1)),
               ('cycle 4.5 gold', dict(cycle_cost=4.5)), ('cycle 7.5 gold', dict(cycle_cost=7.5)), ('no cycling', dict(cycle_cost=999)),
               ('Rally 1.5 a fight late', dict(rally_attacks={99: 1.5})), ('Rally 2.5 a fight late', dict(rally_attacks={8: 1.5, 99: 2.5}))]:
    o = run('typical', B, **x); print(f"  {tag:38s} {o[12]['board']:>6,} / {o[15]['board']:>6,}")
o = run('typical', B); print(f"  {'B itself':38s} {o[12]['board']:>6,} / {o[15]['board']:>6,}")
print('== staples: share of board lost when the card becomes a 4/4 body (R12/R15)')
orig = copy.deepcopy(q.LINES['typical'])
for c in ['hogrider', 'tunneler', 'gem_rat', 'refiner', 'trailblazer', 'champion', 'foodie', 'trench']:
    row = []
    for nm in ['uncut', 'B', 'C']:
        q.LINES['typical'] = copy.deepcopy(orig); full = run('typical', P[nm])
        L = copy.deepcopy(orig); L['buys'] = {r: [('flex3' if x == c else x) for x in xs] for r, xs in L['buys'].items()}
        L['golden'] = {r: n for r, n in L['golden'].items() if n != c}; q.LINES['typical'] = L
        o = run('typical', P[nm]); row.append(f"{1-o[12]['board']/full[12]['board']:.2f}/{1-o[15]['board']/full[15]['board']:.2f}")
    q.LINES['typical'] = orig
    print(f"  {c:12s}", row)
print('== Confiscation steal at the end: carry takes the gem stats of the two biggest others (upper bound)')
for nm in ['B', 'C']:
    o, log = q.run('typical', q.Dials(**P[nm]), verbose=True)
    for r, oo, bb in log:
        if r in (12, 15):
            units = []
            for n, a, h in bb:
                base = q.BODY[n][1] + q.BODY[n][2]
                units.append((n, a + h, a + h - base))
            units.sort(key=lambda x: -x[1])
            tot = sum(u[1] for u in units)
            carry = units[0]; stolen = sum(u[2] for u in units[1:3])
            print(f"  {nm} R{r} big share {carry[1]/tot:.2f} -> {(carry[1]+stolen)/tot:.2f} after one steal (from {units[1][0]}, {units[2][0]})")
