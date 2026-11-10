# End of the ideation run (build 8, 10 Nov 2026)

You ended this run at build 8 (note 10g). This is the short report you asked for. How to thin the process for the next loop is a separate page: `PROCESS-PROPOSAL.md`.

## The game now

**Shape.** An 8-player lobby. You pick one of three heroes and play against seven bots, all at one strength. Each turn you buy from a shop with gold, hold up to ten cards in a fanned hand, tier up through six tiers, triple copies into golden ones, and set a 4–3 board: four in front, three behind. Fights then play out on their own. You start on 40 Health and lose the round's base damage plus one per enemy survivor. Last Stand saves each hero once in the final four. The UI test games ran 11 to 14 turns.

**Pool.** 111 units in the shop pool: six tribes of 16, plus 15 neutrals. There are also 29 spells and 9 heroes. Five of the six tribes appear in each lobby. Each tribe has its own idea:
- **Hedgerow folk:** Acorns and the Supper.
- **Fairies:** Rings on slots, and Rainbow bands.
- **Oozes:** Bellies, plus Stone Soup, which now gives away a fifth of its share.
- **Birds:** Fly South trips and Eggs.
- **Bog folk:** Mire, and Bitter locks.
- **Hunters:** Quarry and Pack.

**Bots.** 23 strategy lines, two to four per tribe plus three neutral ones. They play from realized boards, and a strong field of top-four boards backs the soak.

**Feel.** Numbers are big now, as you asked on 9 Nov. A typical tribe board is around 750–1,300 total Attack + Health at round 12, and it keeps growing fast after that. Shop and board tiles carry no words: tap a card for its rules. No human has played at this scale yet. Everything below comes from bots.

## The numbers per tribe

Each line's total Attack + Health at round 12 at the shipped values (preset B), from 32 lobbies. Each figure gives low / typical / high: the p10, median and p90. The earlier target was 900. You dropped it as a target on 10 Nov, so these are a record, not a pass or fail.

| Tribe | Main line at R12 | Its second line | Growth R8–R14, per round |
|---|---|---|---|
| Hedgerow | Supper 407 / **1,313** / 3,396 | Parish 930 | ×1.7 |
| Oozes | Engine 789 / **1,554** / 59,334 *(with Soup at a fifth)* | Tempo 993 | ×1.8 engine, ×1.4 tempo |
| Hunters | Open Season 446 / **790** / 1,963 | Pack 1,074 | ×1.7–2.0 |
| Birds | Homecoming 362 / **867** / 3,215 | Tempo 604 | ×1.6 |
| Bog folk | Court 628 / **742** / 1,371 | Swamp 840 | ×1.7 |
| Fairies | Ring 220 / **480** / 1,658 | Court 901 | ×1.6–1.8 |

All six are within a factor of about three of each other at their medians, so they are inside the "order of magnitude" you allowed (9 Nov). The Fairy Ring line is the short one. The Ooze engine's high end runs away.

## The weakest part, and what I'd fix first

**Weakest: late fights are decided by whose growth stacks fastest, not by the board you build.** From round 12 to round 15, typical boards grow between 2.4× and 22× depending on the line. The Ooze engine is the extreme case: one game in ten ends up around 40 times the typical board. That tail mostly comes from other tribes' cards landing on Ooze bodies. Hedgerow's Mrs Mallow ("End of Turn: triple your two smallest Hedgerow units' stats"), picked up by Ooze players, triples two bodies every turn. Bog's Soak banks stats it takes from an opponent. Both do what their text says, so they are designs, not bugs. When totals reach the tens of thousands, positioning, scouting and Mire matter less than whose multiplier ran longest.

**What I'd fix first, after you've played:** decide whether the late game should feel this steep. If it shouldn't, change it with one rule rather than cuts card by card. One option: cap how much one effect can multiply in a turn. Another: make "triple" effects add a fixed amount instead. Next, give the Fairy Ring line a stronger early piece, so a Ring board reaches the others by round 12. The resume point for the Ooze work is in `PARKED.md`.

**Bugs found in this last stretch (all fixed in build 8):**
- Finished games weren't actually being saved from the real game screen. The log writer existed but was never called.
- A fight could start from the wrong event.
- Three kinds of animation error where a card was removed mid-motion.
- The desktop card reader covered board slots.
- Big numbers overflowed while counting up.
- The automatic return after a fight cut off its last second.

## Tools worth keeping

- **Sim job** (`scripts/sim-run.sh <config> --base <sha>`): runs a set of bot lobbies on fixed seeds in the cloud and gives per-line numbers. Use it for "what does this change do to the numbers".
- **Soak** (the sim job with `"kind":"soak"`, 200 lobbies): full games that check the rules never break: no crashes, no illegal states. Run it before every build.
- **Game logs** (`user://games/`): every finished game saves its build and a replay that reproduces the same end state. Send them and an agent can replay exactly what you saw.
- **Cloud gate** (`scripts/cloud-gate.sh <sha> <label>`): the full test suite on GitHub in four shards, a few minutes per run. Nothing merges without a PASS.
- **UI run** (`tests/ui/full_ui_run.sh 2 1000`): a bot plays whole games through the real screens at PC and phone size, and flags layout problems and errors. It found most of build 8's bugs.
- **Export** (`build/export.sh <N> "<summary>"`): builds Windows, Linux and Android with every check, tags the build and points `latest` at it.
- **Field library** (`tools/sim/recapture_field.sh --strength top4`): strong bot boards for the soak and fight tests. Recapture it after any change to the numbers.
- **Codex workers** (`codex exec` in their own worktree): cheap and good at bounded fixes and reviews. One worker owns one branch.

## What was parked, and where

All of it is listed with tips in `PARKED.md`:
- **The Ooze tail cut,** on `ideation/ooze-cut`, with a resume point. Its Soup-at-a-fifth result did ship in build 8.
- **The Quilboar reference benchmark,** on `ideation/quilboar`. Three setups never ran.
- **A small portrait test,** on `ideation/portraits3`.
- **Declutter batch 2's full history,** on `ideation/declutter-b2`.
- **Not started:** the full 150-lobby measurement, preset C's own fit, round 6, the checkpoint-1 cloud testers, and declutter batches 3–4.
