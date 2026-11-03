'use strict';
// Browser journey against a running portal. Usage:
//   PORTAL_URL=http://127.0.0.1:8789 node test/journey.js
// Needs Playwright on NODE_PATH (see check.sh). Saves screenshots to shots/.

const path = require('node:path');
const fs = require('node:fs');
const { chromium } = require('playwright');

const BASE = process.env.PORTAL_URL || 'http://127.0.0.1:8780';
const SHOTS = path.join(__dirname, '..', 'shots');
// Expected counts come from the registry and the server's own index, not
// from today's data, so a new build or an answered question doesn't fail the gate.
const REGISTRY = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'workstreams.json'), 'utf8'));
const EXPECT_CARDS = REGISTRY.workstreams.length;

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

async function pageChecks(page, label) {
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  check(overflow <= 0, `${label}: no horizontal overflow (${overflow}px)`);
  // Touch targets: nav links, buttons, card links, summaries.
  const small = await page.evaluate(() => {
    const sel = '.site-nav a, .btn, .meta-link, .text-link, details summary, .waiting-list a, .crumbs a, .card, .fact-link, .install-hint a';
    return [...document.querySelectorAll(sel)]
      .filter((el) => el.offsetParent !== null)
      .map((el) => ({ el: el.className || el.tagName, h: el.getBoundingClientRect().height, w: el.getBoundingClientRect().width }))
      .filter((r) => r.h < 44 || r.w < 44);
  });
  check(small.length === 0, `${label}: touch targets >= 44px${small.length ? ' ' + JSON.stringify(small.slice(0, 3)) : ''}`);
}

(async () => {
  fs.mkdirSync(SHOTS, { recursive: true });
  const health = await (await fetch(BASE + '/healthz')).json();
  const EXPECT_BUILDS = health.builds;
  const EXPECT_PROTO_Q = health.openQuestions.prototype;
  check(EXPECT_BUILDS >= 1, `index reports at least one build (${EXPECT_BUILDS})`);
  const browser = await chromium.launch();
  try {
    for (const size of sizes) {
      for (const scheme of schemes) {
        const label = `${size.name}-${scheme}`;
        console.log(`[${label}]`);
        const context = await browser.newContext({ viewport: { width: size.width, height: size.height }, colorScheme: scheme, deviceScaleFactor: size.width < 500 ? 2 : 1 });
        const page = await context.newPage();
        const errors = [];
        page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
        page.on('pageerror', (e) => errors.push(e.message));
        page.on('requestfailed', (r) => errors.push(`request failed: ${r.url()}`));
        page.on('response', (r) => r.status() >= 400 && errors.push(`${r.status()} ${r.url()}`));

        // Home
        const res = await page.goto(BASE + '/', { waitUntil: 'load' });
        check(res.status() === 200, `${label}: home 200`);
        const cards = await page.locator('.ws-card').count();
        check(cards === EXPECT_CARDS, `${label}: home has ${EXPECT_CARDS} workstream cards (found ${cards})`);
        check((await page.locator('.build-panel .btn-dl').count()) >= 2, `${label}: latest build card has download buttons`);
        check((await page.locator('#h-waiting').count()) === 1, `${label}: waiting-on-you list present`);
        const strip = page.locator('.build-strip .btn-dl');
        if (size.width < 900) {
          const sb = await strip.boundingBox();
          check(!!sb && sb.y + sb.height <= size.height, `${label}: APK button in the first screen (${sb ? Math.round(sb.y) : 'missing'}px)`);
        } else {
          check(!(await strip.isVisible()), `${label}: no phone strip on desktop`);
        }
        await pageChecks(page, `${label} home`);
        await page.screenshot({ path: path.join(SHOTS, `home-${label}.png`), fullPage: true });

        // Drill down from the first card (tap anywhere on the card)
        const first = page.locator('.ws-card').first();
        const id = await first.getAttribute('data-ws');
        const box = await first.boundingBox();
        await page.mouse.click(box.x + box.width / 2, box.y + box.height * 0.45);
        await page.waitForURL(`**/w/${id}`);
        check(page.url().endsWith(`/w/${id}`), `${label}: card drills down to /w/${id}`);
        check((await page.locator('.prose h2, .prose h3').count()) > 0, `${label}: plan rendered as a page`);
        await pageChecks(page, `${label} workstream`);
        if (scheme === 'light') await page.screenshot({ path: path.join(SHOTS, `workstream-${label}.png`), fullPage: true });

        // Questions page from the prototype card
        await page.goto(BASE + '/w/prototype/questions');
        const qn = await page.locator('.q-index li').count();
        check(EXPECT_PROTO_Q === null || qn === EXPECT_PROTO_Q, `${label}: prototype questions page lists ${EXPECT_PROTO_Q} open, as indexed (found ${qn})`);
        await pageChecks(page, `${label} questions`);

        // Builds
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

        // Playtest guide
        await page.goto(BASE + '/playtest');
        check((await page.locator('.prose h2').count()) > 0, `${label}: playtest guide rendered`);
        await pageChecks(page, `${label} playtest`);

        check(errors.length === 0, `${label}: no console or network errors${errors.length ? ' ' + JSON.stringify(errors.slice(0, 3)) : ''}`);
        await context.close();
      }
    }
  } finally {
    await browser.close();
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
