# Build 8 dry-run export — 10 Nov 2026

**PASS. No real export, tag or latest update was made.**

Command: `build/export.sh --dry-run 8 "Bigger tribe stats with new neutrals and clearer screens"`.
Source: `3070b6d09278f342a916beb7e5849bf76f72a566`. Folder: `/home/alex/code/Bramble-ideation-build8/build/export-dry-run-8-1110-1906.dOf72B`.

The script exited 0 after all its own checks:

- Linux, Windows and Android pack listings include the strong-field library.
- Windows PCK and APK asset-pack probes load the library and report its exact
  SHA-256: `3653057c0127bd55ab32bdbb09bf7f95b8831ad8764b7d6c5f63f8fb7ca711fa`.
- APK integrity and certificate verification pass. Certificate SHA-256:
  `e72ece9566a57b9cd8e3d6c65627c680f86eff909c6cf75c1fe6fac44509dbe4`;
  it matches the debug keystore and published build 7.
- Linux and Wine boots reach `boot: main scene ready` and exit 0.

The dry-run snapshot enables `strong_field` to exercise field starts. Its library
is the committed baseline, byte-for-byte; the README's generic “throwaway” label
does not mean a different library was substituted. This does not select the
shipping opponent default. The archived PLAYTEST includes the Soup one-fifth
clarification. Source checkout gameplay and export presets were not altered.

Artifacts, frozen PLAYTEST, README, certificate and all pack/boot logs remain
in the folder above. Memory, soak and UI results have separate receipts here.
The orchestrator retains the cloud gate and performs the real export afterward.
