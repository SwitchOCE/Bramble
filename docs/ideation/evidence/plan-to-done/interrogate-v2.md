# Plan interrogation: "Plan to Done, v2" (10 Nov 2026)

Reviewer: a fresh agent that did not write the plan. I read `plan-v2.md`, `plan.md`, `critic.md`, the owner notes 06a and 09a–10a, PLAN.md, the newest DECISIONS entries, CLOUD.md, BOTS.md, `content/pass3/rates.json` on ideation/wave2b, the live branch tips, and the Quilboar lesson drafts (`bars.md`, `process.md`, `check/ck_captures.txt`). `quilboar-lessons/lessons.md` did not exist when I ran. W-f is the step that will use it. I made no changes and ran no Godot.

## Does this plan move the owner's problem?

**The goal.** The owner's words: "every "Done means" criterion in docs/ideation/PLAN.md is met with evidence, at least three fresh independent reviewers who each played the latest build judge it very good for a playtest, and that build is exported to /data/bramble-builds/ with latest pointing at it. Never merge anything into main."
- **Yes, it reaches all four conditions.**
  - The Done-means evidence is collected at J2.
  - The verdict is J4, with a defined meaning of "played the latest build" (§1.7) and a pass rule that fits that meaning (§1.8).
  - The export is J3, with `latest` repointed (§5).
  - The main guard runs after every cloud session (§3).
- **The earliest the goal can be met is J4, the last step.** Realistically it is round 8 (build 10), because 0 of 17 reports have said "very good" and the pass rule is strict. The plan budgets for that.
- **Four things could still leave it unmet,** and the must-fix list covers them:
  - DM2's reviewer bar was tightened from "they" to "each" while games were cut to 2 per reviewer;
  - the Naive bot bar was demoted without a logged reason;
  - the verdict brief doesn't carry the 09d line about rare highrolls;
  - the bar check that A4 waits on can't run where the plan puts it.

**The scale problem (09a: "our numbers may just be too small in general").**
- **Partly.** A3.5 is the first step that aims at it directly, and A4 reports to the owner. That is the right shape.
- **Problem 1: the lever may not move the two flattest tribes.** A3.5 slides each tribe along its own B→C dial path, and dials that are equal in B and C stay fixed. In `rates.json` (wave2b 0b2fcb88):
  - Bog's path moves only `bog_soak_keep` (2→3) and its golden twin. The file's note says "Bog and hero/spell percentage presets are unchanged".
  - Oozes move only `oozes_elder_share` (0.5→0.75) and `oozes_soup_share` (1/8→1/6).
  - Oozes need about ×3.4–4.5 at R12 (262 and 200, against 900).
  - So A3.5 is likely to end in its own "responds weakly … don't raise it further" branch for those tribes, and the scale stays unfixed for them.
- **Problem 2: it sits late.** A3.5 is fourth on track A. It waits on A1–A3, the Quilboar merge, all four of S3's harness follow-ups, and an S4 that does the soak rework before the sim job.

## Inventory and verdicts

"Owner" means the owner's own words. "Agent" covers the orchestrator, the critic, earlier reviews and plans the orchestrator approved itself.

| Step or item | Moves the problem? | Proposed by | Verdict | Why (evidence) |
|---|---|---|---|---|
| A1 Oozes in | Pool (DM1); one tribe's scale | Agent (wave 2b plan) | **Keep, rewrite** | Stale against the Pot Luck call (DECISIONS 10 Nov, ff0fe759). The triage found a route-fidelity fault, not a dial level. Its fix is arms (a) and (b) on 32 seeds plus a constructed R8 board, then a card change if needed, and it "lands on wave2b before part 3 (neutrals)". Only the level miss goes to the scale step (item 6). A1's "or the triage logs why A3.5 covers it" lets the growth miss through. |
| A2 Hedgerow light pass | DM3 (signature), pool | Agent | **Keep** | Add the Pot Luck process rule now in LEARNINGS (check the line's gold and save rules against its paper route), which the triage says "applies to Hedgerow's line now". |
| A3 Neutrals | DM1, and a past "very good" blocker | Agent (v3) | **Keep** | playtest-3: "Neutral scaling beats tribes. *Alone stops 'very good'.*" (Charcoal Burner). A3 changes the Burner. |
| A3.5 B and C from realized boards | **Scale (09a), directly** | Agent (critic #2), serving 09a and 09h | **Keep, fix the premise, move run 1 earlier** | (1) The premise check above: Bog and Oozes have 1–2 moving dials, and the share dials pass 1.0 when t > 1 (Hunters' 2/3 → 1 → 1.5 at t = 2). (2) It fits R12 only. That contradicts §6.3, "A3.5 doesn't chase R12 alone", and `bars.md` §2: Fairies take off at R13–R15, so an R12 fit pushes them hardest and overshoots at R15. (3) Run 1 could go right after A1 on the five pass 3 tribes, with run 2 after A3 as the confirmation. |
| A4 Step 5 measurement | Scale readout and DM2's first read | Agent (v3 step 5) | **Keep, shrink the reported bundle** | Needed: the 150+ lobbies, field fights, designed setups (09d: "far more reliable"), the damage table (bigger boards change hero damage; pt4-a and pt4-b losing streaks), the libraries and the 200-game soak. The splash audit and the line gate are reported only. Run them from the same lobbies if that's free, otherwise defer. |
| A5 Checkpoint 1 | Fun (09c) and growth | Agent, on 09c and 09i | **Keep** | |
| A6 Build 8 | The owner playtests | Agent (goal) | **Keep** | |
| A7 Round 6 and triage | The "very good" verdict | Agent | **Keep** | 0 of 17 reports said "very good", so a dry run before the verdict is warranted. |
| B1 Batch 1 finish | DM5, 09e | Owner 09e; agent spec | **Keep, mostly done** | ideation/declutter is at cea9d0e2. The fresh reader passed (9649747c), and the Pounce and Mire cues are in. What's left is the Actions gate and the merge. |
| B2 Batch 2 | DM5, 09e ("fewer reminders") | Owner 09e; agent spec | **Keep** | b2 has already merged batch 1 (593e0740). `recruit_screen.gd` is now 1,047 lines, not 1,025. |
| B3 Batch 3, trimmed | 09e | Agent | **Keep** | |
| B4 Tutorial, Rules hub, settings | DM5 ("A tutorial, how-to-play") | Owner 09e ("The job of a tutorial is to tutorialize") | **Keep** | |
| J1–J4 | The goal | Owner (goal) | **Keep** | |
| §1.1 / §1.2 / §1.3 | Order and scope | Agent | **Keep** | Each cuts work or unblocks testers. |
| §1.4 / §1.5 Actions sim job | Throughput (10a) | Agent (critic #7), serving 10a ("tests can run on the cloud") | **Keep, reorder S4** | S4's row says "soak rework, then the sim job", but A3.5 needs the sim job and only A4 needs the soak. §1.4 lists them the other way round. Put the sim job first. |
| §1.6 One library, recaptured last | DM4, DM6 | Agent (critic #5) | **Keep** | |
| §1.7 "Played the latest build" and the render tool (S5) | The goal's "each played the latest build" | Agent (critic #1); PLAN's "a scripted UI driver produces screenshots of the same game" | **Keep** | Without it no reviewer sees their own game. The tutorial gate uses it too. |
| §1.8 Pass rule | The goal and DM7 together | Agent (critic #1) | **Keep, define "problem"** | It's the only rule under which the build the trio played can still be the latest build. It can loop, though, and nothing screens out what 09d says not to fail on (must-fix 3). |
| §1.9 Triage round 6's design items | Verdict | Agent | **Keep** | |
| §1.11a Owner game logs | Nothing in this plan | Agent (v3 step 4) | **Defer** | No step reads them. Trigger: the owner plays build 8 and a step needs strong-player boards. Alternatively, name W-g as their reader. |
| §1.11b Answer-buying bots dropped | Cuts work | Agent | **Keep** | |
| §1.12 Loosenings logged | Goal integrity | Agent | **Keep, complete it** | It leaves out the Naive bar and the replaced 6–25% lobby band (must-fix 2). |
| §1.13 Bar check on the Quilboar archives | DM2's validity | Agent (lessons draft, `process.md` §1.1) | **Shrink** | It can't run "on Actions": the captures aren't in git ("No capture is in the squash tree"); they're in `Bramble-ideation-sol/build/quilboar-h1-captures/` and `/home/alex/backups/`. The answer already exists: `ck_captures.txt` F9 gives Quilboar's fight win rate against its lobby by band. At R12–14: uncut 0.89, C 0.84, B 0.75, frozen 0.54. A local Python read settles the 80% bar with no Godot. Its fallback is bad: the lobby-firsts band "flags whichever line leads this field" (`bars.md` §5). It flags Birds at 36% (B) and 50% (frozen arm), which would force a Birds nerf against "Birds: no nerf" and 09d ("I don't want you to force it"). |
| §1.14 Same-cohort growth | Honest growth read | Agent (lessons draft) | **Keep** | It's cheap. For R8–R14 it moves per-line reads by ≤0.03 (`bars.md` §1). It matters for the R12–R15 reads. |
| §4 Done-means rewrite | The goal's first condition | Agent (W-a) | **Keep, with musts 1–2** | PLAN allows changes, and loosening needs a logged line. The goal points at PLAN.md's criteria, so keep the 6 Nov text visible beside each change. |
| §6 Quilboar lessons | The owner's question today | Owner ("What have we learned from it?") | **Keep, answer sooner** | "Next status report" is vague. Answer when lessons.md lands. The draft leaves out the biggest challenged assumption: power-budget.md's linear, summed costing (`process.md` §1.5 and §2: "Linear growth only"; freezing gem size ÷4.7). That is the direct answer to "challenge any of our assumptions". |
| S3 item 1: the four harness follow-ups gate A3.5 | Validity, partly | Agent (harness reviews) | **Shrink** | Only "drop contaminated trials" bears on A3.5's numbers. Labels, the seated-line check and per-seed storage can follow. |
| S3 item 2: promote the decoy arm | A reported line only (placing (b)) | Agent | **Defer** | Placing is now reported, and it was met on build 6 (DECISIONS: real minus decoy +17.7). Run the existing `xprobe.gd.txt` once if J2 keeps placing. |
| S3 items 3–4: export script, memory budget | DM6, Android | Agent | **Keep** | |
| S7 art (15 images) | DM5 ("Unique art on every unit") | Agent (sharpened DM5) | **Keep** | |
| S8 W-a to W-h | Briefs and calls | Agent | **Keep** | W-d needs 09d's line (must-fix 3). |
| S10 Faster suite | Owner 10a | Owner ("smarter scheduling of when tests are run") | **Keep** | |
| J2 reported extras (visual-tier re-score, neutral economy, placing) | Reported | Agent; 09f supports the visual comparison | **Keep only the cheap ones** | Placing: see the decoy arm above. |

## Fixed after step

- **The goal:** J4 today, and that is the last step. Realistically round 8. No reorder makes it earlier, because the verdict has to come last.
- **The scale, today:** A3.5 run 2, then reported to the owner at A4. That's about 3 or more worker-days out (A1→A2→A3), plus the infra waits.
- **The scale, reordered:** A3.5 run 1 right after A1 on Birds, Fairies, Bog, Hunters and Oozes, with the premise check first. Then run 2 after A3, covering Hedgerow and the neutrals, as the confirmation. The owner gets a first per-tribe answer days earlier, including which tribes can't reach their target on their current dials. That is the point where 09a's "Large amounts of design need to be completely reworked, and that's okay" may apply.

## Smallest plan

1. Refresh §0 and A1 to the live tips and the Pot Luck call, and log the plan with the must-fixes (W-a).
2. Merge Quilboar, then batch 1 (gate only). Then A1, with Pot Luck's arms (a) and (b) before A3.
3. S4: the sim job first. S3: the contamination drop only, then the A3.5 premise check.
4. A3.5 run 1 on five tribes. Tell the owner the per-tribe response.
5. A2 and A3 (pool settled), then A3.5 run 2, then A4 and the plain scale answer.
6. A5, A6 (build 8 to the owner), A7 (round 6), and the triage.
7. B2 → B3 → B4 in parallel, J1–J3, then J4. Round 8 if J4 fails.

## Deferred

- **Owner game logs.** Trigger: a step needs strong-player boards, or the owner sends games.
- **Decoy-arm promotion.** Trigger: J2 keeps placing (b) as a run.
- **Splash audit and line gate,** unless the A4 lobbies give them free.
- **Three of S3's four harness follow-ups.** They go after A3.5.

## Checkpoints, where the owner hears plainly where things stand

1. After A3.5 run 1: which tribes reach target on their dials, and which need design.
2. After A4: whether the scale problem is fixed.
3. At the build 8 export: the owner can play.
4. After the round 6 tally: whether "very good" is in reach.
5. After J4.

## Must-fix (would leave the goal unmet or go against the owner's words)

1. **DM2's reviewer bar can fail by construction.** §4 says "each found 3+ builds that felt different", but each verdict reviewer plays only 2 full games. Sharpened DM2 says "they found at least 3 builds", which is collective. Use the sharpened wording, or give each reviewer 3 games.
2. **Unlogged loosenings of Done means.** §4 demotes the Naive bar to "reported". Original DM2 says "a strong bot clearly beats a naive one", and BOTS.md says "1 best bot among 7 Naive places top 4 at least 85% and wins at least 45%". Put it in DM2's checklist (300 games, and the test already exists), or log the drop with a reason. Add the replaced 6–25% lobby band to §1.12's list too, and keep the 6 Nov text beside every change, so meeting "every Done means criterion" can't be confused with redefining them.
3. **The verdict brief and the tally ignore 09d.** The owner: "don't let reviewers fail good work on power-budget concerns that don't matter, if the thing happens very, very rarely and it produces a good game in general." Under "no problem raised by 2+", two reviewers flagging a rare highroll fail the round. Put the line in W-d's briefs, and have the tally drop such items unless the reviewers saw them often.
4. **A3.5's lever can't reach the target for the flattest tribes.** "The paper workflow already gives every engine dial a B value and a C value" is true only in form. Bog moves 1 dial (plus its golden twin) and Oozes 2. Before run 1, list each tribe's moving dials and their domain limits (shares over 1). For any tribe with too few, have w7 or the paper workflow name the dials that can carry the raise before run 1, rather than finding out at the weak-response branch. Otherwise the plan reports "scale not fixed" for those tribes by design.
5. **§1.13 blocks A4 but can't run on Actions.** The captures are outside git. Rewrite it as a local Python read of the captures (F9 already separates uncut 0.89 from frozen 0.54 at R12–14). Replace its fallback: the lobby-firsts band flags Birds in every arm, which would force a nerf against 09d.
6. **A1 contradicts the logged Pot Luck call.** The triage puts the growth miss on route fidelity, then a card change, before part 3. It doesn't go to A3.5. Rewrite A1's criterion 2 and add the arms step.

## Ask items (the orchestrator's call)

1. Move A3.5 run 1 to just after A1, with run 2 after A3 as the confirmation.
2. Fit A3.5 on R12 with an R15 guard, or on R12–R14, so it doesn't chase R12 alone (§6.3, `bars.md` §2).
3. S4: build the sim job before the soak rework.
4. Define "problem" for the tally before round 7, for example an item the reviewer says should change before this playtest, so the pass rule can end.
5. Answer the owner's Quilboar question when lessons.md lands, and include the power-budget assumption it challenges (`process.md` §1.5).
6. Early rounds: three reports already raise thin R1–5 decisions (playtest-3 #3, pt4-b, the fun probe), and 06a says "if multiple reviewers independently agree on the same thing, you should just keep iterating". Start a paper and designed-setup triage in w7's idle window now, so round 6 can confirm a ready fix.
7. The Claude budget count covers only cloud sessions. The ~14 scope reviews, cold readers, tallies and W-a to W-h workflows also cost Claude. Count them, or say why it doesn't matter now.
8. 09a asked that "you stated all your assumptions: your method and process for balancing". Put A3.5's method and assumptions in the A4 report (telling, not waiting).

## Moved since v2 was written (refresh before logging)

- ideation/main is ff0fe759 (docs only). It adds the Pot Luck triage call and "Quilboar fixes narrow check: clear to merge".
- declutter is at cea9d0e2, and its reader passed.
- b2 is at 593e0740, with batch 1 merged in. `recruit_screen.gd` is 1,047 lines.
- wave2b is at 0b2fcb88 (Hedgerow fixtures and the Ruff format). `recruit_rules.gd` is still 1,003 lines.
