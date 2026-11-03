'use strict';
// Read-only access to the shared git dir. Only the subcommands below may run,
// and they run without a shell. Nothing here fetches or writes.

const { execFile } = require('node:child_process');

const READ_ONLY = new Set(['show', 'log', 'rev-parse', 'for-each-ref', 'merge-base']);

function makeGit(gitDir) {
  function run(args, { allowFail = false } = {}) {
    if (!READ_ONLY.has(args[0])) {
      return Promise.reject(new Error(`git ${args[0]} is not allowed (read-only portal)`));
    }
    return new Promise((resolve, reject) => {
      execFile('git', ['--git-dir=' + gitDir, ...args], {
        maxBuffer: 16 * 1024 * 1024,
        timeout: 15000,
        // Never take optional locks, never prompt, never page.
        env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_TERMINAL_PROMPT: '0', GIT_PAGER: 'cat', LC_ALL: 'C' },
      }, (err, stdout, stderr) => {
        if (err) {
          if (allowFail) return resolve({ ok: false, code: err.code, stdout: String(stdout), stderr: String(stderr) });
          const e = new Error(`git ${args.join(' ')} failed: ${String(stderr).trim() || err.message}`);
          e.code = err.code;
          return reject(e);
        }
        resolve(allowFail ? { ok: true, code: 0, stdout: String(stdout), stderr: String(stderr) } : String(stdout));
      });
    });
  }

  // The full sha of a ref, or null if it doesn't exist.
  async function revParse(ref) {
    const r = await run(['rev-parse', '-q', '--verify', ref + '^{commit}'], { allowFail: true });
    return r.ok ? r.stdout.trim() : null;
  }

  async function isAncestor(a, b) {
    const r = await run(['merge-base', '--is-ancestor', a, b], { allowFail: true });
    if (r.ok) return true;
    if (r.code === 1) return false;
    throw new Error(`git merge-base failed: ${r.stderr.trim()}`);
  }

  // Branch resolution: the local head, unless origin/<name> exists and is a
  // descendant of it (local is behind), then origin. A branch that exists only
  // on origin resolves to origin.
  async function resolveBranch(name) {
    const local = await revParse('refs/heads/' + name);
    const remote = await revParse('refs/remotes/origin/' + name);
    if (local && remote && local !== remote && (await isAncestor(local, remote))) {
      return { name, ref: 'refs/remotes/origin/' + name, sha: remote, from: 'origin' };
    }
    if (local) return { name, ref: 'refs/heads/' + name, sha: local, from: 'local' };
    if (remote) return { name, ref: 'refs/remotes/origin/' + name, sha: remote, from: 'origin' };
    return null;
  }

  // File content at a commit, or null if the path doesn't exist there.
  async function showFile(sha, path) {
    const r = await run(['show', `${sha}:${path}`], { allowFail: true });
    return r.ok ? r.stdout : null;
  }

  // Latest commit across the given commits that touches the paths.
  async function lastCommit(shas, paths = [], exclude = []) {
    if (!shas.length) return null;
    const spec = [];
    if (paths.length || exclude.length) {
      spec.push('--', ...(paths.length ? paths : ['.']), ...exclude.map((p) => ':(exclude)' + p));
    }
    const out = await run(['log', '-1', '--format=%H%x1f%cI%x1f%s', ...shas, ...spec]);
    const line = out.trim();
    if (!line) return null;
    const [sha, date, subject] = line.split('\x1f');
    return { sha, date, subject };
  }

  // One cheap call that changes whenever any branch head moves.
  async function headsFingerprint() {
    return run(['for-each-ref', '--format=%(refname) %(objectname)', 'refs/heads', 'refs/remotes']);
  }

  return { run, revParse, isAncestor, resolveBranch, showFile, lastCommit, headsFingerprint };
}

module.exports = { makeGit, READ_ONLY };
