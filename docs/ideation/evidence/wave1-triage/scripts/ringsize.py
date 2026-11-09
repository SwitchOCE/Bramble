"""Which Fairy pieces move Ring size, R8->R12, and how often (descriptive)."""
import os, pickle
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
rows = pickle.load(open(os.path.join(HERE, "boards.pkl"), "rb"))["rows"]
idx = {(r["seed"], r["seat"], r["round"]): r for r in rows}
for line in ("line_fairies_ring", "line_fairies_court"):
    for rnd in (10, 12):
        rs = [r for r in rows if r["line"] == line and r["round"] == rnd]
        s = np.array([r["ring_size"] or 1 for r in rs])
        print(f"\n{line} R{rnd} n={len(rs)} ring size dist:", {int(k): int((s == k).sum()) for k in np.unique(s)})
        def ever(r, key):
            return any(key in (idx.get((r['seed'], r['seat'], k)) or {}).get('owned', {}) for k in range(8, rnd + 1))
        for key in ("cluricaun", "lob_lie_by_the_fire", "silky", "fairy_monarch", "old_moth_annis", "queen_of_elfland"):
            e = np.array([ever(r, key) for r in rs])
            print(f"   {key:20s} seen R8..R{rnd}: {e.mean()*100:5.1f}%  median size with {np.median(s[e]) if e.any() else float('nan'):.1f} / without {np.median(s[~e]):.1f}  share size>=4 with {np.mean(s[e]>=4)*100 if e.any() else float('nan'):5.1f}% / without {np.mean(s[~e]>=4)*100:5.1f}%")
        mon = np.array([ever(r, 'fairy_monarch') for r in rs])
        print(f"   no Monarch seen: size dist", {int(k): int((s[~mon] == k).sum()) for k in np.unique(s[~mon])})
