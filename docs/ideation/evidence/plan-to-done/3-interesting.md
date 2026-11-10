# Criterion 3: interesting designs (read-only check, 10 Nov 2026)

## Bar now
PLAN.md "Done means, sharpened" 3: every tribe has at least one signature mechanic Battlegrounds lacks; every tribe has some economy (owner 02h); reviewers don't call it a re-skin. Not loosened in DECISIONS.md. 09c (fun over balance) and plan v3 make "tribe identity" part of how designs are ranked, but it is not one of checkpoint 1's two deciding criteria.
Owner 02h refines economy: tie it to actions that reward being in that strategy (generic economy tends to be best at high level).

## Signature and economy per tribe

| Tribe | Signature (BG lacks) | Nearest BG/other analogue the doc admits | Economy (built unless noted) | On ideation/main? |
|---|---|---|---|---|
| Birds | Fly South: unit leaves, comes home doubled; Nest; Seven Whistlers 7-different capstone | Magic suspend; stat doublers | One Swallow (1 gold when played), Mrs Jay (Acorn when sold), Mrs Stork (gold spent -> homecoming, a sink) | pass 3, wave 1 |
| Fairies | Rings: power on slots that outlives units; Changeling brings their carry onto your Ring | Blood Gems (one number), Galaxy slot buffs | Rainbow Chaser (gold per Ringed slot on sale), Shy thanking pays 2 gold, Annis Rings on sale | pass 3, wave 1 |
| Bog folk | Mire (enemy across must attack this) + Bitter + Soak keeps what Bitter took | Provoke/Taunt, Galaxy "gain Attack removed" | Young Pretender (gold on killing a Mired enemy), Peat Cutter (Sink: 1 gold) | pass 3, wave 2a (merged 10 Nov 07:42) |
| Hunters | Quarry/Take: mark an enemy at the bell, take a share of it on the kill; Pack | Galaxy Hunt; Pelts look like Blood Gems | Toll-Bard/Lane-Bard (gold when its quarry attacks), Russet (pool copy) | pass 3, wave 2a |
| Oozes | Belly/Eat + Stone Soup (shop grows with your biggest Ooze) | BG Demons eating the tavern; Nomi | pass 2 shipped: Little Dollop (-1 gold buying into it), Dishwater Nell, Sixpenny Pie; pass 3 keeps Dollop | pass 2 shipped; pass 3 on ideation/wave2b (c66a88e5), not merged |
| Hedgerow | Larder (Acorn/Stash/Great Hoard held or cashed), Pass, Dozey doubles every 3 turns in his slot | Blood Gems (food spent now or later) | Larder itself, Old Mother Mast, Sleeping Partner, Treasurer | pass 2 shipped; pass 3 "light pass" not started (wave 2b next) |

Paper verdict: cross-tribe.md §1 (9 Nov) "six engines and six verbs... yes, they feel different". Weak points named: Bog's answer identity vs its 55-68% carry; Birds effectively one route; Hedgerow Treasury plans to lose two rounds.
Breakers flagged Blood Gem sameness in drafts (birds-breaker, hunters-breaker, fairies-breaker); syntheses removed tribe numbers (birds-pass3.md:589, hunters-pass3.md:624). Fairies still name Blood Gems as the analogue for Ring size; Hedgerow Larder is the closest to a BG port.

## Reviewer evidence
- Played, latest with an identity lens: pt4-a/b/c (8 Nov, build 6 927b0b7, pass 2 content). No one said re-skin; each found 3 different builds. Thin: "Hunters play themselves", "Quarry played itself", "Birds clunky/thin", "Belly felt like storage". All on content since rebuilt (Birds/Fairies/Bog/Hunters) or being rebuilt (Oozes).
- playtest-3 (8 Nov build 4): Bog "distinct and very fun", Oozes "most distinct".
- fun probe (10 Nov, wave 1 Birds/Fairies): reward lens only; no re-skin question. 3/3 go.
- No played review of pass 3 Bog/Hunters, pass 3 Oozes or Hedgerow. No reviewer was ever asked "is any tribe a BG re-skin?" directly.
- Quilboar reference tribe (ideation/quilboar) is guarded test-only (reference_quilboar.gd: absent from exports). Must stay so.

## Missing
1. Evidence file `evidence/interesting-designs.md`: per tribe, signature + BG analogue + why different, economy cards + the action they reward, from shipped content. Small. Can draft now for 4 tribes; finish after wave 2b. Local Claude workflow.
2. Add an explicit re-skin/identity question to the checkpoint 1 and final playtest briefs. Small, now.
3. Played verdict on the full pass 3 pool: reviewers name each tribe's mechanic and say whether any tribe feels like a BG tribe. Medium, folds into checkpoint 1 / final review. Depends on wave 2b + step 5. Cloud Claude sessions.
4. Hedgerow pass 3 light pass must keep a non-BG signature (Dozey's slot clock, the Committee's weakest-member pay) and its tribe-tied economy. Part of wave 2b; Codex worker.
5. Neutral economy (Money Spider, Cricket Busker, Sexton Beetle, Charcoal Burner) is generic; 02h risk that it out-earns tribe economy. Check in step 5 lobbies (tribe vs neutral gold). Small, after pool settles.

## Risks
- Hedgerow Larder and Fairies Ring size are Blood-Gem-shaped; a reviewer could call them re-skins.
- Hunters and Birds were the thin/"plays itself" tribes in the last played reviews; pass 3 rebuilt them but nobody has played Hunters pass 3.
- Template risk (fundamentals-audit/plan-review.json): one compounding template per tribe could read as six "this game" Undead/Beast re-skins at scale.
- If wave 2b dial-backs or retire-38 cuts remove the only economy card of a tribe (Bog has 2, Birds' income is 1 card), the economy leg breaks.
