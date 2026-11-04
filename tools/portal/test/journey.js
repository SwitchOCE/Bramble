'use strict';
// Browser journey against a running portal. Usage (see check.sh):
//   PORTAL_URL=http://127.0.0.1:8789 PORTAL_INBOX_DIR=<temp dir> node test/journey.js
// The server must be started with the same PORTAL_INBOX_DIR and with
// PORTAL_DECISIONS_DIR pointing at the fixture cards. Needs Playwright on
// NODE_PATH. Saves screenshots to shots/. One Chromium at a time.

const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const { chromium } = require('playwright');

const BASE = process.env.PORTAL_URL || 'http://127.0.0.1:8780';
const INBOX = process.env.PORTAL_INBOX_DIR;
const SHOTS = path.join(__dirname, '..', 'shots');
// Expected counts come from the registry and the server's own index, not
// from today's data, so a new build or an answered question doesn't fail the gate.
const REGISTRY = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'workstreams.json'), 'utf8'));
const EXPECT_WS = REGISTRY.workstreams.length;
const GROUP_ORDER = ['looks', 'plays', 'units', 'prototype', 'code', 'other'];

if (!INBOX || !path.resolve(INBOX).startsWith(os.tmpdir())) {
  console.error('PORTAL_INBOX_DIR must be a temp folder: the journey answers decisions and clears the inbox between runs.');
  process.exit(2);
}

const sizes = [
  { name: '390', width: 390, height: 844 },
  { name: '1280', width: 1280, height: 900 },
];
const schemes = ['light', 'dark'];

const failures = [];
function check(cond, msg) {
  if (cond) console.log(`  ok   ${msg}`);
  else {
    console.log(`  FAIL ${msg}`);
    failures.push(msg);
  }
}

function clearInbox() {
  fs.mkdirSync(INBOX, { recursive: true });
  for (const n of fs.readdirSync(INBOX)) fs.rmSync(path.join(INBOX, n), { force: true });
}
function inboxRecords() {
  if (!fs.existsSync(INBOX)) return [];
  return fs
    .readdirSync(INBOX)
    .filter((n) => n.endsWith('.json') && !n.endsWith('.handled.json'))
    .map((n) => ({ file: n, ...JSON.parse(fs.readFileSync(path.join(INBOX, n), 'utf8')) }));
}

async function pageChecks(page, label, { targets = true } = {}) {
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  check(overflow <= 0, `${label}: no horizontal overflow (${overflow}px)`);
  if (!targets) return;
  const small = await page.evaluate(() => {
    const sel = [
      '.site-nav a', '.brand', '.btn', '.meta-link', '.text-link', 'details summary', '.crumbs a', '.fact-link', '.install-hint a',
      '.d-item a', '.picks-line', '.where-list a', '.opt-body', '.sources a', '.fig-link',
    ].join(', ');
    return [...document.querySelectorAll(sel)]
      .filter((el) => el.offsetParent !== null)
      .map((el) => ({ el: el.className || el.tagName, h: el.getBoundingClientRect().height, w: el.getBoundingClientRect().width }))
      .filter((r) => r.h < 44 || r.w < 44);
  });
  check(small.length === 0, `${label}: touch targets >= 44px${small.length ? ' ' + JSON.stringify(small.slice(0, 3)) : ''}`);
}

// Loads every <img> on the page and reports which are broken.
async function imagesLoaded(page) {
  await page.evaluate(async () => {
    for (const img of document.images) img.loading = 'eager';
    await Promise.all([...document.images].map((img) => (img.complete ? null : new Promise((r) => { img.onload = img.onerror = r; }))));
  });
  return page.evaluate(() =>
    [...document.images]
      .filter((i) => i.getAttribute('src'))
      .map((i) => ({ src: i.currentSrc || i.src, ok: i.complete && i.naturalWidth > 0, w: i.getBoundingClientRect().width })),
  );
}

(async () => {
  fs.mkdirSync(SHOTS, { recursive: true });
  const health = await (await fetch(BASE + '/healthz')).json();
  const EXPECT_BUILDS = health.builds;
  const EXPECT_PROTO_Q = health.openQuestions.prototype; // undefined: no questions file; null: no reliable count
  check(EXPECT_BUILDS >= 1, `index reports at least one build (${EXPECT_BUILDS})`);
  check(health.decisions >= 1, `index reports decision cards (${health.decisions})`);
  const browser = await chromium.launch();
  try {
    for (const size of sizes) {
      for (const scheme of schemes) {
        const label = `${size.name}-${scheme}`;
        const phone = size.width < 900;
        console.log(`[${label}]`);
        clearInbox();
        const context = await browser.newContext({ viewport: { width: size.width, height: size.height }, colorScheme: scheme, deviceScaleFactor: phone ? 2 : 1 });
        const page = await context.newPage();
        const errors = [];
        page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
        page.on('pageerror', (e) => errors.push(e.message));
        page.on('requestfailed', (r) => errors.push(`request failed: ${r.url()}`));
        page.on('response', (r) => r.status() >= 400 && errors.push(`${r.status()} ${r.url()}`));

        // ---- Home: decisions grouped, then the build, then where things are.
        const res = await page.goto(BASE + '/', { waitUntil: 'load' });
        check(res.status() === 200, `${label}: home 200`);
        const groups = await page.locator('.d-group').evaluateAll((els) => els.map((e) => e.dataset.group));
        check(groups.length >= 2, `${label}: home shows decisions in groups (${groups.join(', ')})`);
        const ranks = groups.map((g) => GROUP_ORDER.indexOf(g));
        check(ranks.every((r, k) => r >= 0 && (k === 0 || r > ranks[k - 1])), `${label}: groups in part-of-the-game order`);
        const inGroups = await page.locator('.d-group .d-item').count();
        check(inGroups >= 1 && inGroups === (await page.locator('.decisions > .d-group .d-item').count()), `${label}: every open big decision sits in a group (${inGroups})`);
        check((await page.locator('.d-item img.thumb').count()) >= 1, `${label}: a decision line shows a thumbnail`);
        check((await page.locator('.picks-line').count()) >= 1, `${label}: small picks line present`);
        check((await page.locator('.where-list li').count()) === EXPECT_WS, `${label}: "Where things are" has ${EXPECT_WS} lines`);
        check((await page.locator('.ws-card').count()) === 0, `${label}: no workstream cards on home`);
        const tops = await page.evaluate((isPhone) => {
          const top = (s) => document.querySelector(s).getBoundingClientRect().top;
          return [top('.decisions'), top(isPhone ? '.build-strip' : '.build-panel'), top('.where')];
        }, phone);
        check(tops[0] < tops[1] && tops[1] <= tops[2], `${label}: decisions first, then the build, then where things are`);
        const buildOk = phone
          ? (await page.locator('.build-strip .btn-dl').isVisible()) && !(await page.locator('.build-panel').isVisible())
          : (await page.locator('.build-panel .btn-dl').count()) >= 2 && !(await page.locator('.build-strip').isVisible());
        check(buildOk, `${label}: one latest-build block, with downloads`);
        const homeImgs = await imagesLoaded(page);
        check(homeImgs.every((i) => i.ok), `${label}: home thumbnails load`);
        await pageChecks(page, `${label} home`);
        await page.screenshot({ path: path.join(SHOTS, `home-${label}.png`), fullPage: true });

        // ---- A decision with pictures.
        const item = page.locator('.d-item:has(img.thumb) a').first();
        const href = await item.getAttribute('href');
        const id = decodeURIComponent(href.split('/').pop());
        await item.click();
        await page.waitForURL(`**${href}`);
        check(page.url().endsWith(href), `${label}: decision line opens ${href}`);
        const imgs = await imagesLoaded(page);
        check(imgs.length >= 1 && imgs.every((i) => i.ok), `${label}: the decision's pictures all load (${imgs.filter((i) => i.ok).length}/${imgs.length})`);
        if (phone) check(imgs.every((i) => i.w >= size.width - 1), `${label}: pictures run full width on phone (${imgs.map((i) => Math.round(i.w)).join(', ')}px)`);
        check((await page.locator('.opt').count()) >= 2, `${label}: quick-pick options shown as buttons`);
        check((await page.locator('.d-card .prose p').count()) >= 2, `${label}: card body rendered`);
        await pageChecks(page, `${label} decision`);
        await page.screenshot({ path: path.join(SHOTS, `decision-${label}.png`), fullPage: true });

        // Tapping a picture opens it full size.
        const figHref = await page.locator('.fig-link').first().getAttribute('href');
        const full = await page.request.get(BASE + figHref);
        check(full.status() === 200 && /^image\//.test(full.headers()['content-type']), `${label}: tapping a picture opens the full image (${full.status()})`);

        // More detail.
        const more = page.locator('details.more');
        if (await more.count()) {
          await more.locator('summary').click();
          check(await more.locator('.prose, .sources').first().isVisible(), `${label}: "More detail" opens`);
        }

        // Answer it: pick the second option, add a note, send.
        const optLabel = (await page.locator('.opt .opt-label').nth(1).textContent()).trim();
        await page.locator('.opt').nth(1).click();
        await page.fill('#note', `Journey ${label}`);
        await Promise.all([page.waitForURL(/\?sent=1/), page.click('.btn-send')]);
        check(await page.locator('.answered-waiting').isVisible(), `${label}: card says "waiting for an agent" after sending`);
        const recs = inboxRecords();
        check(
          recs.length === 1 && recs[0].kind === 'answer' && recs[0].decisionId === id && recs[0].choice === optLabel && recs[0].note === `Journey ${label}`,
          `${label}: one inbox record written (${recs.map((r) => `${r.kind}/${r.decisionId}/${r.choice}`).join(', ')})`,
        );
        await page.goto(BASE + '/');
        check(await page.locator(`.d-item[data-decision="${id}"] .state-waiting`).isVisible(), `${label}: home shows it as answered, waiting for an agent`);

        // An agent marks it handled; the card shows done with its summary.
        if (recs[0]) {
          fs.writeFileSync(path.join(INBOX, recs[0].file.replace(/\.json$/, '.handled.json')), JSON.stringify({ handledAt: new Date().toISOString(), by: 'journey', summary: 'Journey summary: acted on it.' }));
          await page.goto(BASE + href);
          check((await page.locator('.answered-done').textContent()).includes('Journey summary: acted on it.'), `${label}: a handled answer shows "done" with the summary`);
        }

        // ---- Small picks bundle: accept all.
        await page.goto(BASE + '/');
        const picksHref = await page.locator('.picks-line').first().getAttribute('href');
        await page.locator('.picks-line').first().click();
        await page.waitForURL(`**${picksHref}`);
        const nPicks = await page.locator('.pick').count();
        check(nPicks >= 2, `${label}: bundle page lists the small picks (${nPicks})`);
        check((await page.locator('.btn-change').count()) === nPicks, `${label}: each pick can be changed`);
        await pageChecks(page, `${label} picks`);
        await page.screenshot({ path: path.join(SHOTS, `picks-${label}.png`), fullPage: true });
        const before = inboxRecords().length;
        await Promise.all([page.waitForURL(/accepted=/), page.click('.accept-all .btn')]);
        const accepted = inboxRecords().filter((r) => r.kind === 'accept-small');
        check(accepted.length === nPicks && inboxRecords().length === before + nPicks, `${label}: "Accept all" writes one record per pick (${accepted.length})`);
        check((await page.locator('.pick .state-waiting').count()) === nPicks, `${label}: picks then show as waiting for an agent`);
        check((await page.locator('.accept-all').count()) === 0, `${label}: nothing left to accept`);
        await page.goto(BASE + '/');
        check(await page.locator('.picks-quiet').first().isVisible(), `${label}: home shows the picks as accepted`);

        // ---- Workstream detail, from "Where things are".
        const wsLink = page.locator('.where-list a').first();
        const wsHref = await wsLink.getAttribute('href');
        await wsLink.click();
        await page.waitForURL(`**${wsHref}`);
        check((await page.locator('.prose h2, .prose h3').count()) > 0, `${label}: workstream page holds the plan`);
        check((await page.locator('.facts-grid .fact').count()) >= 2, `${label}: workstream page holds the next and last-done lines`);
        await pageChecks(page, `${label} workstream`);
        if (scheme === 'light') await page.screenshot({ path: path.join(SHOTS, `workstream-${label}.png`), fullPage: true });

        // Questions page from the prototype; a null count still loads it.
        if (EXPECT_PROTO_Q !== undefined) {
          await page.goto(BASE + '/w/prototype/questions');
          if (typeof EXPECT_PROTO_Q === 'number') {
            const qn = await page.locator('.q-index li').count();
            check(qn === EXPECT_PROTO_Q, `${label}: prototype questions page lists ${EXPECT_PROTO_Q} open, as indexed (found ${qn})`);
          } else {
            check((await page.locator('.lede').first().textContent()).includes('No reliable count'), `${label}: questions page says there's no reliable count`);
          }
          await pageChecks(page, `${label} questions`);
        } else {
          console.log(`  skip ${label}: prototype has no questions file`);
        }

        // ---- Builds
        await page.goto(BASE + '/builds');
        const builds = (await page.locator('.build-hero').count()) + (await page.locator('.build-list .build').count());
        check(builds === EXPECT_BUILDS, `${label}: builds page lists ${EXPECT_BUILDS} builds (found ${builds})`);
        check((await page.locator('.build-hero.is-latest').count()) === 1, `${label}: latest build marked`);
        await pageChecks(page, `${label} builds`);
        await page.screenshot({ path: path.join(SHOTS, `builds-${label}.png`), fullPage: true });

        // Keyboard: the first Tab lands on the skip link, which is visible.
        await page.keyboard.press('Tab');
        const skipVisible = await page.evaluate(() => document.activeElement.classList.contains('skip') && document.activeElement.getBoundingClientRect().top >= 0);
        check(skipVisible, `${label}: first Tab focuses a visible skip link`);

        await page.goto(BASE + '/playtest');
        check((await page.locator('.prose h2').count()) > 0, `${label}: playtest guide rendered`);
        await pageChecks(page, `${label} playtest`);

        // ---- The design-lab gallery: its own page, so its buttons aren't ours to size.
        if (scheme === (phone ? 'light' : 'dark')) {
          await page.goto(BASE + '/design-lab/', { waitUntil: 'load' });
          const g = await imagesLoaded(page);
          const broken = g.filter((i) => !i.ok);
          check(g.length >= 10 && broken.length === 0, `${label}: gallery pictures load (${g.length - broken.length}/${g.length})${broken.length ? ' ' + broken.slice(0, 2).map((b) => b.src).join(' ') : ''}`);
          await pageChecks(page, `${label} gallery`, { targets: false });
          if (phone) {
            // Every picture the gallery's tabs can show exists: click each
            // tab, note the picture URLs it sets, then check each with HEAD.
            const found = await page.evaluate(() => {
              const urls = new Set();
              const note = () => document.querySelectorAll('img').forEach((i) => i.src && urls.add(i.src));
              const buttons = [...document.querySelectorAll('.tabs button')];
              note();
              for (const b of buttons) {
                b.click();
                note();
              }
              return { n: buttons.length, urls: [...urls] };
            });
            const n = found.n;
            const urls = new Set(found.urls);
            const bad = [];
            for (const u of urls) {
              const r = await page.request.head(u);
              if (r.status() !== 200 || !/^image\//.test(r.headers()['content-type'] || '')) bad.push(`${r.status()} ${u}`);
            }
            check(urls.size >= 50 && bad.length === 0, `${label}: every picture behind the gallery's ${n} tabs exists (${urls.size - bad.length}/${urls.size})${bad.length ? ' ' + bad.slice(0, 2).join(' ') : ''}`);
          }
        }

        const ours = errors.filter((e) => !/fonts\.(googleapis|gstatic)\.com/.test(e));
        check(ours.length === 0, `${label}: no console or network errors${ours.length ? ' ' + JSON.stringify(ours.slice(0, 3)) : ''}`);
        await context.close();
      }
    }
  } finally {
    await browser.close();
    clearInbox();
  }

  // Downloads, checked over HTTP without pulling the whole file.
  console.log('[downloads]');
  const home = await (await fetch(BASE + '/')).text();
  const apk = /href="(\/builds\/[^"]+\.apk)"/.exec(home);
  check(!!apk, 'home links an APK');
  if (apk) {
    const r = await fetch(BASE + apk[1]);
    check(r.status === 200, `APK link returns 200 (${r.status})`);
    check(r.headers.get('content-type') === 'application/vnd.android.package-archive', `APK content type (${r.headers.get('content-type')})`);
    check(/^attachment/.test(r.headers.get('content-disposition') || ''), 'APK sent as attachment');
    check(Number(r.headers.get('content-length')) > 1e6, `APK has a Content-Length (${r.headers.get('content-length')})`);
    await r.body.cancel();
    const p = await fetch(BASE + apk[1], { headers: { Range: 'bytes=0-1023' } });
    check(p.status === 206, `Range request returns 206 (${p.status})`);
    check(p.headers.get('content-range') && p.headers.get('content-range').startsWith('bytes 0-1023/'), `Content-Range (${p.headers.get('content-range')})`);
    const buf = Buffer.from(await p.arrayBuffer());
    check(buf.length === 1024 && buf[0] === 0x50 && buf[1] === 0x4b, 'partial body is the first 1024 bytes of a zip/APK');
  }

  if (failures.length) {
    console.log(`\nJOURNEY FAILED: ${failures.length} check(s)`);
    process.exit(1);
  }
  console.log('\nJOURNEY PASSED');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
