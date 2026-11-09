import importlib.util, sys, json
path = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/birds-presets-model.py"
six = json.load(open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/final/six.json"))
for label, P, args in (("B final", "B", ["preset=B", "chiff=3", "s=0.1667"]), ("C calib", "C", ["preset=C", "chiff=3", "s=0.1667"]), ("C final", "C", ["preset=C", "chiff=4", "s=0.1667", "k=0.15"])):
    sys.argv = ["m", "n=0", "lines=none"] + args
    spec = importlib.util.spec_from_file_location("bm", path); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    med = six[P]["med"]
    for copies in (2, 3):
        L = dict(m.LINES["D"]); L["copies"] = dict(L["copies"], Cuckoo=copies)
        g, o = m.run("D", L)
        print(f"{label:8s} line D Cuckoo copies={copies}: " + " ".join(f"R{t} {o[t][0]} ({o[t][0] / med[str(t)]:.2f}x)" for t in (12, 14, 16)))
