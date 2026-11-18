# Triple animation — brief 5

Review the films before judging the feel. Automated checks can establish state, input delivery,
frame counts and drawn movement; they cannot establish that this is as exciting as the references,
or reveal a reference game's internal input lock from a recording.

Media lives in Cloudflare R2 at `media/triple/`.
Reference seconds below are relative to the cut clips, viewed as **10 fps overview frames and
12 fps timestamped detail frames** (about ±0.083 s precision). The reference files were read
from `night-18-nov-93aa9a/docs/design/reference-clips/`, as authorised in the brief.

## Beat comparison

| Reference | Beats visible in the cut | Bramble's corresponding beats |
| --- | --- | --- |
| `triple-bg-wolfgang-1` (4.50 s) | Third purchase, 0.42–1.00; cyan identity/glow and copies gathering, 1.08–1.25; concentrated white flash, 1.33–1.58; gold resolves and flies down, 1.67–1.92; golden in hand/hover reveal by 2.08. No reward in this cut. | Three actual drawn copies lift, gather with trails and compress; cream flash with amber rays; enlarged golden resolves, then follows a curved path into the hand. No reward is invented at merge. |
| `triple-bg-wolfgang-2` (7.20 s) | Begins with an editorial normal/golden comparison and a cut into a merge already flashing (0.08); golden lands by 0.42; hover 0.67–0.83; golden dragged/played 1.00–1.33; gold play glow and Triple Reward visible 1.50–1.92; reward held/hovered, then dragged/cast 5.33–5.67; Discover expands 6.08–6.42. The gather is missing from the edit. | `reward.mp4` includes our whole merge, golden play, the **actual core's** reward in hand and casting it to open Discover. Reward/Discover use the existing UI, not a fabricated final animation beat. |
| `triple-tft-redox-1` (3.804 s) | Shop purchases around 0.67/1.17; newly bought bodies/blue travel, 0.75–1.50; local cyan/white concentration, 1.58–1.83; upgraded body resolves, stars visible by 2.17 and cyan afterglow clears around 2.67; later editorial transition to another upgrade near 3.5. Tooltip changes while this runs. | Purchase source follows its current dropped pose, existing owned copies join it, three become one in a local burst, then the stronger unit resolves. Bramble returns it to hand rather than retaining a TFT board body. |
| `triple-tft-redox-2` (6.106 s) | Blue converging energy around 0.83–1.17; warm charge intensifies 1.33–2.67; large gold/white burst and vertical shafts 2.75–3.33; three stars and gold body visible about 3.67; gold afterglow decays through 4.67. A tooltip opens at 2.25 while charging. | Warm compression, brief bright flare, radial rays, enlarged golden and landing halo. Bramble omits TFT's vertical beam and star count: it has one golden step, and the existing golden rim remains a stand-in. |
| `golden-vs-normal-bg-wolfgang-1` (2.50 s) | Hover/blur transition 0.00–0.33; editorial side-by-side normal/golden cards from 0.42. Shows double stats and stronger rim; **not a combining animation**. | Side-by-side review pairs this still comparison with our merge/reveal. Our golden doubles stats through the core, with its existing stand-in look unchanged. It is not evidence that Bramble's golden art matches BG. |

## Chosen motion and pace comparison

All tuning, including both filmed paces, is in
`src/screens/recruit/recruit_triple_motion.gd`. At the brisk pace the seven beats are:

| Beat | Frames after merge | Seconds |
| --- | --- | --- |
| Lift / identify three sources | 0–14 | 0.000–0.233 |
| Accelerating gather | 14–36 | 0.233–0.600 |
| Compress / build light | 36–50 | 0.600–0.833 |
| Local cream flash / rays | 50–58 | 0.833–0.967 |
| Enlarged golden reveal | 58–78 | 0.967–1.300 |
| Curve into authoritative destination | 78–98 | 1.300–1.633 |
| Landing halo clears | 98–108 | 1.633–1.800 |

`brisk.mp4` and `ceremonial.mp4` use identical pointer scripts and state, with only the pace
changed (1.80 s versus 2.16 s). `pace-candidates.mp4` puts them side by side at original speed.
The brisk pace is the current choice; see `taste-triple.md` for the recorded taste call.

## Input blocking measurements

A video cannot show whether an action would have been rejected when nobody tried it. The table
therefore measures the **visible transformation interval**, a conservative upper bound for a
merge-only wait, and separately records actual visible input response. It does not mislabel
an effect's afterglow as a proven global input lock.

| Clip | Visible merge interval (12 fps samples) | Evidence about input |
| --- | --- | --- |
| BG 1 | 1.08–2.08, about **1.00 s** (purchase-to-hand envelope 0.42–2.08, 1.66 s) | Hover on the golden responds at 2.08. No attempted action during merge is visible, so exact lock is unknown. |
| BG 2 | Cut starts mid-flash; visible tail 0.08–0.42, **0.34 s** | Hover responds by 0.67, golden play begins by 1.00. Full merge duration cannot be recovered from this cut. |
| TFT 1 | 0.75–2.67, about **1.92 s** including cyan afterglow | Shop tooltip changes around 1.67 during the transformation; global pointer interaction is live. Exact action lock unknown. |
| TFT 2 | 0.83–4.67 including afterglow, about **3.84 s**; body/stars resolve by 3.67 (2.84 s) | Tooltip opens at 2.25 during charge; board drag visible by 5.0. The long effect is not a demonstrated global lock. |
| Golden/normal | No merge | Editorial still, cannot measure a lock. |
| Bramble | **1.80 s**, destination reached after **1.633 s** | Each tested mouse/key press finishes only the triple layer before normal handling. No measured latency value is claimed; the film records event frames, not a fixed input-lock number. |

The longest reference visible envelope is 3.84 s (TFT 2); Bramble's whole presentation is shorter.
There is no timer or action queue in the triple input path: a press calls the triple helper's
`finish()` and then continues through the normal handler. Tests exercise the same Refresh click
at eight beat positions, immediate golden play, and keyboard input; separate tests ensure the
press does **not** settle an unrelated card's flight. `interrupt.mp4` records a real Refresh
press/release at frame 46 after formation at frame 40; both actions reached the core. That is
functional/event-frame evidence, not a measurement of physical input latency. The former fixed
`added_input_lock_seconds` report field was removed in PR 126 review because it measured nothing.


## Core destinations and the known reward gap

- **7.3.1:** a normal triple is in hand immediately in the core; the presentation ends on that
  actual hand card. Consumed board slots become empty. Dropping the third shop copy onto an
  empty board slot still leaves the golden in hand; it is never auto-played.
- **7.3.7:** when all three copies were on the board and the hand is full, the core places the
  golden in the first vacated slot in reading order. The presentation uses the actual target
  transform and ends there. The screen test exercises slots 2/5/6 and verifies slot 2.
- **7.3.6 gap preserved:** ordinary hand triples set `from_triple`; playing that golden adds the
  Triple Reward. The rulebook requires the reward when the triple forms and nothing more on
  golden play. `reward.mp4` deliberately shows the existing play-time behavior. In the full-hand
  board fallback the core attempts the reward immediately into the full hand and loses it.
  This branch changes no core reward rule and adds no audio.

Sources already drawn on the screen retain their real card data and transformed positions,
rotation and size. This includes the **selected Discover option**, at its enlarged option size:
the pick event identifies it before layout removes the picker. Unchosen options are not sources.
Drawn entries supply the starting card data. For new arrivals the adapter retains full unit log
snapshots when available (for example a summon). The latest absolute buff/stat updates by UID
override older numbers, including those on copies drawn before the action. A buy/pick/gain event
carrying only an ID identifies the selected option/offer or supplies its normal definition. If
there is no drawn source or full snapshot, unknown fields come from that normal definition,
including normal text/keywords; they are never copied from the combined golden or inferred by
halving it. Absolute stat updates are still used when the rest of the source data is unknown.
Every genuinely unseen source starts **at that run's own gathering point**, assigned after all
simultaneous runs are counted; it does not fly from a fabricated screen-centre location. Review film
reports label `origin` and `stats_from` so logged, drawn and definition-only data can be distinguished.

Counter-arrival redraws rebind the golden target while preserving the presentation's age and
copies. Unrelated state updates keep it running when its card entry and destination are unchanged.
Changing that golden's data or place ends the old presentation; a genuinely new formation starts
a new presentation, while repeating an event does not start a second animation. Press completion affects only this triple layer, leaving unrelated keeper
motions to the existing input behavior.


## Reproduction and shared files

From this worktree, use `LP_NUM_THREADS=2`, the shared `/tmp/bramble-n18-godot.lock`, and
`tools/feel/film tests/screens/feel/triple-brisk.json <outside-git>/brisk.mp4`.
The other scenarios are `triple-ceremonial.json`, `triple-reward.json`, and `triple-interrupt.json`.
Set `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `FEEL_TMP` to task-specific `/tmp`
folders. Compare with ffmpeg `hstack`, preserving original playback speed and holding the shorter
panel's last frame; reference frames duplicated to 60 fps do not create new source information.

Shared production files touched: **`src/screens/recruit/recruit_screen.gd`** (lifecycle/input
hooks only) and **`src/game/view_adapter.gd`** (human triple UIDs, arrival snapshots and normal-definition presentation data; no core log changes). No keeper, card look,
core rule, keyword or duplicate-glow implementation is changed. The standalone motion helper,
its tests and film fixture are new files.

## Review files and drawn evidence

- `brisk.mp4` / `ceremonial.mp4`: 225 frames each, true 60 fps, 1920 × 1080. Both end with
  golden Brock Cub UID 4 in hand, an empty board and no active triple presentation.
- `reward.mp4`: 360 frames, 60 fps. Golden play is frame 232 (3.8667 s); reward cast is frame
  298 (4.9667 s). The final report has golden Brock Cub in slot 2 and three Discover options.
- `interrupt.mp4`: 96 frames, 60 fps. Merge at frame 40 (0.6667 s); Refresh press/release at
  frame 46 (0.7667 s). Both actions reach the core, after only six active presentation samples.
- `pace-candidates.mp4`: both paces, original speed, with clocks; the shorter panel holds its
  final frame when needed. Nominal times are 1.80/2.16 s; process reports have 109/130 active
  samples respectively, within one 60 Hz frame of the configured duration.
- `vs-triple-bg-wolfgang-1.mp4`, `vs-triple-bg-wolfgang-2.mp4`,
  `vs-triple-tft-redox-1.mp4`, `vs-triple-tft-redox-2.mp4`, and
  `vs-golden-vs-normal-bg-wolfgang-1.mp4`: all five requested references beside our 60 fps
  film, made with ffmpeg **hstack**, 3840 × 1080 at 60 fps. BG 2 uses our complete reward film.
  Reference playback speed is preserved; clocks are clip time, not aligned transformation onsets.
- `references/`, `reference-frames/`: copied source cuts and the 10/12 fps frames inspected.
  `brisk-frames-*`, `ceremonial-frames-*`, and `reward-frames-*` are our timestamped 12 fps sheets.
- `media-manifest.json` checks all ten review films' rates, dimensions and decoded frame counts.
  `drawn-motion.json` compares seven actual frames across gather/compress/flash/reveal/landing,
  in an 800 × 740 crop excluding the scripted pointer. Every consecutive sample exceeds the
  1,000-pixel change threshold (RGB-channel difference >16). The same check rejects an
  intentionally frozen sequence. The cards, flash and landing are also visible in the inspected
  frames: this is not only a test of a changing node property.

`compare.py` and `validate.py` beside the media reproduce the hstacks/manifest and the drawn-pixel
check (ffmpeg/ffprobe and NumPy required). No movie or frame sheet is committed to Git.

## Original validation at `8abcfae1`

`./scripts/check.sh` passed **all 12 steps** on this branch with `LP_NUM_THREADS=2` under the shared
Godot lock. Compilation: **381 scripts, zero failures**. GUT: **757 tests in 51 scripts, 12,352
assertions**, all passing with no risky/pending tests. The 11 new recruit triple cases cover the
hand and full-hand destinations, deferred buy drawing, eight interruption points, immediate
play, Tab, hover, repeated events, ordinary golden gains, identical shop offers and simultaneous
triples. The film tool's own check drew all **126 frames at 60 fps** and completed its drag/drop.
The 10-game gate soak and 5-game shipped-content soak each reported **zero violations**; all
**six planted faults** made the soak fail as expected. Exact replay matched **two games, 30 turns,
90 checkpoints**; the changed-action fault was caught at turn 2. `check.log` beside the media is
the gate's result log; `media-manifest.json` and `drawn-motion.json` hold the separate film checks.
The final drawn comparison ranges from **52,608 to 109,796 changed pixels** per consecutive beat
sample; the frozen-sequence fault is rejected.

What these checks cannot judge: the owner's sense of excitement, real GPU frame pacing and
physical input latency. The references do not expose their internal input-lock timers. Where neither a drawn entry nor a full arrival snapshot exists, the normal-definition stand-in
cannot reconstruct unlogged effect/buff history. The two pace films and
all five hstacks are review material, not a claim that an agent proved equal aesthetic quality.
The existing golden appearance and the known core reward timing gap remain as described above.

## PR 126 review films and regression evidence

The review films are in `media/triple/review-126/`, in Cloudflare R2 under `docs/workstreams/night-18-nov/`.
Their source scenarios are `tests/screens/feel/triple-full-hand.json` and `triple-discover.json`.
The former holds the real core's summon/end-turn settlement on the recruit screen so the
controller does not replace it with combat; this is a rule-edge film fixture, not a new player
command. It logs the actual summon view, combines three board copies with a full hand and ends
on golden Brock Cub in slot **2**, with all **seven** hand cards retained. The new third copy
starts at its own hub `(960, 570)` with the logged **2 Attack / 6 Health**.

The Discover film clicks the actual left option. Its source is `(674, 470)` at **1.4×** scale,
not a fabricated position near the centre. It ends with the golden in hand. During gather the
fixture calls `RecruitCounts.arrived()`: at **0.7333 s** the helper's age is **0.35 s** before and
after the redraw, and it remains active. The subsequent flash, reveal and landing are drawn.

Both were filmed with `tools/feel/film`, `LP_NUM_THREADS=2`, and the shared Godot lock:

| Film | Frames / rate | Consecutive beat samples: changed pixels (>16 RGB-channel difference) | Card texture: reveal / landed |
| --- | --- | --- | --- |
| `full-hand.mp4` | **210 / 60 fps**, 1920 × 1080 | **52,711–80,548** | **2,321 / 3,149** pixels |
| `discover.mp4` | **213 / 60 fps**, 1920 × 1080 | **52,673–109,042** | **2,271 / 2,997** pixels |

`validate.py` beside the films reproduces `drawn-evidence.json`. It compares seven rendered
frames per path in a 1000 × 760 crop excluding the pointer, and also checks colourful high-contrast
card texture in fixed reveal/landing crops. The Discover source has **4,218** such pixels in its
expected upper-art crop after lift, excluding the lower board copy; this would fail if it started
at the hub or never drew. Intentionally frozen sequences and blank card crops are rejected. A real empty window crop
at the Discover source frame has **zero** textured pixels and is also rejected, even while the
rest of the animation runs.
Timestamped 12 fps frame sheets were also inspected: all three sources, the golden reveal, and
the two different destinations are visible. The JSON includes hashes, decoded frame counts,
source data/pose provenance and the redraw event; node property changes alone are not the proof.

The former constant `added_input_lock_seconds` was deleted from the fixture and the four
original stored reports. It was not a measurement. The functional input tests and real event
frames above remain the evidence for same-press completion; physical input latency is unmeasured.

Review validation: the focused triple suite passed **18/18 tests, 159 assertions**. The new cases
cover counter-arrival redraws, repeated state/event delivery without replay, mouse/key completion
while an unrelated card keeps flying, the Discover option's real pose/size, latest absolute stats
for drawn and unseen copies, two unseen copies starting at their separate triple hubs, and
ending an obsolete presentation when the golden changes. `./scripts/check.sh` then exited **0**
with **all 12 steps passing**: **381 scripts** compiled, **764 tests / 12,406 assertions** passed,
the film check drew 126/126 frames, both soaks had zero violations, all six planted soak faults
were caught, and exact replay matched two games / 30 turns / 90 checkpoints (the changed-action
fault was caught at turn 2). `review-126/check.log` and `focused-tests.log` hold these results.
