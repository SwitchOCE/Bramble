# The playable build's own rules and notes

**This folder is the playable build's own rules and notes. It is not yet reconciled with the [rulebook](../design/rulebook.md).** Agents wrote it on the second ideation track (16 and 17 Nov 2026) while the owner was mostly away. It says what the build does and why. It is not a source of decided rules.

The build came to `main` at commit `f44f2f8f` (Windows build `settings-cog-1`), on the owner's say-so. The plan it was built to is [workstreams/ideation-track-2.md](../workstreams/ideation-track-2.md).

## What the owner accepted, and what they did not

The owner, 17 Nov 2026, after playing the build:

> "I really like ideation. I'm willing to accept most of it. I do not think the content is done ... the tribe's most units are not balanced to my satisfaction, but I am happy with all of the card art and the mechanics so far and the UI. So I'm happy to move ideation onto main and then iterate on main to some of those changes."

- **Accepted:** the card art, the mechanics so far, and the UI.
- **Not accepted:** the content is not done. Most units' numbers and the balance are not to the owner's satisfaction.

*[Editor's note: "the mechanics so far" is read here as the five tribes' mechanics as built. The lists below hold the places where an agent's call or an open question sits inside something accepted; the acceptance does not settle those one by one.]*

## What is here

- `tribes/`: the five tribes' designs (badger, locust, mouse, pigeon, thorn), each with a `LOG.md`; `SHARED-RULES.md` is the wording and timing the build's cards share; `CROSS-TRIBE.md`; `DESIGN-FRAME.md`.
- `mechanics/`: the page of mechanic options the owner picked from on 16 Nov. The picks, as written, are in `HANDOVER.md`.
- `mockups/`: HTML mock-ups for the screens and looks the owner's glass mock-ups do not have. Most are marked STAND-IN: agents made them, and the owner had not seen them when the game was matched to them.
- `ADDING-A-TRIBE.md`, `SCREEN-CONTRACT.md`: how a tribe is added as files, and what the screens read from the rules core.
- `HANDOVER.md`: the track's last hand-over, kept as history.

## Known differences from the rulebook

The rules core follows the rulebook as it stood on 16 Nov (v0.8) where it was built. This list is what is known; the build has not been checked against the rulebook rule by rule.

- **The owner's rules of 17 Nov (rulebook v0.9, C15) are now in the build** (19 Nov, PR #156): recruit effects, the Triple Reward when the triple forms, moving a board unit back to hand and selling from the hand. **The rules of 19 Nov (v0.10, C16) are not:** the build still has a shared pool.
- **Shop odds are flat** (rulebook 6.1.7 is open).
- **No hero powers** (the plan left them out).
- **Three shop spells nobody designed** (Sharpen, Seek, Forage) are stand-ins.
- **Stand-in cards** (`src/game/data/stand_in_units.json`) and the Battlegrounds keywords only they use are still in the core.
- **Badger Fury** differs from the options the owner picked (see below).

## Calls agents made without the owner

None of these is decided for the real game. The plan's own list of the planning session's calls is in [workstreams/ideation-track-2.md](../workstreams/ideation-track-2.md).

**The build and its tools**
- **The game is drawn at the mock-ups' 1920x1080** and scaled to the window.
- **The rules core** keeps Battlegrounds-style keywords available to tribe cards; the screens read the player view and the fight log.
- **Tribe designs:** each tribe's 19 units were designed and costed by agents and reached the build with no review round by the owner, as the plan said. Designers ran on Fable, critics and engineering on Opus.
- **Glass pieces:** the hand count is not pulled from the mock-up (it shows 10; the rule is 7).
- **Bots** are simple: they buy, play, tier up and refresh with spare gold.

**Screens**
- **Buying is by drag only.** The leaderboard is hidden until Tab or a click on the player's corner.
- **Stand-in looks** with no glass mock-up: frozen, golden, keyword and counter pills, the message line, a slot's bonus under its unit, the Discover picker, the start, result and pause screens.
- **Counters by the portrait are named plates** ("Compost 4"), not the owner's emblem chips.
- **An empty slot that holds a slot buff uses the mock-up's Ring slot look.**
- **A seed line on the pause panel,** for bug reports from play-tests.
- **The result screen leaves by itself after 2.5 s;** a "You" label sits under the player's portrait on the start screen.
- **"Space or click to skip" stays on screen through every fight.**

**Dragging (17 Nov, after the owner asked for polish)**
- **The carry's numbers** (lift, lean, swing, landing hop) are stand-ins tuned against two Once Upon a Galaxy clips, then calmed on the owner's word ("a bit too bouncy ... It tilts a bit too much"). The owner named side-to-side tilt and bounce; the up-and-down squash and the narrowing at speed were toned down too.
- **A shop unit dropped on an empty slot is bought and played in one move.** A bought card that completes a triple stays in the hand as a golden. A full hand refuses a buy onto an empty slot (rulebook 4.2.2). A hand unit dropped on a board unit is refused; a board unit dropped on a board unit swaps.
- **The landing hop is small** (16 px). Two film reviewers disagreed on how far Galaxy's card bounces.
- **Parity with Galaxy "to a reviewer" was not reached.** Two film reviewers said "not yet" before the last rounds; nobody compared the later rounds. The owner then moved the tilt away from Galaxy's on purpose.

**Settings (17 Nov, the owner asked for a cog and one setting)**
- **One menu:** the cog opens the pause panel, so the game pauses while a setting is changed. The cog sits top left and goes under the dim while the panel is open.
- **Wording:** "Cards drop by: Pointer / Card middle". The owner's words were "cursor" and "center of the card".
- **"Card middle" decides every drop** (slot, swap, buy, sell, play, cast). Pressing, clicking and hovering stay on the pointer. Default: Pointer.

## Left for the owner to decide

**Rules and tribes**
- **Badger Fury differs from the option picked.** The option read "+8/+8 ... while the enemy has more units than you ... As the enemy thins out, the fury stops by itself". As designed and built, Fury gives Attack only, and the outnumbered count is fixed at the start of the fight, so it never fades. The designers' reasons are in `tribes/badger/LOG.md`.
- **Pigeon Renown** stays on the slot. Old Campaigner earns more when it survives.
- **The three stand-in shop spells:** keep, replace or drop.
- **Gold piles up** (a play-tester had 56 by turn 7). That is rulebook 4.1.1 and 4.1.2 as the owner set them on 12 Nov; it was left alone.
- **Fights are long.** Over 173 fights the middle one ran 19 s and the longest 49 s. Space or a click skips to the result.

**Screens**
- **Chips or plates** for the counters by the portrait. If plates, the owner's own mock-up pages should change. Counter emblems are not drawn: the plates name an emblem that has no picture yet.
- **In a fight, a hover does not always say why a number is green or red** (an opponent's saved board, units that arrive mid-fight).
- **The seed line, the result screen's 2.5 s, the "You" label and the skip line** (above): keep or change.
- **`mockups/recruit-tribes.html` is drawn from the build's own data,** so it checks layout with real cards and cannot catch a wrong pill. It is not a mock-up.

**Dragging and settings**
- **Which drop mode stays:** Pointer or Card middle. Whether the cog is easy to see and to hit.
- **Whether the calmer carry is now too flat,** and whether up-and-down was fine as it was.
- **In either mode nothing marks which slot a carried card will land in;** every open slot is lit the same.
- **Whether the two Galaxy clips are the baseline,** and where a sell reference comes from (Galaxy has no selling).
- **A cue on the sell area** while a unit is held over it.
- **The triple, full-hand and hand-onto-board calls** above.

**Housekeeping**
- **Cloudflare account ID in a closed PR.** PR 77 committed `.wrangler/cache/wrangler-account.json` by mistake: the owner's Cloudflare account ID and email, on a public repo. The file never reached the track's branch (`.wrangler/` is now gitignored; PR 77 is closed and its branch deleted). GitHub still serves a closed PR's commits through the PR, and only GitHub support can purge them. The ID is an identifier, not a credential.
- **Old builds in R2:** the files for `five-tribes-1`, `-2` and `-3` (about 390 MB) are no longer listed in `tools/assets/manifest.tsv` and stay in R2 until someone runs `python tools/assets/assets.py prune --delete`.
- **Reference clips and art masters** are on the Optiplex only (`/data/bramble-art/track-2/`), not in R2.

## What no agent could check

Mock-up match numbers are run by hand: the gate does not re-run the screenshot compares.

See [AGENT-BLIND-SPOTS.md](../AGENT-BLIND-SPOTS.md). For this build in particular: no agent has run it on Windows (the owner has, and plays it there); motion was judged from fixed-rate films, which never show a dropped frame; the late game was reached by bots, not by a person; nobody has heard it, because it has no sound.

## Small things left undone

- `tests/screens/fixtures/fight_moments.json` still has a `"waiting"` block nothing reads, and a button in `mockups/stand-ins.html` still says "outnumbered, waiting, used up".
- The whole-game test compares shop and fight numbers in the five single-tribe games but not in the all-tribes game. A mixed game of only shipped tribes should be added to the test.
- Enter skips a fight; only a unit test covers it.
- The core's `effect` fight event carries no `totals`, so a keyword given twice in one fight shows a summed number until the next unit view.
- From the recruit screen split's review: `RecruitInput` has 19 public methods against the lint's 20, and the screen's parts still reach into its privates.
- In card-middle mode there is no unit test for play or cast by the middle.
- The `README.md` files under `src/` still say "nothing here is decided for the real game". They were left as they are so that `src/` on `main` is byte-identical to the build the owner played.
