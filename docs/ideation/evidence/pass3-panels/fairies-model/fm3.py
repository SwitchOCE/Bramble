import math
SLOTS = ["F1","F2","F3","F4","B1","B2","B3"]
BEHIND = {"F1":["B1"],"F2":["B1","B2"],"F3":["B2","B3"],"F4":["B3"]}
BESIDE = {"F1":["F2"],"F2":["F1","F3"],"F3":["F2","F4"],"F4":["F3"],"B1":["B2"],"B2":["B1","B3"],"B3":["B2"]}
BODY = {"nan":(2,1),"witch":(1,2),"chaser":(1,2),"hob":(1,4),"annis":(2,3),"sally":(1,3),
        "lob":(2,4),"fetch":(2,3),"clur":(3,4),"changeling":(2,2),"silky":(3,6),"will":(3,6),
        "mistress":(4,7),"bella":(4,8),"monarch":(6,8),"queen":(8,8),
        "n2":(3,3),"n3":(3,4),"n4":(4,5),"n5":(5,7),"n6":(7,9)}
SHY = {"hob","lob","silky"}
NONFAIRY = {"n2","n3","n4","n5","n6"}
LOG = {}
def ga(x,g): return 0 if x<=0 else max(1, math.ceil(x*g))
class B:
    def __init__(s,g,golden=(),tithe=0.10):
        s.g=g; s.r={k:0 for k in SLOTS}; s.u={}; s.gold=set(golden); s.sup=0; s.t=tithe; s.credit={}
    def put(s,k,c): a,h=BODY[c]; s.u[k]=dict(id=c,a=a,h=h)
    def emp(s,k): return k not in s.u or s.u[k]["id"] in SHY
    def cr(s,c,v): s.credit[c]=s.credit.get(c,0)+v
    def eot(s):
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
                for t in ("B1","B2","B3") if "annis" not in s.gold else SLOTS:
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
    def snap(s):
        out=[]; wisp=any(v["id"]=="will" for v in s.u.values())
        for k in SLOTS:
            v=s.u.get(k)
            if v:
                a=v["a"]+s.sup; h=v["h"]+s.sup
                if v["id"] not in SHY: a+=s.r[k]; h+=s.r[k]
                if v["id"]=="fetch":
                    bh=[s.r[t] for t in BEHIND.get(k,[])]
                    m=max(bh) if bh else 0; m*=2 if "fetch" in s.gold else 1
                    a+=m; h+=m
                out.append((a+h,a,h,v["id"],k))
            elif s.r[k]>0 and wisp:
                b=2 if "will" in s.gold else 1
                out.append((2*b+2*s.r[k],b+s.r[k],b+s.r[k],"wisp",k))
        return out
def play(sch,g,R=16,golden=(),tithe=0.10):
    b=B(g,golden,tithe); res={}
    for r in range(1,R+1):
        for a in sch.get(r,[]):
            op=a[0]
            if op=="put": b.put(a[1],a[2])
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
    s[3]=[("put","F2","annis"),("seed","B3",2)]                       # Spore Cloud on B3
    s[4]=[("put","B1","hob"),("put","F3","sally")]
    s[5]=[("put","B2","n3")]                                            # tier 3; carry seat
    s[6]=[("put","B3","lob"),("put","F4","fetch")]                     # Fetch F4 copies B3
    s[7]=[]                                                             # tier 4
    s[8]=[("rm","B1"),("put","B1","silky"),("seed","F3",0),("sup",)]   # Silky replaces Hob (sold)
    s[9]=[("rm","F3"),("put","F3","n4"),("sup",)]                       # Sally out
    s[10]=[]                                                            # tier 5
    s[11]=[("rm","F1"),("put","F1","bella")]
    s[12]=[("rm","F3"),("put","F3","mistress"),("sup",)]
    s[13]=[("mv","B2","F3"),("put","B2","queen")] if False else [("rm","F2"),("put","F2","queen")]  # tier 6 R13
    s[14]=[]
    s[15]=[("rm","F3"),("put","F3","monarch")]
    return s
def carry_high():
    s={}
    s[1]=[("put","B1","nan"),("seed","B1",1),("mv","B1","F1")]
    s[2]=[("put","F2","annis")]
    s[3]=[("put","B1","hob"),("seed","B3",2)]
    s[4]=[("put","B2","n3"),("put","F3","sally")]                       # tier 3 R4
    s[5]=[("put","B3","lob"),("seed","B3",2)]
    s[6]=[("put","F4","fetch")]                                          # tier 4 R6
    s[7]=[("rm","B1"),("put","B1","silky"),("sup",)]
    s[8]=[("rm","F3"),("put","F3","mistress"),("sup",)]                  # tier 5 R8
    s[9]=[("rm","F1"),("put","F1","bella"),("sup",)]
    s[10]=[("mv","B2","F1"),("put","B2","queen")] if False else [("rm","F2"),("put","F2","queen")]   # tier 6 R10
    s[11]=[("rm","F1"),("put","F1","monarch")]
    return s
def carry_low():
    s={}
    s[1]=[("put","F1","witch")]
    s[3]=[("put","F2","n2"),("put","F3","n2")]
    s[4]=[("put","F4","annis"),("seed","B1",1)]
    s[5]=[("put","B2","n2")]
    s[6]=[("put","B1","hob")]                                           # tier 3 R6
    s[7]=[("seed","B3",2)]
    s[8]=[("put","B3","lob"),("rm","F1"),("put","F1","n4")]            # tier 4 R8
    s[9]=[("sup",)]
    s[10]=[("rm","F2"),("put","F2","fetch")]
    s[11]=[("rm","F3"),("put","F3","mistress")]                         # tier 5 R11
    s[12]=[("sup",)]
    s[13]=[("rm","F4"),("put","F4","bella")]
    s[14]=[("rm","F2"),("put","F2","monarch")]                          # tier 6 R14
    return s
def wide_typ():
    s={}
    s[1]=[("put","B1","nan"),("seed","B1",1),("mv","B1","F1")]
    s[3]=[("put","F2","annis"),("put","F3","sally")]
    s[4]=[("seed","B2",2),("put","F4","n2")]
    s[5]=[("seed","B3",2)]                                              # tier 3
    s[6]=[("rm","F1"),("put","F1","fetch")]
    s[7]=[("rm","F4"),("put","F4","will")]                              # tier 4: Wisps
    s[8]=[("seed","B1",3),("sup",)]
    s[9]=[("sup",)]
    s[10]=[("rm","F3"),("put","F3","mistress")]                         # tier 5
    s[11]=[("rm","F1"),("put","F1","bella")]
    s[12]=[("rm","F2"),("put","F2","monarch"),("sup",)]                  # tier 6 (Mistress covers back)
    s[14]=[("rm","F1"),("put","F1","queen")]
    return s
def tempo_typ():
    s={}
    # Chaser R1 seeds every slot played into; units everywhere; sold R4 (6-7 gold): tier fast
    s[1]=[("put","F1","chaser"),("seed","F1",1),("put","F2","nan"),("seed","F2",1)]
    s[2]=[("put","F3","witch"),("seed","F3",1)]                      # tier 2 also
    s[3]=[("put","F4","n2"),("seed","F4",1),("put","B1","n2"),("seed","B1",1),("put","B2","n2"),("seed","B2",1)]
    s[4]=[("put","B3","n3"),("seed","B3",1),("rm","F1"),("put","F1","clur")]   # sell Chaser (7 gold), tier 3, Cluricaun
    s[5]=[("rm","B1"),("put","B1","n4"),("seed","F3",2)]               # tier 4 R5 with pot gold
    s[6]=[("rm","B2"),("put","B2","changeling"),("rm","F4"),("put","F4","n4"),("sup",)]
    s[7]=[("rm","B3"),("put","B3","bella"),("seed","F3",3),("sup",)]   # tier 5 R7 (Cluricaun +2/turn)
    s[8]=[("rm","F2"),("put","F2","mistress"),("rm","B1"),("sup",)]   # pivot: B1 left empty (field)
    s[9]=[("rm","F4"),("put","F4","will"),("seed","B1",3)]             # Wisp field B1
    s[10]=[("rm","F1"),("put","F1","monarch"),("rm","B2")]             # tier 6 R10; B2 opened as a field
    s[11]=[("rm","B3"),("put","B3","queen")]
    s[12]=[("seed","F3",3)]
    return s

TARGET={4:24,5:36,6:53,7:79,8:123,9:194,10:305,11:482,12:759,13:1177,14:1751,15:2600,16:3900}
TODAY={4:30,5:42,6:52,7:64,8:80,9:92,10:107,11:121,12:133,13:145,14:155}
if __name__=="__main__":
    lines=(("carry typical",carry_typ,()),("carry high",carry_high,()),("carry low",carry_low,()),("wide typical",wide_typ,()),("tempo typical",tempo_typ,()),
           ("carry high + golden Queen",carry_high,("queen",)),("carry high + golden Silky+Queen",carry_high,("silky","queen")),("wide + golden Will",wide_typ,("will",)))
    for g in (0.4,0.5,0.6):
        print("===== g",g)
        print(f"{'target (BG Sep25 mean)':34}"," ".join(f"R{k}:{TARGET[k]}" for k in (4,6,7,9,12,15)))
        for nm,fn,gd in lines:
            r=play(fn(),g,golden=gd)
            print(f"{nm:34}"," ".join(f"R{k}:{r[k]['tot']}" for k in (4,6,7,9,12,15)), "| big R9/12/15:", " ".join(f"{r[k]['snap'][0][1]}/{r[k]['snap'][0][2]} {r[k]['snap'][0][3]}" for k in (9,12,15)))
