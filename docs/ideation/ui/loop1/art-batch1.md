# Loop 1 — portrait batch 1

52/52 accepted: five heroes, 42 units in tier order, five spells. All originals replaced with 512×512 RGB JPEGs; 52 prompts saved as `tools/art/prompts/inkglow/batch1-<id>.txt`. Generated through the existing Codex wrapper using its built-in image tool, with current portrait then both frozen anchors. No round-two frozen-header portraits overlap this batch; the five overlapping earlier studies were repainted. Header and anchor bytes unchanged.

Every repaint inspected against its preserved original at exactly 150 px; heroes also checked in 70 px circular crops. Zero image retries and no unresolved identity doubts. Close inspection confirmed Ermeline's oval-eyed sewing needle and the wasp's neckerchief/ovipositor; their prompt wording was clarified after generation, with the already-correct images retained. Some faint wash texture remains in the generated art.

Contact sheet and 150 px JSON index: `build/loop1/batch1/contact-sheet.png` and `.json` (52 pairs, grouped by first gameplay tribe). PNG masters: `build/loop1/batch1/masters/<id>/<id>.png`. Original backups, review crops and generation logs remain in the same ignored build folder; `heroes-review.png` includes the circular chip checks.

Validation passed: exact batch membership, JPEG dimensions/format, square PNG masters, frozen header in all prompts, anchor hashes, original backups against the baseline, contact-sheet rectangles and scope. No `.import` files, tests, game/content code or frozen recipe files changed. Godot was not run. Wrapper startup and checkpoint commits required sandbox escalation for external runtime/Git metadata; approved, no denied actions. Six local checkpoint commits; no push or merge.
