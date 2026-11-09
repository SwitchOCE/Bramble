import importlib.util, sys, os, statistics, json
H = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/fairies"
sys.argv = ['x']; os.chdir(H)
spec = importlib.util.spec_from_file_location("m", os.path.join(H, "model.py")); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
B0 = {"fairies_ring_growth": 2, "fairies_lob_turns": 2, "fairies_nan_rings": 2}
C0 = {"fairies_ring_growth": 4, "fairies_lob_turns": 2, "fairies_lob_growth": 3, "fairies_silky_growth": 2, "fairies_nan_rings": 2}
BF = dict(B0, fairies_monarch_period=2)
CF = dict(C0, fairies_monarch_period=2, fairies_monarch_multiplier=3, fairies_golden_monarch_multiplier=4)
CF3 = dict(CF, fairies_ring_growth=3)
RINGS = [n for n, k, v in m.ENSEMBLE if k == "ring"]; COURT = [n for n, k, v in m.ENSEMBLE if k == "court"]
out = {}
for name, o in (("B agent", B0), ("B final", BF), ("C agent", C0), ("C final", CF), ("C final rg3", CF3), ("design", {})):
    res = m.run_all(o, tails=True)
    typ = m.typical(res, "pre"); post = m.typical(res, "post")
    ring = {r: statistics.median([res[n][r]["pre"] for n in RINGS]) for r in range(1, 17)}
    court = {r: statistics.median([res[n][r]["pre"] for n in COURT]) for r in range(1, 17)}
    ringpost = {r: statistics.median([res[n][r]["post"] for n in RINGS]) for r in range(1, 17)}
    sm = lambda d: (d[11] * d[12] * d[13]) ** (1/3)
    two = {r: 0.5 * (ring[r] + court[r]) for r in range(1, 17)}
    out[name] = dict(two=two, ring=ring, court=court, sm=0.5 * (sm(ring) + sm(court)))
    print(f"{name:12s} smoothed2 {0.5*(sm(ring)+sm(court)):.0f} | typ8 R8/10/12/14/16 " + "/".join(f"{typ[r]:.0f}" for r in (8,10,12,14,16))
          + " | two-line R6/8/10/12/14/16 " + "/".join(f"{two[r]:.0f}" for r in (6,8,10,12,14,16))
          + " | ring " + "/".join(f"{ring[r]:.0f}" for r in (8,10,12,14,16)) + " court " + "/".join(f"{court[r]:.0f}" for r in (8,10,12,14,16))
          + f" | ring post R12 {ringpost[12]:.0f} | top1% R16 {res['ring top 1%'][16]['pre']:.0f} | growth R8-14 x{(two[14]/two[8])**(1/6):.2f}", flush=True)
json.dump(out, open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/final/fairies_final.json", "w"))
