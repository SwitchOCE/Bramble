'use strict';
// Bramble portal: a LAN-only site where the owner sees the project and makes
// decisions. It reads the repo only; its one write is the owner's answers,
// into the inbox folder.
// Run: node server.js
//   env: PORTAL_PORT, PORTAL_GIT_DIR, PORTAL_BUILDS_DIR, PORTAL_INBOX_DIR,
//        PORTAL_DECISIONS_DIR (read cards from a folder instead of git; tests)

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const os = require('node:os');

const { makeGit } = require('./lib/git');
const { createIndexer } = require('./lib/indexer');
const { isAllowed } = require('./lib/ipallow');
const { resolveBuildFile, sendFile, downloadName } = require('./lib/builds');
const render = require('./lib/render');
const { createImageStore, imageType, safeRepoPath, splitBranchPath } = require('./lib/images');
const { createInbox, decisionState, readForm } = require('./lib/inbox');

const STATIC_DIR = path.join(__dirname, 'static');
const STATIC = {
  'portal.css': 'text/css; charset=utf-8',
  'icon.svg': 'image/svg+xml',
};

const SECURITY_HEADERS = {
  'Content-Security-Policy': "default-src 'none'; style-src 'self'; img-src 'self' data:; base-uri 'none'; form-action 'self'; frame-ancestors 'none'",
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'no-referrer',
};

function loadStatic() {
  const files = {};
  const hash = crypto.createHash('sha256');
  for (const name of Object.keys(STATIC)) {
    const body = fs.readFileSync(path.join(STATIC_DIR, name));
    files[name] = body;
    hash.update(body);
  }
  return { files, version: hash.digest('hex').slice(0, 10) };
}

function createApp({
  gitDir = process.env.PORTAL_GIT_DIR || path.join(os.homedir(), 'code/Bramble/.git'),
  buildsDir = process.env.PORTAL_BUILDS_DIR || '/data/bramble-builds',
  registryFile = path.join(__dirname, 'workstreams.json'),
  inboxDir = process.env.PORTAL_INBOX_DIR || '/data/bramble-portal/inbox',
  decisionsDir = process.env.PORTAL_DECISIONS_DIR || null,
  allow = isAllowed,
  log = (msg) => console.log(new Date().toISOString(), msg),
  checkEveryMs = 3000,
} = {}) {
  const git = makeGit(gitDir);
  const images = createImageStore(git);
  const indexer = createIndexer({ git, registryFile, buildsDir, images, decisionsDir, checkEveryMs, log });
  const inbox = createInbox(inboxDir);
  const assets = loadStatic();
  render.setAssetVersion(assets.version);

  function send(res, status, body, type = 'text/html; charset=utf-8', extra = {}) {
    const buf = Buffer.from(body);
    res.writeHead(status, { ...SECURITY_HEADERS, 'Content-Type': type, 'Content-Length': buf.length, 'Cache-Control': 'no-cache', ...extra });
    res.end(res.req.method === 'HEAD' ? undefined : buf);
  }

  async function states(index) {
    const { records } = await inbox.read();
    return new Map(index.decisions.cards.map((c) => [c.id, decisionState(c, records)]));
  }

  function redirect(res, to) {
    res.writeHead(303, { ...SECURITY_HEADERS, Location: to, 'Content-Length': 0 });
    res.end();
  }

  // Form posts: an answer to one decision, or "accept all" for a group's
  // small picks. Each writes inbox records, then redirects (no script needed).
  async function handlePost(req, res, segs) {
    // Same-site posts only. Browsers send Sec-Fetch-Site; with the portal's
    // no-referrer policy they send "Origin: null" on form posts, so Origin is
    // only compared when it names a real origin.
    const site = req.headers['sec-fetch-site'];
    const origin = req.headers.origin;
    let sameOrigin;
    if (site) sameOrigin = site === 'same-origin' || site === 'none';
    else if (origin && origin !== 'null') {
      try {
        sameOrigin = new URL(origin).host === req.headers.host;
      } catch {
        sameOrigin = false;
      }
    } else sameOrigin = true;
    if (!sameOrigin) return send(res, 403, render.errorPage(403, 'Answers can only be sent from this site.'));

    let form;
    try {
      form = await readForm(req);
    } catch (e) {
      const status = e.status || 400;
      const msg = { 413: 'That answer is too long to send.', 415: 'That form could not be read.' }[status] || 'That form could not be read.';
      return send(res, status, render.errorPage(status, msg));
    }
    const index = await indexer.get();
    const ua = String(req.headers['user-agent'] || '');

    if (segs[0] === 'd') {
      const c = index.decisions.cards.find((x) => x.id === segs[1]);
      if (!c) return send(res, 404, render.errorPage(404, 'There is no decision at this address.', index));
      const choice = (form.get('choice') || '').trim();
      const note = (form.get('note') || '').replace(/\r\n?/g, '\n').trim();
      const st = (await states(index)).get(c.id);
      let error = '';
      if (choice && !c.options.includes(choice)) error = "That choice isn't one of the options. Pick one again.";
      else if (!choice && !note) error = c.options.length ? 'Pick an option or write a note, then send.' : 'Write your answer, then send.';
      else if (note.length > 4000) error = 'That note is too long: please keep it under 4,000 characters.';
      if (error) return send(res, 400, render.decisionPage(index, c, st, { error, note, choice: c.options.includes(choice) ? choice : '' }));
      const rec = await inbox.write({ kind: 'answer', decisionId: c.id, choice, note, userAgent: ua });
      log(`answer ${req.socket.remoteAddress} ${c.id} ${rec.id}`);
      return redirect(res, `/d/${encodeURIComponent(c.id)}?sent=1#answered`);
    }

    // Accept all: only the ids shown on the page, and only those still open.
    const group = segs[1];
    const st = await states(index);
    const wanted = new Set(form.getAll('id'));
    const take = index.decisions.cards.filter(
      (c) => wanted.has(c.id) && c.size === 'small' && (c.group || 'other') === group && c.suggested && st.get(c.id).state === 'open',
    );
    for (const c of take) {
      const rec = await inbox.write({ kind: 'accept-small', decisionId: c.id, choice: c.suggested, note: '', userAgent: ua });
      log(`accept-small ${req.socket.remoteAddress} ${c.id} ${rec.id}`);
    }
    return redirect(res, `/picks/${encodeURIComponent(group)}${take.length ? `?accepted=${take.length}` : ''}`);
  }

  // The gallery runs its own inline script and styles and loads Google
  // fonts, so it gets a looser CSP than the portal's pages, on this route only.
  // Its script is allowed by hash, not by 'unsafe-inline'.
  async function sendGallery(req, res, g, index) {
    const p = `${g.dir}/${g.page}`;
    const html = await git.showFile(g.resolved.sha, p);
    if (html === null) return send(res, 404, render.errorPage(404, "The gallery can't be found right now.", index));
    const hashes = [];
    for (const m of html.matchAll(/<script(\s[^>]*)?>([\s\S]*?)<\/script>/gi)) {
      if (m[1] && /\bsrc\s*=/.test(m[1])) continue;
      hashes.push(`'sha256-${crypto.createHash('sha256').update(m[2], 'utf8').digest('base64')}'`);
    }
    const csp = [
      "default-src 'none'",
      "img-src 'self' data:",
      "style-src 'unsafe-inline' https://fonts.googleapis.com",
      'font-src https://fonts.gstatic.com',
      `script-src ${hashes.length ? hashes.join(' ') : "'none'"}`,
      "base-uri 'self'",
      "form-action 'none'",
      "frame-ancestors 'none'",
    ].join('; ');
    const back =
      '<nav aria-label="Portal" style="max-width:1180px;margin:0 auto 12px"><a href="/" style="display:inline-flex;align-items:center;min-height:44px;font-weight:700">&larr; Back to Bramble</a></nav>';
    let page = html;
    const styleEnd = page.search(/<\/style>/i);
    page = styleEnd === -1 ? back + page : page.slice(0, styleEnd + 8) + '\n' + back + page.slice(styleEnd + 8);
    if (!/^\s*<!doctype/i.test(page)) page = '<!doctype html>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n' + page;
    return send(res, 200, page, 'text/html; charset=utf-8', { 'Content-Security-Policy': csp });
  }

  async function handle(req, res) {
    const addr = req.socket.remoteAddress;
    if (!allow(addr)) {
      log(`403 ${addr} ${req.method} ${req.url}`);
      return send(res, 403, render.forbiddenPage(addr));
    }

    let url;
    try {
      url = new URL(req.url, 'http://portal.local');
    } catch {
      return send(res, 400, render.errorPage(400, 'That address is not valid.'));
    }
    let segs;
    try {
      segs = url.pathname.split('/').slice(1).map(decodeURIComponent);
    } catch {
      return send(res, 400, render.errorPage(400, 'That address is not valid.'));
    }

    const isPost = req.method === 'POST';
    const postable = (segs[0] === 'd' && segs.length === 3 && segs[2] === 'answer') || (segs[0] === 'picks' && segs.length === 3 && segs[2] === 'accept');
    if (isPost && postable) return handlePost(req, res, segs);
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      return send(res, 405, 'Method not allowed', 'text/plain; charset=utf-8', { Allow: postable ? 'GET, HEAD, POST' : 'GET, HEAD' });
    }

    if (segs[0] === 'static' && segs.length === 2 && STATIC[segs[1]]) {
      const etag = `"${assets.version}"`;
      if (req.headers['if-none-match'] === etag) {
        res.writeHead(304, { ETag: etag });
        return res.end();
      }
      return send(res, 200, assets.files[segs[1]], STATIC[segs[1]], {
        ETag: etag,
        'Cache-Control': url.searchParams.get('v') === assets.version ? 'public, max-age=31536000, immutable' : 'no-cache',
      });
    }
    if (url.pathname === '/favicon.ico') {
      res.writeHead(301, { Location: `/static/icon.svg?v=${assets.version}` });
      return res.end();
    }

    if (url.pathname === '/healthz') {
      const index = await indexer.get();
      return send(
        res,
        200,
        JSON.stringify({
          ok: true,
          builtAt: index.builtAt,
          workstreams: index.workstreams.length,
          builds: index.builds.builds.length,
          decisions: index.decisions.cards.length,
          openQuestions: Object.fromEntries(index.workstreams.filter((w) => w.questions).map((w) => [w.id, w.questions.count])),
          stale: index.stale || null,
        }),
        'application/json',
      );
    }

    // Downloads: /builds/<build>/<file>
    if (segs[0] === 'builds' && segs.length >= 3) {
      const r = await resolveBuildFile(buildsDir, segs[1], segs.slice(2));
      if (r.error) {
        const msg = { 400: 'That file name is not allowed.', 403: 'That file is outside the build folder.', 404: 'There is no such build file.' }[r.error];
        return send(res, r.error, render.errorPage(r.error, msg));
      }
      log(`download ${addr} ${r.build}/${r.rel} ${req.headers.range || ''}`.trim());
      return sendFile(req, res, r, downloadName(r.file, r.build));
    }

    const index = await indexer.get();

    // Pictures from git: /git/<branch>/<path>, allowed branches and image types only.
    if (segs[0] === 'git') {
      const split = splitBranchPath(segs.slice(1), Object.keys(index.imageBranches));
      if (!split) return send(res, 404, render.errorPage(404, "Pictures aren't shared from that branch.", index));
      const p = safeRepoPath(split.segs);
      if (!p) return send(res, 400, render.errorPage(400, 'That file name is not allowed.', index));
      if (!imageType(p)) return send(res, 403, render.errorPage(403, 'Only pictures are shared here.', index));
      const ok = await images.send(req, res, { commit: index.imageBranches[split.branch].sha, path: p, headers: SECURITY_HEADERS });
      if (!ok) return send(res, 404, render.errorPage(404, 'There is no such picture.', index));
      return;
    }

    // The design-lab gallery, a self-contained page, with its own pictures.
    if (segs[0] === 'design-lab') {
      const g = index.gallery;
      if (!g || !g.resolved) return send(res, 404, render.errorPage(404, "The gallery can't be found right now.", index));
      if (segs.length === 1) {
        res.writeHead(301, { Location: '/design-lab/' });
        return res.end();
      }
      const rest = segs.slice(1);
      if (rest.length === 1 && (rest[0] === '' || rest[0] === 'index.html' || rest[0] === g.page)) return sendGallery(req, res, g, index);
      const p = safeRepoPath(rest);
      if (!p) return send(res, 400, render.errorPage(400, 'That file name is not allowed.', index));
      if (!imageType(p)) return send(res, 403, render.errorPage(403, 'Only pictures are shared here.', index));
      const ok = await images.send(req, res, { commit: g.resolved.sha, path: `${g.dir}/${p}`, headers: SECURITY_HEADERS });
      if (!ok) return send(res, 404, render.errorPage(404, 'There is no such picture.', index));
      return;
    }

    if (url.pathname === '/' || url.pathname === '/index.html') return send(res, 200, render.homePage(index, await states(index)));
    if (segs[0] === 'd' && segs.length === 2) {
      const c = index.decisions.cards.find((x) => x.id === segs[1]);
      if (!c) return send(res, 404, render.errorPage(404, 'There is no decision at this address.', index));
      const st = (await states(index)).get(c.id);
      return send(res, 200, render.decisionPage(index, c, st, { sent: url.searchParams.has('sent') }));
    }
    if (segs[0] === 'picks' && segs.length === 2) {
      if (!index.decisions.cards.some((c) => c.size === 'small' && (c.group || 'other') === segs[1])) {
        return send(res, 404, render.errorPage(404, 'There are no small picks at this address.', index));
      }
      const accepted = Math.min(99, Number(url.searchParams.get('accepted')) || 0);
      return send(res, 200, render.picksPage(index, segs[1], await states(index), { accepted }));
    }
    if (url.pathname === '/builds' || url.pathname === '/builds/') return send(res, 200, render.buildsPage(index));
    if (url.pathname === '/playtest') return send(res, 200, render.playtestPage(index));
    if (segs[0] === 'w' && (segs.length === 2 || (segs.length === 3 && segs[2] === 'questions'))) {
      const w = index.workstreams.find((x) => x.id === segs[1]);
      if (w && segs.length === 2) return send(res, 200, render.workstreamPage(index, w));
      if (w && w.questions) return send(res, 200, render.questionsPage(index, w));
      if (w) return send(res, 404, render.errorPage(404, `${w.title} has no questions file.`, index));
    }
    return send(res, 404, render.errorPage(404, 'There is no page at this address.', index));
  }

  const handler = (req, res) => {
    handle(req, res).catch((e) => {
      log(`500 ${req.method} ${req.url}: ${e.stack || e.message}`);
      if (!res.headersSent) send(res, 500, render.errorPage(500, 'The portal hit an error reading the project. The details are in its log.'));
      else res.destroy();
    });
  };

  return { handler, indexer, inbox };
}

// IPv4 only, by the owner's choice (4 Nov 2026): one listener on 0.0.0.0,
// so client addresses are always plain IPv4.
function listen(handler, port, log) {
  const s = http.createServer(handler);
  s.headersTimeout = 20000;
  s.requestTimeout = 0; // long downloads on slow Wi-Fi
  s.keepAliveTimeout = 5000;
  return new Promise((resolve, reject) => {
    s.once('error', reject);
    s.listen({ host: '0.0.0.0', port }, () => {
      const actual = s.address().port;
      log(`listening on 0.0.0.0:${actual} (IPv4 only)`);
      resolve({ servers: [s], port: actual });
    });
  });
}

if (require.main === module) {
  const port = Number(process.env.PORTAL_PORT || 8780);
  const log = (msg) => console.log(msg);
  const app = createApp({ log });
  listen(app.handler, port, log)
    .then(({ servers }) => {
      app.indexer.get().catch((e) => log(`first index failed: ${e.message}`));
      app.inbox
        .ensureDir()
        .then(() => log(`answers go to ${app.inbox.dir}`))
        .catch((e) => log(`the inbox folder ${app.inbox.dir} can't be created yet: ${e.message}`));
      const stop = () => {
        for (const s of servers) s.close();
        setTimeout(() => process.exit(0), 500).unref();
      };
      process.on('SIGTERM', stop);
      process.on('SIGINT', stop);
    })
    .catch((e) => {
      console.error(`can't listen on port ${port}: ${e.message}`);
      process.exit(1);
    });
}

module.exports = { createApp, listen };
