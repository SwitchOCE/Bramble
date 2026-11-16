# Design lab learnings (3–4 Nov 2026)

Lessons from the design-lab night: what went well, what went wrong, and what to do next time. They are lessons, not decisions. The prototype stream's log is `docs/prototype/LEARNINGS.md` in the tag `archive/proto-2026-11-13` (was `proto/main`); the setup lessons there (Playwright on Ubuntu 26.04, the small machine, Codex) apply here too.

### 4 Nov 02:40 — What worked

**What happened:** eight generators, each building HTML mock screens from one shared `fixture.json`, then four blind judges with different personas scoring screenshots only. The judges agreed on the top two, and every judge named borrowable ideas from directions they ranked low.
**Why:** the same data on every screen made the directions comparable. Blind letters kept the judges from scoring names or notes. The personas (art director, casual phone player, Battlegrounds veteran, accessibility designer) pulled in different directions, so ideas that survived all four were strong.
**Next time:** keep the shared fixture and blind letters. Ask judges for a "steal" list as well as scores: it fed round 2 directly.

### 4 Nov 02:40 — Fixture drift costs judge time

**What happened:** small inconsistencies in the first fixture (a boar at 32 Health in one place and 26 in another; a unit in the wrong slot) showed up across directions and had to be fixed mid-round. The judge brief had to tell judges to ignore mock-data slips.
**Next time:** check the fixture against itself before any generator starts, with a short script that validates slot, stat and name consistency.

### 4 Nov 02:40 — Render tool setup

**What happened:** `tools/render.js` needs `PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64`, and `NODE_PATH` pointing at `~/.local/share/bramble-tools/node_modules`, on this machine. Generators that weren't told this lost time.
**Next time:** set both inside `render.js`, or in a wrapper script, so no brief has to repeat them.

### 4 Nov 02:40 — Screenshots can't show tapped states

**What happened:** round 2 added "full text on tap" slips. The render tool only loads a page, so the recruit shots show the slip closed, and judges would see it only where a cards page draws it open.
**Next time:** let `render.js` take an optional click selector, or a `?state=` query the page reads, so interactive states can be shot.

### 4 Nov 02:40 — Small-screen readability is the common failure

**What happened:** nearly every direction lost points on phone readability: tiny names, rules text cut off, low-contrast labels. The same problem then showed up in the Godot prototype, where card text on phone is about 7–9 px.
**Next time:** give generators a hard floor for phone text and touch targets (for example 11 CSS px text and 44 CSS px targets), and have the render tool flag text below it.

### 4 Nov 02:40 — Agent-drawn decoration needs a redraw hook

**What happened:** some directions draw trays, stitches and borders in JavaScript after layout. They go wrong if the layout changes after load, and one generator's broad CSS rule (`.wq-legend b`) restyled numerals inside stat beads elsewhere on the page.
**Next time:** scope CSS to the component, and redraw JS decoration on resize.

### 4 Nov 02:40 — Porting a mock into Godot

**What happened:** Folk Print went into the prototype as a switchable theme in about an hour, using data plus one theme builder, with no forked screens. The first port quietly changed the Plain look: a tier ring lost its gold and badges grew. A pixel diff in review caught it. A late-game test then found two-digit stats spilling out of the drawn heart and star, which the box-based layout check couldn't see.
**Next time:** when adding a theme, pin the default look with a test first. Check drawn shapes, not only boxes, for text fit.

### 4 Nov 03:00 — Round 2 copies carried stale data

**What happened:** one direction's round 2 `data.js` still had the boar at 32 Health and no Hornetling, values from before the fixture was fixed, because round 2 copied round 1's files rather than reading `fixture.json`. Round 3 caught it while building combat.
**Next time:** have every page load `fixture.json` itself instead of copying values into a per-direction `data.js`.

### 4 Nov 03:00 — Text-replace scripts hit phone-only rules

**What happened:** a generator's text-replace matched an indented copy of the same CSS rule inside the phone media query, and set a desktop font size on phone. Only the phone shot showed it.
**Next time:** edit CSS by selector and media block, not by matching text, and always look at the phone shot.
