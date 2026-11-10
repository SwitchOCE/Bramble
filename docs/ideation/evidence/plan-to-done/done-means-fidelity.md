## Fidelity check of the revised Done means (10 Nov)

*[Saved verbatim from the done-means-check agent of workflow wf_ce74d9f0-cdb, 10 Nov. Calls: DECISIONS "Done means: fidelity check calls". It read PLAN.md, plan-to-done.md and DECISIONS.md at 322a28cb.]*

**Keep 7 / cut 3 / ask 5** (the 13 rows of the change table, plus the 7 base items)

Cuts:
1. DM5: the owner's 9 Nov declutter line is gone from the criteria that govern, with no label or reason. That line is no tutorial text, rule reminders or static pointers on the board, and fights read "through animation and feel rather than static labels, arrows or a running log". The table's quote cuts that clause out with "…" and calls the row a tightening.
2. DM1 filler: the change is labelled a loosening under §1.12, but §1.12 gives no reason (every other loosening there has one), and DECISIONS adds none.
3. Base 4: nothing that decides Done tests "worth beating". "Most reviewers say pushovers" only triggers triage. So Done passes with base 4 plainly unmet, unless a reviewer who raised it also says it must change before this playtest (C4).

Asks:
1. DM7 is labelled "tightening", but C4 and the 09d power filter loosen base 7's "the open items they agree on are fixed". It should be relabelled.
2. DM2's field fights don't fix what the field is made of. A line can be scored against its own boards in the field, and that drags it toward 50%.
3. DM2's reviewer row says "unchanged" but now reads "most final reviewers" and "together". Both are lenient readings and should be labelled.
4. The 6 Nov lines the revision leaves out have no clear status: do they still bind? DM1's "the pool count" has no target number.
5. DM5's "phone text at least 31" has no unit or way of measuring it.

**1. Base items**
- **1 Whole game:** still required. The 2,000-lobby soak and 20 UI games played to game over cover it. A scripted player stands in for "a human", which is reasonable because agents can't drag cards. Pool size depends on ask 4.
- **2 Depth:** still required in substance. "Several strategies can win" becomes 5 lines from 4 tribes winning 40%+ against the field. "None dominant" becomes the 80% cap plus the 10× fallback. Strong bot over naive is the Naive checklist, and reviewer decisions stay. The bar leans lenient: the floor passes at R12 *or* R14, while the cap fails only at *both*. Quilboar on B dials (0.75) passes the cap and is caught only at R15 by the fallback. The owner backs this leniency (09c, and 09d's "don't force it"), so I accept it.
- **3 Interesting:** still required, and the evidence file makes it stronger.
- **4 Bots:** not decided (cut 3). Both deciding items are delivery facts, and deciding 1 passes whichever default-opponent call is made. Fix: make "most final reviewers call the rivals pushovers" block Done, and move deciding 1 to the checklist. That keeps two deciding items (09i).
- **5 Release feel:** the base is kept: one look, art, readable text, clear fights, how-to-play through the Rules hub, settings, crash-free runs.
- **6 Delivered:** kept and tightened. The `/data/bramble-builds/` path and `latest` are in PLAN's Logs section and in DM6.
- **7 Agreed:** kept. Three fresh reviewers each play 2 full games of the tagged build at both sizes, which matches the owner's goal.

**2. Changes from 6 Nov**
- **Five of six tribes per lobby:** loosening, logged 8 Nov with the owner's 27 Oct "tribes per game … varied" line. Accept.
- **No filler → count:** loosening with no reason (cut 2). "0 units without rules text" passes a body whose only text is one keyword, and the reviewer line is only reported.
- **Soak, plus "no unit without a set":** tightening, correctly labelled.
- **6–25% band → field fights:** loosening with a logged reason. bars.md §5's structural point and 09d hold up. The Birds argument ("flags Birds … against the logged 'Birds: no nerf'") is circular: it drops a bar because the bar disagrees with an earlier call. Take it out of the reason.
- **Naive bar:** unchanged. "300 games" is now named.
- **Head-to-head dropped:** loosening with a logged reason (09d "okay at best", a gain of about 0.05 of a place). Acceptable, but it removes the only check that the field comes from the best bot, which feeds cut 3.
- **Placing → reported:** loosening with a logged reason (met on build 6 at +17.7; 09i). Acceptable. But "from build 6 unless rerun" means its extreme-miss trigger can't fire on build 9's much-changed pool. A skeptic would want one rerun.
- **Reviewer row:** mislabelled (ask 3). The 6 Nov text didn't say "most", and v2 read "each".
- **Re-skin by 2+ reviewers:** loosening with a logged reason (06a). Acceptable.
- **DM5:** tightened on the UI run and the cold reader. Declutter was dropped silently (cut 1). The checklist names `portraits_pending.json`, which covers only units; "unique art on every … hero and spell" isn't there.
- **DM6:** tightening, correctly labelled.
- **DM7:** the 09d filter is the owner's own direction. C4's only stated reason is "so the pass rule can end". Label it a loosening. A skeptical owner would probably accept it, since the known issues go into PLAYTEST.

**3. Bars that could be tuned to pass**
- These are not tuned to our numbers:
  - the 80% cap, which was set on the Quilboar archives;
  - the 10× fallback, which is 09c's "order of magnitude";
  - the UI slot table, which is fixed before the run.
- **The 10× fallback** was picked with our lines' 5.9–7.0× best ÷ worst spread in view. It uses best ÷ median of the others, which is smaller still, so it will rarely bite. It is acceptable because it comes from the owner.
- **The field is the open problem (ask 2).** It is defined when the library is captured, after the numbers exist, and it is "recaptured last" before every export. The more a dominant line fills the field, the closer its own score falls toward 50%, below the cap. Fix before A4: weight the field per line, score each line against the field without its own boards, say how draws count, and define "committed line".
- **The shipped default preset** is also picked late. That is fair design, but the bar is read on whatever preset ships.

**4. Ambiguity**
- **The header contradicts itself.** The 6 Nov text is "superseded where the 10 Nov revision differs", yet the revision also "decides". Honest readers will split on whether a left-out line still binds:
  - 6 tribes × 12+ units across tiers 1–6, plus neutrals and 10+ tavern spells;
  - hero and spell art;
  - full text one tap away;
  - the declutter line.

  State one rule, and restate the pool target in DM1.
- **Phone text "31":** says neither the unit nor how it is measured.
- **"Most turns overall decides":** doesn't say how the R1–5, R6–10 and R11+ answers combine.
- **DM3:** doesn't say what the fresh reviewer must find for the check to fail.
- **"Layout failure":** is not defined in PLAN.

Everything was read at commit `322a28cb`: `/home/alex/code/Bramble-ideation/docs/ideation/PLAN.md`, `/home/alex/code/Bramble-ideation/docs/ideation/plan-to-done.md` (§1, §4, §9–11) and `/home/alex/code/Bramble-ideation/docs/ideation/DECISIONS.md`.