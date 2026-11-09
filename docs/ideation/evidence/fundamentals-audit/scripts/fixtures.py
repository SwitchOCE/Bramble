import json
E='/home/alex/code/Bramble-ideation-balance/docs/ideation/evidence/'
d=json.load(open(E+'pass2-followup-boards.json'))
r=json.load(open(E+'pass2-followup/r9-results.json'))
# find same-roll win rates
print(list(r.keys())[:10])
