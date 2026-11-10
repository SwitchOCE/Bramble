*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the oozes critic.]*

## Oozes check (A3.5 step 0)

The draft's numbers check out. These were all confirmed:
- dial values, and the code lines that read them;
- R12 medians 262, 285.5 and 200, with their seat counts;
- card counts on the boards, the 20 of 26 seats without Soup, and their 258;
- paper values 954, 1,771, ×3.99, ×8.59, ×1.10, ×1.21 and 254;
- the estimates ~343, 351, 857 and 1,169.

The corrections are about which build was measured, why Soup is missing, the limits and the card text.

### Corrections

1. **"Measured on base 722f5ae4"** → The lobbies ran on `c66a88e5`. 722f5ae4 is only the branch point, and Stone Soup there is still the pass 2 card. After the run, `21a65947` changed four things: Hasty's gain (now read from current stats, not its own body), Soup's Shy rule, Posset's killer, and the bot's fallback value for Ooze cards it doesn't model (6/3 → −1). Pass 3 Hedgerow also joined the field later. So 262 is the right line and preset, but one generation behind `424b3c2a`. Source: `git log 722f5ae4..424b3c2a -- src/core/pass3_oozes.gd`, `git diff c66a88e5 21a65947`.
2. **"Soup reaches only 23% of boards"** → Part of this is seats dying, not only buying. 11 of 32 seats fielded Soup by R10. 5 of those 11 were out before R12, against 1 of the other 21. Soup seats were also smaller early: 42 vs 49 at R6, 76 vs 92 at R8. So the 331 only counts Soup seats that survived. The triage has to cover Soup's weak early game too (`wave2b-build.md`:47). Source: `oozes-final.jsonl`.
3. **Hasty "read at tx only"** → In fights the share is read at `pass3_ooze_combat.gd`:139, from the parameter set at tx:87. The bot's value for Hasty uses a fixed 0.2 (`bot_ooze.gd`:148), so raising the dial won't make the bot buy it more. Hasty is on 10 of 31 boards at R10, falling to 2 of 21 at R14.
4. **Table keys** → They need the `oozes_` prefix, e.g. `oozes_golden_elder_multiplier`.
5. **Elder's limit of 1 "from card text"** → The text doesn't cap it. At C, golden Elder already prints "three halves of its stats" (0.75 × 2). At share 1, golden prints "twice its stats". The cap of 1 is the general rule for shares, not Elder's card (`pass3_text.gd`:123–147).
6. **Soup 8/27 prints "29.6296%"** → `_n` prints the full decimal. Snap up to 3/10 ("three tenths") instead of 2/7: it is closer (+1.3% vs −3.6%) and fits generous-first (09h).
7. **"Text at B, after" in the proposals** → Those are the t = 0 values. B runs at t = 2, so the faces would read "three quarters of it" and "four ninths of …". The eat multiplier at t = 2 is 4.5, which rounds up to 5 (7 at C), not "doubled".
8. **The new Eat reminder** → Ooze meals also use it, and they pass whole, so the proposed wording would be false for them. It needs "a non-Ooze's printed stats" (`effects.json`:939, oz:232).
9. **"Slice moves R12"** → It doesn't. The paper factor stays ×1.00 on the B and no-Soup lines up to s = 0.59 (×1.08–1.11 only if Cut-and-Come-Again arrives by R10). No Slice is on any of the 26 R12 boards. The bot only feeds Slices from R12.
10. **"254 matches"** → 254 is the paper line with Aspic from R6. Without Aspic it is 218, and only 8 of 26 real boards have Aspic, so the match is loose.
11. **Hasty understated** → The paper sizes Hasty from today's field (R12 median 337). The presets grow the field, so Hasty is the one extra dial whose buff grows with the preset itself.

### Verdict
**Plausible on today's dials: no.** About 343 at both caps: 0.38× of the B target, 0.19× of the C target.

### Extra dials (corrected)
1. **`oozes_hasty_share`**: B 1/3, C 1/2. t = 2 gives 3/4, t = 3 gives 1. Limit 1 (the general share rule). Line 148 of the bot must read the dial.
2. **Drop `oozes_slice_share`.** If a replacement is wanted, use **`oozes_aspic_bonus`**:
   - B 0.75, C 1. t = 2 gives 4/3, snapped to 1.35 ("135% more"); t = 3 gives 1.78, snapped to 1.8.
   - Golden Aspic's bonus is its multiplier − 1 (oz:272), so `oozes_golden_aspic_multiplier` must move as 1 + 2 × bonus, or golden ends up weaker than normal.
   - Paper: ×1.44 at t = 2 and ×1.57 at t = 3 on the no-Soup Aspic line, against ×1.21 today. On the Soup line it is ×9.7 and ×43, a snowball risk.
   - It reaches 8 of 26 boards.
3. **Option: let `oozes_elder_share` pass 1.**
   - t = 2 gives 9/8, snapped to 5/4 ("five quarters"); t = 3 gives 27/16, snapped to 7/4 ("seven quarters").
   - Paper on the no-Soup lines: ×1.30 at t = 2 and ×1.57 at t = 3.
   - Elder is on 16 of 26 boards, the widest reach of any existing dial. It spreads stats to other Oozes, though, where 09a prefers concentrating them.
4. **`oozes_eat_printed_multiplier`** (a new rule):
   - B 2, C 3. t = 2 rounds up to 5, t = 3 rounds up to 7. It must stay at 1 or more.
   - The reminder needs the non-Ooze wording from correction 8.
   - It is not a size axis: printed stats stop growing at tier 6, so it grows by meal count. Its only strength is reach (25 of 26 boards).

**Size axis:** the Oozes' growing size axes are Soup (sized by the biggest Ooze, already on the path), Hasty (sized by the enemy) and Slice (sized by the biggest Ooze, but no effect at R12). None of them reaches the median seat. So getting Soup onto boards and keeping those seats alive stays the first triage, before any extra dial.

Files are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/chk/`:
- `asp.py`: the Aspic, Slice and Elder sweep;
- `of.jsonl`: the extracted measurement;
- `committed_model.py`: the committed paper model.