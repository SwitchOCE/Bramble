# Hunters pass 3: the breaker's critique

9 Nov 2026. The adversarial critic for the Hunters panel (Track C, `docs/ideation/plan-scale-rework.md`). I read the three designs (`hunters-engine.md`, `hunters-carry.md`, `hunters-wild.md`), the owner's notes 09a, 09c, 09d and 08e, `fundamentals.md`, the plan, rulebook §8–9 with the BRAMBLE ideation rules, the wording guide, `content/hunters.md`, and the other panels' pass 3 files where they overlap. I reran all three designers' models and probed them.

**My probes:** `hunters-breaker-probe.py`, next to this file (`python3 -I hunters-breaker-probe.py all`, about 5 seconds).
- It adds Quarry, Take, Pack, Shield, Cleave and Sable to the audit's combat model.
- It reproduces the audit's carry test: 14.7% here, 15.4% in the audit.
- It is a paper model with plain units and no Godot. Read its numbers as directions, not measurements.

The target is the brief's: level with today's game to round 7, then about ×1.5 a round. Median boards are 158 / 531 / 1,793 at rounds 9 / 12 / 15, and a strong board is about 717 at round 12.

## Ranking

| Rank | Design | Reward moments | Decisions | Identity | Scale guardrail |
|---|---|---|---|---|---|
| 1 | **Wild** ("You are what you hunt") | 5 | 4.5 | 4.5 | **Closest, and the only one that holds up.** Its model reports boards as they fight, and its lines stay near the field when pieces come a round early or late. Its risks are fixable |
| 2 | **Engine** (the Feast) | 3.5 | 3 | 4 | **Fails as written.** The model scores each board after its own fight and credits Takes at a winning board's rate. Corrected, it is behind until round 15, and it sits on a knife-edge between falling away and a common 2× line |
| 3 | **Carry** (the Alpha and Titbits) | 3.5 | 3 | 2 | **Its numbers don't stand.** The model is one fight ahead too, and the engine needs 9–10 board slots. All its winning comes from Cleave on the Glutton. Ermeline turns every spare gold into carry stats, with no limit |

**Why Wild wins.**
- **Reward moments:** the most, and the most legible.
  - Each enemy shows its price in the scout ("Take: +12/+15").
  - The everyday surprise is common, not a highroll: a 2/3 stoat swings for 62 and comes home 32/32.
  - The rare ones are stories: the fox cub that ate the moose, and "I bought their carry".
- **Decisions:** every Taker's reward depends on its own lane, so "big prey or sure prey" is a real matching problem. In the engine design the rewards are pooled, which shrinks it to one sum.
- **Identity:** Quarry and the Take are the engine itself, and answering a carry *is* how the tribe grows.
- **Its model is the most honest.** Boards are measured before the fight, and the Take chance falls when the board is behind.

**Why Engine is second.** It is also built on the Take, and Old Brock's sett is a good positional puzzle. But it pools every meal into Feast points, so each lane's question becomes "maximise Takes × prey". The designer's own buy rule ("more Feast than hunters, buy a hunter") turns the shop into a formula. And its scale case rests on two errors in the model (below).

**Why Carry is third.**
- It has good parts: Young Brock's Shield, the B2 choice, hunt or harvest at tier 6.
- **But its core is a re-skin.** Blood Gems (Titbit), a Fearless Foodie improver (Grizel), Divine Shield, Cleave and a refresh payoff.
- **Aiming stops mattering.** 80% of its growth doesn't come from Takes, by the designer's own count.
- **The Alpha is another tribe's idea.** It is the Birds carry's Chick, and the Titbit is pass 3's fifth "one number that sizes every buff".

---

## Findings that cut across all three (for the synthesis)

| Severity | Finding | Evidence | What to do |
|---|---|---|---|
| **Must fix** | **Cleave on the carry decides fights, and all three put Cleave on the Glutton.** When a carry's Attack is at least about twice an enemy unit's Health, every swing kills three. That is just where a Battlegrounds-shaped carry sits at equal totals: Attack about 0.15 of its board against Health about 0.08 of theirs. Stat totals then stop meaning anything | Probe 2. The carry design's R12 board, 238 stats with a 102/103 Glutton, beats the 531 median 100% and the 717 strong board 84%. Without Cleave, the same layout with an 87/88 Alpha wins 0%. The wild Open Season R12 board wins 48% against the strong board with Cleave and 4% without. The audit's +11 for Cleave was measured on a 10-Attack Dozey at R9, where a side hit rarely kills | Cost Cleave with fights, not totals: run the carry-against-field sim with Cleave on and off. If it stays decisive, use a weaker form: "also deals half to the units beside", or Cleave on a support body rather than the main carry. The Track B owners should know: it's a shared keyword |
| **Must fix** | **Does Cleave work while joining? Nobody has settled it.** Pass 2 says "joining isn't attacking". The carry design adds Cleave on joins as engine work. The wild design assumes it (the Glutton joins from B2 and "Cleave uses the overkill") but doesn't list it | Wild Pack line R12 against a strong Battlegrounds-shaped board: 77% if joins cleave, 18% if not | Decide once, and log it. A joiner that cleaves takes no hit back *and* kills three, the strongest pairing in the tribe. My lean: joins don't cleave, so the Glutton chooses between leading (cleave, takes the hit) and joining (safe, one target) |
| **Must fix** | **Two of the three models report each board after its own fight.** In the engine and carry models, each round's board already includes that round's meal. The target is the board that fights | Engine model rerun as fought: R9 103 (0.66×), R12 466 (0.88×), R15 2,178 (1.21×), against the claimed 1.10× / 1.37× / 1.93×. The carry's Alpha fights R12 at 87/88 (102/103 with the Glutton), not 130/130 (190/190) | Fix both models. Check the other panels' models for the same slip |
| **Must fix** | **Hunters and Bog now share one mechanic.** Bog's wild design: "When the enemy this Mires dies, this gains X% of its stats permanently", read at combat start and rounded down. Hunters' wild design: "Take: gain half the quarry's stats permanently", read at combat start and rounded down. The engine design's Feast is the same thing, pooled. Both tribes mark the enemy across at the same bell step, and both pitches claim to be "the one tribe that grows from what it fights" | `bog-wild.md` §1–2 and `hunters-wild.md`, tribe rules | One tribe owns "grows from the kill". **Hunters are the better home:** the quarry is chosen to be killed, and "you are what you hunt" is the fiction. Bog keeps growth from being bitten (the Bog carry design's Soak) or the Peat, which stays defensive and fits the answer tribe. The two syntheses settle this together |
| Should fix | **The pool's any-row budget is spent before neutrals get any.** The default allowed two or three "biggest enemy" cards in the whole pool. All three Hunter designs keep Isegrim. The carry design adds Lutra and makes Isegrim aim every Hunter. The Birds designs have the Ratchet, and the Bog designs have Jenny and the Lantern Man | `fundamentals.md` question 2; the pass 3 files | Hunters keep one any-row hunter (Isegrim). Old Brock's reach into their B2 and Lutra's "across, in any row" are positional, so they don't count |
| Should fix | **Takes depend on standing, and two designers ignored it.** A Hunter behind makes fewer Takes, and one ahead makes more | Probe 1, per Quarry Hunter a fight: 0.27 at 0.67×, 0.42 at 0.8×, **0.65 level**, 0.82 at 1.25×, 0.92 at 1.5×. Win rate goes from 11% at 0.9× to 88% at 1.1×. The engine model's fixed 3.5 Takes from four Quarry Hunters (0.875 each) is what a board 1.4× ahead makes. The wild model uses a curve, but a gentler one: 84% of the level rate at 0.8×, where the probe gives about two thirds | The harness's field fights should measure Takes. Any Take-fed engine needs enough growth from sources that aren't win-gated to avoid a losing spiral |
| Note | **Tier 4–6 enablers stay paper** in all three. Wild: Ermeline 6/9 and the Laird 9/12 at R15, when the median unit is about 234. Carry: Isegrim 6/8, Young Brock 2/3. Engine: Ermeline 3/6, Toll-Bard 6, Lutra 44 | The designers' own boards | A capstone that arrives as a 6/9 fails the plan's progression bar. Give enablers a share of the engine (a trophy or Feast) or a body at par with the field |

---

## 1. Wild: "You are what you hunt"

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **The Laird's text says the opposite of its ruling.** The card says "Your Takes trigger twice". Details say "'Take:' text fires twice; 'After each Take' text fires once". So the Glutton and Ermeline, the carry and the Pelts, are *not* doubled, though the card reads as if they are. This is exactly the hidden ruling the owner objected to (08e) | Card table and Details lines | Put the rule in the words: "All your units have Quarry. 'Take:' text triggers twice." (9 words). Or let the Laird double every Take payoff and turn the multiplier down (the designer's lever ×1 / ×2 / ×3) |
| **Must fix** | **The Lodger grows whether or not anything dies, and that isn't in the model.** "After this pounces: gain a quarter of the quarry's stats". It reads the quarry's stats at the bell and pounces once a cycle. Next to Old Brock's neighbours, who hunt their B2 with reach, he pounces their carry every cycle it is hit. A Lodger big enough to survive the hit back then takes ¼ of their carry two or three times a fight | At R15 a 547-stat carry is about +137 a pounce, so +270 to +410 a fight from a tier 3. The doc credits 65/80 by R15 from two quarter-shares of a *typical* unit. Neither model line keeps the Lodger past R10 | "After this pounces a quarry that dies: …", or "once a fight". Also settle whether a Lodger who dies pouncing still gains (Bog's Swell says yes). The rules are silent |
| Should fix | **Agnes's text is wider than her rule.** "Your pack leaders take half damage." Details: "Only the counter-hit of the attack they lead." A player reads it as "half damage from everything" | Card and Details | "Your pack leaders take half the hit back." Plain, and only two words longer |
| Should fix | **Early lead with win-gated growth.** The designer's own model has both lines at 1.28–1.29× at R6. In probe 1 a board 1.25× ahead wins over 99% at R12 scale. Early numbers are coarser, but the direction holds. Early wins also pay Spoils gold (rulebook 10.1.4c) and take more Takes. The model does pull back to 0.85–0.95× by R10. Even so, Hunters would be the common round 8 leader, against the plan's bar that the round 8 leader wins at most about 30% | `hunters-wild-model.py` R6; probe 1 | Use the designer's first lever (Nip and Wick at 2/2), then "shares count from R4". Test against the round 8 leader bar specifically |
| Should fix | **Russet's poached copy keeps buffs that were never permanent.** "Half its buffs" reads combat-start stats minus base. That includes the opponent's auras, Rings, tribe bonus and fight-start buffs, which then become permanent on your copy. It is also the best stats per gold in the tribe: about 95 stats for 3 gold at R15 (277 off a carry), against 15–17 for a printed tier 6 | Poach v3 in the engine needs; the doc's own numbers | Copy **permanent buffs only**, the Queen of Elfland's rule (rulebook 12.1.5). Keep half; golden takes all |
| Should fix | **Golden Young Brock doubles your carry.** T1 triples are the commonest goldens. Sell a 300/365 Glutton beside him at R15 and he is 600/730. Any Hunter loaded with Pelts and sold doubles them too | Card text | The designer's lever ("gain its stats and 2 gold"). Or golden: "gain its stats and its keywords", so the Glutton's Cleave moves with it but isn't doubled |
| Should fix | **Pelts are free spells, and other tribes pay for spells.** The Fairies carry design's Hex: "Each spell you cast adds 5%". 3–7 Pelts a fight would push a Fairy-Hunter board to 100% Hex in about two turns. Cricket Busker has its own guard (once a turn) | `fairies-carry.md` line 120 | A Pelt is "played on a unit", not cast. Or "Pelts don't count as spells". Merge Pelts of one quarry, as the designer suggests, to keep the hand clear |
| Note | **Sable alone rarely kills.** She deals her Attack plus the quarry's. Most of our units have more Health than Attack, so 2 + 24 doesn't kill a 24/30. Her "swings for 62" story needs an Attack-heavy target. With a joiner, or Agnes halving her hit back, the trade works | Card text and the field's 45/55 stat split | Keep it. Write her scout preview so it shows whether she trades alone |
| Note | **The Hunter mirror runs hotter than the field.** Two Hunter boards eat each other's growth. The designer checked ×1.5–1.6 a round with the tier 5s, but not with the Laird's ×2 | Doc, "Two checks" | Add the mirror with the Laird to the sweep |

### What holds up

- **The scale shape is robust.** I moved every piece from round 5 on by −1, +1 and +2 rounds in the designer's own model.
  - Open Season at R15 ranges from 0.88× to 1.41×, and the Pack line from 1.22× to 1.52×.
  - Both lines come back toward the field instead of running away or collapsing. That is the property the engine design claims but doesn't have.
- **It fights at its size.** In probe 2 the R12 Open Season board (488) beats the 531 median 100% and the 717 strong board 48–50%, against a target of about level to strong.

### What survives

The core sentence, "a Hunter grows by what it kills". The scout's trophy preview. Sable's proportional strike. "I bought their carry" (with permanent buffs only). The Laird as Brann for Take. Isegrim's gang on the biggest enemy. Pelts with the prey's portrait. Young Brock the heir. Text is short (median 11 words, longest 16).

---

## 2. Engine: the Feast

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **Corrected, the engine is behind until round 15.** The model scores each round after its own fight, and its fixed Take schedule is a winning board's. As fought, with the designer's generous Takes, the sett line is 0.78× at R6, 0.66× at R9, 0.88× at R12 and 1.21× at R15. The Pack line is 1.03×, 0.69×, 0.72× and 0.99×. The brief wants "behind at once, level in a few turns, clearly ahead after" | Rerun of `hunters-engine-model.py` with boards taken before each fight. Probe 2: the sett as it fights R12 (461) beats the 531 median **15%** (even) or 60% (Battlegrounds-shaped), and the 717 strong board 0%. The doc's post-fight board (729) wins 100% | Fix the model, then size s again. Rounding up already adds about a third at R9 |
| **Must fix** | **A knife-edge between a slump and a common 2× line.** From flat bodies, keeping pace with a ×1.5 field needs Feast points × Takes of about **26** a fight at a sixth: the meal must be at least half the board. The sett line makes 6–8 × 2.6 = 16–21 at level standing, so it drifts down, and fewer Takes when behind speed the fall. Merge the two lines' pieces, as a real player does (the engine line has Brock, the Lodger, the Glutton and the Laird; the tempo line has Grizel and Agnes), and Feast stacks to 12. Agnes gives Brock and the Lodger Pack, Grizel then gives them Feast, and Brock adds his own. With the Laird's 7 marks that is 54, twice the bar | Probe 3, with Takes from standing (probe 1):<br>– Sett line alone: 0.42–0.73× at R12 and 0.19–0.42× at R15.<br>– Merged line, starting 0.76× at R8: 0.33× at R15.<br>– Merged line, starting level at R8: 1.96× at R15.<br>A 30% difference at R8 becomes 6× by R15. That is the "one-round lead decides" pattern (`fundamentals.md` §1.11) | Count only a unit's **biggest** Feast source (Brock, Grizel or its own), not the sum. That caps the merged line near the sett line. Then raise s (a fifth or a quarter) so the sett line clears the bar at level. Or feed Feast from every enemy death, not only Takes, so a losing board still eats |
| Should fix | **Agnes makes the back-row carry untouchable.** "Units behind this have Pack and join its attacks": the Lodger and Brock strike from cycle one, take no hit back, and can't be attacked while the front stands. They also grow mid-fight | Card text; the designer's own risk #2 | The designer's lever: only the unit directly behind her joins. Or the joiners take the hit back on a kill |
| Should fix | **Five cards pay flat amounts at a compounding scale.** Little Nip +1/+1 a Take (11/12 at R15). Wick +1/+1 a joined kill. Russet a 1-gold discount on a base copy. Ermeline about 3 gold off a tier-up, then up to 2 gold a turn. The Toll-Bard about 0.9 gold a turn, and he takes a lane from the Takers. Away from Brock's sett they are dead slots | The doc's own payoff lines | Tie each to the meal ("Take: gain the meal", "Take: get a Feast copy"), or replace them. Ermeline's capped discount is the audit's "too small" pattern |
| Should fix | **The aim decision is pooled.** Every Take feeds every Feast point, so the scout question is one sum: P(kill) × prey stats. The designer writes it as the harness rule. The buy decision is a rule of thumb too | "Aim rule" and "rule of thumb" in the doc | Give a few Takers their own share of the meal (as Wild does) so lanes differ |
| Note | **Keyword grants on keyword grants** (Agnes → Pack → Grizel → Feast) need a layer order the engine doesn't have yet | Engine-support table | List it as engine work, or cut the chain with the "biggest source only" rule above |
| Note | **Old Brock can be splashed.** "Units next to this have Feast" feeds a Hedgerow unit beside him | Doc, Feast details | Harmless while only Hunters make Takes. Say "your Hunters next to this" if the Lollop lesson is to hold |

### What survives

Old Brock's sett: a protected B2 enabler that makes placement matter around one card. Isegrim's Health cut, with the meal read before the cut, an elegant "answer that pays". The meal shown on each paw print in the scout. Feast as a single-card idea (a pooled feeder like the Lodger) inside the Wild design, under the "biggest source only" rule.

---

## 3. Carry: the Alpha and Titbits

### Breaks

| Severity | Break | Evidence | Fix that keeps the core |
|---|---|---|---|
| **Must fix** | **The engine doesn't fit on 7 slots.** The typical line counts Titbits from Nip, Wick, the Lodger, Lutra, two Grizels and Ermeline (7 cards). Then the Glutton must wear the collar, Brother Wolf must give it Pack, and Young Brock must give it Shield: 10 cards. The printed R12 layout has no Grizel, Ermeline or Brother Wolf, so as shown the Alpha neither grows nor holds. Wick beside an Alpha that never leads gets no joins, so his "1.5 joins a fight" is zero there | Doc §3 layout and §5 assumptions | Rebuild the line on 7 slots. Probe 4, dropping only the Lodger: the Alpha is 161 at R12 and 641 at R15 against 187 / 727; with one Grizel, 149 / 485. All four figures use the designer's after-the-fight convention |
| **Must fix** | **The hold doesn't make the carry win; Cleave does.** The designer's case is that Pack-joining plus Shield makes concentration pay. In the fight probe it doesn't, and without the Glutton the carry route has no win condition. That stakes the tribe on two cards: Grizel (about 85% of growth) and the Glutton | Probe 2, the doc's own R12 layout, Alpha sized as it fights:<br>– 87/88 Nip Alpha with Pack and Shield: **0%** against the 531 and 717 boards, even or Battlegrounds-shaped.<br>– 102/103 Glutton with Cleave: 100% / 92% / 84% / 6% | See the Cleave finding above. If the carry route survives, the hold needs to work without Cleave: Agnes's flanks earlier (tier 4), or a stat-holder on the Alpha such as damage reduction |
| **Must fix** | **Ermeline buys carry stats with every spare gold, with no limit.** Each paid refresh is a Titbit, and the first 15 a turn cost 1 gold (rulebook 4.4.2). On the Glutton (double Titbits) that is about 28 stats a gold at R12 and 52 at R15, at the doc's own Titbit sizes (+7/+7 and +13/+13). A 3-gold tier 5 body is about 12 stats. So from R10, refreshing beats buying anything but a key piece, and every refresh also digs for Grizel, the Glutton and triples. With no recruit timer, the right turn is 10–15 refresh clicks. Not win-gated, so not a lobby snowball, but a dominant line that removes the buy decision | Probe 4, same convention as the designer:<br>– All spare gold to refreshes: Alpha 317 at R12 and 1,217 at R15, against 187 / 727 (×1.7).<br>– A second Ermeline, a common tier 4 copy: 525 / 2,085 (×2.8) | The designer's lever: one Titbit per two paid refreshes. Or "the first 3 paid refreshes each turn". A rate limit on a gold loop is allowed (brief) |
| Should fix | **The collar is a free cursor, not a commitment.** "Make Alpha" is free and unlimited, and earned stats stay put. So switching costs nothing, and a player can move the collar between refreshes to send Ermeline's Titbits to any Hunter. Once the Glutton is bought, collaring it (double Titbits) is simply right. The designed dilemma ("switching too late is the common mistake") doesn't exist | §1 Alpha rules | The collar moves once a turn, or Recruit-phase Titbits land on the Alpha at End of Turn. That puts a real cost on the switch |
| Should fix | **Blood Gems, five times over.** The Titbit is Battlegrounds' Blood Gem, and the doc says so. Pass 3 already has Birds' Tailwind and Feed bonus, Bog's Peat and Fairies' Glamour (the Fairies breaker counted four). "Your Alpha" is the Birds carry's Chick with a collar. The tribe's own keyword, the Take, drives only Nip, Lutra and the Laird | `birds-breaker.md`, `fairies-breaker.md`; §5 "80% … not win-gated" | If the synthesis keeps a carry piece, keep it out of Titbits: Young Brock's Shield and the B2 choice fit the Wild design as written |
| Should fix | **Isegrim answers only when you're already winning, and takes away the aim.** "Your Hunters' quarry is the biggest enemy" points every Hunter, the Alpha included, at their carry. It kills it only if your Alpha is bigger (the doc: "Lutra alone does 3 damage"), so it adds no upsets to the variance budget. It also ends the matching problem at tier 6 | Card text and doc §3 | Aim his gang only (as in Wild), or Sable's proportional strike. The text should also say whether Hunters without Quarry gain one |
| Note | **Four hidden rulings on one status.** An Alpha with Pack waits for a partner to lead. A sold Alpha's collar goes to the Hunter with the most stats. Agnes passes on only the base Titbit size. A fainted Alpha still gets its Titbits. Plus a new recruit action and its UI, the most engine and UI work of the three designs | §1, §7 | Cut with the collar fix: fewer moves, fewer rulings |

### What survives

Young Brock: "Start of Combat: your carry gains Shield", a tier 1 holder whose value grows with the field at no cost. Brock and the carry contesting B2. Hunt or harvest at tier 6 (Isegrim or the Laird). The Toll-Bard's twice a fight. Lutra beside the carry, leading it into their biggest unit in cycle one.

---

## For the synthesis: a suggested base

1. **Take Wild as the base.** Fix the Laird's and Agnes's words, the Lodger's every-cycle pounce, Russet's copied auras and golden Young Brock. Settle Cleave on joins, then test the early-lead bar.
2. **Settle the trophy with Bog** before either tribe goes to Step 3.
3. **From Engine:** Isegrim's Health cut with the meal read before the cut, and Old Brock's sett as a positional enabler. Use Feast only on one or two cards, under "biggest source only".
4. **From Carry:** Young Brock's Shield on the carry, as a second tier 1 option or on Agnes.
5. **The sims to ask the harness for:**
   - Takes a fight by standing.
   - Cleave on and off on the Glutton, at R12 and R15, against field boards.
   - The round 8 leader's win share for Hunters lines.
   - The Hunter mirror with the Laird.
