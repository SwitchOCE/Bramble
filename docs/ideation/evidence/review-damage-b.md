# Review: ideation/damage-b (plan step 1, damage arm B as default)

Fresh cloud scope review of `git diff origin/ideation/main...origin/ideation/damage-b` (cd0e4f1), 8 Nov 2026.

**Counts:** 1 cut, 3 ask, the rest fine.
**Moves the problem: partly.** On the 200-lobby bot data, B moves snowballing: losing-streak players go out at R13, not R10; comebacks rise from 22% to 30.5%; the first hero goes out at R12, not R9. It does not fix "last four drag or swing". Games end two rounds later (R19, not R17), and rounds where 3+ heroes go out at once rise from 37 to 54, most of them at R13–14. All of this is bot data, not human play.

## Cut (fix before merge)

1. **One idea, three names.** How-to-play says "enemy starting unit still standing", the linked term is "Starting survivor", and the recruit hint says "survivors". This breaks the wording guide's "One word per concept". Use "starting survivor" in the how-to-play body, for example: "Lose a fight: take the round's base damage, plus 1 per enemy starting survivor."

## Ask (orchestrator's call)

1. **No burst guard.** The plan says "add no burst guard unless bursts persist". For 3+ knockouts they do: 54 against 37 (+46%), or 1.39% against 1.11% of lobby-rounds. The worker's reason, "per the approved implementation scope", misreads a conditional as a ban. The call is defensible on these grounds: 2+ rounds are flat (279 against 275); bursts that start with 5 or fewer alive are fewer (86 against 97); and 43 of B's 54 3+ rounds come at R13–14, where the base steps 7→9→11, mostly from 6–8 alive. Those wipes cut the field to the last four; they don't swing the last four itself. Arm D had 32. Make the call explicitly and log it in DECISIONS, for example: defer to playtest round 6's damage-and-length lens, and revisit the R12–R14 steps if humans report sudden wipes.
2. **The schedule isn't pinned by a test.** I changed R10's base from 5 to 6 and the full suite still passed (1,410 of 1,410); tests check only R1 and R14. Add one assert of the whole array.
3. **Glossary slips state what's implied.** "golden counts once" (Starting survivor) and "with no survivor damage" (Last Blow) are implied, and the owner said "If it's implied, let it be implied." The Round base slip spells out 14 numbers plus "then 13". It's accurate, but the rulebook could carry it. Trim if the wording pass agrees.

## Fine

- **Arm B is exactly the default.** `V05_BASE_DAMAGE = [0,0,0,1,1,2,2,3,4,5,7,9,11,13]`, and `get_int_at` clamps, so 13 repeats. Health is 40. `round_toll` is off in v05 and `_round_toll()` also guards it. The cap is 0 in both `Combat._finish` and `_damage_cap`. Ties set winner −1, so base and performance are both 0. `full_game("legacy")` keeps the old rule, and the bare `defaults()` are unchanged.
- **Starting survivors.** uids are recorded after `CombatSetup.apply`, before Start of Combat. A unit counts only if it is alive and on its starting side. That excludes summons and stolen units and includes returns. Starting Eggs now count 1, a deliberate change that the rulebook (10.1.4a) and engine.md document.
- **Last Stand: unchanged.** `_last_stand_active` is still `<= 4`. Mutating it to `<= 5` fails `test_last_stand_does_not_fire_with_five_alive_or_when_disabled`, so the test guards it.
- **Last Blow.** Who wins is decided exactly as before. The damage changes from `max(4, tier)` to the round base, which is 0 on R1–3. That matches the pre-registered "all arms retain Last Stand/Last Blow" and rulebook 10.1.4a. Note it for players: a Last Blow win on R1–3 deals nothing.
- **Burst counts reproduce.** I re-ran them from the archived `baseline.*` and `B.*` jsonl: baseline 275 / 37 (2 out ×238, 3 ×36, 4 ×1, over 3,321 rounds); B 279 / 54 (225 / 51 / 3, over 3,879). These match the report. Each game counts once per round, which is the right unit.
- **Combat log and hint.** The log reads "N base + M starting survivors = T." The hint "Base N + survivors" replaces "then fight <name>", but legacy already replaced it with "Toll N", so nothing is lost.
- **Bot plumbing.** Passing `round_number` into `Problem` and board search is needed so that layout search sees B's damage.
- **Comment trims in `combat.gd`.** These keep the file at the 1,000-line lint limit. The dropped Whirligig comment is duplicated in `combat_moves.gd:129`.
- **Supporting changes.** The `damage-v05/` evidence, sim scripts and `build_release_bench.py --driver` come from merging `ideation/damage`, as the plan asks. The bench file also re-wraps three lines, which is minor churn.
- **Superseded entries.** The DECISIONS and LOG entries that call D the opt-in arm are superseded by the new B entry, and are kept as history.

## What I ran, what I didn't

- Ran the full GUT suite on damage-b: 1,410 of 1,410 pass.
- Ran two mutations: a schedule change (not caught) and a Last Stand threshold change (caught).
- Re-counted the bursts from the raw data, with arm D for comparison.
- Didn't run `check.sh`, the soak, the UI screens at phone size, or new lobbies.
