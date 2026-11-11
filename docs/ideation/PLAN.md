# Look-and-feel phase

<!-- status -->
- **In short:** The Bazaar Stack layout and the new art are in: units and woodland now painted in one ink-and-wash style. Next, play goes on its own surfaces with the world as a frame, and recruit feel lands.
- **Status:** active
- **Last step done:** 11 Nov: the units went one notch more painted: all 162 portraits and tribe images repainted and merged (gate passed, 0 problems in the 4-game UI run).
- **Next step:** frame play on its own surfaces (A2), recruit feel (B), and a trial of units one notch more painted; mid-loop update to you when A2 lands.
- **Waiting on you:** nothing. Loop 1 ends when you play its build, or 13 Nov 23:22.
- **Scope:** UI, UX, look and feel. Nothing on rules, numbers, bots or content.
<!-- /status -->

Branch family `ideation/*`, merged into `ideation/main`. **Nothing reaches `main` without the owner's say-so** (CLAUDE.md). Build 8 is the latest build; run 1's balance work is parked (`PARKED.md`).

## Reading list (in this order)

1. The owner's notes: `docs/design/owner-notes/2026-11-09e` (UI clutter and tutorials), `09f` (visual comparison), `10d` (audience), `10j` (this phase), and the art-style notes of 1 Nov.
2. `ui-declutter-spec.md` (sections 1–5), and `evidence/declutter/visual-comparison.md`.
3. `END-OF-RUN.md`, its "Tools worth keeping" section only (the rest is run 1's balance numbers), and `PLAYTEST.md`.
4. `DECISIONS.md` (one page).
5. Only when a step needs them: `docs/CLOUD_SETUP.md` (the gate, Godot slots), `engine.md`, `wording-guide.md`, `strong-field.md`.

Don't read `archive/run1/` unless a step needs a specific past call; it's history, not instructions.

## The owner's words (10 Nov)

> "I want to start a new basically phase based on the outputs of Bramble Ideation 2, the proposed amendments to some of the process that you had. And I want this pass to be pretty much solely on game look and feel, UI and UX. No, nothing balance, no mechanical design, purely UI, UX, game look and feel. I want the agents to be able to use computer use in a headless environment to make sure they can kind of get a feel for the scenes and etc. And I want to have you have a plan as to what process I should follow to prevent the issues of the previous Run."

Earlier owner direction this phase builds on:
- 09e: "We need to have far less visual clutter devoted to essential tutorialization… Animations should, by player feel, capture how a game is and how it plays." Also: "the game, the UI, etc., is all, in a way, judged by agents trying to get higher scores from critics who are giving potentially bad feedback."
- 09f: compare "screenshots of our game directly with screenshots of Hearthstone, Battlegrounds, Galaxy, TFT".
- 10d: Johnny first, Spike second, Vorthos last.
- 10g/10h: the last run ended at build 8; stop balance changes.
- `archive/run1/PROCESS-PROPOSAL.md` (end of run 1): one-page DECISIONS, a three-line "done", a design-first reading list, an end condition tied to the owner playing, at most two focus items, one review per step.

## What went wrong last run, and the fix for each

| Last run | This phase |
|---|---|
| Effort went to process: 235 decisions in 5 days, "done" rewritten 3 times | One-page DECISIONS (UI calls only). "Done" is three lines (below). No new bars or measurement plans unless the owner asks |
| End condition that could never be met (0 of 17 "very good") | The loop ends when the owner plays its build, or after N days (owner picks N; suggest 3), whichever comes first |
| The owner didn't see anything at the new scale until the end | The owner sees a picture-and-clip gallery on day 1 and again mid-loop, and can redirect at each |
| Agents chased critic scores (09e) | No numeric scores for looks. Reviewers answer plain questions (what did you notice first, what confused you, what felt slow) and set our shot beside reference-game shots |
| A measured number fix beat a better unmeasured design | Where a focus item has two credible looks, the owner sees both as clips; at most one pair per loop ships behind a setting to pick by playing |
| Orchestrator's context filled with process docs | A fresh orchestrator session, not a continuation of Ideation 2. Run 1's process docs are archived (`archive/run1/`); the reading list below puts owner notes and UI docs first |
| Design skill used only when told | Design skills available by default: design-critique, accessibility-review, ux-copy (game-design-process is a mechanics skill) |
| Scope crept into many parallel tracks | At most two or three focus items per loop, picked by the owner from the day-1 gallery |

## Scope fence

- **In:** everything a player sees and touches: tiles, card reader, board, shop, HUD, hand, scouting, fight animation and timing, feedback and "juice", menus, settings, game-over, phone and PC layouts. Card text wording is out for loop 1 (it lives in content data).
- **Out:** rules, numbers, card behaviour, new content, bots, sims, balance.
- **Enforced by a check, not just a brief:** step 0 adds `tools/checks/scope_fence.sh` to the gate. It lists the files changed since the merge-base with `origin/ideation/main` and fails if any is under `src/core/`, `content/`, `tools/sim/` or `tests/core/`. Once step 0 has merged, the gate's own files (`.github/`, `scripts/cloud-gate.sh`, `tools/checks/`) are fenced too.
- **Old UI tests:** a focus worker may rewrite or delete `tests/ui/` tests that assert the old layout, and lists each one in its step note. That isn't a DECISIONS call. `tests/core/` stays untouched.
- **Bugs:** gameplay bugs found while looking are logged for later, not fixed, unless they break the screen being worked on.
- **Defaults, until the owner says otherwise:** sound out; the tutorial and Rules reference (declutter batch 4) in; PC landscape first, portrait later.

## Step 0: eyes and hands (before any UI change)

"Computer use" in the Claude desktop app drives the owner's real desktop; it isn't headless and workers can't use it. The headless equivalent is a small tool agents call in a loop: look → act → look.

- `tools/look/` (one Codex worker, small–medium):
  - start the game under Xvfb on its own display at the two sizes every UI tool already uses: PC 1920×1080 and phone landscape 1688×780 (the game is landscape today; portrait is a day-1 candidate, not a step-0 job);
  - act: click, drag, key, through xdotool;
  - look: a screenshot (scrot), saved with the step number;
  - clip: Godot's `--write-movie` frames at a fixed rate (screenshot polling misses 0.1–0.2 s motions), made into a contact sheet and GIF with Pillow; Movie mode runs on fixed frame time, so live xdotool input won't line up with it: clips drive input through `tests/ui/player_driver.gd` or a scripted state instead.
  - jump: open one of the ~55 named states `screenshot.gd` already has, so an agent can go straight to a scene. Replay jumps only if a needed scene is missing. Today `tests/ui/shots/screenshot.gd` saves one PNG per run and quits, so "jump to a state, then keep playing" is new work in step 0.
- Look sessions get their own Godot slot class, capped at one or two, so they don't block the gate (note 10a). The gate runs in the cloud during this phase.
- Optional: the owner can watch a live headless session through x11vnc over Tailscale.
- **Proof:** a fresh agent with no other context plays one recruit turn and one fight through clicks and screenshots alone, and reaches game-over from a jump, then reports what it noticed.

Already available: Xvfb, xvfb-run, xdotool, scrot, x11vnc, Pillow. Existing pieces to reuse: `tests/ui/player_driver.gd`, `render_screens.sh`, the `*_states.gd` scene scripts, the game logs and replays.

## Step 0b: reference library and layout options (runs alongside step 0)

**The owner's words (10 Nov):**
> "I want to ensure that there are agents who go and extract good quality images of TFT, the bazaar, battlegrounds, from videos at multiple different game states, and look at how they're laid out, their appearance, how they create the illusion of being in a real environment by being 3D compared to our kind of flat structure. Figure out good layout options for us that keep things simple. I think the bazaar does it the best in terms of just beautiful simplicity. Like the bazaar's UI, I think, is the benchmark to try and beat."

> "Additionally, I want to ensure that we capture the kind of Everdell-like butte *[probably "beautiful" or "cute"]* art style, kind of the beautiful forest and, you know, beautiful woodland areas kind of thing, kind of like almost an Ori and the Blind Forest-esque enchanted forest kind of world."

The existing comparison (`evidence/declutter/visual-comparison.md`) has no Bazaar, and its TFT PC entry is "from memory". This step replaces it with real frames.

**1. Capture (one Codex worker, on the Optiplex).** One worker writes one capture script and runs it for every game.
- **UI references:** The Bazaar (the benchmark), TFT, Hearthstone Battlegrounds. Galaxy reuses the existing Steam shots; no new capture.
- **World and mood references:** Ori and the Blind Forest / Will of the Wisps from video; Everdell from stills of its board-game art (its look lives in the illustrations, not in video).
- Sources: Steam trailers first, then 1080p+ YouTube gameplay (official trailers, developer streams, clean VODs without facecam or overlays). PC and mobile where both exist. Runs locally, since yt-dlp is often blocked from cloud addresses.
- **Game states:** a shared core for every UI game (menu, the main play screen empty and busy, hover or inspect of a card, a fight start, a fight's big moment, end of game), plus a short list per game: Battlegrounds and TFT add the recruit board mid-turn and full, scouting, deaths and a big late board; the Bazaar adds its own screens (the shop and event choices, the board and item layout, the fight). For the world references: wide scenery, a close scene with characters, light and atmosphere, and how characters sit in the scene.
- Frame picking: scene detection at each state, then the sharpest frame, duplicates dropped. Two or three frames per state.
- Tools: yt-dlp and ffmpeg, installed by the orchestrator (local admin, note 10e). If a download is refused or blocked, the worker reports it and moves to the next source.
- **Storage:** frames stay local in `docs/ideation/ui/reference/`, added to `.gitignore`, because they're other studios' images: for internal study, never shipped or traced. A manifest goes in the repo (game, state, source link, timestamp) so the frames can be fetched again.

**2. Breakdown (fresh agents reading the frames):** one each for the Bazaar, TFT and Battlegrounds, and one for Everdell and Ori together.
- A zone map on each key frame: where the board, shop, hand, HUD and opponents sit, and the share of the screen each takes.
- How simple it is: how many things are on screen at once, how much text, and what's hidden until hover.
- **How it creates depth and a sense of place:** camera angle and board perspective, shadows under pieces, lighting and vignette, layered scenery in front of and behind the board, materials, particles, and what moves when nothing is happening.
- For Everdell and Ori: palette, light (glow, light shafts, haze), layering from foreground silhouettes to soft background, and how a 2D picture reads as a deep, real place.
- **A Bazaar deep dive:** what makes it beautifully simple, and what it leaves out that we show.

**3. Our world: painted backdrops (one art worker, `tools/art/`).** Build 8 has no background art; it's flat tan. One batch of three or four recruit-board backdrops in the Everdell and Ori mood, starting from the folio's 17 woodland zone paintings (`docs/folio/art/web/zone-*.jpg`) and their prompts, with Ori frames as references. Each is composited behind real Ink-B units, so the owner can see whether the styles sit well together.

**4. Layout options (one design agent, then one fresh critic).** Starts once the Bazaar breakdown is done; it doesn't wait for the others.
- Three or four layout options for the recruit and fight screens, built from real build-8 screenshots (`render_screens.sh` works today) plus the painted backdrop layers. Any image made by the image model is labelled "concept".
- Each option keeps things simple, with the Bazaar as the bar. It names its depth technique (a skewed board, shadow sprites, parallax, or a 3D camera), what changes, roughly what it costs to build, and how it sits with the units' style.
- A fresh critic sets each option beside a Bazaar frame of the same state and says, in plain words, where it's simpler and where it isn't. No scores.
- **The owner picks one in the day-1 gallery.** It becomes a focus item. If the options run late, the gallery goes out with the references and the options follow.

**Proof:** each layout option shown on our real units with a painted backdrop, beside a Bazaar frame of the same state, with the critic's notes. Each reference frame in the gallery is sharp and free of overlays, with its source and timestamp.

**Open for the owner:** the units' style is "Ink + flat B" (1 Nov). Does the Everdell and Ori look apply to the world only (backgrounds, board, menus), with units kept as they are, or to the units too? Default: world only, units unchanged.

## How each loop runs

1. **Day 1 gallery (no code changes yet).** Agents play build 8 through `tools/look/` and build one page: our screens at both sizes beside the step 0b reference frames (the Bazaar, TFT, Battlegrounds, plus the Everdell and Ori world references) and the three or four layout options; short clips of a fight and a recruit turn; and the 5–8 biggest look-and-feel problems in plain words, listed beside the declutter spec's unbuilt batches 3 (HUD and lobby) and 4 (tutorial and Rules) and portrait. The owner picks two or three to work on.
   - **Where it lives:** a self-contained page with its images in `/data/bramble-gallery/<loop>/` on the Optiplex, served read-only to the tailnet by a `python3 -m http.server 8790 --bind 100.92.26.47 --directory /data/bramble-gallery` in tmux session `bramble-gallery`. Reference frames are fine there: it's private and not in git.
   - **How it reaches the owner:** the orchestrator posts the link (`http://100.92.26.47:8790/<loop>/`) in its chat with the owner and sends one contact-sheet image of the options.
   - **Picks come back by chat.** If the owner hasn't replied within 12 hours, the orchestrator starts on its own top two items and the layout closest to the Bazaar, logs that in one DECISIONS line, and switches if the owner later picks differently.
   - **Timing:** the gallery goes out at the end of day 0 with whatever exists. Anything not ready follows as an update.
2. **Build.** One worker per focus item, in its own worktree on an `ideation/ui-*` branch. Where there are two credible looks, both are shown as clips in the mid-loop gallery; at most one pair per loop ships behind a setting.
3. **Check each step:** the gate (tests, the 4-game UI run, the scope-fence check), one scope review against the owner's words and this plan, and fresh screenshots and clips at both sizes. Nothing else blocks a merge.
   - **Who reviews:** one review per step, by the `scope-reviewer` agent (the owner's global rule). When Claude usage is running short (note 10b), a fresh Codex review thread runs the same method instead; it's still one review. The author fixes its cut items, and the orchestrator checks the fix by reading the diff, with no second review. Ask items are the orchestrator's call, one line in DECISIONS. There are no review rounds.
   - **Focus items get a short brief, not a plan:** this plan has had its interrogation, so a focus item's brief doesn't get its own.
4. **Mid-loop gallery** to the owner: before and after shots and clips. The owner can redirect.
5. **End:** build N ships with what's ready and its variant settings, plus a one-page note: what changed, what to try, which settings to compare. The run stops for the owner's play.

**Done for a loop:**
> The owner has played its build and said what's next, or 3 days have passed since the day-1 gallery went out: then the build ships with what's ready and the loop stops.
> The build passed: the cloud gate, a 200-game soak, a 4-game UI run, the memory check and the export checks.
> The playtest guide says what changed, what to try and which variants to compare.

## Before it starts (owner)

0. **Decided (owner, 10 Nov): "Shelve it, UI now."** `archive/run1/plan-build9.md` (note 10i's balance plan) is shelved for this phase. This UI build gets its own number.
1. `archive/run1/PROCESS-PROPOSAL.md` is in use: items 1 and 3 were applied at the hand-over (run 1's docs archived, a one-page DECISIONS, the reading list below). N = 3 unless the owner picks otherwise.
2. The open scope calls run on these defaults unless overridden: N = 3 days, sound out, batch 4 (tutorial and Rules) in, PC landscape first, portrait later.
3. Optional but strongest input: play build 8 and note first impressions of look and feel.
4. Step 0b runs on the Optiplex: it installs yt-dlp and ffmpeg and downloads public gameplay videos (Steam trailers first). Frames stay local and are never shipped; a manifest in the repo lets them be fetched again.
5. A fresh orchestrator session runs this phase, not the Ideation 2 session.

## Rough timeline

- Day 0: step 0's tool and step 0b's reference library, in parallel; then the day-1 gallery with the layout options.
- Days 1–3, counted from the gallery: two or three focus items, a mid-loop gallery.
- Day 3 after the gallery (or sooner, if the owner plays): the UI build ships and the loop stops.
