#!/usr/bin/env python3
"""Add explicitly reconstructed scout/lobby inputs; never claim historical screen equivalence."""
import copy
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
packet = ROOT / 'docs/ideation/evidence/declutter/batch2'
source = json.loads((ROOT / 'docs/ideation/evidence/strong-field/ui-1688x780.json').read_text())
states = json.loads((packet / 'states.json').read_text())
fight = next(x for x in source['human_fight_inputs'] if x['round'] == 8)
state = copy.deepcopy(states['overview']['state'])

def view(spec):
    if spec is None:
        return None
    unit = json.loads((ROOT / 'content/units' / (spec['def_id'] + '.json')).read_text())
    result = copy.deepcopy(spec)
    for key in ['name', 'tier', 'tribes', 'keywords']:
        result[key] = unit.get(key, [])
    result['text'] = unit.get('golden_text' if spec.get('golden') else 'text', '')
    result['max_health'] = result['health']
    result['keyword_text'] = []
    result['counters'] = {}
    return result

state.update(board=[view(x) for x in fight['boards'][0]], next_opponent_last_board=[view(x) for x in fight['boards'][1]], round=8, tier=fight['tiers'][0], gold=7, next_opponent_id=fight['player_ids'][1], slot_effects=fight['slots'][0], next_opponent_last_slot_effects=fight['slots'][1], next_opponent_last_nests=[], hand=[], hand_items=[], away=[], doorstep=[], pending_choice={})
state['bands'] = fight['fight_rules'][0]['bands']
state['standings'] = []
for player in source['game_log']['players']:
    prior = next((x for x in player['rounds'] if x['round'] == 7), player['rounds'][-1])
    standing = dict(player_id=player['player_id'], name=player['name'], hero=player['hero'], health=prior['health'], armor=prior['armor'], tier=prior['tier'], eliminated=prior['health'] <= 0, is_you=player['player_id'] == 0, last_stand_used=False)
    state['standings'].append(standing)
    if player['player_id'] == 0:
        state['health'] = prior['health']
    if player['player_id'] == state['next_opponent_id']:
        state['next_opponent_hero'] = next((json.loads(p.read_text()) for p in (ROOT / 'content/heroes').glob('*.json') if json.loads(p.read_text()).get('name') == player['hero']), {})
provenance = 'Explicit reconstruction: strong-field seed72 round8 recorded combat boards, floor marks, tiers and prior-round standings; shop/economy shell from saved wave1 overview. Original v1 field library unavailable. Exact same reconstruction replayed before/after; not the original historical full-screen scenario.'
for scenario in ['lobby', 'scout']:
    states[scenario] = dict(state=copy.deepcopy(state), seed=72, source=provenance)
(packet / 'states.json').write_text(json.dumps(states, indent='\t', sort_keys=True) + '\n')
print('Added labelled reconstructed lobby/scout fixtures')
