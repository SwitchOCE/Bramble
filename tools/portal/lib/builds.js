'use strict';
// Builds in /data/bramble-builds: a build is a directory with a README.txt.
// Files are served only from inside a listed build directory, after
// resolving symlinks, so neither "../" nor a symlink can reach anything else.

const fs = require('node:fs');
const fsp = require('node:fs/promises');
const path = require('node:path');

const DOWNLOADS = [
  { key: 'apk', file: 'Bramble.apk', label: 'APK for phone', platform: 'Android' },
  { key: 'windows', file: 'Bramble-windows.zip', label: 'Windows zip', platform: 'Windows' },
];

const TYPES = {
  '.apk': 'application/vnd.android.package-archive',
  '.zip': 'application/zip',
  '.txt': 'text/plain; charset=utf-8',
  '.pck': 'application/octet-stream',
  '.exe': 'application/vnd.microsoft.portable-executable',
  '.idsig': 'application/octet-stream',
  '.x86_64': 'application/octet-stream',
  '.sh': 'text/x-shellscript; charset=utf-8',
};

const NAME_OK = /^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$/;

async function scanBuilds(root) {
  let entries;
  try {
    entries = await fsp.readdir(root, { withFileTypes: true });
  } catch (e) {
    return { builds: [], latest: null, error: `Can't read ${root}: ${e.code || e.message}` };
  }
  let latest = null;
  try {
    latest = path.basename(await fsp.realpath(path.join(root, 'latest')));
  } catch {
    latest = null;
  }
  const builds = [];
  for (const ent of entries) {
    if (!ent.isDirectory() || ent.name === 'latest' || !NAME_OK.test(ent.name)) continue;
    const dir = path.join(root, ent.name);
    let readme, readmeStat;
    try {
      readmeStat = await fsp.stat(path.join(dir, 'README.txt'));
      if (!readmeStat.isFile()) continue;
      readme = await fsp.readFile(path.join(dir, 'README.txt'), 'utf8');
    } catch {
      continue; // not a build (e.g. empty-project)
    }
    const files = [];
    for (const d of DOWNLOADS) {
      try {
        const st = await fsp.stat(path.join(dir, d.file));
        if (st.isFile()) files.push({ ...d, size: st.size, mtime: st.mtime });
      } catch {
        /* this build has no such download */
      }
    }
    let hasLinux = false;
    try {
      hasLinux = (await fsp.stat(path.join(dir, 'linux', 'bramble.x86_64'))).isFile();
    } catch {
      hasLinux = false;
    }
    builds.push({ name: ent.name, dir, date: readmeStat.mtime, readme, ...parseReadme(readme, ent.name), files, hasLinux });
  }
  builds.sort((a, b) => b.date - a.date || b.name.localeCompare(a.name));
  for (const b of builds) b.isLatest = b.name === latest;
  return { builds, latest: builds.find((b) => b.isLatest) || null, latestName: latest };
}

// Pulls the headline parts out of a build README. Anything it can't find is
// left empty; the full README is always shown too.
function parseReadme(text, dirName) {
  const lines = String(text).replace(/\r\n?/g, '\n').split('\n');
  const title = (lines[0] || '').trim();
  const num = /build\s*(\d+)/i.exec(dirName) || /build\s*(\d+)/i.exec(title);
  const label = num ? `Build ${num[1]}` : dirName;
  const paren = /\(([^)]+)\)/.exec(title);
  const srcLine = lines.find((l) => /^Source:/i.test(l)) || '';
  const src = /^Source:\s*(\S+)\s+at\s+([0-9a-f]{7,40})\b\s*(.*)$/i.exec(srcLine.trim());
  const source = src
    ? { branch: src[1], commit: src[2], extra: src[3].replace(/^\(|\)\.?$/g, '').trim(), text: srcLine.replace(/^Source:\s*/i, '').trim() }
    : srcLine
      ? { branch: null, commit: null, extra: '', text: srcLine.replace(/^Source:\s*/i, '').trim() }
      : null;

  // "What's new": from the first "New ..." line up to the install lines.
  const news = [];
  let cur = null;
  let inNew = false;
  for (const raw of lines.slice(1)) {
    const l = raw.trim();
    if (/^(Windows|Android|Linux|Dev panel|How to play|Get it)\b/i.test(l)) {
      if (inNew) break;
      continue;
    }
    if (/^New\b.*:/.test(l)) {
      inNew = true;
      const [head, ...rest] = l.split(/:\s*/);
      cur = { heading: head, items: [] };
      const tail = rest.join(': ').trim();
      if (tail) cur.items.push(tail);
      news.push(cur);
      continue;
    }
    if (!inNew || !l) continue;
    if (l.startsWith('- ')) cur.items.push(l.slice(2));
    else if (cur.items.length) cur.items[cur.items.length - 1] += ' ' + l;
    else cur.items.push(l);
  }
  const summary = news.length ? null : paren ? paren[1] : null;
  return { label, title, source, news, summary };
}

// Resolves /builds/<build>/<file...> to a real file inside that build, or
// returns { error: status }.
async function resolveBuildFile(root, buildName, relParts) {
  if (!NAME_OK.test(buildName)) return { error: 404 };
  if (!relParts.length) return { error: 404 };
  for (const p of relParts) {
    if (!p || p === '.' || p === '..' || p.includes('\0') || p.includes('/') || p.includes('\\')) return { error: 400 };
  }
  let rootReal, buildReal;
  try {
    rootReal = await fsp.realpath(root);
    buildReal = await fsp.realpath(path.join(root, buildName));
  } catch {
    return { error: 404 };
  }
  // The build dir itself (or what "latest" points at) must sit directly in the root,
  // and must be a build (have a README.txt).
  if (path.dirname(buildReal) !== rootReal) return { error: 403 };
  try {
    if (!(await fsp.stat(path.join(buildReal, 'README.txt'))).isFile()) return { error: 404 };
  } catch {
    return { error: 404 };
  }
  let fileReal;
  try {
    fileReal = await fsp.realpath(path.join(buildReal, ...relParts));
  } catch {
    return { error: 404 };
  }
  if (!fileReal.startsWith(buildReal + path.sep)) return { error: 403 };
  let st;
  try {
    st = await fsp.stat(fileReal);
  } catch {
    return { error: 404 };
  }
  if (!st.isFile()) return { error: 404 };
  return { file: fileReal, stat: st, build: path.basename(buildReal), rel: relParts.join('/') };
}

function contentType(file) {
  const ext = path.extname(file).toLowerCase();
  return TYPES[ext] || 'application/octet-stream';
}

// Parses a single "bytes=" range. Returns null (no/ignored range),
// { start, end } or 'unsatisfiable'.
function parseRange(header, size) {
  if (!header) return null;
  const m = /^bytes=\s*(\d*)\s*-\s*(\d*)\s*$/.exec(header.trim());
  if (!m) return null; // multi-range or malformed: ignore and send the whole file
  let start, end;
  if (m[1] === '' && m[2] === '') return 'unsatisfiable';
  if (m[1] === '') {
    const n = Number(m[2]);
    if (n === 0) return 'unsatisfiable';
    start = Math.max(0, size - n);
    end = size - 1;
  } else {
    start = Number(m[1]);
    end = m[2] === '' ? size - 1 : Math.min(Number(m[2]), size - 1);
    if (Number(m[2]) < start && m[2] !== '') return 'unsatisfiable';
  }
  if (start >= size || size === 0) return 'unsatisfiable';
  return { start, end };
}

// Streams a resolved file with Range, HEAD and attachment headers.
function sendFile(req, res, resolved, downloadName) {
  const { file, stat } = resolved;
  const size = stat.size;
  const etag = `"${stat.size.toString(16)}-${Math.floor(stat.mtimeMs).toString(16)}"`;
  const lastModified = stat.mtime.toUTCString();
  const headers = {
    'Content-Type': contentType(file),
    'Content-Disposition': attachment(downloadName || path.basename(file)),
    'Accept-Ranges': 'bytes',
    'Last-Modified': lastModified,
    ETag: etag,
    'Cache-Control': 'no-cache',
    'X-Content-Type-Options': 'nosniff',
  };

  if (req.headers['if-none-match'] === etag && !req.headers.range) {
    res.writeHead(304, headers);
    return res.end();
  }

  let range = parseRange(req.headers.range, size);
  const ifRange = req.headers['if-range'];
  if (range && ifRange && ifRange !== etag && ifRange !== lastModified) range = null;

  if (range === 'unsatisfiable') {
    res.writeHead(416, { ...headers, 'Content-Range': `bytes */${size}`, 'Content-Length': 0 });
    return res.end();
  }
  let status = 200;
  let start = 0;
  let end = size - 1;
  if (range) {
    status = 206;
    ({ start, end } = range);
    headers['Content-Range'] = `bytes ${start}-${end}/${size}`;
  }
  headers['Content-Length'] = size === 0 ? 0 : end - start + 1;
  res.writeHead(status, headers);
  if (req.method === 'HEAD' || size === 0) return res.end();
  const stream = fs.createReadStream(file, { start, end });
  stream.on('error', () => res.destroy());
  res.on('close', () => stream.destroy());
  stream.pipe(res);
}

function attachment(name) {
  const ascii = name.replace(/[^\x20-\x7e]/g, '_').replace(/["\\]/g, '_');
  return `attachment; filename="${ascii}"; filename*=UTF-8''${encodeURIComponent(name)}`;
}

// The name a download is saved under on the phone or PC, so builds don't
// overwrite each other: Bramble.apk from build 4 saves as Bramble-build4.apk.
function downloadName(file, buildName) {
  const ext = path.extname(file);
  const base = path.basename(file, ext);
  const short = (/build\d+/i.exec(buildName) || [buildName])[0];
  return `${base}-${short}${ext}`;
}

module.exports = { scanBuilds, parseReadme, resolveBuildFile, sendFile, parseRange, contentType, downloadName, DOWNLOADS };
