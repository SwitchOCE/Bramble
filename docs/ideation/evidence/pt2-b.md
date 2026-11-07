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
