# Plan: the recommendations in the game (approved 25 Nov)

The owner, 25 Nov (dictated): "Okay, I want all the recommendations implemented into the game."

## What goes in

The recommended option of every filmed decision, as seen on the "Today against the picks" page (https://claude.ai/artifact/HYNTiF6L3QJ9zat7rqBH9y) and in the `recommended` fixture treatment:

| Topic | Recommended | Fixture source |
|---|---|---|
| Attack timing (wind-up, stop depth, strike curve, next lift, ordering) | `best`, with CB2 b and CB3/CB11 mild | `best_timeline.gd`, `best.gd` |
| Turning toward the target | Turn 95% of the path with the medium lean (0.85 / 0.94), Galaxy timing. Every attack. | `rotate.gd`, `tip.gdshader` |
| Thorns before the hit | CB4 hold: Thorns plays while the attacker is still raised; the strike runs unbroken | `best_timeline.gd` |
| Several deaths | CB8 c: speeding-up stagger (10/7/5/4/4 f, cap 30), each gain 15 f after its death | `best_timeline.gd` |
| A single death | CB13 c: the killing number stays; the card's light goes out and it sinks | `pilot_*.gd` |
| Stat gains | CB14 c: each +N flies from the dead card into the stat and adds up (recruit green pill as stand-in) | `buffs*.gd` |
| Damage to the player | CB12 b: the winner's portrait strikes, then Health counts down (turns, no lean) | `pilot_hero_damage.gd` |
| Late-fight speed-ups (CB16) | *Proposal:* ×1.5 from the 5th attack and up to 3 triggers at once (median late fight 30.7 s → 12.7 s); leave out the earlier rule 7 (saves 0.3 s) | `best_timeline.gd` FAST, GROUP |

Turn amount (CB15) and lean strength (CB17) are not picked; the game uses the picks page's values, kept as one set of constants so a later pick is a one-line change.

## What does not go in yet

These need new art and the owner's yes on a picture before they are built (the rule for new visual elements):
- the combo count look (A1 slanted on a backing),
- the Thorns vine (A Lash),
- the glass bolt for player damage (pilot A),
- the shatter death (pilot A).

The interim options above (portrait strike, light goes out) stand in for the last two until then.

## Where it goes

`src/` on `ideation/fight-animation`, then a Windows build sent to the owner's PC. Nothing goes to `dev` or `main` until the owner says so for that merge.

## Steps

Each step is one Opus builder on its own `review/fight-anim-game-*` branch. The steps run in order, because they all touch `src/screens/fight/`. The order comes from the plan review: turning reaches the owner first.

0. **Keep today's motion.** Copy the game's current `FightMotion` and replay into the fixture as `today`, so that `today`, `pilot` and `rotate` keep working after the port.
1. **1a, turning on today's motion,** then a Windows build so the owner can check the turning. `rotate_motion.gd` is already shaped like the game's code. Move `tip.gdshader` into `src/`.
2. **1b, the `best` attack timeline** (CB2 b, mild strike, CB4 hold):
   - Bring the frame scheduler into `src/`. It currently lives in `best_timeline.gd`, about 1,750 lines.
   - Drive it from game time, not drawn frames. The fixture adds one per drawn frame, which would play 2.4× fast on a 144 Hz screen.
   - Make Skip work with the scheduler.
   - Wire `Sound.fight_step` to the scheduler's events.
3. **Several deaths:** CB8 c.
4. **The owner's answers on the stand-ins:** CB13 c, CB14 c, CB12 b.
5. **The owner's answer on the late-fight speed-ups:** FAST and GROUP.
6. **Windows build** to the owner's PC.

## Gates for every step

- **Runtime:**
  - `scripts/check.sh`;
  - the bot soak;
  - film the real game on fight seed 22 with `tools/feel/film` and compare its per-frame log with the `recommended` fixture film: same contact, burst and death frames, within 1 frame;
  - the board at the end matches the rules core.
  - Each step has its own reference film (a fixture scenario with only that step's picks), since early steps can't match the full `recommended` film.
  - A test runs the fight at 30 and 144 frames a second and checks the same timing in seconds.
- **Scope review:** `scope-reviewer` on the step's commits, with the owner's words and this plan.
- **Disk report:** every brief asks for one.
- **No one has watched it move** until the owner plays the build. A yes on a film stays provisional until then.

## Sound

Sound cues stay tied to the events they belong to (contact, death, trigger), so they move with the new timing. No cue is re-timed by hand; each step lists any cue that now plays at a different moment.

## Afterwards

- The late-fight speed-ups, turn amount and lean strength stay open in `DECISIONS-pending.md` until the owner picks.

Reviewed by plan-interrogate (fresh agent, 25 Nov). Its fixes are in the steps and gates above. Its three questions for the owner: the lean default, the stand-ins, and the speed-ups.

## The owner's answers (25 Nov)

- **Lean:** the 4° in-plane tilt with the turn (CB17 "lean", `aim_lean`), no 3D tip, until the owner picks on the page. So step 1a needs no tip shader in `src/`.
- **Stand-ins:** yes, in the game build: CB13 c, CB12 b (portraits travel, as a stand-in) and CB14 c (the recruit green pill in fights). They are replaced by the shatter, the bolt and a designed marker once the owner approves pictures.
- **Late-fight speed-ups:** both, ×1.5 from the 5th attack and up to 3 triggers at once (median late fight 12.7 s).
