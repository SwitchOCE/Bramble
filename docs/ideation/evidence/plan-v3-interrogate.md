# Plan v3 interrogation

Fresh agent following plan-interrogate, 9 Nov 2026. Saved by the orchestrator.

**Verdict: approve with changes.** The direction is right and the evidence holds. My own recount of the lever-build CSVs matches the plan: median final board 141–148, the winner at 5× the runner-up in 26–42% of lobbies, and the median winner still finishing at R19. Make these changes before approving:
1. **Make the gate able to fail on the owner's problem.**
   - Give the designed setups predeclared bars, and say they outrank the line lobbies when the two disagree (09d).
   - Fix the two bars that already pass on today's flat pool: concentration and tier-up arrival.
2. **Decide spells and hero powers at scale.** The scaling switch exists but is off by default, so the checkpoint build would give flat rewards.
3. **Settle how strong-field mode survives about 7 content commits** before it merges. Its content check fails every field test after each content change.
4. **Re-run the line-strength gate on the full pool** before reading the band.
5. **Make the wave 1 probe able to fail:** add a control game on an old tribe, and check each named moment against the game log.
6. Smaller fixes: the harness merge needs a follow-up review of the 45 commits since its last review; run step 4 locally; move the Done means 2 rewrite to step 6; make the top-1% bar report-only; give preset B its own band; play the A/B checkpoint blind; re-point the references to checkpoint 2.

---

## Brief

- **Problem, in the owner's words:**
  - "our power budgeting across the board is very, very much too low"; the stat scale is too low and too spread out; concentration matters (09a).
  - "test it and see if it creates a good game … nice flow … jumps in power level make the player actually feel stronger … Rewards give the player power, always"; tribes in the "same order of magnitude"; fun beats balance (09c).
  - Constructed setups at turn thresholds outweigh bot play; snowballs must not happen in almost every game; the top 1% doesn't fail work; the distribution of stats beats the total (09d).
  - "something really high quality that I can playtest" (06a).
- **Who it's for:** the owner (a top-200 Battlegrounds player whose time is scarce), then agent playtesters.
- **Who decides:** on `ideation/*` the orchestrator decides and logs the call. Every v3 item below is agent-proposed (four critics plus the orchestrator's synthesis), unless it is marked with an owner note.

## Inventory and verdicts

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| 1a Merge harness | Yes: every 9d measurement runs on it | Agent (v2) | **keep, with a follow-up review** | 45 commits sit on top of the reviewed `9af89c2`, including an unreviewed designed-setup driver (`6146fa1`, `1206ae0`, `fbeb2a8`). "Once its cuts are fixed" isn't enough: the cuts are already fixed (`36e2920`), and the new code isn't reviewed. |
| 1b Merge wave 1 | Yes: the only built content near the target curve | Agent (critics) | keep | It has two clear reviews and is behind `pass3_content` (default false), so merging changes nothing for players. |
| 1c Merge strong-field | Yes: "how far can I get" (06a) and the ghost question (09a) | Agent | **keep; settle a question first** | `field_library.gd` checks a hash of every content JSON. The strong-field review's ask 10 says any content edit breaks every field test until someone recaptures. v3 recaptures only at step 4, after about 7 content commits (wave 1, pool rules, four tribes, neutrals). As written, each commit either fails the gate or carries a Godot recapture (the shipped library is 48 MB). Smallest fix: build the tests' manifest from current content, recapture the shipped library once at step 4, and keep strong-field mode out of builds until then. |
| 2a Pool-rules commit | Yes: Bog, Hunters and Oozes depend on it | Agent (cross-tribe §9) | **shrink** | Wave 1 already has the Start of Combat order and see-through Bellies (wave 1 review, K5) and `pass3_loop_guards`. What's left is the permanent-gain queue and any loop guards wave 1 lacks. Check before briefing. |
| 2b W2a (Bog, Hunters) and W2b (Oozes, Hedgerow, neutrals) | Yes: "across the board", "a lot of the design needs to change" (09a) | Agent | **keep; add an integration gate** | Both branches touch bots, `rates.json`, the registry, the rulebook and tests. Rebase W2b onto W2a, then run one gate on the merged tree (the delivery critic's risk 3; not in v3). |
| 2c One commit per tribe, with its line JSON and Hard-bot fixes | Yes (the Fairy lesson) | Agent | keep | |
| 2d Neutrals: keep 9, change 4, add 2, retire 38 bodies | Yes: dead flat text and filler flatten shops | Agent (cross-tribe §8) | keep | |
| 2e Presets A (~500 at R12) and B (~900) | Yes: "test it … 50/50 may be too small" | **Owner (09c)** asked for the test; the values are agent-set | **keep; add B's band and a source** | A is the size the owner doubted (strong board ≈ 50/50 a unit); B is the test of the doubt (carry ≈ 150/150 mid-game, as in 09a). Say so. A's band (300–900) reaches B's target, so B needs its own band (about 700–1,800). Name who writes B's raised values for the four tribes: a paper workflow from the pass 3 models, run during wave 2. |
| **2f (missing) Spells and hero powers at scale** | Yes: "Rewards give the player power, always"; "across the board" | Cross-tribe §8 (not in v3) | **add, smallest version** | `scale_hero_spell_stats` is false by default (`game_config.gd`). Hero powers are flat (Brother Bracken: up to +5/+5). Cross-tribe §8 says the flat stat spells need the scaling, and that Harvest Supper's +3/+3 ceiling is "dead late". Turn the switch on in both presets, lift the ceiling, and include both in the soak and the band. Also state the checkpoint config: pass 3 on, caps off, loop guards on, scaling on, the chosen damage table. |
| 3a Wave 1 fun probe | Yes: feel and progression (09c) | Agent (3 of 4 critics) | **keep; make it able to fail** | Agent testers asked for "a moment they felt stronger" nearly always name one, so a gate of "fewer than 2 of 3" barely bites. Give each tester one old-tribe game as a control. Check each named moment against the game log (the board before and after). Name the opponent: Hard, because the field library is stale after the wave 1 merge. Read no win rates. |
| 3b Designed setups | Yes: the owner's main method (09d) and concentration (09a) | **Owner (09d)** method; the boards are agent-built | **keep; predeclare bars** | The first experiment (`designed-first-plan.json`) is frozen with no outcome bar. v3 also dropped the critics' accounting check: if Birds' or Fairies' typical board in the real engine is outside 0.5–2× its paper figure at R12, fix the accounting in the wave 2 briefs before their dial values land. That check is the reason to run them on wave 1 now. |
| 3c Offline damage and Health shortlist | Yes: flow, and winners at R19 today | Agent (audit) | keep | Python only, from existing captures, confirmed at step 4. |
| 4a 150+ line lobbies per preset, sharded to the cloud | Yes | Agent | **keep; run locally; gate the lines first** | The harness was only ever run locally, and its cloud timings are "planning estimates, not cloud measurements". Once wave 2 merges, both local Godot slots are free, at about 31 minutes per preset. Before reading the band, run the line-strength gate on the new lines: the tribal mixture lost to Hard on both lever builds (−0.52 and −0.58 places). |
| 4b Fields R6–16 | Yes | Agent | keep | |
| 4c Designed setups: Granny, the Whistlers, answers against carries | Yes | Agent (cross-tribe §10) | keep, with bars (see the band) | v2's per-tribe bar ("a common board with one answer can beat its carry") disappeared in v3. Restore it here. |
| 4d Splash audit | Yes (the Lollop check) | Agent | keep, as lobby output | It is the "no card on half the winning boards" bar; it isn't a separate task. |
| 4e Damage table confirmed | Yes | Agent | keep | |
| 4f 200-game soak | Yes: crash-free play; caps-off runs reached 10M stats | Agent | keep | |
| 4g Strong-field recapture from top-4 trajectories | Yes | Agent | keep, once, here | See 1c. |
| 4h Done means 2 rewritten onto the harness | No: nothing reads it before build 8 | Agent | **defer to step 6** | |
| 5 Checkpoint 1 | Yes: the first point where the owner can check | Agent; "the owner hears plainly" is from the global rules | **keep; small changes** | Testers play A and B blind, in counterbalanced order, and say which they prefer and why. The portal build carries both presets as a setting, with the agents' pick as the default, so the owner's ten minutes can confirm it. |
| 6 Step 4 as written | Yes (06a) | Agent | keep | Add the Done means 2 rewrite here. |
| Cut list (sweep, 8a, checkpoint 2, line-against-Hard placements) | — | Agent (all four critics) | **agree** | The lever-build CSVs back it. |

### The guardrail band

Today's figures come from the caps-off screen (`lever-sweep.md`, caps-both).

| Bar | Today | Verdict |
|---|---|---|
| Median growth ×1.3+ a round, R8–14 | about ×1.17 | keep: it measures the fix |
| A's R12 median 300–900 | 133 | keep; add B's band |
| 8–25% of boards at 2× the median, R10–14 | 2–8% | keep: it measures the fix |
| Top 1% at most 20× the median | 39× at R16 | **report only.** 09d: the top 1% doesn't fail work. Loops are the soak's job. |
| Biggest unit holds 25–45% | **25–27% already** | **fix.** It passes on the flat pool. Raise the floor to about 30% (Battlegrounds is about 33–35%), and carry the owner's concentration point with a designed bar: a carry with its holder (Shield, half damage or Cleave) against an even board of the same total at R12, with a share set before the run. The audit's figure today is 0–15%. |
| Tier-ups arrive at 1.0× the median unit | **1.25–1.67 already** on the harness metric (`metrics.py`: the new unit against the owner's median unit before the climb) | **fix.** The audit's 0.60–0.74 used another definition. Use one that fails today, or drop the bar. |
| R8 leader wins at most 35%; a below-median R8 board reaches the top 2 at least 12% | 18–27%; 11–13% | keep, as guards |
| Winner at 5× the runner-up in at most 10% | 0% (lever builds 26–42%) | keep; compare both boards at the same round (the critics' caveat) |
| Median winner finishes R14–16 | R19 | keep: it measures the fix |
| Each tribe's best line within 3× | — | keep. Name the rounds (pooled R10–16), so a late tribe like Bog doesn't read as weak, and cross-check with designed typical boards per tribe. |
| At least 15% of R10–14 field pairs uncertain | 16–18% | keep, as a guard |
| Strong-field rivals 0.7–1.5× the target; the play bars | — | keep |

Only growth, size, the tail share, game length and play can show the fix. The rest are guards, which is fine, but nothing that can fail measures concentration, the owner's central 09a point. The designed bar above covers it.

## When is the problem fixed?

- **Today:** at step 5, when the owner plays the full pass 3 pool on the portal. That is the last substantive step. He would check whether boards compound past R8, whether tier-ups and engines feel like jumps, whether a carry matters, and whether games end by R14–16.
- **No earlier honest point exists.** Wave 1 next to four flat tribes isn't the game, and the critics are right that it would waste his time.
- **Reordered:** still step 5, but reached sooner: step 4 runs locally, the Done means 2 rewrite moves out, and agent playtesters can start once the lobbies, recapture and soak are done, with the fields and designed setups running alongside. The owner's build waits for all of it.

## Smallest plan

1. Merge the harness (after a follow-up review of `9af89c2..HEAD`), then wave 1, then strong-field, with the content-check decision from 1c.
2. Pool rules (the gain queue, any missing loop guards, hero and spell scaling on), then W2a and W2b, one commit per tribe, then an integration gate. Meanwhile, a paper workflow writes B's dial values.
3. In parallel:
   - the wave 1 probe, with its control;
   - designed setups on wave 1, with the 0.5–2× accounting check;
   - the damage shortlist.
4. On the full pool, locally:
   - the line-strength gate;
   - 150 lobbies per preset;
   - the strong-field recapture;
   - the soak;
   - fields and designed setups against predeclared bars;
   - the damage table confirmed.
5. Checkpoint 1: blind A/B testers; a portal build with both presets; tell the owner plainly.
6. Step 4 as written, plus the Done means 2 rewrite.

## Deferred

- **Done means 2 rewrite:** at step 6, before build 8 sign-off.
- **Cloud sharding:** only if the local slots are busy at step 4.
- **8a as a diagnostic:** if both presets miss for unclear reasons (as v3 says).
- **The 7-digit phone check:** already done (`evidence/big-numbers`).

## Checkpoints

1. After the wave 1 probe, before any wave 2 merge: go or no-go.
2. After the wave 1 designed setups, before the wave 2 dial values land: the accounting check.
3. After step 4: read the band, and put in the status line whether the scale problem is fixed on paper.
4. Step 5: the owner plays. Say plainly whether it's fixed.

## Housekeeping (cheap; do it when logging v3)

- Re-point the decisions that cite checkpoint 2:
  - the Jack Daw permanent-against-fight-only comparison;
  - deleting the frozen pass 2 rollback tests "once wave 1 passes";
  - `pass3/README.md`, "What happens next".
- Log the 5× figure's caveat: the runner-up's board is measured at its own elimination round.
- The harness branch is still adding code. If it stays open beside W2a and W2b, that is three code branches against the two-branch rule. Log it, or fold the designed-setup code into the 1a merge.

## Open questions (the orchestrator's calls on this branch)

1. **Strong-field content check during wave 2:** tests build their manifest from current content and the shipped library is recaptured once (my recommendation), or recapture at each content merge.
2. **Hero and spell scaling:** switch it on in both presets (recommended), or leave rewards flat.
3. **B's size:** about 900 at R12 (the design size, which already covers 09a's 150/150 mid-game carry), or steeper.
