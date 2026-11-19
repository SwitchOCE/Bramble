# Plan interrogation: the tribe process plan (19 Nov 2026)

A fresh agent that did not write [plan.md](plan.md) followed `~/.claude/skills/plan-interrogate/SKILL.md` on it, given the owner's words of 19 Nov. Its result, verbatim. One correction it made (TribeBot picks with `% TRIBES.len()`, not a literal `% 5`) has been applied to the plan; nothing else in the plan was changed.

---

Claims checked against the code at 54c9351d, and they hold: red, blue and TribeBot all hard-code `[&str; 5]` (14 sites across `tools/league`); `blue_tribe_pref` defaults to `[-6,0,0,6,0]`; `test_unit_art.gd:72` asserts "five tribes ship"; `lobby_tribes` exists in both engines but the harness doesn't use it; the registry takes bare names only, so `red-lean-x` can't be passed to `league match` today; blue still names `adjutant` and `brigadier`; `cards.py` already computes buy rate when buyable.

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| §2 cost table, §3 bot survey | Indirectly: shows what blocks the process | agent | keep (as background) | Accurate; it is what shows P1 is needed |
| Standard A as A1 (main tribe of final board, 95% interval) | Yes: the owner's "under five percent" | measure agent; threshold owner | ask | Already computed with intervals |
| Standard B as B2+S2, written exceptions | Yes: the owner's "a third as much" | agent | ask | S2 keeps B from repeating A; fits "parts that aren't being used" |
| E1 forced-tribe probe | Yes: tests "near equilibrium at a high skill level" | assurance + agent | keep | The only check of whether a low share is the bots' fault or the design's |
| E2 no gain left | Partly | agent | defer | Costs the most CPU; use E1 and E3 first, add E2 if they disagree |
| E3 the two bots agree | Yes | agent | keep | Free: `agree.py`, `tribes.py` |
| P1 bots read the tribe list | Yes: without it a sixth tribe shows 0% because the bots can't see it | agent | keep | Land it before the third-run teams own the bot code |
| P2 lobby rotation | Only if lobbies are 5 of 6 | agent | ask | Rulebook 5.2.5 is a game decision, not a measuring one |
| P3 art test counts folders | Needed to build a sixth tribe | agent | shrink | One line; fold into stage 4 of the first tribe |
| P4 probe bots in the registry | Needed for E1 | agent | keep | `league match` takes bare names only |
| P5 `tribe_standards.py` | Yes: gives the verdict | agent | keep, do first | No port needed; provable now on arm-b |
| P6 a separate baseline run | Partly | assurance | shrink | The ghost plan already makes the balance sign-off measurement a precondition of the third run; run P5 on that data |
| "Bots read the tribe list" as a third-run rule | No, if P1 lands first | agent | cut | A note to the teams is enough |
| Stage 1 prompt | Yes | owner | keep | |
| Stage 2: 3–4 designers, one refinement pass | Yes | owner | keep | |
| Stage 2 extras: two variations each, power numbers, bot-play notes | Partly | agent | shrink | Two variations per designer doubles review; the owner's variation comes from different agents. Keep the bot-play note |
| Stage 2 mixing Opus and Codex | Partly | agent | keep | Cheap |
| Stage 3 reviewer ranks | Yes | owner | keep | |
| Stage 3b owner sees ranking before build | Not required by the owner's words | assurance | ask | One stop; saves about a day on a rejected design |
| Stage 4 built in GDScript and Rust | Yes | agent | ask | Safest, but a port every mechanic round |
| Stage 5 bot coach | Yes: "the bots are refined to adjust" | owner | keep | |
| Stages 6–7 test and redesign | Yes | owner | keep | |
| Up to 3 rounds, early exit at "halfway" | Yes | agent | ask | The halfway exit is the agent's own idea |
| Stage 8 option two | Yes | owner | keep | |
| `tribe-pipeline` skill + `bramble-design` sections | Yes: it is the "process" | agent | keep, shrink | Draft before the first tribe; finish from what the first run did |
| `tribe_test.sh` wrapper | No | agent | defer | Wrap after the second tribe |
| §8 process times | No | agent | keep as estimates | |

**Fixed after step:** in the plan, only after the first new tribe passes stage 7, the last step, queued behind the rework ports, Pigeon S5, the balance sign-off and the third run's engine work (the plan says so in §9). Reordered, still the last step, but the standards check exists after step 2 below, and the owner sees stages 1–3 days earlier, without waiting on the third run.

**Smallest plan:**
1. The owner decides decisions 1, 2, 6, 7 and the stage 3b stop.
2. P5 proved on arm-b, with E1 and E3 in it; it must report Badger and Briar failing Standard A.
3. P1 and P4 (P2 if lobbies are 5 of 6), before the third-run teams own the bots.
4. Stages 1–3 for the first new tribe; the owner sees the ranking. Documents only, in parallel with the third run.
5. Once Rust is level and the balance pass is signed off, P5 on the sign-off data: the baseline.
6. Stages 4–8 for that tribe, P3 folded into stage 4.
7. Finish the `tribe-pipeline` skill from what happened.

**Deferred:** E2 until E1 and E3 disagree; `tribe_test.sh` until the second tribe; spells in Standard B until the owner asks; P2 if every tribe is in every lobby.

**Checkpoints:** after step 2 (today's verdicts; do the measures read as the owner meant?); after step 4 (the ranking page); after the first stage 6 verdict (does it match how the tribe feels?); after the first pass or move to option two (is this the process the owner described?).

**Open questions:**
1. What "played" and "used" mean: A1? B2+S2? "Pretty much" as written exceptions?
2. Lobbies 5 of 6 by rotation, or every tribe in every lobby?
3. Is a candidate built in both engines before it is tested?
4. The redesign round limit, and is the halfway early exit wanted?
5. Does the owner see the ranking before anything is built?
6. Do the standards apply to today's tribes? If yes, Badger (0.1%) could be the first run of the redesign loop (stages 5–7), testing the loop's back half before a new tribe exists.
