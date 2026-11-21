"""Plain-Python counts over the raw sample files, to check SQL answers (Q1, Q2, Q5, Q4 median)."""
import gzip, json, statistics, csv
S='/data/dbtest/sample'
def tsv(name): return list(csv.DictReader(open(f'/data/dbtest/sqlite/results/{name}.tsv'), delimiter='\t'))
# Q1: green-recruit offers/buys in round 3 from shops.jsonl.gz
off=buy=0
for l in gzip.open(f'{S}/shops.jsonl.gz','rt'):
    d=json.loads(l)
    if d['round']!=3: continue
    b={(x['spell'],x['index']) for x in d['bought']}
    for o in d['offers']:
        if o['card']=='green-recruit':
            off+=1; buy+=(o['spell'],o['index']) in b
sql=[r for r in tsv('q1a_buy_rate_by_card_round') if r['card']=='green-recruit' and r['round']=='3'][0]
print('Q1 green-recruit r3 python', off, buy, '| sql', sql['offered'], sql['bought'], 'MATCH' if (str(off),str(buy))==(sql['offered'],sql['bought']) else 'DIFF')
# Q1 sells from decisions
sells=0
for l in gzip.open(f'{S}/decisions.jsonl.gz','rt'):
    d=json.loads(l); a=d['legal'][d['chosen']]
    if a['type']=='sell' and a.get('card')=='green-recruit': sells+=1
sql=[r for r in tsv('q1c_card_summary_sold_value') if r['card']=='green-recruit'][0]
print('Q1 green-recruit sold python', sells, '| sql', sql['sold'], 'MATCH' if str(sells)==sql['sold'] else 'DIFF')
# Q2: per card boards_with and place_with from games.jsonl final_board
from collections import defaultdict
w=defaultdict(list); allp=[]
for l in open(f'{S}/games.jsonl'):
    g=json.loads(l)
    for s in g['seats']:
        allp.append(s['place'])
        for c in {u['card'] for u in s['final_board']}: w[c].append(s['place'])
bad=0
for r in tsv('q2_final_boards'):
    p=w[r['card']]; pw=round(sum(p)/len(p),3); pwo=round((sum(allp)-sum(p))/(len(allp)-len(p)),3)
    if (len(p),pw,pwo)!=(int(r['boards_with']),float(r['place_with']),float(r['place_without'])): bad+=1; print('diff',r['card'],len(p),pw,pwo,r)
print('Q2 all', len(tsv('q2_final_boards')), 'cards python vs sql:', 'MATCH' if bad==0 else f'{bad} DIFF', '; cards in python', len(w))
# Q5: deaths per fight by round
d5=defaultdict(list)
for l in open(f'{S}/games.jsonl'):
    g=json.loads(l)
    for fr in g['fights']:
        for f in fr['fights']: d5[fr['round']].append(sum(f['result']['deaths']))
bad=0
for r in tsv('q5a_fight_counts'):
    v=d5[int(r['round'])]
    if (len(v), round(sum(v)/len(v),2))!=(int(r['fights']), float(r['deaths_per_fight'])): bad+=1; print('diff', r, len(v), sum(v)/len(v))
print('Q5 deaths/fight all rounds:', 'MATCH' if bad==0 else f'{bad} DIFF')
# Q4: median board attack round 8 (low median, like cume_dist>=0.5)
a=[r['board_attack'] for l in open(f'{S}/games.jsonl') for s in json.loads(l)['seats'] for r in s['rounds'] if r['round']==8]
r8=[r for r in tsv('q4a_round_board_stats') if r['round']=='8'][0]
print('Q4 r8 attack median python low/true', statistics.median_low(a), statistics.median(a), '| sql', r8['attack_median'])
