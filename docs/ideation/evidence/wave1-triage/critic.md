**Verdict: keep the core and change the Fairy half.** About 90% of the Fairy gain comes from one dial. The card that holds Court back most is missing from the report. The package also misses its own targets.

**Main cause (paper models scripted every arrival): keep, with one addition.** It explains the gap to paper. But Court, the worst line at 0.17x, also has a card that fails its role, and the report leaves it out.
- Queen of Elfland destroys the units behind her at End of Turn, so her Ringed slots fight empty.
- At R12, Court boards with her have 1.8 empty slots, against 0.48 without her. Her boards are only 164 against 143 at R12, and 365 against 352 at R14.
- The report puts these empty slots down to bot play. They are a timing problem in the card.

**Factual error: fix it.** "Annis is the only card that adds Rings at R1-3" is wrong.
- Nan Toadstool (T1, "When played or sold: Ring this slot") is on 42-47% of R8 Fairy boards, the most of any Fairy.
- Sally Spore (T2) adds Rings too.
- The second route to Rings already exists; each card just adds too few. So "a second card that adds Rings" would not have caught this.

**Step 1, arrival replays for all six models: change it to something smaller.**
- The replay is calibrated on the same run it then predicts, and it comes out x1.3 below real boards. It is a model of a model.
- Instead: keep the existing offer-rate helper, make the low-roll row remove the keystone, and re-base B and C on one real sim run per wave (about 28 minutes on Sol).
- Rerun first at the shipped config. The run used `tribes_per_lobby` 0 and turned off `card_size_caps` and `card_rate_limits`; `full_game()` uses 5 and has both on.

**Re-basing B and C as real medians: change.** On these dials every line lands below its own target: Birds B at 650-800 against 900, Fairies at 210-320 against 900. 09h says start above and dial back, not below. Either say Fairies can't reach the target without more Rings, or fix that now.

**Fairies:**
- **`fairies_initial_ring_size` 3: keep, and consider 4 (09h).** On its own, re-pricing gives Ring 210 and Court 259 at R12. That is already the report's whole quoted range.
- **Annis and Sally to 2 Rings: drop.** The report's own lens (`a6_dials`) gives +14 to +22 at R12, under 10%. Sally Rings empty slots, so her extra Rings mostly sit where no unit stands; 16-27% of all Rings are already on empty slots at R12-R14.
- **Cluricaun: change, but don't count on it.** The report's text keeps the tier-up trigger, so it stays dead at T6 for 42-55% of its time on the board. Make it "End of Turn: if every slot has a Ring…": 45-78% of R12 boards meet that condition. Either version is small on the median, since it is on only 22-37% of boards (R12 +3 to +9).
- **Add: the Queen triggers at Start of Turn**, so the slots she empties can be refilled before the fight. Estimated Court R12 rises from 278 to about 395 on top of size 3. That is an upper bound: it assumes a median-sized unit and the gold to buy it.

**Birds:**
- **Today's C becomes B: keep.** It is generous (09h) and cheap.
- **New C with multiplier 3: keep only as a constructed-setup test.** Don't ship it yet. Its tail is 7-13k and untested.
- The package widens the tribe gap from about 1.8x to about 3x, while Birds already win 72-78%. That is within 09c's order of magnitude, but the Queen change narrows it at no cost.

**Measures (09i): change.** The report judges results by about eight numbers (median, p90, 2x share, 3x share, p90/p50, high rolls, win rate, growth). Decide on two: the R12 median and growth from R8 to R14. Note the survivor bias in the growth figure: only 37-45% of Fairy seats are alive at R14, against 79% of Birds seats.

**Bot work after this: keep.** But the "fill empty slots" item is mostly the Queen, not the bots.

**Not now (tribe guarantee, Ask for Kin, kin Discover; Stork, Redbreast and Redwing reworks): keep.**

**Wave 2 briefs: cut to two rules.**
- The low-roll row removes the keystone.
- Check each card's condition against when its trigger can fire. This one would have caught both Cluricaun and the Queen.
- Drop the 60% second-card rule (Fairies already had second cards and still failed) and the order-of-generosity rule. "Line files hold only rules the bots run" becomes an engineering fix, not a design rule.

**Simpler fix with most of the effect:** Ring size 3 or 4, the Queen at Start of Turn, Birds' old C as the new B, and one real sim at the shipped config.

All figures re-price the captured boards; none come from fights. My scripts are in `docs/ideation/evidence/wave1-triage/scripts/critic/`:
- `c1_rings.py` (Rings on empty slots)
- `c2_conc.py` (how concentrated stats are, and size re-pricing)
- `c3_empty.py` (empty slots)
- `c4_clur.py` (Cluricaun variants)
- `c5_queen.py` (Queen)