# Fight motion calls, brief 10

All new motion numbers are in `src/screens/fight/fight_motion.gd`; replay holds stay in
`FightReplay`. Films/frames live in `/home/alex/code/Bramble/.claude/worktrees/night-media/fight/`,
outside Git. These are agent choices for the owner's review, not owner-approved taste rules.

- **Preparation:** the upright slide did not identify the attacker before travel. Weighed four
  and six frames of pullback/lean within the same twelve-frame attack; both are filmed.
  Chose four: it leaves eight frames of travel to follow the diagonal; six compresses travel into six frames.

- **Contact:** the old transom-relative destination could miss the apparent defender, especially diagonally.
  Weighed retaining that stop, fully covering the victim, or overlapping by part of a card; chose centres
  0.62 card heights apart along the actual target direction. Readability of target selection rests on this.

- **Impact:** baseline damage had no physical reaction. Weighed camera shake, a large extra overlay,
  and moving/lightening only the recipients; chose local recoil/light, smaller/cooler for prevention.
  The board stays a stable point of reference and a prevented hit still shows its existing zero.

- **Recovery:** the attacker hung at contact through the reading hold. Weighed keeping that pose or
  returning during the existing hold; chose a two-frame contact hold then an eleven-frame return.
  Damage follows the recipient, so survivor identity can be followed without extending attacks.

- **Damage:** full-size stars appeared/vanished abruptly. Weighed a long floating number or a brief
  pop with an interval to read; chose the pop, with a small final rise/fade. Filmed fixed-position and
  recipient-following candidates; chose following, upright, so later effects cannot label an empty collision point.

- **Death:** an upright fade resembled a redraw. Weighed flying off-screen, simulated glass fragments,
  and a short outward knock/tip/shrink; chose the short exit inside the old death hold.
  Death is visibly different from hit recovery; slots remain fixed/empty, per rulebook 8.3.4.

## Candidate decision and verification

`windup-candidates.mp4` compares the four/six-frame preparations; their total attack times match.
`candidate-fixed-bursts.mp4` retains the first rework; the final `after.mp4` follows recipients.
The whole-film review found the fixed-position candidate misleading on the later effect at 7.7 s,
which motivated the extra recipient/following tests and the second whole-fight capture.

Final `./scripts/check.sh`: all steps passed, 727 tests passed. Before/final reports match every
transition and the 12.6833 s finish; 18 review films (all eleven reference pairs included) were
validated. No replay holds/grouping were edited and no duration increase needs approval.

Hardware frame pacing, sound and the owner's judgement of motion cannot be established by films or tests.

Shared files touched: **none**. Recruit screen, `CardKeeper`, card drawing/keyword marks,
glass pieces, replay grouping, rules, sound and design mock-ups were not edited.
