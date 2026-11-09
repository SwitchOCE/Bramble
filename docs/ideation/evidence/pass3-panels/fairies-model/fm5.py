import fm3
from fm3 import *
# Positional Annis: grows the empty Rings behind her only.
_orig_eot = B.eot
def eot_pos(s):
    done=set()
    def gr(k,src):
        if k in done or s.r[k]<=0: return
        d=ga(s.r[k],s.g); s.r[k]+=d; done.add(k); s.cr(src,2*d)
        v=s.u.get(k)
        if v and v["id"] in SHY:
            m=2 if v["id"] in s.gold else 1
            for f in BESIDE[k]:
                w=s.u.get(f)
                if w and w["id"] not in SHY:
                    if v["id"] in ("hob","silky"): w["h"]+=d*m; s.cr(v["id"],d*m)
                    if v["id"] in ("lob","silky"): w["a"]+=d*m; s.cr(v["id"],d*m)
    for k in SLOTS:
        v=s.u.get(k)
        if not v: continue
        c=v["id"]
        if c=="sally":
            for t in sorted([t for t in SLOTS if t not in s.u], key=lambda t: abs(SLOTS.index(t)-SLOTS.index(k))):
                n=2 if "sally" in s.gold else 1; s.r[t]+=n; s.cr("sally",2*n); break
        if c=="annis":
            tg = BEHIND.get(k,[]) if "annis" not in s.gold else ["B1","B2","B3"]
            for t in tg:
                if s.emp(t): gr(t,"annis")
        if c=="mistress":
            for t in SLOTS:
                if s.emp(t) or "mistress" in s.gold: gr(t,"mistress")
        if c=="monarch":
            for t in SLOTS:
                w=s.u.get(t)
                if w and w["id"] not in SHY and (w["id"] not in NONFAIRY or "monarch" in s.gold): gr(t,"monarch")
        if c=="queen":
            sh=s.t*(2 if "queen" in s.gold else 1)
            add=math.floor(sh*sum(s.r[t] for t in SLOTS if t!=k)); s.r[k]+=add; s.cr("queen",2*add)
B.eot = eot_pos

def carry_typ():
    s={}
    s[1]=[("put","B1","nan"),("seed","B1",1),("mv","B1","F1")]
    s[3]=[("put","F2","annis"),("seed","B3",2)]          # Annis F2 lights B1,B2
    s[4]=[("put","B1","hob"),("put","F3","sally")]       # Sally seeds B2 (nearest empty)... then carry takes B2
    s[5]=[("put","B2","n3")]                              # tier 3; carry seat
    s[6]=[("put","B3","lob"),("put","F4","fetch")]        # Lob on B3 (unlit until Mistress); Fetch copies B3
    s[8]=[("rm","B1"),("put","B1","silky"),("sup",)]      # tier 4 R7, Silky R8 replaces Hob
    s[9]=[("rm","F3"),("put","F3","n4"),("sup",)]
    s[10]=[("rm","F3"),("put","F3","mistress")]          # tier 5 R10 -> all fields lit
    s[11]=[("rm","F1"),("put","F1","bella")]
    s[12]=[("sup",)]
    s[13]=[("rm","F2"),("put","F2","queen")]             # tier 6 R13
    s[15]=[("rm","F1"),("put","F1","monarch")]
    return s
def carry_high():
    s={}
    s[1]=[("put","B1","nan"),("seed","B1",1),("mv","B1","F1")]
    s[2]=[("put","F2","annis")]
    s[3]=[("put","B1","hob"),("seed","B3",2)]
    s[4]=[("put","B2","n3"),("put","F3","sally")]        # tier 3 R4
    s[5]=[("put","B3","lob"),("put","F4","annis2")] if False else [("put","B3","lob"),("seed","B3",2)]
    s[6]=[("put","F4","fetch")]                            # tier 4 R6
    s[7]=[("rm","B1"),("put","B1","silky"),("sup",)]
    s[8]=[("rm","F3"),("put","F3","mistress"),("sup",)]    # tier 5 R8
    s[9]=[("rm","F1"),("put","F1","bella"),("sup",)]
    s[10]=[("rm","F2"),("put","F2","queen")]               # tier 6 R10
    s[11]=[("rm","F1"),("put","F1","monarch")]
    return s
def carry_low():
    s={}
    s[1]=[("put","F1","witch")]
    s[3]=[("put","F2","n2"),("put","F3","n2")]
    s[4]=[("put","F4","annis"),("seed","B3",1)]           # F4 lights B3
    s[5]=[("put","B2","n2")]
    s[6]=[("put","B3","hob")]
    s[7]=[("seed","B1",2)]
    s[8]=[("put","B1","lob"),("rm","F1"),("put","F1","n4")]
    s[9]=[("sup",)]
    s[10]=[("rm","F2"),("put","F2","fetch")]
    s[11]=[("rm","F3"),("put","F3","mistress")]
    s[12]=[("sup",)]
    s[13]=[("rm","F1"),("put","F1","bella")]
    s[14]=[("rm","F2"),("put","F2","monarch")]
    return s
def wide_typ():
    s={}
    s[1]=[("put","B1","nan"),("seed","B1",1),("mv","B1","F1")]
    s[3]=[("put","F2","annis"),("put","F3","sally")]       # Annis lights B1,B2
    s[4]=[("seed","B2",2),("put","F4","n2")]
    s[5]=[("seed","B3",2)]
    s[6]=[("rm","F1"),("put","F1","fetch")]
    s[7]=[("rm","F4"),("put","F4","will")]
    s[8]=[("seed","B1",3),("sup",)]
    s[9]=[("sup",)]
    s[10]=[("rm","F3"),("put","F3","mistress")]
    s[11]=[("rm","F1"),("put","F1","bella")]
    s[12]=[("rm","F2"),("put","F2","monarch"),("sup",)]
    s[14]=[("rm","F1"),("put","F1","queen")]
    return s
TODAY={4:30,5:42,6:52,7:64,8:80,9:92,10:107,11:121,12:133,13:145,14:155,15:165}
if __name__=="__main__":
    for g in (0.5,0.6,0.67):
        print("==== positional Annis T2, g",g)
        print(f"{'today median':24}"," ".join(f"R{k}:{TODAY[k]}" for k in (4,5,6,7,8,9,10,12,15)))
        print(f"{'target':24}"," ".join(f"R{k}:{TARGET[k]}" for k in (4,5,6,7,8,9,10,12,15)))
        for nm,fn,gd in (("carry typ",carry_typ,()),("carry high",carry_high,()),("carry low",carry_low,()),("wide typ",wide_typ,()),("tempo typ",tempo_typ,()),("high+gold Queen,Silky",carry_high,("queen","silky")),("high+gold Mistress",carry_high,("mistress",))):
            r=play(fn(),g,golden=gd)
            print(f"{nm:24}"," ".join(f"R{k}:{r[k]['tot']}" for k in (4,5,6,7,8,9,10,12,15)),"| big",
                  " ".join(f"R{k} {r[k]['snap'][0][1]}/{r[k]['snap'][0][2]}({r[k]['snap'][0][0]/r[k]['tot']:.0%})" for k in (9,12,15)))
