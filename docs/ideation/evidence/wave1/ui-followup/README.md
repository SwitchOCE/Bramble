# Wave 1 UI follow-up

Before UI source: `95128ed`. Final after UI source: `695e156` (tray/layout in `82b4b21`, followed by the displayed-offer counting correction). The attribution clarification is `e597932`. All follow-ups are new commits.

Later correction: the overview images here exposed a blank B2 Redbreast label after Ring space was reserved. [The follow-up fix, layout test and corrected overviews](../redbreast-label/README.md) preserve the complete name. These earlier comparison images are retained unchanged.

The twelve full-window PNGs below use identical input states, production UI widgets and the same capture driver. `FixturePort` reads the saved controlled recruit snapshot from `screenshots-1920x1080.json`, capture `ring-carry-away-birds`. This preserves the two away Birds, large Ring count, long shop names and historical Ring size 1.25 across both phases. It does not run or modify gameplay. Both requested resolutions are native captures, with no cropping or image editing.

| Scene | Phone before | Phone after | PC before | PC after |
|---|---|---|---|---|
| Overview: forecasts, economy controls, shop names and Ring badges | [1688×780](ui-before-overview-1688x780.png) | [1688×780](ui-after-overview-1688x780.png) | [1920×1080](ui-before-overview-1920x1080.png) | [1920×1080](ui-after-overview-1920x1080.png) |
| Ring carry selected: compact board labels and End Turn subtitle | [1688×780](ui-before-ring-reader-1688x780.png) | [1688×780](ui-after-ring-reader-1688x780.png) | [1920×1080](ui-before-ring-reader-1920x1080.png) | [1920×1080](ui-after-ring-reader-1920x1080.png) |
| Selection cleared: the away forecasts remain available | [1688×780](ui-before-away-tray-1688x780.png) | [1688×780](ui-after-away-tray-1688x780.png) | [1920×1080](ui-before-away-tray-1920x1080.png) | [1920×1080](ui-after-away-tray-1920x1080.png) |

The tray shows One Swallow **7/8 → 14/16, home in 1 turn**, and Mrs Jay **7/7 → 14/14, home in 2 turns**, including their Nest slots. It occupies its own panel below the hand and stays visible while a card is selected. Gold, Tier up, Refresh, Freeze and End Turn retain their normal controls. While Birds are away or waiting on the doorstep, the hand uses compact tiles and its existing picker, leaving the remaining column height for a scrollable forecast. Large flocks remain accessible without reducing the font. Empty sky restores the normal hand layout.

The forecast font is **31 canvas pixels**, or **22.39 window pixels at 1688×780** (11.19 points at 2×). The title is 34 canvas pixels. No phone text is shrunk below the shared minimum. The two-Bird capture fits in the tray; the full-hand test also exercises a longer list, replaced Nests, compact k/m stats and a doorstep Bird.

Counted Rings use a gold **×count** badge in the slot's name strip. Each slot chip and remaining unit-name space is reserved independently; large counts use the shared compact-number formatting. Full Ring stats remain in the selected slot's reader, and Ring size remains in the shared header. The End Turn subtitle is moved clear of the leaf rim, with its compact title using the normal leaf-button font. Crowded PC shops use the smaller existing tile gap, name measurement matches the Label's actual smart-wrap rules, and names reserve room above the stat badges. PC name fonts can range from 34 down to the shared minimum 31 to keep words intact. His Highness's comma and Jenny Greenteeth's name now remain with their words.

Visual inspection of both sizes found no remaining overlap, cutoff or broken PC word in these scenes. The new count badge intentionally leaves full Ring stat totals to the selected reader. Longer forecast lists scroll. The original fractional Cluricaun trigger-chip limitation is a separate historical finding and is not exercised by this UI scene.

[Independent verification](verification.json) checks all twelve PNG dimensions and hashes, identical before/after state dictionaries, the two exact forecasts, the minimum font and empty automated layout-note lists. Per-phase state and geometry: [phone before](before-1688x780.json), [phone after](after-1688x780.json), [PC before](before-1920x1080.json), [PC after](after-1920x1080.json). Renderer logs: [phone before](before-1688x780.log), [phone after](after-1688x780.log), [PC before](before-1920x1080.log), [PC after](after-1920x1080.log). The logs contain only the renderer's existing unsupported V-Sync warning, with no script errors.

The original artifact manifest's `attribution-audit.md` entry was refreshed for the requested clarification; its other 98 entries and original image/log contents remain unchanged. The original index now links these follow-ups.

## Reproduction

Capture driver: [wave1_ui_followup.gd](../../../../../tests/ui/shots/wave1_ui_followup.gd). At the after source checkpoint, run:

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G timeout 180 xvfb-run -a -s '-screen 0 2560x1440x24' godot --rendering-driver opengl3 --audio-driver Dummy -s res://tests/ui/shots/wave1_ui_followup.gd -- 1688x780 after docs/ideation/evidence/wave1/ui-followup
```

Repeat with `1920x1080`. Before captures were made before changing any UI source. To reproduce them later, extract `git archive 95128ed` under `/tmp`, copy this capture driver into that archive, import it under the same lock/cap, and run with `--path <archive>` and phase `before`. Keep outputs separate when comparing historical captures.

## Validation

Focused UI tests cover the real recruit screen at both sizes, forecast text, font minimum, persistent visibility, unobstructed actions, a full hand and scrollable flock, empty-sky restoration, whole-word PC names, End Turn subtitle clearance and Ring badge geometry. The existing 22 held-view tests and all 16 card-widget tests also pass after updating the old tray-format expectation.

Focused logs: [tray and layout, 10 tests](tray-and-layout-tests.log), [Ring badge geometry](ring-badge-tests.log), [card widgets](card-tests.log), [held views](held-view-tests.log).

The initial locked 3G gate on `82b4b21` passes all 1,797 tests and 29,513 assertions, with the strict hook clean; [initial gate log](quality-gate.log). The [final gate on `695e156`](quality-gate-final.log) also **passes all 1,797 tests and 29,513 assertions across 164 scripts**, strict hook clean, with all other checks passing and 496 source files compiled. The after captures were refreshed on `695e156` after that gate. The gate ran as:

```sh
source /opt/bramble/env.sh
flock /tmp/bramble-godot.lock systemd-run --user --scope -p MemoryMax=3G timeout 1800 ./scripts/check.sh > docs/ideation/evidence/wave1/ui-followup/quality-gate-final.log 2>&1
```
