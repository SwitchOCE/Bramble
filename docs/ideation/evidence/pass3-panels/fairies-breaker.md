# Fairies, pass 3: the breaker's critique

9 Nov 2026. Adversarial review of the three Fairies designs: `fairies-engine.md` (the growing Fairy Ring), `fairies-carry.md` (the Throne and Glamour) and `fairies-wild.md` (Rings × Ring size). Paper only. Every number below comes from the designers' own rules and models, or from `fairies-breaker-stack.py` in this folder (`python3 -I fairies-breaker-stack.py`).

**In short:** Wild wins. It has the biggest reward moments, the best per-fight decision and the most Fairy identity. But its common case runs hot, because second copies stack: 2–2.5× the target at round 10 with one extra Cluricaun. Carry comes second. It has the most real decisions and the best wording, but it runs about half the target from round 12. Engine comes third. Its main decision is solved by its own line policy, its Wisp route is 1.7× the target at round 7, and the round Annis arrives fixes the final board size.

---

## 0. One yardstick first

The three designs measure against different targets. Engine and Wild use the September 2025 mean (759 at R12). Carry uses a softer "median / strong" row (500 / 700 at R12). `reference-curves.md` puts the September 2025 median near 560. Read on one scale, the typical lines are:

| Typical line | R7 | R9 | R12 | R15 | Note |
|---|---|---|---|---|---|
| Target mean (Sep 2025) | 79 | 194 | 759 | ~2,600 | Median at R12 about 560 |
| Engine, carry route | 65 | 155 | 474 (0.62×) | 2,260 | On the target's shape |
| Engine, Wisp route | **135 (1.7×)** | **313 (1.6×)** | 914 (1.2×) | 3,476 | Common mid-game spike |
| Carry, throne | — | 174 | **377 (0.50×)** | **1,130 (0.43×)** | Under target from R12 |
| Carry, wide | — | 149 | 467 (0.62×) | 1,798 | |
| Wild, ring (designer's "typical") | — | 222 | 659 (0.87×) | 2,151 | |
| Wild, ring, every engine piece | — | 296 (1.5×) | 929 (1.2×) | 2,883 | Hob and Silky found |
| Wild, + a second Cluricaun | — | **396 (2.0×)** | **1,289 (1.7×)** | 4,283 | R10: 748, 2.5× |

None of the models fights. They show shape only. The audit's one hard fact still applies: a board at 1.5 times the median wins about 94% of fights (fundamentals §1.11). So any common line at 1.5× or more is a snowball until the sims say otherwise.

---

## 1. Engine: the growing Fairy Ring

### What breaks

1. **The headline decision is solved.** "Fill or tend" is meant to be the question every turn. But a brownie on a field gets the field's growth without stopping it, and so does a Cradle Fetch in front of it. Filling a field is dominated. The design's own line E says "never put a non-Shy unit on a lit field", and the only exception is near death. From tier 6 the decision disappears altogether: Monarch grows the Rings under Fairies, so filling a field with a Fairy costs nothing.
   - *Fix:* make filling a cash-out moment. For example, "a unit that steps onto a grown field takes it permanently, and the Ring drops back to its seed". Then fill-or-tend becomes a real trade between tempo and growth.
2. **The round Annis arrives fixes the final board.** A field grows ×1.5 a turn from the turn it is lit, whatever happens after. Under the design's growth rule, a +1 seed reaches at R12:

   | Annis lights it on | R2 | R3 | R4 | R5 | R6 |
   |---|---|---|---|---|---|
   | Field at R12 | 140 | 93 | 62 | 41 | 27 |

   An R2 Annis against an R5 Annis is 3.4× forever, and nothing lets the late player catch up. This isn't an economy snowball, but it is a round-2 shop roll deciding the rest of the game, which the owner's "shape of the curve" note warns against. The designer flags the lowroll (0.3× at R12) but not that the gap can never close.
   - *Fix:* add a catch-up grower. For example, Reel-Mistress grows each empty Ring twice the turn she's played. Or let Sally's seeds land already lit (the designer's knob 2).
3. **The Wisp route is a common spike, not a highroll.** Typical Wisp play is 1.7× the target at R7 and 1.6× at R9. It also has twice the carry route's stats at R12. So the brownie carry route, the tribe's signature, is the weaker route on totals, and players will skip it.
   - *Fix:* move Will to tier 5 (the designer's knob 1). Re-check the carry route against the Wisp route in the field sim before accepting either.
4. **A false claim about the Changeling.** "The stats are permanent on the unit, so an enemy Changeling can't take them away" is backwards. In this design the brownies give the B2 carry permanent unit stats. Those go with the unit when an enemy Changeling swaps it. Only Ring stats stay home, and the carry's own Ring is small. So this carry is fully stealable. The other two designs get this right.
5. **Cluricaun is an economy snowball that feeds the compounding.** "Start of Turn: if all seven slots have Rings, get 2 gold" is almost free on any Fairy board by R6. Copies stack: two Cluricauns pay 4 gold a turn, about 40 gold by R15. That gold buys Ring spells, and a spell placed early grows ×1.5 a turn. A 2-gold Spore Cloud on an R3 field adds about +117 at R12, and brownies and a Fetch count that field up to three times. That is the economy-to-tempo loop the owner described (9d).
   - *Fix:* "Once a turn" across copies, or a gold payout that costs a Ring.
6. **Hidden rules sit on the main route.** "Empty" means two things: a Ring under a Shy unit counts as empty for growth, but not for Wisps. A player who reads Annis's "the empty Rings behind this grow" won't stand Hob on that slot, yet that is the whole carry route. The rule also needs Shy narrowed (rule 5). The brownies' "gain that much" can be read as the Ring's size, not the amount it grew.
7. **Smaller breaks.**
   - Wisps are combat summons, so they don't count as starting survivors (10.1.4a), and Wisp boards win for less damage.
   - Hedge Witch's Ring stays the same until tier 6, so she is a 1/2 giving −1 Attack on the tempo line through the mid-game.
   - The tempo line is 0.47× the target at R12 by its own table. It is a trap unless the new damage table banks its early wins.
8. **Sameness.** "Gains half its stats every End of Turn while you don't use it" is the same engine as Oozes' Simmer (`oozes-engine.md`) and Birds' Grow while away (`birds-wild.md`). It also asks the same question ("use it now or let it grow"). The synthesis can give this shape to one tribe at most.

### What to keep
- The once-per-End-of-Turn guard on a Ring. It is the cleanest loop guard in the three designs, and it stops copies stacking the rate.
- Wisps rising from empty Rings (the Wisp night) as a reward moment.
- Monarch's "When played: your Rings grow" as a tier 6 spike.

---

## 2. Carry: the Throne and Glamour

### What breaks

1. **It is too small to matter at the target scale.** The throne line is about 0.5× the target mean from R12 and 0.43× at R15, below even its own softer row. Glamour is linear (Annis +1 a turn from R7). Each Ring is sized at the moment it is made, and old Rings never grow. So Ring stats grow quadratically, not ×1.5 a turn. R9 to R12 is ×1.29 a round. The curve only steepens once the Monarch lands. The owner's first complaint was "power budgeting … very, very much too low" (9a), and this design risks repeating it for the weakest tribe.
   - *Fix:* r = 2 (the designer's sweep) only reaches 0.77× at R12. A real fix is structural: let Glamour raise existing Rings (Wild's model), or let the Queen's doubling fire every 2nd turn.
2. **The late curve is a Lollop.** "A Fairy board without her flattens after round 12." One tier 6 card, with 7 copies, carries the tribe's compounding. The audit's lesson (§1.8) is that this is the failure to avoid.
3. **The crown can move on its own.** Four cards read "your biggest Ring": Cluricaun's Cleave, Will's refill, Fetch and the Queen's double. If Sally's slot, or a wall that took Spore Clouds, outgrows the throne, all four jump to that slot without warning. Reel-Mistress also moves Rings during fights, so the crown can change mid-fight. A player has to track sizes that the card text doesn't show.
   - *Fix:* make the throne a slot you mark, and don't infer it from sizes. (Check this against the Hunters carry's Alpha collar, which is the same idea.)
4. **Hex ends at 100% on a tier 1 card.** "Hex 10%. Each spell you cast adds 5%" reaches 90–100% by R12–15 on the spell-heavy line. The unit across then deals nothing. Early on, 10% of a 3-Attack unit rounds to nothing, so the card is dead on rounds 1–6 and absolute late. The designer's 4% lever helps the late end only.
5. **Route-locked cards are traps for the other route.** The throne line never buys Reel-Mistress (she strips the throne's Ring after one swing). Cluricaun, Will and the Queen do little for the Long Dance. That's 4 of 16 cards dead in about half the games.
6. **The board doesn't fit.** The throne, Sally, Lob, Annis, Cluricaun, Will, Fetch, the Queen and her tithe, Hob and the Monarch are 11 pieces for 7 slots. The designer admits the support is 10–20-stat chaff at R12. A wide board clears that front row in one cycle and reaches the throne early. This is the losing shape in fundamentals §1.6: a carry at 30% or more among small units.
7. **Sameness.** Glamour is the fourth "one number that sizes every new buff" in pass 3, after Birds' Tailwind, Bog's Peat and Hunters' Titbits. All of them are Battlegrounds' Blood Gems. The holders are Battlegrounds keywords re-skinned onto a slot: Shield (Hob), Cleave (Cluricaun) and Reborn (Will).

### What to keep
- Cluricaun's Cleave on the biggest Ring, and Will as the throne's Reborn. These are the only designs that give a Fairy carry a way to hold its stats.
- "Neutral Ring spells use the caster's Glamour", so another tribe rings at 1. This is the cleanest anti-splash rule in the three.
- The Rainbow Chaser storing a gold each turn you Ring. It is a small, visible economy card tied to the engine.
- The Changeling on the throne: their carry swaps onto your Ring and Cleaves its own side. It is a placement puzzle with a big payoff.
- Its wording discipline: median 9 words, maximum 17.

---

## 3. Wild: the carry is a place

### What breaks

1. **Second copies are common, and they stack into a snowball.** In the designer's model, every engine piece is counted once. But a second Cluricaun (tier 3, 13 copies) adds another +1 Ring size a turn on every Ring. A second Monarch runs a second Midsummer clock. Neither is rare.

   | Wild ring line (`fairies-breaker-stack.py`) | R9 | R10 | R12 | R13 | R15 |
   |---|---|---|---|---|---|
   | Every engine piece once | 1.5× | 1.9× | 1.2× | 1.8× | 1.1× |
   | + a second Cluricaun at R8 | **2.0×** | **2.5×** | 1.7× | 2.6× | 1.6× |
   | + a second Monarch at R13 | 1.5× | 1.9× | 1.2× | 1.8× | 2.2× |
   | + both | 2.0× | 2.5× | 1.7× | 2.6× | **3.3×** |

   The design labels "two Monarchs" as its top 1%. At tier 6, with a Hiring Fair and 5 Fairies guaranteeing a Fairy option, it looks closer to a routine late find. A Cluricaun triple is the same as two copies. This is the "common snowball" the owner rules out. Rounds 10 and 13 are also the same lump for every Fairy player, which the designer calls a tribe clock.
   - *Fix:*
     - Cluricaun's growth works once a turn whatever the number of copies (golden still gives +2).
     - Midsummer is one shared clock: a second Monarch doesn't start a second count.
     - Then sweep g at ½ (Cluricaun every 2nd turn).
2. **The Queen turns Rings into unit stats and the Ring stays.** Every third turn she shares the carry slot's whole Ring with the court as permanent stats, and the Ring stays to make the next stander a giant. Rule 12.1.5 was written to stop exactly this laundering. The shares don't compound, so this isn't a loop. But it is the biggest single gold-free payoff in the tribe (about 800 stats at R16).
   - *Fix:* default t to half. At 21 words her text is also the longest in the tribe.
3. **"Leaves" is undefined.** Hob ("When this leaves: Ring its slot for each turn it stayed") and Lob don't say whether selling counts. Rule 12.1.7 makes thanking the only exit for Shy, but if selling counts, Lob's payoff needs no spell. The Carry design spells it out ("Destroying or selling a Shy unit doesn't count"). Wild must too.
4. **Much of the carry's fight power is combat-only.** Fetch's twin (about +500 at R12) is visible as combat-start stats. Reel's extra swings (about +480 damage at R12) don't show anywhere. "Twice a fight" also reads as a limit on Mistress, when the Details say it is per Ring.
5. **It needs a mechanic that isn't built.** "Wisps must be attacked first" needs Taunt, which the engine doesn't have yet and Track B doesn't list. Golden Will (2/2 Wisps) does almost nothing at this scale, as the designer flags.
6. **The rainbow tax may be paid anyway.** Cluricaun needs a Ring on all seven slots, which costs the carry line about six Rings off the carry. Nan's play-and-sell and Annis already put Rings everywhere, so the tension may vanish in practice. The harness should check whether the carry line ever chooses not to build the rainbow.
7. **The model's carry share runs at 50–80%.** That is far beyond the share where a carry loses to an even board (fundamentals §1.6). The Fetch twin and the Wisp decoy are meant to answer this, but only the field sim can say whether they do.

### What's strong
- **"Who stands on the big Ring this fight?"** is the best decision in the three designs. You read the scout and choose:
  - the Witch zeroes the unit across;
  - the Changeling steals it onto your Ring;
  - Belladonna poisons their biggest;
  - a Wisp decoy has to be attacked.
  - It is new every fight and needs nothing extra from the engine.
- Count × size is new. Battlegrounds' Blood Gems don't grow after they're played; these do. Every old Ring grows, so a round 2 Nan is still worth buying on round 14.
- The reward moments are the strongest of the three:
  - completing the rainbow;
  - Lob's last night (+156 in one click);
  - Midsummer, a countdown the whole lobby can see;
  - "every fairy took a turn being the giant";
  - "their carry killed their own board."
- An enemy Changeling backfires: their babe stands on your Ring and fights for you. That gives Fairies a natural defence without a rule.
- The Cold Iron proposal ("the biggest enemy's Ring does nothing") is a clean answer aimed at Fairies.

---

## 4. Across all three

- **Answers.** All three make Belladonna hit the biggest enemy. Every other tribe's pass 3 adds its own biggest-enemy card too: Birds' Ratchet, Bog's Jenny or Lantern Man, Hunters' Lutra or Isegrim. The plan wanted 2 or 3 such cards in the whole pool; this adds 6 or more. With that many any-row answers, carries could become pointless. The cross-tribe synthesis has to choose.
- **Fixed slots against Horseshoe.** In Carry and Wild, the carry's power is on a slot that can't move. A 1-gold Horseshoe aimed across from that slot halves it whenever it is bought, and the Fairy player can't dodge by moving units. That is good scam, and it is the tribe's identity. But it makes Fairy carries depend on Horseshoe's spell supply. The fallback is the spread route. Keep Horseshoe and Cold Iron in the answer sim (Carry's item 5).
- **The models can't be compared.** The designers used three different models, two different target rows, no fights and no gold accounting. Rank the designs on shape and decisions; nothing here measures a win rate.

---

## 5. Ranking

| | Reward moments | Decisions created | Tribe identity | Scale guardrail | Rank |
|---|---|---|---|---|---|
| **Wild** | Best: rainbow, Lob's last night, Midsummer, the dance, a stolen carry | Best: who stands on the big Ring, stack or spread, thank timing, keep a gap | Most distinct: "the carry is a place"; count × size has no Battlegrounds equivalent | **Too hot** on common second copies (2.5× at R10); fixable with copy guards | **1** |
| **Carry** | Middling: thank-you turn, Changeling on the throne, golden Teind (rare) | Many and real: where each Ring goes, Sally's walk, planting, the tithe, the route choice | Blood Gem sameness (fourth Glamour-type number); holders re-skinned | **Too cold** (0.5× from R12); Monarch dependency | **2** |
| **Engine** | Good: Wisp night, Monarch's arrival grow | Weak: fill or tend is solved; Annis placement is the only puzzle | Strong folklore, but the same engine as Oozes' Simmer and Birds' Grow | Carry route on shape; **Wisp route 1.7× at R7**; early lock-in | **3** |

**Carry over Engine, narrowly.** Carry's flaw is size, and size is a dial. Engine's flaw is that its main decision is solved, and that needs a redesign. If the synthesis wants Engine's smooth curve, keep its once-per-End-of-Turn guard and graft on Wild's stander decision.

## 6. What the synthesis should build

Take Wild as the base and add:
1. **Copy guards:** Cluricaun's growth once a turn, and Midsummer as one shared clock. Then test g = 1 against g = ½.
2. **Carry's holders on the big Ring:** Cleave from Cluricaun's old text, or Will as the Reborn. Wild's Will then becomes the decoy route's card. The 50–80% share needs holders.
3. **Carry's anti-splash rule:** Ring spells use the caster's Ring size, so other tribes ring at +1.
4. **Carry's Shy ruling,** written out: only thanking counts as leaving.
5. **The Queen at t = half,** and text cut to 17 words or fewer.
6. **No Taunt,** unless Track B adds it for other tribes too. Plain Wisps on empty Rings are enough.
7. **Check with the other panels** that no other tribe ends up with a "one tribe number" engine shaped like this.

## 7. What the sims must answer for Fairies

1. Wild's ring line with 0, 1 and 2 extra copies (Cluricaun, Monarch) against the field at R10 and R13. How often is it at 2× the median or more?
2. Throne or big-Ring boards at 50% share, with and without Cleave or the refill, against even boards of the same total (fundamentals §1.6).
3. Horseshoe plus one biggest-enemy answer against a Fairy carry at R12. Does the carry still win sometimes, and does the answer land sometimes?
4. If Engine survives: Annis arriving on R2 against R5. Does the gap ever close?
