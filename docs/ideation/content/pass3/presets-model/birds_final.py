import sys, json, importlib.util
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/calib")
from birds_sweep import measure
path = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/birds-presets-model.py"
SETS = [("B final", "preset=B chiff=3 s=0.1667"),
        ("C calib", "preset=C chiff=3 s=0.1667"),
        ("C k.15", "preset=C chiff=3 s=0.1667 k=0.15"),
        ("C k.15 chiff4", "preset=C chiff=4 s=0.1667 k=0.15"),
        ("B JD fight-only chiff4", "preset=B chiff=4 s=0.1667 f=0"),
        ("B JD fight-only rb1/5", "preset=B chiff=3 s=0.2 f=0"),
        ("C k.15 chiff4 JD fight-only", "preset=C chiff=4 s=0.1667 k=0.15 f=0"),
        ("C k.15 chiff5 JD fight-only", "preset=C chiff=5 s=0.1667 k=0.15 f=0"),
        ("C k.15 chiff4 rb1/5 JD fight-only", "preset=C chiff=4 s=0.2 k=0.15 f=0"),
        ]
out = {}
for label, args in SETS:
    r = measure(args.split(), N=600)
    a, u, p = r["med"]["A"], r["med"]["U"], r["pooled"]
    two = {t: 0.5 * (a[t] + u[t]) for t in range(1, 17)}
    out[label] = dict(two=two, A=a, U=u, pooled=p, sm=r["two"], res=r["res"], big=r["big"])
    print(f"{label:34s} sm2 {r['two']:5.0f} | pooled R6/8/10/12/14/16 " + "/".join(f"{p[t]:.0f}" for t in (6,8,10,12,14,16))
          + " | two-line " + "/".join(f"{two[t]:.0f}" for t in (6,8,10,12,14,16)) + " | A " + "/".join(f"{a[t]:.0f}" for t in (8,11,12,13,14,16))
          + " | U " + "/".join(f"{u[t]:.0f}" for t in (8,11,12,13,14,16)) + f" | big12 {100*r['big']['A']:.0f}/{100*r['big']['U']:.0f}%", flush=True)
json.dump(out, open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/final/birds_final.json", "w"))
for label, args in (("B final", ["preset=B", "chiff=3", "s=0.1667"]), ("C calib", ["preset=C", "chiff=3", "s=0.1667"]), ("C k.15 chiff4", ["preset=C", "chiff=4", "s=0.1667", "k=0.15"])):
    sys.argv = ["m", "n=0", "lines=none"] + args
    spec = importlib.util.spec_from_file_location("bm", path); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    for key in ("A", "D"):
        for copies in (1, 2):
            L = dict(m.LINES[key]); L["copies"] = dict(L["copies"], Cuckoo=copies)
            g, o = m.run(key, L)
            print(f"  {label:14s} line {key} Cuckoos={copies}: " + " ".join(f"R{t} {o[t][0]}" for t in (10, 12, 14, 15, 16)), flush=True)
    L = dict(m.LINES["D"]); L["copies"] = dict(L["copies"], Cuckoo=2)
