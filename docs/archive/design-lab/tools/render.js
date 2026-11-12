// Render an HTML file to JPEG screenshots at the design lab's fixed sizes.
// node render.js <page.html> <out_prefix> [desktop|phone|both] [selector]
// desktop: 1920x1080, phone: 844x390 CSS px (phone landscape) at scale 2. Output: <out_prefix>-desktop.jpg etc.
// Playwright lives outside the repo on the Optiplex (~/.local/share/bramble-tools).
const { chromium } = require(process.env.PLAYWRIGHT_PATH || (process.env.HOME + '/.local/share/bramble-tools/node_modules/playwright'));
const path = require('path');
(async () => {
  const [page_file, out, mode = 'both', selector] = process.argv.slice(2);
  const sizes = { desktop: { width: 1920, height: 1080, scale: 1 }, phone: { width: 844, height: 390, scale: 2 } };
  const browser = await chromium.launch();
  try {
    for (const name of mode === 'both' ? ['desktop', 'phone'] : [mode]) {
      const s = sizes[name];
      const ctx = await browser.newContext({ viewport: { width: s.width, height: s.height }, deviceScaleFactor: s.scale });
      const page = await ctx.newPage();
      const failed = [];
      page.on('requestfailed', r => failed.push(r.url()));
      await page.goto('file://' + path.resolve(page_file), { waitUntil: 'networkidle' });
      const target = selector ? page.locator(selector) : page;
      await target.screenshot({ path: `${out}-${name}.jpg`, type: 'jpeg', quality: 85 });
      if (failed.length) console.error('failed to load:', failed.join(', '));
      console.log('wrote', `${out}-${name}.jpg`);
      await ctx.close();
    }
  } finally { await browser.close(); }
})();
