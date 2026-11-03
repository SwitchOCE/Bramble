'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const { createApp } = require('../server');
const { imageType, safeRepoPath, splitBranchPath } = require('../lib/images');
const render = require('../lib/render');
const { GIT_DIR, tmpDir, startApp, rawGet } = require('./helpers');

const FIX = path.join(__dirname, 'fixtures', 'decisions');
const BAD = path.join(__dirname, 'fixtures', 'decisions-bad');
const IMG = '/git/design-lab/main/docs/design-lab/game/folk_print_recruit_1688x780.jpg';

async function app(t, opts = {}) {
  const inboxDir = opts.inboxDir || tmpDir('portal-inbox-');
  const a = createApp({ gitDir: GIT_DIR, decisionsDir: FIX, inboxDir, log: () => {}, ...opts });
  const srv = await startApp(a);
  t.after(srv.close);
  return { ...srv, inboxDir };
}

function post(base, p, body, headers = {}) {
  const u = new URL(base);
  const buf = Buffer.from(body);
  return new Promise((resolve, reject) => {
    const req = http.request(
      { host: u.hostname, port: u.port, path: p, method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': buf.length, Origin: base, ...headers } },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks).toString() }));
      },
    );
    req.on('error', reject);
    req.end(buf);
  });
}

const records = (dir) =>
  fs
    .readdirSync(dir)
    .filter((n) => n.endsWith('.json') && !n.endsWith('.handled.json'))
    .map((n) => ({ name: n, ...JSON.parse(fs.readFileSync(path.join(dir, n), 'utf8')) }));

test('image helpers', () => {
  assert.equal(imageType('a/b.JPG'), 'image/jpeg');
  assert.equal(imageType('a/b.svg'), null, 'no SVG');
  assert.equal(imageType('a/b.html'), null);
  assert.equal(imageType('a/b'), null);
  assert.equal(safeRepoPath(['docs', 'a.jpg']), 'docs/a.jpg');
  for (const bad of [['..', 'a.jpg'], ['docs', '.', 'a.jpg'], ['docs', '', 'a.jpg'], ['docs/../../a.jpg'], ['-x.jpg'], ['a\\b.jpg'], []]) {
    assert.equal(safeRepoPath(bad), null, JSON.stringify(bad));
  }
  assert.deepEqual(splitBranchPath(['design-lab', 'main', 'docs', 'a.jpg'], ['main', 'design-lab/main']), { branch: 'design-lab/main', segs: ['docs', 'a.jpg'] });
  assert.deepEqual(splitBranchPath(['main', 'docs', 'a.jpg'], ['main', 'design-lab/main']), { branch: 'main', segs: ['docs', 'a.jpg'] });
  assert.equal(splitBranchPath(['design-lab', 'main'], ['design-lab/main']), null, 'a branch with no path');
  assert.equal(splitBranchPath(['secret', 'a.jpg'], ['main']), null);
});

test('/git serves pictures from allowed branches, with blob-id ETags', async (t) => {
  const { base } = await app(t);
  const r = await rawGet(base, IMG);
  assert.equal(r.status, 200);
  assert.equal(r.headers['content-type'], 'image/jpeg');
  assert.equal(r.body[0], 0xff);
  assert.equal(Number(r.headers['content-length']), r.body.length);
  const etag = r.headers.etag;
  assert.match(etag, /^"[0-9a-f]{40}"$/);
  assert.equal(r.headers['cache-control'], 'no-cache');
  assert.equal((await rawGet(base, IMG, { 'If-None-Match': etag })).status, 304);
  assert.equal((await rawGet(base, IMG, {}, 'HEAD')).status, 200);
});

test('/git refuses non-images, unknown branches and traversal', async (t) => {
  const { base } = await app(t);
  assert.equal((await rawGet(base, '/git/design-lab/main/docs/design-lab/PLAN.md')).status, 403);
  assert.equal((await rawGet(base, '/git/design-lab/main/docs/design-lab/gallery.html')).status, 403);
  assert.equal((await rawGet(base, '/git/design/tribes-and-budget/docs/x.png')).status, 404, 'branch not in the allow-list');
  assert.equal((await rawGet(base, '/git/no/such/a.jpg')).status, 404);
  assert.equal((await rawGet(base, '/git/design-lab/main/docs%2F..%2F..%2Fx.jpg')).status, 400);
  assert.equal((await rawGet(base, '/git/design-lab/main/docs/%2e%2e/%2e%2e/x.jpg')).status, 404, 'dot segments are resolved by the URL parser, leaving no allowed branch');
  assert.equal((await rawGet(base, '/git/design-lab/main/docs//x.jpg')).status, 400);
  assert.equal((await rawGet(base, '/git/design-lab/main/docs/design-lab/game/none.jpg')).status, 404);
});

test('the gallery is served with its own CSP, and its relative pictures load', async (t) => {
  const { base } = await app(t);
  assert.equal((await rawGet(base, '/design-lab')).status, 301);
  const g = await rawGet(base, '/design-lab/');
  assert.equal(g.status, 200);
  const csp = g.headers['content-security-policy'];
  assert.match(csp, /script-src 'sha256-[A-Za-z0-9+/=]+'/);
  assert.doesNotMatch(csp.split(';').find((d) => d.includes('script-src')), /unsafe-inline/);
  assert.match(g.body.toString(), /^<!doctype html>/);
  assert.match(g.body.toString(), /Back to Bramble/);
  const shot = await rawGet(base, '/design-lab/game/woodcraft_recruit_1688x780.jpg');
  assert.equal(shot.status, 200);
  assert.equal(shot.headers['content-security-policy'].startsWith("default-src 'none'"), true, 'pictures keep the strict policy');
  assert.equal((await rawGet(base, '/design-lab/PLAN.md')).status, 403);
  assert.equal((await rawGet(base, '/design-lab/../server.js')).status, 404);
  // The portal's own pages keep the strict policy.
  assert.match((await rawGet(base, '/')).headers['content-security-policy'], /script-src|default-src 'none'/);
  assert.doesNotMatch((await rawGet(base, '/')).headers['content-security-policy'], /unsafe-inline/);
});

test('home groups the decisions; decision and picks pages render', async (t) => {
  const { base } = await app(t);
  const html = (await rawGet(base, '/')).body.toString();
  const order = ['data-group="looks"', 'data-group="plays"', 'data-group="prototype"'].map((s) => html.indexOf(s));
  assert.ok(order.every((i) => i > 0) && order[0] < order[1] && order[1] < order[2], 'groups in order');
  assert.match(html, /Two small picks already made for you/);
  assert.match(html, /How it looks and feels/);
  assert.ok(html.indexOf('What needs you') < html.indexOf('Latest build') && html.indexOf('Latest build') < html.indexOf('Where things are'));
  assert.doesNotMatch(html, /ws-card|Last done|Next step/, 'no workstream cards or process fragments on home');
  const d = (await rawGet(base, '/d/look-direction')).body.toString();
  assert.match(d, /<img src="\/git\/design-lab\/main\/docs\/design-lab\/game\/folk_print_recruit_1688x780\.jpg" alt="The shop in Folk Print"/);
  assert.match(d, /name="choice" value="Folk Print"/);
  assert.match(d, /More detail/);
  assert.match(d, /href="\/design-lab\/"/, 'site links in a card work');
  assert.match(d, /Prototype questions, number 16/);
  const picks = (await rawGet(base, '/picks/prototype')).body.toString();
  assert.match(picks, /Accept all/);
  assert.match(picks, /We went with <b>Random each game<\/b>/);
  assert.equal((await rawGet(base, '/d/nope')).status, 404);
  assert.equal((await rawGet(base, '/picks/looks')).status, 404);
});

test('malformed cards are shown plainly', async (t) => {
  const { base } = await app(t, { decisionsDir: BAD });
  const r = await rawGet(base, '/');
  assert.equal(r.status, 200);
  const html = r.body.toString();
  assert.match(html, /Other decisions/);
  assert.match(html, /Parts of this card are missing/);
  const d = await rawGet(base, '/d/broken-fields');
  assert.equal(d.status, 200);
  assert.match(d.body.toString(), /This card has a formatting problem; details below\./);
  assert.match(d.body.toString(), /<details class="more"[\s\S]*?isn&#39;t one of the groups/, 'the list sits under More detail');
  assert.match(d.body.toString(), /This picture can(&#39;|')t be shown/);
});

test('answering writes one inbox record, redirects, and the card then waits for an agent; handled shows done', async (t) => {
  const { base, inboxDir } = await app(t);
  const r = await post(base, '/d/look-direction/answer', 'choice=Woodcraft&note=Lighter+walnut%2C+please.');
  assert.equal(r.status, 303);
  assert.equal(r.headers.location, '/d/look-direction?sent=1#answered');
  // A browser form post under the no-referrer policy: Origin is "null".
  assert.equal((await post(base, '/d/look-direction/answer', 'note=again', { Origin: 'null', 'Sec-Fetch-Site': 'same-origin' })).status, 303);
  fs.readdirSync(inboxDir).filter((n) => n.includes('again') || JSON.parse(fs.readFileSync(path.join(inboxDir, n))).note === 'again').forEach((n) => fs.rmSync(path.join(inboxDir, n)));
  const [rec] = records(inboxDir);
  assert.equal(rec.kind, 'answer');
  assert.equal(rec.decisionId, 'look-direction');
  assert.equal(rec.choice, 'Woodcraft');
  assert.equal(rec.note, 'Lighter walnut, please.');
  const page = (await rawGet(base, '/d/look-direction?sent=1')).body.toString();
  assert.match(page, /Answered, waiting for an agent/);
  assert.match(page, /You answered <b>Woodcraft<\/b>/);
  assert.match((await rawGet(base, '/')).body.toString(), /data-decision="look-direction"[\s\S]*?Answered, waiting for an agent/);

  fs.writeFileSync(path.join(inboxDir, rec.name.replace(/\.json$/, '.handled.json')), JSON.stringify({ handledAt: new Date().toISOString(), by: 'test', summary: 'Woodcraft is the base look now.' }));
  const done = (await rawGet(base, '/d/look-direction')).body.toString();
  assert.match(done, /Done/);
  assert.match(done, /Woodcraft is the base look now\./);
  assert.match((await rawGet(base, '/')).body.toString(), /already settled/);
});

test('bad answers are refused without writing anything', async (t) => {
  const { base, inboxDir } = await app(t);
  assert.equal((await post(base, '/d/look-direction/answer', 'choice=Purple')).status, 400);
  const empty = await post(base, '/d/look-direction/answer', 'note=++');
  assert.equal(empty.status, 400);
  assert.match(empty.body, /Pick an option or write a note/);
  assert.equal((await post(base, '/d/look-direction/answer', 'note=' + 'x'.repeat(20000))).status, 413);
  assert.equal((await post(base, '/d/look-direction/answer', '{}', { 'Content-Type': 'application/json' })).status, 415);
  assert.equal((await post(base, '/d/look-direction/answer', 'note=hi', { Origin: 'http://evil.example' })).status, 403);
  assert.equal((await post(base, '/d/look-direction/answer', 'note=hi', { Origin: '', 'Sec-Fetch-Site': 'cross-site' })).status, 403);
  assert.equal((await post(base, '/d/nope/answer', 'note=hi')).status, 404);
  assert.equal((await post(base, '/d/look-direction/answer', 'note=hi', { Origin: 'http://127.0.0.1:1', 'Sec-Fetch-Site': 'same-site' })).status, 403);
  assert.equal((await post(base, '/', 'note=hi')).status, 405);
  assert.deepEqual(records(inboxDir), []);
});

test('accept all writes one accept-small record per open small pick shown', async (t) => {
  const { base, inboxDir } = await app(t);
  const r = await post(base, '/picks/prototype/accept', 'id=opponents-live-lobby&id=random-seed&id=look-direction&id=nope');
  assert.equal(r.status, 303);
  assert.equal(r.headers.location, '/picks/prototype?accepted=2');
  const recs = records(inboxDir);
  assert.deepEqual(recs.map((x) => x.decisionId).sort(), ['opponents-live-lobby', 'random-seed']);
  assert.ok(recs.every((x) => x.kind === 'accept-small'));
  assert.deepEqual(recs.map((x) => x.choice).sort(), ['Random each game', 'Yes, fine for now']);
  const page = (await rawGet(base, '/picks/prototype?accepted=2')).body.toString();
  assert.match(page, /2 picks accepted|two picks accepted/);
  assert.doesNotMatch(page, /Accept all/);
  assert.match((await rawGet(base, '/')).body.toString(), /Small picks accepted, waiting for an agent/);
  // A second accept writes nothing new.
  await post(base, '/picks/prototype/accept', 'id=random-seed');
  assert.equal(records(inboxDir).length, 2);
});

test('"Where things are" uses the In short line, or the status word only', () => {
  const ws = [
    { id: 'a', title: 'A', status: { state: 'ok', status: 'active', fields: { inShort: 'Playable: a full game against bots.', next: 'NEXT-FRAGMENT', lastDone: 'LAST-FRAGMENT' }, problems: [] } },
    { id: 'b', title: 'B', status: { state: 'ok', status: 'paused', fields: { next: 'NEXT-FRAGMENT', lastDone: 'LAST-FRAGMENT' }, problems: [] } },
    { id: 'c', title: 'C', status: { state: 'missing', status: null, fields: {}, problems: [] } },
  ];
  const index = { workstreams: ws, builds: { builds: [], latest: null }, decisions: { cards: [], problems: [] }, builtAt: new Date() };
  const html = render.homePage(index, new Map());
  assert.match(html, /data-ws="a"[\s\S]*?Playable: a full game against bots\./);
  assert.match(html, /data-ws="b"[\s\S]*?Paused\./);
  assert.match(html, /data-ws="c"[\s\S]*?No status yet\./);
  assert.doesNotMatch(html, /FRAGMENT/);
  assert.match(html, /Nothing needs you right now\./);
});
