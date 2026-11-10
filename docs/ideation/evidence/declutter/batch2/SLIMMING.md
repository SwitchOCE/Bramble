# Slim evidence derivatives

The native PNG captures and original JSON/JPEG files are preserved locally under
`build/declutter-b2-evidence/originals/` (already covered by the `build/` ignore rule).
`slimming-images.json` records each source digest, tracked display image digest,
and unchanged pixel dimensions. PNG display images use JPEG quality 85. Existing
JPEG sequences retain their original bytes. These JPEGs are visual evidence;
capture-era claims about exact PNG bytes refer to the original digests, not the
lossy derivatives.

Identical images and serialized state fixtures share a canonical file through
relative symlinks. Distinct historical face sheets remain distinct: their unit
ordering and/or art differ. The two cold recruit technical face sheets are exact
duplicates and share the earlier packet's copy. To distribute a reader directory
by itself, dereference links, for example `cp -aL reader /path/to/export/`.
Reader text and sequence images are unchanged; only Rules page image encoding
and links changed.

The 30 `*-calm-mask.png` files remain lossless. Their exact white-pixel histogram
checks the `calm_space_pixels` values in the before/after manifests; JPEG ringing
would change that measurement. All 30 histograms were verified after slimming.
Serialized `states.json` fixtures retain their exact bytes for state hashes and
Godot tests. Large derived JSON reports are stored as `.json.gz`, retaining every
field; `gzip -dc report.json.gz` displays them. The Python report tools accept both
plain fresh capture JSON and these compressed reports. Input manifests remain
plain JSON for capture tools that enumerate/rewrite them.

The new repository gate limits changed documentation files to 2,000,000 bytes
and new documentation files to 30,000,000 bytes per comparison range. Explicit
exceptions in `tools/checks/docs_size_allowlist.txt` identify existing native-size
face sheets which exceed the per-file cap. This gate also runs in docs-only mode.

The 25 MB packet target remains unresolved: JPEG quality 85 at native dimensions
cannot meet it. Even a quality 10 trial required 25,465,238 bytes for images alone,
before JSON, and degraded the cold reader sequences. A decision on dimensions or
reader fidelity is required before this packet is ready to merge.
