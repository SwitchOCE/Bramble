import json
E='/home/alex/code/Bramble-ideation-balance/docs/ideation/evidence/'
d=json.load(open(E+'pass2-followup-boards.json'))
extra={'birds_high':[(9,10),(9,9)],'birds_low':[(2,4)]}  # Eggs per pass2-followup-boards.md
winr={'hunters_high':49.1,'hedgerow_high':44.9,'oozes_high':66.2,'bog_high':28.3,'fairies_high':77.0,'birds_high':34.5,
'hunters_low':26.5,'hedgerow_low':99.6,'oozes_low':39.7,'bog_low':61.9,'fairies_low':10.2,'birds_low':62.1}
print(f"{'board':14s} units total  avg  max-unit  max-share  top2-share  same-roll-win%")
for b in d['boards']:
    units=[(s['attack'],s['health']) for s in b['slots'].values() if s]
    units+=extra.get(b['id'],[])
    tot=sum(a+h for a,h in units); mx=max(units,key=lambda x:x[0]+x[1])
    srt=sorted((a+h for a,h in units),reverse=True)
    print(f"{b['id']:14s} {len(units):5d} {tot:5d} {tot/len(units):5.1f}  {mx[0]:2d}/{mx[1]:<3d}    {(mx[0]+mx[1])/tot:5.2f}     {sum(srt[:2])/tot:5.2f}       {winr[b['id']]:5.1f}")
