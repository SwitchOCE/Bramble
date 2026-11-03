'use strict';
// Pictures read straight from git: /git/<branch>/<path> for the branches the
// registry allows, and the design-lab gallery's own relative images. Only
// image types are served. Everything is read with `git show` on a blob id,
// so the ETag is the blob id and a versioned URL (?v=<blob id>) can be
// cached for good.

const TYPES = {
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  webp: 'image/webp',
  svg: 'image/svg+xml',
};

// An SVG opened on its own can't run script or load anything.
const SVG_CSP = "default-src 'none'; style-src 'unsafe-inline'; sandbox";

function imageType(p) {
  const m = /\.([a-z0-9]+)$/i.exec(String(p));
  return m ? TYPES[m[1].toLowerCase()] || null : null;
}

// A repo path made of plain segments: no empty, "." or ".." parts, no
// backslashes, control characters or leading dashes.
function safeRepoPath(segs) {
  // A decoded "%2F" puts a slash inside one segment; check every part.
  const parts = segs.flatMap((s) => String(s).split('/'));
  if (!parts.length) return null;
  for (const s of parts) {
    if (!s || s === '.' || s === '..' || s.startsWith('-') || /[\\\u0000-\u001f\u007f]/.test(s)) return null;
  }
  return parts.join('/');
}

// Splits /git/<branch>/<path> segments into an allowed branch and a path.
// Branch names have slashes, so the longest allowed branch that the path
// starts with wins.
function splitBranchPath(segs, allowed) {
  let best = null;
  for (const b of allowed) {
    const parts = b.split('/');
    if (parts.length < segs.length && parts.every((p, k) => segs[k] === p) && (!best || parts.length > best.parts.length)) {
      best = { name: b, parts };
    }
  }
  if (!best) return null;
  return { branch: best.name, segs: segs.slice(best.parts.length) };
}

// "branch:path" as used in decision cards, to a site URL.
function gitUrl(branch, path, blobId) {
  const enc = (s) => s.split('/').map(encodeURIComponent).join('/');
  return `/git/${enc(branch)}/${enc(path)}${blobId ? `?v=${blobId.slice(0, 16)}` : ''}`;
}

// Width and height from the first bytes of a JPEG, PNG or WebP; null otherwise.
function imageSize(buf) {
  if (!buf || buf.length < 24) return null;
  if (buf[0] === 0x89 && buf.toString('ascii', 1, 4) === 'PNG') {
    return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
  }
  if (buf[0] === 0xff && buf[1] === 0xd8) {
    let i = 2;
    while (i + 9 < buf.length) {
      if (buf[i] !== 0xff) { i++; continue; }
      const marker = buf[i + 1];
      if (marker === 0xd8 || marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) { i += 2; continue; }
      const len = buf.readUInt16BE(i + 2);
      if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc) {
        return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7) };
      }
      i += 2 + len;
    }
    return null;
  }
  if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WEBP') {
    const kind = buf.toString('ascii', 12, 16);
    if (kind === 'VP8X') return { width: 1 + buf.readUIntLE(24, 3), height: 1 + buf.readUIntLE(27, 3) };
    if (kind === 'VP8 ') return { width: buf.readUInt16LE(26) & 0x3fff, height: buf.readUInt16LE(28) & 0x3fff };
    if (kind === 'VP8L') {
      const b = buf.readUInt32LE(21);
      return { width: 1 + (b & 0x3fff), height: 1 + ((b >> 14) & 0x3fff) };
    }
  }
  return null;
}

function createImageStore(git) {
  const ids = new Map(); // "<commit>:<path>" -> blob id or null
  const sizes = new Map(); // blob id -> { width, height } or null

  async function blobId(commit, path) {
    const key = `${commit}:${path}`;
    if (!ids.has(key)) {
      if (ids.size > 5000) ids.clear();
      ids.set(key, git.objectId(commit, path));
    }
    return ids.get(key);
  }

  // Blob ids never change content, so sizes are cached for good.
  async function size(id) {
    if (!sizes.has(id)) {
      sizes.set(
        id,
        git.blob(id).then(
          (buf) => imageSize(buf),
          () => null,
        ),
      );
    }
    return sizes.get(id);
  }

  // Sends <commit>:<path> as an image. Returns false if there is no such file.
  async function send(req, res, { commit, path, headers }) {
    const type = imageType(path);
    const id = await blobId(commit, path);
    if (!id) return false;
    const etag = `"${id}"`;
    const url = new URL(req.url, 'http://portal.local');
    const v = url.searchParams.get('v');
    const cache = v && id.startsWith(v) && v.length >= 7 ? 'public, max-age=31536000, immutable' : 'no-cache';
    const base = { ...headers, ETag: etag, 'Cache-Control': cache };
    if (type === TYPES.svg) base['Content-Security-Policy'] = SVG_CSP;
    if (req.headers['if-none-match'] === etag) {
      res.writeHead(304, base);
      res.end();
      return true;
    }
    const body = await git.blob(id);
    res.writeHead(200, { ...base, 'Content-Type': type, 'Content-Length': body.length });
    res.end(req.method === 'HEAD' ? undefined : body);
    return true;
  }

  return { blobId, size, send };
}

module.exports = { TYPES, imageType, safeRepoPath, splitBranchPath, gitUrl, imageSize, createImageStore };
