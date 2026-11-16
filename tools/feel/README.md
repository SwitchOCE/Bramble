# Film a scene at a true 60 frames a second

`tools/feel/film` plays a scripted pointer scenario on any scene of this project and films it at
a true 60 frames a second, every frame, however slow the machine is. Use it to judge motion and
feel (a drag, a settle, a tween): things a screenshot or a real-time screen capture cannot show
on a machine without a GPU.

```bash
tools/feel/film tools/feel/demo/demo.json /tmp/demo.mp4     # the project's own size
tools/feel/strips /tmp/demo.mp4 /tmp/strips                  # a PNG strip per press and release
tools/feel/check.sh                                          # the tool's own check, ~15 s
```

`film` writes three files beside `out.mp4` (H.264, 60 fps, the project's viewport size):

- `out.events`, one line per press and release: `<frame> press|release <x> <y> <note>`, x and y
  in the film's pixels, the frame being the first one drawn after the event was sent (the scene
  handles it in that frame).
- `out.report.json`: what the scene reported at the end (see `feel_report` below), or `{}`.

`strips` reads the events and writes, for each one, the frames from 2 before to 21 after
(`--before`, `--after`), cropped round the pointer (`--zoom` for the tile size), each labelled
with its frame number, six to a row: read them to see a pickup or a release frame by frame.

`film` fails, writing no film, when the scene does not load, the scenario names a target the
scene does not know or a step it cannot read, the game logs any error, or the film does not hold
every frame the game drew.

## Why: an agent's view of the game draws a handful of frames a second

Agents look at the game under Xvfb with software OpenGL (Mesa llvmpipe, no GPU). The look tool
(`tools/look`, on the ideation branches, not on `main`) runs games that way. Measured on the
Optiplex (6 cores, no GPU), 17 Nov 2026, with the look tool's own settings (Xvfb,
`--rendering-driver opengl3`, 1920x1080, `--max-fps 30`), frames drawn over ten seconds of wall
time with a box moving across the scene (`count_frames.gd`, below), load average about 6:

| scene | frames in 10 s | frames a second |
|---|---|---|
| this tool's demo (two flat rectangles) | 300 | 30 (the cap) |
| the recruit screen (`tests/screens/recruit_mockup.tscn`, ideation branch only) | 41 | 4 |

The numbers move with the machine's load: a second run by a reviewer at load 13 got 23 frames
in 10.4 s on the recruit screen, and the demo below the 30 cap at load 10. The recruit-screen row
needs the ideation branch's glass screens and cannot be re-run on `main`.

The ideation branch's glass screens are drawn by shaders, in software here, so a real game screen
draws about 4 frames a second under Xvfb. A 0.2 s tween is then one or two drawn frames: a
screenshot catches whichever frame happens to be drawn, and a real-time capture (or a person
watching a look session) sees a jump, never the motion. Timing judged that way is wrong in both
directions: a card that floats for 300 ms may look like a snap, and a snap may look like a stall.

The fix is Godot's movie writer: with `--write-movie <file> --fixed-fps 60` the engine stops
following the wall clock. Every frame advances game time by exactly 1/60 s (process delta,
tweens, timers created from the scene tree, physics) and every frame is rendered and written,
however long it takes to draw. The film is what a player with a fast machine would see at 60 fps.
The demo films 126 frames (2.1 s) in about 7 s of wall time here; a 13 s scenario on the
recruit screen (ideation branch) takes about 3 minutes.

To re-run the table (any scene; add the moving box's frames per second by dividing by ten):

```bash
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
  --audio-driver Dummy --windowed --resolution 1920x1080 --max-fps 30 \
  -s res://tools/feel/count_frames.gd -- res://tools/feel/demo/feel_demo.tscn
```

## A scenario

A JSON file:

```json
{
  "scene": "res://tools/feel/demo/feel_demo.tscn",
  "steps": [
    {"move": "box:0", "time": 0.3},
    {"press": true, "note": "red pickup"},
    {"move": "place:0", "time": 0.4},
    {"release": true, "note": "red drop"},
    {"wait": 0.15}
  ]
}
```

- `scene`: the scene to open (`res://`); empty or absent means the project's main scene.
- `move`: the pointer to a target in `time` seconds, eased in and out, along a slight arc, one
  mouse motion event a frame (button held while pressed).
- `press`, `release`: the left button, where the pointer is. `note` names it in the events file
  and in the strip's file name.
- `wait`: seconds of nothing.
- A target is `"x,y"` in the scene's own pixels (the viewport's canvas; the tool converts to
  window pixels when the window stretches it), or a name the scene resolves: when the scene's
  root node has `feel_point(name: String) -> Variant`, the tool asks it, and it answers a
  `Vector2` in canvas pixels or `null` for a name it does not know (the film then fails). Either
  may end in `+dx,dy`.

Two more optional methods on the scene's root node:

- `feel_setup(scenario: Dictionary)`: called once, after the scene has drawn five frames and
  before the first step, for a scene that needs a state built before filming (from extra fields
  of the scenario). Nothing on `main` uses it yet; the ideation branch's game scenarios do.
- `feel_report() -> Dictionary`: called after the last frame; written to `out.report.json`. The
  demo reports where each rectangle ended, and `check.sh` uses that to prove the input reached
  the scene, not only that frames were filmed.

The film starts with those five frames and ends half a second after the last step.

## How it works

`film` runs Godot under `xvfb-run` (its own virtual display; it needs no other tool of this
repo), with a window of the project's viewport size (`--size WxH` to change the window; the film
stays the project's size), the OpenGL renderer, no sound, `--write-movie <work>/film.avi
--fixed-fps 60` and `-s res://tools/feel/feel_runner.gd`, which opens the scene as the running
game would (it becomes `current_scene`), draws the pointer (`feel_pointer.gd`) on a canvas layer
above everything, and sends the scenario's input through `Input.parse_input_event`, so the scene
gets it as it would get a real mouse's. Then ffmpeg turns the movie writer's MJPEG AVI into
H.264 (`-crf 18`). The AVI is written to a work folder under `${FEEL_TMP:-~/.cache/bramble-feel}`
(about 0.3 MB a frame at 1920x1080) and deleted after.

## What it cannot do

- **The film is the project's size**, not the window's or the screen's.
- **The 15-minute cap throws the whole film away.** A heavy screen renders at roughly 4 film
  frames a second of wall time here (the recruit screen, ideation branch), so the cap is about
  60 s of film on such a screen (an estimate from one 13 s film taking about 3 minutes). Film
  long journeys in parts.
- **Compressed twice** (MJPEG in the movie writer, then H.264), so it is for watching motion,
  not for pixel comparison.
- **The pointer path is synthetic**: eased moves, one event a frame, no jitter. Input lag,
  dropped input and hitches on a real machine cannot show.
- **No sound.** The audio driver is Dummy, so a film is silent.
- **No real input devices.** Only the left button and pointer motion, sent as events: no
  keyboard, wheel, right button, touch or controller (easy to add as steps when needed). Code
  that polls the device itself (`Input.is_mouse_button_pressed`, `get_global_mouse_position`
  read outside events, the OS cursor) probably sees nothing or a stale position: untested.
  Godot's own drag and drop (`_get_drag_data`) has not been tried.
- **Wall-clock time is not film time.** Anything timed by `Time.get_ticks_msec()`,
  `OS.get_unix_time()` or a thread runs at the machine's speed, not the film's: under a slow
  render it races ahead of the picture. Tweens, `_process` delta, `SceneTreeTimer` and
  animations follow film time.
- **Not the real renderer.** Software OpenGL (Compatibility) under Xvfb: shaders and colours
  should match a desktop's Compatibility renderer, but GPU-specific bugs, Forward+ or Mobile
  renderers, HDR and the real frame rate on a player's machine are not filmed.
- **No window events.** No resize, focus loss or pointer leaving the window.

## Needs

`godot` (the version in `tools/versions.env`), `xvfb-run` (package `xvfb`), `ffmpeg` and
`ffprobe`, Python 3 for `strips`. `ffmpeg` is not installed in CI or the cloud sessions and is not
pinned in `tools/versions.env`. `check.sh` exits 77 (skipped, not passed) with one line saying
which is missing where `xvfb-run`, `ffmpeg` or `ffprobe` is.
