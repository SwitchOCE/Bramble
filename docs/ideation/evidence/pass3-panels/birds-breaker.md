# Birds pass 3: the breaker's critique

9 Nov 2026. The adversarial critic for the Birds panel (Track C, `docs/ideation/plan-scale-rework.md`). I read the three designs (`birds-engine.md`, `birds-carry.md`, `birds-wild.md`), the owner's notes 09a, 09c, 09d, 08e and 08f, `fundamentals.md`, the plan, rulebook §8–9 and 12.1.4, and the wording guide. I ran both paper models the designers shipped and probed them with the lines a real player would take. The carry design ships no model, so its numbers are checked by hand. Nothing here ran in Godot. My probe scripts are in the session scratchpad, not the repo. The probes are described below and can be rerun by editing the designers' own schedules.

Target used throughout (the brief): today's level to round 7, then about ×1.5 a round. Median boards are about 55 / 145 / 490 / 1,650 at rounds 6 / 9 / 12 / 15, and a strong board is about 700 at round 12.

## Ranking

| Rank | Design | Reward moments | Decisions | Identity | Scale guardrail |
|---|---|---|---|---|---|
| 1 | **Wild** ("They come home bigger") | 5 | 4.5 | 4 | **Fails as written.** It is fixable with two rate limits that keep the core |
| 2 | **Engine** (the Tailwind) | 4 | 3 | 3.5 | Closest to the band. Typical line is 45% under target at round 9; two Geese is common, not top 1% |
| 3 | **Carry** (the Chick and Feed) | 3.5 | 3.5 | 2.5 | Unmodelled. The Ratchet turns late fights into one breakpoint; the curve hangs on one tier 4 card |

**Why Wild wins.** It has the most and biggest reward moments:
- every homecoming shows a big visible jump;
- the Golden Egg doubles a unit the turn you buy the tier 5;
- an Egg cracks and a giant drops into the slot;
- the omen halves the whole enemy board.

It also has the only real tension at the core: the Bird that would gain most from flying is your best fighter. And it is the most Bird-shaped: the sky is your bench and your bank, and a flight dodges an answer. It breaks the band harder than either rival, but the break comes from stacked Grow sources and a cycling doubler, not from the idea. Both have clean rate-limit fixes (below).

**Why Engine is second.** It is the best-behaved curve: additive and cubic, so a one-round lead shrinks over time instead of lasting forever. But its fliers are interchangeable fuel, flying everything is close to always right, and its two answers aim themselves, which removes decisions on both sides.

**Why Carry is third.** The thieves and the Lump shove are good, but the core is Battlegrounds' Blood Gems aimed at one auto-picked unit. That overlaps the Hunters carry's Alpha. The design also drops the owner's favourite Ratchet landing (08f: "Taking away the downsides is the big thematic payoff of the Gabble Ratchet ... and that's cool").

---

## 1. Wild: "They come home bigger"

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **The natural line is a common 10× runaway.** The two typical lines split the pieces: Line 1 has Stork and no Cuckoo, Line 2 has the Cuckoo and no Stork or Goose. A real player buys all three. Grow sources stack with no once-a-turn guard. A flight beside the Cuckoo Grows, End of Turn Grows, and the Stork recall Grows: ×3.375 every 2 rounds. Goose's replay adds a Golden Egg (×2) each cycle | My probe on the designer's own model: Jay beside the Cuckoo, recalled by Stork every other turn, with one non-golden Goose recalled on the turns between. That needs **one** Stork recall a turn, 6 gold. Jay reaches **2,478 at R13 and 16,692 (about 8,300/8,300) at R15**. That is ~10× the target median *board* in one unit, from four single, non-golden copies (Jay, Cuckoo, Stork, Goose). It beats the design's own "top 1%" highroll (golden Goose + Stork, 6,500/6,500). Stork + Cuckoo alone gives 2,136 at R15 in one unit | **(a) A Bird Grows at most once a turn.** The Fairies engine already uses this loop guard for the same reason. **(b) Goose: "When bought: get a Golden Egg"** (or "the first time this is played"), so it can't cycle. The Golden Egg moment on the tier-up survives. Probe with both fixes: Jay is 250 at R12 and 832 at R15, about half a median board. That is a strong carry, not a runaway |
| **Must fix** | **Two Geese = golden Goose.** The highroll table calls golden Goose + Stork the top 1%. But two non-golden Geese give two Golden Eggs a cycle too, and that needs only ~9 gold a turn of recalls. Two copies of a T5 is routine for a committed player. The `birds_homecoming` line buys Goose *first* | Same arithmetic as above: ×4 per 2 rounds on one Bird | Fix (b) above covers it |
| **Must fix** | **Golden Tom Tit makes flying free.** "Your Eggs have their Bird's stats" means the sky fights at full size *and* grows. A T3 golden is routine, not a highroll as the doc says. With it, the core decision (fly your best fighter or keep it home) disappears | Card text plus the rules | Golden: "Your Eggs have their Bird's Health and half its Attack". Or keep golden as plain Health and add +Attack elsewhere |
| Should fix | **Stayers never grow.** At R15 in the designer's own model: Tom Tit 6/7, Stork 7/10, Whistlers 10/12, Ratchet 9/13, Cuckoo 7/10. The median enemy unit is ~120/120. Five of seven slots are paper, and the carry holds 50–67% with only Cleave to hold it. That fails the plan's progression bar ("a tier-up arrives at or above the player's median unit") at T4–T6 | `birds-wild-model.py` R12 and R15 output | Give the stayers a share of the sky. Borrow the engine's Redbreast: "After a Bird comes home: this gains a quarter of what it grew." That also fixes the dead Redbreast below |
| Should fix | **Mr Redbreast is dead late:** +1/+1 a turn per Bird away, so 26/28 to 35/37 at R15 | Model | As above |
| Should fix | **Mrs Dunnock is a designed trap.** The doc says "after that she is a trap, and the bot line sells her on R8". Growth is time away, so shortening a trip loses growth, and she works against the Cuckoo and the Lump. The owner's 08f test: content that doesn't fulfil its purpose "becomes a trap" | Doc §Tier 1 | Make her the trip-*lengthener* or a Grow source for one Nest beside her ("End of Turn: a Bird whose Nest is beside this Grows"), within the once-a-turn guard |
| Should fix | **Exponential rate sensitivity.** Growth is a product of Grows, so the late board is exponential in r. r 0.5 → 0.6 nearly doubles Line 2 at R15 (1,958 → 3,820). The sweep's 0.3–0.75 range also doesn't print as clean words (only ⅓, ½, ¾ do) | The design's own table | Sweep only ⅓ and ½. With the once-a-turn guard, the stacking pieces stop compounding the error |
| Should fix | **Early tempo, not "behind at once".** Line 2 is 1.33× target at R6 and 1.35× at R9, because cheap early flights and Redwing/Tom Tit Eggs hold the slots | Model R6 73 and R9 203 | The design's own lever: Grow starts on a trip's second End of Turn |
| Note | **A fake decision.** "Give the Golden Egg to the Bird about to fly, so the trip multiplies a doubled base." Doubling and Grow are both multiplications, so order doesn't matter. Only additive buffs (Supper, Chiffchaff) care what order they come in. The target choice is real; the timing reason is not | Arithmetic | Drop the line from the decision list |
| Note | **Mrs Stork "you pick which"** brings back a choice the pass 2 costing dropped for simplicity (DECISIONS: "The player's choice was dropped for simplicity"). That's fine on this branch, but log it. It also needs a mid-purchase prompt, which is a new UI interaction | DECISIONS.md | Log it |

### What survives

The core sentence, "sold, it flies south and comes home bigger". The Cuckoo's slot puzzle. The Golden Egg as a tier-up reward. The Ratchet's Egg-crack landing (the owner's "both halves"). The omen. "Fly the carry south to dodge a scouted Changeling", which no other tribe can do. All three answers aim across, which keeps the pool's any-row budget free. Text is short (median 9.5 words).

### Cross-tribe conflict

The **Fairies engine** design uses the same keyword, **Grow**, at the same rate (½), at the same time (End of Turn), on the same idea: an empty or absent thing grows, and you choose whether to fill it or leave it. Its reminder is "A growing Ring gains half its stats, rounded up". Wild's is "Gains half its current stats". Only one tribe can own "it grows while it isn't fighting". Birds have the better fiction (migration), and absence is already the Birds' cost, so the panel synthesis and the Fairies synthesis must settle this together. If Fairies keep it, Wild's own variation ("Grow at homecoming only", ×2¼ in one pop) gives Birds a different shape.

---

## 2. Engine: the Flyway (Tailwind)

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **Two Geese is common, and the listed guard doesn't bind.** The design calls "two Geese plus Stork" the intended top 1%. Owning two copies of a T5 isn't rare, and the flyway line buys `mother_goose (2)`. The guard "only the first Goose homecoming each turn doubles" never fires, because two Geese land on different turns. Each landing doubles a number that never falls | Probe on `birds-engine-model.py` (`r=1 max_stay=4 golden_bird_x2=1`): the typical line plus one more non-golden Goose at R12 takes R15 from 1,599 to **2,323** and R18 from 3,755 to **8,190**. Tailwind is 298 against 80 | A rate limit that binds across turns: "Tailwind doubles at most once every 3 turns". Or Goose ×1.5 (golden ×2). Or Stork can't bring Goose home early |
| **Must fix** | **The typical line is under the target at every checkpoint, and badly at R9.** The model says 82 at R9 against ~145 (0.55). The doc's "~110–160" comes from a "sensible policy" that wasn't modelled. R12 is 436 (0.87) and R15 is 1,599 (0.94). The engine is never "clearly ahead" on a typical roll. The R7–R12 slump is the very problem the audit named for Birds (4.9% first) | Model output, typical line | The doc's own lever: Egg fraction ¾. Or Tailwind starts at 2. Re-run the model with the policy the doc claims, not the naive one |
| Should fix | **Answers aim themselves, so they remove decisions.** Jack Daw (¼ of the biggest enemy's Attack, any row) and the Whistlers (halve the biggest enemy, any row, "Condition: none") need no placement and allow no dodge. Together at T6, every enemy carry fights at ⅜ Attack and ½ Health, every fight. The owner wants answers that reach a carry *sometimes*. These are always. They also spend two of the pool's "2–3 any-row answers" (fundamentals Q2). Hunters carry (Lutra, Isegrim), Fairies carry (Belladonna) and Bog engine (Lantern Man) already claim four more | Card text; other tribes' pass 3 files | Put the Whistlers on "the enemy across" (the doc's own fallback). Keep Jack Daw on the biggest, since he flies two fights in three |
| Should fix | **Fliers are interchangeable fuel.** Every homecoming pays the same Tailwind, Redbreast and keeper bonus, whichever Bird it is. So "who flies today" collapses to "everyone, Chiffchaff first, Goose before Stork's count". Early losses are cheap (base 0–2 through R7), so flying everything is near-dominant until mid-game. The model's naive "fly everything" policy *is* the engine line | Line policy 2 vs the model | Give fliers different homecoming payoffs that Tailwind scales (some do: Swallow gold, Jay Acorn). Or make Tailwind rise by the Bird's tier, so which Bird lands matters |
| Should fix | **Golden Redbreast is the line's plan, not a highroll.** `birds_flyway` buys "mr_redbreast (up to 3 for the triple)" first. A T2 triple by R6–8 is routine. It is fine as a strong line; just don't count it as top-1% tail. The model's HIGH line ends level with STRONG (2,689 vs 2,641), so the engine shows no tail at all | Model | Sweep the golden gain at 1.5X, as the doc lists |
| Note | **Cuckoo keepers are a chore, not a choice.** At each Start of Turn you want every stayer standing on a Nest, with the Lump on the biggest. It's the obvious move every turn, and the bot needs it scripted | Rules | Show "keeper +X" on Nests, as planned. Accept it, or cut the Cuckoo to one named slot |
| Note | **Model bugs.** It charges no gold. Golden Goose multiplies by gmult² = ×4, but the text says ×3. It counts only the first Cuckoo | `birds-engine-model.py` | Fix before the sweep reads it |
| Note | **The reminder's "X" is undefined.** "Birds gain +X/+X when they come home. Then it rises by 1." Neither X nor "it" is named | Wording | "A Bird coming home gains +1/+1 per Tailwind. Then Tailwind rises by 1." |

### What survives

The robin who stays and grows from every homecoming: a visible, permanent carry that never flies, and the best-behaved compounding of the three. Tom Tit's Shield on the biggest Bird. The Tern's "everyone's home" burst (+87/+87). Chiffchaff as a 2/3 on turn 1. Stork as the gold-to-stats channel.

### Cross-tribe conflict

Tailwind is one rising tribe number, and every reward reads "gain the Tailwind". That is the same template as the **Bog engine's Peat** ("Every Bog folk reward is 'gain the Peat'"), the Fairies carry's Glamour and the Hunters carry's Titbit size. If three or four tribes ship it, they will feel alike. The cross-tribe synthesis should allow it in one or two tribes at most.

---

## 3. Carry: the Brood (Chick and Feed)

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **The Ratchet turns late fights into one breakpoint.** "Your Chick attacks the biggest enemy, in either row. After it kills, it attacks again", with no limit and with Tom Tit's half damage. The doc says it "kills a 300/300 carry, takes 150, then kills two or three 120/120s". The arithmetic says it kills **all seven**: 515 Health − 150 − 6 × 60 = 5 left. So from R14 a typical Birds board wins in one Chick attack whenever its Attack beats their biggest Health, and loses or stalls when it doesn't. That runs against the plan's variance budget (the side with fewer stats should win 14–26% of fights). It also makes Mr Redbreast's text redundant at T6 | Doc §Tier 6 and my hand count against its own R15 board | The doc's dial L = 1: "After it kills, it attacks again. Once a fight" (golden twice). Or the chain stops at the first unit it doesn't kill outright, at full damage |
| **Must fix** | **The curve hangs on one tier 4 card.** The Cuckoo is "60–75% of all Feed growth" from R10. Without it the low roll is ~650 at R15, 0.38 of the median. That repeats the Hedgerow/Lollop pattern the audit flagged (70 of 71 wins on one card), and a second Bird player starves it | Doc §4 | A second bonus source at T3–T4 (for example Old Tern: "When this comes home: Feeds give +1/+1 more this game"). Then the Cuckoo is the best of several, not the only one |
| Should fix | **Unmodelled.** No model file ships, so the R9 / R12 / R15 numbers can't be rerun. My check of R15 growth: about half of it is Jack Daw's permanent steal (~150 of ~290 stats a turn). So the curve depends on how big the *opponent's* carry is. Against wide flat lobbies it is much flatter than the table says | Doc §4; my breakdown | Ship a model with a wide-lobby and a carry-lobby case |
| Should fix | **A re-skin, and it overlaps another tribe.** Feed bonus is Blood Gems ("+1/+1 more this game"), and the doc says so. "Your biggest Bird", auto-picked, is the Hunters carry's Alpha without its collar. The Hunters designer rejected auto-biggest on purpose: "auto-picking the biggest locks the carry forever". The Ratchet's "attacks the biggest enemy" is Hunters' Isegrim | `hunters-carry.md` lines 5, 30, 238 | Keep the Bird-only parts (the thieves and the Lump shove). Drop "Chick" as auto-biggest and point Feeds at a slot or a marked unit |
| Should fix | **It drops the owner's favourite payoff.** The Ratchet's landing ("both halves of the Bird", 08f) is gone, and Nests leave card text. CLAUDE.md: design reactions are directions; don't cut what the owner liked without a logged reason | 08f | Bring the landing back: an Egg dies and its Bird lands, as in the other two designs. Move the chain to a different card |
| Should fix | **"Feed" is taken.** Hedgerow already "feeds" Acorns to Dozey (his details: "Feeding rounds up"), Mrs Mallow is "Feeding Them Up", Hunters engine coins Feast and Oozes coin Eat. The wording guide says one word per concept | `alderman_dozey.json`, `mrs_mallow.json` | Another verb: Peck, Brood, Fledge |
| Should fix | **Golden Whistlers is a destroy across.** "A fifth of its stats per different Bird": five different Birds removes the unit, and seven goes past 100% | Card text | Golden: "a seventh per different Bird", so only a full set of seven removes it |
| Note | **Full-Health Eggs make flying nearly free.** The cost is Attack and text only, and a 0-Attack wall with full Health still soaks. "Who flies" leans to "everyone but the Chick and three attackers" | Rule | Accept it (it answers 08f), or use ¾ Health |
| Note | **Copies stack k.** Two Cuckoos double the bonus rate. The sweep should test copies, not only k | Card text | Sweep it |

### What survives

Jack Daw, "your Chick permanently steals a quarter of the stats of the enemy across". It grows with the field, it is a real placement decision against the scout, and it rewards answering. That is the best single card in the three designs. Mag Pye handing the stolen text to the carry. The Lump shoving the old Chick out and taking its buffs, which is a great moment. Tom Tit's "Your Chick takes half damage", which still works at 4-digit stats. And the wording point that golden Feeds say "twice", so goldens keep pace with a rising bonus.

---

## 4. Problems all three share

1. **Mrs Stork's 6-gold count isn't defined.** None of the designs says whether it carries over between turns. The engine's line policy even branches on it. Today's engine keeps the remainder on the unit (`src/core/effects/effect_runner.gd`, `_times`, stored in `source.counters`), so it appears to carry over. If so, the engine's and carry's "spend in 6-gold blocks" save rules do nothing. Say it in Details.
2. **T5–T6 bodies fail the progression bar.** The bar: a tier-up arrives at or above the player's median unit. Every design's T5–T6 bodies are 12–16 stats, against an own median unit of about 60–70 at R12 (0.2–0.26 of it). Engine and Carry make up for it by growing the stayers (Cuckoo keepers; Redwing and Goose Feeds). Wild doesn't. All three should state that the payoff, not the body, is the tier-up reward, and the sweep should check it.
3. **"Lands" vs "comes home".** In Engine and Wild, the Ratchet's landing is explicitly *not* a homecoming, while every other return is. Two near-synonyms with different rules break "one word per concept". Use a different verb for the Ratchet, such as "drops in".
4. **No design fought a board.** All three are growth calculators. The concentration claims need the audit's combat model, because a carry holding 30% or more loses 9–20 points without holders (fundamentals 1.6). Wild's carry is the most exposed (50–67% of the board, Cleave only). Carry's is the most protected (half damage plus the chain).
5. **The pool's any-row answer budget.** Engine adds two, Carry one and Wild none. Other panels already add four. Whoever synthesises across tribes should count them before adopting any.

## 5. What the synthesis should take

- **Core: Wild's Grow-while-away**, with the two must-fix rate limits:
  - a Bird Grows at most once a turn;
  - Goose's Golden Egg comes when bought, not on every replay.
- **From Engine:** Redbreast as the stayer who grows from homecomings, set to a share of what the Bird grew. That gives the stayers growth and the board a visible carry that never flies. Also Tom Tit's Shield on the biggest Bird, or Carry's half damage.
- **From Carry:** Jack Daw's permanent steal across, given to your biggest Bird, and the Lump's buff shove as the way to switch carries.
- **Keep:** the Ratchet's Egg-crack landing and the omen Whistlers, with all answers aimed across.
- **Settle with the Fairies panel** who owns Grow before anything is built.
