# H1 four-lobby smoke

One distinct, excluded seed per arm; this is runtime and capture-integrity
verification, with all usability verdicts withheld. Each capture includes the
real fight boundary and outcome. `progress.json` records hashes and runtimes;
`summary.json.gz` is the canonical metrics format. The Markdown rendering is
`docs/ideation/reference/quilboar/h1-smoke.md`.

Scope runtime includes Godot startup, excludes lock waiting, and was 5.24 / 4.11 /
3.56 / 4.85 seconds for B / C / uncut / frozen uncut. Mean: 4.44 seconds; weighting
by 150/150/100/100 gives a conservative 2,243.5-second (37.4-minute) projection.
The full run uses five-lobby chunks to amortize startup and distinct seeds
beginning at 2911001. All seven tribes are present; the Hard anchor uses its
normal recruitment, scouting and search placement. Tribal/reference lines use
their scripted policies and blind placement.

Only Birds and Fairies have wave-1 designer files in this source tree. Bog,
Hedgerow, Hunters and Oozes use the committed legacy engine profiles/current
content. B/C/uncut select reference dials; the native tribes keep their committed
rates. These are not measurements of an unmerged wave-2 implementation. The
source and all four configurations are pinned in `../quilboar-h1-plan.json`.

Phase 1 omits Roadboar (Phase 2), so early accounting may run slightly below the
paper's scripted arrivals. Ratios and seed intervals are measurements; only the
predeclared accounting and fidelity criteria decide reference usability.
