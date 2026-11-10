# Look at and play Bramble headlessly

From the repo root, use `tools/look/look` in a **shot → inspect image → act → shot** loop.
Open each printed PNG with your agent's image viewer. Pixels in the PNG are the exact
`x y` input coordinates, from `(0, 0)` at the top left. PC is **1920×1080**; phone is
landscape **1688×780**. No desktop or window manager is needed.
If a shot catches an animation, take another before choosing the next coordinates: controls can reflow.

Prerequisites: `godot`, Xvfb (`xvfb-run`), xdotool, scrot, Python 3 and Pillow.
Some agent sandboxes need permission to access host X11 processes; output automatically uses a writable folder.
On a fresh checkout import once: `scripts/godot_slot.sh godot --headless --editor --import`.

```bash
tools/look/look start --size phone --state recruit  # prints a session ID; default state: menu
tools/look/look shot before                        # prints the image path; inspect it
tools/look/look click 1580 690                      # example coordinate; locate targets in YOUR shot
tools/look/look shot after                         # inspect the resulting change
tools/look/look move 840 350                        # hover
tools/look/look drag 800 350 800 570                 # left press, gradual move, release
tools/look/look key Escape                         # X keysym, or chord such as ctrl+a
tools/look/look states                             # all jump names (fixture states are staged test data)
tools/look/look list                               # live IDs, displays, sizes, jumps, worktrees
tools/look/look stop                               # close game and Xvfb, release slot
```

`start --state last_fight` opens a staged round-14 recruit at 1 Health: click **End turn**
to lose the final fight and reach game-over through play (Play/Skip can advance the fight).
`combat_mid`, `combat_held` and `sandbox_fight` pause partway through a fight; use Play/Step/Skip.
Playback normally auto-returns to recruit or game-over when finished. `combat_end` holds the
completed fight instead. `start --size pc --state game_over` opens the result directly. Jumps create
new sessions. With two sessions open, choose explicitly: `tools/look/look --session ID shot`
(or `export BRAMBLE_LOOK_SESSION=ID`). Commands otherwise select the only live session.
No more than two look games/recordings run at once; they use separate locks from the gate.
An unused live session closes after 30 minutes. `stop` keeps its images and logs.
Each `start` deletes inactive look session folders older than 7 days.

Output defaults to `${XDG_STATE_HOME:-~/.local/state}/bramble/look/`; if that is not writable,
it falls back to `/tmp/bramble-look-<uid>/` (or the system temporary directory). Override with
`export BRAMBLE_LOOK_DIR=/tmp/my-bramble-look` and keep it set for every command.
Shots land in `<output>/<session>/001-before.png`, then `002-after.png`, etc. Labels are optional and use letters, digits, `_` and `-`.
`game.log`, `xvfb.log` and `supervisor.log` are alongside them. Nothing goes into git.

```bash
tools/look/look clip combat_mid --seconds 10 --fps 30    # fight, restarted from first event
tools/look/look clip recruit_turn --seconds 8            # driver buys, plays and ends a recruit turn
tools/look/look clip combat_held --seconds 6 --size pc    # choose the recording size
```

Clips print paths to `contact.png` (12 timed thumbnails) and `clip.gif`; full-resolution
fixed-rate PNGs are deleted after conversion unless you pass `--keep-frames`, e.g.
`tools/look/look clip combat_mid --seconds 2 --keep-frames` keeps the `frames/` directory. Setup frames are excluded
from the GIF/contact sheet. Duration is simulated seconds; rendering may take longer.
**Movie mode advances fixed frame time: live xdotool input cannot reliably drive a clip.**
`recruit_turn` uses `tests/ui/player_driver.gd`; state clips use staged playback. For a custom
script, extend `tests/ui/shots/look_movie.gd`, override `_movie_actions(app: App) -> void`,
pace actions with `await _movie_frames(n)`, then run
`tools/look/look clip tests/ui/shots/my_clip.gd --seconds 8` (starts in recruit).

Optional live watching: find the display in `list`, then `x11vnc -display :N -localhost`;
use an authenticated tunnel to reach it.
