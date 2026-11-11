# Notch rollout: batch 0

Baseline: `e6af222d`. Scope is the 57 batch-0 jobs plus Fairies fallback: 58 identities, including two unchanged approved trials (Dame Hoolet and Grey Agnes). The other ten trials belong to the other slices.

56/56 new repaints accepted; two approved trials reused. Complete production `header-notch.txt` is unchanged in every `notch-<id>.txt`; old flat-background colour clauses were removed and one form/light direction added. Reference order: current identity, both frozen inkglow anchors, assigned notch pilot. PNG masters and original JPEGs are under `build/notch/`. Exports are 512×512 RGB JPEG, quality 90; import files remain untouched.

Every accepted image received a paired 150px identity/form/outer-ink check; the two repainted heroes also passed 70px circular checks. 56 generations, no retries; no originals retained because of a failed repaint.

All 58 slice identities are paired against the setup commit in `build/notch/contact-sheet.png` (exact 150px cells, sorted by tribe). Header/anchor immutability, export dimensions, scope and diff checks passed. No UI, content, gameplay, tests or import files changed.
