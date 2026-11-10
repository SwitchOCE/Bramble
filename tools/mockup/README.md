# Layout studies

Rebuild with Godot, Xvfb and Python/Pillow:

```sh
bash tools/mockup/run.sh
# Reuse the existing real widget captures while adjusting compositions:
bash tools/mockup/run.sh --reuse-captures
```

The runner writes only `build/` and puts editor settings/user data under `/tmp`.
Every Godot invocation uses `scripts/godot_slot.sh`. A first import can generate
missing `.gd.uid` sidecars in older source files; keep those out of this commit.

`capture_parts.gd` inherits the build-8 screenshot state runner and exports actual
widgets from `recruit_late` and `combat_mid` to transparent SubViewports. Captures
include their state dictionaries, all eight lobby portraits, the tap reader and
real controls. Two actual pool definitions supplement the deterministic shop's
three unit offers. No content or card text is changed. A new capture can reach a
slightly different fight event; every option in a batch uses the same capture.

`layouts.py` composes four options. Shop footprints are at least build 8's desktop
width; deployed and hand CardView faces have a 210 logical-pixel floor (over 150
native pixels on phone), excluding projecting badges and shadows. Distant pieces
keep that floor. Full hands overlap at the original size instead of shrinking.
The four layouts use different activity groupings; Bazaar Stack puts the hero,
gold and actions in its slim bottom bar and the hand in a two-column pouch.

Painted stump wood and alpha foliage are committed under `art/`, with provenance
in its README. The material is masked to tables or mapped through a projective
transform onto a receding plane; Godot can reproduce this with a texture on a mesh
or Polygon2D. Thick faces, contact shadows and pooled light establish depth.
Foliage overlaps the screen edges while protecting every interface rectangle.
Every still says **concept**; no depth relies on motion, so no GIF is required.

`render_table.gd` renders Woodland Table recruit at both native sizes with actual
rearranged CardView, lobby, hero and button nodes over the painted base. Other
stills recompose transparent Godot captures. `--finalize` converts only fresh native
PNGs, rebuilds the comparison sheet/gallery and records checksums. Four extra phone
stills show the unchanged real reader. These are visual studies, not an input or
hit-testing implementation; the separate critique belongs to the orchestrator.

`verify.py` checks sixteen native stills, four reader studies, required controls,
widget bounds, hashes and tile-size floors. Also inspect every final image.
The gallery copy needs `index.html`, `notes.md`, `manifest.json`, `sheet.jpg`, and
the five JPEGs in each of the four option folders under `build/layouts/`.

The sheet uses complete Bazaar busy play at `00:01:33.000` and fight at
`00:01:44.500` from its Steam trailer; `manifest.json` records source links.
Third-party frames stay in the private `/data` gallery, outside git and shipping
assets.
