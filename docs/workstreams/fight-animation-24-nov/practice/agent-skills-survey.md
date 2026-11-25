# Skills and tools for agents making animation: a survey (24 Nov 2026)

Step 1, third study, of `../PLAN-animation-practice.md`. The owner's question (24 Nov, dictated):

> "Are there skills out there for doing good animations, maybe on GitHub, for helping AI agents do it? Or is it better not to use those skills and just do it ourselves with some guidelines we make internally?"

## The short answer

**Write our own, and borrow a handful of parts.** Nothing out there fits Bramble whole. Most motion skills (the big, popular ones) were written for web and app UI. Their core numbers ("UI animations stay under 300 ms", "actions seen 100+ times a day get no animation") are right for a settings page and wrong for a fight, which is the show the player came to watch. The game-feel skills are written for games the player steers (platformers, shooters). None of them deals with our real problem: **the agent cannot watch the motion**. Our own film tool (`tools/feel`, true 60 fps, per-frame logs) and the OpenCV tracking already used in `../research/` go further than anything I found for checking motion.

What is worth taking, as ideas or as short adapted passages with credit (details in "What to take"):

1. **Godot pitfalls**, from `gamedev-skills/awesome-gamedev-agent-skills` (`game-feel`, `godot-animation`): how hit-stop interacts with `Engine.time_scale`, two tweens fighting over one property, `Container` children that snap back, `modulate:a`. These are correct, short and written for Godot 4.7 (we run 4.7.2).
2. **Casting a moment**, from Emil Kowalski's `choreograph`: give each moving thing a role (lead, support, decoration, still), then decide for each pair whether they move together, overlap or wait. This maps straight onto an attack, a trigger and a death.
3. **Game-feel checks**, from `ronniebasak/game-feel-skill` (a digest of Steve Swink's *Game Feel*): show the biggest change in the first frames, don't spend them on the wind-up; give deaths and failures the care players notice; **audit by subtraction** (turn each effect off; if nobody misses it, cut it or make it stronger); graph position against a reference game.
4. **A list of the agent's own failure modes**, the format of `kylezantos/design-motion-principles` "Creation gotchas": a short self-check list of what agents get wrong, written for us.

Not worth using: the video-watching skills (they sample at most 2 frames a second and throw away near-identical frames, which deletes exactly the holds and hit-stops we need to see), Godot MCP servers (our `tools/look` and `tools/feel` already do the part that matters), and every web-library skill (GSAP, Framer Motion, Remotion, Lottie, Rive).

## What Bramble needs from such a skill

Judged against these, not against general quality:

- **Watched motion, not steered motion.** The fight plays itself; the shop is drag and drop. Rules for "input to response under 100 ms" apply to the shop only.
- **Repetition with meaning.** An attack plays hundreds of times a game and must stay readable at speed, without being cut, because it is the content.
- **Frames, not milliseconds.** Our films, logs and specs count 60 fps frames (`../research/our-attack-measured.md`).
- **The glass look and quiet screens.** The owner wants quiet backgrounds and no dimming filters; any rule that asks for always-on ambient motion fights that.
- **A blind agent.** Rules must say how each one is checked from a film, a per-frame log or a chart, and what only the owner can judge.
- **Small context.** Agents already load project skills; a 4,000-word general skill crowds out the project's own rules.

## What exists

Stars and last push from GitHub on 24 Nov 2026. "Read" means I read the SKILL.md (and the files named), not only the README.

### Motion design skills (web and app UI)

| Name | What it does | Signs of use | Licence | Judgment |
|---|---|---|---|---|
| [LottieFiles/motion-design-skill](https://github.com/LottieFiles/motion-design-skill) | One skill, `motion-design` (~1,800 words plus 16 reference files): duration and easing tables, "motion personality" archetypes, Disney principles adapted for UI, stagger budgets, an emotion-to-motion map. Read: SKILL.md. | 3,629 stars, pushed 23 Nov 2026. By the Lottie company; suggests its own paid Creator MCP for file exports. | MIT | **Hurts if installed, teaches a little.** Tables are web UI in ms ("Modal 300–400 ms", "total stagger must stay under 500 ms"). One CRITICAL rule, "Always three motion layers: primary + secondary + ambient", fights the owner's quiet backgrounds. Worth reading once: its "material" table (glass: 0.9× duration, no overshoot; paper: 3–5 % overshoot) is a nice prompt for a glass game. |
| [emilkowalski/skills](https://github.com/emilkowalski/skills) | 20 skills by a well-known web design engineer (Vercel, Linear): `animate`, `review-animations`, `choreograph`, `improve-animations`, `remove-animations`, `animation-vocabulary`, and more. ~5,800 lines in all. Read: README, `review-animations`, `choreograph`, `animation-vocabulary`. | 59,130 stars, pushed 15 Nov 2026. The most used motion skills there are. | MIT | **Hurts if installed, one strong idea.** `review-animations` blocks any UI animation over 300 ms and says actions seen "100+/day get no animation": wrong for a fight. Everything is CSS and React. **`choreograph` is the best idea in the survey**: cast every moving element as lead, support, decoration or still; choose together, overlap or sequence for each pair; "good choreography is mostly about cutting moving parts"; vary stagger by importance, never uniform. Take the idea, not the text. |
| [kylezantos/design-motion-principles](https://github.com/kylezantos/design-motion-principles) | One skill with create and audit modes, weighting three named web designers' published views by project type; the audit writes an HTML report with looping demos. Read: SKILL.md, `creation-gotchas.md`, start of `anti-checklist.md`. | 1,645 stars, pushed 30 May 2026. | MIT | **Teaches the format.** Its "frequency gate" assumes a web product. Two useful things: a one-page **list of Claude's own failure modes** when writing motion ("don't animate just because you can", "don't give enter and exit equal weight", "match the codebase's existing conventions"), and an anti-checklist that flags a pattern only when it repeats ("finding the same pattern slapped across the codebase is the tell"). We should write our own version of both. |
| [iart-ai/motion-design-skills](https://github.com/iart-ai/motion-design-skills) | Nine skills for video motion graphics: principles, After Effects, Remotion, logo animation, beat sync. Read: `animation-principles`. | 270 stars, pushed 11 Nov 2026. | MIT | **Skip.** The principles skill repeats the LottieFiles text almost word for word (the same "three pillars" and "three layers"). Aimed at video and brand work. |
| [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | Official skills for the GSAP web animation library. Not read beyond the file list: API skills for a library we don't use. | 18,976 stars, pushed 29 Jul 2026. | MIT | **Not for us.** |
| [remotion-dev/skills](https://github.com/remotion-dev/skills) | Official skills for Remotion (React video rendering). File list only. | 7,895 stars, pushed 23 Nov 2026. | No licence file in the repo | **Not for us.** |
| Lottie and Rive skills ([uianimation/rive-skill](https://github.com/uianimation/rive-skill), [BowTiedSwan/rive-skills](https://github.com/BowTiedSwan/rive-skills), [b1rdmania/claude-lottie-skill](https://github.com/b1rdmania/claude-lottie-skill)) and Framer Motion skills (largest 13 stars) | API help for those tools. Not read. | 7–34 stars. | mostly MIT | **Not for us**: tools Bramble doesn't use. |
| [anthropics/skills](https://github.com/anthropics/skills) | Anthropic's public skills. No animation or motion skill; `slack-gif-creator` builds small GIFs frame by frame with easing helpers. | 199,577 stars. | per skill (Apache-2.0 for that one) | **Nothing to use.** |

### Game feel and Godot skills

| Name | What it does | Signs of use | Licence | Judgment |
|---|---|---|---|---|
| [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | 79 skills for 12 engines plus a router. Read: `disciplines/game-feel` (juice: trauma shake, hit-stop, squash and stretch, tiers of feedback per event), `godot/godot-animation` (AnimationPlayer, AnimationTree, tweens, with gotchas), the animation lines of `genres/card-game`. | 10,627 stars, pushed 12 Nov 2026; says it is checked against Godot 4.7.2 and that code examples were run on real engines. | Apache-2.0 | **Helps, in parts. The best source of Godot facts.** `game-feel` is engine code done right: hit-stop that survives two hits 30 ms apart, shake that decays in real time during hit-stop, "time scale does not slow audio in Godot", "snap to the rest value at the end of every effect", a headless check that time scale returns to 1.0. Its tier table (small, medium, large event → bundle of feedback) is a good shape for us, though its numbers are for action games. `godot-animation` gotchas are short and directly useful (tweens fighting, `Container` transforms, `modulate:a`); check each against the Godot docs before relying on it. Its card-game skill says almost nothing about animation. Do not install the router or the collection: most of it is other engines. |
| [ronniebasak/game-feel-skill](https://github.com/ronniebasak/game-feel-skill) | One skill (~1,800 words, three references) digesting Steve Swink's *Game Feel*: six layers (input, response, context, polish, metaphor, rules), hard latency limits, a verification checklist. Read: SKILL.md, `measurement.md`. | 1 star, pushed 21 Aug 2026. Little use, but the source book is the standard text. | MIT | **Teaches ideas; does not fit whole.** Written for games the player steers. Good for us: "deliver a large, obvious change immediately after input… front-load the response; never front-load the wind-up"; "invest in failure states… make deaths varied, physical and fun to watch" (the owner has flagged deaths); "audit by subtraction"; "graph position over time… against a reference game's" (what `../research/` already does); "measure, don't estimate: count frames at 60 fps". The latency limits (100 ms, 240 ms) fit our drag and drop. |
| [thedivergentai/gd-agentic-skills](https://github.com/thedivergentai/gd-agentic-skills) | 99 Godot 4.7 skills. Read: `godot-tweening` (decision table Tween vs AnimationPlayer, "NEVER" list, bundled scripts including a juice manager); skimmed `godot-genre-card-game`. | 992 stars, pushed 16 Oct 2026. | **LGPL-3.0** | **Teaches; don't copy code.** The tween rules overlap the gamedev-skills ones. "NEVER use linear interpolation for UI/juice" and "pile moves 0.2 s+" are blanket rules we'd want to set ourselves. LGPL makes copying its scripts into a shipped game a licence question; reading is fine. |
| [jame581/GodotPrompter](https://github.com/jame581/GodotPrompter) | Godot 4.x skills framework. Skimmed `tween-animation` (330 lines of Tween API). | 989 stars, pushed 14 Nov 2026. | MIT | **Skip.** An API manual; the Godot docs do this. |
| [MindsMaster/godot-claude-code-skills](https://github.com/MindsMaster/godot-claude-code-skills) | 18 Godot skills including `godot-animation` (300 lines). File list only. | 3 stars. | MIT | **Skip**: no signs of use. |
| Godot juice addons: [Kelpekk/Juicee](https://github.com/Kelpekk/Juicee) (174 stars, MIT, inspired by Unity's FEEL), [johnisking/gameshipkit-game-feel](https://github.com/johnisking/gameshipkit-game-feel) (0 stars) | Game code (shake, hit-stop, flash, knockback, number pops), not agent skills. Not read. | | MIT | **Not now.** Our fight motion is our own code (`FightMotion`); an addon adds a dependency for effects that are a few lines each. |

### Godot MCP servers (agents driving the editor or a running game)

| Name | What it does | Signs of use | Licence | Judgment |
|---|---|---|---|---|
| [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | Launch the editor, run the project, read its output. README read. | 6,748 stars, pushed 16 Apr 2026. | MIT | **Not needed**: our scripts already run Godot headless and read errors. |
| [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai) | 46 tools for a live editor: scenes, scripts, animation, particles. README start read. | 3,674 stars, pushed 24 Nov 2026. Anonymous telemetry, opt-out. | MIT | **Not needed.** Editor building, not motion checking; telemetry on by default. |
| [youichi-uda/godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) | 162 tools, including `record_frames`, `monitor_properties` (values over time), input recording and replay, `compare_screenshots`. README read. | 649 stars. | The server is a **paid** package; the repo holds only the free addon. | **Teaches that others want the same thing**, nothing more: `tools/feel` already records every frame at a true 60 fps with a pointer script, which a live-editor tool on a software renderer cannot. |

### Letting an agent watch video

| Name | What it does | Signs of use | Licence | Judgment |
|---|---|---|---|---|
| [bradautomates/claude-video](https://github.com/bradautomates/claude-video) (`/watch`) | Downloads a video, picks frames, transcribes speech; or sends the video to Google's Gemini model to watch. Read: SKILL.md. | 21,663 stars, pushed 25 Sep 2026. | MIT | **Hurts for animation.** Uniform sampling is capped at **2 frames a second**, and by default it removes near-identical frames ("A 16×16 RGB mean-difference pass removes near-duplicates"). A hit-stop or a 5-frame hold is exactly a run of near-identical frames. Made for talks and tutorials. |
| [jordanrendric/claude-video-vision](https://github.com/jordanrendric/claude-video-vision) | Plugin and MCP: `video_analyze` (ffmpeg scene, silence and motion filters), `video_watch` (frames at a chosen rate), `video_detail`. README read. | 1,535 stars, pushed 14 Oct 2026. | MIT | **Teaches one idea**: run cheap ffmpeg measures first to find where to look, then pull frames there. We can do this with plain ffmpeg (below) without a plugin. |
| [guimatheus92/mcp-video-analyzer](https://github.com/guimatheus92/mcp-video-analyzer), ffmpeg MCP servers ([video-creator/ffmpeg-mcp](https://github.com/video-creator/ffmpeg-mcp), 156 stars; [egoist/ffmpeg-mcp](https://github.com/egoist/ffmpeg-mcp), 122) | Transcripts, key frames, OCR; or ffmpeg behind MCP tools. Descriptions only. | 122–156 stars. | mostly MIT | **Not needed**: agents can call ffmpeg directly. |

### Measuring motion (libraries, not skills)

Nothing found packages motion measurement for agents. The building blocks:

- **ffmpeg filters**, installed here: `freezedetect` (finds holds and freezes, so it can confirm a hit-stop's length), `tblend=all_mode=difference` plus `signalstats` (how much changes each frame: a cheap per-frame "motion energy" curve), `mpdecimate` (lists duplicate frames), `scdet` (cuts and flashes), `mestimate` (block motion vectors), `ssim` (compare a film with a reference film frame by frame).
- **OpenCV** (template matching, optical flow): already used for `../research/` (normalised cross-correlation in a venv under `/data/fight-anim-ref/venv`). Not installed system-wide on this machine.
- What we have that nobody else offers: `tools/feel` films every frame at a true 60 fps however slow the machine, with press and release frames logged and per-frame strips. The agent skills above end their checks with "ask the user to play it and report" (gamedev-skills) or with a screenshot.

### Cursor rules and AGENTS.md

[PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) (41,180 stars, CC0): no rule file for Godot or animation; the game ones are Unity, GameMaker and an ASCII game. I found no published AGENTS.md with animation or game-feel guidance; Godot AGENTS.md files cover building and testing.

## What to take, and how

All of this goes into our own guidelines (step 2 of the plan), rewritten in our terms (frames, cards, the fight log, the glass look), with credit in the doc. Apache-2.0 and MIT allow copying with the licence notice; rewriting the idea needs no notice.

| Take | From | Becomes, for us |
|---|---|---|
| Hit-stop and `Engine.time_scale` pitfalls; shake that decays in real time; audio not slowed by time scale; every effect ends exactly at rest; check overlapping triggers | gamedev-skills `game-feel` | Godot section of our guidelines, plus headless asserts (time scale back to 1.0, scale back to exactly 1 after every pop) |
| Tween pitfalls: kill before re-creating, one owner per property, `Container` children snap back, tween `modulate:a` not `modulate` | gamedev-skills `godot-animation`, thedivergentai `godot-tweening` | Same Godot section; check each against the Godot 4.7 docs first |
| Feedback tiers: each event gets a tier, each tier a fixed bundle of effects, so the game stays in proportion | gamedev-skills `game-feel` | A tier table for our events (hit, big hit, trigger, buff, death, triple, damage to the player), with our own numbers from the craft research |
| Cast the moment: lead, support, decoration, still; together, overlap or sequence; cut moving parts; uneven stagger | Emil Kowalski `choreograph` | The "who moves" step of a timing spec for attacks, triggers and several deaths at once |
| Front-load the response; care for failure states; audit by subtraction; graph against a reference | ronniebasak `game-feel` (Swink) | Checks in our guidelines, each with how it's checked on film |
| A short list of agents' own motion mistakes; flag a pattern when it repeats | kylezantos "Creation gotchas" and anti-checklist | Our own list, filled from what went wrong on this track (from the inventory and the owner's reactions) |
| Find where to look with cheap measures before reading frames | claude-video-vision | A small step in our film review: ffmpeg `freezedetect` and per-frame difference on a film, then strips at those frames |

## What not to take

- **Duration caps in ms for UI** ("sub-300 ms", "stagger under 500 ms"): our long beats (triples, deaths, damage to the player) need room, and our unit is frames.
- **"Don't animate what is seen often"**: the fight is seen often because it is the game. Our answer to repetition is variation and a fast mode, not removal.
- **"Always add ambient motion"**: fights the owner's quiet backgrounds.
- **`prefers-reduced-motion` and hover-gating rules**: web mechanics. A game version (reduce shake, reduce flashing, the three-flashes-a-second limit) belongs in our accessibility skill instead.
- **Personas built on named designers' views** (kylezantos): fine for the web; we judge against the owner's taste and our references.

## Method and limits

- Searched GitHub (`gh search repos`, ~30 queries: game feel, juice, motion design, animation skills, Godot skills and MCP, tweens, Lottie, Rive, Framer Motion, GSAP, Remotion, After Effects MCP, video MCP, ffmpeg MCP, optical flow, hit-stop) and the web (skills.sh and other skill directories, Godot forum, Codex guides). Shallow-cloned 14 repos to `/data/fight-anim-work/skills-survey/` to read them; nothing was installed or run.
- Read in full: the SKILL.md of LottieFiles `motion-design`, kylezantos, ronniebasak, Emil `review-animations`, gamedev-skills `game-feel` and `godot-animation`, thedivergentai `godot-tweening` (first 90 lines), claude-video `watch` (frame handling). Read in part: Emil `choreograph` and `animation-vocabulary`, kylezantos references, ronniebasak `measurement.md`, iart-ai `animation-principles`. For the rest, the README or file list only, as each row says.
- Not checked: whether the Godot API details quoted (for example `offset_transform_enabled` on `Container` children in 4.7) are exactly right. Check them against the docs before they go into our guidelines.
- After Effects MCPs (largest [Dakkshin/after-effects-mcp](https://github.com/Dakkshin/after-effects-mcp), 921 stars) were found and not read: they need Adobe After Effects and make video, not game motion.
