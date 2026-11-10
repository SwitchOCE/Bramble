# Day-1 owner gallery

From the repo root, with Python 3 and Pillow installed:

```bash
python3 tools/gallery/build_day1.py
```

This rebuilds `/data/bramble-gallery/loop1/index.html` and
`options-contact.jpg`, copies the available reference frames and indexes to
`loop1/ref/`, and makes local HTML versions of the reference indexes and Bazaar
breakdown. Open <http://100.92.26.47:8790/loop1/>. Leave the existing server running.
All gallery assets stay outside git.

The generator reads `text.md` on each run, preserves its prose and order, and
replaces its picture markers. It discovers layout folders, reads their ideas,
depth and costs from `layouts/notes.md`, and uses each matching section of
`layouts/critic.md` when available (otherwise the existing Fresh critic note).
New options and references appear on the next run. Missing inputs are reported
on stderr and omitted until available, without adding wording to the page.
The build replaces generated files atomically and never removes source assets.
Alternate locations: `--root PATH --references PATH`.

Clips are captured separately with the existing look tool, which takes its own
Godot slots through the project's slot wrapper. See [the look guide](../look/README.md).
Import once on a fresh checkout, then run this from the repo root:

```bash
export BRAMBLE_LOOK_DIR=/tmp/bramble-day1-clips
export XDG_CONFIG_HOME=/tmp/bramble-day1-config
export XDG_STATE_HOME=/tmp/bramble-day1-state
scripts/godot_slot.sh godot --headless --editor --import
mkdir -p /data/bramble-gallery/loop1/clips

capture() {
    local target="$1" size="$2" seconds="$3" name="$4" recording
    recording="$(tools/look/look clip "$target" --seconds "$seconds" --fps 15 --size "$size")" || return
    # The tool prints contact.png then clip.gif; take the final printed path.
    local gif="${recording##*$'\n'}"
    cp "$gif" "/data/bramble-gallery/loop1/clips/$name.gif"
    cp "${gif%/*}/contact.png" "/data/bramble-gallery/loop1/clips/$name-contact.png"
}
capture recruit_turn phone 7 recruit-phone
capture combat_mid phone 8 fight-phone
capture combat_mid pc 8 fight-pc
python3 tools/gallery/build_day1.py
```

Phone capture is 1688×780; PC is 1920×1080. The look tool's GIF conversion scales
to at most 640×360. These 15 fps clips are below 8 MB each; check replacements
with `ls -lh /data/bramble-gallery/loop1/clips/*.gif` and reduce duration or fps
if necessary. The full fight at PC size and all three clips are in Detail.
