"""Final presets: all six tribes on one convention (two harness lines, each line's median, averaged),
Bog and Hunters re-fed on the mean of the six (3 fixed-point iterations), as adv/lobby2.py did."""
import importlib.util, sys, os, statistics, json, math
S = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets"
OUT = S + "/final"
def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path); m = importlib.util.module_from_spec(spec); sys.modules[name] = m; spec.loader.exec_module(m); return m
RR = list(range(6, 17))
lines = {"B": {}, "C": {}}   # tribe -> (line1 dict, line2 dict)
# Birds (final): B chiff 3, Redbreast 1/6; C Cuckoo 0.15, chiff 4, Redbreast 1/6
bf = json.load(open(OUT + "/birds_final.json"))
for P_, lbl in (("B", "B final"), ("C", "C k.15 chiff4")):
    lines[P_]["Birds"] = ({t: bf[lbl]["A"][str(t)] for t in RR}, {t: bf[lbl]["U"][str(t)] for t in RR})
# Fairies (final, Monarch fix)
ff = json.load(open(OUT + "/fairies_final.json"))
for P_, lbl in (("B", "B final"), ("C", "C final")):
    lines[P_]["Fairies"] = ({t: ff[lbl]["ring"][str(t)] for t in RR}, {t: ff[lbl]["court"][str(t)] for t in RR})
# Oozes (agent values)
cwd = os.getcwd()
R = load("ozr", S + "/oozes_presets_run.py"); D = R.DESIGN
for P_, d in (("B", dict(D, r=1/8, field_scale=900/759)), ("C", dict(D, r=1/6, e=0.75, field_scale=1800/759))):
    res = R.run_all(d)
    b = res['B with Aspic R6']; p = res['P pot route (Pot Luck)']
    lines[P_]["Oozes"] = ({t: b[t]['active'] for t in RR}, {t: p[t]['active'] for t in RR})
# Hedgerow (agent values)
os.chdir(S + "/hedgerow"); sys.path.insert(0, S + "/hedgerow")
sw = load("sw", S + "/hedgerow/sweep.py"); os.chdir(cwd)
hedge_pooled = {}
for P_ in ("B", "C"):
    o, _ = sw.stats(dict(sw.hp.PRESETS[P_]))
    lines[P_]["Hedgerow"] = ({t: o[t]['sup'] for t in RR}, {t: o[t]['par'] for t in RR})
    hedge_pooled[P_] = {t: o[t]['pooled'] for t in RR}
sys.path.remove(S + "/hedgerow")
# Bog and Hunters, re-fed
os.chdir(S + "/bog"); sys.path.insert(0, S + "/bog")
BP = load("bog_presets", S + "/bog/bog_presets.py")
def mk(k=1.0, ts=0.5, ns=0.25, fm=2.0, per=3, rs=None):
    rs = 0.25 * k if rs is None else rs
    return {"bog_soak_keep": k, "bog_golden_soak_keep": 2 * k, "bog_tiddy_share": ts, "bog_golden_tiddy_share": 2 * ts,
            "bog_nan_share": ns, "bog_golden_nan_share": 2 * ns, "bog_frog_multiplier": fm, "bog_golden_frog_multiplier": fm + 1,
            "bog_kiss_period": per, "bog_ranocchio_share": rs, "bog_golden_ranocchio_share": 2 * rs}
sys.path.remove(S + "/bog")
BOGD = {"B": mk(k=2.0, ns=0.5, rs=0.5), "C": mk(k=3.0, ns=0.5, rs=0.5)}
sys.path.insert(0, S + "/hunters"); os.chdir(S + "/hunters")
sys.modules.pop("presets", None)
import presets as HP
HP.ROUNDS = tuple(RR)
class _P:
    def map(self, f, jobs, chunksize=None): return [f(j) for j in jobs]
HP.POOL = _P()
from step5 import B as HB, C as HC
HUND = {"B": HB, "C": HC}
early = {1: 5, 2: 10, 3: 17, 4: 26, 5: 37}
two = lambda pair: {t: 0.5 * (pair[0][t] + pair[1][t]) for t in RR}
def run_pair(P_, field):
    F = lambda r: field[r] if r in field else (BP.STRONG[r] if r <= 16 else field[16] * 1.5)
    court, _ = BP.typical_ensemble(field=F, dials=BOGD[P_])
    sw_ = BP.run(BP.SWAMP, field=F, dials=BOGD[P_])
    curve = dict(early); curve.update({r: field[r] for r in RR}); curve[17] = field[16] * 1.6
    h = HP.typical(HUND[P_], curve, games=200, avg=False)
    return ({r: court[r] for r in RR}, {r: sw_[r]["total"] for r in RR}), ({r: h["A"][r] for r in RR}, {r: h["B"][r] for r in RR})
res = {}
for P_ in ("B", "C"):
    four = {k: two(v) for k, v in lines[P_].items()}
    bog = hun = {r: statistics.mean(four[k][r] for k in four) for r in RR}
    for it in range(3):
        field = {r: statistics.mean([four[k][r] for k in four] + [bog[r], hun[r]]) for r in RR}
        bogp, hunp = run_pair(P_, field)
        bog, hun = two(bogp), two(hunp)
        print(P_, "iter", it, "field R12", round(field[12]), "Bog R12", round(bog[12]), "Hunters R12", round(hun[12]), flush=True)
    lines[P_]["Bog"] = bogp; lines[P_]["Hunters"] = hunp
    res[P_] = field
os.chdir(cwd)
ORDER = ["Birds", "Fairies", "Bog", "Hunters", "Oozes", "Hedgerow"]
dump = {}
for P_ in ("B", "C"):
    tw = {k: two(lines[P_][k]) for k in ORDER}
    med = {r: statistics.median([tw[k][r] for k in ORDER]) for r in RR}
    sm = {k: 0.5 * sum((lines[P_][k][i][11] * lines[P_][k][i][12] * lines[P_][k][i][13]) ** (1/3) for i in (0, 1)) for k in ORDER}
    print(f"\n== {P_}: two-line mean per round, and smoothed R12 (geomean R11-13 per line, then mean)")
    for k in ORDER:
        g = (tw[k][14] / tw[k][8]) ** (1/6)
        print(f"{k:9s} " + " ".join(f"R{r} {tw[k][r]:6.0f}" for r in RR) + f" | sm12 {sm[k]:5.0f} | x{g:.2f} R8-14"
              + " | lines R12 " + "/".join(f"{lines[P_][k][i][12]:.0f}" for i in (0, 1)))
    print(f"{'median':9s} " + " ".join(f"R{r} {med[r]:6.0f}" for r in RR) + f" | x{(med[14]/med[8])**(1/6):.2f} R8-14")
    print(f"{'mean6':9s} " + " ".join(f"R{r} {res[P_][r]:6.0f}" for r in RR))
    for k in ORDER:
        print(f"{k:9s}/med " + " ".join(f"{tw[k][r] / med[r]:5.2f}" for r in RR))
    print("spread max/min " + " ".join(f"R{r} {max(tw[k][r] for k in ORDER) / min(tw[k][r] for k in ORDER):.2f}" for r in RR))
    print("sm12 spread", f"{max(sm.values()) / min(sm.values()):.2f}", "mean sm12", f"{statistics.mean(sm.values()):.0f}")
    dump[P_] = dict(two=tw, med=med, sm=sm, lines={k: lines[P_][k] for k in ORDER}, mean6=res[P_])
json.dump(dump, open(OUT + "/six.json", "w"))
