# Wave 1 behaviour evidence

The [build doc](../../content/pass3/wave1-build.md#real-game-and-screenshot-evidence) describes methods, outcomes and all five initial visual findings. The original images and game logs below record 6a54286. Two full command-client games use normal rules, while controlled visual setup is explicitly marked in screenshot provenance. Later fixes and evidence are recorded in the [bot comparison](bot-review/README.md) and [UI before/after comparison](ui-followup/README.md).

Reproduction sources: [PlayGame command client](../../../../tools/play/wave1_games.gd), [production UI capture driver](../../../../tests/ui/shots/wave1_evidence.gd). Both run with the shared Godot lock and 3G user scope; see the replay proof and per-size metadata for exact commands.

## Images

| File | Dimensions | Criterion |
|---|---|---|
| [shop-birds-fairies-1688x780.png](shop-birds-fairies-1688x780.png) | 1688×780 | Natural turn-1 shop offers both tribes. |
| [ring-carry-away-birds-1688x780.png](ring-carry-away-birds-1688x780.png) | 1688×780 | Ring carry, half-stat Fetch overlay and two away Birds with Nest countdowns. |
| [away-nest-reader-1688x780.png](away-nest-reader-1688x780.png) | 1688×780 | Tap the bare Jay Nest: production Egg reader gives current Bird and countdown. |
| [away-sky-preview-gap-1688x780.png](away-sky-preview-gap-1688x780.png) | 1688×780 | Observed gap: clearing selection with two Birds away hides reader; no current-to-home tray. |
| [homecoming-return-1688x780.png](homecoming-return-1688x780.png) | 1688×780 | Real Start of Turn homecoming: 7/8 Swallow is 14/16 in hand; Jay remains away. |
| [homecoming-following-combat-1688x780.png](homecoming-following-combat-1688x780.png) | 1688×780 | Following combat includes the returned Swallow before attacks begin. |
| [reader-mag_pye-golden-1688x780.png](reader-mag_pye-golden-1688x780.png) | 1688×780 | Production full card reader, exact current authored text. |
| [reader-reel_mistress-golden-1688x780.png](reader-reel_mistress-golden-1688x780.png) | 1688×780 | Production full card reader, exact current authored text. |
| [reader-cradle_fetch-golden-1688x780.png](reader-cradle_fetch-golden-1688x780.png) | 1688×780 | Production full card reader, exact current authored text. |
| [reader-jack_daw-1688x780.png](reader-jack_daw-1688x780.png) | 1688×780 | Production full card reader, exact current authored text. |
| [natural-birds-mixed-shop-1688x780.png](natural-birds-mixed-shop-1688x780.png) | 1688×780 | Exact replay of the committed Birds player's accepted commands. |
| [natural-birds-ring-and-away-1688x780.png](natural-birds-ring-and-away-1688x780.png) | 1688×780 | Exact replay of the committed Birds player's accepted commands. |
| [natural-birds-first-homecoming-1688x780.png](natural-birds-first-homecoming-1688x780.png) | 1688×780 | Exact replay of the committed Birds player's accepted commands. |
| [natural-birds-homecoming-following-combat-1688x780.png](natural-birds-homecoming-following-combat-1688x780.png) | 1688×780 | Return occurs at Start of Turn 5; this is actual turn-5 fight, not the previous turn-4 fight. |
| [natural-fairies-ring-carry-1688x780.png](natural-fairies-ring-carry-1688x780.png) | 1688×780 | Naturally acquired Fairy board and permanent Ring carry. |
| [shop-birds-fairies-1920x1080.png](shop-birds-fairies-1920x1080.png) | 1920×1080 | Natural turn-1 shop offers both tribes. |
| [ring-carry-away-birds-1920x1080.png](ring-carry-away-birds-1920x1080.png) | 1920×1080 | Ring carry, half-stat Fetch overlay and two away Birds with Nest countdowns. |
| [away-nest-reader-1920x1080.png](away-nest-reader-1920x1080.png) | 1920×1080 | Tap the bare Jay Nest: production Egg reader gives current Bird and countdown. |
| [away-sky-preview-gap-1920x1080.png](away-sky-preview-gap-1920x1080.png) | 1920×1080 | Observed gap: clearing selection with two Birds away hides reader; no current-to-home tray. |
| [homecoming-return-1920x1080.png](homecoming-return-1920x1080.png) | 1920×1080 | Real Start of Turn homecoming: 7/8 Swallow is 14/16 in hand; Jay remains away. |
| [homecoming-following-combat-1920x1080.png](homecoming-following-combat-1920x1080.png) | 1920×1080 | Following combat includes the returned Swallow before attacks begin. |
| [reader-mag_pye-golden-1920x1080.png](reader-mag_pye-golden-1920x1080.png) | 1920×1080 | Production full card reader, exact current authored text. |
| [reader-reel_mistress-golden-1920x1080.png](reader-reel_mistress-golden-1920x1080.png) | 1920×1080 | Production full card reader, exact current authored text. |
| [reader-cradle_fetch-golden-1920x1080.png](reader-cradle_fetch-golden-1920x1080.png) | 1920×1080 | Production full card reader, exact current authored text. |
| [reader-jack_daw-1920x1080.png](reader-jack_daw-1920x1080.png) | 1920×1080 | Production full card reader, exact current authored text. |
| [natural-birds-mixed-shop-1920x1080.png](natural-birds-mixed-shop-1920x1080.png) | 1920×1080 | Exact replay of the committed Birds player's accepted commands. |
| [natural-birds-ring-and-away-1920x1080.png](natural-birds-ring-and-away-1920x1080.png) | 1920×1080 | Exact replay of the committed Birds player's accepted commands. |
| [natural-birds-first-homecoming-1920x1080.png](natural-birds-first-homecoming-1920x1080.png) | 1920×1080 | Exact replay of the committed Birds player's accepted commands. |
| [natural-birds-homecoming-following-combat-1920x1080.png](natural-birds-homecoming-following-combat-1920x1080.png) | 1920×1080 | Return occurs at Start of Turn 5; this is actual turn-5 fight, not the previous turn-4 fight. |
| [natural-fairies-ring-carry-1920x1080.png](natural-fairies-ring-carry-1920x1080.png) | 1920×1080 | Naturally acquired Fairy board and permanent Ring carry. |

## Logs, saves and verification

| Artifact | Bytes |
|---|---|
| [attribution-audit.md](attribution-audit.md) | 947 |
| [birds-actions.jsonl](birds-actions.jsonl) | 58,155 |
| [birds-checkpoint-first_homecoming.json](birds-checkpoint-first_homecoming.json) | 948 |
| [birds-checkpoint-homecoming_following_fight.json](birds-checkpoint-homecoming_following_fight.json) | 1,196 |
| [birds-checkpoint-mixed_shop.json](birds-checkpoint-mixed_shop.json) | 184 |
| [birds-checkpoint-ring_and_away.json](birds-checkpoint-ring_and_away.json) | 885 |
| [birds-cli-final.json](birds-cli-final.json) | 134,324 |
| [birds-cli-log.txt](birds-cli-log.txt) | 17,828 |
| [birds-fight-r01.json](birds-fight-r01.json) | 3,826 |
| [birds-fight-r02.json](birds-fight-r02.json) | 7,537 |
| [birds-fight-r03.json](birds-fight-r03.json) | 15,034 |
| [birds-fight-r04.json](birds-fight-r04.json) | 12,345 |
| [birds-fight-r05.json](birds-fight-r05.json) | 23,140 |
| [birds-fight-r06.json](birds-fight-r06.json) | 25,074 |
| [birds-fight-r07.json](birds-fight-r07.json) | 25,169 |
| [birds-fight-r08.json](birds-fight-r08.json) | 37,688 |
| [birds-fight-r09.json](birds-fight-r09.json) | 23,426 |
| [birds-fight-r10.json](birds-fight-r10.json) | 21,089 |
| [birds-fight-r11.json](birds-fight-r11.json) | 24,550 |
| [birds-fight-r12.json](birds-fight-r12.json) | 31,039 |
| [birds-fight-r13.json](birds-fight-r13.json) | 31,951 |
| [birds-fight-r14.json](birds-fight-r14.json) | 23,939 |
| [birds-fight-r15.json](birds-fight-r15.json) | 26,546 |
| [birds-fight-r16.json](birds-fight-r16.json) | 23,815 |
| [birds-fight-r17.json](birds-fight-r17.json) | 24,453 |
| [birds-fight-r18.json](birds-fight-r18.json) | 27,378 |
| [birds-fight-r19.json](birds-fight-r19.json) | 28,760 |
| [birds-game-log.json](birds-game-log.json) | 220,106 |
| [birds-playthrough.txt](birds-playthrough.txt) | 509,401 |
| [birds-round-states.json](birds-round-states.json) | 1,711,916 |
| [birds-save.json](birds-save.json) | 10,027 |
| [birds-state-first_homecoming.json](birds-state-first_homecoming.json) | 26,258 |
| [birds-state-homecoming_following_fight.json](birds-state-homecoming_following_fight.json) | 29,112 |
| [birds-state-mixed_shop.json](birds-state-mixed_shop.json) | 12,930 |
| [birds-state-ring_and_away.json](birds-state-ring_and_away.json) | 22,286 |
| [birds-summary.json](birds-summary.json) | 18,675 |
| [command-client-audit.json](command-client-audit.json) | 1,590 |
| [fairies-actions.jsonl](fairies-actions.jsonl) | 19,115 |
| [fairies-checkpoint-mixed_shop.json](fairies-checkpoint-mixed_shop.json) | 234 |
| [fairies-checkpoint-ring_carry.json](fairies-checkpoint-ring_carry.json) | 3,252 |
| [fairies-cli-final.json](fairies-cli-final.json) | 90,023 |
| [fairies-cli-log.txt](fairies-cli-log.txt) | 12,463 |
| [fairies-fight-r01.json](fairies-fight-r01.json) | 4,396 |
| [fairies-fight-r02.json](fairies-fight-r02.json) | 5,449 |
| [fairies-fight-r03.json](fairies-fight-r03.json) | 9,850 |
| [fairies-fight-r04.json](fairies-fight-r04.json) | 9,898 |
| [fairies-fight-r05.json](fairies-fight-r05.json) | 18,001 |
| [fairies-fight-r06.json](fairies-fight-r06.json) | 25,851 |
| [fairies-fight-r07.json](fairies-fight-r07.json) | 26,121 |
| [fairies-fight-r08.json](fairies-fight-r08.json) | 25,616 |
| [fairies-fight-r09.json](fairies-fight-r09.json) | 24,721 |
| [fairies-fight-r10.json](fairies-fight-r10.json) | 25,037 |
| [fairies-fight-r11.json](fairies-fight-r11.json) | 23,779 |
| [fairies-game-log.json](fairies-game-log.json) | 153,961 |
| [fairies-playthrough.txt](fairies-playthrough.txt) | 237,548 |
| [fairies-round-states.json](fairies-round-states.json) | 719,379 |
| [fairies-save.json](fairies-save.json) | 3,528 |
| [fairies-state-mixed_shop.json](fairies-state-mixed_shop.json) | 13,161 |
| [fairies-state-ring_carry.json](fairies-state-ring_carry.json) | 35,449 |
| [fairies-summary.json](fairies-summary.json) | 12,475 |
| [games-replay-proof.json](games-replay-proof.json) | 1,806 |
| [games-run.txt](games-run.txt) | 690 |
| [quality-gate.txt](quality-gate.txt) | 1,707 |
| [screenshots-1688x780.json](screenshots-1688x780.json) | 565,392 |
| [screenshots-1920x1080.json](screenshots-1920x1080.json) | 565,424 |
| [screenshots-homecoming-combat.json](screenshots-homecoming-combat.json) | 19,451 |
| [screenshots-pc.log](screenshots-pc.log) | 1,362 |
| [screenshots-phone.log](screenshots-phone.log) | 1,347 |
| [verification.json](verification.json) | 4,590 |

[SHA-256 manifest](artifact-manifest.json) covers every evidence artifact except this index and the manifest itself. Renderer layout checks report zero automatic notes; the separate visual findings are still present and documented.
