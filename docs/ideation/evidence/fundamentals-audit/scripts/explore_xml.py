import sys, xml.etree.ElementTree as ET
path = sys.argv[1]
target_turn = int(sys.argv[2])
turn = 0
printing = 0
ents = {}
for ev, el in ET.iterparse(path, events=('start',)):
    t = el.tag
    a = el.attrib
    if t == 'TagChange' and a.get('entity') == '4' and a.get('tag') == '20':
        turn = int(a['value'])
        print('TURN ->', turn)
        if turn == target_turn: printing = 1
        elif printing: break
    if printing and printing < 400:
        if t in ('FullEntity', 'ShowEntity', 'Block', 'TagChange', 'ChangeEntity', 'HideEntity'):
            s = {k: v for k, v in a.items() if k != 'ts'}
            if t == 'TagChange' and s.get('tag') not in ('49','50','263','47','45','19','198','20','1196','1373'): continue
            print(t, s)
            printing += 1
