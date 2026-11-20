# Balance night log, 19–20 Nov 2026

Calls I made without the owner, as I made them. Paths under `/data/` are on the Optiplex. The films and the before/after clip are in [`media/`](media/), stored in R2 (`python tools/assets/assets.py pull docs/workstreams/reworks/night-19-nov`). The owner OKd motion fixes from the films ("Go, log each call"), and full access for Codex workers tonight.

## Card data is frozen on dev tonight
- **Why it came up:** the ghost orchestrator starts the owner's third bot run once Rust is level with dev. It uses whatever cards are on dev when it starts.
- **Options:** land tuning on dev as the measurement calls for it, or keep tuning on a branch.
- **Chose:** no card or rule changes on dev tonight. Tuning goes on a branch as a proposal for the morning, so the third run's ghosts stay current.
- **What rests on it:** any tuning waits for the owner's OK.

## Films judged (pigeon-reserve, mouse-kin, recruit-marks)
Films: `/data/balance-endcheck/films/`. Fixtures: commit 62270aee on `balance/endcheck-films`. I judged them from stills and contact sheets at 60 fps, not on a real display.

### Charge pips dim with a snap: left as is
- **Why it came up:** in pigeon-reserve, frames 252–282, the Bugler's pip goes from lit to dim in one frame.
- **Options:** a short fade or pulse on spend, or leave it.
- **Chose:** leave it.
  - Spent keyword marks also snap, so this is consistent.
  - The card's trigger glow and the Private stepping in already show which card fired.
  - A fade means tracking pip state between rebuilds (`CardPips.make` rebuilds from scratch), which costs more than it buys.
- **What rests on it:** nothing.

### Pip size at board size: left as is
- **Why it came up:** a pip is about 8–10 px at 1080p on a board card. Lit and dim are told apart by white against grey, over busy art.
- **Seen:** readable in recruit-marks frame 23: the Sentry's crates and a card's four round pips.
- **Not seen:** a real display, or a smaller window. This is for the owner's play.

### Reservist Renown pill: fine
- **Seen:** in pigeon-reserve, frames 110–140, the slot's "Renown 3" crossfades to "Renown 6" as the Territorial fades in, over about 0.15 s. The Privates show plain Renown 3.

### Reserve-limit marks: fine
- **Seen:** two marks above "Hand 1/7" while a Reserve unit is in hand. They go when it's played and come back when it returns.

### Pile on reads as the attacker's damage: being fixed
- **Why it came up:** in mouse-kin, frames 72–116, the piler (Fencing Master) only glows and lifts. Its −4 lands at the attacker's impact, so it reads as the attacker's hit. The rule text says the piler "hits the target first".
- **Options:**
  - leave it;
  - a separate full attack per piler (slow);
  - a short grouped jab that lands before the attacker's impact.
- **Chose:** the short grouped jab, at most about 0.25 s extra per attack with pile-ons, with its timings as named constants.
- **Built by me.** Codex workers were refused `git checkout` even with full access, so I wrote it myself: commit 81b86e12 on `fight/pile-on-jab`.
  - The attacker winds up and waits at home.
  - The piler jabs about 60% of the way along the attacker's lunge: 4 frames in, a 3-frame hold, 10 frames back. Its −4 shows as it lands.
  - Then the attacker lunges for the exchange.
  - It adds one 0.22 s step per attack with pile-ons, and none otherwise.
  - Constants: `FightMotion.JAB_*`.
- **Film after:** `media/mouse-kin-pile-on-jab.mp4`. Contact sheet of frames 44–196: `/data/balance-endcheck/review/pileon-after.png`. In order: the wind-up (frames 44–61), the jab with −4 (94–112), then the lunge with −3/−7 (166–196).
- **Revised after the gate and the scope review:**
  - The piler now jabs out and holds at its jab point while its effects play, then goes home as the attacker lunges.
  - The first version passed the gate but didn't move in a real fight (`_recoiled` sent it home). The review caught that, and so did the films; frame sheets are `review/pileon-after2..4.png`.
  - test_slot_layers now plays the real pile-on moment. It fails with the broken placement (checked).
- **Scope review asks (for the owner, so not merged):**
  - (1) **Time:** a plain one-piler attack goes from 1.47 s to 2.24 s (+0.77 s), more than the 0.25 s I aimed for. In the Mouse film, a trigger already split the steps, so the gain there is only +0.22 s.
  - (2) **Scope:** "Go, log each call" answered a question about pips, the Renown pill and reserve marks, not pile-on choreography.
- **Not judged:** the attacker now waits wound up at home for about 2 s while the pile-on's triggers play. Before, it waited at the target. It reads correctly but may feel slow, which is for the owner to judge.
- **What rests on it:** only screen motion. No fight result or log change.

### The fixtures hover the Charge card the whole fight
- In the films, the pointer sits on the Charge card, so its enlarged detail covers parts of the board. That's a fixture choice, not the game. Noted so the films aren't misread.

## First measurement of the reworks (dev 9182e381, ~01:20)
TribeBot, 200 games per arm, same seeds as the earlier arms. Script: `/data/measure/run_reworks.sh`; comparison: `/data/measure/reworks/compare.py`. Lower placement is better, out of 8.

Pigeon-locked seats:
- old 4.24 → new 4.64 (+0.40 ± 0.12, worse);
- with the old bot on the new cards it's 4.80;
- so the new bot helps by −0.16 ± 0.08.

Mouse-locked seats:
- old 5.49 → new 5.76 (+0.27 ± 0.11, worse);
- the bot change makes no difference.

Badger-locked seats: arm C 4.28 → 3.97 (−0.31 ± 0.12).

A/A by main tribe, dev against arm C:

| Tribe | Arm C | Dev | Dev top 4 | Dev win |
|---|---|---|---|---|
| Badger | 3.87 | 3.28 | 73% | 18% |
| Briar | 4.20 | 3.86 | 58% | 34% |
| Locust | 4.41 | 4.09 | | |
| Pigeon | 3.90 | 4.66 | | |
| Mouse | 6.13 | 6.64 | 8% | 0% |

Diagnosis so far: Mouse final boards average 77 Attack and 70 Health on dev, against 135 Attack and 63 Health before the rework. The rework took away most of the Mice's Attack scaling.

Not separated: dev also has the sell rule and the slot-buff retirement (S9), so "old → new" is the reworks plus those. Pigeon readings are provisional until the ghost orchestrator's post-S8 port (the Quartermaster's Reserve cap in TribeBot).

### Tuning goes to a branch, numbers only (my call)
- **Why it came up:** both reworked tribes got weaker, and the Mice are far outside the range (0 wins in A/A).
- **Options:** wait for the owner; tune numbers now on a branch; redesign cards.
- **Chose:** a Codex designer proposes number-only changes (no text or mechanic changes, generous per the owner's direction). I measure them on a copy of dev, and leave them on a branch for the owner, not on dev, because card data is frozen for the third run.
- **What rests on it:** nothing on dev.

## Tuning round 1 measured (~02:00)
Six buffs (`/data/balance-endcheck/tuning/proposal.md`), committed on `balance/mouse-pigeon-tuning` (not pushed or merged).

- **Mouse-locked seats:** 5.76 → 5.55. Their final Attack is back to 128 (old 135), and in A/A the Mice have the most Attack of any tribe from round 6. They still place last in A/A (6.13, 1% wins), with the lowest Health every round.
- **Pigeon-locked seats:** 4.64 → 4.56.

Round 2 is asked for: why Attack doesn't convert, Health-side numbers, and a verdict on whether TribeBot's Mouse play (pilers in the back row, Hand-me-down routing ignored) caps what numbers can show.

## Tuning round 2 measured (~02:40)
The designer's diagnosis: the Mice lose on Health. 354 of 600 fights in rounds 6–10 were lost with more Attack and less Health; at round 8 their front row averaged 31 Health against 63.

The change: seven numbers, six of them Mouse Health and one the Lance Corporal's Renown, 1 → 2.

The result:
- **Mouse-locked:** 5.55 → 5.04 (−0.51 ± 0.11).
- **Pigeon-locked:** 4.56 → 4.44.
- **A/A:** Badger 3.73, Locust 4.37, Pigeon 4.48, Briar 4.49, Mouse 5.45.

The Pigeons are now inside the others' range, so I'm leaving them. Round 3 is asked for, Mice only, aiming at about 4.3–4.5 and leaning generous.

## Tuning round 3 measured (~03:30); stopping here
The change: five Mouse Health buffs on the Harvest Piper, Thimble Captain, Dormouse Cook, Widow Thimble and Needle Pikeman, at about +1 body each, deliberately generous.

The result:
- **Mouse-locked:** 5.04 → 4.54. From dev it's −1.22 ± 0.12 in all; wins 10.5%, top four 51%.
- **A/A:** Badger 3.86, Locust 4.50, Mouse 4.59, Briar 4.71, Pigeon 4.86. All five tribes are inside one place of each other.

The Pigeons slipped from 4.48 to 4.86 in A/A. The tuning didn't touch them; the other tribes got stronger around them, and the error is ±0.27. Their rerun waits for the post-S8 port anyway.

- **Chose:** stop at round 3. The spread is the tightest any arm has measured, and the owner's rule is generous-first, then dial back after play.
- **Branch:** `balance/mouse-pigeon-tuning`, pushed, not merged. 18 numbers changed across the two units.json files, plus the three rounds' reasoning in `docs/workstreams/reworks/tuning/`.

## League bots on dev, untuned (red against blue, 1,000 games)
- Locust is 78% of final boards, at 4.14.
- Pigeon is 17.5%, at 6.39.
- Mouse is 0.3%, and Badger 0%.
- Red 4.06, blue 4.94.

These bots' card weights predate the reworks, and they can't hold reservists or use Actives on purpose, so their Pigeon reading is understated (as the build plan says). Read the tribes from TribeBot.

## Pigeons rerun on dev 61601f2d (post-S8 port, ~04:00)
- **The Reserve-cap bot fix changed almost nothing:** Pigeon-locked 4.638 → 4.633 (−0.005 ± 0.010), as the ghost orchestrator expected.
- **With rounds 1–3:** Pigeon-locked 4.56, still +0.32 ± 0.11 worse than pre-rework.
- **A/A with rounds 1–3:** Badger 3.85, Locust 4.50, Mouse 4.59, Briar 4.72, Pigeon 4.86. Pigeons are now last.
- **Chose:** one more round, Pigeons only, aiming at about 4.3–4.5 in A/A. Same rules: numbers only, generous.

## Tuning round 4, Pigeons only (~04:40): overshot
The change: Territorial 4/5 → 6/9, Old Campaigner 4/7 → 7/11, Grenadier Guard Renown 2 → 4, Lieutenant Attack 5 → 12 (`tuning/round4/proposal.md`).

The result:
- **Pigeon-locked:** 4.56 → 4.07 (−0.49 ± 0.09), now better than pre-rework (4.24).
- **A/A:** Pigeon 3.74, Badger 4.17, Locust 4.69, Mouse 4.86, Briar 5.05. The spread widened to 1.3 places, and Pigeons went from last to first.
- **Chose:** don't keep round 4 as it is. Measure a halved version (4b): Territorial 5/7, Old Campaigner 6/9, Grenadier 3, Lieutenant 9.

## Drag pitch flake fixed (branch `fix/drag-pitch-flake`)
- **Cause:** the card's pitch under drag was worked out per rendered frame, so a slow frame (a loaded machine) changed how far it tipped. That's a real game bug: tilt depended on frame rate.
- **Fix:** the velocity filter runs inside the game-time spring substeps (`src/screens/card_carry.gd`). The reviewer confirmed no change at 60 fps or faster.
- **Checked:** the full gate passes; the scope review has no cut or ask items.

## The third bot run hasn't started (ghost orchestrator, ~10:20)
Two of its workers sat on Codex approval prompts until 09:30. Scored matches start only after the async proof and a field re-cut at the final rules. Any card change on dev forces a re-cut (under an hour). The ghost orchestrator would rather the tuning lands first, and will name the commit the scored run pins to before it starts. So the owner's tuning decision isn't racing the run.

## Tuning round 4b measured (~10:35): kept
- **Pigeon-locked:** 4.32 (pre-rework 4.24; rounds 1–3 4.56).
- **Mouse-locked:** 4.66.
- **A/A:** Badger 4.07, Pigeon 4.18, Locust 4.59, Mouse 4.79, Briar 4.87. Spread 0.80, the tightest yet (rounds 1–3: 1.01; round 4: 1.31).
- **Chose:** 4b. Commit 2220f12e on `balance/mouse-pigeon-tuning`, with `docs/workstreams/reworks/tuning/round4.md`. Not merged.

## The tuning broke 15 tests; brought up to date (~11:00)
- **Why:** the card tests compare the game with `docs/ideation-track-2/tribes/*/units.json`, and several rulings and plans hard-code numbers. The tuning branch had never been gated. The preview's gate caught it.
- **Done:** a worker updated the design files, the expected values from each rule, and three ruling fixtures so the same death still happens. It also regenerated LIVE_REFERENCE. No assertions were removed. Gate passes (189bf37d).
- **Coverage put back:** the 1-Renown Lieutenant case got its own test (49f9482f), shown to fail with 2 Renown.
- **The preview build (1ff796e5) predates this,** but its game content is the same. Its rules soak passed on its own: 150 games, 0 violations.

## The Mouse Health pass goes against the owner's rule (found ~11:15)
- **Found by:** the scope review of the test update. It pointed at the Mouse README, which quotes the owner (16 Nov): "I don't want them to scale HP, so they are weak, but it'd be good for the Mice as a tribe to have a lot of attack scaling". The accepted rework pitch says: "an Attack-only tribe with no Health scaling".
- **What happened:** the round 2–3 designer briefs asked for numbers only and generous. Neither the brief nor my checks named the tribe's identity, so a Health pass went through that makes the Mice the highest-Health tribe at their tiers.
- **Chose:** not to recommend merging the Mouse half; it goes to the owner as question 1. I'm measuring the Pigeon half on its own so it can be decided separately.
- **Lesson:** every tuning brief must quote the tribe's design rules (README, accepted pitch) and say they are fixed.

## Pigeon half measured on its own (~11:35)
Mouse cards as on dev, Pigeon cards from the tuning branch (worktree `/data/wt-pigeon-only`).
- **Pigeon-locked:** 4.08 (dev 4.63, pre-rework 4.24; with the Mouse tuning 4.32).
- **A/A:** Pigeon 3.52, Badger 3.62, Locust 4.31, Briar 4.41, Mouse 6.65.
- **Read:** the Pigeons' strength depends on the Mice. Weak Mice lift every other tribe. Merging the Pigeon half alone is generous, and it needs a re-check once the Mice are settled.
