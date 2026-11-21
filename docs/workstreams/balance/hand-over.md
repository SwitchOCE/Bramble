# Balance: where it stands (hand-over, 20 Nov 2026)

Written by the outgoing balance orchestrator as its last act, for the session that takes over. It points to the files that hold the detail.

**In one line:** every card change since the league has been measured either with bots that no longer count, or with bots that can't play the cards. Balance is not measured until the third run's bots pass the stopping test ([ghost plan, step 5](../third-run/ghost-plan.md)).

## 1. What is on `main` and `dev`

`dev` holds balance batch 1 (PR 214, merged 21 Nov): the owner's picks across all five tribes and the neutral pool. `main` gets it with the next `dev`-into-`main` merge.

| Change | PR |
|---|---|
| Balance pass 1: Pigeons, Orchard Stripper, Locust Hoppers, Flying Ace, Cleave on one unit, tier swaps | [165](https://github.com/SwitchOCE/Bramble/pull/165) |
| Badgers: Fury and Grudge pay a base amount; Sexton, Lancer, Gate Warden, Relic Seeker, Tourney Champion, Master-at-Arms | [167](https://github.com/SwitchOCE/Bramble/pull/167) |
| Pigeon and Mouse reworks (Renown, Reserve limit, Charge, Supply, the gold-coin Active, Pile on N, Hand-me-down), plus the screen pieces | 172–178, 185, 186; plan: [build-plan.md](../reworks/build-plan.md) |
| Stat slot buffs retired | [182](https://github.com/SwitchOCE/Bramble/pull/182) |
| Created units sell for gold; tokens sell for 0 | [184](https://github.com/SwitchOCE/Bramble/pull/184) |
| Mouse and Pigeon tuning: 24 numbers | [196](https://github.com/SwitchOCE/Bramble/pull/196); reasoning in [tuning/](../reworks/tuning/) |

## 2. What each was measured with, and whether it counts

Since [owner note 2026-11-20a](../../design/owner-notes/2026-11-20a-strong-bots-for-balance.md), only league bots that have passed the stopping test count for tuning. **No reading below meets that bar.** The league readings are 1,000 games of red against blue, with 8,000 final boards each.

| Arm | League bots: final main tribe, share and average place (of 8) | TribeBot (doesn't count) |
|---|---|---|
| Before pass 1 (`measure/baseline`) | Locust 65% 4.50 · Mouse 16% 3.39 · Pigeon 15% 5.63 · Briar 4% 4.60 · Badger 0.1% | — |
| Pass 1 (`measure/arm-b`) | Locust 69% 4.46 · Mouse 15% 3.48 · Pigeon 11% 6.22 · Briar 4% 4.36 · Badger 0.1% | 200-game A/A |
| Pass 1 and Badgers (`measure/arm-c`) | Locust 69% 4.48 · Mouse 16% 3.46 · Pigeon 11% 6.13 · Briar 4% 4.49 · Badger 3 boards | Badger-locked 4.28 |
| Reworks, untuned (dev 9182e381) | Locust 78% 4.14 · Pigeon 17.5% 6.39 · Mouse 0.3% · Badger 0% | Mouse-locked 5.76, Pigeon-locked 4.64; A/A Mouse 6.64 |
| Reworks, tuned (dev e5e8db8a) | Locust 78% 4.22 · Pigeon 16% 6.21 · Briar 4.6% 3.14 · Mouse 0.8% 5.28 · Badger 0.1% | A/A 4.07–4.87 for all five tribes |

- **What the league readings can tell you:** the league bots were tuned on the pre-rework cards. They never play Badgers, can't hold reservists or use Actives on purpose, and stopped picking Mice once the Mice were reworked. So they describe the bots, not the cards. Before the reworks they are the best evidence available, read as bot preferences ([owner note 2026-11-19a](../../design/owner-notes/2026-11-19a-balance-reads-bot-preferences.md)).
- **Where the data is:** each arm's analysis is in `/data/measure/<arm>/bots/tribes.md` on the Optiplex. TribeBot runs are summarised in [the night log](../reworks/night-19-nov/night-log.md).

## 3. The owner's aim ([note 2026-11-19b](../../design/owner-notes/2026-11-19b-balance-pass-aims-and-method.md)), item by item

| Item | State |
|---|---|
| Utility effects too strong across the board | **Untouched** as a sweep. Only Cleave went to one unit. |
| Summons and Hoppers: fewer summons, mostly at low tiers; better Tide scaling | **Done in batch 1 (PR 214):** a Hopper with no room gives Tide +1 and nothing waits; Horde-runner gives Tide on a sale; Swarm-lord counts every Locust death. Earlier: Green Recruit 2→1 and Sky-darkener 3→2 Hoppers. |
| Slot buffs too strong with summons | **Done:** stat slot buffs are retired (S9). The Pigeons' Renown applies to Privates, so watch summons there. |
| Neutral pool and scam (tech) units | **Done in batch 1 (PR 214):** eight tribeless cards in every shop. |
| Fury ("not sure if Fury is a great mechanic") | **Part done.** The Badger pass made Fury pay a base amount. Nobody has judged the mechanic itself from first principles. |
| Tier moves, and whether each card earns its tier | **Part done.** Flying Ace 3→4, Squadron Leader 4→3, Famine-caller and Gorger swapped, Master-at-Arms 4→3. No tier-by-tier audit. |
| Tier-one long-term potential | **Part done.** Sentry was cut and later moved to Supply Renown. The tuning raised Territorial (5/7) and Hedgerow Scout (3/10), which are bodies (tempo), not long-term growth. Nobody has looked at the other T1s. |
| The Colonel ("ridiculously busted") | **Done:** a Reserve limit, and the Colonel now doubles hand reservists' Renown. |
| Flying Ace | **Done:** T4, no Sortie, Cleave hits one random unit. |
| Wing Commander ("has to go") | **Done in batch 1 (PR 214):** 8/14, "Sortie. Charge 4: After one of your Pigeons with Sortie kills, give its slot 3 Renown." |
| Every unit weighed against several kinds of adjustment (numbers, economy or tier, replacement, rework, support) | **Done for batch 1:** every tribe was pitched with all four kinds of change (pitch pages of 20 Nov, owner took the picks); built in PR 214. |

**Nobody has looked at:**
- **Briars:** batch 1 changed Blackthorn Sapling, Elder Mother, Old Mother Midden's golden and Hedge Layer.
- **Locusts' late game** (finding 6), Gleaner and The Eighth Plague (finding 4), Granary Glutton (finding 10).
- **Gold cards** (Hedge Layer, Shrew Cutpurse).
- **Neutral units:** eight tribeless cards since batch 1, offered in every shop.
- **The Badgers' T5–T6** (Dame of the Old Sett, Marshal of the Red Mist).

## 4. The league's ten findings ([findings.md](../bot-league/balance-pass-18-nov/findings.md))

| # | Finding | State |
|---|---|---|
| 1 | Pigeons far ahead (slot buffs) | Dealt with by the rework and S9. |
| 2 | Colour Sergeant out-produces its tier | Reworked to Renown; tuned to 2 per slot. Unmeasured. |
| 3 | The Colonel's uncapped Reserve | Dealt with (Reserve limit). |
| 4 | Gleaner unlimited; Eighth Plague | **Open.** Gleaner still deals 5 per friendly death, with no cap. |
| 5 | Mice weakest | Reworked and tuned. Unmeasured by strong bots. |
| 6 | Locusts fall off late | **Open.** |
| 7 | Badger Fury supports underperform | Dealt with by the Badger pass. Unmeasured: the league bots don't play Badgers. |
| 8 | Briars dominate late through the Compost | **Open.** |
| 9 | Gold cards weak (gold isn't scarce) | Relic Seeker changed. Cutpurse and Hedge Layer **open**. |
| 10 | Granary Glutton loop | **Open** (never tested). |

## 5. Choices made without the owner that still stand

- **Pass 1's proposed numbers:** Flying Ace 8/7, Squadron Leader 4/9 with +3 Attack, Gorger 5/7, and Cleave picking its unit at random (PR 165).
- **Every Badger change** (PR 167), on the owner's "go with your recommendations ... I'll change it later".
- **The reworks' build calls,** listed in [build-plan.md](../reworks/build-plan.md), section 2.
- **The 24 tuning numbers** (PR 196). The Mouse Health increase is the big one. The owner accepted it: "I'm okay with mice having health as a generous start."
- **Pigeon round 4 halved to 4b,** a call made from TribeBot readings.
- **Charge pips dim with a snap; pip size unchanged.** Logged in [the night log](../reworks/night-19-nov/night-log.md).

## 6. What balance waits on, and what can go ahead

- **Waits on:** the third run. Bots hill-climb to at least a local maximum, then pass the stopping test, and each one comes with placement and picks per tribe, locked to that tribe, plus per-mechanic use checks. The ghost orchestrator sends each one. Card rules are frozen during each climb, and tuning uses only bots that passed.
- **Can go ahead now, on branches, without merging during a climb:**
  - design work on the untouched items in sections 3 and 4 (Wing Commander, neutral and scam units, Fury, Gleaner, Briars, Locusts' late game);
  - constructed-board simulations at turn thresholds, which the owner prefers to bot play for checking single cards;
  - design pitches to the owner.

## 7. Questions waiting on the owner

- **The reworks mock-up** (`docs/ideation-track-2/mockups/recruit_tribes.json`) still shows pre-tuning numbers. Update it, or leave it as the owner's approved mock-up?
- **Codex full access** was still refused `git checkout` for some workers. Sorting it out is the owner's job.

The morning pack's other questions are all answered: Mouse Health kept, the tuning merged, the pile-on jab merged, `dev` merged into `main`, TribeBot retired.

## 8. Work outside balance

- **Finished and on `main`:**
  - the pile-on jab (PR 197);
  - the Renown pill, reserve-limit marks and Charge/Supply pips (PRs 185, 186);
  - the drag-pitch fix (PR 194);
  - the gate clearing `XMODIFIERS` (PR 192);
  - the film fixtures in `tests/screens/feel/` (pigeon-reserve, mouse-kin, recruit-marks), with the films in R2 under `docs/workstreams/reworks/night-19-nov/media/`.
- **Half done:**
  - The build plan's end check never filmed a Hopper getting no Renown or the T6 Pikeman's +2. The tools/look screenshots it lists were never taken.
  - The owner chose not to play each tribe ("I don't need to play the tribes").

## 9. On the Optiplex

| Thing | Keep or delete |
|---|---|
| `/data/measure/baseline`, `arm-b`, `arm-c` (2.8 GB) and branches `measure/baseline`, `measure/arm-b`, `measure/arm-c` | Keep until the third run's readings replace them; they are the only league readings of pass 1. Then delete. |
| `/data/measure/reworks-scripts/` (compare.py, aa.py, run scripts; TribeBot-based) | Safe to delete. |
| `/data/balance-endcheck/` (night log, tuning proposals; copies are in the repo) | Safe to delete. |
| T3 worker worktrees `t3/tune-mouse-pigeon`, `t3/mouse-pigeon-round2-tuning`, `t3/tune-round3-mice`, `t3/tune-pigeon-round-four`, `t3/pile-on-jab-timing`, `t3/pile-on-jab-impact`, `t3/fix-recruit-pitch-timing` (`~/.t3/worktrees/Bramble/`, 108 MB each, no changes, all at 13f44dd9) | Safe to delete. |
| `design/pigeon-mouse-reworks` (remote) | Safe to delete. `engine/refight` was never merged: it is archive-tagged as `archive/branches/engine/refight` (316f9c76). |
| `/data/wt-handover` and branch `docs/balance-hand-over` | Delete after this PR merges. |
| `/data/night-19nov` (11 GB), `ghost/*`, `/home/alex/league/*`, `/data/cargo-target/orch` | The ghost orchestrator's. Not mine to judge. |

## 10. Memory the next session needs

- **Strong bots only:** balance uses only league bots that passed the stopping test. TribeBot plays no match; it only drives the engine check. Label any other reading as interim.
- **Design remarks are ideas, not rules:** read an owner design or flavour remark by its reason, and change it when that reason lapses. UI/UX instructions are firm. Don't over-follow. Example: Mouse "no HP" was an archetype idea from the Ambush days.
- **Balance work proceeds without asking:** pick your own recommendations, label them proposals, merge balance PRs to `dev`, and bring the owner directions and results. Card changes on `dev` move the ghost rules fingerprint, so tell the ghost orchestrator first.
- **Generous first:** start overpowered and dial back.
- **Clickable links:** every "look at this" gets one.
- **Builds go by Taildrop:** `sudo -n tailscale file cp <zip> desktop-uvt85dj:`; it lands in the PC's Downloads.
- **Merging `dev` into `main` deletes `dev`:** restore it at `main` and retarget open PRs.
- **Codex workers are refused `git checkout` and merges,** even with full access at times. Keep git steps in Claude sessions.
- **Docs say what holds now:** edit them in place; no history caveats.

## 11. Owner notes written for this work

Each needs the owner's word on whether it still holds:
- [2026-11-19a](../../design/owner-notes/2026-11-19a-balance-reads-bot-preferences.md): balance reads what the bots prefer, not population results.
- [2026-11-19b](../../design/owner-notes/2026-11-19b-balance-pass-aims-and-method.md): the balance pass's aim, and every kind of adjustment weighed.
- [2026-11-19c](../../design/owner-notes/2026-11-19c-double-tap-nerfs.md): don't double-tap a nerf or a buff.
- [2026-11-20a](../../design/owner-notes/2026-11-20a-strong-bots-for-balance.md): strong bots for balance; TribeBot isn't a balance bot.

## 12. Warnings

- **Gate breaks on card changes:** any number change fails the gate until `docs/ideation-track-2/tribes/<tribe>/units.json` and the tests that pin numbers are updated, and `LIVE_REFERENCE` is regenerated. How is in the comment in `tests/core/test_async_session.gd`. Gate a card branch before building from it.
- **Coordinate with the ghost orchestrator:** a card change on `dev` forces it to re-cut its field (under an hour), and a change during a climb voids the climb.
- **Check for double-tapped buffs:** the tuning buffed 11 Mice at once, and some may lean on each other.
- **The tribe READMEs** in `docs/ideation-track-2/tribes/` hold the current numbers. The mock-up JSON doesn't.
- **Don't trust a balance reading that comes only from a fixed opponent board.** Check what the bots actually pick.
- **Other sessions use the main checkout** (`/home/alex/code/Bramble`). Work in your own worktree under `/data`.
