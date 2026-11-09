import importlib.util, sys, os, statistics, json
S = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets"
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path); m = importlib.util.module_from_spec(spec); sys.modules[name] = m; spec.loader.exec_module(m); return m
RR = list(range(6, 17)); cwd = os.getcwd()
six = json.load(open(S + "/final/six.json"))
MED = {P: {int(r): v for r, v in six[P]["med"].items()} for P in six}
FIELD = {P: {int(r): v for r, v in six[P]["mean6"].items()} for P in six}
def show(lbl, l1, l2, P="C"):
    two = {t: 0.5 * (l1[t] + l2[t]) for t in RR}
    sm = 0.5 * sum((l[11] * l[12] * l[13]) ** (1/3) for l in (l1, l2))
    print(f"{lbl:36s} sm12 {sm:5.0f} | two-line R8/10/12/14/16 " + "/".join(f"{two[t]:.0f}" for t in (8, 10, 12, 14, 16))
          + " | /median " + " ".join(f"R{t} {two[t] / MED[P][t]:.2f}" for t in (8, 10, 12, 14, 16)), flush=True)
# Birds
sys.path.insert(0, S + "/calib")
from birds_sweep import measure
for lbl, a in ():
    args = ("preset=C chiff=4 s=0.1667 k=0.15 " + a).split()
    r = measure(args, N=600)
    show(lbl, {t: r["med"]["A"][t] for t in RR}, {t: r["med"]["U"][t] for t in RR})
# Fairies
os.chdir(S + "/fairies"); sys.argv = ["x"]
fm = load("fm", S + "/fairies/model.py"); os.chdir(cwd)
RINGS = [n for n, k, v in fm.ENSEMBLE if k == "ring"]; COURT = [n for n, k, v in fm.ENSEMBLE if k == "court"]
CF = {"fairies_ring_growth": 4, "fairies_lob_turns": 2, "fairies_lob_growth": 3, "fairies_silky_growth": 2, "fairies_nan_rings": 2,
      "fairies_monarch_period": 2, "fairies_monarch_multiplier": 3, "fairies_golden_monarch_multiplier": 4}
for lbl, o in ():
    res = fm.run_all(dict(CF, **o), tails=False)
    show(lbl, {r: statistics.median([res[n][r]["pre"] for n in RINGS]) for r in RR}, {r: statistics.median([res[n][r]["pre"] for n in COURT]) for r in RR})
# Oozes
R = load("ozr", S + "/oozes_presets_run.py"); D = R.DESIGN
for lbl, d in (("Oozes C final", {}), ("Oozes C Soup 1/7", {"r": 1/7}), ("Oozes C Soup 1/8", {"r": 1/8}), ("Oozes C Elder 2/3", {"e": 2/3})):
    res = R.run_all({**D, "r": 1/6, "e": 0.75, "field_scale": 1800/759, **d})
    b = res['B with Aspic R6']; p = res['P pot route (Pot Luck)']
    show(lbl, {t: b[t]['active'] for t in RR}, {t: p[t]['active'] for t in RR})
# Hedgerow
os.chdir(S + "/hedgerow"); sys.path.insert(0, S + "/hedgerow")
sw = load("sw", S + "/hedgerow/sweep.py"); os.chdir(cwd)
C = dict(sw.hp.PRESETS["C"])
for lbl, d in (("Hedgerow C final", {}), ("Hedgerow C Mallow x2.5", {"mallow": 2.5}), ("Hedgerow C Mallow x2", {"mallow": 2.0}), ("Hedgerow C Dozey wake x2", {"wake": 1.0})):
    o, _ = sw.stats(dict(C, **d))
    show(lbl, {t: o[t]['sup'] for t in RR}, {t: o[t]['par'] for t in RR})
    if lbl.endswith("2.5") or lbl.endswith("final"):
        print("   parish on time (shift 0) /median R14-16 " + " ".join(f"{o[t]['par0'] / MED['C'][t]:.2f}" for t in (14, 15, 16)) + " | supper on time R9 " + f"{o[9]['sup0'] / MED['C'][9]:.2f}")
sys.path.remove(S + "/hedgerow")
# Bog and Hunters on the final C field
os.chdir(S + "/bog"); sys.path.insert(0, S + "/bog")
BP = load("bog_presets", S + "/bog/bog_presets.py"); sys.path.remove(S + "/bog")
def mk(k=1.0, ts=0.5, ns=0.25, fm_=2.0, per=3, rs=None):
    rs = 0.25 * k if rs is None else rs
    return {"bog_soak_keep": k, "bog_golden_soak_keep": 2 * k, "bog_tiddy_share": ts, "bog_golden_tiddy_share": 2 * ts,
            "bog_nan_share": ns, "bog_golden_nan_share": 2 * ns, "bog_frog_multiplier": fm_, "bog_golden_frog_multiplier": fm_ + 1,
            "bog_kiss_period": per, "bog_ranocchio_share": rs, "bog_golden_ranocchio_share": 2 * rs}
F = lambda r: FIELD["C"][r] if r in FIELD["C"] else (BP.STRONG[r] if r <= 16 else FIELD["C"][16] * 1.5)
for lbl, d in (("Bog C final", mk(k=3.0, ns=0.5, rs=0.5)), ("Bog C Soak keep 2", mk(k=2.0, ns=0.5, rs=0.5)), ("Bog C Nan 1/4", mk(k=3.0, ns=0.25, rs=0.5)), ("Bog C kiss period 4", mk(k=3.0, ns=0.5, rs=0.5, per=4))):
    court, _ = BP.typical_ensemble(field=F, dials=d); swp = BP.run(BP.SWAMP, field=F, dials=d)
    show(lbl, {r: court[r] for r in RR}, {r: swp[r]["total"] for r in RR})
    print(f"   R6 {0.5 * (court[6] + swp[6]['total']):.0f}")
sys.path.insert(0, S + "/hunters"); os.chdir(S + "/hunters")
sys.modules.pop("presets", None)
import presets as HP
HP.ROUNDS = tuple(RR)
class _P:
    def map(self, f, jobs, chunksize=None): return [f(j) for j in jobs]
HP.POOL = _P()
from step5 import C as HC
from step3 import mk as hmk
curve = {1: 5, 2: 10, 3: 17, 4: 26, 5: 37}; curve.update(FIELD["C"]); curve[17] = FIELD["C"][16] * 1.6
for lbl, Rr in (("Hunters C final", HC), ("Hunters C Glutton 3/4", hmk(0.75, 0.75, 1.0, 0.5)), ("Hunters C Glutton 2/3", hmk(0.75, 2/3, 1.0, 0.5)), ("Hunters C Takers 2/3", hmk(2/3, 1.0, 1.0, 0.5))):
    h = HP.typical(Rr, curve, games=200, avg=False)
    show(lbl, h["A"], h["B"])
