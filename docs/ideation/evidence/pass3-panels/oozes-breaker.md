# Oozes pass 3: the breaker's critique

9 Nov 2026. The adversarial critic for the Oozes panel (Track C, `docs/ideation/plan-scale-rework.md`). Three designs: `oozes-engine.md` (Back Burner, Simmer), `oozes-carry.md` (Big Pudding, Stock Pot) and `oozes-wild.md` (What goes in comes out bigger, Rise).

What I read:
- the owner's notes 09a, 09c, 09d and 08e, plus 02h on Oozes;
- `fundamentals.md` §1 and §3, and the plan;
- rulebook §8–9 and the ideation rules, and the Track B rules on `ideation/mechanics`;
- the wording guide, `content/oozes.md` and today's 16 Ooze cards;
- the other tribes' pass 3 designs and breakers, to look for overlaps.

What I ran (nothing in Godot; both scripts run with `python3 -I`):
- `oozes-breaker-probe.py` replays each designer's own growth model with the line a committed player takes, or with a card the design treats as rare arriving when it can.
- `oozes-breaker-fight.py` fights each design's R12 board in the carry designer's combat model, which extends the audit's model. The model is near-deterministic, so read it for direction only.

Target used throughout: Battlegrounds' September 2025 means, 53 / 194 / 759 / 2,600 at R6 / R9 / R12 / R15.

**In short:** the carry design wins. It has the best reward moments, the most real decisions and the closest fit to the owner's Oozes ("buffing the shop… eating each other, and combining and splitting"). As written, though, it stacks into common highrolls. The wild design is second. It has the best fiction and its growth stays in band, but nothing can answer its carry, and its board loses fights at target size. The engine design is third. Track B's tier 3 doubler squares Simmer, and its typical board loses nearly every fight against a board of the same size.

## Ranking

| Rank | Design | Reward moments | Decisions | Identity | Scale guardrail | Score |
|---|---|---|---|---|---|---|
| 1 | **Carry** (Stock Pot) | 4.5 | 5 | 5 | **Fails as written:** Aspics stack and Figgy makes golden Soup, giving 3–15× at R15 on common lines. Fixable without touching the core | 14.5 |
| 2 | **Wild** (Rise) | 4.5 | 3.5 | 4 | Growth is in band (1.0–1.6×). **Fails on answers** (none reach the carry) and **on fights** (4% against an even board of equal size) | 12 |
| 3 | **Engine** (Simmer) | 3 | 3 | 3.5 | **Fails:** a doubler bought at R6 makes 29× at R15. Without one it runs 0.8–0.9× and wins 1% of equal-size fights | 9.5 |

**Why the carry wins.**
- **Reward moments:** they are visible every turn. Every shop card shows the pudding's share (+15/+15 at R12), the shop swells after each meal, Bubble's Shield pops into a split, and Granny makes one 300-Attack Cleave and the family comes back whole.
- **Decisions:** it has the most real ones. Every unit has three homes (board, Belly or stomach). The carry goes in front for Aspic or in the back for safety. Nell pins the carry's slot, Bubble needs a gap, and every Drip can be eaten or played.
- **Late game:** it is the only design where late shop units matter, because they carry a share of your pudding. In the other two, late units are 10–20-stat bodies next to 300-stat risers.
- **Answers:** its carry stands on the board, so biggest-enemy answers reach it.

**Why the wild is second.** "The pie opens and a 600/600 hedgehog walks out" and "Hasty eats Granny" are the best single moments on the panel. "Fight with it or let it rise" fits the fiction best. But its core promise is a carry that nothing can touch, and that is the problem the plan exists to prevent. The wild design is also the wordiest.

**Why the engine is third.** It is the cleanest engine, and its see-through rule is the panel's best rules idea. But it drops the owner's "buffing the shop". It shares its core with Rise, the Fairies' Ring and the Birds' Grow while away. And its only compounding is an End of Turn trigger, which a common neutral doubles.

---

## Problems in more than one design

| # | Severity | Problem | Evidence | Fix |
|---|---|---|---|---|
| A | **Must fix** | **Track B's doubler is a tier 3 neutral.** "Second Helping" (`content/levers/scale_doubler.json`) is tier 3 and adds a firing to every End of Turn effect. Two copies add two firings. Any design that treats it as a rare late highroll is wrong while it sits at tier 3 | Engine (Simmer is End of Turn): typical line 2,037 at R15. Doubler at R10: 7.5×. At R8: 15×. At R6: **9× at R12, 29× at R15**. A golden or second doubler from R10: 81×. Carry (Nell and Elder are End of Turn): doubler from R8 is 3.0× without Aspic, 5.2× with. Wild: Rise is Start of Turn, so it's immune | Simmer moves to Start of Turn, as Rise already does. **Cross-tribe:** the Fairies' Ring is End of Turn too. The doubler's tier and reach should be set with every tribe's End of Turn compounding in view. Its name also clashes with "Second Helpings", a route name in all three Ooze designs |
| B | **Must fix** | **A carry sitting in a back-row Belly loses fights it should win.** Engine and wild keep 57–79% of the board inside back ovens behind 2/4 shells. The riser enters only after the front falls, alone, and wastes its overkill | R12, at equal totals, against even / Battlegrounds-shaped (carry in F2) / Battlegrounds-shaped (carry in B2): engine 689 wins **1% / 1% / 19%**; wild 763 wins **4% / 55% / 80%**. One keyword decides it. A Cleave riser: engine 86/72/86, wild 55/91/94. Shield plus Cleave: engine 99/94/98 | The tribe needs its own way to use a riser's overkill. Otherwise the line's real decision is "find a Track B Cleave neutral for dough", and the power belongs to the neutral. Options: Syllabub "comes out with Shield and Cleave"; Granny's doubled unit gains Cleave; or Bubble's split on risers |
| C | Should fix | **Ooze wins hit softly.** Units inside, and units that came out, aren't starting survivors (10.1.4a). Engine and wild win mostly with units that came out, so a win deals about the round base. That works against "winners done by rounds 14–16" | All three designs flag it; no design fixes it | A rule change for the sweep: a unit that started the fight inside your Belly counts once as a starting survivor if it is alive at the end |
| D | Should fix | **Hasty Pudding is splashable in all three designs**, and its release rule decides whether carries matter (see Carry #4 and Wild #3) | Its text names no Ooze | Keep today's release ("after 3 of your units die"). Any permanent growth goes to "your biggest Ooze", so the growth can't splash |
| E | Should fix | **Sameness.** Simmer and Rise are the same mechanic at different times, and both match the Fairies engine's empty Ring (+half each turn) and the Birds wild design's Grow while away. The Fairies and Hedgerow breakers flagged this too | `fairies-breaker.md` #8; `hedgerow-breaker.md`, notes | The cross-tribe synthesis gives "leave it and it grows by half" to one tribe at most. The carry design doesn't need it |
| F | Note | **The three scale tables use different bases**, so their ratios can't be compared | Engine: its target column is an estimated median (500 at R12), so its "1.4×" is 0.9× of the means. Carry: totals leave out about 160 stats inside Bellies at R12, so on the others' basis it reads about 1.2× higher. Wild: totals count insides (603 of 763 at R12) | The harness's combat-start snapshot counts insides for everyone, and ranking uses field win rate, not totals (fundamentals §2) |

---

## Carry: the Big Pudding

**Keep:**
- Stone Soup's share of your biggest Ooze. It makes late shops matter, it is visible, and it compounds through buying.
- Digest, Nell's End of Turn meal, Moss's Shield on the carry, Bubble's stat-keeping split, Frumenty keeping the text of its last meal, the Cut-and-Come-Again Drip ("eat it or play it") and Granny's gathered Cleave.

| # | Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|---|
| 1 | **Must fix** | **Common stacking runs far past the target.** "Two Aspics add up to double", and Aspic is tier 3. Figgy has no limit and makes golden Soup from two copies of a tier 2. Golden Soup also doubles a fraction, which Track B's percentage effects avoid ("fractions do not double on golden"). The design treats golden Soup as rare, but a committed line gets it from about R8 | Designer's model, line2. Aspic line: 1.4× / 1.9× (R12 / R15). Two Aspics from R7: **1.7× / 3.2×**. Golden Soup from R8: **3.0× / 7.4×**. Both: **4.2× / 15.3×**. The design's own fallback (golden ×1.5) with two Aspics: still 2.7× / 7.2× | Only your best Aspic counts, the same rule as Soup. Golden Soup widens instead of raising the fraction, as Track B's percentage effects do. Sweep r from 1/12 to 1/10. At r = 1/12: no Aspic 0.9× / 0.8×; one Aspic 1.2× / 1.5×; golden Soup (1/10) plus Aspic 1.3× / 1.8×. That spread looks like the target's tail |
| 2 | **Must fix** | **The turducken needs nesting, which the engine refuses.** `held_units.gd` blocks swallowing a unit that holds units ("It's holding units of its own"). Highroll #1 and the Pie's carry-route job both depend on it, and §7 doesn't ask for it. If the block is lifted, every Belly Ooze becomes a box of meals. Then "Belly 1 = one meal a stomach" stops being a brake, gold is the only limit, and Elder reaches every nested Ooze | Code; the design's "What brakes it" list | Keep the block and cut the turducken. The Pie stays the pot route's economy card |
| 3 | Should fix | **Elder counts Oozes inside Bellies.** A player who fills every Belly with Oozes reaches about 11. The model assumed 4 | Insides counted, no Aspic: 4 Oozes gives 1.0× / 1.0×. 8 gives 1.4× / 1.5×. 11 gives **1.7× / 1.8×**. Eating an Elder-grown Ooze each turn from R11 (with Aspic): 1.5× / 3.6× | "Your other Oozes on the board", or a twentieth. The pot route keeps its reserves through the Bellies' spare lives |
| 4 | Should fix | **Hasty Pudding makes carries pointless.** The swallowed unit now comes back only when Pudding dies; the "after 3 of your units die" release is gone. In the back row, behind about 11 Ooze bodies, it holds the enemy carry for the whole fight. Any tribe can splash it | Designer's `answers.py`: Pudding in B2 wins **100%** against a board with 60% in one carry, and 100% against a Battlegrounds-shaped board. The owner wants answers that reach a carry *sometimes* | Restore today's release. The design's own fallback ("comes out after Pudding has attacked twice") also works |
| 5 | Should fix | **The carry holds too well.** Shield, the split and Granny's gathered Cleave together | My run of the drawn R12 board (834): 100% / 100% / 95% at equal totals (even / BG front / BG back). Without Granny: 92% / 73% / 69%. The designer's own run: 70–88%. Combined with 1.4–1.9× totals on the Aspic line, field sims will likely show a common lead | Fix #1 first (r and stacking), then the design's "split after the second hit". Granny is a coin flip already: she stands alone with 25 Health, so when unit counts tie and the enemy attacks first, she dies before swinging |
| 6 | Should fix | **The doubler doubles Nell and Elder** | Problem A: 3.0× / 5.2× at R15 | Cross-tribe fix; or Nell eats at Start of Turn |
| 7 | Note | **Wording:** median 13, p90 16, max 18. "Your biggest Ooze('s stats)" appears on Soup, Nell, Elder and Cut-and-Come-Again, and Moss has "biggest other Ooze" | Count of the §4 texts | Name it: "your Pudding", with the ladle mark. A term on five cards saves about three words each. "Eat" now sits beside Hunters' Feast and Hedgerow's feeding; the Birds breaker asked for one verb per concept |

---

## Wild: What goes in comes out bigger

**Keep:**
- Rise at Start of Turn, which the doubler can't reach.
- Posset's "what comes out attacks at once".
- Cut-and-Come-Again's slice of the thing you grew.
- The fiction: swallowed whole, comes out alive.

| # | Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|---|
| 1 | **Must fix** | **The carry has no answer.** Inside an oven it is "safe from every answer". Served, it "hides in a front Belly (Posset or Wobbly) at the last moment" to dodge Start of Combat answers, then Posset makes it attack at once. Every biggest-enemy answer the plan puts in the pool fires at Start of Combat, so none of them ever sees it. Highroll #1 is "with no way to touch it" | Card text; rulebook 9.3; Track B's Carry Check fires at Start of Combat | Adopt the engine's see-through rule: biggest-enemy effects see inside enemy Bellies and can shrink a unit there, but can't swallow or move it |
| 2 | **Must fix** | **The riser board loses at target size** (Problem B) | R12 carry line (763): 4% / 55% / 80%. Its Hasty swallow barely changes it | As Problem B |
| 3 | Should fix | **Hasty's quarter turns a splashable answer into a carry engine.** Any tribe gains a quarter of the lobby's biggest unit every fight. In the wide line it is the biggest late growth | Designer's field: +25 a fight at R10, rising to about +220 at R15, about +600 in all. Wide line: 41/49 at R12 becomes 197/205 at R15 | "Your biggest Ooze gains a quarter of its stats." The swallow still splashes; the growth stays tribal and feeds the riser |
| 4 | Should fix | **"Comes out" depends on a hidden rule.** Taking out is free and putting back in is free. Elder ("After a unit comes out of your Oozes: … +1/+1 this game") would loop forever if taking out counted. Only a rule a player can't see from the card says it doesn't | The "Taking out" paragraph; Elder's text | Write it into the trigger: "After one of your Oozes dies:" |
| 5 | Should fix | **Flat payoffs are too small at scale, and late gold has nowhere to go.** Soup adds +1/+1 a fill, twice a turn, and stops once the Bellies are full: shop +8 at R12, +14 at R15 and flat after. Elder reaches +17/+17 by R15, when the median unit is about 185/185. Aspic gives +1/+1 a turn to each unit inside. Late shop units are 16/17 | Designer's calculator: the wide line's shop stays at +14 from R12 to R15, and **the carry line ends R15 with 32 gold unspent** because nothing on offer is worth buying | Use the carry design's proportional Soup, and make Elder a share. That gives late gold a job |
| 6 | Should fix | **Wording:** median 14, p90 20, max 21. Three cards go over the guide's 17: Wobbly ("unchanged") 21, Hasty 19, Nell 18. There is also a new rule (Taking out) and a new keyword | Count of the texts | Wobbly: drop "if empty" and "Twice a fight", since board slots bound the Drips (the carry design did this). Nell: "End of Turn: eat your shop's lowest-tier unit. Your biggest unit inside gains half." |
| 7 | Note | **"Fight with it or let it rise" is mostly solved.** A riser in a back oven rises and still fights as a reserve, because the fight runs on a copy and the riser is back inside afterwards. Serving it is only for the endgame | Rulebook 9.1.1 | Variation 1 ("rises only if the oven didn't open last fight") would make the choice real, at some snowball risk. Sweep it |
| 8 | Note | **Growth is the best-behaved on the panel.** Start of Turn dodges the doubler, and Belly room limits the ovens | Slices into ovens: no change, because the ovens are full. A second Pie at R12: 1.6× at R15. At R7: 1.2× / 1.6× | Whichever tribe gets this shape should keep the Start of Turn timing |

---

## Engine: the Back Burner

**Keep:**
- The see-through rule (§9): pool-wide.
- Hasty swallowing the Ooze that holds the biggest enemy.
- Hasty's 3-deaths release.
- Posset's proportional half.
- Syllabub's Shield as each unit comes out.
- The engine-support list, which is the most complete on the panel.

| # | Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|---|
| 1 | **Must fix** | **The tier 3 doubler squares Simmer** (Problem A) | 9× at R12 and 29× at R15 when bought at R6 | Simmer at Start of Turn |
| 2 | **Must fix** | **The riser loses** (Problem B). The design's scale table calls the line ahead; in fights it is far behind | Typical R12 (689): 1% / 1% / 19%. With Syllabub's Shield: 24% / 23% / 39% | As Problem B. Syllabub is the natural card for it |
| 3 | Should fix | **Nell's free unit lands in the first Belly with room, in reading order.** That can be Hasty Pudding's empty Belly, which turns the answer off, or an empty oven, which then holds a tier 1 unit you can only remove by selling the oven | Nell's Details | "Put it into an Ooze next to this", or make her skip Hasty |
| 4 | Should fix | **Payoffs too small, and tier-ups that don't feel like progress.** Stone Soup is +1/+1 a feed (12/13 at R15, when the median unit is about 370 stats). The shells (2/4 at tiers 3–4, Granny 6/10) never grow, so a tier-up arrives as a 6–16-stat body, against the plan's progression bar | Card table; final model | Soup goes back to buffing the shop. A shell could gain a share of what's inside |
| 5 | Should fix | **It drifts from the owner's Oozes.** "Buffing the shop" is gone, eating is reduced to Nell's leftovers, and the core is the shared shape (Problem E) | Owner note 02h | Choose the carry design's Soup and eating, and let the cross-tribe synthesis decide where Simmer goes |
| 6 | Note | **Decision 2 (back or front) is mostly solved**, as for Rise (Wild #7). Late gold has few uses once the ovens are full | Rulebook 9.1.1 | — |
| 7 | Note | **Moss and Track B's spell scaling.** If "reach what's inside" makes the unit inside a recipient, percentage spells give a share of the riser on every cast | Track B, "Hero/spell scaling" | "What's inside gains the same." |

---

## For the synthesis

1. **Base the tribe on the carry design**, with Carry #1–#4 fixed:
   - one Aspic counts;
   - golden Soup widens instead of raising the fraction;
   - Elder counts board Oozes only;
   - no nesting;
   - Hasty keeps today's release.
2. **Take from the engine:**
   - the see-through rule, for the whole pool;
   - Hasty swallowing the Ooze that holds the biggest enemy;
   - Syllabub's Shield as a variation to test against "its Start of Combat fires".
3. **Take from the wild:**
   - Hasty's growth, given to your biggest Ooze, so the lobby's runaway carries feed the Big Pudding;
   - Posset's "attacks at once", tested against the carry's "its killer loses half its stats".
4. **Leave Rise and Simmer to the cross-tribe call** (Problem E). If Oozes keep an oven, make it one card at Start of Turn (the Pie with Rise), not the engine.
5. **Sims the harness must run for Oozes:**
   - the carry line with two Aspics and with golden Soup, read as the share of Ooze games, not as the best case (9d);
   - Hasty against carries of 34% and 60% of a board, in both rows;
   - the R12 carry board against even boards, with and without Granny;
   - every Ooze line with the tier 3 doubler in the pool;
   - game length and damage dealt with Ooze wins counted.

## Files

- `build/orchestrator/pass3/oozes-breaker-probe.py`: growth probes. It embeds the engine model and `routes.py` line2 with their logic unchanged, plus hooks; it imports `oozes-wild-model.py` as is.
- `build/orchestrator/pass3/oozes-breaker-fight.py`: R12 fights. It uses `oozes-carry-model/ooze_combat3.py` with one patch, so that a Belly can hold a list.
