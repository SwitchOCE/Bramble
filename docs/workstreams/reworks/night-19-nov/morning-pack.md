# Balance morning pack, 20 Nov

The reworks made both tribes weaker, and the Mice fell far out of range: 0 wins in A/A. Four rounds of number-only tuning bring all five tribes within 0.8 places of each other in TribeBot games. That tuning is **on a branch, not on `dev`**, because the third bot run was going to use `dev`'s cards. It's waiting for you.

**The Mouse half of the tuning goes against your design.** You set the Mice as an Attack tribe with little Health (16 Nov: "I don't want them to scale HP, so they are weak, but it'd be good for the Mice as a tribe to have a lot of attack scaling"; the accepted pitch: "an Attack-only tribe with no Health scaling"). Tuning rounds 2–3 raised the printed Health of 11 Mice by 2–3 times. They now have the most Health at their tiers. The tuning designer and I missed the conflict; the final review caught it this morning. Attack alone (round 1) left the Mice last, at 6.13 in A/A. That's question 1.

**Is balance fixed?** Not yet. By TribeBot the spread is tight (4.07 to 4.87 out of 8), and the Pigeons are back to pre-rework strength without breaking any rule. But the Mice got there on Health, and TribeBot plays them poorly (section 3). Without the Mouse changes, the Pigeon half alone puts the Pigeons first (3.52) and the Mice last (6.65).

## 1. Try this first (5 minutes)

**Get the builds.** Both were sent by Taildrop. If they aren't there, paste these in PowerShell.

`dev` (reworks, untuned):

```
npx.cmd -y wrangler@4.160.1 r2 object get bramble-assets/sha256/3e/3e040e9ad9084a29f7cfe099ce2633d8cdc7ecf631369a2cde9fdd98cea11848.zip --remote --file "$HOME\Downloads\Bramble-windows-ca82575d4-1120-1034-balance-dev.zip"; Expand-Archive "$HOME\Downloads\Bramble-windows-ca82575d4-1120-1034-balance-dev.zip" "$HOME\Downloads" -Force; ii "$HOME\Downloads\Bramble-windows-ca82575d4-1120-1034-balance-dev"
```

Preview: `dev` plus tuning round 4b plus the pile-on jab. **Not on `dev`.**

```
npx.cmd -y wrangler@4.160.1 r2 object get bramble-assets/sha256/6d/6d02dc2991261d2fa2db6e4055c380439c73996eac2856a0ace16d626b3bc19f.zip --remote --file "$HOME\Downloads\Bramble-windows-1ff796e53-1120-1036-preview-tuned.zip"; Expand-Archive "$HOME\Downloads\Bramble-windows-1ff796e53-1120-1036-preview-tuned.zip" "$HOME\Downloads" -Force; ii "$HOME\Downloads\Bramble-windows-1ff796e53-1120-1036-preview-tuned"
```

**In the preview:**
1. **Play the Mice to round 8 or so.** They now have about twice the Health they had (Needle Pikeman 14 → 36, Dormouse Cook 9 → 24). Do they still feel like Mice, or like a tanky tribe?
2. **Play the Pigeons through rounds 4–6.** That's where they were losing (36% of fights). Territorial is 5/7, Old Campaigner 6/9, and Lieutenant has 9 Attack.
3. **Watch a Mouse fight with a pile-on.** The piler now jabs first and its damage lands before the attacker's. Each attack with a pile-on takes 0.77 s longer. Does it read clearly, and is it too slow? The before/after clip, side by side:

   ```
   npx.cmd -y wrangler@4.160.1 r2 object get bramble-assets/sha256/2f/2fa8c65bdabccd142a97aa411ddbc0ae96365d776ca85238579e0de7f05c20ff.mp4 --remote --file "$HOME\Downloads\pileon-before-after.mp4"; ii "$HOME\Downloads\pileon-before-after.mp4"
   ```

## 2. Key choices made without you

Full log: [night-log.md](night-log.md).

- **No card changes on `dev` tonight.** The tuning lives on `balance/mouse-pigeon-tuning`. The third bot run hasn't started anyway: the ghost orchestrator lost the night to approval prompts.
- **The tuning: numbers only, generous.** No mechanics changed; card text changed only where it prints a number. All 24 numbers are in [tuning/round1–4.md](https://github.com/SwitchOCE/Bramble/tree/balance/mouse-pigeon-tuning/docs/workstreams/reworks/tuning) on the branch.
  - **Mice:** Health went up on 11 units, mostly 2–3 times, against your "no HP" direction (see the top). Fencing Master's Attack went from 4 to 10, and three effects grew.
  - **Pigeons:** bigger early bodies, plus more Renown on a few cards.
  - **Round 4 overshot:** it put the Pigeons first, at 3.74. I halved each of its changes (4b), and 4b is what the branch holds.
- **The pile-on jab: built, held.** The attacker winds up and waits. The piler jabs, holds while its effect plays, and goes home. Then the attacker lunges. The jab timings are named constants, `FightMotion.JAB_*`. It changes motion only, not fight results.
- **Charge pips dim with a snap, and pip size is unchanged.** Spent keyword marks snap too, so this matches them.

## 3. What nothing could see

- **TribeBot plays the Mice badly.** It puts pilers in the back row and ignores Hand-me-down routing. So the Mouse numbers measure the bot as much as the cards. A good player may find the tuned Mice too strong.
- **All balance comes from TribeBot.** Each A/A tribe figure is about ±0.25. The league bots predate the reworks and can't hold reservists, so their Pigeon reading (6.39) understates them.
- **Motion on your screen.** I judged the pile-on jab and the films from 60 fps stills on a software renderer. No one has seen them at real speed on real hardware.
- **Feel of the wait.** With a pile-on, the attacker now stands wound up at home for about 2 s while triggers play.
- **The drag fix on your frame rate.** It passed 10 of 10 runs with all cores loaded. But the old code wasn't rerun under that same load to show it failing there.
- **Film fixtures aren't the game.** The one enemy is a boosted Regimental Sergeant Major (11/35 or 7/35), and the pointer hovers the Charge card the whole time. Two moments from the plan weren't filmed: a Hopper getting no Renown, and the T6 Pikeman spreading +2.
- **The Windows builds** boot under wine on Linux. They haven't run on your PC.

## 4. Done and verified

| What | Where | How it was checked |
|---|---|---|
| Drag pitch follows game time, not frame rate (a real bug behind the drag-test flake) | [PR 194](https://github.com/SwitchOCE/Bramble/pull/194), on `dev` | Full gate (13 steps); the drag test 10/10 under full CPU load; scope review clean |
| Gate clears the desktop's `XMODIFIERS` | [PR 192](https://github.com/SwitchOCE/Bramble/pull/192), on `dev` | Gate passes under xvfb; scope review clean |
| Reworks measured, old against new | [night-log.md](night-log.md) | TribeBot, 200 games per arm on the same 100 seed lines, paired by seed |
| Tuning rounds 1–4b | branch `balance/mouse-pigeon-tuning` (numbers at 2220f12e) | Each round measured the same way; round 4b's table is in `tuning/round4.md` |
| Pile-on jab | branch `preview/reworks-tuned` (from `fight/pile-on-jab`) | Gate; a test plays the real pile-on moment and fails on the broken placement; before/after film |
| Films of the reworks (Pigeon reserve, Mouse kin, recruit marks) | `media/` here | Judged frame by frame from stills and contact sheets |
| Tests brought up to the tuning | `balance/mouse-pigeon-tuning` at 49f9482f | The preview build's gate failed at tests: 15 tests still held the old numbers. A worker updated the design files, the expected values, three ruling fixtures and one recorded game, removing no assertions. Full gate passes at 189bf37d. One case had lost coverage (1 Renown deals no Lieutenant damage), so I added a test for it, shown to fail with 2 Renown. Rules soak on the preview: 150 games, 0 violations. Scope review: no cuts. It asked whether the tribe READMEs should show the proposed numbers: not until you decide. |

## 5. Questions, with my recommendations

1. **The Mice: keep the Health pass, or stay within your rule?** Options:
   - (a) keep it as a generous start and dial back after play;
   - (b) drop the Health and tune within the rule: more Attack, Pile on, or Cousins. Numbers alone got the Mice only to 6.13 under TribeBot, so this probably needs a bot that plays them properly (question 3), or a design change;
   - (c) a middle way: keep some Health on the front-row Mice only (Sentinel, Cook) and tune the rest within the rule.

   *My recommendation is (b), because the rule is yours and the Health pass changes what the tribe is. I'd start a designer on it once you say.* The Pigeon half doesn't depend on this.
2. **Merge the Pigeon half (its 9 numbers) into `dev` on its own?** Measured without the Mouse changes:
   - Pigeon-locked seats: 4.08, a little stronger than before the rework (4.24).
   - A/A: Pigeon 3.52, Badger 3.62, Locust 4.31, Briar 4.41, Mouse 6.65. The weak Mice lift everyone else, and the Pigeons come out on top.

   *Yes, if the preview's Pigeons feel right. That fits "start generous and dial back", and I'd re-check them once the Mice are settled.* The ghost orchestrator would rather card changes land before scored matches; each one costs it a field re-cut (under an hour). The branch passes the full gate.
3. **Keep the pile-on jab?** *Watch the side-by-side clip first. If 0.77 s feels slow, tell me and I'll shorten it: the jab's timings are named constants.* Your "Go, log each call" was about pips and marks, not fight choreography, so I didn't merge it.
4. **Ask the ghost team to teach TribeBot the Mice?** That means pilers in front and Hand-me-down routing. *Yes. If you pick (b) in question 1, before the Mouse tuning; otherwise after scored matches start.* Until then, Mouse balance rests on your play.
5. **`dev` → `main`?** *After you've played both tribes.*
6. **Codex full access was unreliable.** Two of my four workers were still refused `git checkout`, so I did that work myself. The ghost orchestrator's workers sat on approval prompts for hours. *This is yours to sort out. Until then, I'll keep git steps in Claude sessions.*
