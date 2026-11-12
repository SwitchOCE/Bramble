exec(open("twolevel.py").read().split("if __name__")[0])
import statistics as st
def detail(name,big,r,n=2000):
    o=run(big,r,n,seed=7); rec=o['rec']
    print(f"\n{name}\n  game p10/med/p90 {o['L']}  first-out {o['F']}  out with <=2 losses {o['le2']:.1%}, <=3 {o['le3']:.1%}")
    print("  big loss % by round: "+" ".join(f"r{t}:{big(t):.0f}" for t in (1,3,5,7,9,11,13,15)))
    for a,b in ((1,4),(5,8),(9,12),(13,40)):
        s=[x for x in rec if a<=x[0]<=b]; close=[x for x in s if x[3]<0.5]; outc=[x for x in s if x[3]>1.0]
        f=lambda v: f"{sum(x[2] for x in v)/len(v):.0%}" if v else "-"
        print(f"  rounds {a}-{b}: big {f(s)} of losses (close fights {f(close)}, outclassed loser {f(outc)}); avg loss {st.mean(x[1] for x in s):.0f}%")
detail("A: 5% -> 25% by round 9, +3%/round after, small = 60% of big", curve(5,9,3),0.6)
detail("B: same, small = 40% of big", curve(5,9,3),0.4)
detail("C: 5% -> 25% by round 9, then flat 25% (your end-game number)", curve(5,9,0),0.6)
detail("D: 8% -> 25% by round 9, +6%/round after, small = 60%", curve(8,9,6),0.6)
