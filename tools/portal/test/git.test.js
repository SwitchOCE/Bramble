'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { makeGit } = require('../lib/git');
const { GIT_DIR, tmpDir } = require('./helpers');

// A throwaway repo whose refs model each case. Writes happen only here.
function fixtureRepo() {
  const dir = tmpDir('portal-git-');
  const g = (...a) => execFileSync('git', ['-C', dir, ...a], { encoding: 'utf8', env: { ...process.env, GIT_AUTHOR_NAME: 't', GIT_AUTHOR_EMAIL: 't@t', GIT_COMMITTER_NAME: 't', GIT_COMMITTER_EMAIL: 't@t' } }).trim();
  g('init', '-q', '-b', 'main');
  const commit = (msg) => {
    g('commit', '-q', '--allow-empty', '-m', msg);
    return g('rev-parse', 'HEAD');
  };
  const a = commit('a');
  const b = commit('b');
  const c = commit('c');
  // behind: local at a, origin at c (descendant)  -> origin
  g('update-ref', 'refs/heads/behind', a);
  g('update-ref', 'refs/remotes/origin/behind', c);
  // ahead: local at c, origin at a                -> local
  g('update-ref', 'refs/heads/ahead', c);
  g('update-ref', 'refs/remotes/origin/ahead', a);
  // diverged: local at b, origin at a+x           -> local
  g('checkout', '-q', '-b', 'side', a);
  const x = commit('x');
  g('update-ref', 'refs/heads/diverged', b);
  g('update-ref', 'refs/remotes/origin/diverged', x);
  // same, local-only and origin-only
  g('update-ref', 'refs/heads/same', b);
  g('update-ref', 'refs/remotes/origin/same', b);
  g('update-ref', 'refs/heads/localonly', b);
  g('update-ref', 'refs/remotes/origin/originonly', c);
  return { gitDir: path.join(dir, '.git'), a, b, c, x };
}

test('branch resolution', async () => {
  const f = fixtureRepo();
  const git = makeGit(f.gitDir);
  const r = async (n) => {
    const v = await git.resolveBranch(n);
    return v && [v.from, v.sha];
  };
  assert.deepEqual(await r('behind'), ['origin', f.c]);
  assert.deepEqual(await r('ahead'), ['local', f.c]);
  assert.deepEqual(await r('diverged'), ['local', f.b]);
  assert.deepEqual(await r('same'), ['local', f.b]);
  assert.deepEqual(await r('localonly'), ['local', f.b]);
  assert.deepEqual(await r('originonly'), ['origin', f.c]);
  assert.equal(await git.resolveBranch('nope'), null);
});

test('real repo: local main is behind origin/main, so main resolves to origin', async () => {
  const git = makeGit(GIT_DIR);
  const local = await git.revParse('refs/heads/main');
  const remote = await git.revParse('refs/remotes/origin/main');
  const res = await git.resolveBranch('main');
  if (local !== remote && (await git.isAncestor(local, remote))) assert.equal(res.from, 'origin');
  else assert.equal(res.from, 'local');
});

test('only read-only git subcommands can run', async () => {
  const git = makeGit(GIT_DIR);
  for (const cmd of ['fetch', 'push', 'commit', 'update-ref', 'gc', 'checkout', 'config']) {
    await assert.rejects(git.run([cmd]), /not allowed/, cmd);
  }
});

test('showFile returns null for missing paths, content otherwise', async () => {
  const git = makeGit(GIT_DIR);
  const b = await git.resolveBranch('proto/main');
  assert.equal(await git.showFile(b.sha, 'no/such/file.md'), null);
  assert.match(await git.showFile(b.sha, 'docs/prototype/PLAN.md'), /<!-- status -->/);
});
