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
Those picks were viewed individually at native 1920×1080. Bazaar's Android preview
was rejected for chat covering play and a soft mobile feed; its mobile coverage
remains open. Native game tooltips, build labels and two tutorial bubbles are retained.

Battlegrounds has 24 frames: two per requested state, one PC and one Android,
from [Podmates Gaming](https://www.youtube.com/watch?v=0vKxLg0IZDk) and
[MobileCardKing](https://www.youtube.com/watch?v=dCZPojn0D4U), all 1920×1080.
Its menus show hero selection. TFT has 24 frames: two per state, 11 PC and 13 Android,
from [Pajos Games](https://www.youtube.com/watch?v=3W7tMyDtQFQ) (1920×1080 normal match)
and [No comment](https://www.youtube.com/watch?v=XajQRMeu-ko) (2220×1080 Android tutorial).
Both TFT menus are Android client menus; no PC client menu was in the selected source.
The tutorial is explicitly labelled, including its native guidance. Frames with
the later chat-head notification were excluded. For both games, opponent-board
references show combat compositions on opposing arenas, rather than a separate
scouting panel. Neither game has a Steam release; clean YouTube recordings were used.

Everdell has ten original stills: digital board 3, wide scenery 2, close characters 2,
characters in the scene 3. Sources are [Steam screenshots](https://store.steampowered.com/app/1722840/),
Andrew Bosley's [making-of article](https://www.bosleyart.com/post/wits-and-wisdom-the-making-of-everdell)
and [public gallery](https://www.bosleyart.com/copy-of-everdell). Only finished,
identified Everdell/Spirecrest paintings were picked from the mixed gallery.
Steam originals are 1920×1080; illustration originals are 2445×3330, 2500×2500 or
3300×2423. Publisher pages returned HTTP 429, the old Starling page 404 and
ArtStation 403; the accessible artist site supplied the illustrations instead.

Every new pick was inspected individually at native resolution and re-fetched
with matching SHA-256 bytes. Each game's `index.md` and `sheet.jpg` are beside
its frames in `/data/bramble-reference/`. Exact source attempts and coverage
limits are recorded in `manifest.json`; video downloads were deleted after checking.

Requires Python 3, Pillow, numpy, ffmpeg/ffprobe, current yt-dlp, Node.js and
DejaVu Sans. The November 2026 run used yt-dlp 2026.10.26 for YouTube; the installed
March build returned HTTP 403. No cookies, proxies or alternate-client workarounds
were used. If refused, record the error and move to another source.

## Re-fetch the reviewed frames

From this worktree's root:

```sh
python3 tools/reference/capture.py refetch --game bazaar
python3 tools/reference/capture.py refetch --game ori
python3 tools/reference/capture.py refetch --game battlegrounds
python3 tools/reference/capture.py refetch --game tft
python3 tools/reference/capture.py refetch --game everdell
python3 tools/reference/capture.py clean-cache --game bazaar
python3 tools/reference/capture.py clean-cache --game ori
python3 tools/reference/capture.py clean-cache --game battlegrounds
python3 tools/reference/capture.py clean-cache --game tft
```

Omit `--game` from `refetch` to restore every game in the manifest. Frame paths are
`<storage_root>/<game_slug>/<file_name>`. Timestamps are seconds from the original
video's beginning, including its intro. Images retain source resolution, without
cropping, retouching or upscaling. Movie timestamps can change if an uploader
replaces a video; keep the manifest's exact media URL where possible. Download
refusals are reported once per source, and remaining sources are still attempted.
Re-fetch also rebuilds each game's labelled sheet and index, including coverage notes.
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
analysis to source seconds without shifting recorded timestamps. For long VODs,
`--interval 30 --window 2` samples a two-second scene window every 30 seconds;
follow that overview with dense bounded passes around missing states. The default is
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

## Original illustration and board stills

Use the same tool's `stills` subcommand for Steam screenshots or publisher images:

```sh
python3 tools/reference/capture.py stills --game everdell --title Everdell \
  --source steam-screens --steam 1722840
python3 tools/reference/capture.py stills --game everdell --title Everdell \
  --platform Illustration --source publisher --urls /tmp/everdell-image-urls.json
```

The URL file is an array of `{"media_url":"original image URL","source_url":"publisher page URL"}`
objects. Original image bytes and dimensions are preserved; exact/perceptual
duplicates are dropped. Review each candidate, then use `pick` as above. Stills
have `media_type: "image"` and null timestamps; `refetch` restores their original
bytes directly. New sheets and indexes label the platform as well as the state.
