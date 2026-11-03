'use strict';
// Bramble portal: a read-only, LAN-only status site for the project.
// Run: node server.js   (env: PORTAL_PORT, PORTAL_GIT_DIR, PORTAL_BUILDS_DIR)

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
  allow = isAllowed,
  log = (msg) => console.log(new Date().toISOString(), msg),
  checkEveryMs = 3000,
} = {}) {
  const git = makeGit(gitDir);
  const indexer = createIndexer({ git, registryFile, buildsDir, checkEveryMs, log });
  const assets = loadStatic();
  render.setAssetVersion(assets.version);

  function send(res, status, body, type = 'text/html; charset=utf-8', extra = {}) {
    const buf = Buffer.from(body);
    res.writeHead(status, { ...SECURITY_HEADERS, 'Content-Type': type, 'Content-Length': buf.length, 'Cache-Control': 'no-cache', ...extra });
    res.end(res.req.method === 'HEAD' ? undefined : buf);
  }

  async function handle(req, res) {
    const addr = req.socket.remoteAddress;
    if (!allow(addr)) {
      log(`403 ${addr} ${req.method} ${req.url}`);
      return send(res, 403, render.forbiddenPage(addr), 'text/html; charset=utf-8', { 'Content-Security-Policy': render.FORBIDDEN_CSP });
    }
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      return send(res, 405, 'Method not allowed', 'text/plain; charset=utf-8', { Allow: 'GET, HEAD' });
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
          latestBuild: index.builds.latest ? index.builds.latest.name : null,
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

    if (url.pathname === '/' || url.pathname === '/index.html') return send(res, 200, render.homePage(index));
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

  return { handler, indexer };
}

// Listens on IPv4 and IPv6 separately, so it works whatever bindv6only is set
// to, and keeps going on IPv4 if IPv6 is unavailable.
function listen(handler, port, log) {
  const servers = [];
  const make = () => {
    const s = http.createServer(handler);
    s.headersTimeout = 20000;
    s.requestTimeout = 0; // long downloads on slow Wi-Fi
    s.keepAliveTimeout = 5000;
    servers.push(s);
    return s;
  };
  return new Promise((resolve, reject) => {
    const v4 = make();
    v4.once('error', reject);
    v4.listen({ host: '0.0.0.0', port }, () => {
      const actual = v4.address().port;
      log(`listening on 0.0.0.0:${actual}`);
      const v6 = make();
      v6.once('error', (e) => {
        log(`IPv6 listener not started (${e.code || e.message}); IPv4 only`);
        servers.pop();
        resolve({ servers, port: actual });
      });
      v6.listen({ host: '::', port: actual, ipv6Only: true }, () => {
        log(`listening on [::]:${actual}`);
        resolve({ servers, port: actual });
      });
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
