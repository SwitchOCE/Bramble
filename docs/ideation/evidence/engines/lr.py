import json,glob,sys,math,random
def places(arm):
    P={}
    for f in glob.glob('/tmp/claude-0/runs/%s/s*.txt'%arm):
        for l in open(f):
            if l.startswith('eng_row: '):
                r=json.loads(l[9:])
                if r['round']=='final' and r["player"]==r["seed"]%8: P[r['seed']]=r['place']
    return P
a=places(sys.argv[1]); b=places(sys.argv[2]); s=sorted(set(a)&set(b))
ma=sum(a[x] for x in s)/len(s); mb=sum(b[x] for x in s)/len(s)
def ci(v):
    m=sum(v)/len(v); sd=(sum((x-m)**2 for x in v)/(len(v)-1))**.5; return 1.96*sd/len(v)**.5
print('n',len(s),'shuffled seat place: %s %.2f (±%.2f) -> cost %.2f; %s %.2f (±%.2f) -> cost %.2f; diff %+.2f (±%.2f)'%(sys.argv[1],ma,ci([a[x] for x in s]),ma-4.5,sys.argv[2],mb,ci([b[x] for x in s]),mb-4.5,mb-ma,ci([b[x]-a[x] for x in s])))
