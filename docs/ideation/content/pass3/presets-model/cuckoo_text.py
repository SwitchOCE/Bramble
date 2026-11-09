import importlib.util, sys, json
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/calib")
from birds_sweep import measure
path = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/birds-presets-model.py"
six = json.load(open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/final/six.json"))
med = six["C"]["med"]
for k in (1/7, 0.15, 1/6):
    for chiff in (3, 4):
        args = ["preset=C", f"chiff={chiff}", "s=0.16666666666666666", f"k={k}"]
        r = measure(args, N=600)
        sys.argv = ["m", "n=0", "lines=none"] + args
        spec = importlib.util.spec_from_file_location("bm", path); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
        L = dict(m.LINES["D"]); L["copies"] = dict(L["copies"], Cuckoo=2)
        g, o = m.run("D", L)
        print(f"k={k:.4f} chiff={chiff}: sm2 {r['two']:.0f} | pooled R8 {r['pooled'][8]:.0f} | two Cuckoos " + " ".join(f"R{t} {o[t][0]} ({o[t][0] / med[str(t)]:.2f}x)" for t in (12, 14, 16)), flush=True)
