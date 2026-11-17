# Look at and play a Godot scene headlessly

`tools/look/look` lets an agent run any scene of this project on a virtual display (Xvfb), take
screenshots, click, drag and press keys, and read the game's errors. Work in a
**shot, look at the PNG, act, shot** loop. Pixels in a screenshot are the `x y` input
coordinates, from `(0, 0)` at the top left. No desktop or window manager is needed.

```bash
tools/look/look start                      # the main scene at PC size (1920x1080); prints a session ID
tools/look/look start --scene res://tests/look/look_demo.tscn --size 1280x720
tools/look/look shot before                # prints the PNG path; open it with your image viewer
tools/look/look click 960 540              # left click; find targets in YOUR shot
tools/look/look move 840 350               # hover
tools/look/look drag 800 350 800 570       # press, move in steps, release
tools/look/look key Escape                 # X keysyms or chords: space, Return, ctrl+a; several press in turn
tools/look/look shot --wait 1.5 after      # wait first, e.g. for an animation to finish
tools/look/look errors                     # the game's errors and warnings so far, with backtraces
tools/look/look log -n 80                  # the end of the game's full log (prints and errors)
tools/look/look list                       # live sessions: ID, display, size, scene, worktree
tools/look/look stop
```

Sizes: `--size pc` (1920x1080, the default) or any `WIDTHxHEIGHT`.
A shot's pixels are always the screen's: what you click is what you see. The scene itself is laid
out at the design size in `project.godot` (`display/window/size/viewport_width` and `_height`)
and scaled to the window by the project's stretch settings, so a shot at that size shows the
design's own pixels and other sizes show it scaled.

**For motion and feel, film it: `tools/feel/film`** (tools/feel/README.md). A look session draws
about 4 frames a second on a real game screen here (software OpenGL; measured on the ideation
track's recruit screen), so its shots and anything watched
in real time cannot show a drag, a tween or a settle; the film tool renders every frame at a fixed
60 fps.

## What it reports

- `start` waits until the scene has drawn its first frames (60 s at most, `--timeout` to change).
  A scene that does not exist or does not load, or a game that quits or crashes while starting,
  makes `start` fail at once with the reason and the log's errors. Errors logged while the scene
  started (a script error in `_ready`, say) are printed, and the session still starts.
- After a start, any command fails with the reason when the game has quit or crashed, such as
  `session ... ended: the game exited with code 3`. Godot takes a moment to quit, so the command
  that caused it may still succeed; the next one says so.
- `errors` prints each `ERROR`, `WARNING`, `SCRIPT ERROR`, parse error and crash line in the game's
  log, the same lines `scripts/godot_log.sh` counts in the quality gate, with the `at:` and
  GDScript backtrace lines under each. It works after the game has ended too: it reads the live
  session, or else the latest one (`--session ID` for an older one). One line is left out: Xvfb's
  "Could not set V-Sync mode" warning, which comes from the virtual display, not the game.

## How it works

`start` runs Godot with `--script res://tools/look/look_runner.gd`, which opens the scene the
way the game would (it becomes `current_scene`) and signals ready after ten frames. Godot runs
in debug mode at 30 fps with the OpenGL renderer and no sound, under a 3 GB memory cap where
`systemd-run --user` works. Input goes through `xdotool`; shots are taken with `scrot`.

At most **four** look games run on the machine at once, whatever the worktree, each capped at
3 GB; a fifth `start` waits for one to stop, up to its timeout. The quality gate's own demo
(`scripts/check.sh` sets `BRAMBLE_LOOK_SLOT=gate`) has a separate lock, so agents' sessions never
make the gate wait or fail; gate demos take turns on that one lock. A live session that gets no
commands for 30 minutes closes itself.

With two live sessions, name one: `tools/look/look --session ID shot` (or
`export BRAMBLE_LOOK_SESSION=ID`). Otherwise commands use the only live session.

## Where output goes

Outside Git, in `${XDG_STATE_HOME:-~/.local/state}/bramble/look/<session>/`, or
`/tmp/bramble-look-<uid>/` if that is not writable. Set `BRAMBLE_LOOK_DIR` to use another folder,
and keep it set for every command. Each session folder holds the shots (`001-before.png`,
`002-after.png` and so on), `game.log`, `xvfb.log`, `supervisor.log` and the game's `user://`
data. `stop` keeps them. Each `start` deletes stopped session folders older than 7 days.

## Needs

`godot` (the version in `tools/versions.env`), `Xvfb`, `xdotool`, `scrot` and Python 3. All are
installed on the Optiplex. A fresh checkout must be imported once: `godot --headless --import`
(`scripts/check.sh` does this).

## Proof

`tools/look/demo.sh` drives `tests/look/look_demo.tscn` (a button that counts presses, and keys
that log on purpose) through the whole loop in about twenty seconds here: start, shot, click the button,
shot, read the click in the log, press E and read the pushed error, press Q and see the quit
reported, and see a missing scene fail. It prints both screenshot paths; the first shows
"Not pressed", the second "Pressed 1 time". `scripts/check.sh` runs it as its `look` step, and
reports that step as skipped, not passed, where Xvfb, xdotool or scrot is missing (as in CI today).

Dropped from the first run's tool (tag `archive/branches/ideation/main`): its jump states into
that game's screens, and its movie clips, which were tied to that game's UI.
