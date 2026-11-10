#!/usr/bin/env python3
"""Internal reference captures. Requires ffmpeg, ffprobe, yt-dlp, Pillow, numpy.

capture produces candidates; a human reviews them before pick writes the manifest.
No images belong in git. See docs/ideation/ui/reference/README.md.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import urllib.request
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path('/data/bramble-reference')
REPO = Path(__file__).resolve().parents[2]
MANIFEST = REPO / 'docs/ideation/ui/reference/manifest.json'


def run(args):
    return subprocess.check_output([str(a) for a in args], stderr=subprocess.STDOUT, text=True)


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def json_url(url):
    with urllib.request.urlopen(url, timeout=40) as response:
        return json.load(response)


def steam_movies(app):
    data = json_url(f'https://store.steampowered.com/api/appdetails?appids={app}&l=english')
    return data[str(app)]['data']['movies']


def download(url, root, max_height=None):
    cache = root / '_cache'
    cache.mkdir(parents=True, exist_ok=True)
    key = cache_key(url, max_height)
    existing = list(cache.glob(key + '.*'))
    existing = [p for p in existing if p.suffix not in ('.part', '.ytdl', '.json')]
    if existing:
        return existing[0]
    # One normal attempt. No cookies, proxy changes, or alternate clients on refusal.
    formats = f'bestvideo[height<={max_height}]/bestvideo/best' if max_height else 'bestvideo/best'
    output = run(['yt-dlp', '--ignore-config', '--no-cache-dir', '--no-playlist', '--no-progress', '--retries', '0',
                  '--fragment-retries', '0', '--socket-timeout', '30',
                  '--js-runtimes', 'node', '-f', formats,
                  '-o', cache / (key + '.%(ext)s'), '--print', 'after_move:filepath', url])
    return Path(output.strip().splitlines()[-1])


def cache_key(url, max_height=None):
    value = url if max_height is None else f'{url}|height={max_height}'
    return hashlib.sha256(value.encode()).hexdigest()[:16]


def probe(video):
    data = json.loads(run(['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                          '-show_streams', '-show_format', '-of', 'json', video]))
    stream = data['streams'][0]
    return [stream['width'], stream['height']], float(data['format']['duration'])


def extract(video, timestamp, output):
    output.parent.mkdir(parents=True, exist_ok=True)
    run(['ffmpeg', '-v', 'error', '-threads', '2', '-ss', f'{timestamp:.3f}',
         '-i', video, '-frames:v', '1', '-threads', '2', '-q:v', '2', '-y', output])


def timecode(seconds):
    minutes, seconds = divmod(seconds, 60)
    hours, minutes = divmod(int(minutes), 60)
    return f'{hours:02d}:{minutes:02d}:{seconds:06.3f}'


def sheet(frames, base, output, title, columns=4):
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 14)
    width, height = 360, 240
    canvas = Image.new('RGB', (width * columns, 44 + height * ((len(frames) + columns - 1) // columns)), '#171c23')
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 12), title, font=font, fill='white')
    for i, frame in enumerate(frames):
        x, y = (i % columns) * width, 44 + (i // columns) * height
        with Image.open(base / frame['file_name']) as image:
            thumb = image.copy()
            thumb.thumbnail((352, 198))
            canvas.paste(thumb, (x + 4, y + (198 - thumb.height) // 2))
        label = frame.get('state', frame.get('id', ''))
        draw.text((x + 5, y + 200), label[:45], font=font, fill='white')
        draw.text((x + 5, y + 220), f"{frame.get('id', '')}  {timecode(frame['timestamp_seconds'])}", font=font, fill='#c3cdd7')
    canvas.save(output, quality=92)


def scan(video, fps, window, threshold, offset=0, length=None):
    """Detect scene boundaries by normalized mean frame difference.

    Keep the sharpest sample in each scene/window. A periodic window also finds
    hover/shop changes within fixed-camera footage. Analysis only is downscaled;
    exported frames retain native resolution. Laplacian variance ranks sharpness.
    """
    w, h = 512, 288
    command = ['ffmpeg', '-v', 'error', '-threads', '2', '-ss', str(offset), '-i', str(video)]
    if length is not None:
        command += ['-t', str(length)]
    process = subprocess.Popen(command + ['-vf', f'fps={fps}:start_time=0,scale={w}:{h}',
                                '-pix_fmt', 'gray', '-f', 'rawvideo', '-threads', '1', '-'],
                               stdout=subprocess.PIPE)
    previous = best = None
    start = 0.0
    candidates = []
    n = 0
    try:
        while True:
            raw = process.stdout.read(w * h)
            if len(raw) != w * h:
                break
            array = np.frombuffer(raw, np.uint8).reshape(h, w).astype(np.float32)
            timestamp = offset + n / fps
            delta = float(np.abs(array - previous).mean() / 255) if previous is not None else 0
            if best is not None and (delta > threshold or timestamp - start >= window):
                candidates.append(best)
                best = None
                start = timestamp
            lap = (array[1:-1, :-2] + array[1:-1, 2:] + array[:-2, 1:-1]
                   + array[2:, 1:-1] - 4 * array[1:-1, 1:-1])
            sharp = float(lap.var())
            # Drop almost black/white transition frames, not intentionally dark art.
            if array.std() > 12 and 8 < array.mean() < 247:
                small = np.asarray(Image.fromarray(array.astype(np.uint8)).resize((9, 8)), dtype=np.int16)
                fingerprint = np.packbits(small[:, 1:] > small[:, :-1]).tobytes().hex()
                item = dict(timestamp_seconds=timestamp, sharpness=round(sharp, 3),
                            scene_delta=round(delta, 5), dhash=fingerprint,
                            thumbnail=array[::8, ::8].astype(np.uint8))
                if best is None or sharp > best['sharpness']:
                    best = item
            previous = array
            n += 1
        if best is not None:
            candidates.append(best)
    finally:
        process.stdout.close()
        if process.wait() != 0:
            raise RuntimeError('ffmpeg analysis failed')
    # Keep the sharper member of near duplicates, then restore source order.
    unique = []
    for item in sorted(candidates, key=lambda x: -x['sharpness']):
        duplicate = any((int(item['dhash'], 16) ^ int(other['dhash'], 16)).bit_count() <= 5
                        and np.abs(item['thumbnail'].astype(float) - other['thumbnail']).mean() < 9
                        for other in unique)
        if not duplicate:
            unique.append(item)
    for item in unique:
        del item['thumbnail']
    return sorted(unique, key=lambda x: x['timestamp_seconds'])


def capture(args):
    url = args.url
    source_url = f'https://store.steampowered.com/app/{args.steam}/' if args.steam else url
    dest = args.root / args.game / 'candidates' / args.source
    dest.mkdir(parents=True, exist_ok=True)
    metadata = dict(game=args.title, game_slug=args.game, platform=args.platform,
                    source_id=args.source, source_url=source_url, media_url=url,
                    max_height=args.max_height)
    try:
        if args.steam:
            movies = steam_movies(args.steam)
            movie = next(m for m in movies if str(m['id']) == args.movie) if args.movie else movies[0]
            url = movie.get('dash_h264') or movie.get('hls_h264') or movie['mp4']['max']
            metadata.update(media_url=url, steam_app=args.steam, steam_movie=movie['id'])
        video = download(url, args.root, args.max_height)
        resolution, duration = probe(video)
        metadata.update(cache_file=str(video), resolution=resolution, duration_seconds=duration)
        end = min(args.end, duration) if args.end is not None else duration
        if args.start >= end:
            raise ValueError('start must precede end of video')
        metadata['analysis'] = dict(fps=args.fps, window=args.window,
                                    scene_threshold=args.scene_threshold, start=args.start, end=end)
        frames = scan(video, args.fps, args.window, args.scene_threshold, args.start, end - args.start)
        for i, frame in enumerate(frames):
            frame['id'] = f'{args.source}-{i:04d}'
            frame['file_name'] = frame['id'] + '.jpg'
            extract(video, frame['timestamp_seconds'], dest / frame['file_name'])
        expected = {frame['file_name'] for frame in frames}
        for old in dest.glob(args.source + '-*.jpg'):
            if old.name not in expected:
                old.unlink()
        for old in dest.glob('contact-*.jpg'):
            old.unlink()
        metadata['candidates'] = frames
        write_json(dest / 'candidates.json', metadata)
        (dest / 'failure.json').unlink(missing_ok=True)
        for page, offset in enumerate(range(0, len(frames), 64), 1):
            sheet(frames[offset:offset + 64], dest, dest / f'contact-{page:02d}.jpg',
                  f'{args.title} / {args.source} / candidates {offset}–{min(offset+64,len(frames))-1}')
        print(json.dumps(dict(source=args.source, candidates=len(frames), resolution=resolution, directory=str(dest))))
    except Exception as error:
        metadata['error'] = getattr(error, 'output', None) or str(error)
        write_json(dest / 'failure.json', metadata)
        raise SystemExit(metadata['error'])


def pick(args):
    choices = json.loads(args.selections.read_text())
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else dict(schema_version=1, frames=[])
    if not choices:
        raise SystemExit('Select at least one visually reviewed candidate.')
    new = []
    game_dir = args.root / args.game
    sources = {}
    for choice in choices:
        source = choice['source']
        if source not in sources:
            sources[source] = json.loads((game_dir / 'candidates' / source / 'candidates.json').read_text())
        meta = sources[source]
        candidate = next(f for f in meta['candidates'] if f['id'] == choice['id'])
        name = f"{choice['state']}--{candidate['id']}.jpg"
        shutil.copyfile(game_dir / 'candidates' / source / candidate['file_name'], game_dir / name)
        frame = dict(game=meta['game'], game_slug=args.game, platform=meta['platform'],
                     state=choice['state'], file_name=name, source_url=meta['source_url'],
                     media_url=meta['media_url'], source_id=source,
                     timestamp=timecode(candidate['timestamp_seconds']),
                     timestamp_seconds=candidate['timestamp_seconds'], resolution=meta['resolution'],
                     sharpness=candidate['sharpness'], notes=choice.get('notes', ''),
                     max_height=meta.get('max_height'),
                     sha256=hashlib.sha256((game_dir / name).read_bytes()).hexdigest(),
                     visually_reviewed=True)
        new.append(frame)
    manifest['frames'] = [f for f in manifest['frames'] if f['game_slug'] != args.game] + new
    manifest['storage_root'] = str(args.root)
    manifest['usage'] = 'Other studios’ images. Internal study only; never ship or trace.'
    manifest.setdefault('coverage', {}).setdefault(args.game, {}).update(
        platforms=sorted({f['platform'] for f in new}),
        states=dict(Counter(f['state'] for f in new)))
    source_records = []
    for directory in sorted((game_dir / 'candidates').iterdir()):
        path = directory / 'failure.json'
        if not path.exists():
            path = directory / 'candidates.json'
        if not path.exists():
            continue
        meta = json.loads(path.read_text())
        record = {k: meta[k] for k in ('source_id', 'source_url', 'media_url', 'platform', 'resolution', 'notes') if k in meta}
        record['game_slug'] = args.game
        record['status'] = meta.get('status', 'blocked' if 'error' in meta else 'captured')
        if 'error' in meta:
            record['error'] = meta['error'].strip().splitlines()[-1]
        source_records.append(record)
    manifest['sources'] = [s for s in manifest.get('sources', []) if s['game_slug'] != args.game] + source_records
    write_json(MANIFEST, manifest)
    sheet(new, game_dir, game_dir / 'sheet.jpg', f'{new[0]["game"]} / reviewed picks')
    lines = [f'# {new[0]["game"]} reference index', '', manifest['usage'], '',
             'All picks visually reviewed at native resolution. Files are beside this index.', '',
             '| State | Frame | Source | Time | Resolution | Notes |', '|---|---|---|---|---|---|']
    for f in new:
        lines.append(f"| {f['state']} | [{f['file_name']}]({f['file_name']}) | [video]({f['source_url']}) | {f['timestamp']} | {f['resolution'][0]}×{f['resolution'][1]} | {f['notes']} |")
    (game_dir / 'index.md').write_text('\n'.join(lines) + '\n')
    print(f'Picked {len(new)} frames; manifest, sheet.jpg and index.md written.')


def refetch(args):
    manifest = json.loads(MANIFEST.read_text())
    failed = set()
    for frame in manifest['frames']:
        if args.game and args.game != frame['game_slug']:
            continue
        if frame['media_url'] in failed:
            continue
        try:
            video = download(frame['media_url'], args.root, frame.get('max_height'))
        except Exception as error:
            failed.add(frame['media_url'])
            message = getattr(error, 'output', None) or str(error)
            print(f"Refused/failed {frame['source_url']}: {message}")
            continue
        extract(video, frame['timestamp_seconds'], args.root / frame['game_slug'] / frame['file_name'])
    games = {f['game_slug'] for f in manifest['frames'] if not args.game or f['game_slug'] == args.game}
    for game in games:
        frames = [f for f in manifest['frames'] if f['game_slug'] == game
                  and (args.root / game / f['file_name']).exists()]
        if frames:
            sheet(frames, args.root / game, args.root / game / 'sheet.jpg', frames[0]['game'])
    if failed:
        raise SystemExit(f'{len(failed)} source(s) failed; other sources were still attempted.')


def clean_cache(args):
    """Remove only files keyed to this game's recorded source attempts."""
    cache = args.root / '_cache'
    records = [json.loads(path.read_text())
               for path in (args.root / args.game / 'candidates').glob('*/*.json')]
    if MANIFEST.exists():
        records.extend(f for f in json.loads(MANIFEST.read_text())['frames']
                       if f['game_slug'] == args.game)
    for meta in records:
        if not meta.get('media_url'):
            continue
        for key in {cache_key(meta['media_url'], meta.get('max_height')), cache_key(meta['media_url'])}:
            for file in cache.glob(key + '.*'):
                if file.is_file():
                    file.unlink()
                    print(f'Removed {file.name}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    sub = parser.add_subparsers(dest='command', required=True)
    cap = sub.add_parser('capture')
    cap.add_argument('--game', required=True, help='directory slug')
    cap.add_argument('--title', required=True)
    cap.add_argument('--platform', default='PC')
    cap.add_argument('--source', required=True, help='unique source label within game')
    origin = cap.add_mutually_exclusive_group(required=True)
    origin.add_argument('--url')
    origin.add_argument('--steam', type=int, help='Steam app ID; resolves store API movie URLs')
    cap.add_argument('--movie', help='Steam movie ID; default first movie')
    cap.add_argument('--fps', type=float, default=2)
    cap.add_argument('--window', type=float, default=4)
    cap.add_argument('--scene-threshold', type=float, default=.14)
    cap.add_argument('--max-height', type=int, help='optional YouTube height cap; omit for Steam highest resolution')
    cap.add_argument('--start', type=float, default=0, help='analysis range in source seconds')
    cap.add_argument('--end', type=float, help='analysis range in source seconds')
    cap.set_defaults(func=capture)
    choose = sub.add_parser('pick', help='only after human visual review')
    choose.add_argument('--game', required=True)
    choose.add_argument('--selections', required=True, type=Path)
    choose.set_defaults(func=pick)
    fetch = sub.add_parser('refetch')
    fetch.add_argument('--game')
    fetch.set_defaults(func=refetch)
    clean = sub.add_parser('clean-cache', help='delete downloads after picks are complete')
    clean.add_argument('--game', required=True)
    clean.set_defaults(func=clean_cache)
    args = parser.parse_args()
    if args.command == 'capture' and (args.fps <= 0 or args.window <= 0 or args.start < 0):
        parser.error('fps/window must be positive and start nonnegative')
    args.func(args)


if __name__ == '__main__':
    main()
