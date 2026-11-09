# Random-board version: units vary around a mean; common random numbers across treatments.
import random, sys
sys.path.insert(0, '/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/scripts')
from conc_sim import fight
def unit(rng, m):
    s = max(2, round(rng.uniform(0.6, 1.4)*m)); a = max(1, round(s*rng.uniform(0.35, 0.65))); return (a, max(1, s-a))
def rboard(rng, m, k=7):
    us = sorted([unit(rng, m) for _ in range(k)], key=lambda u: -u[0])  # hitters first (positioning-sim rule)
    return us + [None]*(7-k)
def treat_spread(b, add):
    # add SP spread across units as evenly as integers allow, alternating attack/health
    b = [list(x) if x else None for x in b]; idx = [i for i in range(7) if b[i]]; n=0
    while add > 0:
        i = idx[n % len(idx)]; b[i][n//len(idx) % 2] += 1; add -= 1; n += 1
    return [tuple(x) if x else None for x in b]
def treat_one(b, add, which='max'):
    b = [list(x) if x else None for x in b]; idx = [i for i in range(7) if b[i]]
    i = max(idx, key=lambda j: sum(b[j])) if which=='max' else idx[0]
    b[i][0] += add//2; b[i][1] += add - add//2
    return [tuple(x) if x else None for x in b]
def run(m, adds, n=3000, seed=7):
    res = {}
    rng = random.Random(seed)
    cases = [(rboard(rng, m), rboard(rng, m), random.Random(seed*1000+i)) for i in range(n)]
    def wr(f):
        tot = 0.0
        for A, B, r in cases:
            st = r.getstate(); out = fight(f(A), B, r); r.setstate(st)
            tot += 1 if out==0 else 0.5 if out==-1 else 0
        return tot/n
    base = wr(lambda A: A)
    print(f'mean unit {m} SP (board ~{7*m}); base win {base:.3f}')
    for add in adds:
        s = wr(lambda A: treat_spread(A, add)); o = wr(lambda A: treat_one(A, add, 'max')); f1 = wr(lambda A: treat_one(A, add, 'first'))
        print(f'  +{add} SP: spread {s-base:+.3f}  on biggest unit {o-base:+.3f}  on F1 {f1-base:+.3f}   (per SP: {((s-base)/add):.4f} / {((o-base)/add):.4f})')
    # same total, fewer units
    tot = 7*m
    for k in (5, 6):
        def fewer(A, k=k):
            idx=[i for i in range(7) if A[i]]; S=sum(sum(A[i]) for i in idx)
            keep = sorted([A[i] for i in idx], key=lambda u:-sum(u))[:k]; K=sum(sum(u) for u in keep)
            sc = S/K
            return [(max(1,round(u[0]*sc)), max(1,round(u[1]*sc))) for u in keep] + [None]*(7-k)
        print(f'  same total squeezed onto {k} units: {wr(fewer)-base:+.3f}')
if __name__ == '__main__':
    for m in (6, 10, 20, 60):
        run(m, [round(1.4*m), round(2.8*m)])
