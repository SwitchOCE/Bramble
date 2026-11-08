# Design round 5: critic and costing reports

Three fresh agents reviewed `design5.md` as drafted (commit on this branch before the revision), independently: none saw the others' reports. Briefs: Critic A on strategy depth, Critic B on simplicity and the newcomer, both with the owner's principles (owner-taste §1) and the library, without the power budget. The costing agent read `docs/design/power-budget.md` and the library. The reports are as returned, lightly formatted. What the designer did with each point is in `design5.md` §4–5.

## Critic A: strategy depth

**Verdicts**
1. **The Farrier: change.** It is the only idea that hits Rings directly, and Scout makes placing it a real decision. But a tier 3 3/4 is a dead slot against the roughly two-thirds of opponents who run no Rings. Halving one Ring takes about 9 off a board of about 170 stats, so the effect stays small unless that Ring is the pile.
2. **Barn Owl: keep.** It creates a real defender choice: leave the back row empty, add a decoy, or Mire it. It kills the small back-row engines. It does nothing against piles, so it helps problem 3, not problem 1.
3. **Redwing: change.** Summer/Winter loses to early tempo, but Redwing pays out from about turn 5 and maxes each Bird after two trips. By turn 11 its +10/+10 is about one or two Stand Behind Me casts. It also adds permanent stats, which is problem 1 again.
4. **The Cuckoo: keep.** Players have to plan which Bird flies from which slot. Hatching a buffed Bird isn't always worth it. The payoffs are real: a hatched Jack Daw steals from piles and pays gold, and Mother Goose's 0/2 Egg becomes a printed 4/7. Early Birds gain only about +1/+1 from a hatch, so its tempo help is modest.
5. **The Jelly Mould: change.** It is the owner's own example and adds strong counterplay. As written, its best line is a Ring pile that dies twice.
6. **The Old Pike: change.** It is a strong answer to token boards, but it has a rules hole (below), and it suits being the pile carrier too well.
7. **The Pedlar: change.** It is the owner's own economy kind, but with a board full of pairs it gives a near-guaranteed triple every turn. That is an early solved line.
8. **Market Stall: cut to variation (a) or (c).** After the first one, buying a Stall is automatic. It caps at 6 gold in all, so it can't absorb a late bank of 56. It is dead for a Pipkin player, whose shop is already 7.

**Problems, with fixes that keep each card's core**
- **Mould plus Rings (scenario).** Nan Toadstool sits on F2 with +12/+12 of Rings, making her 14/13, and the Mould is on F3. Nan dies, and the printed 2/1 copy lands on the same Ring as a 14/13 again. That is about 13 free stats on the pile tribe, the Mould is offered to Fairy players in any lobby with Oozes, and the Farrier is then the only answer.
  - **Fix:** use the Peat King's existing wording, "summon a copy in your empty slot nearest it". The copy leaves the Ring, no new rule is needed, and keeping a gap becomes a placement cost.
  - **Also spell out** how it treats Cradle Fetch: does it copy the printed Fetch, or what the Fetch became?
- **Pike loses its text to Hunters.** In `engine.md` the targeting order puts quarry before a unit's own targeting text. The Laird of the Sett gives quarry to all your units, and Young Brock and Old Brock give it to their neighbours, so the Pike stops hunting. The same happens to the Owl's Swoop.
  - **Fix:** add "This never takes quarry" to the Pike and the Owl.
- **Pike as a carrier (scenario).** Stand Behind Me makes it 20/20. It then kills an Egg or token on every attack, never meets the enemy pile, and keeps itself alive for performance damage. It is a strictly better pile carrier than any vanilla body.
  - **Fix:** make variation (b), lowest Attack, the main card. Or add "If this has more than 10 Attack, it attacks normally."
- **Pike variation (c) contradicts the card.** It spares textless units, but Kits, Shrewlets, Drips, Wisps and Nymphs are textless. That cancels the Hedgerow Spill example.
  - **Fix:** if Birds need protecting, spare only Eggs.
- **Pedlar pairs (scenario).** At tier 3 the board is Wick ×2, Fox Cub ×2, Mr Crumb ×2 and the Pedlar. On 6 turns in 7 its offer completes a triple, so a Triple Reward Discover comes almost every turn from about turn 5. Figgy Duff speeds this up. The Pedlar also counts itself.
  - **Fix:** "...a random other unit on your board... 3 times in all." That is the existing bound on the Sixpenny Pie and Sleeping Partner. Variation (a) is worse, because a deterministic aim guarantees triples.
- **Farrier is dead most rounds.**
  - **Fix:** put Horseshoe, variation (b), in as the main card. It is a 1-gold spell bought after scouting, so it never wastes a slot. That is the cleanest scouting decision anywhere in this round. Keep the unit as the golden or tier 5 Iron Gate.
  - **Watch Steal, variation (a).** It doubles the swing: a Farrier steals 9, becomes 12/13, and totals decide fights. Too arbitrary for P3.
- **Redwing** should fix tempo, not add stats.
  - **Fix:** "Eggs beside this have their Bird's full current stats", or "+2/+2 for each fight missed". This aims at the loss while the Bird is away, which is what bots punish. It also blunts the Pike's pressure on Eggs.
- **Cuckoo plus Gabble Ratchet.** A hatched copy dies, then the real Bird lands, so one Nest gives three bodies, all with text. A golden Cuckoo does it on two Nests. This is fine at tier 6, but log it.
- **Market Stall.** A third Stall shows up in the shop as a dead card, which is the clutter P1 dislikes.
  - **Fix:** it stops being offered to you once you hold 2. With Pipkin it should still give spell slots, as in variation (b).
- **Barn Owl as a carrier.** Behind a Burner, the Owl is a protected back-row carrier. That is harmless, because a big Owl takes little damage anyway, so "no damage" only matters while it's small. Keep "half damage" as the fallback.

**Section 3**
- **Jack Daw's "P1" shortening is a power change.** A flat +3/+3 once the enemy has 3 gains is much stronger early than "a quarter, up to +4". It should be labelled as a power change.
- **Hasty Pudding's short version drops "when its side has nobody else".** That rule seems to end the fight correctly, and removing it may leave a fight that can't finish. Keep it.
- **Missing: Bread from the Back.** It has the same strain as Stand Behind Me, and the "kin only" variation should cover both.
- **Missing: Cut-and-Come-Again.** A repeating stream of units every other turn is a P4 watch item.
- **Missing: Old Tern with Mrs Stork.** This is a repeatable Discover engine, and Redwing or Dunnock make it stronger. It is bounded, but belongs on the watch list.
- **Belladonna Sprite has two names-alike cards.** There is a tier 5 and a tier 6 card with different texts (`belladonna.json`, `belladonna_sprite.json`). That is a P1 reading hazard worth a note.

**Top 4 for the next build, ranked by how much they help the open problems**
1. **The Farrier, with Horseshoe.** It hits problems 1 and 4 directly at the Rings, and the decision comes from scouting.
2. **The Jelly Mould, with the nearest-gap fix.** It covers problem 3 with the owner's own example, and the Owl, Pike, Pudding and Butcher-bird all counter it.
3. **The Cuckoo.** It helps problems 2 and 3: positional Bird decisions, and a Jack Daw hatch that steals from piles.
4. **Barn Owl, with "never takes quarry".** It covers problem 3 and gives back-row engines a weakness the defender has several ways to answer.

Fifth, if economy (problem 5) needs a slot: the Pedlar with "3 times in all". Hold Redwing until it is reworked toward tempo.

## Critic B: simplicity and the newcomer

**Context from the library.** Bramble already has a lot of rules vocabulary. There are about 22 keywords (Belly, Nest/Egg, Mire, Quarry, Pass, Pack, Pounce, Ring, Rainbow and others), plus geometry words: across, beside, in front, behind, touching, nearest gap, and the Pass zigzag. Some phrases already exist and new cards can reuse them for free: "as printed" (Cradle Fetch), "pool copy… into your shop" (Mistress Russet), "wherever it stands" (Snap) and "the enemy across" (Hex). The ideas below are judged against that baseline.

**Verdicts**

1. **Farrier: keep.** It reuses Hex's "enemy slot across" wording, and the halved Ring number shows on the board, so a replay explains itself. Its counter is shown by where it stands, which beats a Silence effect.
2. **Barn Owl: keep.** It adds one clause to a known keyword, and a replay showing "0 damage taken" is easy to read. It does add a Bristle/Bitter edge case, but that follows from existing rules and isn't new text.
3. **Redwing: simplify.** "Up to +4/+4 per Bird this game", with each Redwing tracking its own cap, is hidden state for every Bird. Nothing on the board shows how much of the cap a Bird has used. The card only works if the UI puts a counter on each Bird.
4. **The Cuckoo: cut to variation (a).** It adds four things at once: the "to the left" geometry, a third slot state (hatched copy), a "first of all" timing slot, and a Gabble Ratchet edge case. That's too much for one tier 3 card.
5. **Jelly Mould: simplify.** The core (Reborn by position) reads well in a replay because the unit reappears in its slot. But "to the left" is a new selector for this card alone. Use "in front of this", which is variation (a).
6. **Old Pike: keep.** It's one line, close to Snap and Zapp, and a replay draws it as a single arrow. Don't adopt variation (c): "has rules text" is a hidden filter, because newcomers can't tell textless from vanilla at phone size. The Butcher-bird adds a new rule word ("can't be summoned back"), so hold it until copies prove to be a problem.
7. **Pedlar: keep, but shorten.** It changes the shop, not the fight, so there's no replay cost. It needs a visible badge on the Pedlar's shop slot.
8. **Market Stall: simplify.** A permanent +1 is easy to understand, but more shop slots risk the clutter P1 warns about: late shops full of cards players learn to skip. Aim the extra slot at your own tier (wording below).

**Rewordings**

- **Farrier:** "Start of Combat: the Ring across from this gives half." Rounding goes in the Ring reminder text. The golden version reads "…across from this and beside that."
- **Barn Owl:** "Swoop. Takes no damage when attacking the back row."
- **Redwing:** "When one of your Birds comes home, it gains +1/+1 permanently per fight it missed (max +4/+4 per Bird)." Show pips on the Bird. If the counter UI is too costly, use "…gains +2/+2 permanently, twice per Bird". That loses the choice of whether to shorten trips with Mrs Dunnock but is easier to read.
- **Cuckoo:** "Eggs beside this have their Bird's text." This drops the copy state, the left geometry and the ordering rule.
- **Mould:** "Once a fight, when the unit in front of this dies, summon a copy of it, as printed, in its slot." Standing in the back row protects it, which is a sensible position. The Belly order rule stays the existing "nearest gap" rule.
- **Pedlar:** "Start of your turn: one shop slot shows a pool copy of a random unit on your board." Keep "your tier or lower" only if Discover can put a higher-tier unit on your board, and if so put it in the rules rather than on the card.
- **Market Stall:** "Rest of game: your shop shows 1 more unit, always of your tier. Max 2 Stalls." The 7-unit cap belongs in the rulebook. This version turns the P1 negative example around: the extra slot is never one players learn to ignore.

**Section 3 shorter texts**

- **Dishwater Nell:** clearer, but losing the Ooze-touching gold removes its only link to Oozes. It's acceptable as a variation, but say that it drops the tribe lean.
- **Hasty Pudding:** clearer, but "only when this dies" removes the defender's escape hatches, which goes against P3 (counterplay). Keep one: "…when this dies or after 3 of your units die."
- **Jack Daw:** the flat +3/+3 is clearer. But "then get 1 gold" now pays unconditionally, which changes the economy, and "enemy across's gains" reads badly. Use: "Start of Combat: take up to +3/+3 of the enemy across's bonus stats. If you took any, get 1 gold next turn."
- **Pipistrelle:** clearer, and the result is the same. Good.
- **Mag Pye:** moving the Belly edge rule to reminder text is good. But the proposed text drops "first of all" and the fact that the enemy loses its text, which is the core of the card. Use: "Start of Combat, first of all: steal the text of the enemy across for this fight."
- **Elsewhere:** "Burner, kindled" (a per-unit game cap from Burners) and "Rings fading" (a new End-of-Turn decay) each add hidden state. Prefer the simpler variation in each row: "Rings stop at +12/+12" reuses Alderman Dozey's existing cap wording.

**Top 4 for the next build**

1. **Old Pike.** It adds positioning counterplay and pressure on fragile engines and wide token boards, at almost no reading cost.
2. **Farrier** (short text). It hits Rings, the largest single source of late stat piles (27%), by position, using an idea players already know from Hex.
3. **Barn Owl.** It's the Birds' scam tool and makes the back row unsafe, which is where Burner's and Stand Behind Me's stats end up. It costs one clause.
4. **Market Stall** (own-tier version). It gives late surplus gold somewhere to go besides the pile, competing with the Burner and Last Orders, and it's a bounded, delayed kind of economy. Its newcomer cost is one easy decision.

**Runner-up: Redwing** (capped, with pips). Pick it over the Stall if the Birds' Summer/Winter route must be addressed this build, since none of the top 3 targets that problem. It costs more reading than the others, and it needs a UI counter to stay readable.

## Costing (read docs/design/power-budget.md)

**Calibration first.** The vanilla bodies in the library sit exactly on V(t) = 5/7/8/10/12/14 (Fieldfare 7, Carrion Crow 8, Buzzard 10, Fairy Knight 12, Old Crane 14), so the two agree on body stats. They disagree on spells:

- **Library rate:** about 2–3.3 SP per gold. Pinch of Dust gives 2 for 1 gold. Spore Cloud gives about 4.4 for 2 gold, and Boundary Stone about 6.6 for 2 gold, once the 1.1 slot factor is applied. Last Orders gives about 1 SP per gold spent.
- **Budget rate:** S(t) = 4–5 SP per gold.

So library spells run about 35–55% under the budget, and the library's late sink is nearer 1–2 SP/gold than 2.0. I judged the spell and economy ideas against the library (Market Day, Hiring Fair). The base shop is 3/4/4/5/5/6 by tier (`game_config.gd`), and I used that for the Stall and Pipkin checks.

| Idea | Budget estimate (body + text vs V) | Verdict | Fix that keeps the core |
|---|---|---|---|
| **The Farrier** T3 3/4 | 7 + about 2–4 expected. Halving a Ring removes about 1.1 × half the Ring; it's live maybe a third of fights, worth 10–20 SP when live late. Total about 9–11 vs 8 | On to slightly over (+10–30%). Inside the ±25% band because it targets a slot (T14). Swingy, which suits a counter | Ship as is. Variation (a), Steal, roughly doubles the swing: drop it to 2/3. Golden 6/8 covering 3 slots is about 2× in practice, because Rings are usually stacked on one slot |
| **Barn Owl** T4 3/4 | 7 + Swoop about 1 (the Ballooning Spider benchmark) + no damage when attacking the back row. That is roughly a shield on each of about 1.3 attacks, realised about 3–4. Total about 11–12 vs 10 | Edge of ±15% (+10–20%) | Keep it. If measured hot, use the designer's "takes half damage", or make it 3/3. Golden 6/8: the immunity doesn't double, about 20 vs 20, on |
| **Redwing** T2 2/2 | 4 + flock growth of about 4 SP per homecoming, about 1.25 homecomings a turn, × 0.6 for the tribe condition, × about 0.7 because Birds are away. Per-turn scaling at c(2) = 3.7 gives about 10–14 vs a text allowance of 3. It also sits far above the T2 growth cap of 1.3 SP/turn | **Over, +60–100%** against the budget. Against the library it's similar to Still-Water Heron, which section 3 already flags for P5 | **Make the cap shared:** "up to +4/+4 per Bird from all your Redwings" (golden +8/+8). Then either move it to T3 at 2/3, or keep T2 with the shared cap at +2/+2 |
| **The Cuckoo** T3 2/4 | 6 + (printed Bird minus Egg, about 4–6, plus the Bird's text) × about 0.5 for Nest placement × 0.6 tribe ≈ 3–4. Total about 9.5 vs 8 | Slightly over (+15–20%) in Birds builds | Body 2/3. Or rule that a hatched copy dying doesn't trigger the Gabble Ratchet (that pairing is a second life on top of a second life). Mother Goose's 0/2 Egg hatching into a 4/7 is the strongest single line; watch it |
| **The Jelly Mould** T4 2/5 | 7 + a printed copy of the unit to its left, worth about 0.8 × 12, firing about 0.75 of fights ≈ 7. Total about 14 vs 10. With a Ring the copy also gets about 5–10 more | **Over, +35–40%; +70% or more with a Ring** | Move to **T5, keep 2/5**: about 14 vs 12, inside ±25% since copy effects (E31) use that band. Add variation (c), "the copy has no Ring". Golden "twice a fight" ≈ 2× without a Ring; with one it's a slot that lives three times, so give the golden the no-Ring rule too |
| **The Old Pike** T3 3/3 | 6 + targeting about 2–3 (sure kills on tokens, reaches the back row, takes little return damage). Total about 8.5–9 vs 8 | **On** (0–15%) | None. The Butcher-bird variation adds a hard counter worth about 1 SP: make it 2/3 or T4. Golden 6/6 is on |
| **The Pedlar** T2 2/3 | 5 + about 1 refresh's worth a turn (about half a gold a turn recurring) ≈ 3. Total about 8 vs 7 | On to +20% early. **Over late**: "of your tier or lower" means your player tier, so a T2 body becomes a T6 triple engine | Cap the copy at **tier 4 or lower** (golden: 5). Also add **"not a Pedlar"** so it can't fetch itself and spiral into a golden Pedlar. With those, golden two slots is about 16.5 vs 14, fine |
| **Market Stall** spell T3, cost 3 | Each extra card adds 17–25% to every shop seen. Mid-to-late that's about 0.5–1.5 refreshes saved a turn, permanently. Bought around turn 6, about 4–8 gold over the game for 3 gold, with no slot used. The nearest library comparison, Market Day, costs 3 for one turn | **Over, +25–50% if bought early**, on if bought late | **Cost 4, offered from T4.** Keep the 7-card cap, which already makes the second Stall dead at T6 and makes Pipkin plus Stall self-limiting |

### Economy loops (r ≥ 1 or feedback)

- **Pedlar.** None of the new economy cards returns gold, so nothing crosses r ≥ 1 in gold; Pedlar and Stall raise how often you hit, not your income. The real loop is "more copies → triples → Triple Reward → higher-tier units the Pedlar can then copy" (Figgy Duff and Mistress Russet join it). The tier cap and the no-self-copy rule break it.
- **Market Stall with Pipkin.** Pipkin's +2 already hits the 7 cap at T5, and Pipkin allows only 2 buys a turn, so there's no loop. **New flag: Stall with Stone Soup.** Stone Soup buffs every shop unit after each Belly buy, so each Stall adds about 2 SP per Belly buy. Check it in the next build.
- **Redwing with several copies.** Copies stack today, so a golden plus a normal Redwing gives +12/+12 per Bird. The shared cap fixes it. Eggs at half the Bird's stats compound mildly (bigger Bird, bigger Egg); fine once the cap is in.

### Section 3 caps

- **Burner, kindled, +8/+8 per unit:** that's about 3 turns of full burning. It doesn't neuter the card, it keeps bank-or-buy, and swapping in a new unit behind it resets the cap, which rewards upgrading carriers. Good.
- **Rings stopping at +12/+12:** that's 4 Boundary Stones on one slot, and the round-12 pile drops from +19 to +12. It doesn't neuter the card. It should say whether Fairy Monarch's +1/+1 counts inside the cap. The "fading" variation would hit neutral Stone and Spore Cloud users hard. Prefer the cap.
- **Last Orders up to +8/+8:** the cap binds only past about 16 gold spent. Normal T5–6 turns (10–14 gold) are untouched, so it bites only on banked turns, which is the target. Good. **Gap: Beltane Bonfire has no capped variation.** On a 56-gold bank it gives +14/+14 to a row (about 110 SP). Suggest "up to +6/+6".
- **Heron +8/+8, Tiddy Mun +6/+6, Grizel +6 Attack:** all reasonable, none neutered.
- **Consistency:** Alderman Dozey already prints a +12/+12 permanent cap. I'd suggest one rule: +8/+8 for a single source, +12/+12 per unit or slot.

### Summary

- **Over the budget:** the Mould, Redwing and Market Stall need the fixes above before the next build.
- **Slightly over:** the Cuckoo and the Pedlar's late game.
- **On:** the Farrier, Barn Owl and Old Pike.
