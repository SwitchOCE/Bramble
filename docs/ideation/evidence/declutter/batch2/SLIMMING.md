# Slim evidence derivatives

The passing `cold-recruit-followup/reader/` and `technical/` retain native image
dimensions. Existing reader sequence JPEGs retain their original bytes. The
superseded first packet is archived locally at
`build/declutter-b2-evidence/first-packet/`; its retained
[`cold-recruit/README.md`](cold-recruit/README.md) and checksum list identify
every archived original and earlier slim derivative. The original first-reader
score remains on `ideation/main` under `evidence/declutter/batch2-cold/reader1/`.

Other before/after/focus capture images and motion strips use JPEG quality 85
and 720 px wide display derivatives, within the 1600 px maximum. Keeping the
passing packet at native dimensions consumes 36.2 MB of the 45 MB budget, so
these historical comparison captures use smaller display copies. Original
native PNG/JPEG images and JSON remain in the gitignored
`build/declutter-b2-evidence/originals/`; tools that compare or repack native
pixels prefer those originals when present. `display-derivatives.json` maps
capture dimensions to display dimensions. Image links identify display copies;
manifest pixel dimensions, geometry and measurement results describe the
original native captures, not the reduced display copies.

`slimming-images.json` records source and tracked image SHA256 digests.
Identical remaining images and state fixtures share relative symlinks, rooted
in the retained passing packet where applicable. To distribute a reader
directory alone, dereference links, for example `cp -aL reader /path/to/export/`.
The passing reader's text and sequence images are unchanged; Rules page image
encoding and links changed from PNG to native-size JPEG.

The 30 `*-calm-mask.png` files remain byte-identical to their captures. Their
exact white-pixel histograms verify `calm_space_pixels` in the native manifests;
JPEG ringing would change these counts. Serialized `states.json` fixtures
retain exact bytes for state hashes and Godot tests. Large derived reports use
lossless `.json.gz`, retaining all fields. `gzip -dc report.json.gz` displays
them; report tools accept fresh plain JSON and compressed copies. Input
manifests remain plain JSON for tools that enumerate or rewrite them.

The repository gate checks every documentation blob introduced after an explicit
`--base <commit>`, including earlier versions later shrunk or deleted. Each blob
is limited to 2,000,000 bytes; all distinct introduced blobs together are limited
to 30,000,000 bytes. Versions of existing paths count too. Repeated identical
content counts once, and content already reachable from the base is excluded.
Local runs also inspect staged, unstaged and untracked versions independently.
Every `check.sh` mode requires `--base`; it never guesses from an upstream or
detached HEAD's parent. The explicit batch 2 allowlist retains passing native
images, including the two contact sheets above the per-blob cap, with a one-line
fidelity rationale. An exemption applies only at its exact path.

CI checks out full history and passes the PR's base SHA. A manual CI run requires
the `docs_base` input. Gate pushes explicitly fetch `origin/ideation/main` and
compare from its merge-base with HEAD, so the range retains every unmerged
commit. Missing bases and a base equal to HEAD fail the CI setup instead of
falling back to a one-commit comparison. Docs-only PR trigger rules are unchanged.
