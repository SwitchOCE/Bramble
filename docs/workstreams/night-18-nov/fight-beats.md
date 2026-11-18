# Fight beats, brief 10

> **Timing rule replaced, 18 Nov.** This run kept every replay hold and the whole fight's length unchanged, as brief 10 then required. The owner has since lifted that rule: see [the owner's rule on fight timing and grouping](../../design/owner-notes/2026-11-18b-fight-timing-and-grouping.md). Read the timing constraints below as history, not as rules.

The baseline was recorded with `tools/feel/film` before the running fight's animations were
changed: `media/fight/before.mp4`, 816 frames at 60 fps, 1920 × 1080. Media paths here are
in Cloudflare R2 under `docs/workstreams/night-18-nov/`. The reproducible scenario
is `tests/screens/feel/fight-whole.json`: neutral test fight 0, seeds 7/11, normal speed. It has
seven attacks, shield prevention, a diagonal attack, a multi-target hit, deaths, a summon and
a return. These are fixture units with borrowed art, not a balance proposal.
The production baseline is commit `e1715630e49dd7df07d1b1845929e0c634a85949`; the film fixture
only adds reporting around the existing deterministic stand-in fight.

Every `fight-*.mp4` listed in `docs/design/reference-clips/README.md` was inspected as timestamped
overview frames, then as cropped **10 fps attack strips**. The strips and copied references are
in `media/fight/frames/` and `media/fight/references/`. Seconds below are **within the
cut clip**, not the original YouTube video. Sampling at 10 fps gives roughly 0.1 s precision;
it does not establish the reference game's internal animation timings.

## What the references do that our baseline does not

| Beat | Reference evidence (clip and seconds) | Our baseline, like for like | Rework |
|---|---|---|---|
| Wind-up | `fight-galaxy-rowanribbit-1`, 2.4–2.7: the upper-left card lifts, grows and leans away before diving. `fight-galaxy-rowanribbit-3`, 3.1–3.3: the lower-left attacker tips out of formation first. `fight-mtga-quietplayroom-1`, 6.0–6.3: the attacking card lifts/tilts before crossing to the blocker. | `before.mp4`, 0.7–0.9 and 2.0–2.1: the attacker slides away immediately, upright, with no preparation pose. | Brief pullback, lift and lean, then launch. The attacker is identifiable before it crosses the board. |
| Travel | `fight-bg-lonelylongplays-1`, 1.1–1.3: upper minion tilts and meets the lower minion. `fight-galaxy-rowanribbit-1`, 2.7–2.9: a fast diagonal move arrives at the selected card. `fight-hs-mckoythebrave-2`, 0.8–0.9: the lower-left minion crosses directly into its target. `fight-mtga-quietplayroom-1`, 6.3–6.5: the card covers the last part of the gap quickly. | `before.mp4`, 0.8–1.0: the attacker eases out towards a transom-relative point; it appears to hover short of contact. At 3.1–3.3 the diagonal attack only partly follows the target's x coordinate. | Accelerating travel to a contact point derived from the actual target in either row, with slight card overlap. |
| Impact | `fight-bg-lonelylongplays-1`, 1.3–1.4: a bright contact flash precedes the two damage stars; the shielded side shows zero. `fight-bg-lonelylongplays-3`, 1.0–1.2: a bright local burst becomes dust and damage. `fight-lor-june-1`, 0.6–0.9: cards clash across an orange flare, then separate. `fight-mtga-quietplayroom-1`, 6.5–6.7: a local white/blue flash marks the clash. | `before.mp4`, 1.3 and 2.2: damage stars appear at full size; the defender does not react to the collision. Health already pops, but that alone is a small cue. | Short directional recoil and warm light on the struck card; blocked hits use a smaller recoil and cool light. The existing zero/destroy meanings are retained. |
| Recoil | `fight-bg-lonelylongplays-1`, 1.4–1.6: both minions regain their places beneath the stars. `fight-galaxy-rowanribbit-1`, 3.0–3.3: surviving attacker straightens and returns, while the loser takes a different path. `fight-lor-june-1`, 0.9–1.2: the attacker retreats from the flare. | `before.mp4`, 2.3–2.7: attacker is parked in the attack pose for the whole damage hold. Its eventual return is an ordinary slide. | Hold contact for two frames, then return during the existing damage hold; the victim rocks back and settles. Damage follows its recipient upright; later triggers must not relaunch the same attack. |
| Damage number | `fight-bg-lonelylongplays-1`, 1.4–2.2: outlined stars stay readable after the minions return. `fight-hs-mckoythebrave-2`, 1.0–1.5: both damage stars remain at their recipients while the card returns. `fight-galaxy-rowanribbit-3`, 3.5–3.9: 1076 and 146 remain legible through the trade. `fight-lor-june-1`, 1.0–1.5: health/damage feedback remains after contact; it uses in-card feedback rather than BG's stars. | `before.mp4`, 2.2–2.7: the burst is static and vanishes with the next state. Its attacker's position depends on the old lunge pose. | Pop the lead/glass burst, settle it for reading, then rise/fade a little. Follow the recipient's current pose while keeping text upright, including for later effects after the attacker has returned. No magnitude-based extra delay. |
| Death | `fight-galaxy-rowanribbit-1`, 3.1–3.5: the knocked-out lower card spins down/out as its attacker returns. `fight-bg-lonelylongplays-3`, 1.2–1.6, and `fight-bg-lonelylongplays-4`, 0.2–0.8: dying bodies break into dust/fragments. `fight-lor-june-1`, 1.0–2.0: a crack-like light precedes the blocker's disappearance. `fight-mtga-quietplayroom-1`, 6.8–7.3: the blocker collapses into a local blue dissolution. | `before.mp4`, 2.8–2.9: the defeated upper-left card simply fades upright in place. It resembles an ordinary redraw/disappearance. | A short outward knock, tip and shrink before fading: an explicit removal motion, distinct from the returning survivor. It clears inside the existing death hold. |

## The other reference windows inspected

These supplement the isolated attacks above; they are not permission to change event grouping.

| Clip | Seconds | Observation and scope decision |
|---|---|---|
| `fight-bg-lonelylongplays-2` | 0.0–3.0; 4.0–4.5; 5.4–6.3 | Board reveal, row-wide purple effect, then bright impact/large stars on the first trade. Learn the local collision/readable-star contrast; board introductions and row-effect grouping are left alone. |
| `fight-bg-lonelylongplays-3` | 4.3–5.5; 8.0–9.5 | Broad fire effect and rapid large-number trades. Several stars can coexist. No new culling/grouping rule is introduced here. |
| `fight-bg-lonelylongplays-4` | 3.5–4.2; 6.0–8.5 | Last enemy disappears; winner then hits the hero. Our result still uses its existing banner/portrait damage; a new hero attack sequence would add scope and possibly time. |
| `fight-galaxy-rowanribbit-2` | 0.5–2.0; 4.0–4.8; 6.5–9.5 | Lift/diagonal lunge, two readable stars, loser kicked out; arrivals refill gaps and fights continue quickly. Keep our existing summon and return order. |
| `fight-galaxy-rowanribbit-3` | 4.0–5.5; 7.0–9.0 | The same motion vocabulary handles large numbers and sparse final boards. Gaps stay visually trackable. Bramble's fixed slots must stay empty (rulebook 8.3.4), regardless of other games' gap-closing. |
| `fight-hs-mckoythebrave-1` | 1.6–2.2; 2.9–3.5 | Target arrow is player input; impact/star and return are useful. Automated Bramble attacks do not acquire a targeting UI. |
| `fight-hs-mckoythebrave-2` | 0.0–0.8; 1.0–1.5; 2.5–4.5 | Purple effect/heal feedback differs from physical attacks. Only the attack's local impact, number and recovery are borrowed; spell/effect grouping is unchanged. |
| `fight-mtga-quietplayroom-1` | 0.0–5.8; 7.4–8.0 | Planning/block assignment dominates the cut; the useful attack is at 6 s. Hero damage follows the clash. No extra blocking-choice or hero-damage pause is added. |
| `fight-lor-june-1` | 0.0–0.5; 1.6–2.5 | Brief poised lane, then loser removal and survivor returning. Bramble retains its own fixed-board layout. |

## Timing ceiling measured before changes

`before.report.json` records **12.23 s** of scheduled holds, **11.1667 s** to the result signal and
**12.6833 s** to playback finished at 60 Hz. The film includes scenario setup/tail and is
**13.6 s**; that is not the fight duration. Per attack, the existing attack pose has a **0.22 s**
hold, damage a **0.55 s** hold, death a **0.30 s** hold and an optional home step a **0.14 s** hold.
Triggers/changes can add their existing holds between these; none are regrouped or removed.
The baseline's pure slide tween was 0.16 s; the new preparation plus travel uses 0.20 s of the
same 0.22 s attack step. The per-attack replay interval does not grow.

The baseline's attack-step onsets (observed on the fixture's process clock) are 0.7167, 1.9833,
3.1000, 4.5833, 5.7000, 8.5833 and 10.0667 s. Their onset-to-next-onset intervals are 1.2667,
1.1167, 1.4833, 1.1167, 2.8833 and 1.4833 s; the last reaches the result step at 11.1833 s
(1.1167 s). The longer interval contains the fixture's existing trigger/destroy/change sequence.
These intervals, every transition, and the whole-fight duration must match the after film.

The rework's wind-up and travel share 0.20 s, recovery takes at most 0.2334 s, death 0.25 s,
and the burst 0.5434 s. Motion constants are all in
`src/screens/fight/fight_motion.gd`; replay holds are not edited.

## Review films and readability

The reworked whole fight is `media/fight/after.mp4`: **816 frames at 60 fps**, 1920 × 1080.
Its report is identical to the baseline's, including **all 30 transition times**, seven attacks,
11.1667 s to result and 12.6833 s to playback finished. Both report `core_matches: true`.
`media/fight/timing-comparison.json` records that comparison alongside both reports.

The readability improvement is a visible chain: identify attacker → follow it to target → see both
recipients react and read damage → distinguish returning survivor from departing loser.
In the before/after frames, 2.0–2.7 s shows the former parked attack replaced by wind-up, contact
and recovery while the numbers remain readable; 2.8–3.0 s shows the loser's distinct exit.
Later trigger/effect steps still have the old pauses: grouping is explicitly tomorrow's work.
At 7.7–8.1 s the later damage now labels the returned enemy card itself; the fixed-position
candidate left that number at the old collision point. This is why the final burst follows
its recipient upright instead of remaining at a screen coordinate.

Review films, all under `media/fight/`:

- `before-after.mp4`: the same whole fight, cropped to its boards, at original speed.
- `vs-fight-<clip-name>.mp4`: the final whole fight next to **each of the eleven references**
  (for example `vs-fight-galaxy-rowanribbit-1.mp4` and `vs-fight-bg-lonelylongplays-1.mp4`).
  Both panels have clocks; references play at their original speed, then hold their last frame.
- `windup-candidates.mp4`: four-frame preparation on the left, six on the right, same twelve-frame
  attack budget. These use the earlier fixed-burst capture, isolating the wind-up choice.
- `burst-follow-candidates.mp4`: fixed-position damage on the left, recipient-following damage
  on the right. `candidate-fixed-bursts.mp4` retains the first complete motion candidate.
- `after.mp4` / `before.mp4`: the full 1920 × 1080 captures, including the entire screen.

No automated assertion establishes human readability, real GPU frame pacing, or the owner's
preference; the 60 fps films are the review material for that judgement.

Final verification: `./scripts/check.sh` passed every step (tools, versions, shell, Python,
format, lint, import, compile, tests, feel and soak). All **727 tests** passed; the seven new
motion tests cover contact, recovery/later damage, upright following numbers, death/skip/restart,
redraw during wind-up, prevention and the duration ceiling. Compilation loaded 362 files with
zero failures; the soak reported zero violations. `media-manifest.json` validates all 18 review
films, including all eleven reference comparisons, their dimensions, 60 fps and frame counts.

To rerun the chosen whole fight (from the worktree root):

```bash
XDG_CONFIG_HOME=/tmp/n18-fight-config XDG_DATA_HOME=/tmp/n18-fight-data \
XDG_CACHE_HOME=/tmp/n18-fight-cache FEEL_TMP=/tmp/n18-fight-film LP_NUM_THREADS=2 \
tools/feel/film tests/screens/feel/fight-whole.json \
  media/fight/after.mp4
```

Use `tests/screens/feel/fight-windup-long.json` and a different output name for the alternate
wind-up. Each film's adjacent `.report.json` gives the frame-clock transitions, result/finish
times and final-board agreement with the core; the whole-fight scenario must report a finished
fight and `core_matches: true`. The short candidate ends before the fight does on purpose.
