'use strict';
// Renders the real decision cards (portal/main once merged, else the content
// branch) from a temp copy, and checks every card has no format problems,
// every page renders, and every picture is served as a real image.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { createApp } = require('../server');
const { GIT_DIR, tmpDir, startApp, rawGet } = require('./helpers');

const git = (...args) => execFileSync('git', ['--git-dir=' + GIT_DIR, ...args], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });

function cardsAt(branch) {
  try {
    return git('show', `${branch}:docs/decisions/`).split('\n').slice(2).filter((n) => /\.md$/.test(n) && !/^readme\.md$/i.test(n));
  } catch {
    return [];
  }
}

const BRANCH = ['portal/main', 'portal/decisions-content'].find((b) => cardsAt(b).length);

test('every real card renders with no problems and its pictures load', { skip: !BRANCH && 'no decision cards on portal/main or portal/decisions-content' }, async (t) => {
  const dir = tmpDir('portal-real-cards-');
  const names = cardsAt(BRANCH);
  for (const n of names) fs.writeFileSync(path.join(dir, n), git('show', `${BRANCH}:docs/decisions/${n}`));
  const app = createApp({ gitDir: GIT_DIR, decisionsDir: dir, inboxDir: tmpDir('portal-inbox-'), log: () => {} });
  const srv = await startApp(app);
  t.after(srv.close);

  const index = await app.indexer.get();
  assert.equal(index.decisions.cards.length, names.length);
  for (const c of index.decisions.cards) assert.deepEqual(c.problems, [], `${c.id} has format problems`);

  const home = await rawGet(srv.base, '/');
  assert.equal(home.status, 200);
  const seen = new Set();
  for (const c of index.decisions.cards) {
    const r = await rawGet(srv.base, `/d/${c.id}`);
    assert.equal(r.status, 200, c.id);
    const html = r.body.toString();
    assert.doesNotMatch(html, /formatting problem|can.t be shown|\(not found\)/, c.id);
    const srcs = [...html.matchAll(/<img src="([^"]+)"/g)].map((m) => m[1]);
    assert.equal(srcs.length, c.images.length, `${c.id}: every picture is on the page`);
    for (const src of srcs) {
      if (seen.has(src)) continue;
      seen.add(src);
      const img = await rawGet(srv.base, src.replace(/&amp;/g, '&'));
      assert.equal(img.status, 200, src);
      assert.match(img.headers['content-type'], /^image\//, src);
      const b = img.body;
      const magic = (b[0] === 0xff && b[1] === 0xd8) || b.toString('ascii', 1, 4) === 'PNG' || b.toString('ascii', 8, 12) === 'WEBP';
      assert.ok(magic, `${src} is a real image`);
    }
  }
  for (const g of new Set(index.decisions.cards.filter((c) => c.size === 'small').map((c) => c.group))) {
    assert.equal((await rawGet(srv.base, `/picks/${g}`)).status, 200, g);
  }
});
