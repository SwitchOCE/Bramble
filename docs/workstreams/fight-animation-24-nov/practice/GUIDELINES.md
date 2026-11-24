# Bramble motion guidelines (draft, 24 Nov 2026)

**Draft for the owner.** Step 2 of [PLAN-animation-practice.md](../PLAN-animation-practice.md). No rule here binds anyone until the owner says so. The process that uses these rules is [PROCESS.md](PROCESS.md).

**How to read a rule.**
- **Numbers are starting points**, at 60 fps (f = one frame, 16.7 ms). The owner, 18 Nov: "I'm more worried about feel than a specific timing, but obviously specific timing needs to be kept in some ways for feel." A number tells you where to start and what to flag. It never overrules the owner's reaction to a film.
- **Check** says how the rule is tested. **Log** = the per-frame engine log of a `tools/feel` film (position, turn, scale, opacity, markers per drawn frame). **Film** = frames or strips from the film. **Code** = a grep or a headless test. **Owner** = only the owner can judge it.
- **Sources.** R1 = Battlegrounds measured ([research/battlegrounds.md](../research/battlegrounds.md)). R3 = our attack measured ([research/our-attack-measured.md](../research/our-attack-measured.md)). FR n = rule n of [feel-research.md](feel-research.md) §7. LB n = lesson n of [look-back.md](look-back.md). INV = [inventory.md](inventory.md). Owner quotes are dated.

## 1. The motion vocabulary

The owner, 24 Nov, on Thorns: "we're trying to communicate it using the same language as an attack, when it's not an attack; it's something else … We need alternate animations for other effects that don't just use movement, but also use additional assets." Every effect below belongs to one family with buffs and combos (pass 2, thread 9): **cause → path → landing on the thing that changed → the number.**

| # | Rule | Why, source | Start | Check |
|---|---|---|---|---|
| V1 | **A card travels toward another card only when it attacks.** Nothing else lunges, jabs or flies a card across the board. | Owner on Thorns, 24 Nov. Hearthstone avoids motion that looks like a mechanic it isn't (feel-research §2.10). | – | Log: card travel toward another card outside an `attack` event = fail |
| V2 | **A trigger acts in place.** The source lifts or pulses where it stands. What it does reaches the target as a drawn piece, or lands on the same frame as the source moves. | Today a trigger has "no line, projectile or motion" to what it does (R3). Balatro links cause by timing; Snap and LoR by something travelling (buff-look §1). | Source pulse 6 f (today's lift) | Log: source travel ≤ its lift; effect lands ≤ 3 f after the piece arrives |
| V3 | **Damage that isn't an attack gets its own drawn piece.** Thorns first, then effect damage (Gleaner, Plague) and death damage. Thorns: the owner's ideas are "a thorny vine whipping out and striking them", or "the unit hitting and then flinching". | Owner, 24 Nov. INV F10, F11: gaps today. | – | Owner (does it read as not-an-attack); Film (the piece draws) |
| V4 | **A stat change draws the eye to the stat, not the card.** The changed disc swells, the amount shows next to it ("+N"), the cause is shown, and repeats sum into one running total. No whole-card flare that hides the number. | Owner, 24 Nov: "very hard to tell what happened … I should be focused on the part of the card that's changed." "We shouldn't just draw from Battlegrounds in this regard." Hearthstone's flare hides the number; Backpack Battles' stacked numbers are unreadable ([buff-look/DESIGN.md](../buff-look/DESIGN.md) §1). | Disc ×2.0, count over 8 f, tag holds 24 f after the last gain (buff-look B, proposal) | Log: only the changed disc scales; Film: digits readable |
| V5 | **One trigger many times plays as a combo**: a ×N count with the running total on the target, a small splat per stacked hit, rising pace. | Owner, 18 Nov ("Combo ×3, ×4 … rises up at increasing pace") and 24 Nov ("a ×11 … and you can see the cumulative damage"). Ideas, not specs. [combo-look/ART-DIRECTION.md](../combo-look/ART-DIRECTION.md). | Gaps ×0.75 per repeat, floor 5 f (best proposal) | Log: each gap ≤ the one before |
| V6 | **A lasting state is drawn on the card; its change is a short drawn event.** Shield breaks, venom applies, stealth lifts. | INV F13: keyword and status changes are gaps. | – | Film; Owner |
| V7 | **Every new drawn piece is lead and stained glass**, gets its own design pass, and is shown to the owner as a picture first. | Art direction, 15 Nov. Owner rules of 22 Nov (PROCESS.md step 4). | – | Owner |
| V8 | **Gains and losses look like a pair.** Same family, opposite sign and direction, never colour alone. | Accessibility skill (colour-blind cues). [unsourced pairing; to confirm] | – | Film (sign drawn); Owner |

## 2. Shared easing and pop tokens

Today one "ease out" means four different curves: Godot Tween transitions, `GlassMotion`'s CSS beziers, hand-rolled curves and a spring (INV inconsistency 1). Number pops differ in size, length and curve for the same meaning (INV inconsistency 2). One table ends that.

**Rule S1: every motion uses a named token from one module.** No raw `TRANS_*`, bezier or hand-rolled curve outside it. The module and its implementation are the builder's choice (proposal: extend `src/glass/glass_motion.gd`). *Why:* Cooper, one exaggeration level per project; FR 28. *Check:* Code, a grep for raw curves outside the module.

| Token | Use | Start | Source |
|---|---|---|---|
| `ease.enter` | Arrives on screen | Decelerate, `cubic-bezier(0,0,0.2,1)` | Material; FR 3 |
| `ease.exit` | Leaves the screen | Accelerate, `(0.4,0,1,1)`; about 85 % of the matching entry | Material; FR 2 |
| `ease.move` | Rest to rest | Standard, `(0.4,0,0.2,1)` | Material |
| `ease.strike` | Attack into contact | **Speeds up into contact. Never constant speed.** Today's quad-in, a mild and a gentler speed-up are under test. | Owner, 24 Nov: "The constant, linear stuff … was very bad"; "maybe even a slower speed-up would be better" |
| `ease.return` | Home after contact | Fast first, cubic out | R1, R3 |
| `ease.fall` | Death fall | Accelerate (quad in today) | R3 |
| `ease.pop` | Number, tag, landing | One overshoot frame and back | Cartwright; FR 4 |
| `spring.carry` | Drag | Keep `CardCarry`'s spring | Owner tuned it, 17 Nov ("feels way better") |
| `pop.number` | A number changes | ×1.5, 14 f, `ease.pop` (today's card numbers) | INV inconsistency 2 |
| `pop.plate` | A counter plate changes | ×1.25, 14 f, `ease.pop`; drop today's in-out dip | INV inconsistency 2 |
| `pop.emphasis` | The stat that changed in a fight | ×2.0, back in 11 f | buff-look A (proposal) |
| `pop.contact` | Attacker at contact | ≤ ×1.25 for 1–2 f, back to 1.0 within 5 f | R1; FR 8 |

**Build rules that keep tokens honest.** *Why:* Godot pitfalls ([agent-skills-survey.md](agent-skills-survey.md), gamedev-skills credit); the shop glow that never drew (LB 9).

| # | Rule | Check |
|---|---|---|
| S2 | Every effect ends exactly at rest: scale 1, turn 0, home position, `Engine.time_scale` 1. | Code: headless assert at the end of each fixture |
| S3 | One tween owns a property at a time. Kill before re-creating. Tween `modulate:a`, not `modulate`. | Log: no velocity sign flip or 3× speed jump outside marked frames (FR 27) |
| S4 | Motion and sound run on game time and scale with fight speed. No wall-clock timers. | Code: grep `get_ticks_msec` in motion and sound; Film at speed 1 and 2, markers scale. Today the plate pop and sound delays leak (INV inconsistency 5). |

## 3. Timing and ordering

The owner, 18 Nov: attacks "can change and vary a bit. They shouldn't vary too much … we need to make sure we don't have wildly disparate stuff." Fix ordering before polishing motion (LB 6): much of the fight's bad feel is when things play, not how one card moves.

| # | Rule | Why, source | Start | Check |
|---|---|---|---|---|
| T1 | **The shop answers at once.** No anticipation before the response; weight goes in the settle. | Swink, NN/g (FR 1, 4) | First change ≤ 6 f after input, aim for 1; one overshoot ≤ 10 % | Log vs `.events` press frame |
| T2 | **UI motion is short; exits shorter than entries.** | NN/g, Material (FR 2) | Feedback 6 f; panels 12–18 f; under 30 f unless a ceremony | Log markers |
| T3 | **The fight shows who acts next**: a visible wind-up, then a still hold. | Owner, 24 Nov: "the wind-up being very clearly visible … That's really important." Ours is 4 f (R3). | Lift 9–11 f, hold 14–22 f; never under 6 + 9 sped up (R1) | Log: plateau before first forward frame |
| T4 | **The strike takes a fixed short time, whatever the distance, and the card aims.** The point facing the target leads: the top of your cards, the bottom of theirs. | R1; owner, 24 Nov ("the card should tilt or rotate to point at what it's hitting"; leading point settled, pass 2 thread 8) | 5–8 f; aim angle under test | Log: frames first-forward → contact; turn per frame |
| T5 | **The target reacts within 3 f of contact.** Later than that, the hit looks like a miss. | Michotte (FR 7). Ours is +3, at the edge (R3). | 0–3 f | Log: contact → first target change |
| T6 | **Never freeze the actor for a trigger.** Strike and return run unbroken; triggers play after; waits go into the next actor's hold. | Owner, 24 Nov: "I don't think they pause mid-animation." Ours freezes 23–41 f (R3). | 0 f of unplanned stop | Log: attacker speed < 0.5 px/f for > 2 f outside planned holds |
| T7 | **Group one event, sequence separate ones, overlap the seams.** One trigger on many targets is one beat. The next wind-up may start in the last effect's tail. | R1 (T1, T3); FR 14, 15 | Dead air ≤ 6 f (proposal) | Log: runs with nothing moving between events |
| T8 | **Long chains and fights speed up, then slow for the finish.** | Owner, 18 Nov; Battlegrounds 31.6 patch (FR 16) | Late cycle about half the early one; last attack at normal speed | Log: attack-to-attack period over a long fixture |
| T9 | **No single attack runs wildly long.** Repeats aggregate (V5) rather than queue. | Owner, 18 Nov: Battlegrounds "one attack could take … 3 or 4 seconds". | Flag any attack cycle over 120 f (2 s) [proposal] | Log, over the long fixtures |
| T10 | **Frequent beats are short; the attack itself is not cut.** The fight is the content, not chrome. | NN/g; Hearthstone 0.8 → 0.2 s triggers (FR 17); survey ("What not to take") | Per-trigger beat ≤ 12 f | Soak log: count × length per game |
| T11 | **Impact sound lands on the impact frame.** | ITU-R BT.1359 (FR 19) | −2 to +7 f, aim 0–1 | Owner, until a game-time sound log exists |

## 4. Emphasis and rarity

Loved moments are rare or earned, escalate, stay legible, and can be skipped once seen (feel-research §4). Juice has an optimum, not a maximum (Kao 2020).

| # | Rule | Why, source | Start | Check |
|---|---|---|---|---|
| E1 | **Every event has a tier, and each tier a fixed bundle.** See the table below. | gamedev-skills feedback tiers (survey); Sakurai "stop for big moments" | – | Code: each event maps to a tier |
| E2 | **Keep an emphasis budget.** Shake, long hit-stop, full-screen flash and slow motion go only to the top tiers. | Kao; DMC5, Bayonetta (FR 20) | ≤ 1 event in 5 in a typical fight [proposal] | Log: share of events with offset, flash or freeze |
| E3 | **Chains escalate**: each repeat a little faster and higher in pitch. | Balatro, +1.6 % pitch per trigger (buff-look §1); FR 18 | Each gap ≤ the last | Log; sound log for pitch |
| E4 | **Shake is directional, scales with the event, dies fast.** | Eiserloh trauma², Celeste (FR 21) | ≤ 20 px at 1080p, gone in 12–30 f | Log: camera offset |
| E5 | **Rigid cards pop; they don't bend.** | R1; FR 22. Whether glass may bend or crack is art direction. | Uniform ≤ ×1.3 | Log: scale x = y; Owner for bending |
| E6 | **Spectacle never hides the number.** | Hearthstone's buff flare (buff-look §1) | – | Film: digits visible on every frame of the effect |
| E7 | **Long ceremonies can be skipped once seen.** | Vampire Survivors (FR 23) | Skip ends it ≤ 6 f | Scripted skip in a film |

| Tier | Events | Bundle (start) |
|---|---|---|
| 0 | Idle, hover | Small, slow, quiet; no flash |
| 1, frequent | Hit, trigger, buff, number change | Pop and flash; hit-stop 0–2 f; no shake |
| 2, big | Death of a big unit, hit over a threshold, golden, a combo's last hit | Adds hit-stop 4–8 f on the two cards only; short directional shake |
| 3, rare | Triple, damage to the player, elimination, the result | May be long; freeze up to 12–20 f; shake; skippable once seen |

## 5. Deaths, damage to the player and other flagged moments

The owner, 24 Nov: "death animations in general might need work, and the player taking damage after a fight as well."

| # | Rule | Why, source | Start | Check |
|---|---|---|---|---|
| D1 | **A death reads after the hit, breaks fast, leaves a short trace, and looks unlike a hit or a fade.** Today's 15 f drop was made under brief 10's time limit and never judged (LB 2, 3). Brief 10's death references: Galaxy's card knocked spinning off, Battlegrounds dust, the LoR crack, the MTGA dissolve. | R1; FR 12 | Starts 30–68 f after the hit (ours 37); break 5–10 f, trace about 20 f | Log; Owner |
| D2 | **Deaths that happen together may fall one at a time.** Stagger options A–C in [research/mass-deaths.md](../research/mass-deaths.md) are to be filmed. | Owner, 24 Nov: "it would feel more realistic if they dropped off one at a time, and more impactful." | Option C: gaps 10 → 7 → 5 → 4 → 4 f | Log; Owner |
| D3 | **Damage to the player is a tier-3 moment**: a cause from the winner's side, an impact on the portrait, Health counting down so the amount reads. Accepted 21 Nov (bolt, shake, count-down), never built. | INV G2; LB 10 | – | Film; Owner |
| D4 | **Arrivals are as strong as departures.** Summons, returns and the new shop get motion, not a plain 0.18 s fade. | INV inconsistency 4 | Use `ease.enter` and `pop.*` | Log |
| D5 | **Every screen change has a transition.** The move into the fight, the result, elimination and the way back snap today. | INV gaps (E2, G1–G5) | Panels 12–18 f (T2) | Log |
| D6 | **A number change shows where it came from**, in the shop as in the fight. | INV gaps (D3–D6, C3, F12) | As V4 | Film |

## 6. Accessibility

| # | Rule | Why, source | Start | Check |
|---|---|---|---|---|
| A1 | **No harmful flashing.** | WCAG 2.3.1, XAG 118 (FR 24) | ≤ 3 general or red flashes in any 1 s, unless the area is under about 640 × 480 px at 1080p | Film: per-region luminance, sliding 60 f window. Fully automatic. |
| A2 | **Reduce, don't remove.** With reduced motion on: no shake, travel and scale replaced by short fades or cuts, every marker on the same frame ±2. Shake and flash get their own sliders. | WCAG 2.3.3, XAG 117, Val Head (FR 25); accessibility-review skill | – | Film with the setting on. The game has no setting yet; Godot's `accessibility_should_reduce_animation()` is unchecked on 4.7.2. |
| A3 | **No spin, big zoom or parallax on decoration.** | WebKit vestibular triggers (FR 26) | Decorative turn ≤ 15°, no continuous spin | Log: non-gameplay nodes |
| A4 | **The fight can be slowed and stepped.** | accessibility-review skill | – | Film at the slowest speed |

## 7. Whether it feels good

**F1: weight, satisfaction, charm, "does it feel right", and fit with lead and glass are the owner's.** Agents bring a film, strips, the speed chart and the rule results above. *Why:* [AGENT-BLIND-SPOTS.md](../../../AGENT-BLIND-SPOTS.md) §1; FR 29. Passing every rule here does not make an animation good. *Check:* Owner, at real speed, on his PC.

## 8. Mistakes agents make (from our own history)

| Mistake | Where it happened | Instead |
|---|---|---|
| Fitted motion into a frozen time budget, then didn't reopen it when the limit lifted | Brief 10: 4 f wind-up, 0.3 s death; limit lifted 18 Nov, nobody went back (LB 2) | Name each limit and what it squeezed; reopen when it lifts |
| Picked a measured reference number over feel | Linear strike "because it is measured"; owner: "very bad" (LB 5) | A reference number is a candidate; film it against an alternative |
| Called untouched work "keep" | Deaths "keep (motion)" in the fix round (LB 3) | "Keep" means someone judged it good; else "not reviewed" |
| Checked a setting, not drawn pixels | The shop glow's pulse never drew; its test passed (LB 9) | Check pixels; prove the check fails on the broken version |
| Read references too coarsely, or only positions | 10 fps strips for 4 f motions; rotation never logged (LB 7) | 60 fps; log angle, scale and light as well as position |
| Showed too many options, or options too alike | Seven panes; a 4 f vs 6 f wind-up (LB 4) | Two options, one difference, visible at speed |
| Took "matches the prototype" as "good" | PR 250 copied HTML prototypes no one had felt (LB, §5) | Faithful copying proves fidelity, not feel |
| Polished motion when ordering was the fault | Brief 10 polished the lunge; the attacker still froze at contact (LB 6) | Fix ordering first |
| Read a blanket yes as approval of a new visual element | The type strip on every card, 22 Nov | A picture and an explicit yes, each time |
| Cropped existing art for a new element | Two-part card frames, 22 Nov | A full design pass with generated art |
| Used the attack's movement for an effect that isn't an attack | Thorns (owner, 24 Nov) | Use the vocabulary (V1–V3) |
| Invented a new curve or pop per feature | Four motion systems, four number pops (INV) | Tokens (S1) |
| Timed motion or sound by the wall clock | Plate pop and sound delays ignore fight speed (INV) | Game time (S4) |
| Read a council or agent play-test pass as a feel verdict | Council's 13 findings, none on feel; two play-tests passed a drag that felt wrong | Say what no check could see |
