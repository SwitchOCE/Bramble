import importlib.util
spec = importlib.util.spec_from_file_location('p', '/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/qfinal/presets3.py')
p = importlib.util.module_from_spec(spec); spec.loader.exec_module(p); q = p.q
P = {k: {**v, 'cycle_cost': 6.0} for k, v in p.P.items()}
for nm in ['B', 'C', 'uncut']:
    t = q.run('typical', q.Dials(**P[nm]))
    for tag, x in [('hand', {}), ('Roogug every 2nd gem', dict(roogug_n=.5)), ('Geomant 3', dict(geomant_gems=3)), ('Surveyor off', dict(surveyor_extra=0))]:
        h = q.run('hand', q.Dials(**{**P[nm], **x}))
        print(nm, f"{tag:22s}", [h[r]['board'] for r in (6, 9, 12, 15)], f"/typ R12 {h[12]['board']/t[12]['board']:.2f} R15 {h[15]['board']/t[15]['board']:.2f}")
o, log = q.run('hand', q.Dials(**P['B']), verbose=True)
for r, oo, b in log:
    if r in (9, 12, 15): print('B hand', r, oo['board'], oo['S'], b)
