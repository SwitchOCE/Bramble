import json,sys
from collections import defaultdict
G=[]
for l in open(sys.argv[1]+'/games.jsonl'):
  try: G.append(json.loads(l))
  except: pass
d=defaultdict(list); t=defaultdict(list); co=0
for g in G:
  for s in g['seats']:
    d[s['bot']].append(s['place']); t[(s['bot'][:5],s['main_tribe'])].append(s['place'])
    co+= s['clock_out'] is not None or s['panic'] is not None
print(len(G),'games',{k:(len(v),round(sum(v)/len(v),3)) for k,v in d.items()}, 'clockouts/panics',co)
for k,v in sorted(t.items(),key=str): print(k,len(v),round(sum(v)/len(v),2))
