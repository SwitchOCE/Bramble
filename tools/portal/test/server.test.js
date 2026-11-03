'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createApp } = require('../server');
const { GIT_DIR, tmpDir, startApp, rawGet } = require('./helpers');

test('clients outside the allow-list get 403', async (t) => {
  const app = createApp({ gitDir: GIT_DIR, allow: () => false, log: () => {} });
  const srv = await startApp(app);
  t.after(srv.close);
  const r = await rawGet(srv.base, '/');
  assert.equal(r.status, 403);
  assert.match(r.body.toString(), /home network or Tailscale/);
  const d = await rawGet(srv.base, '/builds/1104-0400-build4/Bramble.apk');
  assert.equal(d.status, 403);
});

test('the default allow-list lets loopback through', async (t) => {
  const app = createApp({ gitDir: GIT_DIR, log: () => {} });
  const srv = await startApp(app);
  t.after(srv.close);
  assert.equal((await rawGet(srv.base, '/healthz')).status, 200);
});

test('home renders all workstreams from the real repo; malformed and missing blocks are shown plainly', async (t) => {
  const dir = tmpDir('portal-reg-');
  const reg = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'workstreams.json'), 'utf8'));
  reg.workstreams.push(
    { id: 'ghost', title: 'Ghost', branches: ['no/such/branch'], plan: 'docs/x.md' },
    { id: 'nostatus', title: 'No status', branches: ['proto/main'], plan: 'docs/prototype/SPEC.md' },
  );
  const file = path.join(dir, 'workstreams.json');
  fs.writeFileSync(file, JSON.stringify(reg));
  const app = createApp({ gitDir: GIT_DIR, registryFile: file, log: () => {} });
  const srv = await startApp(app);
  t.after(srv.close);
  const r = await rawGet(srv.base, '/');
  assert.equal(r.status, 200);
  const html = r.body.toString();
  assert.equal((html.match(/class="card ws-card/g) || []).length, 9);
  assert.match(html, /data-ws="ghost"[\s\S]*?Missing status block[\s\S]*?not found on no\/such\/branch/);
  assert.match(html, /data-ws="nostatus"[\s\S]*?Missing status block/);
  assert.match(html, /16 open questions/);
  assert.match(html, /9 open questions/);
  for (const id of ['prototype', 'design-lab', 'rules-and-budget', 'mechanics-library', 'art-and-folio', 'architecture', 'portal']) {
    const p = await rawGet(srv.base, `/w/${id}`);
    assert.equal(p.status, 200, id);
  }
  assert.equal((await rawGet(srv.base, '/w/ghost')).status, 200);
  assert.equal((await rawGet(srv.base, '/w/prototype/questions')).status, 200);
  assert.equal((await rawGet(srv.base, '/w/design-lab/questions')).status, 404);
  assert.equal((await rawGet(srv.base, '/w/nope')).status, 404);
  assert.equal((await rawGet(srv.base, '/nope')).status, 404);
  assert.equal((await rawGet(srv.base, '/', {}, 'POST')).status, 405);
});

test('a broken registry shows a banner, not a crash', async (t) => {
  const dir = tmpDir('portal-reg-');
  const file = path.join(dir, 'workstreams.json');
  fs.writeFileSync(file, '{ not json');
  const app = createApp({ gitDir: GIT_DIR, registryFile: file, log: () => {} });
  const srv = await startApp(app);
  t.after(srv.close);
  const r = await rawGet(srv.base, '/');
  assert.equal(r.status, 200);
  assert.match(r.body.toString(), /workstream list couldn't be read/);
});

test('pages send security headers', async (t) => {
  const app = createApp({ gitDir: GIT_DIR, log: () => {} });
  const srv = await startApp(app);
  t.after(srv.close);
  const r = await rawGet(srv.base, '/builds');
  assert.equal(r.status, 200);
  assert.match(r.headers['content-security-policy'], /default-src 'none'/);
  assert.equal(r.headers['x-frame-options'], 'DENY');
});
