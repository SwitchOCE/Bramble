# Film a scene at a true 60 frames a second

`tools/feel/film` plays a scripted pointer scenario on any scene of this project and films it at
a true 60 frames a second, every frame, however slow the machine is. Use it to judge motion and
feel (a drag, a settle, a tween): things a screenshot or a real-time screen capture cannot show
on a machine without a GPU.

```bash
tools/feel/film tools/feel/demo/demo.json /tmp/demo.mp4          # 1920x1080 by default
tools/feel/film my-scenario.json /tmp/out.mp4 --size 1280x720
tools/feel/strips /tmp/out.mp4 /tmp/strips                        # a PNG strip per press and release
tools/feel/check.sh                                               # the tool's own check, ~10 s
```

`film` writes `out.mp4` (H.264, 60 fps) and `out.events`, one line per press and release:
`<frame> press|release <x> <y> <note>`, x and y in the film's pixels, the frame being the first
one drawn after the event was sent (the scene handles it in that frame). `strips` reads those
and writes, for each one, the frames from 2 before to 21 after (`--before`, `--after`), cropped
round the pointer (`--zoom` for the tile size), each labelled with its frame number, six to a
row: read them to see a pickup or a release frame by frame.

## Why: a look session draws a handful of frames a second

Measured on the Optiplex (6 cores, no GPU; Mesa llvmpipe software OpenGL), 17 Nov 2026, a box
moving across the screen on top of the scene, frames drawn over ten seconds of wall time, with
the look tool's own settings (Xvfb, `--rendering-driver opengl3`, 1920x1080, `--max-fps 30`),
load average about 6 at the time:

| scene | frames in 10 s | frames a second |
|---|---|---|
| this tool's demo (two flat rectangles) | 300 | 30 (the cap) |
| the recruit screen (`tests/screens/recruit_mockup.tscn`, an ideation branch) | 41 | 4 |

The glass screens are drawn by shaders in software, so a real game screen draws about 4 frames
a second under Xvfb here. A 0.2 s tween is then one or two drawn frames: a screenshot catches
whichever frame happens to be drawn, and a real-time capture (or a person watching a look
session) sees a jump, never the motion. Timing judged that way is wrong in both directions: a
card that floats for 300 ms may look like a snap, and a snap may look like a stall.

The fix is Godot's movie writer: with `--write-movie <file> --fixed-fps 60` the engine stops
following the wall clock. Every frame advances game time by exactly 1/60 s (process delta,
tweens, timers created from the scene tree, physics) and every frame is rendered and written,
however long it takes to draw. The film is what a player with a fast machine would see at 60 fps.
The demo films 126 frames (2.1 s) in about 7 s of wall time here.

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
- A target is `"x,y"` in the scene's own pixels (the viewport's canvas: with a stretch mode the
  tool converts to window pixels), or a name the scene resolves: when the scene's root node has
  `feel_point(name: String) -> Vector2` (canvas pixels), the tool asks it. Either may end in
  `+dx,dy`.
- When the scene's root node has `feel_setup(scenario: Dictionary)`, it is called once, after
  the scene has drawn five frames and before the first step: a scene can set up its state from
  extra fields of the scenario.

The film starts with those five frames and ends half a second after the last step.

## How it works

`film` runs Godot under `xvfb-run` (its own virtual display; it needs no other tool of this
repo) with the OpenGL renderer, no sound, `--write-movie <tmp>.avi --fixed-fps 60` and
`-s res://tools/feel/feel_runner.gd`, which opens the scene as the running game would (it becomes
`current_scene`), draws the pointer (`feel_pointer.gd`) on a canvas layer above everything, and
sends the scenario's input through `Input.parse_input_event`, so the scene gets it as it would
get a real mouse's. Then ffmpeg turns the MJPEG AVI into H.264 (`-crf 18`). Game errors in the
log are printed after the run. It gives up after 10 minutes.

## What it cannot do

- **No sound.** The audio driver is Dummy, so a film is silent.
- **No real input devices.** Only the left button and pointer motion, sent as events: no
  keyboard, wheel, right button, touch or controller (easy to add as steps when needed). Code
  that polls the device itself (`Input.is_mouse_button_pressed`, `get_global_mouse_position`
  read outside events, the OS cursor) sees nothing or the old position; Godot's own drag and
  drop (`_get_drag_data`) has not been tried.
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
`ffprobe`, Python 3 for `strips`. `check.sh` skips with a note where `xvfb-run`, `ffmpeg` or
`ffprobe` is missing.
