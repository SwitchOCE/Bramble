# Round 2 playtest

Build 2 (458ed0f), three fresh cloud reviewers, each playing 5 games through `tools/play/play.sh`. All three: **good**, not very good.

## Where they agree

| Item | Who | Next |
|---|---|---|
| Acorns and one huge unit decide the late game (Treasurer 58/66, Hoards) | A, B; C saw bots with 12/12 Chasers by round 5 | Fix: keep the loop, cap the runaway |
| Shops at tier 3+ mostly roll tier 1-2 units | A, C | Fix |
| Early losses cheap, late losses 11-23 Health | A, C | Fix |
| Rules not explained: "ends: board empty", Shy, mired, borrowed, walk-outs, Nest replacing | B, C | Fix |
| Phone layout: Nest captions clipped, side panel overflow, bird hides gold and buttons, scout slots don't line up | A, B, C | Fix |

## Where they split

Birds: C says the Nest loop is the best thing in the game; B says Birds felt weak. Oozes: C says weak and slow; A and B count them as a real build. Settle with the bench, not by taste.

## Reviewer A (economy)

**Games (all Hard):** 1st (Dame Farthing, greedy opening, then Acorns and Treasurer), 7th (Pipkin, Treasurer again, but I got passive at 14 health), 8th (Hob Mumblecrust, borrowing every turn), 8th (Pipkin, saving gold with Money Spider), 7th (Little King Wren, playing for early wins).

**Verdict: good.** It is ready to playtest, but the economy has one line that wins and others that are traps.

**What's best:** Acorns. Squirrel Away turned 2 gold into 6, because three Acorns combine into a Stash worth 5. That made holding versus cashing a real tension: keep the Great Hoard to grow the Treasurers, or spend it on Charcoal Burner or Beltane Bonfire. Charcoal Burner also turns unspent gold into stats, which pulls against Money Spider and Dame Farthing. Fight logs are easy to follow.

**Top problems:**
1. Holding Acorns with the Honorary Treasurer runs away. I had two Great Hoards (41 gold held), Treasurers at 26/28 and up, and Cut-and-Come-Again copying Treasurers. I won the last 4 rounds without shopping. Discover offered the Treasurer in 3 of 5 games.
2. Saving plain gold is a trap. Money Spider paid +1 a turn, and I lost every fight while saving. Hob's borrowing cost 7 Health for 21 gold, and I lost every fight but round 1.
3. Early losses cost only 3–4 Health, so a greedy first two rounds is almost always right. Rainy Day plus A Leg Up beat buying a unit. The opening choice is real but lopsided.
4. Shops at tier 4 and above are mostly tier 1–2 cards. In game 5, three tier-4 shops held no tier-4 unit. Hiring Fair (6 gold) offered the same 3 tier-6 units as a Triple Reward.
5. Pipkin's two-units-a-turn cap breaks a big saved-up turn, and nothing warns you.
6. With a bird held, the phone layout hides gold and the Refresh/Tier buttons. In the CLI, hand numbers shift after you buy, which once made me cash a Hoard by mistake.

**Builds that felt really different:** 2 (Acorns/Treasurer, and board-stats Oozes).

## Reviewer B (board)

**Games played:** 5 on Hard. Places: 8th, 8th, 1st, 7th, 3rd.

**Verdict:** good

**What's best:** where units stand matters on most turns. Each of these came up as a real choice in play:
- **Across-from effects:** Hex, Changeling, Hasty Pudding and Belladonna all hit whoever stands opposite.
- **Gaps:** Bracken rewards empty slots next to units; Mousewife needs empty back slots for her Mice.
- **Shy:** Old Moth Annis buffs whoever stands behind it, and a Shy unit there walks out.
- **Bands and touching:** Rainbow bands only paint when a unit is played into an empty slot, and the Standing Committee wants all seven slots touching.

Scouting changed about 6 of my decisions, such as putting a Pudding across a 28/33 Little Dollop and moving Dozey away from an enemy Pudding.

**Top problems, in order:**
1. **One unit decides the late game.** Acorns snowball: three Stashes combine into a 20-gold Hoard, and Old Mother Mast gives 2 Acorns per buy while you hold one. That fed my 36/39 Dozey and a 58/66 golden Treasurer by round 15. The bots won the same way with a 48/61 Sleeping Partner and a 31/36 Little Dollop. Games do run to round 14–16, but they end in one big trade.
2. **Scouting only pays off about half the time.** Bots rearrange between rounds (Annis moved from F4 to F1, a Pudding from F2 to B1), Whirligig swaps your rows, and the scout shows last round's board. In the phone-size scout view the opponent's slots don't line up with yours, and Ring chips cover some slot labels.
3. **Bug:** the golden Changeling's Start of Combat fired twice. The enemy unit went home with +8/+8 plus my Committee's buff.
4. **Text view gaps:** Shy isn't in the keyword list, and nothing says when a unit walks out (I lost Hob-in-the-Hearth twice). "ends: board empty" doesn't say whose board, and once named no survivor. The hex number on the board differs from what it does in the fight. The log showed an internal id ("mr_crumb").
5. **Screenshots:** `tests/ui/render_screens.sh` renders fine, but its JPEG step fails because this environment's system PIL is broken. I rendered PNGs directly instead.

**Builds that felt really different:** 3. Hedgerow Acorns (the strongest), Fairies Rainbow (strong early, tops out at +14/+14), and Ooze swallowing. Birds and Nests felt weak.

## Reviewer C (new player), as the orchestrator noted it

*Reviewer C's report was read from the run log and not pushed; this is the orchestrator's note of it.*

Games: Easy 2nd, Normal 8th, Hard 5th, Hard 2nd, Normal 6th. Verdict: **good**. Best: the Birds Nest loop, fresh and strong. Builds that felt different: 2.

1. Oozes weak and slow: the front row loses while the power sits inside.
2. The ladder isn't felt: Easy bots had 12/12 Rainbow Chasers by round 5.
3. Late losses cost 11-23 Health; many 0-damage ties.
4. Shops at tiers 3-4 mostly rolled T1-T2 units.
5. Rule clarity: a win says "ends: board empty"; a newer Nest silently replaces Mother Goose's Nest and her strikes; "in front/behind" for the back row is unexplained; whether Birds in hand count for Seven Whistlers; "mired" and "borrowed" aren't in the keyword list; fight logs repeat "+0/+0" lines.
6. UI: Nest slot captions clipped; side panel text runs off its box.
