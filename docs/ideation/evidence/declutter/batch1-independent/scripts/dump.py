import json, sys
p = sys.argv[1]
d = json.load(open(p))
ev = d['events']
units = {}
pos = {}
start = ev[0]
for side, board in enumerate(start['boards']):
    for slot, u in enumerate(board):
        if u:
            units[int(u['uid'])] = u
            pos[int(u['uid'])] = (side, slot)
def nm(uid):
    if uid is None: return 'None'
    uid = int(uid)
    u = units.get(uid)
    s = pos.get(uid)
    lab = ''
    if s:
        side, slot = s
        lab = ('S%d' % side) + ('F%d' % (slot+1) if slot < 4 else 'B%d' % (slot-3))
    return '%s#%d(%s)' % (u['name'] if u else '?', uid, lab)
print('first_side', start.get('first_side'), 'slot_effects', json.dumps(start.get('slot_effects')))
for side, board in enumerate(start['boards']):
    for slot, u in enumerate(board):
        if u:
            print(' ', nm(u['uid']), '%d/%d' % (u['attack'], u['health']), u['def_id'], 'gold' if u['golden'] else '', u['keywords'], '|', u['text'], 'held=%s' % u.get('held'), u['statuses'])
attack_idx = set(a['event_index'] for a in d['attacks'])
for i, e in enumerate(ev[1:], 1):
    if i in attack_idx: print('=== ATTACK', i)
    t = e['type']
    if t == 'summon':
        u = e['unit']; units[int(u['uid'])] = u; pos[int(u['uid'])] = (int(e['side']), int(e['slot']))
        print(i, 'summon', nm(u['uid']), '%d/%d' % (u['attack'], u['health']), 'src', nm(e.get('source')), u['text'])
        continue
    if t == 'death':
        print(i, 'death', nm(e['uid'])); continue
    if t in ('attack',):
        print(i, 'attack', nm(e['attacker']), '->', nm(e['defender']), 'joiners', [nm(j) for j in e['joiners']], 'side', e['side'], 'quick', e['quick'], 'strikes', e['strikes']); continue
    if t == 'damage':
        print(i, 'damage', nm(e['source']), '->', nm(e['target']), e['amount'], 'after', e['health_after'], e['kind'], e['modifiers']); continue
    if t == 'stats':
        print(i, 'stats', nm(e['target']), 'src', nm(e['source']), '%d/%d' % (e['attack'], e['health']), 'd', e['attack_delta'], e['health_delta'], e['cause'], e['causes'], 'perm' if e['permanent'] else ''); continue
    rest = {k: v for k, v in e.items() if k not in ('seq', 'type')}
    for k in ('uid', 'source', 'target', 'hunter', 'quarry', 'attacker', 'defender', 'maker'):
        if k in rest and isinstance(rest[k], (int, float)): rest[k] = nm(rest[k])
    print(i, t, json.dumps(rest))
