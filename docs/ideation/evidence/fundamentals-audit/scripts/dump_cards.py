import json, glob, os, sys
root = sys.argv[1]
V = {1:5,2:7,3:8,4:10,5:12,6:14,7:18}
rows = []
for f in sorted(glob.glob(os.path.join(root, 'content/units/*.json'))):
    try:
        d = json.load(open(f))
    except Exception as e:
        continue
    if d.get('set') != 'slice':
        continue
    caps = {k: v for k, v in d.items() if 'cap' in k}
    rows.append((d.get('tier'), ','.join(d.get('tribes', [])) or 'Neutral', d.get('name'), d.get('attack'), d.get('health'), d.get('pool'), d.get('text','').replace('\n',' '), d.get('details','') or '', caps))
rows.sort(key=lambda r: (r[1], r[0] or 0, r[2]))
for r in rows:
    t, tribe, name, a, h, pool, text, det, caps = r
    s = (a or 0) + (h or 0)
    print(f"{tribe}|T{t}|{name}|{a}/{h}|sum {s} vs V {V.get(t)}|pool={pool}|{text}|{det}|{caps}")
print(len(rows))
