'use strict';
// Pictures read straight from git: /git/<branch>/<path> for the branches the
// registry allows, and the design-lab gallery's own relative images. Only
// image types are served. Everything is read with `git show` on a blob id,
// and the ETag is the blob id, so a browser revalidates with a cheap 304.

const TYPES = {
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  webp: 'image/webp',
};

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
function gitUrl(branch, path) {
  const enc = (s) => s.split('/').map(encodeURIComponent).join('/');
  return `/git/${enc(branch)}/${enc(path)}`;
}

function createImageStore(git) {
  const ids = new Map(); // "<commit>:<path>" -> blob id or null

  async function blobId(commit, path) {
    const key = `${commit}:${path}`;
    if (!ids.has(key)) {
      if (ids.size > 5000) ids.clear();
      ids.set(key, git.objectId(commit, path));
    }
    return ids.get(key);
  }

  // Sends <commit>:<path> as an image. Returns false if there is no such file.
  async function send(req, res, { commit, path, headers }) {
    const type = imageType(path);
    const id = await blobId(commit, path);
    if (!id) return false;
    const etag = `"${id}"`;
    const base = { ...headers, ETag: etag, 'Cache-Control': 'no-cache' };
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

  return { blobId, send };
}

module.exports = { TYPES, imageType, safeRepoPath, splitBranchPath, gitUrl, createImageStore };
