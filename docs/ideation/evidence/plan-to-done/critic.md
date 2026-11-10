# Critique of the plan to done (10 Nov 2026)

I checked the plan against the repo at e88a204d and against the live worker branches: ideation/wave2b 21a65947, ideation/declutter d400831e and ideation/quilboar 4b44e66a.

## The five most important changes

### 1. The final verdict doesn't meet the /goal, or PLAN's own "reviewers can really play"

**The gap.**
- The /goal asks for reviewers who "each played the latest build".
- PLAN.md says how reviewers play: `tools/play/` commands, "and a scripted UI driver produces screenshots of the same game".
- The plan's reviewers instead play the source commit through `play.sh`, "with the build's screen pack". No stream builds that pack.
- `tests/ui/player_driver.gd` can't replay a `play.sh` save, so nobody sees their own game on screen. That also covers the tutorial and the "first-timer agent plays the tutorial, then one real game" gate (B4). A workflow agent can't run Godot, and no stream gives a cloud agent a way to play through the UI.
- The pass rule also contradicts DM7. Sharpened DM7 says "with their agreed items fixed". §1.5 says the passing round's agreed items that don't block "go on the owner's list and stay out of the build". So the plan can declare done with agreed items unfixed.

**The change.**
- Add a stream, medium size, Codex. It renders a `play.sh` save (or replays it in the UI) at 1688x780 and 1920x1080, from the build's exact source commit and the shipped field-library SHA. Reviewers then get screens of their own turns. The tutorial gate uses the same tool.
- Log one line on what "played the latest build" means: the same commit as the export, the same pack and library hashes, and default settings.
- Keep 2 full games per reviewer. The sharpened text says "full games", and dropping to 1 is an unlogged loosening.
- Define a pass as: 3 or more say "very good", and no item is raised by 2 or more reviewers (blocking or not). Anything agreed is fixed in the next build, and a fresh trio plays that build.

### 2. Nothing in the plan closes the scale gap, which is the problem that started the work (09a)

**The gap.**
- Targets are realized medians (DECISIONS 10 Nov: "B and C are re-based… the realized median of a committed line").
- Realized B at R12 is about 300–400 (PLAN status). The Oozes lines read 262 and 200 (DECISIONS "Wave 2b part 1").
- The plan goes A3 → A4 → checkpoint with no step that sets the dials from realized numbers.
- So checkpoint 1 plays "small against medium". A4's plain answer to the owner will be "not fixed", and the plan has no branch for that case.

**The change.**
- Add A3.5, after the pool settles and before A4 and the recapture. Set the B and C engine-rate dials from the realized gap, so committed lines reach about 900 and 1,800 at R12. This is generous first: the targets are already realized. Confirm on a short lobby shard.
- Decide now what happens if A4 still reads B far below 900: raise again, or play C as the default.

### 3. The DM2 rewrite goes against 09c, 09d and v3, and is measured too late

**The gap.**
- The deciding criterion is a bot-lobby balance band: at least 5 lines from 4 tribes at 6% or more, none above 25%. Designed setups are only "reported".
- v3 says the opposite. Designed setups "outrank line lobbies when the two disagree (09d)", and v2 says bot lobbies are "only a sanity line".
- 09d: "rely far more on empirical simulation data"; "I don't want you to force it".
- 09c: tribes only need "the same order of magnitude".
- A 6% floor read from bots would push Birds up, though the fun probe found bots understate skilled Birds by 2–3×.
- The spread is read only at J2, after round 6. Fairies Court is already at 31.6% (wave1-rebase.md).
- Early-round decisions are a known failure: pt4-b "rounds 1 to 5 rarely", playtest-3, and the fun probe's "early game is slow". Yet "real decisions most turns" is a deciding criterion, and no step targets it.

**The change.**
- **Deciding:**
  1. Pre-registered designed setups at turn thresholds: answers against carries, distribution against totals, and placement against the real opponent. Placing (a) and (b) is already one of these.
  2. Reviewers: a real decision on most turns, rounds 1–5 included, and 3 or more builds that felt different.
- **Sanity line:** the line-lobby spread, read at A4 from the 150+ lobbies already planned. Use v3's three extreme misses (order of magnitude; one line winning whatever the player chooses; runaway snowballs) as the "none dominant" evidence.
- Start an early-rounds triage now, on paper plus designed setups.

### 4. The file-ownership table is false against the repo

**Clashes that already exist.**
- **Wave 2b and the declutter:** wave2b edits `src/ui/widgets/card_view.gd`, `card_detail.gd` and `src/ui/screens/recruit_screen.gd`, the same three files the declutter edits. It also edits `recruit_view.gd`, `tests/ui/test_followup_tribes56.gd`, and the new `ooze_marks.gd` and `test_pass3_ooze_ui.gd`. So the Ooze marks are being built twice.
- **Wave 2b and S3:** wave2b also edits `tools/sim/line_brain.gd`, `committed_line_brain.gd`, `upset_combat.gd`, `tools/sim/lines/oozes.json` and `wave2b_lines.gd`. S3 "owns tools/sim/**".
- **Quilboar and wave 2b:** the Quilboar merge edits `bot_brain.gd`, `combat_unit.gd` and `content/schema/effects.json`, as wave2b does, and `export_presets.cfg`.
- **The faster suite:** it rewrites tests across `tests/core` and `tests/ui`, and adds a `game_config.gd` knob that wave2b also edits.

**Gaps in the table.**
- S9's `rules_hub*.gd` sits inside S2's `src/ui/**`.
- S9's `content/tutorial/**` and `content/rules/**` aren't in `include_filter`, which S3 owns, so they won't ship.
- Choosing a field library per preset is unowned. `field_library.gd` has one `BUNDLED_PATH`, and the preset line is in `core_port.gd`.
- S4 names `scripts/soak.sh`. The wrapper is `tools/checks/soak.sh`, beside `soak_plant.sh`, `soak_content.gd`, `soak_bot.gd` and per-tribe `soak_*_check.gd` files, and S1 adds those per-tribe checks.

**The change.**
- **Carve-outs:**
  - S1 owns `tools/sim/lines/**`, its tribe's audit entries and its `soak_<tribe>_check.gd`.
  - All marks belong to S2. w7 adds no UI after Oozes, and S2 re-faces `ooze_marks.gd`.
  - S3 adds S9's folders to `include_filter`.
  - S5b owns preset → library selection.
- **Merge order:** wave2b part 1 → declutter → Quilboar.

### 5. The strong-field library: wrong order, and unmeasured on Android

**The gap.**
- The library's manifest hashes gameplay fields in `content/units`, `pass3` and the other content folders. Any dial or card change invalidates it, and it then fails loudly.
- A5 cuts C back dial by dial after A4's recapture. So build 8 needs a fresh recapture, and A6 doesn't have one.
- Recapture after any later content fix is mandatory, not "if any dial moved".
- B and C need two libraries, but the loader has one path.
- S4's soak split needs the default preset (picked at A5) and a library (made at A4). Yet S4 must pass 200 games on today's tree before A4.
- Peak memory to load a library was about 1.15 GB RSS (`strong-field.md`). Making strong field the Android default with no memory number is a release risk. `strong-field.md` also still says "The normal bot lobby remains the default".

**The change.**
- Recapture B and C as the last step before every export, and record the SHA in the README.
- S4's soak takes preset and library arguments and skips field seats when there is no library.
- Measure the peak memory of a field start on the Linux export, and cap the library size (fewer trajectories) to a stated budget.
- Log the default-opponent call.

## Other changes

6. **§1.3's reason is partly wrong.** Gates moved to Actions, but the local cap of two Godot processes (14 GB, RAM upgrade pending) still covers targeted tests, sims, frame strips, UI runs and exports. DECISIONS 10 Nov counted about 5 worker turns lost to waits in 8 hours. Three Codex branches work only if S3's heavy runs go off the machine.
7. **The Claude budget.** CLOUD.md (7 Nov): the owner is "near my Claude budget".
   - The plan uses about 15 or more Claude cloud sessions: 3 code sessions, 3+ checkpoint testers, 5 in round 6, 3+ in round 7, possibly 3 in round 8, plus the tutorial first-timer, shards and the soak.
   - Send the 2,000-game soak and the lobby shards to a `workflow_dispatch` Actions job. Actions is free and parallel, and the sharding session can add the job, since only cloud sessions can push `ci.yml`. Keep Claude cloud for testers.
8. **Loosenings with no reason given.**
   - DM5's UI-run bar keeps only "10 reach turn 12". It drops turn 15, one win, 3 ghost fights, and tiers 5 and 6 reached (`tests/ui/full_ui_run.sh:9-10`). Those are late-game crash and layout coverage, not depth. Keep them, or log why.
   - "If S6 can't reach that, log a changed coverage bar" sets up an escape before the run. Cut it.
   - Each of these needs its reason logged in W-a: DM1's "no filler" demoted, DM4's flavours (08a) demoted, placing (a)/(b) demoted, and DM2's head-to-head dropped.
9. **Approved v2 step 4 items are missing.** v3 step 7 is "Step 4 as written: opponents…". Two of its items aren't in the plan:
   - "Bots buy an answer when the scout shows a carry". `src/core/bots` has no answer logic, and the strong field inherits that.
   - "Owner's games… logged in the snapshot format" from build 8, "our only strong-player anchor". The game writes no game log; only records and settings persist.

   Schedule both, or drop them with a logged reason.
10. **The triage rule.** Round 6's design complaints go straight to w7. The project's triage skill says to triage recurring playtest complaints before fixing them, but the plan triages only after two failed rounds. Triage round 6's agreed design items. 0 of 17 reports so far have said "very good".
11. **Build 8 for the owner.**
    - The owner would get batch-1-only declutter, against v3 step 3 ("lands before checkpoint 1") and 09e.
    - Batch 1 took about 6.5 hours from its first commit (03:43 to d400831e at 10:04, 10 Nov). That makes "7–9 worker-days" for track B look inflated, and the long-pole claim with it.
    - Keep the CLI testers unblocked, and hold the build 8 export for B2 (where the ~65 words at rest are) if it lands within a day of A5.
12. **Stale steps.** B1 steps 1–2 are done: main merged in at 55e0d8b0, the four fixes at 7b7a5fb7, and the reshoot at d400831e, with its gate branch pushed. wave2b merged main (a2f4295f) and has review fixes (21a65947). Quilboar merged main (92cbce1f). Refresh before logging.
13. **DM3's first deciding criterion grades the agents' own work.** `interesting-designs.md` is written by the agents. Have a fresh reviewer check it against the card library in `docs/research/battlegrounds/`.
14. **Smaller items for J2.**
    - Recount the pool on the build 9 tree: wave 2b adds 2 neutrals and may retire Pipistrelle.
    - Add a soak check that no unit without a set appears in a `full_game` lobby. §1.1 keeps all 38 on disk, and 13 have pool:true.
    - Run the 20 UI games at default settings, against the strong field.
    - Add the visual-tier re-score after batches 2 and 4 (spec §7) as a reported line.
15. **The portal.** The single `playtest` entry belongs to the prototype workstream. Ask the portal session for a per-workstream link rather than repointing someone else's guide.
16. **Main.** No step merges into main. But cloud sessions start on main with admin rights (CLOUD.md:23,37), and the plan multiplies them. After each cloud session ends, check that `origin/main` is still 156e8c11, and keep the "never push main, no PR" line in every brief.
