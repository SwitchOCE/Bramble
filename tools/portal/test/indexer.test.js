'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createIndexer } = require('../lib/indexer');
const { tmpDir } = require('./helpers');

// A fake git whose branch heads we can move.
function fakeGit() {
  const g = { heads: 'refs/heads/a 1', checks: 0, shows: 0 };
  g.headsFingerprint = async () => {
    g.checks++;
    return g.heads;
  };
  g.resolveBranch = async (name) => ({ name, sha: 'abc', from: 'local' });
  g.showFile = async () => {
    g.shows++;
    return '# P\n<!-- status -->\n- **Status:** active\n- **Last step done:** x\n- **Next step:** y\n- **Waiting on you:** Nothing yet.\n<!-- /status -->\n';
  };
  g.lastCommit = async () => null;
  g.isAncestor = async () => true;
  return g;
}

test('re-indexes only when a head moves, and checks at most once per interval', async () => {
  const dir = tmpDir('portal-idx-');
  const reg = path.join(dir, 'w.json');
  fs.writeFileSync(reg, JSON.stringify({ workstreams: [{ id: 'a', title: 'A', branches: ['a'], plan: 'p.md' }] }));
  const git = fakeGit();
  const idx = createIndexer({ git, registryFile: reg, buildsDir: dir, checkEveryMs: 50 });
  const first = await idx.get();
  assert.equal(git.shows, 1);
  await Promise.all([idx.get(), idx.get(), idx.get()]);
  assert.equal(git.checks, 1, 'a burst of requests makes one check');
  await new Promise((r) => setTimeout(r, 60));
  await idx.get();
  assert.equal(git.checks, 2);
  assert.equal(git.shows, 1, 'nothing moved, no re-index');
  git.heads = 'refs/heads/a 2';
  await new Promise((r) => setTimeout(r, 60));
  const second = await idx.get();
  assert.equal(git.shows, 2, 'head moved, re-indexed');
  assert.notEqual(first, second);
});
