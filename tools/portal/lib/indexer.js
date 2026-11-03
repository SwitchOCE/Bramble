'use strict';
// The in-memory index: every workstream's status, questions and last
// activity, read from git, plus the builds on disk. It is rebuilt only when
// a branch head or the builds folder changes, checked at most once every
// few seconds.

const fsp = require('node:fs/promises');
const path = require('node:path');
const { parseStatusBlock, isNothingWaiting } = require('./status');
const { parseQuestions } = require('./questions');
const { scanBuilds } = require('./builds');
const { loadDecisions } = require('./decisions');

async function loadRegistry(file) {
  const data = JSON.parse(await fsp.readFile(file, 'utf8'));
  if (!Array.isArray(data.workstreams)) throw new Error(`${file}: "workstreams" must be a list`);
  for (const w of data.workstreams) {
    if (!w.id || !w.title || !Array.isArray(w.branches) || !w.plan) {
      throw new Error(`${file}: each workstream needs id, title, branches and plan (bad entry: ${JSON.stringify(w).slice(0, 80)})`);
    }
  }
  return data;
}

async function indexWorkstream(git, w, resolve) {
  const out = {
    id: w.id,
    title: w.title,
    blurb: w.blurb || '',
    planPath: w.plan,
    branchesTried: w.branches,
    branch: null,
    planText: null,
    status: null,
    questions: null,
    activity: null,
    problems: [],
  };

  for (const name of w.branches) {
    const b = await resolve(name);
    if (!b) continue;
    const text = await git.showFile(b.sha, w.plan);
    if (text !== null) {
      out.branch = b;
      out.planText = text;
      break;
    }
  }

  if (!out.branch) {
    out.status = { state: 'missing', status: null, fields: {}, problems: [`${w.plan} was not found on ${w.branches.join(' or ')}.`] };
  } else {
    out.status = parseStatusBlock(out.planText);
  }

  if (w.questions) {
    const qBranch = w.questions.branch ? await resolve(w.questions.branch) : out.branch;
    const qText = qBranch ? await git.showFile(qBranch.sha, w.questions.path) : null;
    if (qText === null) {
      out.questions = { path: w.questions.path, branch: qBranch, count: null, reason: `${w.questions.path} was not found.`, items: [] };
    } else {
      out.questions = { path: w.questions.path, branch: qBranch, text: qText, ...parseQuestions(qText) };
    }
  }

  const act = w.activity || {};
  const actBranches = [];
  for (const name of act.branches || w.branches) {
    const b = await resolve(name);
    if (b && !actBranches.some((x) => x.sha === b.sha)) actBranches.push(b);
  }
  try {
    const c = await git.lastCommit(actBranches.map((b) => b.sha), act.paths || [], act.exclude || []);
    if (c) {
      const on = [];
      for (const b of actBranches) {
        if (b.sha === c.sha || (await git.isAncestor(c.sha, b.sha))) on.push(b.name);
      }
      out.activity = { ...c, branches: on };
    }
  } catch (e) {
    out.problems.push(`Couldn't read the last activity: ${e.message}`);
  }
  return out;
}

// decisionsDir: read cards from this folder on disk instead of git (tests).
function createIndexer({ git, registryFile, buildsDir, images, decisionsDir = null, checkEveryMs = 3000, log = () => {} }) {
  let index = null;
  let fingerprint = null;
  let lastCheck = 0;
  let pending = null;

  async function currentFingerprint() {
    const heads = await git.headsFingerprint();
    let builds = '';
    try {
      const names = (await fsp.readdir(buildsDir)).sort();
      const stats = await Promise.all(
        names.map(async (n) => {
          try {
            const st = await fsp.stat(path.join(buildsDir, n, 'README.txt'));
            return `${n}:${st.mtimeMs}`;
          } catch {
            return n;
          }
        }),
      );
      let latest = '';
      try {
        latest = await fsp.readlink(path.join(buildsDir, 'latest'));
      } catch {
        latest = '';
      }
      builds = stats.join(',') + '|' + latest;
    } catch (e) {
      builds = 'unreadable:' + e.code;
    }
    let reg = '';
    try {
      reg = String((await fsp.stat(registryFile)).mtimeMs);
    } catch {
      reg = 'missing';
    }
    let cards = '';
    if (decisionsDir) {
      try {
        const names = (await fsp.readdir(decisionsDir)).sort();
        const st = await Promise.all(names.map((n) => fsp.stat(path.join(decisionsDir, n)).then((x) => `${n}:${x.mtimeMs}`, () => n)));
        cards = st.join(',');
      } catch (e) {
        cards = 'unreadable:' + e.code;
      }
    }
    return heads + '\n' + builds + '\n' + reg + '\n' + cards;
  }

  async function build() {
    const started = Date.now();
    const cache = new Map();
    const resolve = (name) => {
      if (!cache.has(name)) cache.set(name, git.resolveBranch(name));
      return cache.get(name);
    };
    let registry;
    let registryError = null;
    try {
      registry = await loadRegistry(registryFile);
    } catch (e) {
      registry = { workstreams: [] };
      registryError = e.message;
    }
    const workstreams = await Promise.all(
      registry.workstreams.map((w) =>
        indexWorkstream(git, w, resolve).catch((e) => ({
          id: w.id,
          title: w.title,
          planPath: w.plan,
          branchesTried: w.branches,
          status: { state: 'missing', status: null, fields: {}, problems: [`Couldn't read this workstream: ${e.message}`] },
          problems: [],
        })),
      ),
    );
    const builds = await scanBuilds(buildsDir);
    const playtestCfg = registry.playtest || null;
    let playtest = null;
    if (playtestCfg) {
      const b = await resolve(playtestCfg.branch);
      const text = b ? await git.showFile(b.sha, playtestCfg.path) : null;
      playtest = { path: playtestCfg.path, branch: b, branchName: playtestCfg.branch, text };
    }
    const waiting = workstreams
      .filter((w) => w.status && w.status.fields.waiting && w.status.status !== 'done' && !isNothingWaiting(w.status.fields.waiting))
      .map((w) => ({ id: w.id, title: w.title, text: w.status.fields.waiting, status: w.status.status }))
      .sort((a, b) => (b.status === 'waiting on you') - (a.status === 'waiting on you'));

    // Branches pictures may be served from, resolved once per index.
    const imageBranchNames = (registry.images && registry.images.branches) || [];
    const imageBranches = {};
    for (const name of imageBranchNames) {
      const b = await resolve(name);
      if (b) imageBranches[name] = b;
    }
    const gallery = registry.gallery ? { ...registry.gallery, resolved: imageBranches[registry.gallery.branch] || (await resolve(registry.gallery.branch)) } : null;

    const questionFiles = workstreams
      .filter((w) => w.questions && w.questions.branch)
      .map((w) => ({ id: w.id, title: w.title, path: w.questions.path, branch: w.questions.branch.name }));
    let decisions;
    try {
      decisions = await loadDecisions({
        git,
        resolve,
        cfg: registry.decisions || null,
        dir: decisionsDir,
        images,
        imageBranches: imageBranchNames,
        questionFiles,
      });
    } catch (e) {
      decisions = { cards: [], problems: [`The decision cards couldn't be read: ${e.message}`] };
    }
    log(`indexed ${workstreams.length} workstreams, ${decisions.cards.length} decisions and ${builds.builds.length} builds in ${Date.now() - started} ms`);
    return { builtAt: new Date(), registryError, workstreams, builds, waiting, playtest, decisions, imageBranches, gallery };
  }

  // Returns the index, rebuilding it if anything moved since the last check.
  async function get() {
    if (pending) return pending;
    if (index && Date.now() - lastCheck < checkEveryMs) return index;
    pending = (async () => {
      try {
        const fp = await currentFingerprint();
        lastCheck = Date.now();
        if (!index || fp !== fingerprint) {
          index = await build();
          fingerprint = fp;
        }
        index.checkedAt = new Date(lastCheck);
        index.stale = null;
        return index;
      } catch (e) {
        log(`index refresh failed: ${e.message}`);
        if (index) {
          index.stale = e.message;
          return index;
        }
        throw e;
      } finally {
        pending = null;
      }
    })();
    return pending;
  }

  return { get };
}

module.exports = { createIndexer, loadRegistry, indexWorkstream };
