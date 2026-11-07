# Prototype units

One JSON file per unit, in the format of [docs/prototype/SPEC.md](../../docs/prototype/SPEC.md) section 3. `python3 tools/checks/check_units.py` validates them (also run by `scripts/check.sh`, step `content`). **Prototype content, not designs:** the 16 library units are example units from [mechanics-library.md](../../docs/design/mechanics-library.md) with their rules text and the budget reviews' firm stat fixes; the 24 plain units are filler with placeholder names so shops and the pool work.

- **Priority** is the order the core adds mechanics (SPEC section 10). The 6 **skeleton** units (one plain unit per tier) are the walking skeleton's pool.
- 40 pool units by tier: 9 / 8 / 8 / 6 / 5 / 4, plus one token (Hoglet).
- Plain units have Attack + Health equal to the tier value V(t) in power-budget.md: 5, 7, 8, 10, 12, 14.

## Units

| Priority | Name | Tier | Tribe | Stats | Mechanic | Library entry | Notes |
|---|---|---|---|---|---|---|---|
| 1 | Belladonna Sprite | 6 | Fairies | 4/5 | Nightshade | 75 | budget fix (library 5/8) |
| 2 | Bitter Toad | 5 | Bog folk | 3/7 | Nightshade | 75 | budget fix (library 4/9) |
| 3 | Hoglet Mother | 2 | Hedgerow folk | 1/3 | Bristle | 7 |  |
| 4 | Sett Warden | 3 | Hunters | 1/4 | Hunker | 1 | budget fix (library 2/8) |
| 5 | Garden Snail | 1 | Neutral | 1/3 | Shell | 4 |  |
| 6 | Mudwallow Toad | 2 | Bog folk | 2/4 | Pin | 11 |  |
| 7 | Fox Notary | 1 | Hunters | 1/3 | Bystander | 13 |  |
| 8 | Weasel Second | 3 | Hunters | 2/4 | Quick | 24 |  |
| 9 | Ermine Duellist | 5 | Hunters | 6/4 | Quick | 24 | budget fix (library 7/5) |
| 10 | Drumming Woodpecker | 3 | Birds | 2/3 | Peck (X) | 5 | budget fix (library 4/4) |
| 11 | Worker Bee | 1 | Hive | 2/2 | Swarm | 25 | budget fix (library 1/1) |
| 12 | Hedgehog Twin | 2 | Hedgerow folk | 2/3 | Both Ends | 45 |  |
| 13 | Hazel Dormouse | 1 | Hedgerow folk | 1/3 | Bide | 9 |  |
| 14 | Marmot Lookout | 2 | Hedgerow folk | 0/4 | Whistle | 10 |  |
| 15 | Fox Cub | 1 | Hunters | 2/2 | Mark | 40 | budget fix (library 2/1) |
| 16 | Still-Water Heron | 2 | Birds | 2/2 | Fast (action, N) | 56 | budget fix (library 3/2, Feast +4/+4) |
| — | Dewdrop Ooze | 1 | Oozes | 2/3 | — | — | skeleton set; plain filler |
| — | Field Vole | 1 | Hedgerow folk | 2/3 | — | — | plain filler |
| — | Hoglet | 1 | Hedgerow folk | 1/1 | Bristle | 7 | token, not in pool |
| — | Marsh Frog | 1 | Bog folk | 1/4 | — | — | plain filler |
| — | Pixie Scout | 1 | Fairies | 3/2 | — | — | plain filler |
| — | Fieldfare | 2 | Birds | 4/3 | — | — | skeleton set; plain filler |
| — | Hedge Sprite | 2 | Fairies | 2/5 | — | — | plain filler |
| — | Moss Ooze | 2 | Oozes | 3/4 | — | — | plain filler |
| — | Bramble Ooze | 3 | Oozes | 4/4 | — | — | plain filler |
| — | Brownie Porter | 3 | Fairies | 3/5 | — | — | plain filler |
| — | Carrion Crow | 3 | Birds | 4/4 | — | — | plain filler |
| — | Common Toad | 3 | Bog folk | 5/3 | — | — | plain filler |
| — | Wood Mouse Guard | 3 | Hedgerow folk | 4/4 | — | — | skeleton set; plain filler |
| — | Bog Ooze | 4 | Oozes | 5/5 | — | — | plain filler |
| — | Buzzard | 4 | Birds | 6/4 | — | — | plain filler |
| — | Crested Newt | 4 | Bog folk | 6/4 | — | — | plain filler |
| — | Hedgerow Elder | 4 | Hedgerow folk | 4/6 | — | — | plain filler |
| — | Moth Fairy | 4 | Fairies | 4/6 | — | — | plain filler |
| — | Stoat Captain | 4 | Hunters | 5/5 | — | — | skeleton set; plain filler |
| — | Fairy Knight | 5 | Fairies | 5/7 | — | — | skeleton set; plain filler |
| — | Great Ooze | 5 | Oozes | 6/6 | — | — | plain filler |
| — | Old Badger | 5 | Hunters | 7/5 | — | — | plain filler |
| — | Elder Ooze | 6 | Oozes | 7/7 | — | — | skeleton set; plain filler |
| — | Fairy Monarch | 6 | Fairies | 6/8 | — | — | plain filler |
| — | Old Crane | 6 | Birds | 8/6 | — | — | plain filler |

## By tribe and tier (pool units)

| Tribe | T1 | T2 | T3 | T4 | T5 | T6 | Total | Of which library |
|---|---|---|---|---|---|---|---|---|
| Fairies | 1 | 1 | 1 | 1 | 1 | 2 | 7 | 1 |
| Oozes | 1 | 1 | 1 | 1 | 1 | 1 | 6 | 0 |
| Hedgerow folk | 2 | 3 | 1 | 1 | 0 | 0 | 7 | 4 |
| Hunters | 2 | 0 | 2 | 1 | 2 | 0 | 7 | 5 |
| Birds | 0 | 2 | 2 | 1 | 0 | 1 | 6 | 2 |
| Bog folk | 1 | 1 | 1 | 1 | 1 | 0 | 5 | 2 |
| Hive | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| Neutral | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| **All** | 9 | 8 | 8 | 6 | 5 | 4 | 40 | 16 |

Oozes and Fairies are mostly filler: the library has only three Ooze units (Bud, entry 30, which needs an open split ruling), and most Fairy units need systems the prototype doesn't have. See SPEC section 10, "Library gaps".
