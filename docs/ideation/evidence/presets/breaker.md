On paper the presets mostly hold up. Nothing gets near the 1-billion clamp, no dial is below its design value, and I found no repeated doubling inside a turn. But the tight spread you report only holds at R12. The tribes' curves cross a lot on either side of it, and that causes three of the four problems below.

**Problems that need a dial change, most serious first**

1. **Fairies peak early and then fade, in both presets.**
   - Pre-start board divided by the lobby median (the method is at the end):

   | | R9 | R10 | R11 | R12 | R13 | R14 | R15 | R16 |
   |---|---|---|---|---|---|---|---|---|
   | B | 1.25 | 1.55 | 1.37 | 1.01 | 0.69 | 0.55 | 0.55 | 0.39 |
   | C | 1.54 | 2.13 | 1.59 | 0.97 | 0.59 | 0.43 | 0.40 | 0.27 |

   - In C, the Fairies court line is at 2.7× the lobby at R10 (1,298 against 482). It wins R9–R11 whatever the other player does, then loses from R13.
   - From R12 to R14 the Fairies grow about ×1.25 a round. The lobby grows ×1.71 (B) and ×1.88 (C).
   - The cause: every C raise (fairies_ring_growth 4, lob_growth 3, silky_growth 2) is a one-off step that lands R8–R11. The late engine, the Monarch, arrives last.
   - **Fix, B:** fairies_monarch_period 3→2. That moves R13–R16 from 0.69/0.55/0.55/0.39 to 0.81/0.74/0.68/0.70, with R12 unchanged.
   - **Fix, C:** fairies_monarch_period 3→2, plus fairies_monarch_multiplier 2→3 (golden 3→4). R13–R16 become 0.68/0.93/0.71/1.07. The top 1% line reaches 276,568 at R16.
   - The R10 peak stays. If the harness confirms it, cut fairies_ring_growth in C from 4 to 3: R10 drops from 2.13 to 1.95, but R12 drops from 0.97 to 0.85.

2. **In C, a Birds Flock with two Cuckoos wins from R12 on.** The harness lines never buy a second Cuckoo, so the harness won't see this; a human player will.
   - Two Cuckoos: 3,651 / 19,866 / 76,046 at R12 / R14 / R16. That is 1.9×, 2.9× and 3.5× the lobby.
   - A golden Cuckoo plus one more: 5,992 / 50,619 / 253,219, which is 3.1×, 7.4× and 11.6×.
   - In B, two Cuckoos are 1.6–2.3× the lobby. That reads as a normal tail.
   - **Fix:** birds_cuckoo_share in C from 0.2 to 0.15 (still above B's 0.125). Two Cuckoos then read 1.42× / 1.74× / 1.78×.
   - Cost: Birds C smoothed drops from 1,675 to 1,599, because the tempo line has no Cuckoo. Raising Chiffchaff to +4 in C only brings it back to 1,797, though two Cuckoos then reach 2.0× at R14.
   - A cheaper alternative is a rule rather than a dial: "only one Cuckoo counts", like Soup's copy rule. It costs the calibrated lines nothing.

3. **Hedgerow in C: Mallow at ×3 drives both an early lead and a late runaway.**
   - Early: the pooled board is 1.47× the lobby at R8, 1.48× at R9 and 1.83× at R10.
   - Late: the Parish grows ×2.44 a round from R13 to R16 (3,215 → 46,773). The on-time Parish is 2.5×, 3.6× and 5.0× the lobby at R14–R16, reaching 109,799.
   - The calibrator's suggested cut, Mallow ×3 → ×2, removes all of the Parish's C raise. The C Parish then equals the B Parish exactly (851 smoothed at R12).
   - **Fix, if the harness shows the Parish winning late:** hedgerow_mallow_multiplier in C from 3 to 2.5.
     - The Parish then grows ×2.21 a round, and the on-time Parish is 1.3× / 1.7× / 2.1× at R14–R16.
     - The early lead falls to 1.13–1.36× at R8–R10.
     - Cost: Hedgerow C's two-line R12 figure drops from 2,168 to 1,722, and pooled R12–R16 sits at 0.76–0.95 of the lobby.

**The spread claim.** The 1.15× (B) and 1.29× (C) spreads hold at R12 only. Largest tribe divided by smallest:
- B: 1.8× at R10, 3.1× at R16.
- C: 2.6× at R10, 4.6× at R16.

Everything stays within an order of magnitude.

**Checked and fine**

- **Bog and Hunters**, re-fed on a lobby built from all six calibrated tribes:
  - At R12: Bog 1,058 / 1,971 and Hunters 940 / 1,879 (B / C). That is 0.97–1.12× the lobby, which confirms the calibrator's estimate.
  - Late, both lead slightly: 1.17–1.30× at R15–R16. No change needed.
  - Two Hunter boards that fight each other every round feed each other: ×2.09 a round in B and ×2.27 in C, against the lobby's ×1.64 and ×1.86. It is the pool's one mutual-feeding loop, limited by how often two Hunter seats meet. Report it only.
- **The clamp.** The biggest board on paper by R16 is 466,650 (Oozes' top 1% line in C), about 2,100 times below 1 billion. Even growing ×3 a round to R20 it would reach about 38 million.
- **Loop guards (amendment 11).**
  - The code limits each Bird to one homecoming a round and one Golden Egg a game, and guards Dunnock against repeat triggers.
  - Bog doubles a unit at most once a turn, and two Monarchs share one clock.
  - Click Beetle's second Golden Egg goes to a different Bird, which cross-tribe §8 allows. Worst case in C: a golden Goose with a golden Beetle makes 6 Eggs, so 6 Birds are tripled in one landing. That is a one-time spike, still once per Bird.
- **No dial is below design.** Two dials look lower in C but run the generous way: birds_stork_gold_step 6→5 and fairies_lob_turns 3→2. So "every C value is at or above B" is true in the generous direction, not numerically.
- **Things to log:**
  - Raising Fairies and Oozes above their design values in B departs from the plan's "stay at design size". I agree with doing it.
  - Jack Daw stays permanent in both presets, pending the harness check in amendment 5. If he becomes fight-only, Birds drop from 901 to 809 (B) and from 1,675 to 1,459 (C), and Birds are already the late laggard: 0.70–0.74 of the lobby at R14–R16 in B. Agree the compensation (Chiffchaff +4) in advance.
- **Reported tails, no change:**
  - Oozes C top 1% line: 21× the lobby at R16. The two-goldens line: 4.1×.
  - Hunters C top 1%: 2.7–2.8× at R14.
  - Hedgerow's on-time Supper: 3.1× (B) and 4.2× (C) at R9, and about 1.3× or more every round to R16. This was already a highroll in the design, and lowering the food dial to 1 only takes R9 to 2.5×.

**What I counted, and where it's shaky**
- **The lobby:** for each round, the median of six tribe figures, all pre-start, end-of-recruit boards, Eggs in, reserves out.
  - Birds: pooled jitter of both harness lines.
  - Fairies: median of 8 scripted lines.
  - Oozes: mean of line B and Pot Luck.
  - Hedgerow: pooled median of 6 shift variants.
  - Bog and Hunters: re-fed three times on the mean of all six.
  - Lobby median, B: 141 / 337 / 945 / 2,750 / 7,171 at R8 / R10 / R12 / R14 / R16 (×1.64 a round R8–R14).
  - Lobby median, C: 164 / 482 / 1,929 / 6,823 / 21,848 (×1.86 a round).
- **Each tribe's "typical" is a different kind of median**, so ratios within about 15% are noise.
- **The Fairies' R10 peak depends on the model's Ring sizes.** Wave 1's bots ran a Ring size of 2.2 against the model's 4–6. If real play matches the bots, the peak shrinks and the late fade gets worse, which makes the Monarch raise matter more.
- **The Birds tempo line has a fixed cycle**, so all tempo seats dip on odd rounds: 0.67 at R11, 0.65 at R13, 0.60 at R15 in C. Smoothing over R11–R13 hides this.

Everything is in /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets/adv/:
- lobby.py
- lobby2.py
- lobby4.json
- lobby6.json
- fairies_probe.py
- fairies_probe2.py
- hedge_probe.py
- hedge_probe2.py
- cuckoo.py
- birds_late.py
- birds_k.py
- birds_k2.py
- oozes_late.py