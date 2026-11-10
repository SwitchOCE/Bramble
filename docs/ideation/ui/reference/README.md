# UI and world reference captures

Other studios’ images: **internal study only; never ship or trace**. Images, candidate
metadata, labelled contact sheets (`sheet.jpg`) and per-game indexes (`index.md`)
live outside git in `/data/bramble-reference/<game>/`. Only this guide, the source
manifest and capture tooling belong in git. Galaxy reuses existing shots.

This handoff contains 22 Bazaar PC frames (two per requested state) from its
[Steam trailer](https://store.steampowered.com/app/1617400/) and
[Bek's clean gameplay VOD](https://www.youtube.com/watch?v=gaX0SxOxRzk).
Ori has 10 frames: wide scenery 3, close characters 2, atmosphere 2, characters in
the scene 3, from Steam's [Blind Forest](https://store.steampowered.com/app/261570/),
[Definitive Edition](https://store.steampowered.com/app/387290/) and
[Will of the Wisps](https://store.steampowered.com/app/1057090/) trailers.
Every pick was viewed individually at native 1920×1080. The Android preview was
rejected for chat covering play and a soft mobile feed; mobile coverage remains
open. Native game tooltips, build labels and two tutorial bubbles are retained.
Battlegrounds, TFT and Everdell are deferred to the next turn.

Requires Python 3, Pillow, numpy, ffmpeg/ffprobe, current yt-dlp, Node.js and
DejaVu Sans. The November 2026 run used yt-dlp 2026.10.26 for YouTube; the installed
March build returned HTTP 403. No cookies, proxies or alternate-client workarounds
were used. If refused, record the error and move to another source.

## Re-fetch the reviewed frames

From this worktree's root:

```sh
python3 tools/reference/capture.py refetch --game bazaar
python3 tools/reference/capture.py refetch --game ori
python3 tools/reference/capture.py clean-cache --game bazaar
python3 tools/reference/capture.py clean-cache --game ori
```

Omit `--game` from `refetch` to restore every game in the manifest. Frame paths are
`<storage_root>/<game_slug>/<file_name>`. Timestamps are seconds from the original
video's beginning, including its intro. Images retain source resolution, without
cropping, retouching or upscaling. Movie timestamps can change if an uploader
replaces a video; keep the manifest's exact media URL where possible. Download
refusals are reported once per source, and remaining sources are still attempted.
To change storage, put `--root /some/path` **before** the subcommand.

## Capture another source and pick frames

Steam store API trailers first: the script resolves adaptive H.264 URLs and
downloads the highest-resolution video stream. Use `--movie ID` to select a
specific trailer; omit it for the first trailer. Then use clean YouTube footage
at 1080p or better. `--max-height 1080` is available for long YouTube VODs.

```sh
python3 tools/reference/capture.py capture --game bazaar --title 'The Bazaar' \
  --source steam-trailer --steam 1617400
python3 tools/reference/capture.py capture --game bazaar --title 'The Bazaar' \
  --source bek-part1 --url 'https://www.youtube.com/watch?v=gaX0SxOxRzk' \
  --fps 1 --window 12
```

Use a fresh `--source` label for each analysis pass. `--start`/`--end` restrict
analysis to source seconds without shifting recorded timestamps. The default is
two samples/second, with scene boundaries detected by normalized mean image
difference and a maximum four-second window for fixed-camera footage. The
sharpest sample (Laplacian variance) in each scene/window wins; perceptual hashes
plus image differences remove near duplicates. Only analysis is downscaled.
Candidates are full-resolution JPEGs with JSON provenance and paginated contact
sheets under `candidates/<source>/`. Automation proposes; it does not approve.

Inspect each proposed pick individually at native resolution. Reject facecams,
chat, streamer graphics, promotional captions, watermarks covering play,
transitions, motion blur and wrong states. Preserve the game's own HUD/tooltips.
Pick two or three distinct frames per state without padding with near duplicates.
Use a local JSON array (do not commit images) containing entries like:

```json
[{"source":"steam-trailer","id":"steam-trailer-0011","state":"item-inspect","notes":"Shop hover."}]
```

```sh
python3 tools/reference/capture.py pick --game bazaar --selections /tmp/bazaar-picks.json
```

`pick` replaces that game's manifest entries, preserves other games, copies picks
beside `sheet.jpg`, and writes `index.md` with states, links, times and notes.
It marks entries visually reviewed: run it only after inspecting every pick.
Delete cached downloads with `clean-cache` once selection and re-fetch checks pass.
Candidate images can stay local for later study. No Godot or old UI tests change.
