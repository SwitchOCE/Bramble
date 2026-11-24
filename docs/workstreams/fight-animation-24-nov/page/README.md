# The phase's page

Published at https://claude.ai/artifact/7AfjsAxqQp6VLHfRvFtPjZ (private to the owner).

`template.html` is the page source; it is assembled with the house-style `base.css` and `plans/tree.json` inlined. Its clips and charts are not in Git (video): they are in `/data/fight-anim-work/treatments/clips/` and `.../films/best.speed.png`, `/data/fight-anim-work/fixture/today.speed.png` on the Optiplex, and published with the page.

The comparison viewer (section 02) reads `/data/fight-anim-work/treatments/compare/` (one clip per option, cut by `tools/feel` clips code on `review/fight-animation-clips`) and inlines its `manifest.json` in place of `/*COMPARE*/null`; the clips are published under `compare/`.

The picks page (`picks.html`, published at https://claude.ai/artifact/HYNTiF6L3QJ9zat7rqBH9y) shows today against the recommended option, one pair per topic. Its clips are copies of `compare/` clips, named `v/<branch>-<option>.mp4`.
