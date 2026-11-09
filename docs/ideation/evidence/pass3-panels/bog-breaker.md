# Bog folk pass 3: the breaker's critique

9 Nov 2026. The adversarial critic for the Bog folk panel (Track C, `docs/ideation/plan-scale-rework.md`). I read:
- the three designs (`bog-engine.md`, `bog-carry.md`, `bog-wild.md`);
- owner notes 09a, 09c, 09d and 08e, `fundamentals.md` §1 and §3, the plan, rulebook §7–9 and the BRAMBLE ideation rules, and the wording guide;
- the other panels' pass 3 files, to check overlap.

I ran all three paper models as shipped, then probed them with the lines a real player would take:
- engine: its own command-line levers;
- carry: its own arguments;
- wild: a copy of its `run()` with knobs for copies, goldens and bodies, at `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/bogprobe/wild_probe.py`.

Nothing ran in Godot, and no design fought a board.

**One baseline for everything below.** The three designs used two different targets. Engine and Carry sized their lines against Battlegrounds' September 2025 means, which the brief calls a *strong* board. Wild used the brief's own median: today's boards to round 7, then ×1.5 a round. Their ratios can't be compared as printed, so I restate them on one table.

| | R6 | R9 | R12 | R15 |
|---|---|---|---|---|
| Brief median (today to R7, then ×1.5) | ~50 | 146 | 494 | 1,666 |
| Strong board (Sept 2025 mean) | 53 | 194 | 759 | 2,600 |
| Engine, Diva line (typical) | 54 (1.1×) | 197 (1.35×) | 827 (1.67×) | 2,251 (1.35×) |
| Carry, Diva line with King (field-proportional, so the ratio holds on any field) | 0.69× | 0.77× | 1.34× | 1.72× |
| Wild, carry line typical, as shipped | 0.83× | 0.71× | 1.17× | 1.23× |
| Wild, carry line typical, printed T4–T6 bodies | 0.83× | 0.62× | 0.81× | 0.82× |

## Ranking

| Rank | Design | Reward moments | Decisions | Identity | Scale guardrail |
|---|---|---|---|---|---|
| 1 | **Wild** ("Everything the bog sinks, it keeps") | 5 | 4.5 | 3.5 | **Fails as written:** a second His Highness or a golden Gideon gives common 2–4× boards. One loop guard fixes it. Its engine duplicates Hunters wild |
| 2 | **Carry** ("The bog keeps what it takes") | 4 | 4 | 4.5 | **Fails as written:** a golden Soak unit plus the King can't be killed by attacks, and two Hopkins kill every field carry before it swings. Two text changes fix it |
| 3 | **Engine** (the Peat) | 3 | 3.5 | 2.5 | The best-behaved curve, but its typical line sits at the strong level by default, the tail is thin, and Turfs break the hand rules |

**Why Wild wins.** It has the most and biggest moments:
- the frog's curse breaks mid-fight and the carry doubles on the spot;
- "+41/+41" pops as their units sink;
- their carry rises on your side as a Peatling;
- the Lantern Man brings a hidden carry home and keeps half of it.

It also has the richest matching puzzle: who eats whom, Bufo's halving against Gideon's meal, which row Jenny stands in, and when to play the frog. And it is the best folklore. It loses identity points because its engine is the Hunters' trophy with a different trigger (cross-tribe section).

**Why Carry is a close second.** Soak is the only Bog engine no other tribe has. Bitter takes a share of each bite and Soak keeps it, so one keyword is both the answer and the engine, and Mire decides who bites whom. "Is their carry food or a threat?" is a real placement decision every round. It ranks below Wild because the auto-picked Diva locks the carry on one unit, it has fewer pop moments, and both of its breaks are the "nothing can answer this" kind.

**Why Engine is third.** Gold feeds the Peat and the Peat feeds every gain, so the curve is cubic and has no common snowball. But the payoff is Battlegrounds' Blood Gems, Brann and Elemental "this game" with a bog skin; the doc says so itself. Six cards share one payoff, so which sweller you buy hardly matters. And its decision, Turf or tempo, comes with its own solving formula.

---

## 1. Wild: Swell, Sink and the frog prince

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **The curse stacks with copies.** Two His Highness beside one carry count the same sinkings, so they break together for ×4. Two Princes then give ×4 every 15 sinkings. Owning two copies of a T4 is common, and the design's own engine line says "buy second copies of `gideon` and `his_highness` … keep pairs". Its back-row box (B1 frog, B2 Gideon, B3) has the second beside slot ready | Probe on the designer's model. Typical carry line: 1.17 → **1.93** at R12, and 2.02 → **4.45** at R16. Strong line: 2.20 → **4.71** at R13. Golden His Highness (a T4 triple) gives 1.55 and 3.17 on the typical line. With the Prince's repeat off, the strong line is flat at about 1.4 from R9: the whole late shape hangs on this one counter | **"A unit can be doubled by a curse at most once a turn."** The golden triple stays as the rare highroll. It also covers the next row |
| Should fix | **Token opponents speed up the curse.** Sink (X) counts deaths, not size. Summons land in the dead unit's slot (8.4.1), which is still the patch, so every Drip or Hedgerow token that dies there counts. Against a summoner, 15 sinkings come in about one fight instead of about three | Card text and rule 8.4.1. The design says the Prince doubles "about every third fight" at 5–7 deaths a fight | The once-a-turn guard above caps it |
| Should fix | **Golden Gideon is a common 2–3× board.** Golden Swell 100%, doubled by Tiddy, keeps 200% of their carry each time it sinks. A T3 triple is routine, not top 1% | Probe. Typical: 1.17 → 1.64 at R12, 2.02 → 3.44 at R16. Strong: 3.57 at R13, with Gideon 64–70% of the board | The design's own lever, golden Swell 75%, written on the golden card (rule 7.3.5 otherwise doubles every number). Or Tiddy at "half again", so golden plus Tiddy is 150% |
| Should fix | **The numbers lean on a lever nobody has picked.** The model gives T4–T6 bodies the median enemy unit's stats ("the scale build's body multiplier"). Step 2 hasn't adopted that, and the other two Bog models don't assume it | Probe with printed bodies. The typical carry line is **under the median at every checkpoint**: 0.62 / 0.81 / 0.82 at R9 / R12 / R15. The strong line barely moves (1.25 / 1.24 / 1.73), so the lever mostly hides how far typical games trail strong ones | Report both cases. Without the multiplier, the typical line needs f of about 0.6 or His Highness at Sink (4) |
| Should fix | **The curse's "current stats" is undefined.** Mid-fight, it doubles "its own current stats" in the fight and on the recruit board. That could mean damaged Health, and it could include combat-only buffs (another tribe's Rings or auras) turned into permanent stats | Rulings section | Double **permanent** stats on the recruit board, and show the fight copy's jump separately |
| Should fix | **Jenny's pull fights the Lantern.** The Lantern lays his patch under the biggest enemy first. Jenny then pulls the biggest enemy in her row across. If patches belong to the ground, she drags their carry off the Lantern's patch | Rulings section | Jenny skips an enemy the Lantern holds. Also note, as a feature, that her pull strips a Fairy carry from its Ring, because slot effects stay on the slot (8.5.1) |
| Note | **Over-concentration.** Gideon holds 47–64% of the board late in the model, which ignores overkill. The audit found that a 30%+ carry without holders loses 9–20 points | Model output | Gideon has holders (the echo hit, a Chorus's Bitter, the back-row duel). The combat model should check them, not the growth model |
| Note | **"Sink:" and "Sink (5)" are two concepts under one word**, a trigger and a counter across fights | Keyword table | Fine if the lily-pad hearts show the count. Wording median is 11.5 (guide: 11) |

### What survives
- **The frog prince:** "Sink (5): permanently double the units beside this, then become a Prince". It is the best reward moment across the three designs, and it creates a real "hold him or play him" decision.
- **The Peat King's Peatlings:** their carry rises for you, twice a fight, in the fight only.
- **Warty Nan as the leveller:** "your smallest Bog folk gains 25%". It lifts the supports that are dead weight in the other two designs.
- **Jenny's one-row pull:** reach that's "sometimes", as the fundamentals' default wants.
- **Who eats whom,** shown in the tray against the scout.
- **Bog as a comeback tribe:** a losing board still eats the small units it holds.

---

## 2. Carry: Soak, the Diva and the funnel

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **Golden Soak plus the King makes the Diva immune to attacks.** Golden Soak takes half the bite, and the King doubles the gain. So she gains +A/+A before a hit of A/2: every bite makes her bigger. A plain Soak unit with a golden King gains ¾A before a ¾A hit, which is net zero. In general, a Soak unit can't die to attacks when keep × share ≥ 1 − share; at a quarter share, that means keep ≥ 3. Routes in: a golden Bridge Toad (a T1 triple, and the model's default Diva), a golden Gideon (T3), a Diva beside a golden Chorus (T3, lends half-strength Soak), or a golden King | Arithmetic on the doc's own rules. The doc's highroll is this case ("she Soaks +400/+400 … She takes 200"), but the cheap routes are T1 and T3 triples, not top 1%. Only Nightshade, poison, Start of Combat shots and cleave can kill her | **Soak's gain lands after the hit** (it is still kept if the hit kills her). The designer's call #1 names this option. A bite of ¾A at or above her Health then kills her, so a carry her size can still win, and she still outgrows it across fights |
| **Must fix** | **Hopkin copies kill every field carry before it swings.** The Diva's Attack is structurally 1.2–1.6× the field carry's Health. Two Hopkins in B1 and B2 both vault off a Diva in F2, each with half her Attack. A golden Hopkin (a T2 triple, routine) does the same alone. The Prima Donna's three patches and Jenny make sure the carry is Mired, so Snap finds it | Model Diva against the field carry: 41 vs 35 Health at R9, 196 vs 138 at R12, 773 vs 472 at R15. Two vaults deal 40, 196 and 772: dead at every checkpoint. The doc's "full share (golden) kills it, which is a golden reward" treats a T2 golden as rare | Hopkin vaults with **a quarter** of the highest Attack in front (golden: half). Two Hopkins then leave the carry at about 30%, which is the doc's own stated target |
| Should fix | **The crown locks onto the Toad, so the Prima Donna can never be the Diva.** The funnel feeds the Diva, which keeps her the unit with the most Health. The doc calls the Prima Donna "the strongest" Diva, but she arrives at 2/8 against a 41/43 Toad and never catches up. Switching means selling 200–770 stats. The Hunters designer rejected auto-biggest for this reason ("auto-picking the biggest locks the carry forever"), and the Birds carry's Chick has the same pattern | Model: the Bridge Toad holds the crown from R1 to R16 (Gideon if Tiddy arrives at R9) | The designer's alternative: a placed crown, moved once a turn. Better still, make the move a reward moment: "the understudy takes the stage", where the new Diva gets half the old one's Soak gains |
| Should fix | **Golden Warty Nan halves every bite on three units.** Her own Bitter and the Bitter she lends take half. The loss lasts the fight (9.6.0), so an enemy that bites there twice is at a quarter of its Attack, and the funnel pays double for those takes. This is a T1 triple | Probe, upper bound (Bitter at half everywhere): 1.14 / 2.41 / 3.32× the field at R9 / R12 / R15, against 0.77 / 1.34 / 1.72 | Golden Nan widens her reach instead, as in the engine design ("your units in this row have Bitter"), and Bitter stays at a quarter |
| Should fix | **Six rounds behind.** The Diva line sits at 0.69–0.83 of the field from R5 to R10, or 0.47–0.63 if Tiddy is found at R9. Fights are nearly deterministic (fundamentals 1.11), so it loses most of those fights, roughly 20–30 of 40 Health before it comes online at R11. Its Bitter answers would have to be worth about 1.3× in fights to cover that. The Swamp, which is meant to cover the window, is only a hand estimate: 0.77 at R9 and 0.68 at R12 | `bog-carry-model.out.txt`, and the doc's table | Run the audit's combat model on the R7–R10 boards before the panel picks. If they fail, Tiddy's tier is the lever |
| Should fix | **The funnel and Soak read alike, but the King doubles only one.** Tiddy's "Your Diva permanently gains +1/+1 per Attack your other units' Bitter takes" has the same shape as Soak. The King doubles Soak, not the funnel, and nothing on the cards says so | Card text. The doc: "Plain words, not Soak, so the Peat King doesn't double it" | One concept, one wording: either the King names what it doubles, or Tiddy lends Soak to the Diva and the King doubles both (then tune k) |
| Note | **The Prince's echo reads the Diva's "current" stats.** In a fight, it's unclear whether he loses Health as she takes damage | Rules table | The echo reads her stats at Start of Combat |
| Note | **Growth needs enemy Attack.** Eggs, Hunker and Shell walls, and ghosts feed nothing, so the tribe's speed depends on who it is paired with. There is also no gold-to-stats channel: the Cutter's gold only buys rolls | Doc §7 | Acceptable variance. The tray's preview of the take from the scouted board makes it readable |

### What survives
- **Soak itself:** "Bitter. This also gains +1/+1 permanently for each Attack its Bitter takes." It is a proportional holding keyword that works at any scale, and it is Bog-only.
- **"Food or threat":** feed the Diva on their carry, fell it with Bufo (who halves the Diva's drink too), or leave it free. These are the best placement decisions in the three designs.
- **Bufo's halving,** which now has a cost against your own engine.
- **The field-proportional brake:** Bog converges to a multiple of the field and can't run away on its own.
- **The Lantern Man's live counter** as the non-carry route's finisher.

---

## 3. Engine: the Peat, Turfs and Swell on the bite

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **Turfs break the hand rules.** A full hand can't buy (4.2.2), the hand holds 10 (7.1.1), and only board units can be sold (4.3.7), so a Turf can only be cast. The design says "the hand limit is the only brake". The cash-in moment ("save 8 Turfs") leaves two hand slots for buying and tripling. A golden Cutter you can't afford to feed fills the hand in 4–5 turns | The model's highroll line holds **10 Turfs at R9 and 11 at R12** while buying units, which is illegal. The greedy line holds 6 | Turfs **stack in one hand slot** ("Turf ×8"). Or the Cutter holds them: "Start of Turn: this gets a Turf. Pay 3 gold: spend one to raise the Peat by 1." Banking and the cash-in survive |
| Should fix | **At default levers, the typical line is a strong board.** 827 at R12 is 1.67× the brief's median. The line's own neutral (Cricket Busker, a 2-gold Turf) gives 924, two Tiddys (a common T5 pair) give 1,107, and both give 1,260. The doc's fallback only covers a sweep that lands *above* r = 1 ("lower the Turf's cost"), and r = ½ isn't printable | Engine model probes | Printable levers that land near the median: **Turf 4 gold, and Tiddy "gain half the Peat"**. That gives 169 / 565 / 1,710 (1.16 / 1.14 / 1.03×) |
| Should fix | **The King doubles the Lantern's halving.** The Lantern's halving is written as a Swell, so the King triggers it twice: ×¼ a swing (×⅛ with a golden King), and ×¾ more with Nan's Bitter. Their carry then swings at about 19% (9%) of its Attack. Both are T6s in each line's top five, the Lantern reaches any row, and no placement dodges it. That is "always", not "sometimes" | Card text and the declaration order ("gains, halving, then queued replies") | Write the halving as plain text: "Mire the biggest enemy, in any row. When it attacks this: halve its Attack." (14 words) |
| Should fix | **It is Blood Gems with a bog skin.** The Peat is Blood Gems (the doc says so), the King is Brann, and Tiddy is the Elementals' "this game". Six cards pay the same "gain the Peat", so which sweller you buy hardly matters. The Peat is the fourth rising tribe number in the pass (Birds' Tailwind, Fairies' Glamour, Hunters' Titbit) | Doc §1. The Birds breaker made the same point about Tailwind | Keep Swell on the bite, which is Bog's, and pay it in something Bog-shaped: the carry design's Soak share. Keep the Peat only if the cross-tribe synthesis leaves tribe numbers to one or two tribes |
| Should fix | **The tail is thin, and Tiddy squeezes it.** The highroll (golden Cutter and golden Diva) is only 1.46× the Diva line at R12 and 1.70× at R15, and it's illegal anyway by the hand rule. The audit's top finding was "no tail". Tiddy's flat layer compresses the spread | With Tiddy off, the highroll is 1.64× and 1.93× the Diva line. With Turf 4 and Tiddy at half, it's 1.54× and 1.56× | The half-Peat Tiddy above helps. A golden King (×3) is the right rare multiplier; leave it uncapped |
| Should fix | **Tier-ups don't feel like progress.** A T1 Bridge Toad kept from R1 is 65–80 a stat at R12, bigger than Jenny (T4, 69/72), the Prince (46/47) or a fresh King (45/49). T5–T6 bodies arrive under the median unit (the doc flags this) | Doc and model | Scale Swell with tier: "gain the Peat" on T1–T3, "gain the Peat twice" on T4+. Or switch on the arrival lever, as the doc proposes |
| Note | **"The Drowning" is under the median at every checkpoint** (0.76 / 0.84 / 0.73), and its claimed combat edge isn't modelled. Its tempo cards (Hopkin, Sal, Pretender) kill Mired enemies before they swing, which costs Swells, so they work against the engine | Model, tempo line | It counts as a route only if a fight model shows its answers are worth about 1.3× |

### What survives
- **Swell on the bite:** "When an enemy this Mires attacks this", before the hit. A wall that grows when struck is Bog's identity in one trigger.
- **"Frogs or walls":** killing early wins tempo but costs growth. It is a real second decision.
- **The Diva's aria** as a highroll.
- **The UI ideas:** the Swell log line and live values in card text ("gain the Peat (+10/+10)").
- **A gold-fed rate** as the only Bog design that doesn't depend on the opponent's size. Worth keeping if Bog needs a gold sink.

---

## 4. Cross-tribe conflicts

1. **Wild's Swell is the Hunters' Trophy (must settle before either is built).**
   - Hunters wild prints "Take: gain half the quarry's stats permanently" on five cards and "Your Takes trigger twice" on its T6. Hunters engine's Feast is the same at a sixth.
   - Bog wild prints Swell 50% on six cards and "Your Swells trigger twice" on Tiddy.
   - Both pitches claim to be "the one tribe" that grows from what it fights.
   - Hunters' fiction ("You are what you hunt") fits a share of the kill. Bog's fits the bite: Swell in the engine design and Soak in the carry design both grow when the toad is struck.
   - If Hunters keep the kill share, Wild's engine becomes its own variation 1, "When its Mired enemy attacks this: first gain 10% of its stats", or the carry design's Soak.
2. **Brann is everywhere.** "Your X trigger twice" appears in Bog engine (the King), Bog wild (Tiddy) and Hunters wild (the Laird). Keep one or two in the whole pool.
3. **Auto-biggest carries:** the Carry's Diva, Birds carry's Chick and the Hunters' Alpha. Only one tribe should use it, if any.
4. **Parasitic engines are spreading.** Bog carry (Soak), Bog wild (Swell), Hunters wild (Trophy) and Birds carry (Jack Daw's permanent steal) all grow from a share of the enemy. One such tribe is a brake. Three make the lobby's curve depend on itself, and none of them can be measured on today's flat pool. Bog in wave 2 is the right order.

## 5. Problems all three share

1. **No design fought a board.** All three models are growth calculators, and every route claims combat strength they don't count: Bitter, halving, holds, the Swamp and the Drowning. The audit's combat model exists. Run it on each design's R9 and R12 boards before the panel ranks on numbers.
2. **Proportional Bitter compounds.** Rule 9.6.0 keeps the loss for the fight, so an enemy that bites quarter-Bitter units three times is at 42% of its Attack. All three spread Bitter across the front row. Add Bufo's halving and a Lantern, and a Bog board shrinks a carry to between a fifth and a tenth of its Attack. That is the answer tribe working, but the answer bar runs both ways: a carry should still sometimes beat Bog. Measure carry-against-Bog win rates.
3. **The any-row answer budget is spent.** Each Bog design adds one (Engine's Lantern, Carry's Jenny, Wild's Lantern). The other panels' candidates already include Hasty Pudding, Isegrim, Lutra, Belladonna, Jack Daw and the Whistlers, and most panels will keep at least one. The default was two or three in the whole pool, so the cross-tribe synthesis must count them.
4. **New T5–T6 bodies arrive small** in Engine and Carry, and Wild assumes a body lever. State that the payoff, not the body, is the tier-up reward, and test it against the progression bar.

## 6. What the synthesis should take

- **Engine of the tribe: the bite.** Use Carry's Soak, with the gain landing after the hit. Mire chooses who bites, Bitter takes a quarter, and Soak keeps it. It is Bog-only, it grows with the field, and the answer and the engine are one keyword.
- **Moments, from Wild:**
  - His Highness's curse break, with "doubled at most once a turn";
  - the Peat King's Peatlings;
  - Nan as the leveller;
  - Jenny's one-row pull, which skips the Lantern's target;
  - the Lantern Man, with his halving written as plain text.
- **Decisions, from Carry:** "food or threat" against the scout, and Bufo's halving as a cost to your own drink. Use a placed crown, not the auto-picked Diva, with "the understudy takes the stage" as the switch.
- **From Engine:** "frogs or walls", the Swell log line, and Swell tiered by card tier. Keep the Turf only as a stacked pile, and only if Bog needs its own gold-to-stats channel.
- **Fix before building:** golden Soak immunity (gain after the hit), Hopkin at a quarter, golden Nan widening her reach instead of halving, and the curse's once-a-turn guard. Settle the kill share with the Hunters panel.
