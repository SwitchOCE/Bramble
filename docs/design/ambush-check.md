# Ambush: brief-7 comparison

**Direct-strike replacements are much lower; the full-card bar has ties.** Master of Engines is **×4 / ×4 → ×1 / ×1**; Catapult **×2 / ×1.75 → ×1 / ×1**; Pile on **×2.5 / ×1.75 → ×1 / ×1**; Ballista **×2 / ×2 → ×1 / ×1**; Lieutenant **>×6.5 / ×1 → ×1 / ×1**. Pairs are **built around / all ten**, total normalized carrying-unit stats, including its body.

Ambush deals **quarter Attack rounded up, once per unit per fight across every source**. Ballista fires at the opening; Pile on before a neighbour's exchange; Catapult before its first ordinary attack, then trades normally. Master reinforces only the leftmost back unit by +4 Attack (+8 golden), then asks for that unit's one Ambush. Bodkin changes only pile-on damage to half Attack (75% golden), never adds uses. Lieutenant gives temporary row Health instead of damage.

## Every affected card and indirect giver

Unlike the four earlier isolated-effect prices, these trials retain the carrying card's complete combat text. Its body is reset to the same fixed-case size, other board units remain plain, and no recruit-phase action is simulated. Existing gold, acquisition costs, a fully tribal board and actual printed-stat differences are not priced.

| Card | Old built / all ten | New built / all ten | Set-up cases old / new |
|---|---|---|---|
| Cousin | ×2.5 / ×1.75 | ×1 / ×1 | 6 / 6 |
| Needle Page | ×2.5 / ×1.75 | ×1 / ×1 | 6 / 6 |
| Hedgerow Scout | ×1.5 / ×1.25 | ×1.5 / ×1.25 | 7 / 7 |
| Harvest Piper | ×2.5 / ×1.75 | ×1 / ×1 | 6 / 6 |
| Shrew Cutpurse | ×2.5 / ×1.75 | ×1 / ×1 | 6 / 6 |
| Thimble Captain | ×1.5 / ×1 | ×1.5 / ×1 | 5 / 5 |
| Needle Pikeman | ×3 / ×2.5 | ×1 / ×1 | 9 / 9 |
| Toothpick Ballista | ×2 / ×2 | ×1 / ×1 | 10 / 10 |
| Spoon Catapult | ×2 / ×1.75 | ×1 / ×1 | 8 / 8 |
| Fencing Master | ×2.5 / ×1.75 | ×1 / ×1 | 6 / 6 |
| Master of Engines | ×4 / ×4 | ×1 / ×1 | 7 / 7 |
| King Speck | ×3 / ×3 | ×3 / ×1.5 | 7 / 7 |
| Dame Bodkin | ×2.5 / ×1.75 | ×1 / ×1 | 6 / 6 |
| Lieutenant | >×6.5 / ×1 | ×1 / ×1 | 2 / 2 |

**Where the requested bar is not demonstrated:** Hedgerow Scout and Thimble Captain tie in both summaries; King Speck's built-around median also ties, though its all-ten median halves. Their body engines and summon counts are unchanged. The Cousins they create have the much weaker one-use Ambush, but much of the measured value comes from the same extra bodies. The narrower frozen layouts and final-Health measure can also hide the lower sublethal damage. Lieutenant's all-ten median is already the ×1 floor because eight cases have no qualifying slot setup. No averaging rule, layout, stat parameter or measure was changed to remove those ties. A full numerical pass for every card is therefore **not claimed**.

New ×1 scores mean no visible final-Health improvement in the median case, not “the ability has no value.” Ballista and Master still reach ×3 in fragile-backline case 8: quarter of the reinforced Attack can kill a 5-Health unit. Bodkin reaches ×3 in cases 8 and 10. The capstone is still a real payoff; the review must not treat the median as a guarantee of weakness in every matchup.

The optional scope question is whether to preserve summon output and report these ties, or also reduce the affected body engines to pursue the numerical bar. Until directed otherwise, the implementation keeps their summon counts and token bodies: changing those to force a lower score would also rebalance the non-Ambush value.

## Frozen method and setup

The [power check](power-check.md) is unchanged in its ten layouts, B=10, S=10, eight plain-stat comparisons, `_matches` and `_median`. Each run is **220 small fights: 80 reusable plain comparisons plus 14 cards × 10 cases**. No extra boards, seed sweep, bots or whole games were used for these numbers.

Setup was specified before either run: a card must actually fire (Hit/Ambush event, summon, or positive buff). Both old and new use that rule, retaining poor outcomes. Historical Lieutenant needs positive opening damage; its replacement needs a positive temporary Health buff. There are no no-op hook calls counted as setup. The set-up counts match old/new for all fourteen cards. Source IDs, normal copies, seed 1 and alternating sides are fixed. Spent Ambush uses persist through returns and across gifted triggers; a newly summoned Cousin is a new unit.

Old content is read from **`2e0b9081`**, not reconstructed from the new rules. The small exporter copies its Mouse/Pigeon/shared `.gd`/`.json` into ignored `build/ambush-baseline` and remaps only their preload paths. The existing engine `hit` primitive retains its original truncation by default. Only Ambush requests rounding up through the new optional flag; historical fights therefore keep their old damage semantics. No other tribe's gameplay effects changed.

## Rerun

With that baseline commit available locally, from the repository root run:

```sh
python3 tools/research/ambush_baseline.py
godot --headless -s res://tools/checks/power_check.gd -- --cards res://build/ambush-baseline
godot --headless -s res://tools/checks/power_check.gd -- --cards
```

Each invocation prints all ten card answers, setup flags, final margins and both medians. The normal `power_check.gd` mode still runs the isolated live effects and +50% buff control; parameterless Catapult/Ballista now take `{}`, and Master takes `{"attack":4}`. The baseline exporter needs the old commit object; the stacked `night/ambush` branch includes it. On a fresh squashed checkout, obtain that reviewed parent commit before exporting. Neither command changes Git branches or history. In a restricted environment use writable `XDG_DATA_HOME` and `XDG_CONFIG_HOME`.

Choices and the owner's approved exception: [taste-ambush.md](../workstreams/night-18-nov/taste-ambush.md). The old frozen tables in `power-check.md` remain historical evidence, not live-content ratings after brief 7.

Verification: `./scripts/check.sh` passed all steps before commit: **729/729 tests**, 360 compiled resources, film, 10 mixed-content and 5 shipped-content soak games, zero violations, and all six fault plants detected. Focused content tests passed 333/333. The normal live-effect check also passed its +50% control in all ten cases (160 fights). Old and new full-card runs each used 220 fights and finished normally. All Mouse/Pigeon printed stats and tiers were compared against the baseline and remained unchanged.
