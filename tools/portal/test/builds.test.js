'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createApp } = require('../server');
const { resolveBuildFile, parseRange, parseReadme, scanBuilds } = require('../lib/builds');
const { GIT_DIR, tmpDir, startApp, rawGet } = require('./helpers');

function fixtureBuilds() {
  const outside = tmpDir('portal-outside-');
  fs.writeFileSync(path.join(outside, 'secret.txt'), 'secret');
  const root = tmpDir('portal-builds-');
  const b = path.join(root, '1104-0400-build4');
  fs.mkdirSync(path.join(b, 'android'), { recursive: true });
  fs.writeFileSync(path.join(b, 'README.txt'), 'Bramble build 4, 4 Nov\nSource: proto/main at 8b6a107 (x).\n\nNew since build 3: a thing.\n\nWindows: unzip\n');
  fs.writeFileSync(path.join(b, 'Bramble.apk'), Buffer.from(Array.from({ length: 1000 }, (_, i) => i % 256)));
  fs.writeFileSync(path.join(b, 'Bramble-windows.zip'), 'zipzip');
  fs.writeFileSync(path.join(b, 'android', 'bramble.apk'), 'inner');
  fs.symlinkSync(path.join(outside, 'secret.txt'), path.join(b, 'escape.txt'));
  fs.symlinkSync(outside, path.join(b, 'escdir'));
  fs.symlinkSync('1104-0400-build4', path.join(root, 'latest'));
  fs.symlinkSync(outside, path.join(root, 'evil')); // a "build" that is a symlink out of the root
  fs.writeFileSync(path.join(outside, 'README.txt'), 'fake');
  fs.mkdirSync(path.join(root, 'empty-project'));
  fs.writeFileSync(path.join(root, 'empty-project', 'x.apk'), 'x');
  return { root, outside };
}

test('resolveBuildFile refuses traversal and symlink escapes', async () => {
  const { root } = fixtureBuilds();
  const ok = await resolveBuildFile(root, '1104-0400-build4', ['Bramble.apk']);
  assert.ok(ok.file);
  assert.ok((await resolveBuildFile(root, 'latest', ['Bramble.apk'])).file, 'latest symlink inside root is fine');
  assert.ok((await resolveBuildFile(root, '1104-0400-build4', ['android', 'bramble.apk'])).file);
  assert.equal((await resolveBuildFile(root, '1104-0400-build4', ['..', 'x'])).error, 400);
  assert.equal((await resolveBuildFile(root, '..', ['etc', 'passwd'])).error, 404);
  assert.equal((await resolveBuildFile(root, '1104-0400-build4', ['../../etc/passwd'])).error, 400);
  assert.equal((await resolveBuildFile(root, '1104-0400-build4', ['escape.txt'])).error, 403);
  assert.equal((await resolveBuildFile(root, '1104-0400-build4', ['escdir', 'secret.txt'])).error, 403);
  assert.equal((await resolveBuildFile(root, 'evil', ['secret.txt'])).error, 403);
  assert.equal((await resolveBuildFile(root, 'empty-project', ['x.apk'])).error, 404, 'not a build');
  assert.equal((await resolveBuildFile(root, '1104-0400-build4', ['android'])).error, 404, 'directories are not files');
  assert.equal((await resolveBuildFile(root, '1104-0400-build4', ['a\0b'])).error, 400);
});

test('scanBuilds lists only dirs with a README, newest first, latest marked', async () => {
  const { root } = fixtureBuilds();
  const s = await scanBuilds(root);
  assert.deepEqual(s.builds.map((b) => b.name), ['1104-0400-build4']);
  assert.ok(s.builds[0].isLatest);
  assert.equal(s.builds[0].files.length, 2);
});

test('parseReadme on the real build 4 README', () => {
  const real = '/data/bramble-builds/1104-0400-build4/README.txt';
  if (!fs.existsSync(real)) return;
  const r = parseReadme(fs.readFileSync(real, 'utf8'), '1104-0400-build4');
  assert.equal(r.label, 'Build 4');
  assert.equal(r.source.branch, 'proto/main');
  assert.equal(r.source.commit, '8b6a107');
  assert.equal(r.news[0].heading, 'New since build 3');
  assert.equal(r.news.length, 2);
});

test('parseRange', () => {
  assert.equal(parseRange(undefined, 100), null);
  assert.deepEqual(parseRange('bytes=0-9', 100), { start: 0, end: 9 });
  assert.deepEqual(parseRange('bytes=90-', 100), { start: 90, end: 99 });
  assert.deepEqual(parseRange('bytes=-10', 100), { start: 90, end: 99 });
  assert.deepEqual(parseRange('bytes=50-500', 100), { start: 50, end: 99 });
  assert.equal(parseRange('bytes=100-', 100), 'unsatisfiable');
  assert.equal(parseRange('bytes=0-1,5-6', 100), null);
  assert.equal(parseRange('items=0-1', 100), null);
});

test('HTTP downloads: types, attachment, length, Range, HEAD, traversal', async (t) => {
  const { root } = fixtureBuilds();
  const app = createApp({ gitDir: GIT_DIR, buildsDir: root, log: () => {} });
  const srv = await startApp(app);
  t.after(srv.close);
  const url = '/builds/1104-0400-build4/Bramble.apk';

  let r = await rawGet(srv.base, url);
  assert.equal(r.status, 200);
  assert.equal(r.headers['content-type'], 'application/vnd.android.package-archive');
  assert.match(r.headers['content-disposition'], /^attachment; filename="Bramble-build4.apk"/);
  assert.equal(r.headers['content-length'], '1000');
  assert.equal(r.headers['accept-ranges'], 'bytes');
  assert.equal(r.body.length, 1000);

  r = await rawGet(srv.base, url, { Range: 'bytes=10-19' });
  assert.equal(r.status, 206);
  assert.equal(r.headers['content-range'], 'bytes 10-19/1000');
  assert.equal(r.headers['content-length'], '10');
  assert.deepEqual([...r.body], [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);

  r = await rawGet(srv.base, url, { Range: 'bytes=-5' });
  assert.equal(r.status, 206);
  assert.equal(r.headers['content-range'], 'bytes 995-999/1000');

  r = await rawGet(srv.base, url, { Range: 'bytes=5000-' });
  assert.equal(r.status, 416);
  assert.equal(r.headers['content-range'], 'bytes */1000');

  r = await rawGet(srv.base, url, { Range: 'bytes=0-9', 'If-Range': '"stale"' });
  assert.equal(r.status, 200, 'If-Range mismatch sends the whole file');

  r = await rawGet(srv.base, url, {}, 'HEAD');
  assert.equal(r.status, 200);
  assert.equal(r.headers['content-length'], '1000');
  assert.equal(r.body.length, 0);

  r = await rawGet(srv.base, '/builds/1104-0400-build4/Bramble-windows.zip');
  assert.equal(r.headers['content-type'], 'application/zip');

  for (const p of [
    '/builds/1104-0400-build4/../../../etc/passwd',
    '/builds/1104-0400-build4/..%2f..%2f..%2fetc%2fpasswd',
    '/builds/1104-0400-build4/%2e%2e/%2e%2e/etc/passwd',
    '/builds/..%2f..%2fetc/passwd',
    '/builds/1104-0400-build4/escape.txt',
    '/builds/1104-0400-build4/escdir/secret.txt',
    '/builds/evil/secret.txt',
    '/builds/1104-0400-build4/%E0%A4%A',
  ]) {
    const res = await rawGet(srv.base, p);
    assert.ok([400, 403, 404].includes(res.status), `${p} -> ${res.status}`);
    assert.ok(!res.body.toString().includes('secret') || res.status !== 200, p);
    assert.ok(!res.body.toString().includes('root:x:'), p);
  }
});
