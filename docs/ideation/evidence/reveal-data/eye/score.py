import json,re,sys,math
S=sys.argv[1]; picks_files=sys.argv[2:]
C=json.load(open(f'{S}/chosen.json'))
NAMES=["F1","F2","F3","F4","B1","B2","B3"]
def key(a,b):
    i,j=sorted([NAMES.index(a),NAMES.index(b)]); return f"{NAMES[i]}-{NAMES[j]}"
def val(x,pick):
    sc=x['scores']
    if pick=='still' or pick not in sc: return sc['still']
    return sc[pick]
def gain(x,pick): return 100*(val(x,pick)-x['scores']['still'])
def ci(v):
    n=len(v); m=sum(v)/n; sd=math.sqrt(sum((a-m)**2 for a in v)/(n-1)); return m,1.96*sd/math.sqrt(n)
rand=[100*(sum(v for k,v in x['scores'].items() if k!='still')/max(1,len(x['scores'])-1)-x['scores']['still']) for x in C]
best=[100*(max(x['scores'].values())-x['scores']['still']) for x in C]
print("random %+.1f ±%.1f"%ci(rand)); print("rule %+.1f ±%.1f"%ci([gain(x,x['rule']) for x in C])); print("hard %+.1f ±%.1f"%ci([gain(x,x['hard']) for x in C])); print("best %+.1f ±%.1f"%ci(best))
print("still is right (best gains <=3):",sum(b<=3 for b in best),"of",len(C))
print("rule stands still:",sum(x['rule']=='still' for x in C),"hard stands still:",sum(x['hard']=='still' for x in C))
for f in picks_files:
    picks={}; real=0
    for line in open(f):
        m=re.match(r'\s*S(\d+)\s*\|\s*([^|]+)\|\s*([^|]+)\|',line)
        if not m: continue
        n=int(m.group(1)); p=m.group(2).strip().lower(); r=m.group(3).strip().lower()
        sw=re.findall(r'\b([fb][1-4])\b',p)
        picks[n]='still' if 'still' in p or len(sw)!=2 else key(sw[0].upper(),sw[1].upper())
        real+= r.startswith('y')
    g=[gain(C[n-1],picks.get(n,'still')) for n in range(1,len(C)+1)]
    m,c=ci(g); diff=[a-gain(x,x['rule']) for a,x in zip(g,C)]; dm,dc=ci(diff)
    print(f"{f.split('/')[-1]}: n={len(picks)} gain {m:+.1f} ±{c:.1f}; minus rule {dm:+.1f} ±{dc:.1f}; real decisions {real}; stood still {sum(v=='still' for v in picks.values())}; worse than still {sum(a<-3 for a in g)}")
