"""Stream-parse one HSReplay XML (zip) from Battlegrounds; snapshot both boards at each combat.
Snapshot A (pre): main player's board when BOARD_VISUAL_STATE goes to 2 (combat starts), like Firestone.
Snapshot B (first attack): both sides' minions in PLAY at the first ATTACK block of the combat
(after start-of-combat effects). Output one JSON line per combat."""
import sys, json, zipfile, xml.etree.ElementTree as ET

ATK, HEALTH, DAMAGE, ZONE, CONTROLLER, CARDTYPE, PREMIUM, ZONEPOS = 47, 45, 44, 49, 50, 202, 12, 263
BVS, TECH, PLACE, ARMOR = 1347, 1377, 1373, 292
PLAY, MINION, HERO = 1, 4, 3

def parse(zpath):
    z = zipfile.ZipFile(zpath)
    f = z.open(z.namelist()[0])
    ents = {}
    main_pid = None; opp_pid = None
    game_id = None
    bvs = 0
    combat = 0
    pre = None
    took_first = False
    out = []
    cur = None  # entity being defined (FullEntity/ShowEntity/ChangeEntity)
    def board(pid):
        res = []
        for e in ents.values():
            if e.get(CONTROLLER) == pid and e.get(ZONE) == PLAY and e.get(CARDTYPE) == MINION:
                res.append((e.get('card', ''), e.get(ATK, 0), e.get(HEALTH, 0) - e.get(DAMAGE, 0), e.get(PREMIUM, 0), e.get(ZONEPOS, 0)))
        res.sort(key=lambda r: r[4])
        return res
    def hero(pid):
        for e in ents.values():
            if e.get(CONTROLLER) == pid and e.get(ZONE) == PLAY and e.get(CARDTYPE) == HERO:
                return dict(card=e.get('card', ''), hp=e.get(HEALTH, 0) - e.get(DAMAGE, 0) + e.get(ARMOR, 0), tier=e.get(TECH, 0), place=e.get(PLACE, 0))
        return None
    for ev, el in ET.iterparse(f, events=('start', 'end')):
        t = el.tag
        if ev == 'start':
            a = el.attrib
            if t == 'GameEntity':
                game_id = a['id']; cur = ents.setdefault(game_id, {})
            elif t == 'Player':
                if a.get('isMainPlayer') == 'true': main_pid = int(a['playerID'])
                else: opp_pid = int(a['playerID'])
                cur = ents.setdefault(a['id'], {})
            elif t in ('FullEntity', 'ShowEntity', 'ChangeEntity'):
                eid = a.get('id') or a.get('entity')
                cur = ents.setdefault(eid, {})
                if a.get('cardID'): cur['card'] = a['cardID']
            elif t == 'Tag' and cur is not None:
                cur[int(a['tag'])] = int(a['value'])
            elif t == 'TagChange':
                eid = a['entity']; tag = int(a['tag']); val = int(a['value'])
                ents.setdefault(eid, {})[tag] = val
                if eid == game_id and tag == BVS:
                    if val == 2 and bvs != 2:
                        combat += 1
                        pre = board(main_pid)
                        took_first = False
                    bvs = val
            elif t == 'Block' and a.get('type') == '1' and bvs == 2 and not took_first:
                took_first = True
                out.append(dict(combat=combat, pre=pre, me=board(main_pid), opp=board(opp_pid),
                                me_hero=hero(main_pid), opp_hero=hero(opp_pid)))
        else:
            if t in ('FullEntity', 'ShowEntity', 'ChangeEntity', 'GameEntity', 'Player'):
                cur = None
            el.clear()
    return out

if __name__ == '__main__':
    res = parse(sys.argv[1])
    for r in res:
        print(json.dumps(r))
