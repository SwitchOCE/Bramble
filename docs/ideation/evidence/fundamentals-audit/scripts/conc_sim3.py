import random, sys
sys.path.insert(0, '/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/scripts')
from conc_sim import fight
from conc_sim2 import rboard
def run(m, n=3000, seed=11):
    rng = random.Random(seed)
    cases = [(rboard(rng, m), rboard(rng, m), random.Random(seed*1000+i)) for i in range(n)]
    def wr(f):
        tot=0.0
        for A,B,r in cases:
            st=r.getstate(); o=fight(f(A),B,r); r.setstate(st); tot += 1 if o==0 else 0.5 if o==-1 else 0
        return tot/n
    base = wr(lambda A:A)
    print(f'mean unit {m}: base {base:.3f}')
    # move SP from the rest onto one carry, keeping the total: carry share f
    for f in (0.2, 0.3, 0.4, 0.5):
        for slot in ('F1','B1'):
            def carry(A, f=f, slot=slot):
                S = sum(sum(u) for u in A if u); big = f*S; rest=(S-big)
                others = [u for u in A if u][1:]; O=sum(sum(u) for u in others); sc=rest/O
                others=[(max(1,round(u[0]*sc)), max(1,round(u[1]*sc))) for u in others]
                c=(round(big/2), round(big/2))
                if slot=='F1': return [c]+others[:3]+others[3:]
                return others[:4]+[c]+others[4:]
            print(f'  carry share {f:.1f} in {slot}: {wr(carry)-base:+.3f}', end='')
        print()
    # Dozey-like: add +16 SP (8/8) onto one unit vs +16 spread
    add=16
    def one(A):
        A=list(A); i=0; A[i]=(A[i][0]+8, A[i][1]+8); return A
    def spread(A):
        A=[list(u) for u in A]; k=0
        while k<add:
            A[k%7][k//7%2]+=1; k+=1
        return [tuple(u) for u in A]
    print(f'  +8/+8 on F1: {wr(one)-base:+.3f}   +16 SP spread: {wr(spread)-base:+.3f}')
for m in (9, 12):
    run(m)
