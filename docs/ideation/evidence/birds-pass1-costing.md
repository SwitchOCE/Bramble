# Birds pass 1: buy-moment costing (8 Nov 2026)

A fresh reviewer. Method: V(t) 5/7/8/10/12/14, ±15% (±25% for gold, scaling and engines), each card priced on the board you'd have when you buy it (change A), against the best slice-pool cards of its tier. Hand estimates, no sims.

**Counts:** 11 fair, 4 over, and 1 under unless enabled (Redbreast, a payoff whose enablers pass). Two are far outside the band: Tom Tit, and the Lump on Goose's Nest. **The owner's test now passes at T1–T2:** every one is a par body on an empty board, and its text is a bonus.

**The competition list is incomplete.** It's missing Pill Bug 1/4, Warty Nan, Madame Bufo, Mrs Sorrel, Toll-Bard, Turnip Scarecrow, Sexton Beetle (2/4, up to 2 gold a fight) and Ballooning Spider. Sexton Beetle sets Jack Daw's bar.

## Verdicts

| Card | Bought, on | Verdict | Reason |
|---|---|---|---|
| One Swallow 1/2 | R1, empty board | fair (+8%) | 3 SP + 2.4 for the first gold. Returns pay 0.33–0.5 gold a turn, which bends the "no recurring gold at T1–2" cap, but cost the body for two fights in three. |
| Chiffchaff 1/2 | R1, empty board | fair | Plays as a 2/3, par. Growth of +1/+1 a 3-turn cycle is under the T1 cap. |
| Mrs Dunnock 2/3 | R1, empty board | fair | A par 5. Her text only matters to Birds later. |
| Mr Redbreast 2/3 | R3, 0–1 Nests | **under** without a Nest (−29%); fair with one | A payoff whose enablers pass. He swings between 2/3 and 3/4 as Birds come home. |
| Redwing 2/4 | R3–4, one Egg | fair | 6 + about 2 from one full-size Egg. Level with Moss Ooze. |
| Mrs Jay 3/3 | R3–4 | fair | The Acorn refunds the sale gold that flying gives up: about 0.33 gold a turn, against a 2/2 Egg two fights in three. |
| **Tom Tit 3/4** | R5, 2 Eggs (the designer's line) | **over, +88%** | 7 + 2 × 4 = 15 against 8. With 4 Eggs it's +16 SP at R12 from a T3. With none it's 7. |
| **Jack Daw 3/4** | R5–6, across a buffed enemy | **over, about +40%** | The steal reads every gain above the card, tribe bonus included. From R6, most units across have gained 4 or more, so the gold fires most fights (3–5 SP), plus a 2–8 SP swing (up to 4/4 off a golden Chaser). Level with Sexton Beetle, which is itself over. |
| Old Tern 2/4 | R5, flown R6 | fair, +20% | The old cost was 7.8; the bigger body adds 2. The first Discover lands about R9. |
| Mrs Stork 3/6 | R7, 2 Birds away | fair | "Must have missed a fight" stops same-turn loops, so each Bird cycles every 2 turns at most. Comparable to Charcoal Burner. |
| Barn Owl 4/5 | R7 | fair | 9 + Swoop and immunity, about 11. |
| Mag Pye 3/5 | R7 | fair | 8 + text removal, about 11. |
| Mother Goose 4/7 | R10 | fair | Unchanged. |
| **The Great Lump 4/6** | R10, on a Nest | **over: +42% on a typical Nest, +75% on Goose's** | One slot holds 17–21 SP against 12, and it replaces the Egg there. Off a Nest it's −17%. |
| **Gabble Ratchet 4/8** | R12, 3 Nests | **over the budget** (about 30 against 14) | Peat King and Whirligig also come to about 28–30, so it's level with the pool. The body bump isn't needed. |
| Seven Whistlers 5/7 | R12 | fair against the pool | 12 + up to 7 × −1/−1, about 27. Whirligig is worth more. |

## The R12 overshoot

The designer's R12 board shows 130, below Oozes (155) and Fairies (151). Goose's 9 damage and the Ratchet's roughly 40 landed stats are in-fight effects; for other tribes the benchmark counts those as keywords. So rank 1–2 is plausible, not certain. The excess is concentrated in two places:
- **Tom Tit** on 2–4 Eggs.
- **Goose's Nest counted three times:** the Lump borrows her 4/7, the Ratchet then lands Goose when the Lump dies, and her Nest still strikes.

The changes below take about 7 SP off the board. Sim before cutting the Ratchet.

## Does every tribe take a T1 or T2?

No T1–T2 card is over. Without Fly South, Chiffchaff, Dunnock and Jay are plain par bodies. One Swallow, turn-1 gold on a 3 SP body, is the one universal candidate. Watch its pick rate in free-choice bots (change C) before nerfing it.

## Proposed changes (each keeps the card's core)

1. **Tom Tit:** 2/4, "Your Eggs have +1/+1" (golden +2/+2). With 2 Eggs that's 10 (+25%); at R12 about 14. Still the reason to leave Birds away.
2. **Jack Daw:** 2/4, both texts kept. That's about 11 (+35% at T3, near par against the T4s it's held into).
3. **The Great Lump:** 3/5, which makes it 6/9 on Jack Daw's Nest (+25%). If R12 still overshoots in sims, add: "On Mother Goose's Nest, the Lump borrows her Egg's 0/2", to match her Egg rule.
4. **Gabble Ratchet:** back to 3/7, text unchanged.
5. **Optional, Mr Redbreast:** 2/4, so he matches Moss Ooze with no Nests.

## Engine check (`src/core/mechanics`)

Data only:
- Stats and tiers on all 16.
- Swallow: drop the `if`.
- Chiffchaff: `buff` with `select: self` on `on_play`. Replays fire `on_play` (rulebook 12.1.4).
- Old Tern: add `"tribe": "Birds"` to the Discover step (`recruit_discover.gd` supports it).
- Golden Lump: `factor` 2 exists.

New code:
- **Tom Tit's Egg aura.** `tom_tit.gd` is still the old Swoop and gold card, and `CombatAuras.recalc` only hooks `RedwingAura.egg_aura`. That needs:
  - an all-Eggs term that uses only the strongest Tom Tit and stacks after Redwing;
  - a call on Goose's 0/2 Egg;
  - updated `tests/core/test_birds.gd`, `test_oozes.gd`, `content/bots/cards.json` and `strategies/birds_highway.json`, which all use the old Tom Tit.
- **To verify:** that Old Tern offers fewer than three where its tier has only two Birds (T5, T6). Untested.
