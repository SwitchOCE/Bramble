# Criterion 6, Delivered: gap notes (10 Nov 2026)

## Bar now
- PLAN.md "Done means" item 6: Windows and Android builds on the portal, with a playtest guide.
- PLAN.md "sharpened" item 6 (6 Nov): each with a README.txt, plus PLAYTEST.md. No later DECISIONS entry loosens it.
- Linked from criterion 7: the guide must say no real device was tested.
- plan-scale-rework.md v3: step 6 says the portal build carries presets B and C as a setting. Step 4/7 says build 8 is the delivered build, with Windows, Android and `latest` alongside playtest round 6.

## What exists
- 11 builds in /data/bramble-builds. `latest` -> 1108-2016-ideation7 (8 Nov 20:17). The folder has Bramble.apk (91 MB), Bramble-windows.zip (68 MB), linux/, and a README.txt whose first line is "Ideation build 7: ...".
  - Logs: wine and linux boot ("boot: main scene ready"), gate, UI run.
  - Signing: android-signing.txt (CN=Godot debug cert, SHA-256 e72ece95...), with build5/6/7 certificate files that match.
- Portal (bramble-portal.service, port 8780, Bramble-portal on portal/main, tools/portal/lib/builds.js) lists every dir with a README.txt automatically.
  - /builds shows Build 7 as latest, with APK and Windows zip download links.
- docs/ideation/PLAYTEST.md (last change cd0e4f14, 8 Nov 22:32). It says no real phone was tested and nobody has heard the sounds.
- scripts/export_smoke.sh (last change 44c73292, 10 Nov):
  - Linux: boots headless.
  - Windows: checks the pack and the product name.
  - Android APK: REQUIRE_ANDROID=1.
  - Pack listing: levers and pass3 rates must be in it; content/fields must NOT be in it.
- export_presets.cfg: 4 presets. Android version/code=1 and name 0.0.1 on every build.
- At the reviewed baseline, delivery wrappers were hand-copied for each build with the number hard-coded. They have since been deleted; `build/export.sh` is the single entry point, and Git retains the historical wrappers:
  - apksigner cert compare against builds 5 and 6;
  - wine boot;
  - zip and APK integrity;
  - the README heredoc;
  - `ln -sfn latest`.
- Keystore: /opt/godot-data/godot/keystores/debug.keystore (3 Nov). It is copied into XDG for each export. It is the only copy found.

## Gaps
1. Build 8 doesn't exist. Build 7 predates arm B damage, pass 3 tribes, the strong field, declutter and presets B/C.
2. The portal's /playtest ("Full playtest guide", linked from the home page) serves docs/prototype/PLAYTEST.md from proto/main, the 4 Nov prototype guide. Cause: workstreams.json has "playtest": {branch: proto/main, ...}. That file is on portal/main, which another session owns.
3. PLAYTEST.md is already out of step with `latest`: it describes arm B damage, which build 7 lacks. It also needs a build 8 rewrite:
   - pass 3 pool;
   - strong field;
   - presets B/C setting;
   - declutter (its mentions of the "combat log" and "picture guide" may be stale);
   - trim the history.
4. The strong field is the playtest default, but exports exclude content/fields/* and the smoke test fails if a field library ships. src/core/field_library.gd expects res://content/fields/baseline.json.gz, and no library is committed yet; the recapture is in plan step 5. Before build 8:
   - flip the presets;
   - flip the smoke check to require the library;
   - check the APK still runs strong-field mode (the 9 Nov strong-field gap says the "loader fails loudly").
5. The export script needs a version for each build. Make it one parametrised script.
6. Back up the keystore off the machine. If it's lost, the next APK won't install over the existing ones.
7. Portal README parse: the "In this build" line shows "about Battlegrounds' length, same effects", because parseReadme takes the first parenthesis in line 1. For build 8, keep parentheses out of line 1, or use "New ...:" lines.
