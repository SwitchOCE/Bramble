import fm5
from fm3 import *
# add Monarch arrival grow ("When played: your Rings grow"), tracked per card
def play2(sch,g,R=16,golden=(),tithe=0.10):
    b=B(g,golden,tithe); res={}
    for r in range(1,R+1):
        for a in sch.get(r,[]):
            op=a[0]
            if op=="put":
                b.put(a[1],a[2])
                if a[2]=="monarch":
                    reps = 2 if "monarch" in golden else 1
                    for _ in range(reps):
                        for k in SLOTS:
                            if b.r[k]>0:
                                d=ga(b.r[k],g); b.r[k]+=d; b.cr("monarch",2*d)
            elif op=="rm": b.u.pop(a[1],None)
            elif op=="mv": b.u[a[2]]=b.u.pop(a[1])
            elif op=="seed": b.r[a[1]]+=a[2]
            elif op=="sup": b.sup+=1
        b.eot(); sn=b.snap(); tot=sum(x[0] for x in sn)
        res[r]=dict(tot=tot,snap=sorted(sn,reverse=True),ring=dict(b.r),credit=dict(b.credit))
    return res
def carry_typ():
    s={}
    s[1]=[("put","B1","nan"),("seed","B1",1),("mv","B1","F1")]
    s[3]=[("put","F2","annis"),("seed","B3",2)]
    s[4]=[("put","B1","hob"),("put","F3","sally")]
    s[5]=[("put","B2","n3")]
    s[6]=[("put","B3","lob"),("rm","F1"),("put","F1","fetch")]
    s[7]=[("put","F4","fetch2")] if False else [("seed","B3",0)]
    s[8]=[("rm","B1"),("put","B1","silky"),("sup",)]
    s[9]=[("rm","F3"),("put","F3","annis"),("sup",)]          # 2nd Annis F3 lights B3 (Lob)
    s[10]=[("put","F4","mistress")]                          # tier 5
    s[11]=[("rm","F3"),("put","F3","bella")]
    s[12]=[("sup",)]
    s[13]=[("mv","B2","F2"),("put","B2","queen")]            # tier 6: crown the Queen; old carry to F2 (Annis sold)
    s[14]=[("rm","F3"),("put","F3","monarch")]
    return s
def wide_typ():
    return fm5.wide_typ()
if __name__=="__main__":
    for g in (0.5,0.67):
        for nm,fn in (("carry typ",carry_typ),("wide typ",wide_typ),("carry high",fm5.carry_high),("tempo",tempo_typ)):
            r=play2(fn(),g)
            print(f"== g {g} {nm}:"," ".join(f"R{k}:{r[k]['tot']}" for k in (4,5,6,7,8,9,10,12,15)))
            for k in (9,12,15):
                print(f"   R{k}:", ", ".join(f"{x[3]}@{x[4]} {x[1]}/{x[2]}" for x in r[k]['snap']))
                print(f"      credit to R{k}:", r[k]['credit'], "rings", {a:b for a,b in r[k]['ring'].items() if b})
