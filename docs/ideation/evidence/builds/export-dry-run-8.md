# S3 unified export dry run — 10 Nov 2026

The complete dry run passed on source commit
`7b550a2c674275ee0a51ba83c0d5c78de15e4206`, using:

```sh
FIELD_LIBRARY="$PWD/build/fields/throwaway-512dc07e8ad0.json.gz" \
  build/export.sh --dry-run 8 'Throwaway current-content field and delivery verification'
```

Folder: `/home/alex/code/Bramble-ideation-sol/build/export-dry-run-8-1110-1214.0202BX/`

README: `build/export-dry-run-8-1110-1214.0202BX/README.txt`. Its first line is:

> Ideation build 8: Throwaway current-content field and delivery verification

The README records the source commit, intended `ideation-build-8` tag, throwaway
library SHA-256, signing certificate and testing limitations. The artifact folder
also contains `build-8.md`, the dry-run delivery record. A real delivery writes
`docs/ideation/evidence/builds/build-8.md`; this dry run leaves that name available
for the actual build 8 delivery.

Checks passed:

- Dirty-tree refusal was exercised before committing the implementation.
- Linux and Windows PCKs and APK exported; all three listings contain exactly one
  `content/fields/baseline.json.gz`. Development directories and reference content
  are excluded. Tutorial and rules filters are included for every preset.
- Linux boot and Wine boot reached `boot: main scene ready` with exit 0.
- Field startup probes loaded the library from Linux/Windows PCKs and a ZIP made
  solely from APK `assets/` entries. The latter exercises the APK's resource bytes
  with the editor; it is not an Android device execution. Each probe verified SHA
  `6ca0dc2b191c53007dd2b8f2415305077b1e19fbd16b7310fe246030e0cda396`.
- APK signature verified; certificate SHA-256
  `e72ece9566a57b9cd8e3d6c65627c680f86eff909c6cf75c1fe6fac44509dbe4`
  matches `/opt/godot-data/godot/keystores/debug.keystore` and build 7's APK record.
  Signing output, exported DER certificate and SHA record accompany the build.
- `PLAYTEST.md` is copied from the source snapshot. No real device was tested.
- `latest` before and after was `/data/bramble-builds/1108-2016-ideation7`;
  `ideation-build-8` was absent before and after. The comparison records are
  `build/measure-{latest,tag}-{before,after}.txt`.

The script retains old per-build scripts as historical records. A real run refuses
an existing tag or evidence record, creates only a local tag and atomically
updates `latest` after every check. This path was inspected, not executed: this
assignment requested a dry run, not publication.

Integration fixes necessary for current-content fields: load named line profiles
from their source commit, retain immutable starting lines through policy pivots,
match Godot's 15-digit fractional gameplay hashes, and remove the runtime
`FightCapture` dependency on excluded tools. Three Python regressions and the
17-test field-library/launch GUT run cover these paths. `tests/sim/test_field_profiles.py`
is outside S3's ownership and was added to test these necessary builder fixes.

Godot hardcodes `/tmp` for temporary APKs and ignored `TMPDIR`. The first full
attempt hit the shared tmpfs quota and produced a truncated temporary APK. The
script now acquires the shared slot outside a private bubblewrap `/tmp` mount
backed by the build folder, preserving `/dev` for signing. The final run used that
path and passed. Earlier scratch attempts were not delivered and do not supply
memory results. No shared temporary files were deleted.
