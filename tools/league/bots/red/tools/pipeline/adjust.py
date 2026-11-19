import json,sys,collections
reg=json.load(open(sys.argv[1])); src=sys.argv[2]; dst=sys.argv[3]; K=float(sys.argv[4]); CAP=float(sys.argv[5])
lib={c['id']:c for c in json.load(open(sys.argv[6] if len(sys.argv)>6 else 'library.json'))}
# center beta within (tier, round), weighted by count
grp=collections.defaultdict(list)
for c,d in reg.items():
  for R,(b,n) in d.items():
    if n>=100: grp[(lib[c]['tier'],R)].append((b,n))
mean={k:sum(b*n for b,n in v)/sum(n for b,n in v) for k,v in grp.items()}
lines=open(src).read().splitlines()
out=[lines[0]]; changes=[]
for l in lines[1:]:
  f=l.split('\t'); c=f[0]
  d=reg.get(c,{}); num=0;den=0
  for R,(b,n) in d.items():
    if n>=100 and (lib[c]['tier'],R) in mean:
      num+=(b-mean[(lib[c]['tier'],R)])*n; den+=n
  if den>0:
    beta=num/den; delta=max(-CAP,min(CAP,-K*beta))
    f[1]=str(round(float(f[1])+delta)); changes.append((round(delta,1),c))
  out.append('\t'.join(f))
open(dst,'w').write('\n'.join(out)+'\n')
for d,c in sorted(changes): print(d,c)
