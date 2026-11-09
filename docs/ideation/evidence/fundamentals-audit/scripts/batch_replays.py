import sys, json, random, os, time, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parse_bg_replay import parse
S = sys.argv[1]; n = int(sys.argv[2]); out = sys.argv[3]
games = json.load(open(os.path.join(S, 'web/perfect.json')))
random.seed(11)
random.shuffle(games)
dl = os.path.join(S, 'web/replays/dl'); os.makedirs(dl, exist_ok=True)
fo = open(out, 'a')
t0 = time.time(); k = 0; fails = 0
for g in games:
    if k >= n or fails > 5: break
    p = os.path.join(dl, 'cur.xml.zip')
    r = subprocess.run(['curl', '-s', '-f', '-o', p, 'https://xml.firestoneapp.com/' + g['replayKey']])
    if r.returncode != 0:
        print('fail', g['reviewId'], r.returncode, flush=True); fails += 1; continue
    try:
        res = parse(p)
    except Exception as e:
        print('parsefail', g['reviewId'], e, flush=True); continue
    finally:
        if os.path.exists(p): os.remove(p)
    fo.write(json.dumps(dict(reviewId=g['reviewId'], rank=g['playerRank'], hero=g['playerCardId'], turns=g['gameDurationTurns'],
                             tribes=g['bgsAvailableTribes'], archetype=g.get('archetype'), anomalies=g.get('bgsAnomalies'), combats=res)) + '\n')
    fo.flush(); k += 1
    if k % 10 == 0: print(k, round(time.time() - t0), 's', flush=True)
    time.sleep(1)
print('done', k, 'fails', fails, round(time.time() - t0), 's')
