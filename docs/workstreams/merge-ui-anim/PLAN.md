# Plan: getting the UI rework and the fight animation into `dev` and `main`

Merge coordinator, 25 Nov 2026. Proposal; nothing in it is approved yet.

## The owner's words (25 Nov, dictated; filler removed)

> "Animations might also be moving into dev. So I'm just wondering what's going to move first ... You might want to coordinate, or at least set up a sub-session that's in charge of understanding where both in-flight large reworks are happening ... both of you are overhauling quite a bit. So yes, you're right, there is some risk in terms of merge conflicts. So I think it's probably best that there is some figure that's across [both]. You can focus on your task and they can focus on their task, but there's some other agent that's across both and what needs to happen. Can you and it coordinate creating a session that both of you can talk to, that is on top of that ... I don't mind which of you goes first, as long as there's a plan for getting both animations and UI/UX improvements merged into dev and then into main."

## Where both stand (checked 25 Nov)

| | UI rework | Fight animation |
|---|---|---|
| Branch | `ui/l1` at `0f967435`, 14 ahead of `dev`, 0 behind | `ideation/fight-animation` at `6f17b93f`, 101 ahead, 2 behind (docs only); step 3 on `review/fight-anim-game-3` |
| Changes in `src/` | 50 files: every card (`glass_card.gd`, new `l1_*`), the buy screen, `glass_screen.gd`, `game_controller.gd` | `src/screens/fight/`, `src/sound/`, `assets/audio/cues.json`; step 3 adds `game_controller.gd`, `game_flow.gd`, `game_session.gd` |
| Left before a `dev` PR | light (running), the two panels, merge prep; the owner's fix round after the first build | first Windows build (today); then B (motion polish) and S (sound), second build |
| Rough time | about a day for its own steps | first set today; B and S after |

Other open work doesn't touch either rework: the league and balance branches change only `tools/league/`, and PRs #243, #248, #252 and #255 share no files with them.

## What the combination showed

1. **The text merges cleanly.** `dev` + `ui/l1` + `ideation/fight-animation` has no conflicts. Both branches change `tests/screens/test_fight_screen.gd` and, with step 3, `src/game/game_controller.gd`, but in different places.
2. **It does not compile.** `fight_screen.gd` fails to load. The fight's new +N gain discs (`fight_gain_disc.gd` extends `GlassCard`, and `fight_gains.gd`) use the old card: `tier`, `distinct_stats`, `_draw_stat_setting`, `_draw_number`, `GlassPieces.disc(tier, …)`. `ui/l1` removed all of these, so every fight in the game would break.
3. **A small port fixes the compile.** Four files move onto the new card's fixed disc (`GlassCard.stat_disc`, `_draw_stat`): two in `src/screens/fight/` and two fixture files. Coordinator's trial commit `77ebbd1b`, not for merging. Result of the full checks on it: see the status line at the end.
4. **What the checks can't see.** Whether the +N flights land on the new discs, and how the swollen disc looks on the lead card. These need the fight session's film comparison, and in the end the owner's eyes. Motion, feel and sound are not judged by any agent.
5. **Ties that work today and must keep working:**
   - The fight dims and fades a card through `modulate` on the card node. The UI's coming light halos (golden, hover) must be children of the card or follow it, or a dying golden card keeps its glow. The UI orchestrator will hold its light step to this.
   - The fight turns and pivots cards about `size / 2`, so the L1 card must stay one Control the size of the visible card.
   - The fight's port relies on `GlassCard.stat_disc(stat)` and `_draw_stat(value, disc, red, pop, green)`. The UI orchestrator treats both as fixed through merge prep.
   - The UI's merge prep would remove `GlassPieces.disc` and `frame`. After the port nothing else calls them; until the fight branch has the port, they stay.

## The route

**Order: the UI rework into `dev` first, the fight animation second.**

Why:
- The card is what both draw on. The fight's link to it is four files, and only the fight session has the films to check a port.
- The fight's next step B (numbers slam with a jitter) draws over the card's numbers again. Built on the new card, it is done once. Built on the old card, it would be ported a second time.
- The UI side is about a day from a PR. The fight's first set would wait that long for `dev`, but the fight session doesn't stop: it builds B and S meanwhile.

**Steps**

| # | Who | What | When |
|---|---|---|---|
| 1 | Fight | Finish step 3, send the owner the first Windows build (old card, new motion) as planned | today |
| 2 | Fight | Merge `ui/l1` at a commit the coordinator names into `ideation/fight-animation`; take the coordinator's port; re-film against its references (disc places move, as expected); full checks | after the owner has the first build, before B |
| 3 | Fight | Build B and S on the new card; second Windows build, which is also the first build of both reworks together | after 2 |
| 4 | UI | Light (halos follow `modulate`), panels, owner's fix round, merge prep (removes `GlassPieces.disc`/`frame` only after step 2), PR `ui/l1` into `dev` | in parallel |
| 5 | Coordinator | Before each PR: trial-merge with the other side's latest, run the full checks and the bot soak, report | before 4's and 6's PRs |
| 6 | Owner | Merge the UI PR into `dev` | on the owner's say-so |
| 7 | Fight | Merge `dev` into its branch (no conflict expected, since it already holds `ui/l1`), checks, PR into `dev` | after 6 |
| 8 | Owner | Merge the fight PR into `dev` | on the owner's say-so |
| 9 | Coordinator | A Windows build from `dev` with both reworks, for the owner to play | after 8 |
| 10 | Owner | Merge `dev` into `main` (all 134+ commits on `dev`, not just these two) | after playing 9 |

After 10, `dev` is deleted automatically and its PRs retargeted. `dev` is restored at `main` and the PRs pointed back.

**Fallback if the UI PR stalls** (the owner's fix round reshapes the card, or the PR waits more than a day or two after the fight is ready): before step 2 the fight session tags its last commit without `ui/l1`. The fight's first set can then go to `dev` from that tag, on the old card, and `ui/l1` takes the port (`77ebbd1b`) in its merge prep. The other way round costs a second port of B's number overlay, and leaves the UI session shipping a fight change it can't film.

**Seeing the port early:** with step 2, the fight session sends the owner a short film of the +N gains on the new card, so the changed disc places are seen before B is stacked on them.

## How the sessions reach the coordinator

The coordinator is the T3 thread "Merge coordinator: UI and fight animation" (`mcp:launch:b60c22c1bd2450715670b0791dc6ebdcba45befd3a84f850b485bebf1efd7359`). Both orchestrators write to it with `t3_thread_send`, and it writes to theirs. Both have answered and agreed to what is asked of them here: the UI session to keep `stat_disc`/`_draw_stat` fixed, make halos follow `modulate`, leave `GlassPieces.disc`/`frame` until told, and warn before touching `fight_screen.gd`; the fight session to take `ui/l1` and the port before B, once the owner agrees.

## What I keep watching

- A fresh trial merge with the full checks before each PR, and whenever either side changes `stat_disc`, `_draw_stat`, card `modulate` or the card's node shape.
- The light step's halos and `modulate` (UI session to report).
- Any UI step that touches `fight_screen.gd` (the fight room redo is later, not in this merge; the UI session tells me first).
- Other work only when someone opens a PR that touches `src/glass/`, `src/screens/` or `src/game/`.
