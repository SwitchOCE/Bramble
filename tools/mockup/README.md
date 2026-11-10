# Layout studies

Run from this worktree with Godot, Xvfb and Python/Pillow installed:

```sh
bash tools/mockup/run.sh
```

Every Godot invocation goes through `scripts/godot_slot.sh`. The runner puts its
editor settings and screenshot user data under `/tmp`; it changes no game files.
Godot's first import can generate missing `.gd.uid` sidecars in older source files;
keep those generated files out of this proposal's commit.

`capture_parts.gd` inherits the existing build-8 screenshot state runner. It opens
`recruit_late` and `combat_mid`, stops playback, and renders actual widgets in an
alpha SubViewport. It exports cards, their state dictionaries, all eight lobby
portraits, the tap reader and real controls to `build/layout-parts/`. The shop's
three existing unit offers are supplemented with two real pool definitions to show
the requested five-unit capacity; card text is untouched. Mid-fight timing comes
from the live runner, so a fresh capture can reach a slightly different event.
Every option in one batch uses the same captured fight state.

`layouts.py` composes those widgets with the committed paintings. Only tables,
contact shadows, inlays and lighting are drawn procedurally. The diorama's pinhole
projection is reproducible with a Camera3D, a plane mesh and billboard Sprite3D
tiles, or the same projection in a 2D stage. No AI artwork is newly generated.
All stills say **concept** because the source backdrops were generated.

`render_table.gd` renders both Woodland Table recruit stills using the actual
rearranged CardView, lobby, hero and button nodes over the procedural table base;
the other stills use transparent Godot captures. `--finalize` converts the native
Godot PNGs and rebuilds the comparison sheet and checksums. Three extra phone
stills show the actual on-tap reader, with unchanged rules, over each proposal.
These are visual studies; they do not implement hit testing or gameplay changes.

Outputs live in `build/layouts/`. The gallery copy needs only `index.html`,
`notes.md`, `manifest.json`, `sheet.jpg`, and the five JPEGs in each option directory.
`verify.py` checks sizes, completeness, widget bounds, required controls and hashes.
Review each final image visually as well. No motion clip is needed: the depth is
static in every option.

The comparison sheet uses the complete, sharp Bazaar busy-play frame at
`00:01:33.000` and fight at `00:01:44.500`, from its Steam trailer; the manifest
records source URLs. Third-party frames remain in the private `/data` gallery,
never in git or shipped assets.
