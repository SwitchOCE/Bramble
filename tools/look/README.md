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
3 GB; a fifth `start` waits for one to stop, up to its timeout. `BRAMBLE_LOOK_SLOT=gate` takes a
separate lock instead, for anything that must never wait on agents' sessions. A live session that gets no
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
(`scripts/check.sh` does this). The compare also needs Pillow and Playwright's headless Chromium
shell (both on the Optiplex).

## Compare with a mock-up page

`tools/look/compare.py` shoots a scene and an HTML mock-up page at the same size and says how far
apart they are, over the whole screen and region by region.

```bash
python3 tools/look/compare.py res://tests/look/compare_demo.tscn tests/look/compare_demo.html --size 1280x720
python3 tools/look/compare.py res://src/screens/recruit.tscn docs/mockups/recruit.html --query lb=1
python3 tools/look/compare.py res://src/screens/recruit.tscn docs/mockups/recruit.html --ref origin/design/x
```

The page is a path in this working tree, or with `--ref` the same path read from that commit or
branch. Chromium (the headless shell Playwright keeps in `~/.cache/ms-playwright`; this tool does
not install one) renders it in dark mode, with `?shot` added to the query so a page can hide its own
controls. The scene is shot with `look`, 0.5 s after it is ready. It prints:

```
measured against: tests/look/compare_demo.html?corner=wrong in the working tree at 3f2a9c1d (unchanged from that commit)
scene: res://tests/look/compare_demo.tscn at 1280x720
whole screen: mean difference 0.90 of 255; 0.69% of pixels differ by more than 32
worst regions (16 x 9 grid, 80x80 px each):
  1. P1   top right      x 1200-1280, y 0-80: mean 58.19; 46.88% differ by more than 32
  2. O1   top right      x 1120-1200, y 0-80: mean 35.80; 28.12% differ by more than 32
  3. P2   top right      x 1200-1280, y 80-160: mean 21.51; 15.62% differ by more than 32
```

- **Which page:** the first line names the page and the commit it was measured at: the commit
  checked out and whether the page has changed since, or the commit `--ref` named.
- **Regions:** the screen is cut into a grid, 16 columns (A to P) by 9 rows (1 to 9) by default
  (`--grid`). On a 16:9 screen that makes square regions, 120 px at 1920x1080: about the size of
  a portrait, a counter or a button. A wrong thing that size fills most of a region and scores
  high there, while a region is still large enough that the few pixels where Chromium and Godot
  draw text edges differently do not swamp it. The `--worst` (3 by default) regions are printed
  and outlined on `diff.png`, the worst in red.
- **The numbers** are the mean difference per pixel, 0 to 255, the same measure as the
  whole-screen number, and the share of pixels that differ by more than 32.

Output goes outside Git, to `${XDG_STATE_HOME:-~/.local/state}/bramble/look-compare/<time>/` or
`--out`: `diff.png` (the difference x4, the grid drawn faintly over it, its names and a legend of the
worst regions in bands outside the picture, the worst regions outlined, worst in red),
`stacked.png` (the page above, the scene below, the worst region outlined on both), `mockup.png`,
`godot.png` and `result.json` (every region's numbers, with the page and commit).

**What it cannot be trusted for:**
- **Small wrong things still hide.** A region's number is an average too. Something wrong that is
  much smaller than a region, or split across region edges, scores lower: in the demo an 80 px
  element over four 80 px regions scored 58 in its best one. A wrong word or a 10 px offset can
  score only a few points. Look at `diff.png` and `stacked.png`, not only the numbers.
- **Text never scores zero.** Chromium and Godot draw glyphs differently, so regions with text
  score a few points even when they are right. Compare a region with itself on another run, not
  with a region that has no text.
- **Blue counts for little.** The difference is turned to grey by brightness (red 0.30, green
  0.59, blue 0.11), so a change only in blue scores about a ninth of the same change in green.
- **A match is only a match with the page.** It does not say the page is right or that the owner
  has seen it. A page edited to match the build scores well.
- **One still frame.** Anything still moving 0.5 s after the scene is ready is caught mid-way.
  For motion use `tools/feel/film`.
- **No limits.** No number passes or fails, and the gate runs no compare.
- With `--ref`, only the page's folder (and what its symlinks point to inside the repository) is
  read from the commit; parts a page reaches with `../` paths are missing.

## Proof (run by hand, not in the gate)

The quality gate runs neither demo (owner, 17 Nov: the tool's files are not meant to change, and
the demos cost Godot time on every run). Run them by hand after changing the tool or upgrading
Godot (`docs/CLOUD_SETUP.md`, "Upgrading the toolchain"):

```bash
tools/look/demo.sh
python3 tools/look/compare_demo.py
```

`tools/look/demo.sh` drives `tests/look/look_demo.tscn` (a button that counts presses, and keys
that log on purpose) through the whole loop in about twenty seconds: start, shot, click the button,
shot, read the click in the log, press E and read the pushed error, press Q and see the quit
reported, and see a missing scene fail. It prints both screenshot paths; the first shows
"Not pressed", the second "Pressed 1 time". It exits 1 on any miss.

Dropped from the first run's tool (tag `archive/branches/ideation/main`): its jump states into
that game's screens, and its movie clips, which were tied to that game's UI.

`tools/look/compare_demo.py` proves the compare on `tests/look/compare_demo.tscn` and its page
`tests/look/compare_demo.html` (plain rectangles at 1280x720) in about ten seconds. Against
the page as drawn every number is 0. With `?corner=wrong`, the badge in the top right corner is
replaced by a different element: the whole-screen number must stay under 1.5 while region P1 is
named the worst, over 40 and at least 30 times the whole. It exits 1 on any miss, and 77 where
Xvfb, xdotool, scrot, headless Chromium or Pillow is missing.
