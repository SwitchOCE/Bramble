import importlib.util, sys, json
path = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/birds-presets-model.py"
six = json.load(open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/final/six.json"))
for label, P, args, k in (("C calib", "C", ["preset=C", "chiff=3", "s=0.1667"], 0.2), ("C final", "C", ["preset=C", "chiff=4", "s=0.1667"], 0.15), ("B final", "B", ["preset=B", "chiff=3", "s=0.1667"], 0.125)):
    for kk, copies, nm in ((1.5 * k, 2, "2 copies at 1.5k"), (3 * k, 1, "1 copy at 3k")):
        sys.argv = ["m", "n=0", "lines=none", f"k={kk}"] + args
        spec = importlib.util.spec_from_file_location("bm", path); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
        med = six[P]["med"]
        L = dict(m.LINES["D"]); L["copies"] = dict(L["copies"], Cuckoo=copies)
        g, o = m.run("D", L)
        print(f"{label:8s} golden+one as {nm:16s}: " + " ".join(f"R{t} {o[t][0]} ({o[t][0] / med[str(t)]:.2f}x)" for t in (12, 14, 16)))
