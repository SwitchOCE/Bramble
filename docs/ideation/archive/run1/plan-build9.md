# Plan: build 9, the build 8 that plan-to-done v3 planned (10 Nov 2026)

> **Shelved (10 Nov 2026), by the owner (note `2026-11-10j-shelve-build9-look-and-feel.md`):** "New direction: shelve build 9 and stop. … I'm starting a new phase that is only about look and feel: UI, UX, how the game looks and plays on screen. Nothing on balance or mechanics. A fresh orchestrator session will run it, from a plan I've approved. So the balance plan for build 9 (plan-build9.md) is shelved, and this run stops here."
>
> Where it stopped: steps 1–2 merged into ideation/main as ccdb79c6. Step 3 and A4 are on `ideation/b9-measure` with a WIP commit. Step 4 never started. Steps 6–7 never started. Resume points: `PARKED.md`.

*[Approved by the orchestrator on 10 Nov after a fresh plan interrogation (`evidence/plan-build9/interrogation.md`); its corrections are applied.]*

**The owner's words (note 10i):** "you can go back to the polishing and all the stuff that I asked you to stop, and you can continue on with your iteration stuff. Keep it smaller and keep it more bounded. Less fan-outs, less cloud utilization. Just mainly try to use the PC's full resources, but not go too much beyond that. Maybe a few cloud workers here and there." Then: "Get it to the spot where you would have gotten build 8 to if I hadn't intervened earlier."

**Target.** Build 8 as `plan-to-done.md` v3 §5 planned it. Of that list, build 8 already has the settled pool, B from realized boards, batch 2, the 15 portraits, the game logs, the recaptured library, and the memory budget (a field start adds +154 MB, under the 300 MB bar). Still missing:
- preset C from realized boards;
- A5's cuts at the outliers: the Ooze tail, plus the Fairy Ring line, which is short;
- A4's measurement;
- checkpoint 1's pick of the default preset;
- the preset setting in the game;
- **the strong field as the default opponents on the default preset.** Build 8 bundles and checks the library, but `settings.gd` still defaults to `"bots"`, and the export sets no `strong_field` feature (found by the interrogation).

It ships as **build 9**, because export numbers only go up. v3's later steps (round 6, batches 3–4, J1–J4) come after it, one at a time.

**How it runs.**
- At most three Codex workers at once, each in its own worktree. Godot goes through the two-slot wrapper.
- Sims and soaks run on this PC with `python3 tools/sim/sim_job.py local <config> <out> --jobs N`. The local runner takes 1–2 jobs, one per shared Godot slot. Step 3's first commit raises the slots to 3, with the 3 GB cap per run kept, so local runs use more of the 6 cores (the owner: "use the PC's full resources").
- Actions runs only the test gate, plus a sim only when a local run would take more than about two hours.
- Cloud workers: only checkpoint 1's three testers.
- No Workflows, and no Claude subagents running Godot.
- Each step gets one fresh review (Codex) and the test gate, and names at most two deciding criteria (09i). The numeric bars are agent choices, not the owner's. They decide the step, and the distributions are reported beside them (10f).
- **Budget for the whole plan:** about two days of wall clock. Cloud use is the test gate per merge, at most two Actions sims, three testers and one checker. Each failed check gets one repair round, then it's reported, not retried.

## Steps

| # | What | Who | Waits on | Decides |
|---|---|---|---|---|
| 1 | **The Ooze tail.** Resume `ideation/ooze-cut` from `PARKED.md`'s resume point, on the build 8 tree (Soup is already at a fifth). First, triage whether Mrs Mallow and Soak on Ooze boards, and the 1-billion unit ceiling, are each a rule doing what its text says or a hole. Then make one bounded change at the outlier, on the 32 confirmation seeds, locally. | content worker | nothing | 1. Ooze engine R12 p90 ≤ 10× its median <br>2. both Ooze R12 medians stay ≥ 675 <br>One change and one confirming run. A miss is reported. |
| 2 | **The Fairy Ring line.** Triage why it reads 480 at R12 (the role and journey checks), then make one bounded change, generous first (09h), on the same seeds, locally. | content worker (same as 1, run after it) | 1 | 1. Ring engine R12 median ≥ 675. The other lines' medians are reported. <br>One change and one confirming run. |
| 3 | **Preset C from realized boards.** First commit: three Godot slots, and `--jobs` 1–3. Then use run 1's four points per tribe (`evidence/a35-run1/results.json`) to solve a **provisional** t for 1,800 at R12 on frozen endpoints. No new arms. The estimate is labelled provisional, since the endpoints and shared scaling have changed since run 1. Oozes keep the probe's C, and Fairies and Oozes take steps 1–2's changes first. Then one local confirming run at C on the 32 seeds. A miss is reported, not refit. | measurement worker | 1–2 for Fairies and Oozes only | 1. every engine line's R12 median at C is 0.75–2× of 1,800 <br>2. growth ×1.3+ a round, R8–R14, same cohort |
| 4 | **The preset setting and the default opponents.** One Settings row: Normal (B) / Big (C). It's saved and shown at game over, using the existing settings, `core_port` preset resolution and game logs. Separate records per preset wait until something reads them. The strong field becomes the default opponents on the default preset: the settings default, plus the export feature. Bots stay on the other preset (v3 §1.6). PLAYTEST says what both do. | UI worker | nothing | 1. a fresh-settings new game uses the chosen preset, with the strong field on the default (tests through `core_port`) <br>2. the 4-game UI run is clean on both sizes |
| 5 | **A4, smaller.** 64 line lobbies each at the final B and C, run locally. Field fights at R10, R12 and R14 on both presets (DM2's first read). Reported per line: R6–R11 and R11–R15 medians, p10 and p90, the share alive, and the order-of-magnitude read at R14 and R15. Field fights: at most 40 per line per round. The report states A3.5's method and assumptions (C8). The designed setups and the damage table wait. | measurement worker | 1–3 | 1. growth ×1.3, R8–R14, same cohort, on both presets <br>2. none of v3's three extreme misses (a miss is triaged, not refit) |
| 6 | **Checkpoint 1.** Three reward-lens cloud testers play blind, `play.sh new --variant X\|Y`, one game per variant in assigned XY/YX order. A fresh reader checks each named moment against the game logs. Pick the default preset. Each tester gets at most 3 hours, and there's no repeat panel. **If the result is inconclusive,** B stays the default and the split is reported. | 3 cloud testers, then one checker | 5, plus throwaway B and C libraries from 5 | 1. felt progress at a log-checked moment <br>2. growth ×1.3 on the picked preset |
| 7 | **Export build 9.** Recapture the library on the picked default, then run the 200-game soak (locally), the 4-game UI run, the memory check and `build/export.sh 9`. PLAYTEST covers what changed since build 8. Then tell the owner plainly whether the scale problem is fixed. | measurement worker, then the orchestrator | 4, 6 | §5's checks, plus a fresh-settings launch of the export that starts on the picked preset against the strong field |

Steps 1→2, 3 and 4 run side by side, which is three workers. Step 5 waits for them. After build 9 comes v3's round 6 (A7), then batch 3, each with its own short plan.

**Stop rules.** After build 9 is exported, report and wait for the owner's play before the next plan.
- One fix per outlier, then one confirming run. A miss is recorded and triaged, not refit.
- A step whose run would take more than about four hours locally is cut down before it starts.
- If a worker hits a Codex usage limit, stop and tell the owner.
